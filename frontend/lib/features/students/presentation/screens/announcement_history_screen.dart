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
    final announcementsAsync = ref.watch(teacherAnnouncementsProvider(teacherId));

    return NotebookScreenScaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.announcementHistoryTitle,
          style: NotebookTypography.appBarTitle,
        ),
        actions: [
          IconButton(
            onPressed: () => AnnouncementSheet.show(context, ref: ref),
            icon: const Icon(Icons.add, color: AppColors.ink),
            tooltip: AppStrings.announcementSend,
          ),
        ],
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

class _AnnouncementCard extends ConsumerWidget {
  final TeacherAnnouncement announcement;

  const _AnnouncementCard({required this.announcement});

  void _editAnnouncement(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: announcement.message);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공지 수정'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '공지 내용을 수정하세요',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty) {
      final repo = ref.read(teacherAnnouncementRepositoryProvider);
      await repo.update(TeacherAnnouncement(
        id: announcement.id,
        teacherId: announcement.teacherId,
        type: announcement.type,
        dates: announcement.dates,
        message: result,
        createdAt: announcement.createdAt,
        affectedLessons: announcement.affectedLessons,
      ));
      ref.invalidate(teacherAnnouncementsProvider(announcement.teacherId));
    }
  }

  void _deleteAnnouncement(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공지 삭제'),
        content: const Text('이 공지를 삭제하시겠습니까?\n이미 발송된 알림은 취소되지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),
            child: const Text('삭제'),
          ),
        ],
      ),
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
                const SizedBox(width: AppSpacing.space1),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  iconSize: 18,
                  icon: Icon(Icons.more_vert, size: 18, color: AppColors.inkTertiary),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.space2),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.inkQuaternary),
                      ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          child: Row(
                            children: [
                              // 학생 정보
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
                                      style: AppTypography.captionSmall.copyWith(
                                        color: AppColors.inkTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 스케줄 변경 버튼 (크고 명확)
                              if (lesson.subscriptionId != null)
                                FilledButton.icon(
                                  onPressed: () => context.push(
                                    AppRoutes.subscriptionDetail.replaceFirst(
                                      ':id',
                                      lesson.subscriptionId!,
                                    ),
                                    extra: {'viewerRole': 'teacher'},
                                  ),
                                  icon: const Icon(Icons.swap_horiz, size: 16),
                                  label: const Text(AppStrings.announcementScheduleChange),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.space3,
                                    ),
                                    textStyle: AppTypography.captionSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
