import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Login screen with social login options
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and Title
              _buildHeader(),

              const Spacer(flex: 2),

              // Social Login Buttons
              _buildSocialButtons(context),

              const SizedBox(height: AppSpacing.space8),

              // Terms and Privacy
              _buildTermsText(context),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.space6),

        // App Name
        Text(
          'Lesson App',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),

        // Slogan
        Text(
          '음악 레슨의 새로운 경험',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Column(
      children: [
        // Google Login
        _SocialLoginButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google로 계속하기',
          backgroundColor: AppColors.googleBackground,
          textColor: AppColors.textPrimaryLight,
          borderColor: AppColors.borderLight,
          onPressed: () => _handleGoogleLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Kakao Login
        _SocialLoginButton(
          icon: Icons.chat_bubble_rounded,
          label: '카카오로 계속하기',
          backgroundColor: AppColors.kakaoBackground,
          textColor: AppColors.textPrimaryLight,
          onPressed: () => _handleKakaoLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Apple Login (iOS only)
        _SocialLoginButton(
          icon: Icons.apple_rounded,
          label: 'Apple로 계속하기',
          backgroundColor: AppColors.appleBackground,
          textColor: Colors.white,
          onPressed: () => _handleAppleLogin(context),
        ),
      ],
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiaryLight,
        ),
        children: [
          const TextSpan(text: '계속하면 '),
          TextSpan(
            text: '이용약관',
            style: TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' 및 '),
          TextSpan(
            text: '개인정보처리방침',
            style: TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: '에 동의하는 것으로 간주됩니다.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  void _handleGoogleLogin(BuildContext context) {
    // TODO: Implement Google login
    _showRoleSelectDialog(context);
  }

  void _handleKakaoLogin(BuildContext context) {
    // TODO: Implement Kakao login
    _showRoleSelectDialog(context);
  }

  void _handleAppleLogin(BuildContext context) {
    // TODO: Implement Apple login
    _showRoleSelectDialog(context);
  }

  void _showRoleSelectDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              Text(
                '역할을 선택하세요',
                style: AppTypography.headingMedium,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '레슨 앱에서 어떤 역할로 사용하시나요?',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Teacher option
              _RoleOptionCard(
                icon: Icons.school,
                title: '선생님',
                description: '학생 관리, 레슨 일정, 피드백 작성',
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.home);
                },
              ),

              const SizedBox(height: AppSpacing.space3),

              // Student option
              _RoleOptionCard(
                icon: Icons.person,
                title: '학생',
                description: '연습 기록, 레슨 일정, 피드백 확인',
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.studentHome);
                },
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// Social login button widget
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: borderColor ?? backgroundColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.button.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
