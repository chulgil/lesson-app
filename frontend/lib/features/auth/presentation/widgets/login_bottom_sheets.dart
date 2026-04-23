import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import 'parent_login_option.dart';
import 'role_option_card.dart';

/// Shows the parent login bottom sheet with social login options.
void showParentLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXLarge),
      ),
    ),
    isScrollControlled: true,
    builder:
        (sheetContext) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                const BottomSheetHandle(margin: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.space4),

                // Parent icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  ),
                  child: const Center(
                    child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),

                // Notebook × Score §7.27: 바텀시트 제목 Playfair.
                Text('학부모 로그인', style: NotebookTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '자녀의 레슨과 연습을 확인하세요',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.space3),

                // Social login buttons for parent with test scenarios
                ParentLoginOption(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google로 계속하기',
                  description: '기존 학부모 (자녀 등록됨)',
                  backgroundColor: AppColors.googleBackground,
                  textColor: AppColors.ink,
                  borderColor: AppColors.inkQuaternary,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.parentHome);
                  },
                ),
                const SizedBox(height: AppSpacing.space2),

                ParentLoginOption(
                  icon: Icons.chat_bubble_rounded,
                  label: '카카오로 계속하기',
                  description: '기존 학부모 (자녀 없음)',
                  backgroundColor: AppColors.kakaoBackground,
                  textColor: AppColors.ink,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.parentHome);
                  },
                ),
                const SizedBox(height: AppSpacing.space2),

                ParentLoginOption(
                  icon: Icons.apple_rounded,
                  label: 'Apple로 계속하기',
                  description: '신규 가입 → 초대코드 입력',
                  backgroundColor: AppColors.appleBackground,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(AppRoutes.parentInviteCode);
                  },
                ),

                const SizedBox(height: AppSpacing.space3),
              ],
            ),
          ),
        ),
  );
}

/// Shows the role selection bottom sheet (teacher vs student).
void showRoleSelectSheet(
  BuildContext context, {
  String authProvider = 'google',
  required void Function(String role) onRoleSelected,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXLarge),
      ),
    ),
    builder:
        (dialogContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                const BottomSheetHandle(margin: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.space4),

                // Notebook × Score §7.27: 바텀시트 제목 Playfair.
                Text('역할을 선택하세요', style: NotebookTypography.sectionTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '레슨 앱에서 어떤 역할로 사용하시나요?',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Teacher option
                RoleOptionCard(
                  icon: Icons.school,
                  title: '선생님',
                  description: _getTeacherDescription(authProvider),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    onRoleSelected('teacher');
                  },
                ),

                const SizedBox(height: AppSpacing.space3),

                // Student option
                RoleOptionCard(
                  icon: Icons.person,
                  title: '학생',
                  description: _getStudentDescription(authProvider),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    onRoleSelected('student');
                  },
                ),

                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
  );
}

String _getTeacherDescription(String authProvider) {
  switch (authProvider) {
    case 'google':
      return '기존 선생님 (학생 있음)';
    case 'kakao':
      return '기존 선생님 (학생 없음)';
    case 'apple':
      return '신규 가입 → SMS 인증';
    default:
      return '학생 관리, 레슨 일정, 피드백 작성';
  }
}

String _getStudentDescription(String authProvider) {
  switch (authProvider) {
    case 'google':
      return '기존 학생 (레슨 있음)';
    case 'kakao':
      return '기존 학생 (레슨 없음)';
    case 'apple':
      return '신규 학생 → 초대코드 입력';
    default:
      return '레슨 일정, 연습 기록, 피드백 확인';
  }
}
