// Lesson notes section — attendance, feedback, key points, practice tips.
//
// 2탭→단일 스크롤 통합(doc 41 §6.1): 기존 `LessonDetailScreen._buildNotesTab`
// 을 그대로 위젯으로 추출했다. Debounce 저장/뮤테이션 등 상태 로직은 화면의
// State 에 남기고, 이 위젯은 콜백을 받아 노트 섹션 UI 트리만 구성한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/notebook/staff_divider.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../../features/subscription/subscription_facade.dart';
import '../weekly_focus_card.dart';
import 'attendance_section.dart';
import 'lesson_notes_widgets.dart';
import 'previous_lesson_notes_card.dart';

/// Notes section for the lesson detail single-scroll layout.
///
/// Composes: 출석 확인/휴강 액션, 피드백 작성 유도, 스케줄 변경 바로가기,
/// 이번 주 집중 카드(학생), 노트 편집/열람, 학생 메모, 주요 포인트, 연습 팁.
class LessonNotesSection extends ConsumerWidget {
  final Lesson lesson;
  final bool isTeacher;

  /// Called after a successful 출석 확인(completed) — e.g. auto-proposal.
  final VoidCallback onAttendanceCompleted;

  /// Called on every feedback editor change — debounced save lives in the
  /// screen's State (flush-on-dispose 는 State 만 관리 가능).
  final ValueChanged<String> onFeedbackChanged;

  final ValueChanged<String> onStudentMemoSave;
  final VoidCallback onAddKeyPoint;
  final void Function(int index) onRemoveKeyPoint;
  final VoidCallback onAddPracticeTip;
  final VoidCallback onEditPracticeTip;

