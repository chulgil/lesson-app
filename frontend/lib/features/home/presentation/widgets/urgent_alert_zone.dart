import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/providers/booking_providers.dart';
import '../../../lessons/presentation/providers/lesson_confirmation_provider.dart';
import '../../../lessons/presentation/widgets/attendance_confirmation_sheet.dart';
import '../../../subscription/subscription_facade.dart';

/// Consolidated urgent alerts zone for the dashboard.
///
/// Displays all priority-1 items in a single visual group:
/// - Unpaid amounts (error)
/// - Expired subscriptions (error)
/// - Expiring soon subscriptions (warning)
/// - Lessons needing attendance confirmation (warning)
/// - Pending booking approvals (info)
///
/// Hidden entirely when no alerts exist.
class UrgentAlertZone extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final expiringSoonAsync = ref.watch(expiringSoonSubscriptionsProvider);
    final expiredAsync = ref.watch(expiredSubscriptionsProvider);
    final pendingBookingsAsync = ref.watch(
      pendingBookingsCountProvider(teacherId),
    );

    final items = <Widget>[];

    // 1. Unpaid (error — highest priority)
    unpaidSummary.whenData((summary) {
      if (summary.totalAmount > 0) {
        final formattedAmount =
            summary.totalAmount >= 10000
                ? '${(summary.totalAmount / 10000).toStringAsFixed(0)}만원'
                : '${summary.totalAmount}원';

        items.add(
          _AlertItem(
            icon: Icons.account_balance_wallet_outlined,
            text: '미수금 $formattedAmount (${summary.studentCount}명)',
            color: AppColors.error,
            backgroundColor: AppColors.errorLight,
            onTap: () => context.push(AppRoutes.outstandingPayments),
          ),
        );
      }
    });

    // 2. Expired subscriptions (error)
    expiredAsync.whenData((subs) {
      if (subs.isNotEmpty) {
        items.add(
          _AlertItem(
            icon: Icons.cancel_outlined,
            text: AppStrings.subscriptionExpired(subs.length),
            color: AppColors.error,
            backgroundColor: AppColors.errorLight,
            onTap: () => context.push(AppRoutes.expiringSubscriptions),
          ),
        );
      }
    });

    // 3. Expiring soon subscriptions (warning)
    expiringSoonAsync.whenData((subs) {
      if (subs.isNotEmpty) {
        items.add(
          _AlertItem(
            icon: Icons.timer_outlined,
            text: AppStrings.subscriptionExpiringSoon(subs.length),
            color: AppColors.warning,
            backgroundColor: AppColors.warningLight,
            onTap: () => context.push(AppRoutes.expiringSubscriptions),
          ),
        );
      }
    });

    // 4. Attendance confirmation (warning)
    needsConfirmation.whenData((lessons) {
      if (lessons.isNotEmpty) {
        items.add(
          _AlertItem(
            icon: Icons.fact_check,
            text: AppStrings.lessonsNeedConfirmation(lessons.length),
            color: AppColors.warning,
            backgroundColor: AppColors.warningLight,
            onTap: () => _showAttendanceSheet(context, ref, lessons.first),
          ),
        );
      }
    });

    // 5. Pending bookings (info)
    pendingBookingsAsync.whenData((count) {
      if (count > 0) {
        items.add(
          _AlertItem(
            icon: Icons.event_note_outlined,
            text: AppStrings.pendingBookings(count),
            color: AppColors.info,
            backgroundColor: AppColors.infoLight,
            onTap: () => context.push(AppRoutes.bookingList),
          ),
        );
      }
    });

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1) const SizedBox(height: AppSpacing.space2),
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
      final notifier = ref.read(
        lessonConfirmationNotifierProvider.notifier,
      );
      if (result.completed) {
        await notifier.confirmLessonCompleted(lesson);
      } else {
        await notifier.handleLessonNonCompletion(lesson, result);
      }
    }
  }
}

/// Individual alert item with consistent styling.
class _AlertItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _AlertItem({
    required this.icon,
    required this.text,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiaryLight, size: 20),
          ],
        ),
      ),
    );
  }
}
