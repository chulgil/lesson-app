import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/domain/value_objects/discipline_registry.dart';
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
    // Multi-discipline gate (#977): with >1 registered discipline the user
    // picks a discipline before role onboarding; with the single music
    // discipline (DisciplineRegistry.all.length == 1) this auto-skips straight
    // to role onboarding — byte-identical to the prior inline switch.
    if (DisciplineRegistry.all.length > 1) {
      context.go(AppRoutes.disciplineSelection, extra: role);
      return;
    }
    context.go(role.onboardingRoute);
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
                AppStrings.roleSelectWelcome(userName),
                style: NotebookTypography.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                AppStrings.roleSelectSubtitle,
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
                title: AppStrings.roleSelectTeacher,
                description: AppStrings.roleSelectTeacherDesc,
                color: AppColors.paperAccent,
                isEnabled: _canSelectRole,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.teacher),
              ),
              const SizedBox(height: AppSpacing.space3),
              _RoleCard(
                icon: Icons.music_note_rounded,
                title: AppStrings.roleSelectStudent,
                description: AppStrings.roleSelectStudentDesc,
                color: AppColors.paperAccent,
                isEnabled: _canSelectRole,
                isLoading: _isLoading,
                badge: AppStrings.roleSelectStudentInviteBadge, // #112
                onTap: () => _selectRole(UserRole.student),
              ),
              const SizedBox(height: AppSpacing.space3),
              _RoleCard(
                icon: Icons.family_restroom_rounded,
                title: AppStrings.roleSelectParent,
                description: AppStrings.roleSelectParentDesc,
                color: AppColors.ink,
                isEnabled: _canSelectRole,
                isLoading: _isLoading,
                onTap: () => _selectRole(UserRole.parent),
              ),

              if (!_terms.requiredAccepted) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  AppStrings.roleSelectConsentRequired,
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
  final String? badge; // #112: optional pre-badge (e.g. "초대 필요")

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.isEnabled,
    required this.isLoading,
    required this.onTap,
    this.badge,
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
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.12),
                        border: Border.all(
                          color: effectiveColor.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.zero, // §1.3.1 각진 원칙
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.caption.copyWith(
                          color: effectiveColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
