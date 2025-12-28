import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/child_profile.dart';
import '../../../../models/parent_notification_settings.dart';
import '../../../../providers/child_profile_provider.dart';
import '../../../../providers/parent/parent_crud_provider.dart';
import 'child_profile_form_screen.dart';

/// Parent profile tab with settings and child management
class ParentProfileTab extends ConsumerWidget {
  const ParentProfileTab({super.key});

  // TODO: Get from auth provider
  static const _parentId = 'parent_1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childProfilesAsync = ref.watch(childProfilesProvider(_parentId));
    final notificationSettingsAsync =
        ref.watch(notificationSettingsNotifierProvider(_parentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.space4),

            // Profile header
            _buildProfileHeader(context),

            const SizedBox(height: AppSpacing.space6),

            // Connected children section
            _buildChildrenSection(context, ref, childProfilesAsync),

            const SizedBox(height: AppSpacing.space4),

            // Notification settings
            _buildNotificationSection(context, ref, notificationSettingsAsync),

            const SizedBox(height: AppSpacing.space4),

            // General settings
            _buildMenuSection(
              context,
              title: '설정',
              items: [
                _MenuItem(
                  icon: Icons.dark_mode_outlined,
                  label: '다크 모드',
                  trailing: _buildSwitch(false),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.language,
                  label: '언어',
                  trailing: Text(
                    '한국어',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Support section
            _buildMenuSection(
              context,
              title: '지원',
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  label: '도움말',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.feedback_outlined,
                  label: '피드백 보내기',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  label: '앱 정보',
                  trailing: Text(
                    'v1.0.0',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space4),

            // Account section
            _buildMenuSection(
              context,
              title: '계정',
              items: [
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: '이용약관',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: '개인정보처리방침',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  labelColor: AppColors.error,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          // Profile avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.secondary,
                child: Text(
                  '박',
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.space4),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '박부모',
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '학부모',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  'parent@example.com',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            icon: const Icon(Icons.edit_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;

                return Column(
                  children: [
                    _buildMenuItem(item),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: AppSpacing.space4 + 24 + AppSpacing.space3,
                        color: AppColors.borderLight,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 24,
              color: item.labelColor ?? AppColors.textSecondaryLight,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: item.labelColor ?? AppColors.textPrimaryLight,
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.trailing == null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value, {ValueChanged<bool>? onChanged}) {
    return Switch(
      value: value,
      onChanged: onChanged ?? (_) {},
      activeColor: AppColors.primary,
    );
  }

  Widget _buildNotificationSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ParentNotificationSettings?> settingsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '알림 설정',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => _showNotificationSettingsSheet(context, ref),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('상세 설정'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: settingsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.space4),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Text('오류: $error'),
              ),
              data: (settings) {
                // Use default settings if none exist
                final s = settings ??
                    ParentNotificationSettings.defaultSettings(
                      id: 'default',
                      parentId: _parentId,
                    );

                return Column(
                  children: [
                    _buildNotificationItem(
                      icon: Icons.assignment_outlined,
                      label: '과제 알림',
                      subtitle: '새 과제 등록, 미완료 알림',
                      value: s.newAssignment || s.assignmentIncomplete,
                      onChanged: (value) => _toggleNotificationGroup(
                        ref,
                        s,
                        assignmentEnabled: value,
                      ),
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      icon: Icons.schedule,
                      label: '레슨 알림',
                      subtitle: '일정 변경, 취소 알림',
                      value: s.lessonChange || s.lessonCancel,
                      onChanged: (value) => _toggleNotificationGroup(
                        ref,
                        s,
                        lessonEnabled: value,
                      ),
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      icon: Icons.music_note,
                      label: '연습 알림',
                      subtitle: '연습 완료, 스트릭 달성',
                      value: s.practiceComplete || s.streakAchievement,
                      onChanged: (value) => _toggleNotificationGroup(
                        ref,
                        s,
                        practiceEnabled: value,
                      ),
                    ),
                    _buildDivider(),
                    _buildNotificationItem(
                      icon: Icons.payment,
                      label: '결제 알림',
                      subtitle: '결제 요청, 완료 확인 (필수)',
                      value: true,
                      isRequired: true,
                      onChanged: null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    bool isRequired = false,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: AppTypography.bodyLarge),
                    if (isRequired) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '필수',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitch(
            value,
            onChanged: isRequired ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: AppSpacing.space4 + 24 + AppSpacing.space3,
      color: AppColors.borderLight,
    );
  }

  void _toggleNotificationGroup(
    WidgetRef ref,
    ParentNotificationSettings settings, {
    bool? assignmentEnabled,
    bool? lessonEnabled,
    bool? practiceEnabled,
  }) {
    ParentNotificationSettings updated = settings;

    if (assignmentEnabled != null) {
      updated = updated.copyWith(
        newAssignment: assignmentEnabled,
        assignmentIncomplete: assignmentEnabled,
      );
    }
    if (lessonEnabled != null) {
      updated = updated.copyWith(
        lessonChange: lessonEnabled,
        lessonCancel: lessonEnabled,
      );
    }
    if (practiceEnabled != null) {
      updated = updated.copyWith(
        practiceComplete: practiceEnabled,
        streakAchievement: practiceEnabled,
      );
    }

    ref
        .read(notificationSettingsNotifierProvider(_parentId).notifier)
        .saveSettings(updated);
  }

  void _showNotificationSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final settingsAsync =
              ref.watch(notificationSettingsNotifierProvider(_parentId));

          return settingsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (settings) {
              final s = settings ??
                  ParentNotificationSettings.defaultSettings(
                    id: 'default',
                    parentId: _parentId,
                  );

              return _NotificationSettingsSheet(
                settings: s,
                scrollController: scrollController,
                onSettingsChanged: (newSettings) {
                  ref
                      .read(notificationSettingsNotifierProvider(_parentId)
                          .notifier)
                      .saveSettings(newSettings);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChildrenSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ChildProfile>> childProfilesAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '연결된 자녀',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('${AppRoutes.childProfiles}?parentId=$_parentId'),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('관리'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: childProfilesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.space4),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Text('오류: $error'),
              ),
              data: (profiles) => Column(
                children: [
                  ...profiles.map((profile) => _buildChildItem(context, profile)),
                  if (profiles.isNotEmpty)
                    Divider(
                      height: 1,
                      indent: AppSpacing.space4 + 24 + AppSpacing.space3,
                      color: AppColors.borderLight,
                    ),
                  _buildMenuItem(_MenuItem(
                    icon: Icons.add_circle_outline,
                    label: '자녀 추가하기',
                    labelColor: AppColors.primary,
                    onTap: () => _showAddChildDialog(context),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildItem(BuildContext context, ChildProfile profile) {
    return InkWell(
      onTap: () {
        // Navigate to child profile edit
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _buildChildProfileFormScreen(profile),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: profile.profileColor,
              child: Text(
                profile.initial,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(profile.name, style: AppTypography.bodyLarge),
                      const SizedBox(width: 4),
                      Text(
                        '(만 ${profile.age}세)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${profile.instrumentLabel} • ${profile.teacherName ?? "선생님 미연결"}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: profile.isActive
                    ? AppColors.successLight
                    : AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                profile.status.label,
                style: AppTypography.caption.copyWith(
                  color:
                      profile.isActive ? AppColors.success : AppColors.textTertiaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build child profile form screen with existing profile
  Widget _buildChildProfileFormScreen(ChildProfile profile) {
    return ChildProfileFormScreen(
      parentId: _parentId,
      existingProfile: profile,
    );
  }

  void _showAddChildDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('자녀 추가 방법', style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.space2),
              Text(
                '자녀를 추가할 방법을 선택하세요',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Option 1: Add child profile (under 14)
              _AddChildOption(
                icon: Icons.child_care,
                iconColor: AppColors.primary,
                title: '만 14세 미만 자녀 등록',
                description: '별도 계정 없이 학부모 계정에서 관리',
                onTap: () {
                  Navigator.pop(context);
                  context.push('${AppRoutes.addChildProfile}?parentId=$_parentId');
                },
              ),

              const SizedBox(height: AppSpacing.space3),

              // Option 2: Connect existing student
              _AddChildOption(
                icon: Icons.link,
                iconColor: AppColors.secondary,
                title: '기존 학생 연결',
                description: '초대 코드로 만 14세 이상 학생 계정 연결',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.parentInviteCode);
                },
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.login);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.trailing,
    required this.onTap,
  });
}

class _AddChildOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AddChildOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Detailed notification settings sheet
class _NotificationSettingsSheet extends StatefulWidget {
  final ParentNotificationSettings settings;
  final ScrollController scrollController;
  final ValueChanged<ParentNotificationSettings> onSettingsChanged;

  const _NotificationSettingsSheet({
    required this.settings,
    required this.scrollController,
    required this.onSettingsChanged,
  });

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  late ParentNotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSetting(ParentNotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _settings.groupedSettings;

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('알림 상세 설정', style: AppTypography.headingSmall),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Summary
        Container(
          margin:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${_settings.enabledCount}/${ParentNotificationSettings.totalConfigurable}개 알림 활성화',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.space4),

        // Settings list
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            children: [
              for (final category in NotificationCategory.values)
                _buildCategorySection(category, grouped[category] ?? []),
              const SizedBox(height: AppSpacing.space8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
      NotificationCategory category, List<NotificationItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space4,
            bottom: AppSpacing.space2,
          ),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.space2),
              Text(
                category.label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _buildSettingTile(category, item, index),
                  if (!isLast)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
      NotificationCategory category, NotificationItem item, int index) {
    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: AppTypography.bodyMedium.copyWith(
                color: item.isRequired
                    ? AppColors.textTertiaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          if (item.suffix.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.isRequired
                    ? AppColors.textTertiaryLight.withValues(alpha: 0.2)
                    : item.isRecommended
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.suffix,
                style: AppTypography.caption.copyWith(
                  color: item.isRequired
                      ? AppColors.textTertiaryLight
                      : item.isRecommended
                          ? AppColors.success
                          : AppColors.textSecondaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      trailing: Switch(
        value: item.isEnabled,
        onChanged: item.isRequired
            ? null
            : (value) => _handleToggle(category, index, value),
        activeColor: AppColors.primary,
      ),
    );
  }

  void _handleToggle(NotificationCategory category, int index, bool value) {
    ParentNotificationSettings updated = _settings;

    switch (category) {
      case NotificationCategory.payment:
        if (index == 2) updated = updated.copyWith(paymentDueSoon: value);
        break;
      case NotificationCategory.lesson:
        if (index == 0) updated = updated.copyWith(lessonChange: value);
        if (index == 1) updated = updated.copyWith(lessonCancel: value);
        if (index == 2) updated = updated.copyWith(lessonStart: value);
        if (index == 3) updated = updated.copyWith(lessonEnd: value);
        break;
      case NotificationCategory.assignment:
        if (index == 0) updated = updated.copyWith(newAssignment: value);
        if (index == 1) updated = updated.copyWith(assignmentIncomplete: value);
        break;
      case NotificationCategory.practice:
        if (index == 0) updated = updated.copyWith(practiceComplete: value);
        if (index == 1) updated = updated.copyWith(streakAchievement: value);
        break;
      case NotificationCategory.communication:
        if (index == 0) updated = updated.copyWith(teacherMessage: value);
        if (index == 1) updated = updated.copyWith(lessonNoteUpdate: value);
        break;
      case NotificationCategory.report:
        if (index == 0) updated = updated.copyWith(weeklyReport: value);
        if (index == 1) updated = updated.copyWith(monthlyReport: value);
        break;
    }

    _updateSetting(updated);
  }
}
