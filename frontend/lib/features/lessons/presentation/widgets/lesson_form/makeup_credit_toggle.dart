import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../subscription/subscription_facade.dart';

/// S4 (spec §2.6.1, makeup_credit_spec §5.4) — "보강으로 처리" toggle on the
/// add-lesson form. Rendered only when the student holds spendable makeup
/// credits; default OFF (D3 — credit spend stays an explicit choice).
class MakeupCreditToggle extends ConsumerWidget {
  const MakeupCreditToggle({
    super.key,
    required this.studentId,
    required this.value,
    required this.onChanged,
  });

  final String studentId;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(teacherMakeupCreditsProvider(studentId));
    final credits = creditsAsync.valueOrNull;
    if (credits == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final available = credits.where((c) => c.isAvailable(now)).length;
    if (available == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.makeupToggleLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AppStrings.makeupToggleCredits(available),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
