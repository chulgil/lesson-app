import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../../features/lessons/domain/entities/lesson.dart';
import '../../providers/feedback_template_providers.dart';
import '../feedback_template_picker_sheet.dart';

/// Section header widget for lesson detail screen
class LessonDetailSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showAddButton;
  final VoidCallback? onAdd;

  const LessonDetailSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.showAddButton = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        // Notebook × Score: 섹션 제목을 Playfair 17 로 통일 (매스트헤드·AppBar 위계와 맞춤).
        Text(title, style: NotebookTypography.sectionTitle),
        const Spacer(),
        if (showAddButton && onAdd != null)
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 22,
            color: AppColors.paperAccent,
            tooltip: AppStrings.add,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

/// Note editor widget for lesson feedback.
///
/// §7.135: chip line(`feedbackPresets` 단어 누적) → 템플릿 1탭 본문 교체.
/// §7.136: Notebook × Score 마지널리아 패턴 — 본문 위 28px 단일 행에
/// 좌측 `※ 템플릿 가져오기`(NotebookGlyph + Gaegu handEmphasis), 우측
/// `↶` undo (Material 시스템 affordance). Stack overlay 폐기로 본문/액션
/// 시선이 한 행에 정렬, OutlinedButton 의 시각적 무게 제거.
class LessonNoteEditor extends ConsumerStatefulWidget {
  final String? initialText;
  final ValueChanged<String>? onChanged;

  const LessonNoteEditor({super.key, this.initialText, this.onChanged});

  @override
  ConsumerState<LessonNoteEditor> createState() => _LessonNoteEditorState();
}

class _LessonNoteEditorState extends ConsumerState<LessonNoteEditor> {
  static const int _undoStackMax = 20;
  static const Duration _undoSnapshotDebounce = Duration(milliseconds: 1500);

  late TextEditingController _controller;
  final ScrollController _editorScroll = ScrollController();
  _SaveStatus _saveStatus = _SaveStatus.idle;
  Timer? _statusResetTimer;
  Timer? _snapshotTimer;

