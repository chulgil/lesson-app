import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teaching_resource.dart';
import '../providers/teaching_resource_providers.dart';

/// Bottom sheet for adding a teacher recording resource (Phase 2).
///
/// Allows the teacher to record or pick an audio file,
/// add a title and description, then save as a teaching resource.
class AddRecordingResourceSheet extends ConsumerStatefulWidget {
  final void Function(TeachingResource resource)? onResourceCreated;

  const AddRecordingResourceSheet({
    super.key,
    this.onResourceCreated,
  });

  @override
  ConsumerState<AddRecordingResourceSheet> createState() =>
      _AddRecordingResourceSheetState();
}

class _AddRecordingResourceSheetState
    extends ConsumerState<AddRecordingResourceSheet> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('시범 연주 녹음 추가',
                    style: AppTypography.headingSmall),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // File picker area
            GestureDetector(
              onTap: _pickAudioFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.space6),
                decoration: BoxDecoration(
                  color: AppColors.paperDark,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLarge),
                  border: Border.all(
                    color: _selectedFilePath != null
                        ? AppColors.primary
                        : AppColors.inkQuaternary,
                    width: _selectedFilePath != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFilePath != null
                          ? Icons.audiotrack
                          : Icons.mic_outlined,
                      size: 48,
                      color: _selectedFilePath != null
                          ? AppColors.primary
                          : AppColors.inkTertiary,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      _selectedFileName ?? '탭하여 오디오 파일 선택',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _selectedFilePath != null
                            ? AppColors.ink
                            : AppColors.inkSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFilePath == null)
                      Text(
                        'm4a, mp3, wav 지원',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '예: 바흐 미뉴에트 G장조 시범연주',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Description
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (학생에게 표시)',
                hintText: '연습 포인트를 적어주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.space6),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit =>
      _selectedFilePath != null &&
      _titleController.text.trim().isNotEmpty &&
      !_isSubmitting;

  Future<void> _pickAudioFile() async {
    // Use file picker for audio files
    // For now, use image_picker as a fallback pattern
    try {
      final picker = ImagePicker();
      final result = await picker.pickMedia();
      if (result != null) {
        setState(() {
          _selectedFilePath = result.path;
          _selectedFileName = result.name;
          if (_titleController.text.isEmpty) {
            _titleController.text =
                result.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 선택할 수 없습니다')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final resource = await ref
          .read(teachingResourceNotifierProvider.notifier)
          .createResource(
            type: TeachingResourceType.teacherRecording,
            title: _titleController.text.trim(),
            description: _memoController.text.trim().isNotEmpty
                ? _memoController.text.trim()
                : null,
            audioUrl: _selectedFilePath,
          );

      if (mounted) {
        widget.onResourceCreated?.call(resource);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('녹음 추가에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
