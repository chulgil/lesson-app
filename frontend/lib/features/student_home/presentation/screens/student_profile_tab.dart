import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/parent_home/domain/entities/parent.dart';
import '../../../../features/parent_home/presentation/providers/parent_crud_provider.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../../../practice/presentation/providers/practice_crud_provider.dart';
import '../../../practice/presentation/providers/practice_repertoire_crud_provider.dart';
import '../../../profile/presentation/providers/invite_provider.dart';
import '../../../students/presentation/providers/student_crud_provider.dart';
import '../providers/practice_reminder_provider.dart';
import '../widgets/language_select_sheet.dart';
import '../widgets/practice_reminder_sheet.dart';

/// Student profile tab with settings and account info
class StudentProfileTab extends ConsumerWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(currentUserIdProvider);
    final studentAsync = ref.watch(studentProvider(studentId));
    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));
    final practiceLogsAsync = ref.watch(practiceLogsProvider(studentId));

    final student = studentAsync.valueOrNull;
    final studentName = student?.name ?? '-';
    final studentInitial = student?.initial ?? '-';
    final studentEmail = student?.email ?? '-';
    final studentInstrument = student?.instrument ?? '-';

    // Stats calculations
    final completedLessonCount =
        lessonsAsync.valueOrNull
            ?.where((l) => l.status == LessonStatus.completed)
            .length ??
        0;
    final totalPracticeMinutes =
        practiceLogsAsync.valueOrNull?.fold<int>(
          0,
          (sum, log) => sum + log.totalMinutes,
        ) ??
        0;
    final totalPracticeHours = totalPracticeMinutes ~/ 60;
    final lessonPeriodMonths =
        student != null
            ? DateTime.now().difference(student.createdAt).inDays ~/ 30
            : 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(
            context,
            name: studentName,
            initial: studentInitial,
            email: studentEmail,
            instrument: studentInstrument,
          ),

          const SizedBox(height: AppSpacing.space6),

          // Stats summary
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildStatsSummary(
              lessonCount:
                  lessonsAsync.isLoading ? null : '$completedLessonCount회',
              practiceTime:
                  practiceLogsAsync.isLoading ? null : '$totalPracticeHours시간',
              period:
                  studentAsync.isLoading
                      ? null
                      : lessonPeriodMonths < 1
                      ? '1개월 미만'
                      : '$lessonPeriodMonths개월',
            ),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildMenuSection(context, ref),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Settings
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildSettingsSection(context, ref),
          ),

          const SizedBox(height: AppSpacing.space6),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _buildLogoutButton(context),
          ),

          const SizedBox(height: AppSpacing.space8),

          // App version
          Text(
            '버전 1.0.0',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryLight,
            ),
          ),

          const SizedBox(height: AppSpacing.space6),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String name,
    required String initial,
    required String email,
    required String instrument,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Profile image
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.space3),

            // Name
            Text(
              name,
              style: AppTypography.headingLarge.copyWith(color: Colors.white),
            ),

            const SizedBox(height: AppSpacing.space1),

            // Email
            Text(
              email,
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),

            const SizedBox(height: AppSpacing.space2),

            // Instrument tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note, size: 16, color: Colors.white),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    instrument,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary({
    String? lessonCount,
    String? practiceTime,
    String? period,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
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
      child: Row(
        children: [
          _buildStatItem('레슨 받은 횟수', lessonCount ?? '-'),
          _buildDivider(),
          _buildStatItem('총 연습 시간', practiceTime ?? '-'),
          _buildDivider(),
          _buildStatItem('레슨 기간', period ?? '-'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.borderLight);
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final studentId = ref.watch(currentUserIdProvider);
    final repertoiresAsync = ref.watch(studentRepertoiresProvider(studentId));
    final repertoireCount = repertoiresAsync.whenOrNull(
      data: (list) => list.where((r) => !r.isArchived).length,
    );
    final connectionsAsync = ref.watch(myConnectionsProvider);
    final teacherSubtitle = connectionsAsync.whenOrNull(
      data: (connections) {
        final active = connections.where((c) => c.isActive).toList();
        if (active.isEmpty) return null;
        if (active.length == 1) return active.first.teacherName;
        return '선생님 ${active.length}명';
      },
    );

    return Container(
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
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: '프로필 수정',
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.school_outlined,
            title: '내 선생님',
            subtitle: teacherSubtitle,
            onTap: () => context.push(AppRoutes.myTeachers),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.assignment_outlined,
            title: AppStrings.lessonRequestMenu,
            onTap: () => context.push(AppRoutes.myLessonRequests),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.library_music_outlined,
            title: '레퍼토리',
            subtitle: repertoireCount != null ? '$repertoireCount곡 진행 중' : null,
            onTap:
                () => context.push(
                  '${AppRoutes.practiceRepertoire}?studentId=$studentId',
                ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: '연습 기록 내역',
            onTap:
                () => context.push(
                  '${AppRoutes.repertoireHistory}?studentId=$studentId',
                ),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.headphones_outlined,
            title: '레슨 녹음 파일',
            subtitle: '전체 녹음 관리',
            onTap: () => context.push(AppRoutes.allRecordings),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.family_restroom,
            iconColor: AppColors.secondary,
            title: '학부모 초대',
            subtitle: '학부모님과 연결하기',
            onTap: () => _showInviteCodeDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    final reminderSettings = ref.watch(practiceReminderProvider);
    return Container(
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
        children: [
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            subtitle: '카테고리별 알림 관리',
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.alarm_outlined,
            title: '연습 리마인더',
            subtitle:
                reminderSettings.isEnabled
                    ? reminderSettings.formattedTime
                    : '꺼짐',
            onTap: () => PracticeReminderSheet.show(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.dark_mode_outlined,
            title: '다크 모드',
            trailing: Switch(
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('다크 모드는 준비 중입니다')));
              },
              activeThumbColor: AppColors.primary,
            ),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('다크 모드는 준비 중입니다')));
            },
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.language_outlined,
            title: '언어',
            subtitle: '한국어',
            onTap: () => LanguageSelectSheet.show(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.backup_outlined,
            title: '녹음 백업',
            onTap: () => context.push(AppRoutes.backupSettings),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '도움말',
            onTap: () => context.push(AppRoutes.help),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: '앱 정보',
            onTap: () => context.push(AppRoutes.appInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                color:
                    iconColor?.withValues(alpha: 0.1) ??
                    AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      indent: AppSpacing.space4 + 36 + AppSpacing.space3,
      color: AppColors.borderLight,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: Icon(Icons.logout, color: AppColors.error),
        label: Text('로그아웃', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.login);
                },
                child: Text('로그아웃', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );
  }

  void _showInviteCodeDialog(BuildContext context, WidgetRef ref) {
    // Generate a random 6-character alphanumeric invite code
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final inviteCode =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
    final studentId = ref.read(currentUserIdProvider);

    // Create and save the invitation to the repository
    final invitation = ParentInvitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      studentId: studentId,
      source: InvitationSource.student,
      parentPhone: '',
      invitationCode: inviteCode,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

    ref
        .read(invitationsNotifierProvider(studentId).notifier)
        .createInvitation(invitation);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('학부모 초대 코드'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('학부모님을 초대합니다', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.space4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space5,
                    vertical: AppSpacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        inviteCode.split('').map((digit) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space1,
                            ),
                            child: Text(
                              digit,
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '이 코드를 학부모님께 전달해주세요.\n학부모님이 앱에서 코드를 입력하면\n연결됩니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '* 코드는 24시간 동안 유효합니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('초대 코드가 복사되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('복사'),
              ),
              FilledButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          '[레슨앱] 학부모 초대\n\n'
                          '학생의 학부모님을 초대합니다.\n\n'
                          '초대 코드: $inviteCode\n\n'
                          '앱을 설치하고 위 코드를 입력해주세요.',
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('공유'),
              ),
            ],
          ),
    );
  }
}
