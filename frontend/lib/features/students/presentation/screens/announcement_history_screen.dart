import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../domain/entities/teacher_announcement.dart';
import '../providers/teacher_announcement_providers.dart';

/// 공지 이력 화면 — 선생님이 보낸 공지 목록 + 영향 학생 처리 상태.
///
/// 진입: 수강관리 📢 아이콘 길게 누르기
// ignore: widget-smoke-test
class AnnouncementHistoryScreen extends ConsumerWidget {
  const AnnouncementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final announcementsAsync = ref.watch(teacherAnnouncementsProvider(teacherId));

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.announcementHistoryTitle,
          style: NotebookTypography.appBarTitle,
        ),
      ),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            AppStrings.errorTryAgain,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ),
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined, size: 48, color: AppColors.inkTertiary),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    AppStrings.announcementHistoryEmpty,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _AnnouncementCard(
                announcement: announcements[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final TeacherAnnouncement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final isDayOff = announcement.type == AnnouncementType.dayOff;
    final dateText = announcement.dates.isNotEmpty
        ? formatDateMD(announcement.dates.first)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.space3),
            decoration: BoxDecoration(
              color: isDayOff ? AppColors.paperDark : AppColors.paper,
            ),
            child: Row(
              children: [
                Icon(
                  isDayOff ? Icons.event_busy : Icons.campaign,
                  size: 18,
                  color: isDayOff ? AppColors.paperAccent : AppColors.ink,
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(
                    isDayOff ? '휴강 · $dateText' : '일반 공지',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatDateMD(announcement.createdAt),
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Message
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space2,
            ),
            child: Text(
              announcement.message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),

          // Affected students (dayOff only)
          if (isDayOff && announcement.affectedLessons.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.inkQuaternary),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.announcementAffectedStudents(
                      announcement.affectedLessons.length,
                    ),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.inkTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  ...announcement.affectedLessons.map((lesson) {
                    // TODO: Check actual schedule change status from subscription events
                    // ignore: dead_code
                    final isResolved = false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space1),
                      child: InkWell(
                        onTap: lesson.subscriptionId != null
                            ? () => context.push(
                                AppRoutes.subscriptionDetail.replaceFirst(
                                  ':id',
                                  lesson.subscriptionId!,
                                ),
                                extra: {'viewerRole': 'teacher'},
                              )
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              isResolved
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              size: 16,
                              color: isResolved
                                  ? AppColors.paperOk
                                  : AppColors.paperAccent,
                            ),
                            const SizedBox(width: AppSpacing.space2),
                            Expanded(
                              child: Text(
                                '${lesson.studentName} · ${lesson.instrument} · ${lesson.startTime}',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Text(
                              isResolved
                                  ? AppStrings.announcementStatusResolved
                                  : AppStrings.announcementStatusPending,
                              style: AppTypography.captionSmall.copyWith(
                                color: isResolved
                                    ? AppColors.paperOk
                                    : AppColors.paperAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isResolved) ...[
                              const SizedBox(width: AppSpacing.space1),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppColors.paperAccent,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
