import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/value_objects/discipline.dart';
import '../../../../core/domain/value_objects/discipline_registry.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/user_role.dart';
import '../extensions/discipline_visuals.dart';
import '../extensions/user_role_visuals.dart';
import '../providers/active_discipline_provider.dart';

/// Discipline selection — the first sign-up step of the multi-discipline
/// platform (#977). The user picks a coaching discipline (music today; later
/// fitness/language) before role onboarding.
///
/// With the single registered music discipline, RoleSelectScreen's gate
/// auto-skips here (DisciplineRegistry.all.length == 1), so this screen is dead
/// until a 2nd discipline registers in Phase 4 — kept intentionally minimal.
///
/// [role] (via GoRouter `extra`) is the role chosen on RoleSelectScreen; after a
/// discipline is picked we continue to that role's onboarding. A null role
/// (e.g. a direct deep-link) safely restarts at role selection.
class DisciplineSelectionScreen extends ConsumerWidget {
  final UserRole? role;

  const DisciplineSelectionScreen({super.key, this.role});

  Future<void> _onDisciplineSelected(
    BuildContext context,
    WidgetRef ref,
    Discipline discipline,
  ) async {
    // #979-A: persist the chosen discipline so the logged-in session resolves
    // its active discipline (practice tools, theme, expertise). Music-only today
    // means RoleSelectScreen auto-skips this screen, so this path stays dormant
    // until Phase 4 (#979-B) registers a 2nd discipline.
    await ref
        .read(selectedDisciplineStorageProvider.notifier)
        .select(discipline.id);
    if (!context.mounted) return;
    final selectedRole = role;
    if (selectedRole == null) {
      context.go(AppRoutes.roleSelect);
      return;
    }
    context.go(selectedRole.onboardingRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disciplines = DisciplineRegistry.all;

    return NotebookScreenScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space4),
              Text(
                AppStrings.disciplineSelectTitle,
                style: NotebookTypography.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                AppStrings.disciplineSelectSubtitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space6),
              for (final discipline in disciplines) ...[
                _DisciplineCard(
                  label: discipline.displayName,
                  onTap: () => _onDisciplineSelected(context, ref, discipline),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DisciplineCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.paperAccent.withValues(alpha: 0.3),
          ),
          color: AppColors.paperAccent.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.paperAccent),
          ],
        ),
      ),
    );
  }
}
