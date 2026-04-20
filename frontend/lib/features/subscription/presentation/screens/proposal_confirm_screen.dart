import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_utils.dart';
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
    this.teacherName = '선생님', // 🆕 Default value
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

    return Scaffold(
      appBar: AppBar(title: const Text('입금 확인'), centerTitle: true),
      body: proposalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
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
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '입금 확인 대기 중인 제안이 없습니다',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '학생이 입금 완료를 알리면 여기에 표시됩니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
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
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),

              // Student name
              Expanded(
                child: studentAsync.when(
                  loading: () => const Text('로딩중...'),
                  error: (e, st) => const Text('학생 정보 오류'),
                  data: (student) {
                    if (student == null) return const Text('알 수 없는 학생');
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            student.name[0],
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
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
                                '입금 알림: ${_formatDateTime(proposal.paymentNotifiedAt)}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiaryLight,
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
            error: (_, __) => const Text('오류가 발생했습니다.'),
            data: (template) {
              if (template == null) return const Text('템플릿을 찾을 수 없습니다');
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
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
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
                  '${template.totalLessons}회 · ${template.lessonDurationMinutes}분 · ${template.formattedValidity}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
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
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
              Text(
                _formatPrice(price),
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.primary,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('입금 미확인'),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child:
                isProcessing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('입금 확인 → 수강권 발급'),
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
            content: Text('수강권이 발급되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );

        // Refresh the list
        ref.invalidate(awaitingConfirmationProposalsProvider(widget.teacherId));
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
          (context) => AlertDialog(
            title: const Text('입금 미확인'),
            content: const Text('입금 내역을 확인할 수 없습니다.\n학생에게 확인 요청 메시지를 보내시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('메시지 보내기'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      // TODO: Send inquiry message notification
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('확인 요청 메시지를 보냈습니다')));
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }

  String _formatPrice(int price) => price.toKoreanWon;
}
