import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/paper_scaffold.dart';
import '../providers/auth_provider.dart';
import '../widgets/dev_login_section.dart';
import '../widgets/login_bottom_sheets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const SizedBox(height: AppSpacing.space4),
                    const NotebookMasthead(
                      eyebrow: 'ESTD. MMXXVI',
                      meta: 'SEOUL · KOREA',
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.space8),
                    _buildSocialButtons(context),
                    if (EnvironmentConfig.useMockData == false) ...[
                      const SizedBox(height: AppSpacing.space6),
                      _buildDevAccountsSection(),
                    ],
                    const Spacer(),
                    const SizedBox(height: AppSpacing.space6),
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
        Text(
          '\u2766 \u2766 \u2766',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            color: AppColors.inkTertiary,
            letterSpacing: 10,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // "A handbook for" eyebrow (italic, uppercase)
        Text(
          'A HANDBOOK FOR',
          style: GoogleFonts.playfairDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: AppColors.inkSecondary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Main title "Lessonaza" — Playfair 56
        Text(
          'Lessonaza',
          style: GoogleFonts.playfairDisplay(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),

        // Pencil underline
        const _PencilUnderline(
          width: 160,
          color: AppColors.paperAccent,
          strokeWidth: 2.2,
        ),
        const SizedBox(height: AppSpacing.space3),

        // Italic serif slogan
        Text(
          '선생님을 위한 레슨 노트.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: AppColors.inkSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space5),

        // Handwritten sub-note
        Text(
          '— 시작하시겠어요?',
          style: NotebookTypography.hand.copyWith(
            color: AppColors.paperPencil,
            fontSize: 16,
          ),
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
          onTap: () => _handleKakaoLogin(context),
        ),
        const SizedBox(height: AppSpacing.space3),
        _NotebookAuthBtn(
          label: 'Apple 계정으로 시작',
          onTap: () => _handleAppleLogin(context),
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
        Container(
          height: 1,
          color: AppColors.ink.withValues(alpha: 0.25),
          margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        ),
        Text(
          'TERMS · PRIVACY · MMXXVI',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 9,
            fontWeight: FontWeight.w400,
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
            backgroundColor: AppColors.paperAccent,
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

// ─────────────────────────────────────────────────────────────────
// Notebook × Score auth button — HBAuthBtn 레퍼런스 이식.
// primary=true: ink background + paper text (Google).
// primary=false: transparent + ink border (Kakao, Apple).
// 아이콘 없음, 직각 모서리, Playfair Display 15/600/letterSpacing 1.
// ─────────────────────────────────────────────────────────────────
class _NotebookAuthBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _NotebookAuthBtn({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.ink : Colors.transparent;
    final fg = primary ? AppColors.paper : AppColors.ink;
    final borderWidth = primary ? 1.0 : 1.2;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: AppColors.ink, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 1,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PencilUnderline — 손그림 느낌 단순 곡선 (CustomPainter).
// 레퍼런스: design-plan/hybrid/primitives.jsx PencilUnderline.
// ─────────────────────────────────────────────────────────────────
class _PencilUnderline extends StatelessWidget {
  final double width;
  final Color color;
  final double strokeWidth;

  const _PencilUnderline({
    required this.width,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, 6),
      painter: _PencilUnderlinePainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _PencilUnderlinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _PencilUnderlinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final w = size.width;
    final path =
        Path()
          ..moveTo(1, 3.5)
          ..quadraticBezierTo(w * 0.3, 1.5, w * 0.5, 3)
          ..quadraticBezierTo(w * 0.7, 4.5, w - 1, 3.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PencilUnderlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
