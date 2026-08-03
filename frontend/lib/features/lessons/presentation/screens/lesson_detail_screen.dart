import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/staff_divider.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../domain/entities/tip_template.dart';
import '../providers/lesson_crud_provider.dart';
import '../../../share/share_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../widgets/lesson_detail/lesson_detail_widgets.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../settings/settings_facade.dart';

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

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  Timer? _feedbackDebounce;
  bool _isSharingSummary = false;
  String? _pendingFeedbackText;
  // _proposalBannerDismissed removed — 정규레슨 제안은 학생 상세 수강권 현황에서 표시

  @override
  void dispose() {
    // Flush pending feedback before cancel
    if (_feedbackDebounce?.isActive == true && _pendingFeedbackText != null) {
      _feedbackDebounce!.cancel();
      _flushPendingFeedback();
    }
    _feedbackDebounce?.cancel();
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
      appBar: const NotebookDetailAppBar(title: AppStrings.lessonRecordTitle),
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
      appBar: const NotebookDetailAppBar(title: AppStrings.lessonRecordTitle),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold() {
    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.lessonRecordTitle),
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
              LessonHeaderCard(
                lesson: lesson,
                isTeacher: widget.isTeacher,
                // 보강 배지 — teacher-scoped credit lookup (§2.6.6)
                extraBadge:
                    widget.isTeacher
                        ? MakeupLessonBadge(
                          lessonId: lesson.id,
                          studentId: lesson.studentId,
                        )
                        : null,
              ),
              Expanded(child: _buildSingleScroll(lesson)),
            ],
          ),
        ),
        // Recording FAB removed — will be re-enabled with teaching resources feature (#172)
      ),
    );
  }

  /// 2탭(레슨 노트/과제) → 단일 스크롤 통합 (doc 41 §6.1). 노트 섹션 다음
  /// 구분선 + 과제 섹션을 이어 붙여 탭 전환 없이 한 화면에서 보고 입력한다.
  Widget _buildSingleScroll(Lesson lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonNotesSection(
            lesson: lesson,
            isTeacher: widget.isTeacher,
            onAttendanceCompleted: () => _tryAutoProposal(lesson),
            onFeedbackChanged: (text) => _saveFeedbackDebounced(lesson, text),
            onStudentMemoSave: (memo) => _saveStudentMemo(lesson, memo),
            onAddKeyPoint: () => _showAddKeyPointDialog(lesson),
            onRemoveKeyPoint: (index) => _removeKeyPoint(lesson, index),
            onAddPracticeTip: () => _showAddPracticeTipDialog(lesson),
            onEditPracticeTip: () => _showEditPracticeTipDialog(lesson),
          ),

          const SizedBox(height: AppSpacing.space5),
          const StaffDivider(),
          const SizedBox(height: AppSpacing.space5),

          LessonAssignmentsSection(
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

  /// #808 — 레슨 요약 공유: 서버 토큰 생성 → 공유 URL 클립보드 복사 + 토스트.
  /// 토큰 발급만 서버, 발급된 URL 은 그대로 복사(랜딩=학생 요약 화면).
  Future<void> _handleShareSummary(Lesson lesson) async {
    if (_isSharingSummary) return;
    setState(() => _isSharingSummary = true);
    try {
      final share = await ref
          .read(lessonSummaryShareRepositoryProvider)
          .createLessonSummaryShare(lesson.id);
      await Clipboard.setData(ClipboardData(text: share.url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.lessonSummaryShareCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.lessonSummaryShareError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharingSummary = false);
    }
  }

  PreferredSizeWidget _buildAppBar(Lesson lesson) {
    return NotebookDetailAppBar(
      title: AppStrings.lessonDetailAppBarTitle(lesson.studentName),
      actions: const [DetailAppBarAction.share],
      onAction: (action) {
        if (action == DetailAppBarAction.share) {
          _handleShareSummary(lesson);
        }
      },
      customActions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
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
                    child: Text(AppStrings.attendanceConfirmAction),
                  ),
                if (lesson.displayStatus == LessonStatus.scheduled)
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(
                      lesson.subscriptionId != null
                          ? AppStrings.cancelViaSubscription
                          : AppStrings.cancel,
                    ),
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
                  value: 'archive',
                  child: Text(
                    AppStrings.archive,
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
      if (lesson.subscriptionId != null) {
        // Connected lesson → navigate to subscription detail for proper cancel flow
        context.push(
          AppRoutes.subscriptionDetail.replaceFirst(
            ':id',
            lesson.subscriptionId!,
          ),
          extra: {'viewerRole': widget.isTeacher ? 'teacher' : 'student'},
        );
      } else {
        // Manual/legacy lesson without subscription → direct cancel
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
      }
    } else if (value == 'complete') {
      // #767: 완료=출석 확정 단일화 — confirmAttendance 로 라우팅(차감 notice
      // 다이얼로그 + confirmLessonCompleted 차감). plain updateLesson 은 차감을
      // 누락했다. 자동제안·평점은 onCompleted 로 보존.
      await confirmAttendance(
        context,
        ref,
        lesson,
        onCompleted: () async {
          if (widget.isTeacher && lesson.teacherId != null) {
            _tryAutoProposal(lesson);
          }
          if (widget.isTeacher && mounted) {
            final completedCount =
                ref
                    .read(lessonsNotifierProvider)
                    .value
                    ?.where((l) => l.status == LessonStatus.completed)
                    .length ??
                0;
            await showAppRatingPromptIfNeeded(
              context: context,
              ref: ref,
              userRole: UserRole.teacher,
              completedLessonCount: completedCount,
            );
          }
        },
      );
    } else if (value == 'archive') {
      final confirmed = await showDeleteLessonConfirmation(context);
      if (confirmed == true) {
        try {
          await ref
              .read(lessonsNotifierProvider.notifier)
              .archiveLesson(lesson.id);
          if (mounted) {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.lessonArchivedSnack)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.archiveLessonFailed),
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