  const LessonNotesSection({
    super.key,
    required this.lesson,
    required this.isTeacher,
    required this.onAttendanceCompleted,
    required this.onFeedbackChanged,
    required this.onStudentMemoSave,
    required this.onAddKeyPoint,
    required this.onRemoveKeyPoint,
    required this.onAddPracticeTip,
    required this.onEditPracticeTip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #796: 피드백 프롬프트는 출석 확인(실제 status == completed) 후에만 노출.
    // displayStatus(과거 미확인 레슨을 completed 로 투영)를 쓰면 출석 확인 전에
    // 프롬프트가 떠 출석 액션 위를 가린다. 출석 섹션을 프롬프트 위에 배치.
    final needsFeedback = isTeacher && lesson.awaitsTeacherFeedback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 단일 스크롤 병합 후 섹션 라벨 — 탭 없이도 구획을 알 수 있도록 유지.
        LessonDetailSectionHeader(
          title: AppStrings.lessonNotesTab,
          icon: Icons.menu_book_outlined,
        ),
        const SizedBox(height: AppSpacing.space4),

        // #473: 미확인 레슨 액션(출석 확인/휴강) + 사전 안내 배너 + 차감 결과
        AttendanceSection(
          lesson: lesson,
          isTeacher: isTeacher,
          onCompleted: onAttendanceCompleted,
        ),

        // 출석 확인 후 피드백 작성 유도 프롬프트 (#796: 출석 섹션 아래)
        if (needsFeedback) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: AppColors.paperAccentSoft,
              border: Border.all(color: AppColors.paperAccent),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.paperAccent, size: 20),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    AppStrings.lessonNeedsFeedbackPrompt,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // 스케줄 변경(챗) 바로가기 — 수강권 연동 레슨 또는 활성 수강권이 있는 수동 레슨
        _buildScheduleChangeButton(context, ref),

        // #1106: 이번 주 집중 카드 (학생 뷰 · 피드백→연습 연결)
        if (!isTeacher && WeeklyFocusCard.focusContentOf(lesson) != null) ...[
          WeeklyFocusCard(lesson: lesson, isTeacher: isTeacher),
          const SizedBox(height: AppSpacing.space5),
        ],

        // Teacher notes section
        if (isTeacher) ...[
          LessonDetailSectionHeader(
            title: AppStrings.lessonFeedbackHeader,
            icon: Icons.edit_note,
          ),
          const SizedBox(height: AppSpacing.space3),
          // #1215: 이번 노트를 쓰는 동안 같은 학생의 지난 노트를 참조.
          PreviousLessonNotesCard(lesson: lesson),
          LessonNoteEditor(
            initialText: lesson.feedback,
            onChanged: onFeedbackChanged,
          ),
        ] else ...[
          LessonDetailSectionHeader(
            title: AppStrings.teacherFeedbackHeader,
            icon: Icons.school,
          ),
          const SizedBox(height: AppSpacing.space3),
          TeacherFeedbackCard(lesson: lesson),
        ],

        // Student memo section (shown after feedback for student view)
        if (!isTeacher) ...[
          const SizedBox(height: AppSpacing.space6),
          StudentMemoCard(
            initialMemo: lesson.studentNote,
            onSave: onStudentMemoSave,
          ),
        ],

        const SizedBox(height: AppSpacing.space5),
        const StaffDivider(),
        const SizedBox(height: AppSpacing.space5),

        // Key points
        LessonDetailSectionHeader(
          title: AppStrings.keyPointsSection,
          icon: Icons.lightbulb_outline,
          showAddButton: isTeacher,
          onAdd: onAddKeyPoint,
        ),
        const SizedBox(height: AppSpacing.space3),
        KeyPointsList(
          lesson: lesson,
          isTeacher: isTeacher,
          onRemove: onRemoveKeyPoint,
        ),

        const SizedBox(height: AppSpacing.space5),
        const StaffDivider(),
        const SizedBox(height: AppSpacing.space5),

        // Practice tips
        LessonDetailSectionHeader(
          title: AppStrings.practiceTipsSection,
          icon: Icons.tips_and_updates_outlined,
          showAddButton: isTeacher,
          onAdd: onAddPracticeTip,
        ),
        const SizedBox(height: AppSpacing.space3),
        PracticeTipsCard(
          lesson: lesson,
          isTeacher: isTeacher,
          onEdit: onEditPracticeTip,
        ),
      ],
    );
  }

  /// Schedule-change button — shows for subscription lessons or manual lessons
  /// that have an active subscription with the same student.
  /// Hidden for completed/cancelled/past lessons (§15 스펙).
  Widget _buildScheduleChangeButton(BuildContext context, WidgetRef ref) {
    // §15: 완료/취소/과거 레슨에는 스케줄 변경 불필요
    if (lesson.status == LessonStatus.completed ||
        lesson.status == LessonStatus.cancelled ||
        !lesson.isUpcoming) {
      return const SizedBox.shrink();
    }

    // Case 1: lesson is directly linked to a subscription
    if (lesson.subscriptionId != null) {
      return _scheduleChangeButton(
        context: context,
        subscriptionId: lesson.subscriptionId!,
        label: AppStrings.announcementScheduleChange,
        focusLessonId: lesson.id,
      );
    }

    // Case 2: manual lesson — check whether an active subscription exists
    final subsAsync = ref.watch(
      activeStudentSubscriptionsProvider(lesson.studentId),
    );
    return subsAsync.maybeWhen(
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();
        final activeSub = subs.first;
        return _scheduleChangeButton(
          context: context,
          subscriptionId: activeSub.id,
          label:
              '${AppStrings.announcementScheduleChange} (${activeSub.typeLabel})',
          focusLessonId: lesson.id,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _scheduleChangeButton({
    required BuildContext context,
    required String subscriptionId,
    required String label,
    String? focusLessonId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: OutlinedButton.icon(
        onPressed:
            () => context.push(
              AppRoutes.subscriptionDetail.replaceFirst(':id', subscriptionId),
              extra: {
                'viewerRole': isTeacher ? 'teacher' : 'student',
                if (focusLessonId != null) 'focusLessonId': focusLessonId,
              },
            ),
        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
      ),
    );
  }
}
