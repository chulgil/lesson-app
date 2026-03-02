import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

/// Login screen with social login options (mock mode) or dev-login accounts (remote mode).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Remote mode uses scrollable layout (social login + dev accounts)
    if (!EnvironmentConfig.useMockData) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.space6),
                _buildHeader(),
                const SizedBox(height: AppSpacing.space6),
                _buildSocialButtons(context),
                const SizedBox(height: AppSpacing.space6),
                _buildDevLoginAccounts(),
                const SizedBox(height: AppSpacing.space6),
                _buildTermsText(context),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      );
    }

    // Mock mode uses spacer-based layout
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildHeader(),
              const Spacer(flex: 2),
              _buildSocialButtons(context),
              const SizedBox(height: AppSpacing.space8),
              _buildTermsText(context),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dev Login (Remote mode) ──────────────────────────────────────

  Widget _buildDevLoginAccounts() {
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
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              'DEV MODE — 테스트 계정 선택',
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // ── Teacher accounts ──
        _DevSectionHeader(label: '선생님', color: AppColors.primary),
        const SizedBox(height: AppSpacing.space2),
        _DevAccountCard(
          emoji: '👩‍🏫',
          name: '박미연',
          description: '학생 3명, 레슨/구독 관리',
          color: AppColors.primary,
          isLoading: _isLoading,
          onTap:
              () => _handleDevLogin(
                email: 'minyeon@example.com',
                role: 'teacher',
                name: '박미연',
              ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // ── Student accounts ──
        _DevSectionHeader(label: '학생', color: AppColors.secondary),
        const SizedBox(height: AppSpacing.space2),
        _DevAccountCard(
          emoji: '🎻',
          name: '김소연',
          description: '레슨 6개, 연습 기록, 수강권 보유',
          color: AppColors.secondary,
          isLoading: _isLoading,
          onTap:
              () => _handleDevLogin(
                email: 'soyeon@example.com',
                role: 'student',
                name: '김소연',
              ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _DevAccountCard(
          emoji: '🎻',
          name: '이준호',
          description: '레슨 2개, 초급 학생',
          color: AppColors.secondary,
          isLoading: _isLoading,
          onTap:
              () => _handleDevLogin(
                email: 'junho@example.com',
                role: 'student',
                name: '이준호',
              ),
        ),
        const SizedBox(height: AppSpacing.space2),
        _DevAccountCard(
          emoji: '🎵',
          name: '최유진',
          description: '체험 레슨 1개 (플루트)',
          color: AppColors.secondary.withValues(alpha: 0.7),
          isLoading: _isLoading,
          onTap:
              () => _handleDevLogin(
                email: 'yujin@example.com',
                role: 'student',
                name: '최유진',
              ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // ── Parent accounts ──
        _DevSectionHeader(label: '학부모', color: AppColors.info),
        const SizedBox(height: AppSpacing.space2),
        _DevAccountCard(
          emoji: '👨‍👩‍👧',
          name: '김정수',
          description: '자녀: 김소연 (레슨/연습 확인)',
          color: AppColors.info,
          isLoading: _isLoading,
          onTap:
              () => _handleDevLogin(
                email: 'parent@example.com',
                role: 'parent',
                name: '김정수',
              ),
        ),
      ],
    );
  }

  Future<void> _handleDevLogin({
    required String email,
    required String role,
    String? name,
  }) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .devLogin(email: email, role: role, name: name);

      if (!mounted) return;
      // Navigate to home based on authenticated role
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        context.go(authState.role.homeRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Mock mode (existing social login UI) ─────────────────────────

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
          'Lessonaza',
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

        const SizedBox(height: AppSpacing.space5),

        // Parent login link
        GestureDetector(
          onTap: () => _handleParentLogin(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('👨‍👩‍👧', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  '학부모이신가요?',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
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

  Future<void> _handleGoogleLogin(BuildContext context) async {
    // Mock mode: show role select dialog
    if (EnvironmentConfig.useMockData) {
      _showRoleSelectDialog(context, authProvider: 'google');
      return;
    }

    // Remote mode: actual Google Sign-In
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: EnvironmentConfig.googleServerClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final serverAuthCode = account.serverAuthCode;
      if (serverAuthCode == null) {
        throw Exception('Failed to get server auth code from Google');
      }

      await ref
          .read(authNotifierProvider.notifier)
          .loginWithOAuth(provider: 'google', idToken: serverAuthCode);

      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        context.go(authState.role.homeRoute);
      } else if (authState is AuthNeedsRole) {
        context.go(AppRoutes.roleSelect);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google 로그인 실패: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleKakaoLogin(BuildContext context) {
    _showRoleSelectDialog(context, authProvider: 'kakao');
  }

  void _handleAppleLogin(BuildContext context) {
    _showRoleSelectDialog(context, authProvider: 'apple');
  }

  void _handleParentLogin(BuildContext context) {
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  // Parent icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusLarge,
                      ),
                    ),
                    child: const Center(
                      child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),

                  Text('학부모 로그인', style: AppTypography.headingMedium),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '자녀의 레슨과 연습을 확인하세요',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.space3),

                  // Social login buttons for parent with test scenarios
                  _ParentLoginOption(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Google로 계속하기',
                    description: '기존 학부모 (자녀 등록됨)',
                    backgroundColor: AppColors.googleBackground,
                    textColor: AppColors.textPrimaryLight,
                    borderColor: AppColors.borderLight,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go(AppRoutes.parentHome);
                    },
                  ),
                  const SizedBox(height: AppSpacing.space2),

                  _ParentLoginOption(
                    icon: Icons.chat_bubble_rounded,
                    label: '카카오로 계속하기',
                    description: '기존 학부모 (자녀 없음)',
                    backgroundColor: AppColors.kakaoBackground,
                    textColor: AppColors.textPrimaryLight,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go(AppRoutes.parentHome);
                    },
                  ),
                  const SizedBox(height: AppSpacing.space2),

                  _ParentLoginOption(
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

  void _showRoleSelectDialog(
    BuildContext context, {
    String authProvider = 'google',
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),

                  Text('역할을 선택하세요', style: AppTypography.headingMedium),
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
                    description: _getTeacherDescription(authProvider),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _handleTeacherLogin(context, authProvider);
                    },
                  ),

                  const SizedBox(height: AppSpacing.space3),

                  // Student option
                  _RoleOptionCard(
                    icon: Icons.person,
                    title: '학생',
                    description: _getStudentDescription(authProvider),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _handleStudentLogin(context, authProvider);
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

  void _handleStudentLogin(BuildContext context, String authProvider) {
    switch (authProvider) {
      case 'google':
        context.go(AppRoutes.studentHome);
        break;
      case 'kakao':
        context.go(AppRoutes.studentHome);
        break;
      case 'apple':
        context.go(AppRoutes.studentInviteCode);
        break;
      default:
        context.go(AppRoutes.studentHome);
    }
  }

  void _handleTeacherLogin(BuildContext context, String authProvider) {
    switch (authProvider) {
      case 'google':
        context.go(AppRoutes.home);
        break;
      case 'kakao':
        context.go(AppRoutes.home);
        break;
      case 'apple':
        context.go(AppRoutes.teacherPhoneVerification);
        break;
      default:
        context.go(AppRoutes.home);
    }
  }
}

/// Section header for grouping dev accounts by role
class _DevSectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _DevSectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Dev account card for remote mode login
class _DevAccountCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _DevAccountCard({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          color: color.withValues(alpha: 0.04),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(Icons.chevron_right, color: color, size: 20),
          ],
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
            Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
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
          side: BorderSide(color: borderColor ?? backgroundColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: AppSpacing.space2),
            Text(label, style: AppTypography.button.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}

/// Parent login option button with description (for test scenarios)
class _ParentLoginOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ParentLoginOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor ?? backgroundColor, width: 1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.button.copyWith(color: textColor),
                  ),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textColor.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
