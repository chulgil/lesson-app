// R2 #318 — 토큰 기반 공개 학생 요약 화면.
//
// 백엔드 P2 (GET /public/student-summaries/{token}) 가 아직 미연결이라
// 현재 단계에서는 placeholder 텍스트 + 토큰 노출만 표시한다.
// Backend 연결 후 ShareSummaryRepository 를 추가하고 본 화면에서 watch한다.

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';

/// 공개 공유 토큰으로 진입하는 읽기 전용 학생 요약 화면.
///
/// `/student/summary/{token}` 경로 또는 `lessonapp://student/summary/{token}`
/// 딥링크로 진입한다. 인증 없이 접근 가능하며, 백엔드 토큰 발급/만료 정책에
/// 따라 표시 가능 여부가 결정된다.
class StudentSummaryScreen extends StatelessWidget {
  const StudentSummaryScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.studentSummaryAppBarTitle,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.studentSummaryComingSoon,
                style: AppTypography.headingMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space6),
              Text(
                AppStrings.studentSummaryTokenLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              SelectableText(
                token,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
