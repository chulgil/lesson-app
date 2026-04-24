import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/teaching_resource.dart';
import '../providers/teaching_resource_providers.dart';
import 'add_youtube_resource_sheet.dart';

/// Displays attached teaching resources on a practice item card (read-only)
class ResourceAttachmentList extends ConsumerWidget {
  final List<String> resourceIds;

  const ResourceAttachmentList({super.key, required this.resourceIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resourceIds.isEmpty) return const SizedBox.shrink();

    final resourcesAsync = ref.watch(resourcesByIdsProvider(resourceIds));

    return resourcesAsync.when(
      data: (resources) {
        if (resources.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.space2),
            ...resources.map((r) => _ResourceChip(resource: r)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final TeachingResource resource;

  const _ResourceChip({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
      child: InkWell(
        onTap: () => _launchResource(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: _chipColor.withValues(alpha: 0.08),
            border: Border.all(color: _chipColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_chipIcon, size: 14, color: _chipColor),
              const SizedBox(width: AppSpacing.space1),
              Flexible(
                child: Text(
                  resource.title,
                  style: AppTypography.caption.copyWith(
                    color: _chipColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (resource.timestampText != null) ...[
                const SizedBox(width: AppSpacing.space1),
                Text(
                  '(${resource.timestampText})',
                  style: AppTypography.captionSmall.copyWith(
                    color: _chipColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.space1),
              Icon(Icons.open_in_new, size: 12, color: _chipColor),
            ],
          ),
        ),
      ),
    );
  }

  Color get _chipColor {
    switch (resource.type) {
      case TeachingResourceType.youtube:
        return AppColors.youtubeRed;
      case TeachingResourceType.teacherRecording:
        return AppColors.paperAccent;
      case TeachingResourceType.externalLink:
        return AppColors.ink;
    }
  }

  IconData get _chipIcon {
    switch (resource.type) {
      case TeachingResourceType.youtube:
        return Icons.play_circle_filled;
      case TeachingResourceType.teacherRecording:
        return Icons.music_note;
      case TeachingResourceType.externalLink:
        return Icons.link;
    }
  }

  Future<void> _launchResource(BuildContext context) async {
    final url = resource.launchUrl;
    if (url == null) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다')));
      }
    }
  }
}

/// Editable resource attachment section for practice item edit/add sheets
class ResourceAttachmentEditor extends ConsumerWidget {
  final List<String> resourceIds;
  final ValueChanged<List<String>> onChanged;
  final bool isTeacher;

  const ResourceAttachmentEditor({
    super.key,
    required this.resourceIds,
    required this.onChanged,
    this.isTeacher = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isTeacher) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: AppColors.inkSecondary),
            const SizedBox(width: AppSpacing.space1),
            Text(
              '학습 자료 (${resourceIds.length})',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),

        // Show attached resources
        if (resourceIds.isNotEmpty) ...[
          _AttachedResourceList(
            resourceIds: resourceIds,
            onRemove: (id) {
              onChanged(resourceIds.where((rid) => rid != id).toList());
            },
          ),
          const SizedBox(height: AppSpacing.space2),
        ],

        // Add resource button
        _AddResourceButton(
          onResourceSelected: (resource) {
            if (!resourceIds.contains(resource.id)) {
              onChanged([...resourceIds, resource.id]);
            }
          },
        ),
      ],
    );
  }
}

class _AttachedResourceList extends ConsumerWidget {
  final List<String> resourceIds;
  final ValueChanged<String> onRemove;

  const _AttachedResourceList({
    required this.resourceIds,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesByIdsProvider(resourceIds));

    return resourcesAsync.when(
      data:
          (resources) => Column(
            children: resources.map((r) => _buildAttachedItem(r)).toList(),
          ),
      loading:
          () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAttachedItem(TeachingResource resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Text(resource.type.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (resource.timestampText != null)
                  Text(
                    resource.timestampText!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () => onRemove(resource.id),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space1),
              child: Icon(Icons.close, size: 18, color: AppColors.inkTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddResourceButton extends ConsumerWidget {
  final ValueChanged<TeachingResource> onResourceSelected;

  const _AddResourceButton({required this.onResourceSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showAddOptions(context, ref),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('자료 첨부'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        foregroundColor: AppColors.inkSecondary,
        side: BorderSide(color: AppColors.inkQuaternary),
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  const Center(
                    child: BottomSheetHandle(
                      margin: EdgeInsets.only(bottom: AppSpacing.space4),
                    ),
                  ),
                  // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
                  // 패턴. Playfair appBarTitle 로 통일.
                  Text('학습 자료 추가', style: NotebookTypography.appBarTitle),
                  const SizedBox(height: AppSpacing.space4),

                  // From library
                  _buildOption(
                    ctx,
                    icon: Icons.folder_outlined,
                    label: '라이브러리에서 선택',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showLibraryPicker(context, ref);
                    },
                  ),

                  // New YouTube link
                  _buildOption(
                    ctx,
                    icon: Icons.play_circle_outline,
                    label: '유튜브 링크 추가',
                    color: AppColors.youtubeRed,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddYoutube(context);
                    },
                  ),

                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.inkSecondary),
      title: Text(label, style: AppTypography.bodyMedium),
      onTap: onTap,
    );
  }

  void _showLibraryPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Consumer(
            builder: (ctx, modalRef, _) {
              final resourcesAsync = modalRef.watch(
                teachingResourceNotifierProvider,
              );

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXLarge),
                  ),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        children: [
                          const Center(
                            child: BottomSheetHandle(
                              margin: EdgeInsets.only(
                                bottom: AppSpacing.space4,
                              ),
                            ),
                          ),
                          // Notebook × Score: BottomSheetHandle + 상단 제목 조합은 §7.27
                          // 패턴. Playfair appBarTitle 로 통일.
                          Text(
                            '내 학습 자료',
                            style: NotebookTypography.appBarTitle,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: resourcesAsync.when(
                        data: (resources) {
                          if (resources.isEmpty) {
                            return Center(
                              child: Text(
                                '등록된 자료가 없습니다',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                            ),
                            itemCount: resources.length,
                            itemBuilder: (_, index) {
                              final r = resources[index];
                              return ListTile(
                                leading: Text(
                                  r.type.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(
                                  r.title,
                                  style: AppTypography.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle:
                                    r.timestampText != null
                                        ? Text(
                                          r.timestampText!,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.inkTertiary,
                                          ),
                                        )
                                        : null,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  onResourceSelected(r);
                                },
                              );
                            },
                          );
                        },
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        error:
                            (_, __) => Center(
                              child: Text(
                                '자료를 불러올 수 없습니다',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.paperAccent,
                                ),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _showAddYoutube(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddYoutubeResourceSheet(onResourceCreated: onResourceSelected),
    );
  }
}
