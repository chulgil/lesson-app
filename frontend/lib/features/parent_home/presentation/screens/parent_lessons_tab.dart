import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/lessons/presentation/extensions/lesson_visuals.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_masthead.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../auth/auth_facade.dart';
import '../../../lessons/lessons_facade.dart' as lessons;
import '../../domain/entities/child_profile.dart';
import '../providers/child_profile_provider.dart';
import '../providers/parent_crud_provider.dart';

/// Parent lessons tab for viewing the selected child's lesson schedule.
///
/// Resolves the selected child -> linked student -> real lessons. Lesson notes
/// are gated by [ParentVisibilitySettings] set by the teacher (data-privacy P0).
class ParentLessonsTab extends ConsumerWidget {
  const ParentLessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(currentUserIdProvider);
    final selectedProfile = ref.watch(selectedChildProfileProvider);
    final childrenAsync = ref.watch(childProfilesProvider(parentId));

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: childrenAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _LessonsMessageState(
            message: AppStrings.parentHomeLessonLoadError,
          ),
          data: (profiles) {
            if (profiles.isEmpty) {
              return const _LessonsMessageState(
                message: AppStrings.parentHomeNoChildren,
              );
            }
            final profile = selectedProfile ?? profiles.first;
            return _ChildLessonsView(profile: profile);
          },
        ),
      ),
    );
  }
}

/// Renders a child's real lessons (upcoming / past) or a not-linked state.
class _ChildLessonsView extends ConsumerWidget {
  const _ChildLessonsView({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedStudentId = profile.linkedStudentId;
    if (linkedStudentId == null) {
      return const _LessonsMessageState(
        message: AppStrings.parentHomeChildNotLinked,
        hint: AppStrings.parentHomeChildNotLinkedHint,
      );
    }

    final lessonsAsync = ref.watch(
      lessons.lessonsByStudentProvider(linkedStudentId),
    );

    return lessonsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _LessonsMessageState(
        message: AppStrings.parentHomeLessonLoadError,
      ),
      data: (allLessons) => _LessonsList(
        profile: profile,
        lessonItems: allLessons,
        onRefresh: () =>
            ref.invalidate(lessons.lessonsByStudentProvider(linkedStudentId)),
      ),
    );
  }
}

class _LessonsList extends StatelessWidget {
  const _LessonsList({
    required this.profile,
    required this.lessonItems,
    required this.onRefresh,
  });

  final ChildProfile profile;
  final List<lessons.Lesson> lessonItems;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final visible = lessonItems.where((l) => !l.isArchived).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final upcoming = visible
        .where((l) => l.displayStatus == lessons.LessonStatus.scheduled)
        .toList();
    final past = visible
        .where((l) => l.displayStatus != lessons.LessonStatus.scheduled)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notebook × Score: §1.2 #5 Masthead — tier-1 진입 시그니처.
            NotebookMasthead(
              eyebrow: 'LESSONAZA',
              // H2 — 로고는 배경으로 물러나고 본문 글자가 먼저 읽히게 한다.
              eyebrowStyle: NotebookTypography.wordmark,
              meta: 'VOL. ${now.month} · NO. ${now.day}',
            ),
            const SizedBox(height: AppSpacing.space4),
            const ThinRule(),
            const SizedBox(height: AppSpacing.space4),

            // Upcoming lessons
            // Notebook × Score: 페이지 섹션 제목은 Playfair sectionTitle 로 통일 (§7.17 패턴).
            Text(
              AppStrings.parentHomeUpcomingLessons,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            if (upcoming.isEmpty)
              const _LessonsEmptyRow(
                message: AppStrings.noUpcomingLessons,
              )
            else
              for (final lesson in upcoming) ...[
                _LessonCard(
                  profile: profile,
                  lesson: lesson,
                  onTap: () => context.push(
                    AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],

            const SizedBox(height: AppSpacing.space5),

            // Past lessons
            Text(
              AppStrings.parentHomePastLessons,
              style: NotebookTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.space3),
            if (past.isEmpty)
              const _LessonsEmptyRow(
                message: AppStrings.parentHomeNoPastLessons,
              )
            else
              for (final lesson in past) ...[
                _LessonCard(
                  profile: profile,
                  lesson: lesson,
                  onTap: () => context.push(
                    AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
                  ),
                  onViewNote: () =>
                      _showLessonNoteSheet(context, profile, lesson),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],

            const SizedBox(height: AppSpacing.space5),

            // Notebook × Score: §1.2 #6 "Fine." 페이지 종지부.
            const ThinRule(),
            const SizedBox(height: AppSpacing.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Fine.', style: NotebookTypography.fine),
                const Spacer(),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
          ],
        ),
      ),
    );
  }
}

