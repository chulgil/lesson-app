import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/instrument_colors.dart';
import '../../../../subscription/subscription_facade.dart';

/// Subscription status + instrument inheritance for the manual add-lesson form
/// (spec `docs/specs/subscription/subscription_required_spec.md` §2.5).
///
/// - 0개: no-subscription info + 악기(학생 정보) 칩
/// - 1개(자동) / 2+개(선택됨): 수강권 요약 + 악기(수강권 상속) 칩 (+2개면 변경)
/// - 2+개(미선택): 선택 유도 배너 (탭 → 선택 시트)
class ManualLessonSubscriptionSection extends ConsumerWidget {
  const ManualLessonSubscriptionSection({
    super.key,
    required this.studentId,
    required this.studentInstrument,
    required this.selectedSubscription,
    required this.onPickRequested,
  });

  final String studentId;
  final String studentInstrument;
  final Subscription? selectedSubscription;

  /// Open the picker sheet (used by the select prompt and the 변경 affordance).
  final VoidCallback onPickRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeStudentSubscriptionsProvider(studentId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _errorRow(),
      data: (subs) {
        final count = subs.length;
        // 2+개인데 아직 선택 안 됨 → 선택 유도
        if (count >= 2 && selectedSubscription == null) {
          return _SelectPromptBanner(count: count, onTap: onPickRequested);
        }
        // 단일(자동) 경우 flicker 방지: 화면 상태 반영 전이라도 그 수강권을 노출
        final effective =
            selectedSubscription ?? (count == 1 ? subs.first : null);
        return _ResolvedBanner(
          subscription: effective,
          studentInstrument: studentInstrument,
          showChange: count >= 2,
          onChange: onPickRequested,
        );
      },
    );
  }

  Widget _errorRow() => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.space2),
    child: Row(
      children: [
        Icon(Icons.error_outline, size: 16, color: AppColors.inkTertiary),
        const SizedBox(width: AppSpacing.space2),
        Text(
          AppStrings.loadDataFailed,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    ),
  );
}

/// Resolved banner: subscription summary (or no-subscription info) + 악기 칩.
class _ResolvedBanner extends StatelessWidget {
  const _ResolvedBanner({
    required this.subscription,
    required this.studentInstrument,
    required this.showChange,
    required this.onChange,
  });

  final Subscription? subscription;
  final String studentInstrument;
  final bool showChange;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final hasSub = subscription != null;
    final effectiveInstrument = resolveLessonInstrument(
      subscription: subscription,
      studentInstrument: studentInstrument,
    );

    final message =
        hasSub
            ? AppStrings.activeSubscriptionBanner(
              subscription!.remainingLessons ?? 0,
              subscription!.totalLessonsForDisplay ?? 0,
            )
            : AppStrings.noActiveSubscriptionBanner;
    final icon = hasSub ? Icons.check_circle_outline : Icons.info_outline;
    final bgColor =
        hasSub
            ? AppColors.paperOk.withValues(alpha: 0.08)
            : AppColors.paperDark;
    final iconColor = hasSub ? AppColors.paperOk : AppColors.ink;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color:
                hasSub
                    ? AppColors.paperOk.withValues(alpha: 0.3)
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (showChange)
                  GestureDetector(
                    onTap: onChange,
                    child: Text(
                      AppStrings.manualLessonChangeSubscription,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            _InstrumentChip(instrument: effectiveInstrument, inherited: hasSub),
          ],
        ),
      ),
    );
  }
}

/// Select-required banner shown for 2+ active subscriptions before a choice.
class _SelectPromptBanner extends StatelessWidget {
  const _SelectPromptBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            border: Border.all(color: AppColors.paperAccent),
          ),
          child: Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                color: AppColors.paperAccent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.manualLessonSelectSubscriptionPrompt(count),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.paperAccent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only instrument chip. [inherited] = from membership (SSOT), else student.
class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({required this.instrument, required this.inherited});

  final String instrument;
  final bool inherited;

  @override
  Widget build(BuildContext context) {
    final pair = InstrumentColors.getColor(instrument);
    final label =
        inherited
            ? AppStrings.manualLessonInstrumentInherited(instrument)
            : AppStrings.manualLessonInstrumentFromStudent(instrument);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: pair.background,
        border: Border.all(color: pair.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: pair.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
