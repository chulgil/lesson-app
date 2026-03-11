import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../models/tip_template.dart';
import '../../../../providers/providers.dart';
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
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _feedbackDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
            Icon(Icons.event_busy, size: 64, color: AppColors.textTertiaryLight),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '레슨을 찾을 수 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
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
              onPressed: () => ref.invalidate(lessonProvider(widget.lessonId)),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Lesson lesson) {
    return Scaffold(
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
                  _buildRecordingsTab(lesson),
                  _buildAssignmentsTab(lesson),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildRecordingFAB(),
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
            final date = '${lesson.date.year}.${lesson.date.month.toString().padLeft(2, '0')}.${lesson.date.day.toString().padLeft(2, '0')}';
            final text = '${lesson.studentName} ${lesson.instrument} 레슨\n$date ${lesson.startTime} (${lesson.duration}분)';
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
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            if (lesson.status == LessonStatus.scheduled)
              const PopupMenuItem(value: 'cancel', child: Text('취소')),
            PopupMenuItem(
              value: 'delete',
              child: Text('삭제', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleAppBarAction(String value, Lesson lesson) async {
    if (value == 'edit') {
      context.push('/lessons/${widget.lessonId}/edit');
    } else if (value == 'cancel') {
      final confirmed = await showCancelLessonConfirmation(context);
      if (confirmed == true) {
        await ref.read(lessonsNotifierProvider.notifier).cancelLesson(lesson.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('레슨이 취소되었습니다')),
          );
        }
      }
    } else if (value == 'delete') {
      final confirmed = await showDeleteLessonConfirmation(context);
      if (confirmed == true) {
        await ref.read(lessonsNotifierProvider.notifier).deleteLesson(lesson.id);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('레슨이 삭제되었습니다')),
          );
        }
      }
    }
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '레슨 노트'),
          Tab(text: '녹음'),
          Tab(text: '과제'),
        ],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryLight,
        indicatorColor: AppColors.primary,
      ),
    );
  }

  Widget _buildNotesTab(Lesson lesson) {
    final needsFeedback = widget.isTeacher &&
        lesson.status == LessonStatus.completed &&
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
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '레슨이 완료되었습니다. 피드백을 작성해주세요!',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],

          // Teacher notes section
          if (widget.isTeacher) ...[
            LessonDetailSectionHeader(
              title: '레슨 피드백',
              icon: Icons.edit_note,
            ),
            const SizedBox(height: AppSpacing.space3),
            LessonNoteEditor(
              initialText: lesson.feedback,
              onChanged: (text) => _saveFeedbackDebounced(lesson, text),
            ),
          ] else ...[
            LessonDetailSectionHeader(
              title: '선생님 피드백',
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

  Widget _buildRecordingsTab(Lesson lesson) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isRecording)
            RecordingStatusIndicator(recordingSeconds: _recordingSeconds),

          LessonDetailSectionHeader(title: '녹음 파일', icon: Icons.mic),
          const SizedBox(height: AppSpacing.space3),

          if (lesson.recordings == null || lesson.recordings!.isEmpty)
            const RecordingsEmptyState()
          else
            ...lesson.recordings!.asMap().entries.map((entry) {
              final idx = entry.key;
              final recording = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: LessonRecordingCard(
                  title: '레슨 녹음 ${idx + 1}',
                  duration: formatRecordingDuration(recording.duration),
                  date:
                      '${recording.recordedAt.month}월 ${recording.recordedAt.day}일 ${recording.recordedAt.hour}:${recording.recordedAt.minute.toString().padLeft(2, '0')}',
                  hasTranscript: recording.transcription != null,
                ),
              );
            }),

          const SizedBox(height: AppSpacing.space6),

          if (lesson.recordings?.any((r) => r.aiSummary != null) == true) ...[
            LessonDetailSectionHeader(title: 'AI 요약', icon: Icons.auto_awesome),
            const SizedBox(height: AppSpacing.space3),
            Builder(
              builder: (context) {
                final aiSummary = lesson.recordings
                    ?.firstWhere(
                      (r) => r.aiSummary != null,
                      orElse: () => lesson.recordings!.first,
                    )
                    .aiSummary;
                if (aiSummary == null) return const SizedBox.shrink();
                return AISummaryCard(summary: aiSummary);
              },
            ),
          ],
        ],
      ),
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

  Widget _buildRecordingFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        setState(() {
          _isRecording = !_isRecording;
          if (_isRecording) {
            _recordingSeconds = 0;
            _startRecordingTimer();
          }
        });
      },
      backgroundColor: _isRecording ? AppColors.error : AppColors.primary,
      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
      label: Text(_isRecording ? '녹음 중지' : '녹음 시작'),
    );
  }

  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() => _recordingSeconds++);
        return true;
      }
      return false;
    });
  }

  void _showAddKeyPointDialog(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTipBottomSheet(
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
      builder: (context) => AddTipBottomSheet(
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
    await ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주요 포인트가 추가되었습니다')),
      );
    }
  }

  Future<void> _removeKeyPoint(Lesson lesson, int index) async {
    final currentPoints = List<String>.from(lesson.keyPoints ?? []);
    if (index < 0 || index >= currentPoints.length) return;

    currentPoints.removeAt(index);

    final updatedLesson = lesson.copyWith(
      keyPoints: currentPoints.isEmpty ? null : currentPoints,
    );
    await ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);
  }

  void _saveFeedbackDebounced(Lesson lesson, String text) {
    _feedbackDebounce?.cancel();
    _feedbackDebounce = Timer(const Duration(milliseconds: 800), () {
      final updatedLesson = lesson.copyWith(
        feedback: text.isEmpty ? null : text,
      );
      ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);
    });
  }

  void _saveStudentMemo(Lesson lesson, String memo) {
    final updatedLesson = lesson.copyWith(
      studentNote: memo.isEmpty ? null : memo,
    );
    ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);
  }

  Future<void> _setPracticeTip(Lesson lesson, String? content) async {
    final updatedLesson = lesson.copyWith(
      practiceTips: content?.isEmpty == true ? null : content,
    );
    await ref.read(lessonsNotifierProvider.notifier).updateLesson(updatedLesson);

    if (mounted && content != null && content.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연습 팁이 저장되었습니다')),
      );
    }
  }
}
