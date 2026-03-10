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
import '../widgets/dev_login_section.dart';
import '../widgets/login_bottom_sheets.dart';
import '../widgets/social_login_button.dart';

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
                DevLoginSection(
                  isLoading: _isLoading,
                  onDevLogin: ({
                    required String email,
                    required String role,
                    String? name,
                  }) => _handleDevLogin(email: email, role: role, name: name),
                ),
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

  // ── Common UI builders ────────────────────────────────────────────

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
        SocialLoginButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google로 계속하기',
          backgroundColor: AppColors.googleBackground,
          textColor: AppColors.textPrimaryLight,
          borderColor: AppColors.borderLight,
          onPressed: () => _handleGoogleLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Kakao Login
        SocialLoginButton(
          icon: Icons.chat_bubble_rounded,
          label: '카카오로 계속하기',
          backgroundColor: AppColors.kakaoBackground,
          textColor: AppColors.textPrimaryLight,
          onPressed: () => _handleKakaoLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Apple Login (iOS only)
        SocialLoginButton(
          icon: Icons.apple_rounded,
          label: 'Apple로 계속하기',
          backgroundColor: AppColors.appleBackground,
          textColor: Colors.white,
          onPressed: () => _handleAppleLogin(context),
        ),

        const SizedBox(height: AppSpacing.space5),

        // Parent login link
        GestureDetector(
          onTap: () => showParentLoginSheet(context),
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

  // ── Login handlers ────────────────────────────────────────────────

  Future<void> _handleGoogleLogin(BuildContext context) async {
    // Mock mode: show role select dialog
    if (EnvironmentConfig.useMockData) {
      showRoleSelectSheet(
        context,
        authProvider: 'google',
        onRoleSelected: (role) => _handleRoleLogin(context, role, 'google'),
      );
      return;
    }

    // Remote mode: actual Google Sign-In
    if (_isLoading) return;

    // Guard: check if Google OAuth credentials are configured
    if (EnvironmentConfig.googleServerClientId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google 로그인이 아직 설정되지 않았습니다. 테스트 계정을 사용해주세요.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final iosClientId = EnvironmentConfig.googleIosClientId;
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
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
        context.go(AppRoutes.termsAgreement);
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
    if (!EnvironmentConfig.useMockData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카카오 로그인은 준비 중입니다. 테스트 계정을 사용해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showRoleSelectSheet(
      context,
      authProvider: 'kakao',
      onRoleSelected: (role) => _handleRoleLogin(context, role, 'kakao'),
    );
  }

  void _handleAppleLogin(BuildContext context) {
    if (!EnvironmentConfig.useMockData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple 로그인은 준비 중입니다. 테스트 계정을 사용해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showRoleSelectSheet(
      context,
      authProvider: 'apple',
      onRoleSelected: (role) => _handleRoleLogin(context, role, 'apple'),
    );
  }

  void _handleRoleLogin(BuildContext context, String role, String authProvider) {
    if (role == 'teacher') {
      _handleTeacherLogin(context, authProvider);
    } else {
      _handleStudentLogin(context, authProvider);
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
