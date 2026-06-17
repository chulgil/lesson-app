import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../domain/entities/vacation_period.dart';
import '../../providers/vacation_providers.dart';

/// Visualizes registered vacation spans inside the availability screen (#431 §4).
///
/// Calendar-grid cell shading is owned by the booking grid; this banner provides
/// a lightweight, low-risk indication that the teacher has active vacation
/// windows where no student booking will be placed.
class AvailabilityVacationBanner extends ConsumerWidget {
  const AvailabilityVacationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(vacationListProvider);
    return listAsync.when(
      data: (vacations) {
        final now = DateTime.now();
        final active = vacations
            .where((v) => v.isActiveOn(now))
            .toList(growable: false);
        if (active.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space4),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.scheduleMutedBackground,
            border: Border.all(color: AppColors.scheduleMutedAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.vacationBannerTitle,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                AppStrings.vacationBannerHint,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              for (final period in active)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _VacationRow(period: period),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Row inside [AvailabilityVacationBanner].
///
/// C4 (audit §4.10) — distinguish 다중일 휴가 vs 1일 휴무
/// by icon + accent color so the teacher can tell them apart at a glance.
/// C2 (audit §4.8) — adds a trailing close icon so the teacher can cancel
/// without navigating to the vacation management screen.
class _VacationRow extends ConsumerWidget {
  final VacationPeriod period;
  const _VacationRow({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOneDay = period.vacationDays <= 1;
    final icon = isOneDay ? Icons.event_busy : Icons.beach_access;
    final accent = isOneDay ? AppColors.inkSecondary : AppColors.paperAccent;

    final startLabel = _formatShortDate(period.startDate);
    final mainLabel = isOneDay
        ? AppStrings.vacationBannerOneDayLabel(startLabel)
        : AppStrings.vacationBannerRangeLabel(
            AppStrings.vacationCardDateRange(
              startLabel,
              _formatShortDate(period.endDate),
            ),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            mainLabel,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          ),
        ),
        if (period.reason != null && period.reason!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.space2),
            child: Text(
              period.reason!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.inkSecondary,
          tooltip: AppStrings.vacationBannerCancelTooltip,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          onPressed: () => _confirmCancel(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => NotebookAlertDialog(
        title: AppStrings.vacationCancelConfirmTitle,
        content: const Text(AppStrings.vacationCancelConfirmBody),
        confirmLabel: AppStrings.vacationCancelLabel,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (result != true || !context.mounted) return;
    try {
      await ref.read(vacationActionsProvider).cancel(period.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.vacationCancelSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString();
      final friendly = message.contains('이미 시작')
          ? AppStrings.vacationCancelAlreadyStarted
          : message.contains('24')
          ? AppStrings.vacationCancelWindowExpired
          : message.contains('이미 취소')
          ? AppStrings.vacationCancelAlreadyCancelled
          : AppStrings.vacationCancelFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    }
  }

  static String _formatShortDate(DateTime d) => '${d.month}/${d.day}';
}
