import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../domain/entities/user_role.dart';
import '../extensions/user_role_visuals.dart';
import '../providers/auth_provider.dart';
import '../widgets/terms_agreement_section.dart';

/// Role selection screen — also collects required terms agreement inline
/// (replacing the previously separate TermsAgreementScreen). Required terms
/// must be checked before any role card becomes tappable.
class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  bool _isLoading = false;
  TermsAgreementState _terms = TermsAgreementState.initial;

  bool get _canSelectRole => _terms.requiredAccepted && !_isLoading;

  void _onTermsChanged(TermsAgreementState state) {
    setState(() => _terms = state);
  }

  Future<void> _selectRole(UserRole role) async {
    if (!_canSelectRole) return;
    setState(() => _isLoading = true);

    try {
      ref
          .read(authNotifierProvider.notifier)
          .acceptTerms(marketingConsent: _terms.marketingConsent);

      final currentState = ref.read(authNotifierProvider);
      if (currentState is AuthNeedsOnboarding && currentState.role == role) {
        if (!mounted) return;
        _goToOnboarding(role);
        return;
      }

      await ref.read(authNotifierProvider.notifier).setRole(role);

      if (!mounted) return;
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        context.go(authState.role.homeRoute);
      } else if (authState is AuthNeedsOnboarding) {
        _goToOnboarding(authState.role);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.authRoleSetupFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToOnboarding(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        context.go(AppRoutes.teacherProfileSetup);
      case UserRole.student:
        // 정책: 학생 직접 가입은 만 14세 검증을 위해 SSO 직후 전화인증 필수.
        // (phone_verification_policy.md §3.2) — 라우터 분기 wiring 은 별도 작업.
        context.go(AppRoutes.studentProfileSetup);
      case UserRole.parent:
        context.go(AppRoutes.parentInviteCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName =
        authState is AuthNeedsRole
            ? authState.name
            : authState is AuthNeedsOnboarding
            ? authState.name
            : '';

    return NotebookScreenScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space4),

              // Welcome header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.paperAccentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    size: 40,
                    color: AppColors.paperAccent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                '$userName님, 환영합니다!',
                style: NotebookTypography.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '약관에 동의하고 사용할 역할을 선택해 주세요.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.space6),

              // Inline terms agreement (replaces separate TermsAgreementScreen)
              TermsAgreementSection(onChanged: _onTermsChanged),

              const SizedBox(height: AppSpacing.space6),

              // Role cards — disabled until required terms checked
              _RoleCard(
                icon: Icons.school_rounded,
                title: '선생님',
                description: '학생 관리, 레슨 일정, 피드백 작성',
                color: AppColors.paperAccent,
                isEnabled: _canSelectRole,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.teacher),
              ),
              const SizedBox(height: AppSpacing.space3),
              _RoleCard(
                icon: Icons.music_note_rounded,
                title: '학생',
                description: '레슨 확인, 연습 기록, 피드백 확인',
                color: AppColors.paperAccent,
                isEnabled: _canSelectRole,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.student),
              ),
              const SizedBox(height: AppSpacing.space3),
              _RoleCard(
                icon: Icons.family_restroom_rounded,
                title: '학부모',
                description: '자녀의 레슨과 연습을 확인',
                color: AppColors.ink,
                isEnabled: _canSelectRole,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.parent),
              ),

              if (!_terms.requiredAccepted) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '필수 약관에 동의하면 역할을 선택할 수 있어요.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isEnabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? color : color.withValues(alpha: 0.35);

    return InkWell(
      onTap: (!isEnabled || isLoading) ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
          color: effectiveColor.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: effectiveColor, size: 24),
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
                      color: isEnabled ? AppColors.ink : AppColors.inkTertiary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveColor,
                ),
              )
            else
              Icon(Icons.chevron_right, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}
