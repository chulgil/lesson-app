import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../../features/profile/presentation/providers/invite_provider.dart';

/// Screen for viewing established connections
class MyConnectionsScreen extends ConsumerWidget {
  const MyConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(myConnectionsProvider);
    final userRole = ref.watch(currentInviteUserRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(userRole == InviteUserRole.teacher ? '내 학생' : '내 선생님'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: connections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError('연결 목록을 불러올 수 없습니다. 다시 시도해주세요.'),
        data: (activeList) {
          final inactiveAsync = ref.watch(myDisconnectedConnectionsProvider);
          final inactiveList = inactiveAsync.valueOrNull ?? [];

          if (activeList.isEmpty && inactiveList.isEmpty) {
            return _buildEmpty(context, userRole);
          }
          return _buildSectionedList(
            context,
            ref,
            activeList,
            inactiveList,
            userRole,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.invite),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(userRole == InviteUserRole.teacher ? '학생 추가' : '선생님 추가'),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '연결 목록을 불러오는 중 오류가 발생했습니다',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, InviteUserRole userRole) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              userRole == InviteUserRole.teacher
                  ? '아직 연결된 학생이 없습니다'
                  : '아직 연결된 선생님이 없습니다',
              style: AppTypography.headingSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              userRole == InviteUserRole.teacher
                  ? '초대 링크를 공유하거나\n학생의 QR 코드를 스캔하세요.'
                  : '선생님의 초대 코드를 입력하거나\nQR 코드를 스캔하세요.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space6),
            OutlinedButton.icon(
              onPressed: () => _showHelpSheet(context),
              icon: const Icon(Icons.help_outline),
              label: const Text('연결 방법 알아보기'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BottomSheetHandle(margin: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.space6),
                Text('선생님과 연결하는 방법', style: AppTypography.headingSmall),
                const SizedBox(height: AppSpacing.space4),
                _HelpItem(
                  icon: Icons.dialpad,
                  title: '초대 코드 입력',
                  subtitle: '선생님에게 받은 6자리 코드를 입력하세요',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.inviteCode);
                  },
                ),
                const SizedBox(height: AppSpacing.space2),
                _HelpItem(
                  icon: Icons.qr_code_scanner,
                  title: 'QR 코드 스캔',
                  subtitle: '선생님의 QR 코드를 카메라로 스캔하세요',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.inviteScan);
                  },
                ),
                const SizedBox(height: AppSpacing.space2),
                _HelpItem(
                  icon: Icons.search,
                  title: '선생님 검색',
                  subtitle: '이름, 악기, 지역으로 선생님을 검색하세요',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.teacherSearch);
                  },
                ),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionedList(
    BuildContext context,
    WidgetRef ref,
    List<Connection> activeConnections,
    List<Connection> inactiveConnections,
    InviteUserRole userRole,
  ) {
    final sectionLabel = userRole == InviteUserRole.teacher ? '학생' : '선생님';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active connections section
          if (activeConnections.isNotEmpty) ...[
            _SectionHeader(
              title: '연결된 $sectionLabel',
              count: activeConnections.length,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...activeConnections.map(
              (connection) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _ConnectionCard(
                  connection: connection,
                  userRole: userRole,
                  isActive: true,
                  onTap:
                      () => _showConnectionDetails(
                        context,
                        ref,
                        connection,
                        userRole,
                      ),
                ),
              ),
            ),
          ],

          // Inactive connections section
          if (inactiveConnections.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            _SectionHeader(
              title: '이전 $sectionLabel',
              count: inactiveConnections.length,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...inactiveConnections.map(
              (connection) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _ConnectionCard(
                  connection: connection,
                  userRole: userRole,
                  isActive: false,
                  onTap:
                      () => _showConnectionDetails(
                        context,
                        ref,
                        connection,
                        userRole,
                      ),
                  onReconnect: () => _handleReconnect(context, ref, connection),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleReconnect(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
  ) async {
    final success = await ref
        .read(connectionManagerProvider.notifier)
        .reactivateConnection(connection.id);

    if (success && context.mounted) {
      final name =
          ref.read(currentInviteUserRoleProvider) == InviteUserRole.teacher
              ? connection.studentName
              : connection.teacherName;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name님과 다시 연결되었습니다')));
    }
  }

  void _showConnectionDetails(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    InviteUserRole userRole,
  ) {
    final otherName =
        userRole == InviteUserRole.teacher
            ? connection.studentName
            : connection.teacherName;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BottomSheetHandle(margin: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.space6),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    otherName[0],
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(otherName, style: AppTypography.headingMedium),
                Text(
                  userRole == InviteUserRole.teacher ? '학생' : '선생님',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '연결일: ${_formatDate(connection.connectedAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.calendar_today, color: AppColors.primary),
                  title: const Text('레슨 일정 보기'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to schedule
                  },
                ),
                ListTile(
                  leading: Icon(Icons.message, color: AppColors.info),
                  title: const Text('메시지 보내기'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to messages
                  },
                ),
                ListTile(
                  leading: Icon(Icons.link_off, color: AppColors.warning),
                  title: const Text('연결 해제'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleDeactivate(context, ref, connection, otherName);
                  },
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
    );
  }

  Future<void> _handleDeactivate(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    String otherName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('연결 해제'),
            content: Text('$otherName님과의 연결을 해제하시겠습니까?\n나중에 다시 연결할 수 있습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                child: const Text('연결 해제'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(connectionManagerProvider.notifier)
          .deactivateConnection(connection.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$otherName님과의 연결이 해제되었습니다')));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$title ($count명)',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiaryLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final Connection connection;
  final InviteUserRole userRole;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onReconnect;

  const _ConnectionCard({
    required this.connection,
    required this.userRole,
    required this.isActive,
    required this.onTap,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        userRole == InviteUserRole.teacher
            ? connection.studentName
            : connection.teacherName;
    final profileImage =
        userRole == InviteUserRole.teacher
            ? connection.studentProfileImage
            : connection.teacherProfileImage;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Colors.white
                  : AppColors.textTertiaryLight.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Profile image
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.textTertiaryLight.withValues(alpha: 0.1),
              backgroundImage:
                  profileImage != null ? NetworkImage(profileImage) : null,
              child:
                  profileImage == null
                      ? Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: AppTypography.headingSmall.copyWith(
                          color:
                              isActive
                                  ? AppColors.primary
                                  : AppColors.textTertiaryLight,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: AppSpacing.space3),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isActive ? null : AppColors.textSecondaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      // Status badge
                      _StatusBadge(isActive: isActive),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? '연결됨: ${_formatRelativeDate(connection.connectedAt)}'
                        : '해제됨: ${_formatRelativeDate(connection.deactivatedAt ?? connection.connectedAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            if (isActive)
              IconButton(
                onPressed: onTap,
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondaryLight,
                ),
              )
            else if (onReconnect != null)
              TextButton(
                onPressed: onReconnect,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                  ),
                ),
                child: const Text('다시 연결'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}주 전';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()}개월 전';
    } else {
      return '${(diff.inDays / 365).floor()}년 전';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.textTertiaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Text(
        isActive ? '연결됨' : '해제됨',
        style: AppTypography.bodySmall.copyWith(
          fontSize: 11,
          color: isActive ? AppColors.success : AppColors.textTertiaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
