import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/teaching_resource.dart';
import '../providers/teaching_resource_providers.dart';

/// Bottom sheet for adding a YouTube resource
class AddYoutubeResourceSheet extends ConsumerStatefulWidget {
  /// Called when a resource is successfully created
  final void Function(TeachingResource resource)? onResourceCreated;

  const AddYoutubeResourceSheet({super.key, this.onResourceCreated});

  @override
  ConsumerState<AddYoutubeResourceSheet> createState() =>
      _AddYoutubeResourceSheetState();
}

class _AddYoutubeResourceSheetState
    extends ConsumerState<AddYoutubeResourceSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _startMinController = TextEditingController();
  final _startSecController = TextEditingController();
  final _endMinController = TextEditingController();
  final _endSecController = TextEditingController();

  bool _isSubmitting = false;
  bool _useTimestamp = false;
  String? _parsedVideoId;
  String? _parsedThumbnail;
  bool _urlParsed = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _titleController.dispose();
    _memoController.dispose();
    _startMinController.dispose();
    _startSecController.dispose();
    _endMinController.dispose();
    _endSecController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _urlParsed = false;
        _parsedVideoId = null;
        _parsedThumbnail = null;
      });
      return;
    }

    final parsed = TeachingResource.parseYoutubeUrl(url);
    if (parsed.videoId != null) {
      setState(() {
        _parsedVideoId = parsed.videoId;
        _parsedThumbnail = TeachingResource.thumbnailUrl(parsed.videoId);
        _urlParsed = true;

        // Auto-fill timestamp if URL has t= parameter
        if (parsed.startSeconds != null && parsed.startSeconds! > 0) {
          _useTimestamp = true;
          _startMinController.text = '${parsed.startSeconds! ~/ 60}';
          _startSecController.text = '${parsed.startSeconds! % 60}'.padLeft(
            2,
            '0',
          );
        }
      });
    } else {
      setState(() {
        _urlParsed = false;
        _parsedVideoId = null;
        _parsedThumbnail = null;
      });
    }
  }

  int? _parseTimestamp(
    TextEditingController minCtrl,
    TextEditingController secCtrl,
  ) {
    final min = int.tryParse(minCtrl.text.trim()) ?? 0;
    final sec = int.tryParse(secCtrl.text.trim()) ?? 0;
    final total = min * 60 + sec;
    return total > 0 ? total : null;
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space4),
                ),
              ),

              Text('유튜브 영상 추가', style: AppTypography.headingMedium),
              const SizedBox(height: AppSpacing.space4),

              // URL input
              _buildLabel('URL'),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.link, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),

              // Thumbnail preview (shown when URL is valid)
              if (_urlParsed && _parsedThumbnail != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          _parsedThumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: AppColors.surfaceSecondaryLight,
                                child: Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 48,
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.space2),
                        color: AppColors.practiceGood.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.practiceGood,
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Text(
                              'URL 확인됨',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.practiceGood,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
              ],

              // Title
              _buildLabel('제목'),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '예: 힐러리 한 - 바흐 파르티타',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),

              // Timestamp toggle
              Row(
                children: [
                  Text(
                    '재생 구간',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _useTimestamp,
                    onChanged: (v) => setState(() => _useTimestamp = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),

              // Timestamp inputs
              if (_useTimestamp) ...[
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    // Start time
                    Expanded(
                      child: _buildTimeInput(
                        label: '시작',
                        minController: _startMinController,
                        secController: _startSecController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                      ),
                      child: Text('~', style: AppTypography.headingSmall),
                    ),
                    // End time
                    Expanded(
                      child: _buildTimeInput(
                        label: '종료 (선택)',
                        minController: _endMinController,
                        secController: _endSecController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
              ],

              // Memo
              const SizedBox(height: AppSpacing.space2),
              _buildLabel('메모 (학생에게 표시)'),
              TextField(
                controller: _memoController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '예: 1:32~2:05 구간의 보잉 방향 전환을 관찰하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),

              // Submit
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('추가'),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required TextEditingController minController,
    required TextEditingController secController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '분',
                    hintStyle: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                  ),
                  style: AppTypography.bodySmall,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space1,
              ),
              child: Text(':', style: AppTypography.bodyMedium),
            ),
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: secController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '초',
                    hintStyle: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space2,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                  ),
                  style: AppTypography.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('유튜브 URL을 입력해주세요')));
      return;
    }

    if (_parsedVideoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 유튜브 URL을 입력해주세요')));
      return;
    }

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final startSeconds =
          _useTimestamp
              ? _parseTimestamp(_startMinController, _startSecController)
              : null;
      final endSeconds =
          _useTimestamp
              ? _parseTimestamp(_endMinController, _endSecController)
              : null;

      final resource = await ref
          .read(teachingResourceNotifierProvider.notifier)
          .addYoutubeResource(
            title: title,
            youtubeUrl: url,
            youtubeVideoId: _parsedVideoId,
            youtubeThumbnail: _parsedThumbnail,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
            description:
                _memoController.text.trim().isNotEmpty
                    ? _memoController.text.trim()
                    : null,
          );

      if (mounted) {
        widget.onResourceCreated?.call(resource);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('유튜브 영상이 추가되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
