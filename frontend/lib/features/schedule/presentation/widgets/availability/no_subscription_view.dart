import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../subscription/subscription_facade.dart';

/// View shown when a student tries to book a regular lesson without an active subscription.
///
/// This view explains that a subscription is required and provides options to:
/// - View pending subscription proposals
/// - Request a subscription from the teacher
class NoSubscriptionView extends ConsumerWidget {
  final String studentId;
  final String teacherId;
  final String teacherName;
  final String instrument;

  const NoSubscriptionView({
    super.key,
    required this.studentId,
    required this.teacherId,
    required this.teacherName,
    required this.instrument,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check for pending proposals
    final pendingProposalsAsync = ref.watch(
      pendingStudentProposalsProvider(studentId),
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_outlined,
                size: 48,
                color: AppColors.paperAccent,
              ),
            ),

            const SizedBox(height: AppSpacing.space6),

            // Notebook × Score: 빈 상태 헤드라인 3축 통과 (§7.89) — Playfair 승격.
            Text(
              '수강권이 필요합니다',
              style: NotebookTypography.sectionTitle,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.space3),

            // Description
            Text(
              '정기 레슨을 예약하려면\n먼저 수강권을 등록해야 합니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.space8),

            // Pending proposals section
            pendingProposalsAsync.when(
              data: (proposals) {
                // Filter proposals from this teacher
                final teacherProposals =
                    proposals.where((p) => p.teacherId == teacherId).toList();

                if (teacherProposals.isEmpty) {
                  return _buildNoProposalContent(context);
                }

                return _buildPendingProposalContent(
                  context,
                  teacherProposals.first.id,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => _buildNoProposalContent(context),
            ),

            const SizedBox(height: AppSpacing.space6),

            // Flow explanation
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.paperDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '정기 레슨 등록 순서',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  _buildFlowStep(1, '선생님이 수강권 제안'),
                  _buildFlowStep(2, '학생이 수강권 선택 및 결제'),
                  _buildFlowStep(3, '선생님이 입금 확인 후 발급'),
                  _buildFlowStep(4, '레슨 시간 선택', isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProposalContent(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.ink, size: 20),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  '선생님에게 수강권 제안을 요청해 주세요.\n체험 레슨 후 선생님이 수강권을 제안합니다.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('돌아가기'),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingProposalContent(BuildContext context, String proposalId) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paperOk.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.paperOk.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.mail_outline, color: AppColors.paperOk, size: 20),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  '$teacherName 선생님이 수강권을 제안했습니다!\n제안을 확인하고 결제해 주세요.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.paperOk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              context.push(
                AppRoutes.proposalDetail.replaceAll(':id', proposalId),
              );
            },
            icon: const Icon(Icons.card_membership),
            label: const Text('수강권 제안 확인하기'),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowStep(int number, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.caption.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          if (number == 4)
            Text(
              '← 현재 단계',
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
