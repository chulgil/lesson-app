import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/parent_home/domain/entities/parent.dart';
import '../../../../features/students/domain/entities/student.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../lessons/presentation/providers/lesson_crud_provider.dart';
import '../../../parent_home/presentation/providers/parent_crud_provider.dart';
import '../../../practice/presentation/providers/practice_crud_provider.dart';
import '../../presentation/providers/student_crud_provider.dart';
import '../providers/student_image_provider.dart';
import '../widgets/student_detail/student_detail_widgets.dart';

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
                    // Stats cards (neutral tone, no icons)
                    StudentStatsCards(student: student),

                    const SizedBox(height: AppSpacing.space6),

                    // Upcoming lessons — teacher's primary concern
                    StudentUpcomingLessonsSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space6),

                    // Subscription status (수강권 현황)
                    StudentSubscriptionSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space6),

                    // Recent lesson history
                    StudentRecentLessonsSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space6),

                    // Lesson notes history
                    StudentNotesSection(studentId: student.id),

                    const SizedBox(height: AppSpacing.space6),

                    // Practice progress this week
                    StudentPracticeSection(studentId: student.id),

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
          context.push('${AppRoutes.addLesson}?studentId=${student.id}');
        },
        icon: const Icon(Icons.add),
        label: const Text('레슨 예약'),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final profileImagePath =
        ref.watch(studentProfileImageNotifierProvider(student.id)).valueOrNull;
    final backgroundImagePath =
        ref.watch(studentBackgroundImageNotifierProvider(student.id)).valueOrNull;

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
            context.push(AppRoutes.editStudent.replaceFirst(':id', student.id));
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
        background: _buildAppBarBackground(
          profileImagePath: profileImagePath,
          backgroundImagePath: backgroundImagePath,
        ),
      ),
    );
  }

  Widget _buildAppBarBackground({
    String? profileImagePath,
    String? backgroundImagePath,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: image or gradient
        if (backgroundImagePath != null && backgroundImagePath.isNotEmpty)
          _buildBackgroundImage(backgroundImagePath)
        else
          _buildDefaultGradientBackground(),

        // Dark overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: _resolveStudentProfileImage(profileImagePath),
                child: _resolveStudentProfileImage(profileImagePath) == null
                    ? Text(
                        student.initial,
                        style: AppTypography.displayMedium.copyWith(
                          color: student.profileColor,
                        ),
                      )
                    : null,
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
      ],
    );
  }

  Widget _buildBackgroundImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultGradientBackground(),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildDefaultGradientBackground(),
    );
  }

  Widget _buildDefaultGradientBackground() {
    return Container(
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
    );
  }

  ImageProvider? _resolveStudentProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return NetworkImage(imagePath);
    final file = File(imagePath);
    if (file.existsSync()) return FileImage(file);
    return null;
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
              enabled: student.phone != null && student.phone!.isNotEmpty,
              subtitle: student.phone == null || student.phone!.isEmpty
                  ? const Text('전화번호가 등록되지 않았습니다')
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (student.phone != null && student.phone!.isNotEmpty) {
                  launchUrl(Uri.parse('tel:${student.phone}'));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('메시지 보내기'),
              enabled: student.phone != null && student.phone!.isNotEmpty,
              subtitle: student.phone == null || student.phone!.isEmpty
                  ? const Text('전화번호가 등록되지 않았습니다')
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (student.phone != null && student.phone!.isNotEmpty) {
                  launchUrl(Uri.parse('sms:${student.phone}'));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('레슨 기록 보기'),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  AppRoutes.studentNotes.replaceFirst(':id', student.id),
                );
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
                    try {
                      await ref
                          .read(studentsNotifierProvider.notifier)
                          .updateStudentStatus(student.id, StudentStatus.active);
                      ref.invalidate(studentProvider(student.id));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('상태 변경에 실패했습니다. 다시 시도해주세요.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
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
                    try {
                      await ref
                          .read(studentsNotifierProvider.notifier)
                          .updateStudentStatus(student.id, StudentStatus.paused);
                      ref.invalidate(studentProvider(student.id));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('상태 변경에 실패했습니다. 다시 시도해주세요.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
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
                    try {
                      await ref
                          .read(studentsNotifierProvider.notifier)
                          .updateStudentStatus(student.id, StudentStatus.active);
                      ref.invalidate(studentProvider(student.id));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('상태 변경에 실패했습니다. 다시 시도해주세요.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
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
                  try {
                    await ref.read(studentsNotifierProvider.notifier).deleteStudent(student.id);
                    if (context.mounted) {
                      context.pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('학생 삭제에 실패했습니다. 다시 시도해주세요.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
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
        content: Text('${student.name} 학생을 삭제하시겠습니까?\n\n관련된 모든 레슨 기록과 연습 기록이 함께 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
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

  Future<void> _showInviteCodeDialog(BuildContext context, String studentName, WidgetRef ref) async {
    // Generate a random 6-character alphanumeric invite code
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final inviteCode = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();

    // Create and save the invitation
    final teacherId = ref.read(currentUserIdProvider);
    final invitation = ParentInvitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      studentId: student.id,
      teacherId: teacherId,
      source: InvitationSource.teacher,
      parentPhone: '', // Will be filled when parent registers
      invitationCode: inviteCode,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

    // Save invitation with error handling
    try {
      await ref.read(invitationsNotifierProvider(student.id).notifier).createInvitation(invitation);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('초대 코드 생성에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

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
              Navigator.pop(context);
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
