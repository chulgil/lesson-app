import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/app_release.dart';
import '../providers/app_release_provider.dart';

class NewsRoadmapScreen extends ConsumerWidget {
  const NewsRoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseInfo = ref.watch(appReleaseSnapshotProvider);

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.newsRoadmapTitle),
      body: releaseInfo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
              child: Text(
                AppStrings.settingsInfoLoadError,
                style: AppTypography.bodyMedium,
              ),
            ),
        data:
            (releaseInfo) => ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                Text('LESSONAZA', style: NotebookTypography.mastheadLabel),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  AppStrings.newsRoadmapTitle,
                  style: NotebookTypography.masthead,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  AppStrings.newsRoadmapVersion(
                    releaseInfo.version.displayVersion,
                    releaseInfo.version.latestVersion ??
                        releaseInfo.version.currentVersion,
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                NotebookCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.newsRoadmapReleaseSectionTitle,
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        ...releaseInfo.news.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.space2,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('-'),
                                const SizedBox(width: AppSpacing.space2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        item.summary,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                Text(
                  AppStrings.newsRoadmapSectionTitle,
                  style: NotebookTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space3),
                ...releaseInfo.roadmap.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: NotebookCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.space4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 44,
                              color: AppColors.paperAccent,
                            ),
                            const SizedBox(width: AppSpacing.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.space1),
                                  Text(
                                    item.summary,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Text(
                              _statusLabel(item.status),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.paperAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  String _statusLabel(AppRoadmapStatus status) {
    return switch (status) {
      AppRoadmapStatus.planned => AppStrings.newsRoadmapStatusPlanned,
      AppRoadmapStatus.inProgress => AppStrings.newsRoadmapStatusInProgress,
      AppRoadmapStatus.shipped => AppStrings.newsRoadmapStatusShipped,
    };
  }
}
