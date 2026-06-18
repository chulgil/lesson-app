import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_proposal.dart';
import '../../domain/entities/subscription_template.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../extensions/subscription_template_visuals.dart';
import '../../../students/students_facade.dart';
import '../providers/subscription_issue_flow_provider.dart';
import '../providers/subscription_proposal_providers.dart';
import '../providers/subscription_template_providers.dart';
import '../providers/subscription_providers.dart';

/// Screen for teachers to confirm payments and issue subscriptions.
///
/// Supports both single confirmation (per-card button) and batch confirmation
/// (checkbox selection + bottom action bar) — the latter relieves the "1건씩
/// 수동 확인" burden when deposits pile up at semester start (#771).
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

  /// Proposal ids currently checked for batch confirmation.
  final Set<String> _selectedProposalIds = {};

  /// True while a batch confirmation is running (disables the bar button).
  bool _batchProcessing = false;

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(
      awaitingConfirmationProposalsProvider(widget.teacherId),
    );
    final proposals =
        proposalsAsync.asData?.value ?? const <SubscriptionProposal>[];

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.paymentConfirm),
      bottomNavigationBar: _buildBatchBar(proposals),
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
    // Multi-choice proposals must use the student's selected template
    // (effectiveTemplateId), not the first/base templateId.
    final templateAsync = ref.watch(
      subscriptionTemplateProvider(proposal.effectiveTemplateId),
    );
    final studentAsync = ref.watch(
      subscriptionIssueStudentProvider(proposal.studentId),
    );

    // Multi-choice proposals the student hasn't decided yet can't be issued, so
    // they are excluded from batch selection (checkbox disabled).
    final selectable = !proposal.needsTemplateSelection;
    final isSelected = _selectedProposalIds.contains(proposal.id);

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
          // Header with selection checkbox + student info
          Row(
            children: [
              // Batch selection checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged:
                      selectable
                          ? (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedProposalIds.add(proposal.id);
                              } else {
                                _selectedProposalIds.remove(proposal.id);
                              }
                            });
                          }
                          : null,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),

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
                              // 입금자명(예금주) — 통장 대조용. 학부모 우선, 없으면 학생.
                              Text(
                                AppStrings.paymentDepositorFormat(
                                  _depositorName(student),
                                ),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.inkSecondary,
                                  fontWeight: FontWeight.w600,
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
            error:
                (e, st) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.inkTertiary,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        AppStrings.loadDataFailed,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            data: (template) {
              if (template == null) return const SizedBox.shrink();
              return _buildActionButtons(proposal, template);
            },
          ),
        ],
      ),
    );
  }

  /// Expected depositor (예금주) for bank-transfer matching. Parents usually
  /// transfer on the student's behalf, so prefer the parent name when present.
  String _depositorName(Student student) {
    final parent = student.parentName;
    if (parent != null && parent.trim().isNotEmpty) return parent;
    return student.name;
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

  /// Sticky bottom bar for batch confirmation. Returns null when no selectable
  /// proposal is checked, so the bar only appears on demand.
  Widget? _buildBatchBar(List<SubscriptionProposal> proposals) {
    final selectedCount =
        proposals
            .where(
              (p) =>
                  _selectedProposalIds.contains(p.id) &&
                  !p.needsTemplateSelection,
            )
            .length;
    if (selectedCount == 0) return null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top divider as a standalone line (avoids partial-border paint
          // assertions — see Border non-uniform × strokeAlign lesson).
          Container(height: 0.5, color: AppColors.inkQuaternary),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _batchProcessing ? null : () => _confirmBatch(proposals),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space3,
                  ),
                ),
                child:
                    _batchProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          AppStrings.paymentBatchConfirmAction(selectedCount),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(
    SubscriptionProposal proposal,
    SubscriptionTemplate template,
  ) async {
    // Multi-choice proposal must have a student selection before issuing.
    if (proposal.needsTemplateSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.proposalAwaitingTemplateSelection),
          backgroundColor: AppColors.paperAccent,
        ),
      );
      return;
    }

    setState(() {
      _processingProposalId = proposal.id;
    });

    try {
      await _issueSubscriptionForProposal(proposal, template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.subscriptionIssuedMessage),
            backgroundColor: AppColors.paperOk,
          ),
        );

        // Refresh proposal list + subscription list/detail views so the new
        // subscription appears immediately (create bypasses the notifier).
        ref.invalidate(awaitingConfirmationProposalsProvider(widget.teacherId));
        invalidateSubscriptionListsForStudent(
          ref,
          proposal.studentId,
          teacherId: widget.teacherId,
        );
      }
    } on PhoneVerificationRequiredException catch (_) {
      // #430 G1 §4.3 — E3 게이트. 미인증 선생님이 수강권을 발급하려 할 때
      // 인증 안내 다이얼로그 노출. (orphan cleanup은 헬퍼에서 수행됨)
      if (mounted) {
        await PhoneVerificationGate.show(context);
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

  /// Confirm payment for every selected proposal in one pass. Shows a single
  /// confirmation dialog (money / impact gate), issues each sequentially, and
  /// reports an aggregate result. Aborts the remaining issues if the teacher
  /// needs phone verification.
  Future<void> _confirmBatch(List<SubscriptionProposal> all) async {
    final selected =
        all
            .where(
              (p) =>
                  _selectedProposalIds.contains(p.id) &&
                  !p.needsTemplateSelection,
            )
            .toList();
    if (selected.isEmpty) return;

    // Resolve each template up front so the dialog can show an accurate total.
    final templates = <String, SubscriptionTemplate>{};
    var total = 0;
    for (final p in selected) {
      final template = await ref.read(
        subscriptionTemplateProvider(p.effectiveTemplateId).future,
      );
      if (template == null) continue;
      templates[p.id] = template;
      final discount = p.hasDiscount ? (p.discountAmount ?? 0) : 0;
      final amount =
          (template.price - discount) < 0 ? 0 : (template.price - discount);
      total += amount;
    }
    final issuable =
        selected.where((p) => templates.containsKey(p.id)).toList();
    if (issuable.isEmpty || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => NotebookAlertDialog(
            title: AppStrings.paymentBatchConfirmDialogTitle,
            content: Text(
              AppStrings.paymentBatchConfirmDialogBody(
                issuable.length,
                _formatPrice(total),
              ),
            ),
            cancelLabel: AppStrings.cancel,
            onCancel: () => Navigator.pop(dialogContext, false),
            confirmLabel: AppStrings.paymentBatchIssueConfirm,
            onConfirm: () => Navigator.pop(dialogContext, true),
          ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _batchProcessing = true;
    });

    final succeeded = <SubscriptionProposal>[];
    var failed = 0;
    var needsPhoneVerification = false;

    try {
      for (final proposal in issuable) {
        try {
          await _issueSubscriptionForProposal(
            proposal,
            templates[proposal.id]!,
          );
          succeeded.add(proposal);
        } on PhoneVerificationRequiredException catch (_) {
          // Stop the batch — the teacher must verify before issuing anything
          // more, otherwise every remaining item would fail the same gate.
          needsPhoneVerification = true;
          break;
        } catch (e) {
          failed++;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          for (final p in succeeded) {
            _selectedProposalIds.remove(p.id);
          }
          _batchProcessing = false;
        });
      }
    }

    if (!mounted) return;

    ref.invalidate(awaitingConfirmationProposalsProvider(widget.teacherId));
    for (final p in succeeded) {
      invalidateSubscriptionListsForStudent(
        ref,
        p.studentId,
        teacherId: widget.teacherId,
      );
    }

    if (needsPhoneVerification) {
      await PhoneVerificationGate.show(context);
      return;
    }

    if (failed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.paymentBatchConfirmResultAll(succeeded.length),
          ),
          backgroundColor: AppColors.paperOk,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.paymentBatchConfirmResultPartial(
              succeeded.length,
              failed,
            ),
          ),
          backgroundColor: AppColors.paperAccent,
        ),
      );
    }
  }

  /// Core issue: create a payment-confirmed subscription and confirm the
  /// proposal. Throws on failure (after deactivating the orphan subscription)
  /// so single + batch callers can each render their own UX.
  Future<void> _issueSubscriptionForProposal(
    SubscriptionProposal proposal,
    SubscriptionTemplate template,
  ) async {
    final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
    String? createdSubscriptionId;

    try {
      // Create subscription. Deposit is confirmed here (manual bank transfer
      // only — no PG), so seed payment fields accordingly.
      final now = DateTime.now();
      final discount =
          proposal.hasDiscount ? (proposal.discountAmount ?? 0) : 0;
      // Clamp: a discount larger than the price must not yield a negative
      // amount.
      final amount =
          (template.price - discount) < 0 ? 0 : (template.price - discount);
      // Resolve the student's active membership to attach the subscription to
      // the correct class context. Falls back to the first membership if the
      // student has multiple active memberships.
      final memberships = await ref.read(
        activeStudentMembershipsProvider(proposal.studentId).future,
      );
      final membershipId =
          memberships.isNotEmpty
              ? memberships.first.id
              : 'membership_${proposal.studentId}';

      final subscription = Subscription(
        id: const Uuid().v4(),
        studentId: proposal.studentId,
        membershipId: membershipId,
        type: SubscriptionType.package,
        totalLessons: template.totalLessons,
        usedLessons: 0,
        startDate: now,
        endDate: now.add(Duration(days: template.validityDays)),
        amount: amount,
        originalAmount: discount > 0 ? template.price : null,
        discountAmount: discount > 0 ? discount : null,
        discountReason: discount > 0 ? proposal.discountReason : null,
        status: SubscriptionStatus.active,
        createdAt: now,
        bonusCount: 0,
        paymentConfirmed: true,
        paymentMethod: SubscriptionPaymentMethod.bankTransfer,
        paidAt: now,
        paymentConfirmedAt: now,
      );

      final createdSubscription = await subscriptionRepo.create(subscription);
      createdSubscriptionId = createdSubscription.id;

      // Confirm the proposal with the subscription ID. If this fails the
      // subscription would be orphaned, so the catch below deactivates it.
      final proposalNotifier = ref.read(
        subscriptionProposalNotifierProvider.notifier,
      );
      await proposalNotifier.confirmPayment(
        proposal.id,
        createdSubscription.id,
        teacherName: widget.teacherName,
        templateName: template.name,
        totalLessons: template.totalLessons,
      );
    } catch (e) {
      await _deactivateOrphanSubscription(
        subscriptionRepo,
        createdSubscriptionId,
      );
      rethrow;
    }
  }

  /// Deactivate a subscription that was created but whose proposal confirmation
  /// failed, preventing an orphaned active subscription. There is no hard
  /// delete on the repository, so we mark it expired (inactive).
  Future<void> _deactivateOrphanSubscription(
    SubscriptionRepository repo,
    String? subscriptionId,
  ) async {
    if (subscriptionId == null) return;
    try {
      await repo.updateStatus(subscriptionId, SubscriptionStatus.expired);
    } catch (e) {
      debugPrint('Failed to deactivate orphan subscription: $e');
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
