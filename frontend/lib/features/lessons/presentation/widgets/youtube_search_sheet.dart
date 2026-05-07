import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/teaching_resource.dart';
import '../../domain/entities/youtube_search_result.dart';
import '../providers/teaching_resource_providers.dart';
import '../providers/youtube_search_providers.dart';
import 'youtube_player_widget.dart';

/// 유튜브 검색 + 구간 선택 통합 시트.
///
/// 하나의 입력창에서:
/// - URL 붙여넣기 → 자동 파싱 → 해당 영상 표시
/// - 검색어 입력 → 실시간 검색 → 결과 리스트
///
/// 결과 클릭 → 영상 프리뷰 + 구간 슬라이더 → 추가.
// ignore: widget-smoke-test
class YoutubeSearchSheet extends ConsumerStatefulWidget {
  final void Function(TeachingResource resource)? onResourceCreated;

  const YoutubeSearchSheet({super.key, this.onResourceCreated});

  @override
  ConsumerState<YoutubeSearchSheet> createState() => _YoutubeSearchSheetState();
}

class _YoutubeSearchSheetState extends ConsumerState<YoutubeSearchSheet> {
  final _inputController = TextEditingController();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  // 선택된 영상 + 구간
  YoutubeSearchResult? _selected;
  double _startSeconds = 0;
  double _endSeconds = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _inputController.dispose();
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
      }
    });
  }

  void _selectVideo(YoutubeSearchResult result) {
    setState(() {
      _selected = result;
      _startSeconds = 0;
      _endSeconds = (result.durationSeconds ?? 300).toDouble();
      _titleController.text = result.title;
      _memoController.clear();
    });
  }

  void _backToSearch() {
    setState(() => _selected = null);
  }

  Future<void> _submit() async {
    final result = _selected;
    if (result == null || _isSubmitting) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.enterTitleValidation)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final resource = await ref
          .read(teachingResourceNotifierProvider.notifier)
          .addYoutubeResource(
            title: title,
            youtubeUrl: result.youtubeUrl,
            youtubeVideoId: result.videoId,
            youtubeThumbnail: result.thumbnail,
            startSeconds: _startSeconds > 0 ? _startSeconds.round() : null,
            endSeconds:
                _endSeconds < (result.durationSeconds ?? 300).toDouble()
                    ? _endSeconds.round()
                    : null,
            description:
                _memoController.text.trim().isNotEmpty
                    ? _memoController.text.trim()
                    : null,
          );

      if (mounted) {
        widget.onResourceCreated?.call(resource);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.errorTryAgain)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.paper),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _selected == null ? _buildSearchView() : _buildDetailView(),
    );
  }

  // ── 검색 뷰 ──────────────────────────────────────────────────────

  Widget _buildSearchView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.space3,
            AppSpacing.screenPadding,
            0,
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
              // 통합 입력 (URL + 검색어)
              TextField(
                controller: _inputController,
                autofocus: true,
                onChanged: _onInputChanged,
                decoration: InputDecoration(
                  hintText: AppStrings.youtubeSearchUnifiedHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.ink),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space3,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
        Flexible(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
    if (_searchQuery.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Center(
          child: Text(
            AppStrings.youtubeSearchEmptyState,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final resultsAsync = ref.watch(youtubeSearchProvider(_searchQuery));

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
              (_, __) => Container(height: 1, color: AppColors.inkQuaternary),
          itemBuilder: (_, index) {
            final result = results[index];
            return _ResultTile(
              result: result,
              onTap: () => _selectVideo(result),
            );
          },
        );
      },
    );
  }

  // ── 상세 뷰 (영상 프리뷰 + 구간 선택) ─────────────────────────────

  Widget _buildDetailView() {
    final result = _selected!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: BottomSheetHandle(
              margin: EdgeInsets.only(bottom: AppSpacing.space3),
            ),
          ),

          // 뒤로 + 제목
          Row(
            children: [
              GestureDetector(
                onTap: _backToSearch,
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Text(
                  AppStrings.youtubeSearchTitle,
                  style: NotebookTypography.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),

          // 영상 정보 (채널 + 이름)
          Text(
            result.title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (result.channel.isNotEmpty)
            Text(
              '${result.channel} · ${result.durationText ?? ''}',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          const SizedBox(height: AppSpacing.space3),

          // ── 인앱 유튜브 플레이어 (구간 선택 포함) ──
          YoutubePlayerWidget(
            videoId: result.videoId,
            initialStartSeconds:
                _startSeconds > 0 ? _startSeconds.round() : null,
            initialEndSeconds:
                _endSeconds < (result.durationSeconds ?? 300).toDouble()
                    ? _endSeconds.round()
                    : null,
            isEditable: true,
            onSectionChanged: (section) {
              setState(() {
                _startSeconds = section.start.toDouble();
                _endSeconds = section.end.toDouble();
              });
            },
          ),

          const SizedBox(height: AppSpacing.space4),

          // 제목
          Text(
            AppStrings.titleLabel,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: AppStrings.youtubeTitleHint,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: AppSpacing.space3),

          // 메모
          Text(
            AppStrings.memoStudentVisibleLabel,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: AppStrings.youtubeMemoHint,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          const SizedBox(height: AppSpacing.space5),

          // 추가 버튼
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
    );
  }
}

// ── 검색 결과 타일 ────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final YoutubeSearchResult result;
  final VoidCallback onTap;

  const _ResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.space2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            SizedBox(
              width: 80,
              height: 60,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      result.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: AppColors.paperDark,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 24,
                                color: AppColors.inkTertiary,
                              ),
                            ),
                          ),
                    ),
                  ),
                  // 시간 뱃지
                  if (result.durationText != null)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        color: AppColors.ink.withValues(alpha: 0.75),
                        child: Text(
                          result.durationText!,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.paper,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // 정보
            Expanded(
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
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    result.channel,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