  // Undo snapshots (FIFO drop at _undoStackMax). 최신 push 끝에 위치.
  final List<String> _undoStack = <String>[];
  // 마지막 push 시점 텍스트. 신규 변경이 이 값과 다를 때만 snapshot 후보.
  late String _lastSnapshotText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _lastSnapshotText = _controller.text;
  }

  @override
  void dispose() {
    _statusResetTimer?.cancel();
    _snapshotTimer?.cancel();
    _editorScroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 본문 끝(append된 새 템플릿)이 보이도록 다음 프레임에 스크롤.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_editorScroll.hasClients) return;
      _editorScroll.animateTo(
        _editorScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// 현재 컨트롤러 텍스트가 마지막 snapshot과 다르면 stack에 push.
  /// FIFO: max 초과 시 가장 오래된 항목 제거.
  void _pushSnapshot() {
    final current = _controller.text;
    if (current == _lastSnapshotText) return;
    _undoStack.add(_lastSnapshotText);
    if (_undoStack.length > _undoStackMax) {
      _undoStack.removeAt(0);
    }
    _lastSnapshotText = current;
  }

  void _onChanged(String text) {
    setState(() => _saveStatus = _SaveStatus.saving);
    widget.onChanged?.call(text);

    // Show "saved" after debounce delay (800ms) + small buffer
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _saveStatus = _SaveStatus.saved);
        // Reset to idle after 2 seconds
        _statusResetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
        });
      }
    });

    // Undo snapshot — debounce 1.5s 동안 추가 입력 없으면 묶음 push.
    // 글자 단위 push는 사용자 의도와 어긋나므로 묶음 단위만 보존.
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer(_undoSnapshotDebounce, () {
      if (!mounted) return;
      setState(_pushSnapshot);
    });
  }

  Future<void> _applyTemplate() async {
    final selected = await FeedbackTemplatePickerSheet.show(context);
    if (selected == null || !mounted) return;

    // 적용 직전 본문은 즉시 snapshot — 잘못 적용해도 1탭 회복 가능.
    _snapshotTimer?.cancel();
    setState(_pushSnapshot);

    // 누적 추가: 빈 본문이면 그대로, 기존 본문이 있으면 빈 줄로 구분 후 끝에 append.
    final existing = _controller.text.trimRight();
    final hasExisting = existing.isNotEmpty;
    final body = hasExisting ? '$existing\n\n${selected.body}' : selected.body;
    _controller.value = TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(offset: body.length),
    );
    _onChanged(body);
    // append된 새 본문 끝이 보이도록 내부 스크롤 다운.
    _scrollToEnd();

    // usageCount +1 — 실패해도 UX에 영향 없으므로 fire-and-forget.
    unawaited(
      ref
          .read(feedbackTemplatesNotifierProvider.notifier)
          .useTemplate(selected.id),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasExisting
              ? AppStrings.feedbackTemplateAddedSnack
              : AppStrings.feedbackTemplateAppliedSnack,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final restored = _undoStack.removeLast();
    _snapshotTimer?.cancel();
    _lastSnapshotText = restored;
    _controller.value = TextEditingValue(
      text: restored,
      selection: TextSelection.collapsed(offset: restored.length),
    );
    setState(() {}); // stack 변화 → IconButton 활성도 갱신.

    // 자동 저장 동기화 — 화면만 되돌고 DB는 그대로면 모순.
    // _onChanged 내부에서 snapshot debounce 재시작하나, 즉시 push된 적 있는
    // 직후라 같은 값이면 no-op.
    setState(() => _saveStatus = _SaveStatus.saving);
    widget.onChanged?.call(restored);
    _statusResetTimer?.cancel();
    _statusResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _saveStatus = _SaveStatus.saved);
        _statusResetTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.lessonNoteUndoSnack),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Marginalia row — 본문 위 28px 단일 행.
  ///
  /// 좌: `※ 템플릿 가져오기` (NotebookGlyph + Gaegu, 여백 주석 메타포).
  /// 우: `↶` undo (Material 시스템 affordance).
  /// 두 액션이 한 쌍("교체"-"되돌리기")이므로 같은 행에 배치.
  Widget _buildMarginaliaRow({required bool canUndo}) {
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌: ※ + Gaegu handEmphasis 라벨. InkWell tap → 템플릿 시트.
          InkWell(
            onTap: _applyTemplate,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: AppSpacing.space1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NotebookGlyph(
                    NotebookGlyph.referenceMark,
                    size: 14,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    AppStrings.feedbackTemplatePickerSelectButton,
                    style: NotebookTypography.handEmphasis,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // 우: 되돌리기 — Material undo (system affordance, §9 일반 영역).
          IconButton(
            onPressed: canUndo ? _undo : null,
            icon: const Icon(Icons.undo),
            iconSize: 18,
            // 활성 시 paperAccent — 행동 가능 시그널.
            color: canUndo ? AppColors.paperAccent : AppColors.inkTertiary,
            tooltip: AppStrings.lessonNoteUndoTooltip,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = _undoStack.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // §7.136: 마지널리아 행 — 템플릿 + Undo 한 쌍을 본문 위에 정렬.
        _buildMarginaliaRow(canUndo: canUndo),

        // 본문 — Stack overlay 폐기, 단일 컨테이너.
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: TextField(
            maxLines: 6,
            controller: _controller,
            scrollController: _editorScroll,
            onChanged: _onChanged,
            // 선생님 피드백 = 자필 본문 → Tier 1 Gaegu hand
            // (README §1.1.1, §7.129 사용자 입력 정렬).
            style: NotebookTypography.hand,
            decoration: InputDecoration(
              hintText: AppStrings.feedbackEditorHint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.space4),
            ),
          ),
        ),

        // Save status
        if (_saveStatus != _SaveStatus.idle)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space1),
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    _saveStatus == _SaveStatus.saving
                        ? Row(
                          key: const ValueKey('saving'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.inkTertiary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              AppStrings.savingLabel,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ],
                        )
                        : Row(
                          key: const ValueKey('saved'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.paperOk,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              AppStrings.savedLabel,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.paperOk,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _SaveStatus { idle, saving, saved }

/// Card displaying teacher feedback
class TeacherFeedbackCard extends StatelessWidget {
  final Lesson lesson;

  const TeacherFeedbackCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    if (lesson.feedback == null || lesson.feedback!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.paperDark),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space3),
            Text(
              AppStrings.feedbackEmpty,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Notebook × Score: 레슨 상세 피드백 본문도 선생님 손글씨 주석(Gaegu)으로 렌더.
            lesson.feedback!,
            style: NotebookTypography.hand,
          ),
          if (lesson.updatedAt != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.feedbackWrittenAt(formatDateYMD(lesson.updatedAt!)),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// List of key points for a lesson
class KeyPointsList extends StatelessWidget {
  final Lesson lesson;
  final bool isTeacher;
  final void Function(int index)? onRemove;

  const KeyPointsList({
    super.key,
    required this.lesson,
    required this.isTeacher,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson.keyPoints == null || lesson.keyPoints!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.paperDark),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                isTeacher
                    ? AppStrings.keyPointsEmptyTeacher
                    : AppStrings.keyPointsEmptyStudent,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          lesson.keyPoints!.asMap().entries.map((entry) {
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
                      color: AppColors.paperAccent,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(child: Text(point, style: AppTypography.bodyMedium)),
                  if (isTeacher && onRemove != null)
                    IconButton(
                      onPressed: () => onRemove!(index),
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      color: AppColors.inkTertiary,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      tooltip: AppStrings.delete,
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

/// Practice tips card
class PracticeTipsCard extends StatelessWidget {
  final Lesson lesson;
  final bool isTeacher;
  final VoidCallback? onEdit;

  const PracticeTipsCard({
    super.key,
    required this.lesson,
    required this.isTeacher,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasTips =
        lesson.practiceTips != null && lesson.practiceTips!.isNotEmpty;

    if (!hasTips) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.paperDark),
        child: Row(
          children: [
            Icon(Icons.tips_and_updates_outlined, color: AppColors.inkTertiary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text(
                isTeacher
                    ? AppStrings.practiceTipsEmptyTeacher
                    : AppStrings.practiceTipsEmptyStudent,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.ink, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            // Notebook × Score: 연습 팁은 선생님이 여백에 손글씨로 적어준 메모.
            child: Text(
              lesson.practiceTips ?? '',
              style: NotebookTypography.hand.copyWith(color: AppColors.ink),
            ),
          ),
          if (isTeacher && onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              iconSize: 18,
              color: AppColors.ink,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: AppStrings.modify,
            ),
        ],
      ),
    );
  }
}

/// Recording status indicator
class RecordingStatusIndicator extends StatelessWidget {
  final int recordingSeconds;

  const RecordingStatusIndicator({super.key, required this.recordingSeconds});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.paperAccent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            AppStrings.recordingInProgress,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatDuration(recordingSeconds),
            style: AppTypography.headingMedium.copyWith(
              color: AppColors.paperAccent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state for recordings
class RecordingsEmptyState extends StatelessWidget {
  const RecordingsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        children: [
          Icon(Icons.mic_off, color: AppColors.inkTertiary),
          const SizedBox(width: AppSpacing.space3),
          Text(
            AppStrings.recordingsEmpty,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show cancel lesson confirmation dialog
Future<bool?> showCancelLessonConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.actionLessonCancel),
          content: const Text(AppStrings.cancelLessonConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.no),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.cancelRequestAction),
            ),
          ],
        ),
  );
}

/// Show delete lesson confirmation dialog
Future<bool?> showDeleteLessonConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.deleteLessonTitle),
          content: const Text(AppStrings.deleteLessonConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.paperAccent,
              ),
              child: const Text(AppStrings.delete),
            ),
          ],
        ),
  );
}

/// Show edit practice tip dialog
Future<String?> showEditPracticeTipDialog({
  required BuildContext context,
  required String? currentTip,
  required bool hasTip,
}) async {
  final controller = TextEditingController(text: currentTip ?? '');

  return showDialog<String?>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text(AppStrings.editPracticeTipTitle),
          content: TextField(
            controller: controller,
            maxLines: 4,
            // 연습 팁 = 선생님 자필 → Tier 1 Gaegu hand
            // (README §1.1.1, §7.129).
            style: NotebookTypography.hand,
            decoration: const InputDecoration(
              hintText: AppStrings.editPracticeTipHint,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(AppStrings.cancel),
            ),
            if (hasTip)
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: Text(
                  AppStrings.delete,
                  style: TextStyle(color: AppColors.paperAccent),
                ),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
  );
}

/// Student memo card - allows students to write their own notes about a lesson
class StudentMemoCard extends StatefulWidget {
  final String? initialMemo;
  final ValueChanged<String> onSave;

  const StudentMemoCard({super.key, this.initialMemo, required this.onSave});

  @override
  State<StudentMemoCard> createState() => _StudentMemoCardState();
}

class _StudentMemoCardState extends State<StudentMemoCard> {
  late final TextEditingController _controller;
  Timer? _debounce;
  _SaveStatus _status = _SaveStatus.idle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMemo);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _status = _SaveStatus.saving);
    _debounce = Timer(const Duration(milliseconds: 800), () {
      try {
        widget.onSave(value.trim());
        if (mounted) {
          setState(() => _status = _SaveStatus.saved);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _status = _SaveStatus.idle);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonDetailSectionHeader(
          title: AppStrings.studentMemoTitle,
          icon: Icons.sticky_note_2_outlined,
        ),
        const SizedBox(height: AppSpacing.space3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperAccentSoft,
            border: Border.all(color: AppColors.paperAccentSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppStrings.studentMemoHint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                // 학생 메모 = 자필 본문 → Tier 1 Gaegu hand
                // (README §1.1.1, §7.129 사용자 입력 정렬).
                style: NotebookTypography.hand,
              ),
              const SizedBox(height: AppSpacing.space2),
              if (_status == _SaveStatus.saving)
                Text(
                  AppStrings.savingLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                )
              else if (_status == _SaveStatus.saved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: AppColors.paperOk),
                    const SizedBox(width: AppSpacing.space1),
                    Text(
                      AppStrings.savedLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperOk,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Format recording duration
String formatRecordingDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
