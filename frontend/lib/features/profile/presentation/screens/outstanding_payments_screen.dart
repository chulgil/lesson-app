import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../auth/auth_facade.dart';
import '../../../students/students_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Tuition deposit status screen.
class OutstandingPaymentsScreen extends ConsumerWidget {
  const OutstandingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final unpaidAsync = ref.watch(unpaidSubscriptionsProvider(teacherId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.profileOutstandingTitle,
      ),
      body: unpaidAsync.when(
        data: (unpaidList) {
          if (unpaidList.isEmpty) {
            return _buildEmptyState();
          }
          return _buildContent(context, ref, unpaidList, teacherId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text(AppStrings.genericError)),
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
          Text(
            AppStrings.profileOutstandingEmpty,
            style: NotebookTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            '모든 수강권의 입금 상태가 정리되었습니다',
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

          // Deposit confirmation list
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Text(
              AppStrings.profileOutstandingListTitle,
              style: NotebookTypography.sectionTitle,
            ),
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
            colors: [AppColors.paperAccent, AppColors.paperAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              '미수금 금액',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.paper.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              formatWonWithComma(totalAmount),
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.paper,
              ),
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
                    ? AppColors.paperAccent
                    : AppColors.inkQuaternary,
          ),
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
                        color: AppColors.paper,
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
                    // #1212 — 학생에게 도달하는 발송 경로(BE)가 없어 비활성.
                    // 기존 구현은 교사 기기에만 로컬 알림을 띄우고 "전송됨" 을 보여
                    // 허위 성공이었다.
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.notifications_outlined, size: 18),
                      label: const Text(
                        AppStrings.profileOutstandingSendReminderPreparing,
                      ),
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
                      label: const Text(
                        AppStrings.profileOutstandingConfirmPayment,
                      ),
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
    // #851 입금 안내는 보통 1영업일 소요 — 발급 당일·익일은 연체 표시 제외.
    final createdAt = subscription.createdAt;
    final days = DateTime.now().difference(createdAt).inDays - 1;
    return days > 0 ? days : 0;
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

  void _confirmPayment(BuildContext context, WidgetRef ref) {
    showNotebookDialog(
      context: context,
      title: AppStrings.profileOutstandingConfirmPayment,
      content: Text(
        AppLocalizations.of(
          context,
        ).paymentConfirmBody(formatWonWithComma(subscription.amount)),
      ),
      confirmLabel: AppStrings.confirm,
      cancelLabel: AppStrings.cancel,
      onConfirm: () async {
        Navigator.pop(context);
        await ref
            .read(subscriptionNotifierProvider(subscription.studentId).notifier)
            .confirmPayment(subscription.id);

        // Invalidate unpaid providers
        final teacherId = ref.read(currentUserIdProvider);
        ref.invalidate(unpaidSubscriptionsProvider(teacherId));
        ref.invalidate(unpaidSummaryProvider(teacherId));

        if (context.mounted) {
          // #426 — 8s Undo window in the SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.paymentConfirmedUndoSnackbar),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: AppStrings.paymentUndoLabel,
                onPressed: () => _undoConfirmPayment(context, ref),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _undoConfirmPayment(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(subscriptionNotifierProvider(subscription.studentId).notifier)
          .undoConfirmPayment(subscription.id);

      final teacherId = ref.read(currentUserIdProvider);
      ref.invalidate(unpaidSubscriptionsProvider(teacherId));
      ref.invalidate(unpaidSummaryProvider(teacherId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.paymentUndoSuccessSnackbar)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      // Server returns 409 for window-expired / first-lesson-consumed; map to friendly text.
      final message = e.toString();
      final friendly =
          message.contains('24')
              ? AppStrings.paymentUndoWindowExpired
              : message.contains('lesson') || message.contains('차감')
              ? AppStrings.paymentUndoBlockedByLesson
              : AppStrings.paymentUndoFailedSnackbar;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendly)));
    }
  }
}
