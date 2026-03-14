import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../search/presentation/providers/teacher_search_provider.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('수강권 갱신 제안'),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : proposalAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
              data: (proposal) {
                if (proposal == null) {
                  return const Center(child: Text('제안을 찾을 수 없습니다'));
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
    final teacherName = teacherAsync.whenOrNull(
          data: (profile) => profile?.name,
        ) ??
        '선생님';

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
              '수강권을 선택하세요',
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
          if (proposal.canRespond)
            const SizedBox(height: AppSpacing.space8),
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
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.autorenew,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teacherName이 수강권 갱신을 제안했어요',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                if (proposal.canRespond)
                  Text(
                    proposal.formattedExpiration,
                    style: AppTypography.bodySmall.copyWith(
                      color: proposal.timeUntilExpiration.inDays < 2
                          ? AppColors.warning
                          : AppColors.textSecondaryLight,
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
      children: proposal.allTemplateIds.map((templateId) {
        final templateAsync = ref.watch(
          subscriptionTemplateProvider(templateId),
        );
        final isSelected = _selectedTemplateId == templateId;
        final isRecommended = proposal.isRecommended(templateId);

        return templateAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (template) {
            if (template == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTemplateOption(
                template,
                isSelected: isSelected,
                isRecommended: isRecommended,
                onTap: () => setState(() {
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
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
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
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
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '추천',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
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
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              template.formattedPrice,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.primary,
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
      error: (_, __) => const SizedBox.shrink(),
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
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: AppColors.info),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '지난번과 동일한 수강권입니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.info,
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
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
      data: (profile) => ProposalPaymentInfoCard(
        bankAccount: profile?.bankAccount,
      ),
    );
  }

  Widget _buildBottomActions(SubscriptionProposal proposal) {
    final canProceed =
        !proposal.isMultiChoice || _selectedTemplateId != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                onPressed: (_isProcessing || !canProceed)
                    ? null
                    : () => _notifyPayment(proposal),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: const Text('수강권 선택하기'),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            // Secondary: reject with snooze
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => _showRejectDialog(proposal),
              child: Text(
                '나중에 할게요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
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
      final notifier = ref.read(
        subscriptionProposalNotifierProvider.notifier,
      );

      if (proposal.isMultiChoice && _selectedTemplateId != null) {
        await notifier.selectTemplate(proposal.id, _selectedTemplateId!);
      }

      await notifier.notifyPayment(proposal.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('입금 알림을 보냈습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(subscriptionProposalProvider(proposal.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
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
      final notifier = ref.read(
        subscriptionProposalNotifierProvider.notifier,
      );
      await notifier.reject(proposal.id, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('다음에 다시 안내해 드릴게요')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
