import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';

/// 12시간 이내 강사 취소 정책 안내 배너 (G16).
///
/// 강사가 12h 이내에 레슨을 취소할 때 노출. 자동 처리되는 항목을 명시한다:
/// - 학생 변경권 +1 자동 적립
/// - 사과 카톡 자동 발송
/// - 학원 관리자 알림 (ownership=academy 한정)
/// - 보강은 강사가 직접 안내
///
/// 12h 초과면 `SizedBox.shrink()` 반환.
class TeacherCancelPolicyBanner extends StatelessWidget {
  /// 레슨 시작까지 남은 시간 (시간 단위).
  final double hoursUntilLesson;

  /// `academy` 일 때 학원 관리자 알림 항목 노출.
  final bool isAcademyOwnership;

  /// 학생에게 전송되는 추가 시간 안내 문구. null 이면 기본값 사용.
  final String? compensationMessage;

  const TeacherCancelPolicyBanner({
    super.key,
    required this.hoursUntilLesson,
    this.isAcademyOwnership = false,
    this.compensationMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (hoursUntilLesson > 12) {
      return const SizedBox.shrink();
    }

    final message =
        compensationMessage ?? AppStrings.teacherCancelExtraMinutesDefault;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.paperAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                NotebookGlyph.referenceMark,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paperAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.teacherCancelWithin12hTitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paperAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          _bulletLine(AppStrings.teacherCancelGrantsCredit),
          _bulletLine(AppStrings.teacherCancelSendsApology),
          if (isAcademyOwnership)
            _bulletLine(AppStrings.teacherCancelNotifyAcademy),
          _bulletLine(AppStrings.teacherCancelTeacherReschedule),
          const SizedBox(height: AppSpacing.space3),
          Text(
            AppStrings.teacherCancelExtraMinutesLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            '"$message"',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            NotebookGlyph.bullet,
            style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
