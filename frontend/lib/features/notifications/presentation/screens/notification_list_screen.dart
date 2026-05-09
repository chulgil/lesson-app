import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../domain/entities/notification.dart';
import '../navigation/notification_navigation_target.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_item.dart';

/// 알림 목록 화면
///
/// UX 패턴:
/// - 상단 앱바에 '모두 읽음' 버튼
/// - 날짜별 그룹핑 (오늘, 어제, 이전)
/// - 읽지 않은 알림 강조 표시
/// - 알림 탭 시 actionUrl로 이동
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    // §7.131: AppBar 는 전역 테마(Playfair appBarTitle)를 따르고,
    // 하단에 1px ThinRule 을 두어 매스트헤드 메타포 유지.
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.notifications,
        customActions: [
          TextButton(
            onPressed: () => _markAllAsRead(ref),
            // §7.131: 액션 라벨도 시스템 메타이므로 sectionLabel(uppercase) 톤.
            child: Text(
              '모두 읽음',
              style: NotebookTypography.sectionLabel.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.paperDark,
      body: notificationsAsync.when(
        data:
            (notifications) =>
                _buildNotificationList(context, ref, notifications),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> notifications,
  ) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    // Group notifications by date
    final grouped = _groupByDate(notifications);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return _buildDateSection(context, ref, entry.key, entry.value);
      },
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    WidgetRef ref,
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
            onTap: () => _handleNotificationTap(context, ref, notification),
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
        label = '오늘';
      } else if (date == yesterday) {
        label = '어제';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        // Within last 7 days - show day name
        final weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
        label = weekdays[date.weekday - 1];
      } else {
        // Older - show date
        label = '${date.month}월 ${date.day}일';
      }

      grouped.putIfAbsent(label, () => []).add(notification);
    }

    return grouped;
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      title: '알림이 없습니다',
      subtitle: '새로운 소식이 있으면 알려드릴게요',
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.paperAccent,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            '알림을 불러올 수 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
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

  void _markAllAsRead(WidgetRef ref) {
    ref.read(notificationActionsProvider.notifier).markAllAsRead();
  }
}
