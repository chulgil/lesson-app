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
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../domain/entities/tip_template.dart';
import '../providers/lesson_crud_provider.dart';
import '../../../subscription/subscription_facade.dart';
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
  bool _proposalBannerDismissed = false;

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

  Scaffold _buildNotFoundScaffold() {
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
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '레슨을 찾을 수 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Scaffold _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _buildErrorScaffold() {
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
            Icon(Icons.error_outline, size: 64, color: AppColors.paperAccent),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '데이터를 불러오는데 실패했습니다',
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
      child: Scaffold(
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
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Text('레슨 상세'),
      actions: [
        IconButton(
          onPressed: () {
            final date = formatDateYMD(lesson.date);
            final text =
                '${lesson.studentName} ${lesson.instrument} 레슨\n$date ${lesson.startTime} (${lesson.duration}분)';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('공유 텍스트가 복사되었습니다: $text'),
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
                const PopupMenuItem(
                  value: 'edit',
                  child: Text(AppStrings.modify),
                ),
                if (lesson.displayStatus == LessonStatus.scheduled)
                  const PopupMenuItem(value: 'complete', child: Text('완료 처리')),
                if (lesson.displayStatus == LessonStatus.scheduled)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text(AppStrings.cancel),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: AppColors.paperAccent)),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('레슨이 취소되었습니다')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('레슨 취소에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: AppColors.paperAccent,
              ),
            );
          }
        }
      }
    } else if (value == 'complete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('레슨 완료'),
              content: const Text('이 레슨을 완료 처리하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('완료'),
                ),
              ],
            ),
      );
      if (confirmed == true) {
        try {
          final updatedLesson = lesson.copyWith(status: LessonStatus.completed);
          await ref
              .read(lessonsNotifierProvider.notifier)
              .updateLesson(updatedLesson);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('레슨이 완료 처리되었습니다')));
          }

          // Auto-propose regular lessons if student has no active subscription
          if (widget.isTeacher && lesson.teacherId != null) {
            _tryAutoProposal(lesson);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('레슨 완료 처리에 실패했습니다. 다시 시도해주세요.'),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('레슨이 삭제되었습니다')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('레슨 삭제에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: AppColors.paperAccent,
              ),
            );
          }
        }
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
        tabs: const [Tab(text: '레슨 노트'), Tab(text: '과제')],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkSecondary,
        indicatorColor: AppColors.primary,
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
                color: AppColors.paperAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.paperAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.paperAccent, size: 20),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '레슨이 완료되었습니다. 피드백을 작성해주세요!',
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

          // Regular lesson proposal banner (shown after feedback is written,
          // when no active subscription exists with this student)
          if (widget.isTeacher &&
              lesson.displayStatus == LessonStatus.completed &&
              !needsFeedback &&
              !_proposalBannerDismissed)
            _buildRegularLessonProposalBanner(lesson),

          // Teacher notes section
          if (widget.isTeacher) ...[
            LessonDetailSectionHeader(title: '레슨 피드백', icon: Icons.edit_note),
            const SizedBox(height: AppSpacing.space3),
            LessonNoteEditor(
              initialText: lesson.feedback,
              onChanged: (text) => _saveFeedbackDebounced(lesson, text),
            ),
          ] else ...[
            LessonDetailSectionHeader(title: '선생님 피드백', icon: Icons.school),
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

          const SizedBox(height: AppSpacing.space6),

          // Key points
          LessonDetailSectionHeader(
            title: '주요 포인트',
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

          const SizedBox(height: AppSpacing.space6),

          // Practice tips
          LessonDetailSectionHeader(
            title: '연습 팁',
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
        ],
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

  /// Banner prompting teacher to propose regular lessons after a completed lesson.
  /// Only shows when no active subscription exists for this student.
  Widget _buildRegularLessonProposalBanner(Lesson lesson) {
    if (lesson.teacherId == null) return const SizedBox.shrink();

    final subscriptionAsync = ref.watch(
      activeSubscriptionBetweenProvider(
        studentId: lesson.studentId,
        teacherId: lesson.teacherId!,
      ),
    );

    return subscriptionAsync.when(
      data: (subscription) {
        // Has active subscription — no need to propose
        if (subscription != null && (subscription.remainingLessons ?? 0) > 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        '정규 레슨을 제안해보세요',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          () => setState(() => _proposalBannerDismissed = true),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '수강권을 발급하면 정기 레슨을 시작할 수 있습니다.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push(
                        '${AppRoutes.issueSubscription}?studentId=${lesson.studentId}',
                      );
                    },
                    icon: const Icon(Icons.card_membership, size: 18),
                    label: const Text('수강권 발급하기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAssignmentsTab(Lesson lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: PracticeItemsSection(
        lessonId: lesson.id,
        studentId: lesson.studentId,
        isTeacher: widget.isTeacher,
      ),
    );
  }

  void _showAddKeyPointDialog(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddTipBottomSheet(
            title: '주요 포인트 추가',
            instrument: lesson.instrument,
            initialCategory: TipCategory.technique,
            onSubmit: (content) => _addKeyPoint(lesson, content),
          ),
    );
  }

  void _showAddPracticeTipDialog(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddTipBottomSheet(
            title: '연습 팁 추가',
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
        ).showSnackBar(const SnackBar(content: Text('주요 포인트가 추가되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('주요 포인트 추가에 실패했습니다.'),
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
            content: const Text('주요 포인트 삭제에 실패했습니다.'),
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
              content: const Text('피드백 저장에 실패했습니다.'),
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
            content: const Text('메모 저장에 실패했습니다.'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연습 팁이 저장되었습니다')));
    }
  }
}
