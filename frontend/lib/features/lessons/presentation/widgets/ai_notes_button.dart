import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../data/services/ai_notes_service.dart';
import '../../domain/entities/lesson.dart';
import '../providers/ai_notes_provider.dart';
import 'ai_notes_result_sheet.dart';

/// AI Notes button + status indicator for lesson detail screen.
///
/// Handles the full lifecycle: pick audio → upload → show results.
class AiNotesButton extends ConsumerWidget {
  final Lesson lesson;

  const AiNotesButton({super.key, required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteState = ref.watch(aiNoteGeneratorProvider(lesson.id));
    final status = noteState.status;

    if (status == AiNoteStatus.uploading || status == AiNoteStatus.processing) {
      return _buildProcessingCard(context, status);
    }

    if (status == AiNoteStatus.completed && noteState.result != null) {
      return _buildCompletedCard(context, ref, noteState.result!);
    }

    if (status == AiNoteStatus.failed) {
      return _buildErrorCard(context, ref, noteState.error);
    }

    // Idle state — show action button
    return _buildActionButton(context, ref);
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.paperAccentSoft, AppColors.paperAccentSoft],
        ),
        border: Border.all(color: AppColors.paperAccentSoft),
      ),
      child: InkWell(
        onTap: () => _pickAndGenerate(context, ref),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(color: AppColors.paperAccentSoft),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.paperAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 노트 생성',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.paperAccent,
                    ),
                  ),
                  Text(
                    '레슨 녹음을 업로드하면 노트를 자동 작성합니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.paperAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context, AiNoteStatus status) {
    final message =
        status == AiNoteStatus.uploading
            ? '오디오 업로드 중...'
            : 'AI 노트를 생성하고 있습니다...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccentSoft),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(message, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(
    BuildContext context,
    WidgetRef ref,
    AiNoteResult result,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperOk.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.paperOk.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showResults(context, result),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.paperOk, size: 24),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 노트 생성 완료',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.paperOk,
                    ),
                  ),
                  Text(
                    '탭하여 결과를 확인하고 수정할 수 있습니다',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.paperOk),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, String? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paperAccentSoft,
        border: Border.all(color: AppColors.paperAccent),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.paperAccent,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              error ?? 'AI 노트 생성에 실패했습니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(aiNoteGeneratorProvider(lesson.id).notifier).reset();
            },
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndGenerate(BuildContext context, WidgetRef ref) async {
    // Pick audio file
    final picker = ImagePicker();
    final result = await picker.pickMedia();
    if (result == null) return;

    // Generate
    ref
        .read(aiNoteGeneratorProvider(lesson.id).notifier)
        .generate(
          audioFilePath: result.path,
          studentName: lesson.studentName,
          instrument: lesson.instrument,
          pieces: lesson.pieces.map((p) => p.displayName).toList(),
        );
  }

  void _showResults(BuildContext context, AiNoteResult result) {
    showNotebookModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AiNotesResultSheet(result: result),
    );
  }
}
