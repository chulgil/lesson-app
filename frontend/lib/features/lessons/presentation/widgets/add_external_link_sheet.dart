import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/teaching_resource.dart';
import '../providers/teaching_resource_providers.dart';

/// Bottom sheet for adding an external link resource (Phase 3).
///
/// Allows the teacher to add any URL (sheet music, articles, etc.)
/// with a title and description.
class AddExternalLinkSheet extends ConsumerStatefulWidget {
  final void Function(TeachingResource resource)? onResourceCreated;

  const AddExternalLinkSheet({
    super.key,
    this.onResourceCreated,
  });

  @override
  ConsumerState<AddExternalLinkSheet> createState() =>
      _AddExternalLinkSheetState();
}

class _AddExternalLinkSheetState extends ConsumerState<AddExternalLinkSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isSubmitting = false;
  bool _urlValid = false;

  @override
  void dispose() {
    _urlController.dispose();
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
                Text('외부 링크 추가', style: AppTypography.headingSmall),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // URL input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                border: const OutlineInputBorder(),
                prefixIcon:
                    const Icon(Icons.link, color: AppColors.inkTertiary),
                suffixIcon: _urlValid
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
              ),
              keyboardType: TextInputType.url,
              onChanged: _onUrlChanged,
            ),
            const SizedBox(height: AppSpacing.space3),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '예: 바이올린 활잡기 영상',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Description
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (학생에게 표시)',
                hintText: '참고할 내용을 적어주세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.space3),

            // Hint
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      '악보, 강의 영상, 참고 자료 등 모든 URL을 추가할 수 있습니다',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Submit
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
      _urlValid &&
      _titleController.text.trim().isNotEmpty &&
      !_isSubmitting;

  void _onUrlChanged(String url) {
    final trimmed = url.trim();
    final valid = Uri.tryParse(trimmed)?.hasScheme ?? false;
    setState(() => _urlValid = valid && trimmed.isNotEmpty);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final resource = await ref
          .read(teachingResourceNotifierProvider.notifier)
          .createResource(
            type: TeachingResourceType.externalLink,
            title: _titleController.text.trim(),
            description: _memoController.text.trim().isNotEmpty
                ? _memoController.text.trim()
                : null,
            externalUrl: _urlController.text.trim(),
          );

      if (mounted) {
        widget.onResourceCreated?.call(resource);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크 추가에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
