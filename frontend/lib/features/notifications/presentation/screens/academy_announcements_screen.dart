import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_announcement_repository.dart';

final _announcementListProvider =
    FutureProvider.family<List<AcademyAnnouncement>, String>((
      ref,
      academyId,
    ) async {
      final repo = MockAcademyAnnouncementRepository();
      return repo.listByAcademy(academyId);
    });

class AcademyAnnouncementsScreen extends ConsumerWidget {
  const AcademyAnnouncementsScreen({required this.academyId, super.key});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(_announcementListProvider(academyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.announcementsTitle,
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.ink,
          ),
        ),
      ),
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
        error: (error, stack) => Center(child: Text('오류: $error')),
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
    return Card(
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
                    Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(left: AppSpacing.space2),
                      decoration: BoxDecoration(
                        color: AppColors.paperAccent,
                        shape: BoxShape.circle,
                      ),
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
