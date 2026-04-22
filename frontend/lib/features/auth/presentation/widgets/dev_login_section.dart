import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'dev_account_widgets.dart';

/// Dev login accounts section shown in remote mode.
/// Displays test accounts grouped by role (teacher, student, parent).
class DevLoginSection extends StatelessWidget {
  final bool isLoading;
  final void Function({
    required String email,
    required String role,
    String? name,
  }) onDevLogin;

  const DevLoginSection({
    super.key,
    required this.isLoading,
    required this.onDevLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              'DEV MODE — 테스트 계정 선택',
              style: AppTypography.caption.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // ── Teacher accounts ──
        DevSectionHeader(label: '선생님', color: AppColors.paperAccent),
        const SizedBox(height: AppSpacing.space2),
        DevAccountCard(
          emoji: '👩‍🏫',
          name: '박미연',
          description: '학생 3명, 레슨/구독 관리',
          color: AppColors.paperAccent,
          isLoading: isLoading,
          onTap:
              () => onDevLogin(
                email: 'minyeon@example.com',
                role: 'teacher',
                name: '박미연',
              ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // ── Student accounts ──
        DevSectionHeader(label: '학생', color: AppColors.secondary),
        const SizedBox(height: AppSpacing.space2),
        DevAccountCard(
          emoji: '🎻',
          name: '김소연',
          description: '레슨 6개, 연습 기록, 수강권 보유',
          color: AppColors.secondary,
          isLoading: isLoading,
          onTap:
              () => onDevLogin(
                email: 'soyeon@example.com',
                role: 'student',
                name: '김소연',
              ),
        ),
        const SizedBox(height: AppSpacing.space2),
        DevAccountCard(
          emoji: '🎻',
          name: '이준호',
          description: '레슨 2개, 초급 학생',
          color: AppColors.secondary,
          isLoading: isLoading,
          onTap:
              () => onDevLogin(
                email: 'junho@example.com',
                role: 'student',
                name: '이준호',
              ),
        ),
        const SizedBox(height: AppSpacing.space2),
        DevAccountCard(
          emoji: '🎵',
          name: '최유진',
          description: '체험 레슨 1개 (플루트)',
          color: AppColors.secondary.withValues(alpha: 0.7),
          isLoading: isLoading,
          onTap:
              () => onDevLogin(
                email: 'yujin@example.com',
                role: 'student',
                name: '최유진',
              ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // ── Parent accounts ──
        DevSectionHeader(label: '학부모', color: AppColors.ink),
        const SizedBox(height: AppSpacing.space2),
        DevAccountCard(
          emoji: '👨‍👩‍👧',
          name: '김정수',
          description: '자녀: 김소연 (레슨/연습 확인)',
          color: AppColors.ink,
          isLoading: isLoading,
          onTap:
              () => onDevLogin(
                email: 'parent@example.com',
                role: 'parent',
                name: '김정수',
              ),
        ),
      ],
    );
  }
}
