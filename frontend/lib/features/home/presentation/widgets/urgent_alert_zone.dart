import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../lessons/lessons_ui_facade.dart';
import '../../../subscription/subscription_facade.dart';

/// Urgent alerts zone — **Notebook × Score 스타일 "긴급 메모 스트립"**.
///
/// 종이 위의 "색연필 경고줄" 메타포:
/// - 좌측 3px paperAccent(vermillion) 세로선 — 4대 시그니처
/// - 배경: 투명 (crimson wash 제거, paper 그대로)
/// - 텍스트: ink, 아이콘: ink (color overload 지양)
/// - 3색 미만 원칙 (ux_rules.md) — semantic error/warning/info 구분 제거
///
/// Policy (2026-04-16): Top 1 + Expandable (ux_guidelines §2.5)
class UrgentAlertZone extends ConsumerStatefulWidget {
  final String teacherId;
  final AsyncValue<({int totalAmount, int studentCount})> unpaidSummary;
  final AsyncValue<List<Lesson>> needsConfirmation;

  const UrgentAlertZone({
    super.key,
    required this.teacherId,
    required this.unpaidSummary,
    required this.needsConfirmation,
  });

  @override
  ConsumerState<UrgentAlertZone> createState() => _UrgentAlertZoneState();
}

class _UrgentAlertZoneState extends ConsumerState<UrgentAlertZone> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final teacherId = widget.teacherId;
    final unpaidSummary = widget.unpaidSummary;
    final needsConfirmation = widget.needsConfirmation;
    final expiringSoonAsync = ref.watch(expiringSoonSubscriptionsProvider);
    final expiredAsync = ref.watch(expiredSubscriptionsProvider);
    final pendingBookingsAsync = ref.watch(
      pendingBookingsCountProvider(teacherId),
    );

    final items = <Widget>[];

    // 1. Unpaid (highest priority — vermillion)
    unpaidSummary.whenData((summary) {
      if (summary.totalAmount > 0) {
        items.add(
          _AlertItem(
            icon: Icons.account_balance_wallet_outlined,
            text: AppStrings.urgentAlertOutstandingFormat(
              summary.totalAmount,
              summary.studentCount,
            ),
            urgent: true,
            onTap: () => context.push(AppRoutes.outstandingPayments),
          ),
        );
      }
    });

    // 2. Expired subscriptions
    expiredAsync.whenData((subs) {
      if (subs.isNotEmpty) {
        items.add(
          _AlertItem(
            icon: Icons.cancel_outlined,
            text: AppStrings.subscriptionExpired(subs.length),
            urgent: true,
            onTap: () => context.push(AppRoutes.expiringSubscriptions),
          ),
        );
      }
    });

    // 3. Expiring soon subscriptions
    expiringSoonAsync.whenData((subs) {
      if (subs.isNotEmpty) {
        items.add(
          _AlertItem(
            icon: Icons.timer_outlined,
            text: AppStrings.subscriptionExpiringSoon(subs.length),
            urgent: false,
            onTap: () => context.push(AppRoutes.expiringSubscriptions),
          ),
        );
      }
    });

    // 4. Attendance confirmation
    needsConfirmation.whenData((lessons) {
      if (lessons.isNotEmpty) {
        items.add(
          _AlertItem(
            icon: Icons.fact_check,
            text: AppStrings.lessonsNeedConfirmation(lessons.length),
            urgent: false,
            onTap: () => _showAttendanceSheet(context, ref, lessons.first),
          ),
        );
      }
    });

    // 5. Pending bookings
    pendingBookingsAsync.whenData((count) {
      if (count > 0) {
        items.add(
          _AlertItem(
            icon: Icons.event_note_outlined,
            text: AppStrings.pendingBookings(count),
            urgent: false,
            onTap: () => context.push(AppRoutes.myBookings),
          ),
        );
      }
    });

    if (items.isEmpty) return const SizedBox.shrink();

    // Top 1 + Expandable policy (ux_guidelines §2.5)
    final primary = items.first;
    final rest = items.sublist(1);
    final extraCount = rest.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        primary,
        if (extraCount > 0) ...[
          if (_expanded)
            ...rest.expand((item) => [const SizedBox(height: 2), item]),
          _ExpandToggle(
            count: extraCount,
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ],
        const SizedBox(height: AppSpacing.space5),
      ],
    );
  }

  Future<void> _showAttendanceSheet(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
  ) async {
    final result = await AttendanceConfirmationSheet.show(
      context,
      lesson: lesson,
    );
    if (result != null) {
      final notifier = ref.read(lessonConfirmationNotifierProvider.notifier);
      if (result.completed) {
        await notifier.confirmLessonCompleted(lesson);
      } else {
        await notifier.handleLessonNonCompletion(lesson, result);
      }
    }
  }
}

/// Alert item — Notebook 스타일.
/// - 좌측 3px 세로선: urgent=paperAccent(vermillion), 일반=ink
/// - 배경: 투명
class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool urgent;
  final VoidCallback onTap;

  const _AlertItem({
    required this.icon,
    required this.text,
    required this.urgent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = urgent ? AppColors.paperAccent : AppColors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              AppSpacing.space3,
              AppSpacing.space3,
              AppSpacing.space3,
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(
                    text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.inkTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Expand/collapse toggle — Notebook 스타일 (ink 색, 사각형).
class _ExpandToggle extends StatelessWidget {
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _ExpandToggle({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expanded
                  ? AppStrings.urgentAlertCollapse
                  : AppStrings.urgentAlertMoreFormat(count),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.inkSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
