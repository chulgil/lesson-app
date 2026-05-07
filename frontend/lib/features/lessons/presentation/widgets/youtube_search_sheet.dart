import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/teaching_resource.dart';
import '../../domain/entities/youtube_search_result.dart';
import '../providers/teaching_resource_providers.dart';
import '../providers/youtube_search_providers.dart';
import 'add_youtube_resource_sheet.dart';

/// Full-screen bottom sheet for searching YouTube and selecting a video.
///
/// Flow:
///  1. User types query → results list appears.
///  2. Tapping [선택] on a result → timestamp selection step.
///  3. Confirm → creates TeachingResource via [TeachingResourceNotifier].
///  4. "URL 직접 입력 →" footer → opens [AddYoutubeResourceSheet].
// ignore: widget-smoke-test
class YoutubeSearchSheet extends ConsumerStatefulWidget {
  /// Called after a resource has been successfully created.
  final void Function(TeachingResource resource)? onResourceCreated;

  const YoutubeSearchSheet({super.key, this.onResourceCreated});

  @override
  ConsumerState<YoutubeSearchSheet> createState() => _YoutubeSearchSheetState();
}

class _YoutubeSearchSheetState extends ConsumerState<YoutubeSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  // Timestamp step
  YoutubeSearchResult? _selectedResult;
  bool _useTimestamp = false;
  final _startMinController = TextEditingController();
  final _startSecController = TextEditingController();
  final _endMinController = TextEditingController();
  final _endSecController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _startMinController.dispose();
    _startSecController.dispose();
    _endMinController.dispose();
    _endSecController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
  }

  void _selectResult(YoutubeSearchResult result) {
    setState(() {
      _selectedResult = result;
      _useTimestamp = false;
      _startMinController.clear();
      _startSecController.clear();
      _endMinController.clear();
      _endSecController.clear();
    });
  }

  void _backToSearch() {
    setState(() => _selectedResult = null);
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

  Future<void> _submit() async {
    final result = _selectedResult;
    if (result == null) return;

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
            title: result.title,
            youtubeUrl: result.youtubeUrl,
            youtubeVideoId: result.videoId,
            youtubeThumbnail: result.thumbnail,
            startSeconds: startSeconds,
            endSeconds: endSeconds,
          );

      if (mounted) {
        widget.onResourceCreated?.call(resource);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorTryAgain)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.zero,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child:
          _selectedResult == null
              ? _buildSearchStep()
              : _buildTimestampStep(_selectedResult!),
    );
  }

  // ─── Step 1: Search ───────────────────────────────────────────────────────

  Widget _buildSearchStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle + title
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
            AppSpacing.screenPadding,
            AppSpacing.space2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: BottomSheetHandle(
                  margin: EdgeInsets.only(bottom: AppSpacing.space3),
                ),
              ),
              Text(
                AppStrings.youtubeSearchTitle,
                style: NotebookTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space3),
              // Search bar
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: AppStrings.youtubeSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.ink),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results list
        Flexible(child: _buildResultsList()),

        // Footer: URL 직접 입력
        _buildDirectUrlFooter(),
      ],
    );
  }

  Widget _buildResultsList() {
    if (_query.isEmpty) return const SizedBox.shrink();

    final resultsAsync = ref.watch(youtubeSearchProvider(_query));

    return resultsAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(AppSpacing.space6),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error:
          (_, __) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Center(
              child: Text(
                AppStrings.youtubeSearchNoResults,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ),
          ),
      data: (results) {
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: Center(
              child: Text(
                AppStrings.youtubeSearchNoResults,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder:
              (_, __) => Container(
                height: 1,
                color: AppColors.inkQuaternary,
              ),
          itemBuilder:
              (_, index) => _SearchResultTile(
                result: results[index],
                onSelect: _selectResult,
              ),
        );
      },
    );
  }

  Widget _buildDirectUrlFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.inkQuaternary)),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          showNotebookModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder:
                (_) => AddYoutubeResourceSheet(
                  onResourceCreated: widget.onResourceCreated,
                ),
          );
        },
        child: Text(
          AppStrings.youtubeSearchDirectUrl,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.paperAccent,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.paperAccent,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ─── Step 2: Timestamp selection ─────────────────────────────────────────

  Widget _buildTimestampStep(YoutubeSearchResult result) {
    return SingleChildScrollView(
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

            // Back + title row
            Row(
              children: [
                GestureDetector(
                  onTap: _backToSearch,
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  AppStrings.youtubeSearchTitle,
                  style: NotebookTypography.sectionTitle,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),

            // Selected video preview
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inkQuaternary),
                color: AppColors.paperDark,
              ),
              child: Row(
                children: [
                  // Thumbnail
                  SizedBox(
                    width: 96,
                    height: 72,
                    child: Image.network(
                      result.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: AppColors.paperDark,
                            child: Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 28,
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.title,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (result.channel.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.space1),
                            Text(
                              result.channel,
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Timestamp toggle
            Row(
              children: [
                Text(
                  AppStrings.playSectionLabel,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _useTimestamp,
                  onChanged: (v) => setState(() => _useTimestamp = v),
                  activeThumbColor: AppColors.paperAccent,
                ),
              ],
            ),

            if (_useTimestamp) ...[
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeInput(
                      label: AppStrings.rangeStart,
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
                  Expanded(
                    child: _buildTimeInput(
                      label: AppStrings.timeEndOptionalLabel,
                      minController: _endMinController,
                      secController: _endSecController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
            ],

            const SizedBox(height: AppSpacing.space4),

            // Confirm button
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
                        : const Text(AppStrings.add),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
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
          style: AppTypography.caption.copyWith(color: AppColors.inkSecondary),
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
                    hintText: AppStrings.minuteLabel,
                    hintStyle: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space2,
                    ),
                    border: const OutlineInputBorder(),
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
                    hintText: AppStrings.secondLabel,
                    hintStyle: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space2,
                      vertical: AppSpacing.space2,
                    ),
                    border: const OutlineInputBorder(),
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
}

// ─── Search Result Tile ───────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final YoutubeSearchResult result;
  final ValueChanged<YoutubeSearchResult> onSelect;

  const _SearchResultTile({required this.result, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail 64×48, angular
          SizedBox(
            width: 64,
            height: 48,
            child: Image.network(
              result.thumbnail,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: AppColors.paperDark,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 20,
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.space3),

          // Title + channel + duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        result.channel,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (result.durationText != null) ...[
                      Text(
                        ' · ',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                      Text(
                        result.durationText!,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),

          // Select button (compact, no minimum width expansion)
          TextButton(
            onPressed: () => onSelect(result),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.paperAccent,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(AppStrings.youtubeSearchSelect),
          ),
        ],
      ),
    );
  }
}
