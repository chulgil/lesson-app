import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../search/search_facade.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../extensions/subscription_proposal_visuals.dart';
import '../extensions/subscription_template_visuals.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
import '../widgets/proposal_card_widgets.dart';
import '../widgets/skip_reason_dialog.dart';
import '../widgets/subscription_history_section.dart';

/// Screen for students to view and respond to a renewal proposal.
///
/// Like receiving a gym membership renewal notice — shows what you had before,
/// confirms it's the same deal, and lets you renew with one tap.
class RenewalDetailScreen extends ConsumerStatefulWidget {
  final String proposalId;

  const RenewalDetailScreen({super.key, required this.proposalId});

  @override
  ConsumerState<RenewalDetailScreen> createState() =>
      _RenewalDetailScreenState();
}

class _RenewalDetailScreenState extends ConsumerState<RenewalDetailScreen> {
  bool _isProcessing = false;
  String? _selectedTemplateId;

  @override
  Widget build(BuildContext context) {
    final proposalAsync = ref.watch(
      subscriptionProposalProvider(widget.proposalId),
    );

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.renewalProposalAppBarTitle,
      ),
      body:
          _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : proposalAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (_, __) =>
                        Center(child: Text('${AppStrings.errorOccurred}.')),
                data: (proposal) {
                  if (proposal == null) {
                    return const Center(
                      child: Text(AppStrings.proposalNotFoundEmpty),
                    );
                  }
                  return _buildContent(proposal);
                },
              ),
      bottomNavigationBar: proposalAsync.whenOrNull(
        data: (proposal) {
          if (proposal == null || !proposal.canRespond || _isProcessing) {
            return null;
          }
          return _buildBottomActions(proposal);
        },
      ),
    );
  }

  Widget _buildContent(SubscriptionProposal proposal) {
    final teacherAsync = ref.watch(
      teacherFullProfileProvider(proposal.teacherId),
    );
    final teacherName =
        teacherAsync.whenOrNull(data: (profile) => profile?.name) ??
        AppStrings.teacher;

    _selectedTemplateId ??=
        proposal.selectedTemplateId ?? proposal.effectiveRecommendedTemplateId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner (if not pending)
          if (proposal.status != ProposalStatus.pending)
            ProposalStatusBanner(proposal: proposal),

          // Renewal header
          _buildRenewalHeader(teacherName, proposal),

          const SizedBox(height: AppSpacing.space5),

          // Template selection or details
          if (proposal.isMultiChoice && proposal.canRespond) ...[
            Text(
              AppStrings.renewalSelectTemplatePrompt,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _buildTemplateOptions(proposal),
            const SizedBox(height: AppSpacing.space4),
          ],

          // Selected template details
          _buildTemplateDetails(),

          // "Same as before" hint
          if (proposal.isRenewal) ...[
            const SizedBox(height: AppSpacing.space3),
            _buildSameAsPreviousHint(),
          ],

          // Teacher message
          if (proposal.message != null) ...[
            const SizedBox(height: AppSpacing.space5),
            ProposalMessageCard(message: proposal.message!),
          ],

          // Discount info
          if (proposal.hasDiscount) ...[
            const SizedBox(height: AppSpacing.space5),
            _buildDiscountSection(proposal),
          ],

          // Subscription history
          const SizedBox(height: AppSpacing.space5),
          SubscriptionHistorySection(studentId: proposal.studentId),

          // Payment info
          if (proposal.status == ProposalStatus.pending) ...[
            const SizedBox(height: AppSpacing.space5),
            _buildPaymentInfo(proposal),
          ],

          // Waiting card
          if (proposal.status == ProposalStatus.paymentNotified) ...[
            const SizedBox(height: AppSpacing.space5),
            ProposalWaitingCard(onContactTapped: () {}),
          ],

          // Bottom spacing for action bar
          if (proposal.canRespond) const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildRenewalHeader(
    String teacherName,
    SubscriptionProposal proposal,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccentSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.paperAccentSoft),
            child: const Icon(
              Icons.autorenew,
              size: 24,
              color: AppColors.paperAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.renewalProposedByFormat(teacherName),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                if (proposal.canRespond)
                  Text(
                    proposal.formattedExpiration,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          proposal.timeUntilExpiration.inDays < 2
                              ? AppColors.paperAccent
                              : AppColors.inkSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOptions(SubscriptionProposal proposal) {
    return Column(
      children:
          proposal.allTemplateIds.map((templateId) {
            final templateAsync = ref.watch(
              subscriptionTemplateProvider(templateId),
            );
            final isSelected = _selectedTemplateId == templateId;
            final isRecommended = proposal.isRecommended(templateId);

            return templateAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.inkTertiary),
                    const SizedBox(width: AppSpacing.space2),
                    Text(AppStrings.loadDataFailed, style: AppTypography.bodySmall.copyWith(color: AppColors.inkSecondary)),
                  ],
                ),
              ),
              data: (template) {
                if (template == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: _buildTemplateOption(
                    template,
                    isSelected: isSelected,
                    isRecommended: isRecommended,
                    onTap:
                        () => setState(() {
                          _selectedTemplateId = templateId;
                        }),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildTemplateOption(
    SubscriptionTemplate template, {
    required bool isSelected,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paperAccentSoft : AppColors.paper,
          border: Border.all(
            color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkQuaternary,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.paperAccent,
                          ),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: AppSpacing.space1),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paperAccentSoft,
                          ),
                          child: Text(
                            AppStrings.templateRecommendedBadge,
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.paperAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    template.summaryText,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              template.formattedPrice,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateDetails() {
    if (_selectedTemplateId == null) return const SizedBox.shrink();

    final templateAsync = ref.watch(
      subscriptionTemplateProvider(_selectedTemplateId!),
    );

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorStateWidget(title: AppStrings.loadDataFailed),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return ProposalDetailsCard(template: template);
      },
    );
  }

  Widget _buildSameAsPreviousHint() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.08)),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space2),
          Text(
            AppStrings.renewalSameAsPreviousHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(SubscriptionProposal proposal) {
    final effectiveId = _selectedTemplateId ?? proposal.effectiveTemplateId;
    final templateAsync = ref.watch(subscriptionTemplateProvider(effectiveId));

    return templateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => ErrorStateWidget(title: AppStrings.loadDataFailed),
      data: (template) {
        if (template == null) return const SizedBox.shrink();
        return ProposalDiscountCard(proposal: proposal, template: template);
      },
    );
  }

  Widget _buildPaymentInfo(SubscriptionProposal proposal) {
    final teacherProfileAsync = ref.watch(
      teacherFullProfileProvider(proposal.teacherId),
    );

    return teacherProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const ProposalPaymentInfoCard(),
      data:
          (profile) => ProposalPaymentInfoCard(
            bankAccount: profile?.defaultBankAccount,
            bankAccounts: profile?.bankAccounts ?? [],
          ),
    );
  }

  Widget _buildBottomActions(SubscriptionProposal proposal) {
    final canProceed = !proposal.isMultiChoice || _selectedTemplateId != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary action: accept & pay
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (_isProcessing || !canProceed)
                        ? null
                        : () => _notifyPayment(proposal),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space4,
                  ),
                  shape: RoundedRectangleBorder(),
                ),
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.payment),
                label: const Text(AppStrings.renewalSelectButton),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            // Secondary: reject with snooze
            TextButton(
              onPressed:
                  _isProcessing ? null : () => _showRejectDialog(proposal),
              child: Text(
                AppStrings.renewalDeclineLater,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _notifyPayment(SubscriptionProposal proposal) async {
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);

      if (proposal.isMultiChoice && _selectedTemplateId != null) {
        await notifier.selectTemplate(proposal.id, _selectedTemplateId!);
      }

      await notifier.notifyPayment(proposal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.paymentReminderSent),
            backgroundColor: AppColors.paperOk,
          ),
        );
        ref.invalidate(subscriptionProposalProvider(proposal.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.errorTryAgain),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showRejectDialog(SubscriptionProposal proposal) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => const SkipReasonDialog(),
    );

    if (reason != null && mounted) {
      await _rejectProposal(proposal, reason.isEmpty ? null : reason);
    }
  }

  Future<void> _rejectProposal(
    SubscriptionProposal proposal,
    String? reason,
  ) async {
    setState(() => _isProcessing = true);

    try {
      final notifier = ref.read(subscriptionProposalNotifierProvider.notifier);
      await notifier.reject(proposal.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.renewalDeclineSnackbar)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.errorTryAgain),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
