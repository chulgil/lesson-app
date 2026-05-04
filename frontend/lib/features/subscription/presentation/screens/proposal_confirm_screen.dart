import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
import '../providers/subscription_providers.dart';

/// Screen for teachers to confirm payments and issue subscriptions.
class ProposalConfirmScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final String teacherName; // 🆕 For notification

  const ProposalConfirmScreen({
    super.key,
    required this.teacherId,
    this.teacherName = AppStrings.teacher, // 🆕 Default value
  });

  @override
  ConsumerState<ProposalConfirmScreen> createState() =>
      _ProposalConfirmScreenState();
}

class _ProposalConfirmScreenState extends ConsumerState<ProposalConfirmScreen> {
  String? _processingProposalId;

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(
      awaitingConfirmationProposalsProvider(widget.teacherId),
    );

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: const Text(AppStrings.paymentConfirm),
        centerTitle: true,
      ),
      body: proposalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text('${AppStrings.errorOccurred}.')),
        data: (proposals) {
          if (proposals.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: proposals.length,
            itemBuilder: (context, index) {
              return _buildProposalCard(proposals[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            AppStrings.proposalConfirmEmptyTitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.proposalConfirmEmptyBody,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(SubscriptionProposal proposal) {
    final templateAsync = ref.watch(
      subscriptionTemplateProvider(proposal.templateId),
    );
    final studentAsync = ref.watch(studentProvider(proposal.studentId));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with student info
          Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.paperAccent),
              ),
              const SizedBox(width: AppSpacing.space2),

              // Student name
              Expanded(
                child: studentAsync.when(
                  loading: () => const Text(AppStrings.loadingText),
                  error: (e, st) => const Text(AppStrings.studentInfoError),
                  data: (student) {
                    if (student == null) {
                      return const Text(AppStrings.unknownStudent);
                    }
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.paperAccentSoft,
                          child: Text(
                            student.name[0],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.paperAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                AppStrings.proposalPaymentNotificationFormat(
                                  _formatDateTime(proposal.paymentNotifiedAt),
                                ),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.inkTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Template info
          templateAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text('${AppStrings.errorOccurred}.'),
            data: (template) {
              if (template == null) {
                return const Text(AppStrings.templateNotFound);
              }
              return _buildTemplateInfo(template, proposal);
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // Action buttons
          templateAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
            data: (template) {
              if (template == null) return const SizedBox.shrink();
              return _buildActionButtons(proposal, template);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateInfo(
    SubscriptionTemplate template,
    SubscriptionProposal proposal,
  ) {
    final price =
        proposal.hasDiscount
            ? template.price - (proposal.discountAmount ?? 0)
            : template.price;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.proposalTemplateSummaryFormat(
                    template.totalLessons,
                    template.lessonDurationMinutes,
                    template.formattedValidity,
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (proposal.hasDiscount) ...[
                Text(
                  template.formattedPrice,
                  style: AppTypography.caption.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
              Text(
                _formatPrice(price),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    SubscriptionProposal proposal,
    SubscriptionTemplate template,
  ) {
    final isProcessing = _processingProposalId == proposal.id;

    return Row(
      children: [
        // Inquiry button
        Expanded(
          child: OutlinedButton(
            onPressed: isProcessing ? null : () => _showInquiryDialog(proposal),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
            ),
            child: const Text(AppStrings.paymentUnverifiedAction),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        // Confirm button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                isProcessing ? null : () => _confirmPayment(proposal, template),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
            ),
            child:
                isProcessing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text(AppStrings.paymentVerifyToIssueButton),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmPayment(
    SubscriptionProposal proposal,
    SubscriptionTemplate template,
  ) async {
    setState(() {
      _processingProposalId = proposal.id;
    });

    try {
      // 1. Create subscription
      final now = DateTime.now();
      final subscription = Subscription(
        id: const Uuid().v4(),
        studentId: proposal.studentId,
        membershipId:
            'membership_${proposal.studentId}', // TODO: Get actual membership
        type: SubscriptionType.package,
        totalLessons: template.totalLessons,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(Duration(days: template.validityDays)),
        amount:
            proposal.hasDiscount
                ? template.price - (proposal.discountAmount ?? 0)
                : template.price,
        status: SubscriptionStatus.active,
        createdAt: now,
        bonusCount: 0,
      );

      // Create the subscription (using repository directly for now)
      final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
      final createdSubscription = await subscriptionRepo.create(subscription);

      // 2. Confirm the proposal with the subscription ID
      final proposalNotifier = ref.read(
        subscriptionProposalNotifierProvider.notifier,
      );
      await proposalNotifier.confirmPayment(
        proposal.id,
        createdSubscription.id,
        // 🆕 For notification
        teacherName: widget.teacherName,
        templateName: template.name,
        totalLessons: template.totalLessons,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.subscriptionIssuedMessage),
            backgroundColor: AppColors.paperOk,
          ),
        );

        // Refresh the list
        ref.invalidate(awaitingConfirmationProposalsProvider(widget.teacherId));
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
      if (mounted) {
        setState(() {
          _processingProposalId = null;
        });
      }
    }
  }

  Future<void> _showInquiryDialog(SubscriptionProposal proposal) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => NotebookAlertDialog(
            title: AppStrings.paymentUnverifiedAction,
            content: const Text(AppStrings.paymentInquiryDialogBody),
            cancelLabel: AppStrings.cancel,
            onCancel: () => Navigator.pop(context, false),
            confirmLabel: AppStrings.sendMessage,
            onConfirm: () => Navigator.pop(context, true),
          ),
    );

    if (result == true && mounted) {
      // TODO: Send inquiry message notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.inquiryMessageSent)),
      );
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return AppStrings.timeAgoMinutes(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return AppStrings.timeAgoHours(diff.inHours);
    } else {
      return AppStrings.timeAgoDays(diff.inDays);
    }
  }

  String _formatPrice(int price) => price.toKoreanWon;
}
