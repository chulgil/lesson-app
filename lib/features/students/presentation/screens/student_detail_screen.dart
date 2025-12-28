import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../models/parent.dart';
import '../../../../models/practice.dart';
import '../../../../models/student.dart';
import '../../../../providers/providers.dart';

/// Student detail screen showing profile, lessons, and practice stats
class StudentDetailScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(studentId));

    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: AppColors.textTertiaryLight),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    '학생을 찾을 수 없습니다',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _StudentDetailContent(student: student);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.space4),
              Text(
                '데이터를 불러오는데 실패했습니다',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(studentProvider(studentId)),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentDetailContent extends ConsumerWidget {
  final Student student;

  const _StudentDetailContent({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProvider(student.id));
          ref.invalidate(lessonsByStudentProvider(student.id));
          ref.invalidate(weeklyPracticeProvider(student.id));
        },
        child: CustomScrollView(
          slivers: [
            // App bar with profile header
            _buildSliverAppBar(context, ref),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats cards
                    _StatsCards(student: student),

                    const SizedBox(height: AppSpacing.space6),

                    // Practice progress this week
                    _PracticeSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space6),

                    // Upcoming lessons
                    _UpcomingLessonsSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space6),

                    // Recent lesson history
                    _RecentLessonsSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/lessons/add?studentId=${student.id}');
        },
        icon: const Icon(Icons.add),
        label: const Text('레슨 예약'),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.push('/students/${student.id}/edit');
          },
          icon: const Icon(Icons.edit),
        ),
        IconButton(
          onPressed: () {
            _showMoreOptions(context, ref);
          },
          icon: const Icon(Icons.more_vert),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                student.profileColor,
                student.profileColor.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    student.initial,
                    style: AppTypography.displayMedium.copyWith(
                      color: student.profileColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),

                // Name
                Text(
                  student.name,
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),

                // Status, Instrument and Practice badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enrollment status badge (체험/정규/휴강/종료)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: student.status.color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        student.status.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    // Instrument badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        student.instrument,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    // Practice status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: student.practiceStatus.color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: student.practiceStatus.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.practiceStatus.label,
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space2),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('전화하기'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('메시지 보내기'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('레슨 기록 보기'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // Show status change options based on current status
            if (student.status == StudentStatus.trial) ...[
              ListTile(
                leading: Icon(Icons.upgrade, color: AppColors.practiceGood),
                title: Text(
                  '정규 전환',
                  style: TextStyle(color: AppColors.practiceGood),
                ),
                subtitle: const Text('체험 학생을 정규 학생으로 전환'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showStatusChangeConfirmation(
                    context,
                    '정규 전환',
                    '${student.name} 학생을 정규 학생으로 전환하시겠습니까?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(studentsNotifierProvider.notifier)
                        .updateStudentStatus(student.id, StudentStatus.active);
                    ref.invalidate(studentProvider(student.id));
                  }
                },
              ),
            ],
            if (student.status == StudentStatus.active) ...[
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('휴강 설정'),
                subtitle: const Text('일시적으로 레슨을 중단'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showStatusChangeConfirmation(
                    context,
                    '휴강 설정',
                    '${student.name} 학생을 휴강 상태로 변경하시겠습니까?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(studentsNotifierProvider.notifier)
                        .updateStudentStatus(student.id, StudentStatus.paused);
                    ref.invalidate(studentProvider(student.id));
                  }
                },
              ),
            ],
            if (student.status == StudentStatus.paused) ...[
              ListTile(
                leading: Icon(Icons.play_circle_outline, color: AppColors.practiceGood),
                title: Text(
                  '레슨 재개',
                  style: TextStyle(color: AppColors.practiceGood),
                ),
                subtitle: const Text('휴강 상태를 해제하고 레슨 재개'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showStatusChangeConfirmation(
                    context,
                    '레슨 재개',
                    '${student.name} 학생의 레슨을 재개하시겠습니까?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(studentsNotifierProvider.notifier)
                        .updateStudentStatus(student.id, StudentStatus.active);
                    ref.invalidate(studentProvider(student.id));
                  }
                },
              ),
            ],
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.family_restroom, color: AppColors.secondary),
              title: const Text('학부모 초대'),
              subtitle: const Text('학부모 연결을 위한 초대 코드 생성'),
              onTap: () {
                Navigator.pop(context);
                _showInviteCodeDialog(context, student.name, ref);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                '학생 삭제',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed == true) {
                  await ref.read(studentsNotifierProvider.notifier).deleteStudent(student.id);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학생 삭제'),
        content: Text('${student.name} 학생을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showStatusChangeConfirmation(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showInviteCodeDialog(BuildContext context, String studentName, WidgetRef ref) {
    // Generate a random 6-character alphanumeric invite code
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final inviteCode = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();

    // Create and save the invitation
    final invitation = ParentInvitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      studentId: student.id,
      teacherId: 'teacher_1', // TODO: Get from auth
      source: InvitationSource.teacher,
      parentPhone: '', // Will be filled when parent registers
      invitationCode: inviteCode,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

    // Save invitation asynchronously
    ref.read(invitationsNotifierProvider(student.id).notifier).createInvitation(invitation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('학부모 초대 코드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$studentName 학생의 학부모를 초대합니다',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.space4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space5,
                vertical: AppSpacing.space4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: inviteCode.split('').map((digit) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
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
              '이 코드를 학부모님께 전달해주세요.\n학부모님이 앱에서 코드를 입력하면\n자녀와 연결됩니다.',
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
                  text: '[레슨앱] 학부모 초대\n\n'
                      '$studentName 학생의 학부모님을 초대합니다.\n\n'
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

class _StatsCards extends StatelessWidget {
  final Student student;

  const _StatsCards({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_month,
            value: '${student.totalLessons}',
            label: '총 레슨',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            icon: Icons.event_note,
            value: '${student.monthlyLessons}',
            label: '이번 달',
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            icon: Icons.fitness_center,
            value: '${student.practiceRate}일',
            label: '주간 연습',
            color: student.practiceStatus.color,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.space2),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeSection extends ConsumerWidget {
  final String studentId;

  const _PracticeSection({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final weeklyPracticeAsync = ref.watch(weeklyPracticeProvider(studentId));
    final todayPracticeAsync = ref.watch(todayPracticeProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('이번 주 연습', style: AppTypography.headingSmall),
            weeklyPracticeAsync.when(
              data: (practiced) => Text(
                '${practiced.where((p) => p).length}/7일',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),

        // Practice calendar
        weeklyPracticeAsync.when(
          data: (practiced) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isPracticed = index < practiced.length && practiced[index];
                return Column(
                  children: [
                    Text(
                      days[index],
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPracticed
                            ? AppColors.practiceGood.withValues(alpha: 0.15)
                            : AppColors.surfaceSecondaryLight,
                        shape: BoxShape.circle,
                        border: isPracticed
                            ? Border.all(color: AppColors.practiceGood, width: 2)
                            : null,
                      ),
                      child: Icon(
                        isPracticed ? Icons.check : Icons.remove,
                        size: 18,
                        color: isPracticed
                            ? AppColors.practiceGood
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: Text('연습 정보를 불러올 수 없습니다'),
          ),
        ),

        const SizedBox(height: AppSpacing.space3),

        // Today's practice tasks
        todayPracticeAsync.when(
          data: (practiceLog) {
            if (practiceLog == null || practiceLog.tasks.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: practiceLog.tasks.map((task) => _buildTaskRow(task)).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTaskRow(PracticeTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 20,
            color: task.isCompleted
                ? AppColors.practiceGood
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              task.title,
              style: AppTypography.bodyMedium.copyWith(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted
                    ? AppColors.textTertiaryLight
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            '${task.targetMinutes}분',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingLessonsSection extends ConsumerWidget {
  final String studentId;

  const _UpcomingLessonsSection({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('다가오는 레슨', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () {
                // Navigate to full lessons list
              },
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        lessonsAsync.when(
          data: (lessons) {
            final upcomingLessons = lessons
                .where((l) => l.isUpcoming)
                .take(3)
                .toList();

            if (upcomingLessons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: AppColors.textTertiaryLight),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      '예정된 레슨이 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: upcomingLessons
                  .map((lesson) => _LessonCard(lesson: lesson, isUpcoming: true))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text('레슨 정보를 불러올 수 없습니다'),
          ),
        ),
      ],
    );
  }
}

class _RecentLessonsSection extends ConsumerWidget {
  final String studentId;

  const _RecentLessonsSection({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsByStudentProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 레슨', style: AppTypography.headingSmall),
            TextButton(
              onPressed: () {
                // Navigate to full lesson history
              },
              child: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        lessonsAsync.when(
          data: (lessons) {
            final recentLessons = lessons
                .where((l) => l.status == LessonStatus.completed)
                .take(3)
                .toList();

            if (recentLessons.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.space4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.textTertiaryLight),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      '완료된 레슨이 없습니다',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: recentLessons
                  .map((lesson) => _LessonCard(lesson: lesson, isUpcoming: false))
                  .toList(),
            );
          },
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Text('레슨 기록을 불러올 수 없습니다'),
          ),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isUpcoming;

  const _LessonCard({
    required this.lesson,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: isUpcoming
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/lessons/${lesson.id}');
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceSecondaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Column(
                  children: [
                    Text(
                      '${lesson.date.day}',
                      style: AppTypography.headingSmall.copyWith(
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      DateFormat('E', 'ko').format(lesson.date),
                      style: AppTypography.caption.copyWith(
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.space3),

              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.startTime} (${lesson.duration}분)',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (lesson.pieces.isNotEmpty)
                      Text(
                        lesson.pieces.first.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    if (!isUpcoming && lesson.feedback != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Row(
                        children: [
                          Icon(
                            Icons.comment,
                            size: 14,
                            color: AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lesson.feedback!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Indicators
              Column(
                children: [
                  if (lesson.hasRecordings)
                    Icon(
                      Icons.mic,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  if (lesson.hasFeedback)
                    Icon(
                      Icons.note,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                ],
              ),

              const SizedBox(width: AppSpacing.space2),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
