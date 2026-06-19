import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../auth/auth_facade.dart';
import '../providers/post_providers.dart';
import '../widgets/follow_feed_item.dart';

/// Feed screen showing posts from followed teachers/academies.
///
/// Displays posts sorted by createdAt DESC (newest first).
/// Entry: profile tab → "소식" menu item.
class FollowFeedScreen extends ConsumerWidget {
  const FollowFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final feedAsync = ref.watch(followFeedProvider(userId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(
        title: AppStrings.followFeedTitle,
      ),
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                AppStrings.followFeedLoadError,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
        data: (posts) {
          if (posts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: posts.length,
            itemBuilder: (context, index) => FollowFeedItem(post: posts[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.followFeedEmptySubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
