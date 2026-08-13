import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../domain/entities/notification.dart';
import '../navigation/notification_navigation_target.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_item.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/date_format_utils.dart';

/// 알림 목록 화면
///
/// UX 패턴:
/// - 상단 앱바에 '모두 읽음' 버튼
/// - 앱바 하단 전체/안읽음 세그먼트 필터 + 미읽음 배지
/// - 날짜별 그룹핑 (오늘, 어제, 이전)
/// - 읽지 않은 알림 강조 표시
/// - 알림 탭 시 actionUrl로 이동
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  // false = 전체, true = 안읽음
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.notifications,
        customActions: [
          TextButton(
            onPressed: () => _markAllAsRead(),
            // §7.131: 액션 라벨도 시스템 메타이므로 sectionLabel(uppercase) 톤.
            child: Text(
              AppStrings.notifMarkAllRead,
              style: NotebookTypography.sectionLabel.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.paperDark,
      body: Column(
        children: [
          _NotifFilterBar(
            showUnreadOnly: _showUnreadOnly,
            unreadCount: unreadCount,
            onChanged: (v) => setState(() => _showUnreadOnly = v),
          ),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) => _buildNotificationList(notifications),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    final filtered =
        _showUnreadOnly
            ? notifications.where((n) => !n.isRead).toList()
            : notifications;

    if (filtered.isEmpty) {
      return _showUnreadOnly ? _buildNoUnreadState() : _buildEmptyState();
    }

    final grouped = _groupByDate(filtered);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return _buildDateSection(entry.key, entry.value);
      },
    );
  }

  Widget _buildDateSection(
    String dateLabel,
    List<AppNotification> notifications,
  ) {
    // §7.131: 날짜 그룹 헤더 → NotebookSectionHeader (uppercase + ThinRule).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space4,
            AppSpacing.space2,
          ),
          child: NotebookSectionHeader(label: dateLabel),
        ),
        ...notifications.map(
          (notification) => NotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDelete: () => _handleNotificationDelete(notification),
          ),
        ),
      ],
    );
  }

  Map<String, List<AppNotification>> _groupByDate(
    List<AppNotification> notifications,
  ) {
    final Map<String, List<AppNotification>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notification in notifications) {
      final date = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      String label;
      if (date == today) {
        label = AppStrings.todayLabel;
      } else if (date == yesterday) {
        label = AppStrings.yesterdayLabel;
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        // Within last 7 days - show day name
        label = LessonDateUtils.getWeekdayFullNameKorean(date.weekday);
      } else {
        // Older - show date
        label = formatDateMDKorean(date);
      }

      grouped.putIfAbsent(label, () => []).add(notification);
    }

    return grouped;
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: AppStrings.notifEmptyTitle,
      subtitle: AppStrings.notifEmptySubtitle,
    );
  }

  Widget _buildNoUnreadState() {
    return EmptyStateWidget(
      icon: Icons.mark_email_read_outlined,
      title: AppStrings.notifNoUnread,
      subtitle: AppStrings.notifNoUnreadSubtitle(AppStrings.notifFilterAll),
    );
  }

  Widget _buildErrorState(Object error) {
    return const ErrorStateWidget(title: AppStrings.notifLoadError);
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);

    final target = resolveNotificationNavigationTarget(
      notification,
      viewerRole: ref.read(notificationViewerRoleProvider),
    );
    if (target != null) {
      context.push(target.location, extra: target.extra);
    }
  }

  void _markAllAsRead() {
    ref.read(notificationActionsProvider.notifier).markAllAsRead();
  }

  /// swipe-to-dismiss 삭제 — #629 DELETE /notifications/{id} 호출 후 목록 갱신.
  Future<void> _handleNotificationDelete(AppNotification notification) async {
    await ref
        .read(notificationActionsProvider.notifier)
        .deleteNotification(notification.id);
  }
}

/// 전체/안읽음 필터 바 + 미읽음 카운트 배지
class _NotifFilterBar extends StatelessWidget {
  const _NotifFilterBar({
    required this.showUnreadOnly,
    required this.unreadCount,
    required this.onChanged,
  });

  final bool showUnreadOnly;
  final int unreadCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paperDark,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: AppStrings.notifFilterAll,
            selected: !showUnreadOnly,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: AppSpacing.space2),
          _FilterChip(
            label: AppStrings.notifFilterUnread,
            selected: showUnreadOnly,
            badge: unreadCount > 0 ? unreadCount : null,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.inkTertiary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? AppColors.paper : AppColors.inkSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: AppSpacing.space1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.paper : AppColors.ink,
                ),
                child: Text(
                  '$badge',
                  style: AppTypography.caption.copyWith(
                    color: selected ? AppColors.ink : AppColors.paper,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
