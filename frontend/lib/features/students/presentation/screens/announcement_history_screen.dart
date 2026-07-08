import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
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
            return const EmptyStateWidget(
              icon: Icons.campaign_outlined,
              title: AppStrings.announcementHistoryEmpty,
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

  /// 편집 — 작성 시트를 EDIT 모드로 연다 (시트가 update + 리스트 invalidate 처리).
  void _editAnnouncement(BuildContext context, WidgetRef ref) {
    AnnouncementSheet.show(context, ref: ref, existing: announcement);
  }

  void _deleteAnnouncement(BuildContext context, WidgetRef ref) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.swipeActionDeleteAnnouncementConfirmTitle,
      content: const Text(AppStrings.swipeActionDeleteAnnouncementConfirmBody),
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
    final dateText = announcement.dates.isNotEmpty
        ? formatDateMD(announcement.dates.first)
        : '';

    // swipe 4원칙: 우→좌 관리 액션 [편집(normal) · 삭제(destructive)].
    // 행 탭 = 편집 시트 (swipe 편집과 동일 진입점).
    final card = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: InkWell(
        onTap: () => _editAnnouncement(context, ref),
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
            if (isDayOff && announcement.affectedLessons.isNotEmpty)
              ..._affectedStudentsSlivers(context),
          ],
        ),
      ),
    );

    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.swipeActionEdit,
          icon: Icons.edit_outlined,
          onPressed: () => _editAnnouncement(context, ref),
        ),
        SwipeAction(
          label: AppStrings.swipeActionDelete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _deleteAnnouncement(context, ref),
        ),
      ],
      child: card,
    );
  }

  List<Widget> _affectedStudentsSlivers(BuildContext context) {
    final isDayOff = announcement.type == AnnouncementType.dayOff;
    if (!isDayOff || announcement.affectedLessons.isEmpty) {
      return const [];
    }
    return [
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
                            label: const Text(
                              AppStrings.announcementScheduleChange,
                            ),
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
    ];
  }
}
