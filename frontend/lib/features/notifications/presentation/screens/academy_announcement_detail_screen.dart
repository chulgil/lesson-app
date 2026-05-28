import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_spacing.dart';
import 'package:lessonaza/core/theme/app_typography.dart';
import 'package:lessonaza/features/academy/academy.dart';
import 'package:lessonaza/features/academy/data/repositories/mock_academy_announcement_repository.dart';

class AcademyAnnouncementDetailScreen extends ConsumerWidget {
  const AcademyAnnouncementDetailScreen({
    required this.announcement,
    super.key,
  });

  final AcademyAnnouncement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.announcementsTitle,
          style: AppTypography.headingMedium.copyWith(color: AppColors.ink),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: AppTypography.headingLarge.copyWith(color: AppColors.ink),
            ),
            SizedBox(height: AppSpacing.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(announcement.sentAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                if (!announcement.isRead)
                  ElevatedButton.icon(
                    onPressed: () {
                      _markAsRead(ref);
                    },
                    icon: const Icon(Icons.check),
                    label: Text(AppStrings.announcementMarkAsRead),
                  ),
              ],
            ),
            Divider(height: AppSpacing.space5, color: AppColors.inkQuaternary),
            Text(
              announcement.body,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(WidgetRef ref) async {
    final repo = MockAcademyAnnouncementRepository();
    await repo.markAsRead(announcement.id);
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