/// Opens the lesson note sheet. The sheet itself resolves visibility settings
/// and gates note / recording / detailed feedback content.
void _showLessonNoteSheet(
  BuildContext context,
  ChildProfile profile,
  lessons.Lesson lesson,
) {
  showNotebookModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LessonNoteSheet(profile: profile, lesson: lesson),
  );
}

class _LessonNoteSheet extends ConsumerWidget {
  const _LessonNoteSheet({required this.profile, required this.lesson});

  final ChildProfile profile;
  final lessons.Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // teacherId/studentId 획득: 레슨의 teacherId 우선, 없으면 자녀의 연결 선생님.
    final teacherId = lesson.teacherId ?? profile.teacherId;
    final studentId = lesson.studentId;

    // 게이트가 없으면(선생님 미연결) 권한 확인 불가 → 빈 안내 상태로.
    if (teacherId == null) {
      return _NoteSheetShell(
        lesson: lesson,
        child: const _NoteBlockedState(
          message: AppStrings.parentHomeLessonNoteNotShared,
        ),
      );
    }

    final settingsAsync = ref.watch(
      visibilitySettingsProvider((teacherId: teacherId, studentId: studentId)),
    );

    return _NoteSheetShell(
      lesson: lesson,
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _NoteBlockedState(
          message: AppStrings.parentHomeLessonLoadError,
        ),
        data: (settings) {
          // 기본값: 노트 ON, 녹음/상세피드백 OFF. settings null이면 기본 적용.
          final canViewNotes = settings?.canViewLessonNotes ?? true;
          final canViewRecordings = settings?.canViewRecordings ?? false;
          final canViewFeedback = settings?.canViewDetailedFeedback ?? false;

          if (!canViewNotes) {
            return const _NoteBlockedState(
              message: AppStrings.parentHomeLessonNoteNotShared,
            );
          }

          return _LessonNoteContent(
            lesson: lesson,
            canViewRecordings: canViewRecordings,
            canViewFeedback: canViewFeedback,
          );
        },
      ),
    );
  }
}

/// Shared sheet chrome (handle + header with detail link).
class _NoteSheetShell extends StatelessWidget {
  const _NoteSheetShell({required this.lesson, required this.child});

