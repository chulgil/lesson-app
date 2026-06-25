import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../../../../core/widgets/notebook/pencil_primitives.dart';
import '../extensions/user_role_visuals.dart';
import '../providers/auth_provider.dart';
import '../../../home/home_ui_facade.dart' show AppUpdateBanner;
import '../widgets/dev_login_section.dart';
import '../widgets/login_bottom_sheets.dart';

const _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '',
);
const _googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '',
);

/// Login screen — Notebook × Score 디자인.
/// 스펙: docs/specs/design/notebook/README.md
/// 레퍼런스: design-plan/hybrid/login.jsx
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  /// Reusable GoogleSignIn instance — constructed once, reused on re-taps.
  /// Avoids stale native state that causes the picker to not reopen after
  /// the user cancels/closes the OAuth popup (Bug #726 fix).
  GoogleSignIn? _googleSignIn;

  GoogleSignIn _getGoogleSignIn() {
    return _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: _googleIosClientId.isNotEmpty ? _googleIosClientId : null,
      serverClientId: _googleServerClientId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // DEV accounts visibility follows the centralized runtime data mode.
    final showDevAccounts = ref.watch(mockDataModeProvider);

    // Show feedback when auto-login fails with a server/network error (#866).
    // Distinguishes between "no token" (silent) and "server unavailable" (toast).
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthUnauthenticated &&
          next.reason != AuthUnauthenticatedReason.none &&
          mounted) {
        final message =
            next.reason == AuthUnauthenticatedReason.networkError
                ? AppStrings.authLoginNetworkError
                : AppStrings.authAutoLoginServerError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    });

    return NotebookScreenScaffold(
      body: PaperScaffold(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.space2),
                    const NotebookMasthead(
                      eyebrow: 'ESTD. MMXXVI',
                      meta: 'SEOUL · KOREA',
                    ),
                    const Spacer(flex: 2),
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.space6),
                    // 앱 업데이트 배너 (로그인 전 표시)
                    const AppUpdateBanner(),
                    const SizedBox(height: AppSpacing.space4),
                    _buildSocialButtons(context),
                    // DEV accounts only in mock mode (hidden in beta/production)
                    if (showDevAccounts) ...[
                      const SizedBox(height: AppSpacing.space6),
                      _buildDevAccountsSection(),
                    ],
                    const Spacer(flex: 3),
                    _buildFooter(context),
                    const SizedBox(height: AppSpacing.space4),
                  ],
                ),
              ),
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
        // Ornament ❦ ❦ ❦
        Text('\u2766 \u2766 \u2766', style: NotebookTypography.splashOrnament),
        const SizedBox(height: AppSpacing.space4),

        // "A handbook for" eyebrow (italic, uppercase)
        Text(
          'A HANDBOOK FOR',
          style: NotebookTypography.mastheadLabel.copyWith(letterSpacing: 3),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Main title "Lessonaza" — Playfair 56
        Text(
          'Lessonaza',
          style: NotebookTypography.displayMassive.copyWith(height: 1),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Pencil underline
        const PencilUnderline(
          width: 160,
          color: AppColors.paperAccent,
          strokeWidth: 2.2,
        ),
        const SizedBox(height: AppSpacing.space3),

        // Italic serif slogan
        Text(
          '선생님을 위한 레슨 노트.',
          style: NotebookTypography.fine.copyWith(
            color: AppColors.inkSecondary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space5),

        // Handwritten sub-note
        Text(
          '— 시작하시겠어요?',
          style: NotebookTypography.hand.copyWith(color: AppColors.paperPencil),
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
        _NotebookAuthBtn(
          label: 'Google 계정으로 시작',
          primary: true,
          onTap: () => _handleGoogleLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),
        _NotebookAuthBtn(
          label: 'Kakao로 시작',
          onTap: null, // #118: 준비중 — NO-OP 제거
          comingSoonBadge: AppStrings.authComingSoonBadge,
        ),
        const SizedBox(height: AppSpacing.space3),
        _NotebookAuthBtn(
          label: 'Apple 계정으로 시작',
          onTap: null, // #118: 준비중 — NO-OP 제거
          comingSoonBadge: AppStrings.authComingSoonBadge,
        ),
        const SizedBox(height: AppSpacing.space5),
        GestureDetector(
          onTap: () {
            // Parent login is a mock test-scenario picker (no real OAuth wired).
            // In real mode it must not grant unauthenticated access to parentHome.
            if (ref.read(mockDataModeProvider)) {
              showParentLoginSheet(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.authParentLoginNotReady),
                ),
              );
            }
          },
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
        Container(
          height: 1,
          color: AppColors.ink.withValues(alpha: 0.25),
          margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        ),
        Text(
          'TERMS · PRIVACY · MMXXVI',
          style: NotebookTypography.metaMono.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Login handlers ────────────────────────────────────────────────

  Future<void> _handleDevLogin({
    required String email,
    required String role,
    String? name,
  }) async {
    if (_isLoading) return;

    // Switch to mock mode for dev accounts
    ref.read(dataModeProvider.notifier).setMockMode(true);

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
      // Dev-login failed — revert mock mode so real auth paths are unaffected.
      ref.read(dataModeProvider.notifier).setMockMode(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.authLoginFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
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
    if (_isLoading) return;

    if (_googleServerClientId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.authGoogleNotConfigured),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Switch to remote mode for real OAuth
      ref.read(dataModeProvider.notifier).setMockMode(false);

      // Reuse the single GoogleSignIn instance. Clear any stale session first
      // so that closing/cancelling the popup and re-tapping always reopens the
      // account picker (Bug #726 fix).
      final googleSignIn = _getGoogleSignIn();
      await googleSignIn.signOut();
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
      } else if (authState is AuthNeedsRole ||
          authState is AuthNeedsOnboarding) {
        // 정책: phone_verification_policy.md §2.3 — 약관 동의는 별도 페이지
        // 없이 RoleSelectScreen 안에 인라인 통합. 신규 가입(AuthNeedsRole)
        // 도 곧바로 roleSelect 로 이동.
        context.go(AppRoutes.roleSelect);
      }
    } catch (e) {
      if (context.mounted) {
        final message = _loginErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Maps caught exceptions to user-facing snackbar messages (#866).
  ///
  /// NetworkException → 연결 오류 / ServerException(5xx) → 서버 오류
  /// UnauthorizedException(401) → 인증 실패 / 기타 → 일반 실패.
  String _loginErrorMessage(Object e) {
    if (e is NetworkException) return AppStrings.authLoginNetworkError;
    if (e is ServerException) return AppStrings.authLoginServerError;
    if (e is UnauthorizedException) return AppStrings.authLoginUnauthorized;
    return AppStrings.authLoginFailed;
  }
}
// #118: _handleKakaoLogin / _handleAppleLogin 제거 — NO-OP snackbar 금지 (ux-rules.md)

// ─────────────────────────────────────────────────────────────────
// Notebook × Score auth button — HBAuthBtn 레퍼런스 이식.
// primary=true: ink background + paper text (Google).
// primary=false: transparent + ink border (Kakao, Apple).
// 아이콘 없음, 직각 모서리, Playfair Display 15/600/letterSpacing 1.
// ─────────────────────────────────────────────────────────────────
class _NotebookAuthBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback? onTap; // #118: nullable — null = disabled (준비중)
  final String? comingSoonBadge; // #118: 준비중 배지 텍스트

  const _NotebookAuthBtn({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.comingSoonBadge,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final bg = primary ? AppColors.ink : Colors.transparent;
    final fg =
        isDisabled
            ? AppColors.inkTertiary
            : (primary ? AppColors.paper : AppColors.ink);
    final borderColor = isDisabled ? AppColors.inkTertiary : AppColors.ink;
    final borderWidth = primary ? 1.0 : 1.2;

    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: NotebookTypography.buttonLabelSerif.copyWith(
            color: fg,
            height: 1.1,
          ),
        ),
      ),
    );

    if (comingSoonBadge == null) return button;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        button,
        Positioned(
          top: 6,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.inkTertiary, // §1.3.1 각진 원칙 — BorderRadius.zero
            ),
            child: Text(
              comingSoonBadge!,
              style: NotebookTypography.metaMono.copyWith(
                color: AppColors.paper,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
