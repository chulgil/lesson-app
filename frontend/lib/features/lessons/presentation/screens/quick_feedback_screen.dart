import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_glyph.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../providers/lesson_crud_provider.dart';
import '../providers/feedback_template_providers.dart';
import '../widgets/feedback_template_picker_sheet.dart';

/// Quick feedback writing screen for a specific lesson.
/// Supports feedback text, key points, and practice tips.
class QuickFeedbackScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const QuickFeedbackScreen({super.key, required this.lessonId});

  @override
  ConsumerState<QuickFeedbackScreen> createState() =>
      _QuickFeedbackScreenState();
}

class _QuickFeedbackScreenState extends ConsumerState<QuickFeedbackScreen> {
  late TextEditingController _feedbackController;
  late TextEditingController _tipController;
  final ScrollController _feedbackScroll = ScrollController();
  final List<String> _keyPoints = [];
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _showKeyPoints = false;
  bool _showTips = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController();
    _tipController = TextEditingController();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _tipController.dispose();
    _feedbackScroll.dispose();
    super.dispose();
  }

  void _initFromLesson(Lesson lesson) {
    if (!_hasChanges && _feedbackController.text.isEmpty) {
      _feedbackController.text = lesson.feedback ?? '';
    }
    if (!_hasChanges && _keyPoints.isEmpty && lesson.keyPoints != null) {
      _keyPoints.addAll(lesson.keyPoints!);
    }
    if (!_hasChanges && _tipController.text.isEmpty) {
      _tipController.text = lesson.practiceTips ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.feedbackTitle)),
            body: const Center(child: Text(AppStrings.lessonNotFound)),
          );
        }

        _initFromLesson(lesson);

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.studentFeedbackTitle(lesson.studentName)),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.space4),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: _hasChanges ? () => _saveFeedback(lesson) : null,
                  child: const Text(AppStrings.save),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson info header
                _buildLessonHeader(lesson),

                const SizedBox(height: AppSpacing.space6),

                // Feedback text field
                _buildSectionHeader(
                  icon: Icons.edit_note,
                  title: AppStrings.lessonFeedbackSection,
                ),
                const SizedBox(height: AppSpacing.space3),
                _buildFeedbackField(),

                const SizedBox(height: AppSpacing.space5),

                // Key Points (collapsible)
                _buildExpandableSection(
                  icon: Icons.lightbulb_outline,
                  title: AppStrings.keyPointsSection,
                  count: _keyPoints.length,
                  isExpanded: _showKeyPoints,
                  onToggle:
                      () => setState(() => _showKeyPoints = !_showKeyPoints),
                  child: _buildKeyPointsSection(),
                ),

                const SizedBox(height: AppSpacing.space4),

                // Practice Tips (collapsible)
                _buildExpandableSection(
                  icon: Icons.tips_and_updates_outlined,
                  title: AppStrings.practiceTipsSection,
                  count: _tipController.text.isNotEmpty ? 1 : 0,
                  isExpanded: _showTips,
                  onToggle: () => setState(() => _showTips = !_showTips),
                  child: _buildTipsField(),
                ),

                const SizedBox(height: AppSpacing.space6),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _hasChanges && !_isSaving
                            ? () => _saveFeedback(lesson)
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space3,
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  // Notebook × Score §7.50: Vermillion CTA foreground = paper.
                                  color: AppColors.paper,
                                ),
                              )
                              : const Text(AppStrings.saveAction),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.feedbackTitle)),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.feedbackTitle)),
            body: Center(
              child: Text(
                AppStrings.loadDataFailed,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLessonHeader(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Row(
        children: [
          Icon(Icons.music_note, color: AppColors.paperAccent, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.lessonAtDateTime(
                    formatDateYMD(lesson.date),
                    lesson.startTime,
                  ),
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppStrings.instrumentDurationSubtitle(
                    lesson.instrument,
                    lesson.duration,
                  ),
                  style: AppTypography.bodySmall.copyWith(
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

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.paperAccent),
        const SizedBox(width: AppSpacing.space2),
        // Notebook × Score: 섹션 헤더 §7.17 승격 + bodyLarge+w600 평행 패턴 §7.104.
        Text(title, style: NotebookTypography.sectionTitle),
      ],
    );
  }

  Future<void> _applyTemplate() async {
    final selected = await FeedbackTemplatePickerSheet.show(context);
    if (selected == null || !mounted) return;

    // 누적 추가: 빈 본문이면 그대로, 기존 본문이 있으면 빈 줄로 구분 후 끝에 append.
    final existing = _feedbackController.text.trimRight();
    final hasExisting = existing.isNotEmpty;
    final body = hasExisting ? '$existing\n\n${selected.body}' : selected.body;
    _feedbackController.value = TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(offset: body.length),
    );
    setState(() => _hasChanges = true);
    // append된 새 본문 끝이 보이도록 내부 스크롤 다운.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_feedbackScroll.hasClients) return;
      _feedbackScroll.animateTo(
        _feedbackScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });

    // Bump usage counter (fire-and-forget; failure is non-fatal UX-wise).
    unawaited(
      ref
          .read(feedbackTemplatesNotifierProvider.notifier)
          .useTemplate(selected.id),
    );

    if (mounted) {
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
  }

  /// §7.136: Notebook × Score 마지널리아 — `※ 템플릿으로 피드백 추가`
  /// (NotebookGlyph + Gaegu handEmphasis). 본문 위 InkWell 한 행,
  /// OutlinedButton 시각적 무게 제거.
  Widget _buildTemplateMarginalia() {
    return InkWell(
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
    );
  }

  Widget _buildFeedbackField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTemplateMarginalia(),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: TextField(
            controller: _feedbackController,
            scrollController: _feedbackScroll,
            maxLines: 6,
            onChanged: (_) => setState(() => _hasChanges = true),
            // §7.130: 선생님 자필 피드백 → Tier 1 Gaegu hand.
            style: NotebookTypography.hand.copyWith(color: AppColors.ink),
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
      ],
    );
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.paperAccent),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: AppSpacing.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(color: AppColors.paperAccentSoft),
                    child: Text(
                      '$count',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.inkTertiary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[const SizedBox(height: AppSpacing.space2), child],
      ],
    );
  }

  Widget _buildKeyPointsSection() {
    return Column(
      children: [
        // Existing points
        ..._keyPoints.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space3,
              ),
              decoration: BoxDecoration(color: AppColors.paperDark),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.paperOk,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    // §7.130: 선생님 입력 keypoint → Tier 1 Gaegu hand.
                    child: Text(
                      entry.value,
                      style: NotebookTypography.hand.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _keyPoints.removeAt(entry.key);
                        _hasChanges = true;
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.inkTertiary,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          );
        }),

        // Add new point
        _KeyPointInput(
          onAdd: (text) {
            setState(() {
              _keyPoints.add(text);
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTipsField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: TextField(
        controller: _tipController,
        maxLines: 3,
        onChanged: (_) => setState(() => _hasChanges = true),
        // §7.130: 선생님 자필 연습팁 → Tier 1 Gaegu hand.
        style: NotebookTypography.hand.copyWith(color: AppColors.ink),
        decoration: InputDecoration(
          hintText: AppStrings.practiceTipsHint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.inkTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.space4),
        ),
      ),
    );
  }

  Future<void> _saveFeedback(Lesson lesson) async {
    setState(() => _isSaving = true);

    try {
      final feedbackText = _feedbackController.text.trim();
      final tipText = _tipController.text.trim();
      final updatedLesson = lesson.copyWith(
        feedback: feedbackText.isEmpty ? null : feedbackText,
        keyPoints: _keyPoints.isEmpty ? null : _keyPoints,
        practiceTips: tipText.isEmpty ? null : tipText,
      );

      await ref
          .read(lessonsNotifierProvider.notifier)
          .updateLesson(updatedLesson);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.feedbackSavedSnack),
            backgroundColor: AppColors.paperOk,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.feedbackSaveFailed),
            backgroundColor: AppColors.paperAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Inline input for adding key points
class _KeyPointInput extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _KeyPointInput({required this.onAdd});

  @override
  State<_KeyPointInput> createState() => _KeyPointInputState();
}

class _KeyPointInputState extends State<_KeyPointInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _submit(),
            // §7.130: 선생님 keypoint 입력 → Tier 1 Gaegu hand.
            style: NotebookTypography.hand.copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              hintText: AppStrings.keyPointAddHint,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.inkTertiary,
              ),
              filled: true,
              fillColor: AppColors.paper,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.inkQuaternary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        IconButton(
          onPressed: _submit,
          icon: const Icon(Icons.add_circle),
          color: AppColors.paperAccent,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
