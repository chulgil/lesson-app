import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../auth/auth_facade.dart' show currentUserIdProvider;
import '../../domain/entities/teacher_announcement.dart';
import '../providers/teacher_announcement_providers.dart';
import '../widgets/announcement_sheet.dart';

/// 공지 이력 화면 — 선생님이 보낸 공지 목록 + 영향 학생 처리 상태.
///
/// 진입: 수강관리 📢 아이콘 길게 누르기
// ignore: widget-smoke-test
class AnnouncementHistoryScreen extends ConsumerWidget {
  const AnnouncementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherId = ref.watch(currentUserIdProvider);
    final announcementsAsync = ref.watch(
      teacherAnnouncementsProvider(teacherId),
    );

    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.announcementHistoryTitle,
        actions: [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            AnnouncementSheet.show(context, ref: ref);
          }
        },
      ),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
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
                  Icon(
                    Icons.campaign_outlined,
                    size: 48,
                    color: AppColors.inkTertiary,
                  ),
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
              return _AnnouncementCard(announcement: announcements[index]);
            },
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  final TeacherAnnouncement announcement;

  const _AnnouncementCard({required this.announcement});

  void _editAnnouncement(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: announcement.message);
    final result = await showNotebookDialog<String>(
      context: context,
      title: AppStrings.announcementEditTitle,
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: AppStrings.announcementEditHint,
        ),
      ),
      confirmLabel: AppStrings.save,
      onConfirm: () => Navigator.pop(context, controller.text.trim()),
      cancelLabel: AppStrings.cancel,
      onCancel: () => Navigator.pop(context),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty) {
      final repo = ref.read(teacherAnnouncementRepositoryProvider);
      await repo.update(
        TeacherAnnouncement(
          id: announcement.id,
          teacherId: announcement.teacherId,
          type: announcement.type,
          dates: announcement.dates,
          message: result,
          createdAt: announcement.createdAt,
          affectedLessons: announcement.affectedLessons,
        ),
      );
      ref.invalidate(teacherAnnouncementsProvider(announcement.teacherId));
    }
  }

  void _deleteAnnouncement(BuildContext context, WidgetRef ref) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.announcementDeleteTitle,
      content: const Text(AppStrings.announcementDeleteConfirm),
      confirmLabel: AppStrings.delete,
      onConfirm: () => Navigator.pop(context, true),
      cancelLabel: AppStrings.cancel,
      onCancel: () => Navigator.pop(context, false),
      isDestructive: true,
    );

    if (confirmed == true) {
      final repo = ref.read(teacherAnnouncementRepositoryProvider);
      await repo.delete(announcement.id);
      ref.invalidate(teacherAnnouncementsProvider(announcement.teacherId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDayOff = announcement.type == AnnouncementType.dayOff;
    final dateText =
        announcement.dates.isNotEmpty
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
                    isDayOff
                        ? '${AppStrings.announcementTypeDayOff} · $dateText'
                        : AppStrings.announcementTypeGeneral,
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
                const SizedBox(width: AppSpacing.space1),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  iconSize: 18,
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.inkTertiary,
                  ),
                  itemBuilder:
                      (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(AppStrings.modify),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(AppStrings.delete),
                        ),
                      ],
                  onSelected: (action) {
                    if (action == 'edit') {
                      _editAnnouncement(context, ref);
                    } else if (action == 'delete') {
                      _deleteAnnouncement(context, ref);
                    }
                  },
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
            const ThinRule(),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.inkQuaternary),
                      ),
                      child: InkWell(
                        onTap:
                            lesson.subscriptionId != null
                                ? () => context.push(
                                  AppRoutes.subscriptionDetail.replaceFirst(
                                    ':id',
                                    lesson.subscriptionId!,
                                  ),
                                  extra: {'viewerRole': 'teacher'},
                                )
                                : null,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${lesson.studentName} · ${lesson.instrument}',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      lesson.startTime,
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color: AppColors.inkTertiary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (lesson.subscriptionId != null) ...[
                                Text(
                                  AppStrings.announcementScheduleChange,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.paperAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
