import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/profile_photo_header.dart';
import '../../../../providers/profile/teacher_extended_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/presentation/providers/lesson_stats_provider.dart';
import '../../../students/presentation/providers/grouped_students_provider.dart';
import '../../../students/presentation/widgets/student_form/student_form_dialogs.dart';
import '../providers/background_image_provider.dart';
import '../providers/profile_image_provider.dart';

/// Profile tab with user info and settings
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final name = authState is AuthAuthenticated ? authState.name : '-';
    final email = authState is AuthAuthenticated ? authState.email : '-';
    final teacherId = ref.watch(currentUserIdProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.space4),

          // Profile header
          _buildProfileHeader(context, ref, name, email, teacherId),

          const SizedBox(height: AppSpacing.space6),

          // Stats section
          _buildStatsSection(ref, teacherId),

          const SizedBox(height: AppSpacing.space6),

          // Menu sections
          _buildMenuSection(
            title: '내 프로필',
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                label: '프로필 수정',
                onTap: () => context.push(AppRoutes.extendedProfile),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '레슨 관리',
            items: [
              _MenuItem(
                icon: Icons.access_time,
                label: '레슨 시간 설정',
                subtitle: '시간 길이, 쉬는시간, 시작 간격',
                onTap: () => context.push(AppRoutes.lessonTimeSettings),
              ),
              _MenuItem(
                icon: Icons.calendar_month,
                label: '가용 시간 관리',
                subtitle: '주간 스케줄, 휴무, 예외 시간',
                onTap: () => context.push(AppRoutes.teacherAvailability),
              ),
              _MenuItem(
                icon: Icons.shield_outlined,
                label: '취소/노쇼 정책',
                subtitle: '변경 횟수, 취소 기한, 노쇼 처리',
                onTap:
                    () => context.push(
                      '${AppRoutes.lessonPolicy}?teacherId=$teacherId',
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '설정',
            items: [
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: '알림 설정',
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
              _MenuItem(
                icon: Icons.library_music_outlined,
                label: '녹음 관리',
                onTap: () => context.push(AppRoutes.allRecordings),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '지원',
            items: [
              _MenuItem(
                icon: Icons.help_outline,
                label: '도움말',
                onTap: () => context.push(AppRoutes.help),
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
                onTap: () => context.push(AppRoutes.appInfo),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          _buildMenuSection(
            title: '계정',
            items: [
              _MenuItem(
                icon: Icons.description_outlined,
                label: '이용약관',
                onTap: () => context.push(AppRoutes.termsOfService),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                label: '개인정보처리방침',
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              _MenuItem(
                icon: Icons.logout,
                label: '로그아웃',
                labelColor: AppColors.error,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    String name,
    String email,
    String userId,
  ) {
    final initial = name.isNotEmpty ? name[0] : '?';
    final profileImageAsync = ref.watch(profileImageNotifierProvider(userId));
    final imagePath = profileImageAsync.valueOrNull;
    final backgroundImageAsync =
        ref.watch(backgroundImageNotifierProvider(userId));
    final backgroundPath = backgroundImageAsync.valueOrNull;
    final profileState = ref.watch(teacherExtendedProfileProvider);
    final introduction = profileState.valueOrNull?.introduction;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo header with background + profile avatar
          ProfilePhotoHeader(
            profileImagePath: imagePath,
            backgroundImagePath: backgroundPath,
            initial: initial,
            avatarColor: AppColors.primaryLight,
            backgroundHeight: 140,
            avatarRadius: 40,
            onTapProfile: () =>
                _showImagePickerOptions(context, ref, userId, isBackground: false),
            onTapBackground: () =>
                _showImagePickerOptions(context, ref, userId, isBackground: true),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Name + badge
          Row(
            children: [
              Text(name, style: AppTypography.headingLarge),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '선생님',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Email
          Text(
            email,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),

          // Introduction text
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: Text(
                  (introduction != null && introduction.isNotEmpty)
                      ? introduction
                      : '소개글을 작성해주세요',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: (introduction != null && introduction.isNotEmpty)
                        ? AppColors.textSecondaryLight
                        : AppColors.textTertiaryLight,
                    fontStyle: (introduction != null && introduction.isNotEmpty)
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              InkWell(
                onTap: () => context.push(AppRoutes.profilePreview),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space2,
                    vertical: AppSpacing.space1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '미리보기',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, String teacherId) {
    final lessonStatsAsync = ref.watch(lessonStatsProvider);
    final groupsAsync = ref.watch(groupedStudentsProvider(teacherId));

    // Student count from grouped students
    final studentCountValue = groupsAsync.whenOrNull(
      data: (groups) {
        final total = groups.fold(0, (sum, g) => sum + g.students.length);
        return '$total명';
      },
    ) ?? '-';
    // Lesson stats
    final lessonCountValue =
        lessonStatsAsync.whenOrNull(
          data: (stats) => '${stats['completed'] ?? 0}회',
        ) ??
        '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            _buildStatItem('학생', studentCountValue),
            _buildStatDivider(),
            _buildStatItem('이번 달 레슨', lessonCountValue),
            _buildStatDivider(),
            _buildStatItem(
              '완료율',
              lessonStatsAsync.whenOrNull(
                data: (stats) {
                  final completed = stats['completed'] ?? 0;
                  final total = stats['total'] ?? 0;
                  if (total == 0) return '-';
                  return '${(completed / total * 100).round()}%';
                },
              ) ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildMenuSection({
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
              children:
                  items.asMap().entries.map((entry) {
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
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.trailing == null)
              Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  Future<void> _showImagePickerOptions(
    BuildContext context,
    WidgetRef ref,
    String userId, {
    required bool isBackground,
  }) async {
    final currentPath = isBackground
        ? ref.read(backgroundImageNotifierProvider(userId)).valueOrNull
        : ref.read(profileImageNotifierProvider(userId)).valueOrNull;

    final action = await showImagePickerBottomSheet(
      context,
      title: isBackground ? '배경 사진' : '프로필 사진',
      showDelete: currentPath != null,
    );
    if (action == null || !context.mounted) return;

    if (isBackground) {
      final notifier =
          ref.read(backgroundImageNotifierProvider(userId).notifier);
      if (action == ImagePickerAction.delete) {
        await notifier.removeImage();
        return;
      }
      final source = action == ImagePickerAction.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      await notifier.pickAndSaveImage(source, context);
    } else {
      final notifier =
          ref.read(profileImageNotifierProvider(userId).notifier);
      if (action == ImagePickerAction.delete) {
        await notifier.removeImage();
        return;
      }
      final source = action == ImagePickerAction.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      await notifier.pickAndSaveImage(source, context);
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await ref.read(authNotifierProvider.notifier).logout();
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
