import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_detail_app_bar.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/academy_facade.dart';

class AcademyAnnouncementsScreen extends ConsumerWidget {
  const AcademyAnnouncementsScreen({required this.academyId, super.key});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(academyAnnouncementsProvider(academyId));

    return NotebookScreenScaffold(
      appBar: const NotebookDetailAppBar(title: AppStrings.announcementsTitle),
      body: announcementAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Text(
                AppStrings.announcementNoContent,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.space4),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return _AnnouncementCard(
                announcement: announcement,
                onTap: () {
                  context.push(
                    '/academy/$academyId/announcements/${announcement.id}',
                    extra: announcement,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(AppStrings.announcementsLoadErrorWith(error))),
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final AcademyAnnouncement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotebookCard(
      margin: EdgeInsets.only(bottom: AppSpacing.space3),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!announcement.isRead)
                    // #991 — unread 마커 통일: notification_item 표준 6x6 사각(각진).
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: AppSpacing.space2),
                      color: AppColors.paperAccent,
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.space2),
              Text(
                announcement.body,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.space3),
              Text(
                _formatDate(announcement.sentAt),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return '방금 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
