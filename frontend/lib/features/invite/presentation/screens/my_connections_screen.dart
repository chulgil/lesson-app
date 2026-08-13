import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/profile_facade.dart';

/// Screen for viewing established connections
class MyConnectionsScreen extends ConsumerWidget {
  const MyConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(myConnectionsProvider);
    final userRole = ref.watch(currentInviteUserRoleProvider);

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title:
            userRole == InviteUserRole.teacher
                ? AppStrings.inviteMyStudentsTitle
                : AppStrings.inviteMyTeachersTitle,
        actions: const [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            context.push(AppRoutes.invite);
          }
        },
      ),
      body: connections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildError(AppStrings.inviteConnectionsLoadError),
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
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.inviteConnectionsLoadErrorDescription,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, InviteUserRole userRole) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title:
          userRole == InviteUserRole.teacher
              ? AppStrings.inviteNoConnectedStudents
              : AppStrings.inviteNoConnectedTeachers,
      subtitle:
          userRole == InviteUserRole.teacher
              ? AppStrings.inviteEmptyHintTeacher
              : AppStrings.inviteEmptyHintStudent,
      actionLabel: AppStrings.inviteHowToConnect,
      actionIcon: Icons.help_outline,
      onAction: () => _showHelpSheet(context),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showNotebookModalBottomSheet<void>(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BottomSheetHandle(margin: EdgeInsets.zero),
                const SizedBox(height: AppSpacing.space6),
                // Notebook × Score: BottomSheetHandle + 상단 제목 조합은
                // §7.27 패턴. Playfair appBarTitle 로 통일.
                Text(
                  AppStrings.inviteConnectWithTeacher,
                  style: NotebookTypography.appBarTitle,
                ),
                const SizedBox(height: AppSpacing.space4),
                _HelpItem(
                  icon: Icons.dialpad,
                  title: AppStrings.inviteCodeAppBarTitle,
                  subtitle: AppStrings.inviteHelpCodeSubtitle,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.inviteCode);
                  },
                ),
                const SizedBox(height: AppSpacing.space2),
                _HelpItem(
                  icon: Icons.qr_code_scanner,
                  title: AppStrings.inviteScanQrTitle,
                  subtitle: AppStrings.inviteHelpScanSubtitle,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.inviteScan);
                  },
                ),
                const SizedBox(height: AppSpacing.space2),
                _HelpItem(
                  icon: Icons.search,
                  title: AppStrings.inviteTeacherSearchTitle,
                  subtitle: AppStrings.inviteHelpSearchSubtitle,
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
    final sectionLabel =
        userRole == InviteUserRole.teacher
            ? AppStrings.student
            : AppStrings.teacher;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active connections section
          if (activeConnections.isNotEmpty) ...[
            _SectionHeader(
              title: AppStrings.inviteConnectedSectionFormat(sectionLabel),
              count: activeConnections.length,
            ),
            const SizedBox(height: AppSpacing.space3),
            ...activeConnections.map(
              (connection) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: SwipeActionTile(
                  actions: [
                    SwipeAction(
                      label: AppStrings.swipeActionDisconnect,
                      icon: Icons.link_off,
                      tone: SwipeActionTone.destructive,
                      onPressed:
                          () => _handleDisconnectFromSwipe(
                            context,
                            ref,
                            connection,
                            userRole,
                          ),
                    ),
                  ],
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
            ),
          ],

          // Inactive connections section
          if (inactiveConnections.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            _SectionHeader(
              title: AppStrings.invitePreviousSectionFormat(sectionLabel),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.inviteReconnectedFormat(name))),
      );
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

    showNotebookModalBottomSheet<void>(
      context: context,
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
                  backgroundColor: AppColors.paperAccentSoft,
                  child: Text(
                    otherName[0],
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(otherName, style: AppTypography.headingMedium),
                Text(
                  userRole == InviteUserRole.teacher
                      ? AppStrings.student
                      : AppStrings.teacher,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  AppStrings.inviteConnectedDateFormat(
                    _formatDate(connection.connectedAt),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                const ThinRule(),
                ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: AppColors.paperAccent,
                  ),
                  title: const Text(AppStrings.inviteViewLessonSchedule),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    if (userRole == InviteUserRole.teacher) {
                      // Teacher: the student detail screen carries this
                      // connection's lesson schedule.
                      context.push(
                        AppRoutes.studentDetail.replaceFirst(
                          ':id',
                          connection.studentId,
                        ),
                      );
                    } else {
                      context.push(
                        AppRoutes.myBookings,
                        extra: {
                          'studentId': connection.studentId,
                          'studentName': connection.studentName,
                          'teacherId': connection.teacherId,
                          'teacherName': connection.teacherName,
                        },
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.link_off, color: AppColors.paperAccent),
                  title: const Text(AppStrings.inviteDisconnect),
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
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.swipeActionDisconnect,
      content: Text(AppStrings.inviteDisconnectConfirmFormat(otherName)),
      confirmLabel: AppStrings.swipeActionDisconnect,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(connectionManagerProvider.notifier)
          .deactivateConnection(connection.id);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.inviteDisconnectedFormat(otherName)),
          ),
        );
      }
    }
  }

  /// SwipeAction 의 [연결 해제] 진입점.
  /// _handleDeactivate 와 달리 영향 안내를 본문에 포함한 강화 확인 다이얼로그를 띄운다 (#660).
  Future<void> _handleDisconnectFromSwipe(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
    InviteUserRole userRole,
  ) async {
    final otherName =
        userRole == InviteUserRole.teacher
            ? connection.studentName
            : connection.teacherName;

    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.swipeActionDisconnectConfirmTitle,
      content: Text(
        '$otherName님 — ${AppStrings.swipeActionDisconnectConfirmBody}',
      ),
      confirmLabel: AppStrings.swipeActionDisconnect,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(connectionManagerProvider.notifier)
        .deactivateConnection(connection.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.inviteDisconnectedFormat(otherName))),
      );
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
          AppStrings.inviteSectionCountFormat(title, count),
          // Notebook × Score: 이 화면의 다른 섹션 타이틀(§L110)과 동일하게
          // sectionTitle 로 통일 (§1258 헤더 토큰 정합).
          style: NotebookTypography.sectionTitle.copyWith(
            color: AppColors.inkSecondary,
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
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.paperAccentSoft,
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(icon, color: AppColors.paperAccent, size: 20),
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
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary, size: 20),
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
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color:
              isActive
                  ? AppColors.paper
                  : AppColors.inkSoft,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            // Profile image
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  isActive
                      ? AppColors.paperAccentSoft
                      : AppColors.inkSoft,
              backgroundImage:
                  profileImage != null ? NetworkImage(profileImage) : null,
              child:
                  profileImage == null
                      ? Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: AppTypography.headingSmall.copyWith(
                          color:
                              isActive
                                  ? AppColors.paperAccent
                                  : AppColors.inkTertiary,
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
                            color: isActive ? null : AppColors.inkSecondary,
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
                        ? AppStrings.inviteConnectedSinceFormat(
                          formatRelativeDay(connection.connectedAt),
                        )
                        : AppStrings.inviteDisconnectedSinceFormat(
                          formatRelativeDay(
                            connection.deactivatedAt ?? connection.connectedAt,
                          ),
                        ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Actions — active 카드는 SwipeActionTile 의 좌측 swipe 로
            // [연결 해제] 노출. trailing 버튼 중복 배치 금지 (#660).
            if (!isActive && onReconnect != null)
              TextButton(
                onPressed: onReconnect,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paperAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                  ),
                ),
                child: const Text(AppStrings.inviteReconnect),
              ),
          ],
        ),
      ),
    );
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
                ? AppColors.paperOkSoft
                : AppColors.inkSoft,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        isActive
            ? AppStrings.inviteStatusConnected
            : AppStrings.inviteStatusDisconnected,
        style: AppTypography.caption.copyWith(
          color: isActive ? AppColors.paperOk : AppColors.inkTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
