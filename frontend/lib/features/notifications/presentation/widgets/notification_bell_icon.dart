import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/notification_providers.dart';

/// 알림 종 아이콘 위젯 (뱃지 포함)
///
/// 재사용 가능한 알림 아이콘:
/// - 읽지 않은 알림 수 뱃지 표시
/// - 탭 시 알림 목록 화면으로 이동
///
/// 사용 예시:
/// ```dart
/// AppBar(
///   actions: [
///     NotificationBellIcon(),
///   ],
/// )
/// ```
class NotificationBellIcon extends ConsumerWidget {
  /// 아이콘 색상 (기본: 검정)
  final Color? iconColor;

  /// 아이콘 크기 (기본: 24)
  final double iconSize;

  const NotificationBellIcon({super.key, this.iconColor, this.iconSize = 24});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return IconButton(
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_outlined,
            color: iconColor ?? AppColors.ink,
            size: iconSize,
          ),
          // Unread badge
          if (unreadCount > 0)
            Positioned(right: -4, top: -4, child: _buildBadge(unreadCount)),
        ],
      ),
      tooltip: '알림',
    );
  }

  /// §7.131: 둥근 뱃지 → 사각 잉크 마크. paperAccent 배경 + paper 테두리(1px).
  Widget _buildBadge(int count) {
    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 14),
      decoration: BoxDecoration(
        color: AppColors.paperAccent,
        border: Border.all(color: AppColors.paper, width: 1),
      ),
      child: Text(
        displayCount,
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.paper,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
