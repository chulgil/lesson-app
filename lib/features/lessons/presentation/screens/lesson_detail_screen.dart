import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/lesson.dart';
import '../../../../models/tip_template.dart';
import '../../../../providers/providers.dart';
import '../widgets/practice_items_section.dart';
import '../widgets/tip_template_bottom_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
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

        return _buildContent(context, lesson);
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
                onPressed: () => ref.invalidate(lessonProvider(widget.lessonId)),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
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
            // Lesson info header
            _buildLessonHeader(lesson),

            // Tab bar
            _buildTabBar(),

            // Tab content
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
            // Share or export
          },
          icon: const Icon(Icons.share_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              context.push('/lessons/${widget.lessonId}/edit');
            } else if (value == 'cancel') {
              final confirmed = await _showCancelConfirmation();
              if (confirmed == true) {
                await ref.read(lessonsNotifierProvider.notifier).cancelLesson(lesson.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('레슨이 취소되었습니다')),
                  );
                }
              }
            } else if (value == 'delete') {
              final confirmed = await _showDeleteConfirmation();
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
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('수정')),
            if (lesson.status == LessonStatus.scheduled)
              const PopupMenuItem(value: 'cancel', child: Text('취소')),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                '삭제',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLessonHeader(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student/Teacher info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  widget.isTeacher
                      ? (lesson.studentName.isNotEmpty ? lesson.studentName[0] : '?')
                      : (lesson.teacherName?.isNotEmpty == true ? lesson.teacherName![0] : '?'),
                  style: AppTypography.headingSmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.isTeacher
                              ? lesson.studentName
                              : (lesson.teacherName ?? '선생님'),
                          style: AppTypography.headingMedium,
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lesson.instrument,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Status badge
                        _buildStatusBadge(lesson.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '${lesson.date.month}월 ${lesson.date.day}일 ${lesson.startTime} · ${lesson.duration}분',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.space4),

          // Pieces
          if (lesson.pieces.isNotEmpty)
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: lesson.pieces.map((piece) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Text(
                    piece.displayName,
                    style: AppTypography.bodySmall,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LessonStatus status) {
    Color color;
    switch (status) {
      case LessonStatus.scheduled:
        color = AppColors.primary;
      case LessonStatus.completed:
        color = AppColors.practiceGood;
      case LessonStatus.cancelled:
        color = AppColors.textTertiaryLight;
      case LessonStatus.noShow:
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher notes section
          if (widget.isTeacher) ...[
            _buildSectionHeader('레슨 피드백', Icons.edit_note),
            const SizedBox(height: AppSpacing.space3),
            _buildNoteEditor(lesson),
          ] else ...[
            _buildSectionHeader('선생님 피드백', Icons.school),
            const SizedBox(height: AppSpacing.space3),
            _buildTeacherFeedbackCard(lesson),
          ],

          const SizedBox(height: AppSpacing.space6),

          // Key points
          _buildSectionHeader(
            '주요 포인트',
            Icons.lightbulb_outline,
            showAddButton: widget.isTeacher,
            onAdd: () => _showAddKeyPointDialog(lesson),
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildKeyPointsList(lesson),

          const SizedBox(height: AppSpacing.space6),

          // Practice tips
          _buildSectionHeader(
            '연습 팁',
            Icons.tips_and_updates_outlined,
            showAddButton: widget.isTeacher,
            onAdd: () => _showAddPracticeTipDialog(lesson),
          ),
          const SizedBox(height: AppSpacing.space3),
          _buildPracticeTips(lesson),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    bool showAddButton = false,
    VoidCallback? onAdd,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.space2),
        Text(title, style: AppTypography.headingSmall),
        const Spacer(),
        if (showAddButton && onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 22,
            color: AppColors.primary,
            tooltip: '추가',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildNoteEditor(Lesson lesson) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        maxLines: 6,
        controller: TextEditingController(text: lesson.feedback ?? ''),
        decoration: InputDecoration(
          hintText: '레슨 피드백을 작성하세요...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiaryLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.space4),
        ),
      ),
    );
  }

  Widget _buildTeacherFeedbackCard(Lesson lesson) {
    if (lesson.feedback == null || lesson.feedback!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Text(
              '아직 피드백이 없습니다',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.feedback!,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
          if (lesson.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              '작성: ${lesson.updatedAt!.month}월 ${lesson.updatedAt!.day}일',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyPointsList(Lesson lesson) {
    if (lesson.keyPoints == null || lesson.keyPoints!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                widget.isTeacher
                    ? '+ 버튼을 눌러 주요 포인트를 추가하세요'
                    : '주요 포인트가 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: lesson.keyPoints!.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(point, style: AppTypography.bodyMedium),
              ),
              if (widget.isTeacher)
                IconButton(
                  onPressed: () => _removeKeyPoint(lesson, index),
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  color: AppColors.textTertiaryLight,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  tooltip: '삭제',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticeTips(Lesson lesson) {
    final hasTips = lesson.practiceTips != null && lesson.practiceTips!.isNotEmpty;

    if (!hasTips) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondaryLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates_outlined, color: AppColors.textTertiaryLight),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                widget.isTeacher
                    ? '+ 버튼을 눌러 연습 팁을 추가하세요'
                    : '연습 팁이 없습니다',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              lesson.practiceTips ?? '',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
          if (widget.isTeacher)
            IconButton(
              onPressed: () => _showEditPracticeTipDialog(lesson),
              icon: const Icon(Icons.edit_outlined),
              iconSize: 18,
              color: AppColors.info,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: '수정',
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
          // Recording status
          if (_isRecording) _buildRecordingStatus(),

          // Past recordings
          _buildSectionHeader('녹음 파일', Icons.mic),
          const SizedBox(height: AppSpacing.space3),

          if (lesson.recordings == null || lesson.recordings!.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic_off, color: AppColors.textTertiaryLight),
                  const SizedBox(width: AppSpacing.space3),
                  Text(
                    '녹음 파일이 없습니다',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          else
            ...lesson.recordings!.asMap().entries.map((entry) {
              final idx = entry.key;
              final recording = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _buildRecordingCard(
                  title: '레슨 녹음 ${idx + 1}',
                  duration: _formatRecordingDuration(recording.duration),
                  date:
                      '${recording.recordedAt.month}월 ${recording.recordedAt.day}일 ${recording.recordedAt.hour}:${recording.recordedAt.minute.toString().padLeft(2, '0')}',
                  hasTranscript: recording.transcription != null,
                ),
              );
            }),

          const SizedBox(height: AppSpacing.space6),

          // AI Summary (if available)
          if (lesson.recordings?.any((r) => r.aiSummary != null) == true) ...[
            _buildSectionHeader('AI 요약', Icons.auto_awesome),
            const SizedBox(height: AppSpacing.space3),
            _buildAISummaryCard(lesson),
          ],
        ],
      ),
    );
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildRecordingStatus() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '녹음 중',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(_recordingSeconds),
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.error,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildRecordingCard({
    required String title,
    required String duration,
    required String date,
    required bool hasTranscript,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: Icon(Icons.audio_file, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$date · $duration',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // Play recording
                },
                icon: const Icon(Icons.play_circle_filled),
                iconSize: 40,
                color: AppColors.primary,
              ),
            ],
          ),
          if (hasTranscript) ...[
            const SizedBox(height: AppSpacing.space3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.text_snippet_outlined,
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '텍스트 변환 완료',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '보기',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAISummaryCard(Lesson lesson) {
    final aiSummary = lesson.recordings
        ?.firstWhere((r) => r.aiSummary != null, orElse: () => lesson.recordings!.first)
        .aiSummary;

    if (aiSummary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'AI가 생성한 레슨 요약',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            aiSummary,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
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

  Future<bool?> _showCancelConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레슨 취소'),
        content: const Text('이 레슨을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('레슨 삭제'),
        content: const Text(
          '이 레슨을 삭제하시겠습니까?\n녹음 파일과 노트도 함께 삭제됩니다.',
        ),
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

  // Key points and practice tips editing methods
  void _showAddKeyPointDialog(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTipBottomSheet(
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
      builder: (context) => _AddTipBottomSheet(
        title: '연습 팁 추가',
        instrument: lesson.instrument,
        initialCategory: TipCategory.practice,
        onSubmit: (content) => _setPracticeTip(lesson, content),
      ),
    );
  }

  void _showEditPracticeTipDialog(Lesson lesson) {
    final controller = TextEditingController(text: lesson.practiceTips ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('연습 팁 수정'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '연습 팁을 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          if (lesson.practiceTips != null && lesson.practiceTips!.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _setPracticeTip(lesson, null);
              },
              child: Text(
                '삭제',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _setPracticeTip(lesson, controller.text.trim());
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
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

/// Bottom sheet for adding tips with template support
class _AddTipBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String? instrument;
  final TipCategory? initialCategory;
  final Function(String content) onSubmit;

  const _AddTipBottomSheet({
    required this.title,
    this.instrument,
    this.initialCategory,
    required this.onSubmit,
  });

  @override
  ConsumerState<_AddTipBottomSheet> createState() => _AddTipBottomSheetState();
}

class _AddTipBottomSheetState extends ConsumerState<_AddTipBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Text(widget.title, style: AppTypography.headingMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showTipTemplateBottomSheet(
                        context: context,
                        instrument: widget.instrument,
                        initialCategory: widget.initialCategory,
                        onSelect: widget.onSubmit,
                      );
                    },
                    icon: const Icon(Icons.library_books_outlined, size: 18),
                    label: const Text('템플릿에서'),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.space4),

              // Text input
              TextField(
                controller: _controller,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '직접 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final content = _controller.text.trim();
                    if (content.isNotEmpty) {
                      Navigator.pop(context);
                      widget.onSubmit(content);
                    }
                  },
                  child: const Text('추가'),
                ),
              ),

              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
