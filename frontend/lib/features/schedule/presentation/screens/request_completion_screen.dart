import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// Parameters for the request completion screen.
class RequestCompletionParams {
  final String teacherName;
  final String instrument;
  final LessonRequestType lessonType;
  final List<PreferredTimeSlot> preferredSlots;
  final int duration;

  const RequestCompletionParams({
    required this.teacherName,
    required this.instrument,
    required this.lessonType,
    required this.preferredSlots,
    required this.duration,
  });
}

/// 5-step progress guide shown after successful lesson request submission.
///
/// Naver Booking benchmark: visual step guide after booking completion.
class RequestCompletionScreen extends StatelessWidget {
  final RequestCompletionParams params;

  const RequestCompletionScreen({super.key, required this.params});

  /// Number of progress steps (for testing).
  static int get stepCount => _steps.length;

  static const _steps = [
    _StepData(
      title: AppStrings.requestCompleteTitle,
      description: '선생님에게 요청이 전송되었습니다',
    ),
    _StepData(title: '선생님이 시간 확인', description: '희망 시간을 검토 중입니다'),
    _StepData(title: '시간 확정 후 입금', description: '확정된 시간에 맞춰 입금합니다'),
    _StepData(title: '선생님이 수강권 발급', description: '수강권이 발급되면 알림을 보내드립니다'),
    _StepData(title: '레슨 시작!', description: '첫 레슨을 즐겨보세요'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('신청 완료'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.space4),
            _buildSuccessHeader(),
            const SizedBox(height: AppSpacing.space8),
            _buildStepGuide(),
            const SizedBox(height: AppSpacing.space8),
            _buildRequestSummary(),
            const SizedBox(height: AppSpacing.space8),
            _buildHomeButton(context),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.paperOk,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 40, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.space4),
        // Notebook × Score: 성공 상태 헤드라인 3축 통과 (§7.89) — Playfair 승격.
        Text(
          AppStrings.requestCompleteHeader,
          style: NotebookTypography.sectionTitle.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          '${params.teacherName} 선생님에게 요청을 보냈습니다',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepGuide() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
          Text(
            '진행 단계 가이드',
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isActive = index == 0;
            final isLast = index == _steps.length - 1;
            return _buildStepItem(
              stepNumber: index + 1,
              title: step.title,
              description: step.description,
              isActive: isActive,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required String description,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator column
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.paperAccent : AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isActive
                            ? AppColors.paperAccent
                            : AppColors.scheduleMutedAccent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child:
                      isActive
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : Text(
                            '$stepNumber',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.scheduleMutedAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  color:
                      isActive
                          ? AppColors.paperAccent.withValues(alpha: 0.3)
                          : AppColors.scheduleMutedAccent.withValues(
                            alpha: 0.3,
                          ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        // Step content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isActive
                            ? AppColors.paperAccent
                            : AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space5),
      decoration: BoxDecoration(
        color: AppColors.paper,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
          Text(
            '신청 정보 요약',
            style: NotebookTypography.sectionTitle.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          _buildSummaryRow('선생님', params.teacherName),
          _buildSummaryRow('악기', params.instrument),
          _buildSummaryRow('유형', params.lessonType.label),
          _buildSummaryRow('레슨시간', '${params.duration}분'),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '희망시간',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          ...params.preferredSlots.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.space4,
                bottom: AppSpacing.space1,
              ),
              child: Row(
                children: [
                  Text(
                    '${slot.priority}순위',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(slot.displayLabel, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ),
          // Show empty slots
          ...List.generate(
            3 - params.preferredSlots.length,
            (i) => Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.space4,
                bottom: AppSpacing.space1,
              ),
              child: Row(
                children: [
                  Text(
                    '${params.preferredSlots.length + i + 1}순위',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.scheduleMutedAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '(미선택)',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.scheduleMutedAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Pop back to root (home screen)
          context.go(AppRoutes.home);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paperAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          shape: RoundedRectangleBorder(
          ),
        ),
        child: const Text('메인으로 가기'),
      ),
    );
  }
}

class _StepData {
  final String title;
  final String description;

  const _StepData({required this.title, required this.description});
}