  final lessons.Lesson lesson;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: BottomSheetHandle(
                margin: EdgeInsets.only(bottom: AppSpacing.space4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Notebook × Score: 바텀시트 섹션 헤더 (§7.17/§7.27) — Playfair sectionTitle.
                Text(
                  AppStrings.parentHomeLessonNote,
                  style: NotebookTypography.sectionTitle,
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(
                      AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text(AppStrings.parentHomeViewDetail),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _LessonInfoRow(lesson: lesson),
                  const SizedBox(height: AppSpacing.space4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonInfoRow extends StatelessWidget {
  const _LessonInfoRow({required this.lesson});

  final lessons.Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final start = lesson.startTime;
    final end = formatTimeHM(lesson.endDateTime);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            size: 16,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '${formatDateMDWithDayParens(lesson.date)} $start - $end',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lesson note body — note/comment/assignments always; recordings gated.
class _LessonNoteContent extends StatelessWidget {
  const _LessonNoteContent({
    required this.lesson,
    required this.canViewRecordings,
    required this.canViewFeedback,
  });

  final lessons.Lesson lesson;
  final bool canViewRecordings;
  final bool canViewFeedback;

  @override
  Widget build(BuildContext context) {
    final keyPoints = lesson.keyPoints ?? const <String>[];
    final assignments = lesson.assignments ?? const <String>[];
    final recordings = lesson.recordings ?? const <lessons.LessonRecording>[];
    final hasFeedback =
        lesson.feedback != null && lesson.feedback!.trim().isNotEmpty;

    final hasAnyContent = keyPoints.isNotEmpty ||
        assignments.isNotEmpty ||
        (canViewFeedback && hasFeedback) ||
        (canViewRecordings && recordings.isNotEmpty);

    if (!hasAnyContent) {
      return const _NoteBlockedState(
        message: AppStrings.parentHomeLessonNoteEmpty,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (keyPoints.isNotEmpty) ...[
          _SectionLabel(AppStrings.parentHomeLessonNoteContent),
          const SizedBox(height: AppSpacing.space2),
          Text(
            keyPoints.map((p) => '• $p').join('\n'),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // 상세 피드백 — canViewDetailedFeedback 기준.
        if (canViewFeedback && hasFeedback) ...[
          _SectionLabel(AppStrings.parentHomeLessonTeacherComment),
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft.withValues(alpha: 0.2),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.paperAccentSoft),
            ),
            child: Text(lesson.feedback!, style: AppTypography.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        if (assignments.isNotEmpty) ...[
          _SectionLabel(AppStrings.parentHomeLessonAssignments),
          const SizedBox(height: AppSpacing.space2),
          for (final assignment in assignments)
            _AssignmentItem(title: assignment),
          const SizedBox(height: AppSpacing.space4),
        ],

        // 녹음 — canViewRecordings true 일 때만 렌더.
        if (canViewRecordings && recordings.isNotEmpty) ...[
          _SectionLabel(AppStrings.parentHomeLessonRecording),
          const SizedBox(height: AppSpacing.space2),
          for (final recording in recordings)
            _RecordingItem(recording: recording),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _AssignmentItem extends StatelessWidget {
  const _AssignmentItem({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_box_outline_blank,
            size: 18,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingItem extends StatelessWidget {
  const _RecordingItem({required this.recording});

  final lessons.LessonRecording recording;

  @override
  Widget build(BuildContext context) {
    final minutes = recording.duration.inMinutes;
    final seconds = recording.duration.inSeconds % 60;
    final durationLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          // §7.132: round → 사각 play 버튼. white → paper.
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.paperAccent),
            child: const Icon(Icons.play_arrow, color: AppColors.paper),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateMDWithDayParens(recording.recordedAt),
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  durationLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocked / empty content state inside the note sheet.
class _NoteBlockedState extends StatelessWidget {
  const _NoteBlockedState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 40,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.profile,
    required this.lesson,
    this.onTap,
    this.onViewNote,
  });

  final ChildProfile profile;
  final lessons.Lesson lesson;
  final VoidCallback? onTap;
  final VoidCallback? onViewNote;

  bool get _isPast => lesson.displayStatus != lessons.LessonStatus.scheduled;

  bool get _hasNote {
    final keyPoints = lesson.keyPoints ?? const <String>[];
    final assignments = lesson.assignments ?? const <String>[];
    final recordings = lesson.recordings ?? const <lessons.LessonRecording>[];
    return lesson.hasFeedback ||
        keyPoints.isNotEmpty ||
        assignments.isNotEmpty ||
        recordings.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isPast = _isPast;
    final teacherName = lesson.teacherName ?? profile.teacherName ?? '';
    final timeLabel =
        '${lesson.startTime} - ${formatTimeHM(lesson.endDateTime)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Row(
          children: [
            // Date box
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
              decoration: BoxDecoration(
                color: isPast
                    ? AppColors.paperDark
                    : AppColors.paperAccentSoft.withValues(alpha: 0.2),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Text(
                    '${lesson.date.day}',
                    style: AppTypography.headingMedium.copyWith(
                      color: isPast
                          ? AppColors.inkSecondary
                          : AppColors.paperAccent,
                    ),
                  ),
                  Text(
                    formatWeekdayShort(lesson.date),
                    style: AppTypography.caption.copyWith(
                      color: isPast
                          ? AppColors.inkTertiary
                          : AppColors.paperAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Lesson details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppStrings.parentHomeRegularLesson,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          // H7 — 지나간 레슨은 잉크가 바랜 것처럼 물러난다.
                          color: isPast
                              ? AppColors.inkQuaternary
                              : AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      _StatusBadge(status: lesson.displayStatus),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    teacherName.isEmpty
                        ? timeLabel
                        : '$timeLabel • $teacherName',
                    style: AppTypography.bodySmall.copyWith(
                      color: isPast
                          ? AppColors.inkQuaternary
                          : AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            if (onViewNote != null && _hasNote)
              IconButton(
                onPressed: onViewNote,
                icon: const Icon(
                  Icons.note_outlined,
                  color: AppColors.paperAccent,
                ),
                tooltip: AppStrings.parentHomeLessonNote,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final lessons.LessonStatus status;

  @override
  Widget build(BuildContext context) {
    final textColor = status.color;
    final String label;
    switch (status) {
      case lessons.LessonStatus.scheduled:
      case lessons.LessonStatus.reschedulePending:
        label = AppStrings.statusUpcoming;
      case lessons.LessonStatus.completed:
        label = AppStrings.statusCompleted;
      default:
        label = AppStrings.statusCancelled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LessonsEmptyRow extends StatelessWidget {
  const _LessonsEmptyRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }
}

/// Full-tab centered message state (no children / not linked / error).
class _LessonsMessageState extends StatelessWidget {
  const _LessonsMessageState({required this.message, this.hint});

  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_note_outlined,
              size: 56,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            // Notebook × Score: 빈 상태 헤드라인 (§7.89 3축) — Playfair sectionTitle.
            Text(message, style: NotebookTypography.sectionTitle),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
