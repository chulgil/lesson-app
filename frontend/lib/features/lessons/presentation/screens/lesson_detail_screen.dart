import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/staff_divider.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../domain/entities/tip_template.dart';
import '../providers/lesson_crud_provider.dart';
import '../../../subscription/subscription_facade.dart';
import '../../../subscription/presentation/extensions/subscription_visuals.dart';
import '../widgets/lesson_detail/lesson_detail_widgets.dart';
import '../widgets/practice_items_section.dart';

/// Lesson detail screen with recording and notes
class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final bool isTeacher;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    this.isTeacher = true,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _feedbackDebounce;
  String? _pendingFeedbackText;
  // _proposalBannerDismissed removed — 정규레슨 제안은 학생 상세 수강권 현황에서 표시

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Flush pending feedback before cancel
    if (_feedbackDebounce?.isActive == true && _pendingFeedbackText != null) {
      _feedbackDebounce!.cancel();
      _flushPendingFeedback();
    }
    _feedbackDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return _buildNotFoundScaffold();
        }
        return _buildContent(context, lesson);
      },
      loading: () => _buildLoadingScaffold(),
      error: (error, _) => _buildErrorScaffold(),
    );
  }

  Widget _buildNotFoundScaffold() {
    return NotebookScreenScaffold(
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
            Icon(Icons.event_busy, size: 64, color: AppColors.inkTertiary),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.lessonNotFound,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return NotebookScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold() {
    return NotebookScreenScaffold(
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
            Icon(Icons.error_outline, size: 64, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.loadDataFailed,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(lessonProvider(widget.lessonId)),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  /// Flush any pending debounced feedback save immediately.
  Future<void> _flushPendingFeedback() async {
    if (_feedbackDebounce?.isActive == true && _pendingFeedbackText != null) {
      _feedbackDebounce!.cancel();
      final lesson = ref.read(lessonProvider(widget.lessonId)).valueOrNull;
      if (lesson != null) {
        final trimmed = _pendingFeedbackText!.trim();
        final updatedLesson = lesson.copyWith(
          feedback: trimmed.isEmpty ? null : trimmed,
        );
        try {
          await ref
              .read(lessonsNotifierProvider.notifier)
              .updateLesson(updatedLesson);
        } catch (_) {
          // Silent fail on exit — data already in debounce
        }
      }
      _pendingFeedbackText = null;
    }
  }

  Widget _buildContent(BuildContext context, Lesson lesson) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          await _flushPendingFeedback();
        }
      },
      child: NotebookScreenScaffold(
        appBar: _buildAppBar(lesson),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(lessonProvider(widget.lessonId));
          },
          child: Column(
            children: [
              LessonHeaderCard(lesson: lesson, isTeacher: widget.isTeacher),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotesTab(lesson),
                    _buildAssignmentsTab(lesson),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Recording FAB removed — will be re-enabled with teaching resources feature (#172)
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Lesson lesson) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        AppStrings.lessonDetailAppBarTitle(lesson.studentName),
        style: NotebookTypography.appBarTitle,
      ),
      actions: [
        IconButton(
          onPressed: () {
            final date = formatDateYMD(lesson.date);
            final text = AppStrings.lessonShareText(
              studentName: lesson.studentName,
              instrument: lesson.instrument,
              date: date,
              startTime: lesson.startTime,
              duration: lesson.duration,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.shareTextCopied(text)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.share_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleAppBarAction(value, lesson),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    lesson.subscriptionId != null
                        ? AppStrings.editContent
                        : AppStrings.editManual,
                  ),
                ),
                if (lesson.displayStatus == LessonStatus.scheduled)
                  const PopupMenuItem(
                    value: 'complete',
                    child: Text(AppStrings.markComplete),
                  ),
                if (lesson.displayStatus == LessonStatus.scheduled)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text(AppStrings.cancel),
                  ),
                // Show for subscription lessons OR manual lessons with an active subscription
                if (lesson.subscriptionId != null ||
                    ref
                            .watch(
                              activeStudentSubscriptionsProvider(
                                lesson.studentId,
                              ),
                            )
                            .valueOrNull
                            ?.isNotEmpty ==
                        true)
                  PopupMenuItem(
                    value: 'schedule_change',
                    child: Text(AppStrings.announcementScheduleChange),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    AppStrings.delete,
                    style: TextStyle(color: AppColors.paperAccent),
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Future<void> _handleAppBarAction(String value, Lesson lesson) async {
    if (value == 'edit') {
      context.push(AppRoutes.editLesson.replaceFirst(':id', widget.lessonId));
    } else if (value == 'cancel') {
      final confirmed = await showCancelLessonConfirmation(context);
      if (confirmed == true) {
        try {
          await ref
              .read(lessonsNotifierProvider.notifier)
              .cancelLesson(lesson.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.lessonCancelled)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.lessonCancelFailed),
                backgroundColor: AppColors.paperAccent,
              ),
            );
          }
        }
      }
    } else if (value == 'complete') {
      final confirmed = await showNotebookDialog(
        context: context,
        title: AppStrings.lessonCompleteTitle,
        message: AppStrings.lessonCompleteConfirm,
        confirmLabel: AppStrings.completeAction,
        cancelLabel: AppStrings.cancel,
      );
      if (confirmed == true) {
        try {
          final updatedLesson = lesson.copyWith(status: LessonStatus.completed);
          await ref
              .read(lessonsNotifierProvider.notifier)
              .updateLesson(updatedLesson);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.lessonCompletedSnack)),
            );
          }

          // Auto-propose regular lessons if student has no active subscription
          if (widget.isTeacher && lesson.teacherId != null) {
            _tryAutoProposal(lesson);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.lessonCompleteFailed),
                backgroundColor: AppColors.paperAccent,
              ),
            );
          }
        }
      }
    } else if (value == 'delete') {
      final confirmed = await showDeleteLessonConfirmation(context);
      if (confirmed == true) {
        try {
          await ref
              .read(lessonsNotifierProvider.notifier)
              .deleteLesson(lesson.id);
          if (mounted) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.lessonDeleted)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.lessonDeleteFailed),
                backgroundColor: AppColors.paperAccent,
              ),
            );
          }
        }
      }
    } else if (value == 'schedule_change') {
      final subId =
          lesson.subscriptionId ??
          ref
              .read(activeStudentSubscriptionsProvider(lesson.studentId))
              .valueOrNull
              ?.firstOrNull
              ?.id;
      if (subId != null) {
        context.push(
          AppRoutes.subscriptionDetail.replaceFirst(':id', subId),
          extra: {'viewerRole': widget.isTeacher ? 'teacher' : 'student'},
        );
      }
    }
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: AppStrings.lessonNotesTab),
          Tab(text: AppStrings.assignmentsTab),
        ],
        labelColor: AppColors.paperAccent,
        unselectedLabelColor: AppColors.inkSecondary,
        indicatorColor: AppColors.paperAccent,
      ),
    );
  }

  Widget _buildNotesTab(Lesson lesson) {
    final needsFeedback =
        widget.isTeacher &&
        lesson.displayStatus == LessonStatus.completed &&
        (lesson.feedback == null || lesson.feedback!.isEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt to write feedback for completed lessons
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
          _buildScheduleChangeButton(lesson),

          // Teacher notes section
          if (widget.isTeacher) ...[
            LessonDetailSectionHeader(
              title: AppStrings.lessonFeedbackHeader,
              icon: Icons.edit_note,
            ),
            const SizedBox(height: AppSpacing.space3),
            LessonNoteEditor(
              initialText: lesson.feedback,
              onChanged: (text) => _saveFeedbackDebounced(lesson, text),
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
          if (!widget.isTeacher) ...[
            const SizedBox(height: AppSpacing.space6),
            StudentMemoCard(
              initialMemo: lesson.studentNote,
              onSave: (memo) => _saveStudentMemo(lesson, memo),
            ),
          ],

          const SizedBox(height: AppSpacing.space5),
          const StaffDivider(),
          const SizedBox(height: AppSpacing.space5),

          // Key points
          LessonDetailSectionHeader(
            title: AppStrings.keyPointsSection,
            icon: Icons.lightbulb_outline,
            showAddButton: widget.isTeacher,
            onAdd: () => _showAddKeyPointDialog(lesson),
          ),
          const SizedBox(height: AppSpacing.space3),
          KeyPointsList(
            lesson: lesson,
            isTeacher: widget.isTeacher,
            onRemove: (index) => _removeKeyPoint(lesson, index),
          ),

          const SizedBox(height: AppSpacing.space5),
          const StaffDivider(),
          const SizedBox(height: AppSpacing.space5),

          // Practice tips
          LessonDetailSectionHeader(
            title: AppStrings.practiceTipsSection,
            icon: Icons.tips_and_updates_outlined,
            showAddButton: widget.isTeacher,
            onAdd: () => _showAddPracticeTipDialog(lesson),
          ),
          const SizedBox(height: AppSpacing.space3),
          PracticeTipsCard(
            lesson: lesson,
            isTeacher: widget.isTeacher,
            onEdit: () => _showEditPracticeTipDialog(lesson),
          ),

          // Notebook × Score: "Fine." 종지부
          const SizedBox(height: AppSpacing.space6),
          Center(child: Text('Fine.', style: NotebookTypography.fine)),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  /// Schedule-change button — shows for subscription lessons or manual lessons
  /// that have an active subscription with the same student.
  Widget _buildScheduleChangeButton(Lesson lesson) {
    // Case 1: lesson is directly linked to a subscription
    if (lesson.subscriptionId != null) {
      return _scheduleChangeButton(
        subscriptionId: lesson.subscriptionId!,
        label: AppStrings.announcementScheduleChange,
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
          subscriptionId: activeSub.id,
          label:
              '${AppStrings.announcementScheduleChange} (${activeSub.typeLabel})',
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _scheduleChangeButton({
    required String subscriptionId,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: OutlinedButton.icon(
        onPressed:
            () => context.push(
              AppRoutes.subscriptionDetail.replaceFirst(':id', subscriptionId),
              extra: {'viewerRole': widget.isTeacher ? 'teacher' : 'student'},
            ),
        icon: const Icon(Icons.swap_horiz, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
      ),
    );
  }

  /// Fire-and-forget auto-proposal trigger after lesson completion.
  /// Handles both trial (no subscription) and renewal (low subscription) cases.
  void _tryAutoProposal(Lesson lesson) async {
    if (lesson.teacherId == null) return;

    try {
      final subscription = await ref.read(
        activeSubscriptionBetweenProvider(
          studentId: lesson.studentId,
          teacherId: lesson.teacherId!,
        ).future,
      );

      if (subscription == null || (subscription.remainingLessons ?? 0) <= 0) {
        // No subscription → trial auto proposal
        await ref
            .read(autoProposalServiceProvider)
            .triggerAfterTrialCompletion(
              teacherId: lesson.teacherId!,
              studentId: lesson.studentId,
              trialCompletedAt: DateTime.now(),
            );
      } else if ((subscription.remainingLessons ?? 999) <= 2) {
        // Low subscription → renewal trigger
        await ref
            .read(subscriptionRenewalServiceProvider)
            .triggerOnSubscriptionLow(
              subscription: subscription,
              teacherId: lesson.teacherId!,
            );
      }
    } catch (_) {
      // Silent fail — auto proposal is best-effort
    }
  }

  Widget _buildAssignmentsTab(Lesson lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          PracticeItemsSection(
            lessonId: lesson.id,
            studentId: lesson.studentId,
            isTeacher: widget.isTeacher,
          ),

          // Notebook × Score: "Fine." 종지부
          const SizedBox(height: AppSpacing.space6),
          Center(child: Text('Fine.', style: NotebookTypography.fine)),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  void _showAddKeyPointDialog(Lesson lesson) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AddTipBottomSheet(
            title: AppStrings.addKeyPointTitle,
            instrument: lesson.instrument,
            initialCategory: TipCategory.technique,
            onSubmit: (content) => _addKeyPoint(lesson, content),
          ),
    );
  }

  void _showAddPracticeTipDialog(Lesson lesson) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => AddTipBottomSheet(
            title: AppStrings.addPracticeTipTitle,
            instrument: lesson.instrument,
            initialCategory: TipCategory.practice,
            onSubmit: (content) => _setPracticeTip(lesson, content),
          ),
    );
  }

  void _showEditPracticeTipDialog(Lesson lesson) async {
    final result = await showEditPracticeTipDialog(
      context: context,
      currentTip: lesson.practiceTips,
      hasTip: lesson.practiceTips != null && lesson.practiceTips!.isNotEmpty,
    );

    if (result != null) {
      _setPracticeTip(lesson, result.isEmpty ? null : result);
    }
  }

  Future<void> _addKeyPoint(Lesson lesson, String content) async {
    if (content.isEmpty) return;

    final currentPoints = List<String>.from(lesson.keyPoints ?? []);
    currentPoints.add(content);

    final updatedLesson = lesson.copyWith(keyPoints: currentPoints);
    try {
      await ref
          .read(lessonsNotifierProvider.notifier)
          .updateLesson(updatedLesson);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.keyPointAdded)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.addKeyPointFailed),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Future<void> _removeKeyPoint(Lesson lesson, int index) async {
    final currentPoints = List<String>.from(lesson.keyPoints ?? []);
    if (index < 0 || index >= currentPoints.length) return;

    currentPoints.removeAt(index);

    final updatedLesson = lesson.copyWith(
      keyPoints: currentPoints.isEmpty ? null : currentPoints,
    );
    try {
      await ref
          .read(lessonsNotifierProvider.notifier)
          .updateLesson(updatedLesson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.removeKeyPointFailed),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  void _saveFeedbackDebounced(Lesson lesson, String text) {
    _feedbackDebounce?.cancel();
    _pendingFeedbackText = text;
    _feedbackDebounce = Timer(const Duration(milliseconds: 800), () async {
      final trimmed = text.trim();
      final updatedLesson = lesson.copyWith(
        feedback: trimmed.isEmpty ? null : trimmed,
      );
      try {
        await ref
            .read(lessonsNotifierProvider.notifier)
            .updateLesson(updatedLesson);
        _pendingFeedbackText = null;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.feedbackSaveFailedShort),
              backgroundColor: AppColors.paperAccent,
            ),
          );
        }
      }
    });
  }

  Future<void> _saveStudentMemo(Lesson lesson, String memo) async {
    final updatedLesson = lesson.copyWith(
      studentNote: memo.trim().isEmpty ? null : memo.trim(),
    );
    try {
      await ref
          .read(lessonsNotifierProvider.notifier)
          .updateLesson(updatedLesson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.memoSaveFailed),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }
  }

  Future<void> _setPracticeTip(Lesson lesson, String? content) async {
    final updatedLesson = lesson.copyWith(
      practiceTips: content?.isEmpty == true ? null : content,
    );
    await ref
        .read(lessonsNotifierProvider.notifier)
        .updateLesson(updatedLesson);

    if (mounted && content != null && content.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.practiceTipSaved)),
      );
    }
  }
}
