import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../widgets/student_detail/student_contact_actions.dart';
import '../../../../features/students/students_facade.dart'
    show
        Student,
        StudentStatus,
        studentProfileImageNotifierProvider,
        studentProvider,
        studentsNotifierProvider;
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../../parent_home/parent_home_facade.dart'
    show InvitationSource, ParentInvitation, invitationsNotifierProvider;
import '../extensions/student_domain_visuals.dart';
import '../widgets/student_detail/student_detail_widgets.dart';
import '../../../lessons/lessons_facade.dart';

/// Student detail screen — Notebook × Score 레이아웃.
///
/// 정체성 4 적용:
/// - Playfair: NotebookMasthead eyebrow + 학생명 (pieceTitle)
/// - 로마숫자: 탭 인덱스 (I. 정보 / II. 레슨 / III. 연습)
/// - Vermillion: 파괴적 액션 (학생 삭제) + 체험 상태 텍스트
/// - Gaegu: (해당 없음 — 본 화면은 메타 카드 위주)
///
/// 구조 2 적용:
/// - NotebookMasthead: 상단 2px ink + 1px ink 라인 사이 헤더
/// - 헤더 액션(+): 레슨 추가 진입점 우선 배치
class StudentDetailScreen extends ConsumerWidget {
  final String studentId;
  final String? membershipId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    this.membershipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentProvider(studentId));

    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return _buildShellScaffold(
            context,
            child: _buildEmptyMessage(
              icon: Icons.person_off,
              message: AppStrings.studentNotFound,
            ),
          );
        }

        return _StudentDetailContent(
          student: student,
          membershipId: membershipId,
        );
      },
      loading:
          () => _buildShellScaffold(
            context,
            child: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => _buildShellScaffold(
            context,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.paperAccent,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  AppStrings.loadDataFailed,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(studentProvider(studentId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildShellScaffold(BuildContext context, {required Widget child}) {
    return NotebookScreenScaffold(
      backgroundColor: AppColors.paper,
      appBar: const NotebookDetailAppBar(title: AppStrings.studentDetailTitle),
      body: SafeArea(child: child),
    );
  }

  Widget _buildEmptyMessage({required IconData icon, required String message}) {
    return EmptyStateWidget(icon: icon, title: message);
  }
}

class _StudentDetailContent extends ConsumerWidget {
  final Student student;
  final String? membershipId;

  const _StudentDetailContent({required this.student, this.membershipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileImagePath =
        ref.watch(studentProfileImageNotifierProvider(student.id)).valueOrNull;

    return DefaultTabController(
      length: 3,
      child: NotebookScreenScaffold(
        backgroundColor: AppColors.paper,
        appBar: NotebookDetailAppBar(
          title: student.name,
          actions: [DetailAppBarAction.add],
          onLeadingTap: () => context.pop(),
          onAction: (action) {
            if (action == DetailAppBarAction.add) {
              context.push('${AppRoutes.addLesson}?studentId=${student.id}');
            }
          },
          customActions: [
            IconButton(
              onPressed: () => _showMoreOptions(context, ref),
              icon: const Icon(Icons.more_vert, color: AppColors.ink, size: 22),
              tooltip: 'more',
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── 신원 스트립: 모노그램 + 학생명 + 메타 라인 ──
              ColoredBox(
                color: AppColors.paper,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.space5,
                        AppSpacing.screenPadding,
                        AppSpacing.space4,
                      ),
                      child: Column(
                        children: [
                          _StudentMonogram(
                            student: student,
                            profileImagePath: profileImagePath,
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          Text(
                            student.name,
                            style: NotebookTypography.masthead.copyWith(
                              fontSize: 28,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          _StudentMetaLine(student: student),
                          if (student.phone != null &&
                              student.phone!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.space3),
                            StudentContactActions(phone: student.phone),
                          ],
                        ],
                      ),
                    ),
                    const ThinRule(),
                    // ── 로마숫자 탭 ──
                    const _RomanTabBar(),
                    const ThinRule(),
                  ],
                ),
              ),
              // ── 본문: 3 탭 콘텐츠 ──
              Expanded(
                child: TabBarView(
                  children: [
                    StudentInfoTab(
                      student: student,
                      membershipId: membershipId,
                    ),
                    StudentLessonsTab(studentId: student.id),
                    StudentPracticeTab(studentId: student.id),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    showNotebookBottomSheet<void>(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _MoreSectionLabel(
                title: AppStrings.managementSectionTitle,
              ),
              _MoreOptionTile(
                icon: Icons.edit_outlined,
                title: AppStrings.studentEditInfoTitle,
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    AppRoutes.editStudent.replaceFirst(':id', student.id),
                  );
                },
              ),
              _MoreOptionTile(
                icon: Icons.history,
                title: AppStrings.studentViewLessonHistory,
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    AppRoutes.studentNotes.replaceFirst(':id', student.id),
                  );
                },
              ),
              _MoreOptionTile(
                icon: Icons.file_download_outlined,
                title: AppStrings.exportTitle,
                hint: 'CSV · PDF',
                onTap: () {
                  Navigator.pop(context);
                  showNotebookModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder:
                        (_) => LessonExportSheet(
                          studentId: student.id,
                          studentName: student.name,
                        ),
                  );
                },
              ),
              _MoreOptionTile(
                icon: Icons.family_restroom,
                title: AppStrings.studentParentInviteLabel,
                hint: AppStrings.studentParentInviteHint,
                onTap: () {
                  Navigator.pop(context);
                  _showInviteCodeDialog(context, student.name, ref);
                },
              ),
              const _MoreSectionLabel(
                title: AppStrings.studentStatusChangeSection,
              ),
              if (student.status == StudentStatus.trial)
                _MoreOptionTile(
                  icon: Icons.upgrade,
                  title: AppStrings.studentConvertRegular,
                  hint: AppStrings.studentConvertRegularHint,
                  onTap:
                      () => _confirmStatusChange(
                        context,
                        ref,
                        newStatus: StudentStatus.active,
                        dialogTitle: '정규 전환',
                        dialogBody: '${student.name} 학생을 정규 학생으로 전환하시겠습니까?',
                      ),
                ),
              if (student.status == StudentStatus.active)
                _MoreOptionTile(
                  icon: Icons.pause_circle_outline,
                  title: AppStrings.studentPauseTitle,
                  hint: AppStrings.studentPauseHint,
                  onTap:
                      () => _confirmStatusChange(
                        context,
                        ref,
                        newStatus: StudentStatus.paused,
                        dialogTitle: '휴강 설정',
                        dialogBody: '${student.name} 학생을 휴강 상태로 변경하시겠습니까?',
                      ),
                ),
              if (student.status == StudentStatus.paused)
                _MoreOptionTile(
                  icon: Icons.play_circle_outline,
                  title: AppStrings.studentResumeTitle,
                  hint: AppStrings.studentResumeHint,
                  onTap:
                      () => _confirmStatusChange(
                        context,
                        ref,
                        newStatus: StudentStatus.active,
                        dialogTitle: '레슨 재개',
                        dialogBody: '${student.name} 학생의 레슨을 재개하시겠습니까?',
                      ),
                ),
              const _MoreOptionDivider(),
              _MoreOptionTile(
                icon: Icons.archive_outlined,
                title: AppStrings.studentArchiveTitle,
                isDestructive: true,
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showArchiveConfirmation(context);
                  if (confirmed == true) {
                    try {
                      await ref
                          .read(studentsNotifierProvider.notifier)
                          .archiveStudent(student.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.studentArchivedSnack),
                          ),
                        );
                        context.pop();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(AppStrings.studentArchiveFailed),
                            backgroundColor: AppColors.paperAccent,
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
    );
  }

  Future<void> _confirmStatusChange(
    BuildContext context,
    WidgetRef ref, {
    required StudentStatus newStatus,
    required String dialogTitle,
    required String dialogBody,
  }) async {
    Navigator.pop(context);
    final confirmed = await _showStatusChangeConfirmation(
      context,
      dialogTitle,
      dialogBody,
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(studentsNotifierProvider.notifier)
          .updateStudentStatus(student.id, newStatus);
      ref.invalidate(studentProvider(student.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.studentStatusChangeFailed),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Future<bool?> _showArchiveConfirmation(BuildContext context) {
    return showNotebookDialog(
      context: context,
      title: AppStrings.studentArchiveTitle,
      message:
          '${student.name} 학생을 보관하시겠습니까?\n\n${AppStrings.studentArchiveMessage}',
      confirmLabel: AppStrings.archive,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    );
  }

  Future<bool?> _showStatusChangeConfirmation(
    BuildContext context,
    String title,
    String message,
  ) {
    return showNotebookDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: AppStrings.confirm,
      cancelLabel: AppStrings.cancel,
    );
  }

  Future<void> _showInviteCodeDialog(
    BuildContext context,
    String studentName,
    WidgetRef ref,
  ) async {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final inviteCode =
        List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();

    final teacherId = ref.read(currentUserIdProvider);
    final invitation = ParentInvitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      studentId: student.id,
      teacherId: teacherId,
      source: InvitationSource.teacher,
      parentPhone: '',
      invitationCode: inviteCode,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

    try {
      await ref
          .read(invitationsNotifierProvider(student.id).notifier)
          .createInvitation(invitation);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.studentInviteCodeFailed),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showNotebookDialog(
      context: context,
      titleWidget: const Text(AppStrings.studentParentInviteCode),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$studentName 학생의 학부모를 초대합니다', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              border: Border.all(color: AppColors.paperAccent),
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
                          color: AppColors.paperAccent,
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
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.inviteParentValidityNote,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
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
                content: Text(AppStrings.inviteCodeCopiedSnack),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text(AppStrings.studentCopyLabel),
        ),
        FilledButton.icon(
          onPressed: () {
            SharePlus.instance.share(
              ShareParams(
                text:
                    '[레슨앱] 학부모 초대\n\n'
                    '$studentName 학생의 학부모님을 초대합니다.\n\n'
                    '초대 코드: $inviteCode\n${AppStrings.inviteParentShareValidity}\n\n'
                    '앱을 설치하고 위 코드를 입력해주세요.',
              ),
            );
          },
          icon: const Icon(Icons.share, size: 18),
          label: const Text(AppStrings.studentShareLabel),
        ),
      ],
    );
  }
}

/// 학생 모노그램 — 64dp paper bg + 1px ink stroke + Playfair initial.
/// 프로필 이미지가 있으면 이미지로 대체.
class _StudentMonogram extends StatelessWidget {
  final Student student;
  final String? profileImagePath;

  const _StudentMonogram({required this.student, this.profileImagePath});

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage(profileImagePath);

    if (image != null) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 1),
          image: DecorationImage(image: image, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.paper,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        student.initial,
        style: NotebookTypography.masthead.copyWith(
          fontSize: 28,
          color: AppColors.ink,
        ),
      ),
    );
  }

  ImageProvider? _resolveImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http')) return NetworkImage(imagePath);
    final file = File(imagePath);
    if (file.existsSync()) return FileImage(file);
    return null;
  }
}

/// 학생 메타 라인 — "악기 · 상태 · 연습상태".
/// 색 채움 칩 대신 단일 행 텍스트 (3색 이하 원칙).
/// 체험 상태만 Vermillion 액센트로 강조.
class _StudentMetaLine extends StatelessWidget {
  final Student student;

  const _StudentMetaLine({required this.student});

  @override
  Widget build(BuildContext context) {
    final isTrial = student.status == StudentStatus.trial;
    final statusColor =
        isTrial ? AppColors.paperAccent : AppColors.inkSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            student.instrument,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '  ·  ',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        Text(
          student.status.label,
          style: AppTypography.bodySmall.copyWith(
            color: statusColor,
            fontWeight: isTrial ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '  ·  ',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
        ),
        Text(
          student.practiceStatus.label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

/// 로마숫자 탭바 — I. 정보 / II. 레슨 / III. 연습.
class _RomanTabBar extends StatelessWidget {
  const _RomanTabBar();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: AppColors.ink,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.ink,
      unselectedLabelColor: AppColors.inkTertiary,
      labelStyle: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: AppTypography.bodyMedium,
      dividerColor: Colors.transparent,
      tabs: [
        Tab(child: _RomanTab(roman: 'I.', label: AppStrings.studentTabInfo)),
        Tab(
          child: _RomanTab(roman: 'II.', label: AppStrings.studentTabLessons),
        ),
        Tab(
          child: _RomanTab(roman: 'III.', label: AppStrings.studentTabPractice),
        ),
      ],
    );
  }
}

class _RomanTab extends StatelessWidget {
  final String roman;
  final String label;

  const _RomanTab({required this.roman, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(roman, style: NotebookTypography.roman.copyWith(fontSize: 12)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

/// More options 시트 섹션 구분선 — 좌우 padding 적용한 ThinRule.
class _MoreOptionDivider extends StatelessWidget {
  const _MoreOptionDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
    child: ThinRule(),
  );
}

/// More options 시트의 ink-only ListTile.
/// hint = subtitle (회색), enabled=false 시 비활성, isDestructive=true 시 Vermillion.
class _MoreSectionLabel extends StatelessWidget {
  final String title;

  const _MoreSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space1,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.inkTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MoreOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MoreOptionTile({
    required this.icon,
    required this.title,
    this.hint,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? AppColors.paperAccent : AppColors.ink;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: AppTypography.bodyLarge.copyWith(color: color)),
      subtitle:
          hint != null
              ? Text(
                hint!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              )
              : null,
      onTap: onTap,
    );
  }
}
