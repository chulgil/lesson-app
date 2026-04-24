import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../notifications/domain/entities/notification.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../../../subscription/subscription_facade.dart';

/// Outstanding payments management screen
class OutstandingPaymentsScreen extends ConsumerWidget {
  const OutstandingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final unpaidAsync = ref.watch(unpaidSubscriptionsProvider(teacherId));

    return Scaffold(
      appBar: AppBar(title: const Text('미수금 관리')),
      body: unpaidAsync.when(
        data: (unpaidList) {
          if (unpaidList.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(context, ref, unpaidList, teacherId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.paperOk),
          const SizedBox(height: AppSpacing.space4),
          // Notebook × Score: 빈 상태 헤드라인 (§7.89 3축) — Playfair sectionTitle.
          Text('미수금이 없습니다', style: NotebookTypography.sectionTitle),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '모든 수강료가 수금 완료되었습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Subscription> unpaidList,
    String teacherId,
  ) {
    final totalAmount = unpaidList.fold(0, (sum, s) => sum + s.amount);
    final studentCount = unpaidList.map((s) => s.studentId).toSet().length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          _buildSummaryHeader(totalAmount, studentCount),

          const SizedBox(height: AppSpacing.space6),

          // Unpaid list
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17).
            // (line 48 의 '미수금이 없습니다' 는 empty-state headline / line 222 는 가격 — §7.30 제외.)
            child: Text('미수금 목록', style: NotebookTypography.sectionTitle),
          ),
          const SizedBox(height: AppSpacing.space3),

          ...unpaidList.map(
            (subscription) => _UnpaidCard(subscription: subscription),
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(int totalAmount, int studentCount) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.paperAccent,
              AppColors.paperAccent.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              '총 미수금',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paper.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              formatWonWithComma(totalAmount),
              style: AppTypography.displayMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '$studentCount명의 학생',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paper.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnpaidCard extends ConsumerWidget {
  final Subscription subscription;

  const _UnpaidCard({required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(subscription.studentId));
    final studentName =
        studentAsync.whenOrNull(data: (student) => student?.name) ?? '학생';

    final daysOverdue = _calculateDaysOverdue(subscription);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space1,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(
            color:
                daysOverdue > 0
                    ? AppColors.paperAccent.withValues(alpha: 0.3)
                    : AppColors.inkQuaternary,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + amount
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.paperAccentSoft,
                    child: Text(
                      studentName.isNotEmpty ? studentName[0] : '?',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _subscriptionTypeLabel(subscription),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatWonWithComma(subscription.amount),
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.paperAccent,
                        ),
                      ),
                      _buildDaysBadge(daysOverdue),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space3),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendReminder(context, ref),
                      icon: const Icon(Icons.notifications_outlined, size: 18),
                      label: const Text('알림 보내기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.inkSecondary,
                        side: BorderSide(color: AppColors.inkQuaternary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _confirmPayment(context, ref),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('입금 확인'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.paperOk,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysBadge(int daysOverdue) {
    if (daysOverdue > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.paperAccentSoft,
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          'D+$daysOverdue',
          style: AppTypography.caption.copyWith(
            color: AppColors.paperAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  int _calculateDaysOverdue(Subscription subscription) {
    final createdAt = subscription.createdAt;
    return DateTime.now().difference(createdAt).inDays;
  }

  String _subscriptionTypeLabel(Subscription subscription) {
    switch (subscription.type) {
      case SubscriptionType.package:
        final total = subscription.totalLessonsForDisplay ?? 0;
        return '회차권 · ${subscription.usedLessons}/$total회';
      case SubscriptionType.monthly:
        return '월정액';
      case SubscriptionType.trial:
        return '체험';
    }
  }

  Future<void> _sendReminder(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final notification = AppNotification(
      id:
          'payment_reminder_${subscription.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: subscription.studentId,
      type: NotificationType.paymentReminder,
      priority: NotificationPriority.high,
      title: AppStrings.paymentReminderTitle,
      body: AppStrings.paymentReminderBody(
        teacherName: '선생님',
        amount: subscription.amount,
      ),
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      actionUrl: '/subscriptions/${subscription.id}',
      actionLabel: AppStrings.viewDetail,
      data: {
        'subscriptionId': subscription.id,
        'studentId': subscription.studentId,
        'amount': subscription.amount,
      },
    );

    try {
      await notificationService.showNotification(notification);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.paymentReminderSent)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.paymentReminderSendFailed)),
        );
      }
    }
  }

  void _confirmPayment(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('입금 확인'),
            content: Text(
              '${formatWonWithComma(subscription.amount)} 입금을 확인하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await ref
                      .read(
                        subscriptionNotifierProvider(
                          subscription.studentId,
                        ).notifier,
                      )
                      .confirmPayment(subscription.id);

                  // Invalidate unpaid providers
                  final teacherId = ref.read(currentUserIdProvider);
                  ref.invalidate(unpaidSubscriptionsProvider(teacherId));
                  ref.invalidate(unpaidSummaryProvider(teacherId));

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('입금이 확인되었습니다')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paperOk,
                ),
                child: const Text(AppStrings.confirm),
              ),
            ],
          ),
    );
  }
}
