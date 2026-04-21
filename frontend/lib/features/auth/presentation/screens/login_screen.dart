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
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/dev_login_section.dart';
import '../widgets/login_bottom_sheets.dart';
import '../widgets/social_login_button.dart';

/// Login screen — Notebook × Score 디자인.
/// 스펙: docs/specs/design/notebook/README.md
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final meta =
        'VOL. ${_romanMonth(now.month)} · NO. ${_romanDay(now.day)} · ${_englishMonth(now.month)} MMXXVI';

    if (!EnvironmentConfig.useMockData) {
      // Remote mode — scrollable (social + dev accounts)
      return Scaffold(
        body: PaperScaffold(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.space4),
                  NotebookMasthead(eyebrow: 'LESSONAZA', meta: meta),
                  const SizedBox(height: AppSpacing.space8),
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.space8),
                  _buildSocialButtons(context),
                  const SizedBox(height: AppSpacing.space6),
                  _buildDevAccountsSection(),
                  const SizedBox(height: AppSpacing.space6),
                  _buildFooter(context),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mock mode — spacer-based
    return Scaffold(
      body: PaperScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.space4),
                NotebookMasthead(eyebrow: 'LESSONAZA', meta: meta),
                const Spacer(flex: 2),
                _buildHeader(),
                const Spacer(flex: 2),
                _buildSocialButtons(context),
                const SizedBox(height: AppSpacing.space8),
                _buildFooter(context),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Notebook header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Text('Programme for Login', style: NotebookTypography.mastheadLabel),
        const SizedBox(height: AppSpacing.space3),
        Text('Lessonaza', style: NotebookTypography.masthead),
        const SizedBox(height: AppSpacing.space3),
        Text(
          '— 음악 레슨의 새로운 경험 —',
          style: NotebookTypography.hand.copyWith(
            color: AppColors.paperPencil,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDevAccountsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.ink.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              child: Text(
                'DEV · ACCOUNTS',
                style: NotebookTypography.sectionLabel,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.ink.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        DevLoginSection(
          isLoading: _isLoading,
          onDevLogin:
              ({required String email, required String role, String? name}) =>
                  _handleDevLogin(email: email, role: role, name: name),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Column(
      children: [
        SocialLoginButton(
          icon: Icons.g_mobiledata_rounded,
          label: 'Google로 계속하기',
          backgroundColor: AppColors.googleBackground,
          textColor: AppColors.textPrimaryLight,
          borderColor: AppColors.borderLight,
          onPressed: () => _handleGoogleLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),
        SocialLoginButton(
          icon: Icons.chat_bubble_rounded,
          label: '카카오로 계속하기',
          backgroundColor: AppColors.kakaoBackground,
          textColor: AppColors.textPrimaryLight,
          onPressed: () => _handleKakaoLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),
        SocialLoginButton(
          icon: Icons.apple_rounded,
          label: 'Apple로 계속하기',
          backgroundColor: AppColors.appleBackground,
          textColor: Colors.white,
          onPressed: () => _handleAppleLogin(context),
        ),
        const SizedBox(height: AppSpacing.space5),
        GestureDetector(
          onTap: () => showParentLoginSheet(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            child: Text(
              '학부모이신가요?',
              style: NotebookTypography.hand.copyWith(
                color: AppColors.paperAccent,
                fontSize: 16,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.paperAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text('Fine.', style: NotebookTypography.fine),
        const SizedBox(height: AppSpacing.space3),
        Text.rich(
          TextSpan(
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
            children: [
              const TextSpan(text: '계속하면 '),
              TextSpan(
                text: '이용약관',
                style: TextStyle(
                  color: AppColors.paperAccent,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.paperAccent,
                ),
              ),
              const TextSpan(text: ' 및 '),
              TextSpan(
                text: '개인정보처리방침',
                style: TextStyle(
                  color: AppColors.paperAccent,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.paperAccent,
                ),
              ),
              const TextSpan(text: '에 동의하는 것으로 간주됩니다.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Roman/Month helpers (Notebook meta) ──────────────────────────

  String _romanMonth(int m) =>
      const [
        'I',
        'II',
        'III',
        'IV',
        'V',
        'VI',
        'VII',
        'VIII',
        'IX',
        'X',
        'XI',
        'XII',
      ][(m - 1).clamp(0, 11)];

  String _romanDay(int d) {
    // 1..31 → 간단한 로마숫자 변환. 실패 시 아라비아 숫자.
    if (d < 1 || d > 31) return '$d';
    const ones = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX'];
    const tens = ['', 'X', 'XX', 'XXX'];
    return '${tens[d ~/ 10]}${ones[d % 10]}';
  }

  String _englishMonth(int m) =>
      const [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ][(m - 1).clamp(0, 11)];

  // ── Login handlers ────────────────────────────────────────────────

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
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        context.go(authState.role.homeRoute);
      } else if (authState is AuthNeedsOnboarding) {
        await ref.read(authNotifierProvider.notifier).completeOnboarding();
        if (!mounted) return;
        final updatedState = ref.read(authNotifierProvider);
        if (updatedState is AuthAuthenticated) {
          context.go(updatedState.role.homeRoute);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('로그인 실패. 다시 시도해주세요.'),
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

  Future<void> _handleGoogleLogin(BuildContext context) async {
    if (EnvironmentConfig.useMockData) {
      showRoleSelectSheet(
        context,
        authProvider: 'google',
        onRoleSelected: (role) => _handleRoleLogin(context, role, 'google'),
      );
      return;
    }

    if (_isLoading) return;

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

      if (!context.mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        context.go(authState.role.homeRoute);
      } else if (authState is AuthNeedsRole) {
        context.go(AppRoutes.termsAgreement);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Google 로그인 실패. 다시 시도해주세요.'),
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

  void _handleRoleLogin(
    BuildContext context,
    String role,
    String authProvider,
  ) {
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
