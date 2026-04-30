import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../students/domain/entities/lesson_class.dart';
import '../../../students/presentation/providers/lesson_class_providers.dart';
import '../../../students/presentation/providers/membership_providers.dart';
import '../../../subscription/presentation/widgets/subscription_badge.dart';
import '../../../subscription/subscription_facade.dart';

/// Lesson card — **Notebook × Score 스타일**.
///
/// 종이 위의 "프로그램 한 편":
/// - 배경: 투명 (paper 그대로), 카드 그림자 제거
/// - 좌측: 3px 세로선 (상태별 ink/paperAccent/paperOk)
/// - 시간: IBM Plex Mono (악보 템포 라벨 메타포)
/// - 학생·악기: Playfair pieceTitle
/// - 하단 1px 잉크 라인으로 다음 레슨과 구분
class LessonCard extends ConsumerWidget {
  final Lesson lesson;
  final VoidCallback onTap;

  const LessonCard({super.key, required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _getStatusColor(), width: 3),
              bottom: const BorderSide(color: AppColors.inkQuaternary),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              AppSpacing.space3,
              AppSpacing.space2,
              AppSpacing.space3,
            ),
            child: Row(
              children: [
                // Time column — Plex Mono (악보 템포 라벨)
                SizedBox(
                  width: 52,
                  child: Text(
                    lesson.startTime,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                // Info section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lesson.studentName} · ${lesson.instrument}',
                        style: NotebookTypography.pieceTitle.copyWith(
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      _buildBadgesRow(ref),
                      if (lesson.pieces.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            lesson.pieces.first.displayName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status label — uppercase sans, 스탬프 느낌
                SizedBox(
                  width: 40,
                  child: Text(
                    _getStatusLabel(),
                    style: NotebookTypography.sectionLabel.copyWith(
                      color: _getStatusColor(),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: AppSpacing.space1),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.inkTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (lesson.displayStatus) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return AppStrings.statusUpcoming;
      case LessonStatus.completed:
        return AppStrings.statusCompleted;
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return AppStrings.statusCancelled;
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return AppStrings.statusAbsent;
    }
  }

  Color _getStatusColor() {
    switch (lesson.displayStatus) {
      case LessonStatus.scheduled:
      case LessonStatus.reschedulePending:
        return AppColors.ink;
      case LessonStatus.completed:
        return AppColors.paperOk;
      case LessonStatus.cancelled:
      case LessonStatus.cancelledByStudentAdvance:
      case LessonStatus.cancelledByTeacher:
      case LessonStatus.cancelledMutual:
        return AppColors.inkTertiary;
      case LessonStatus.noShow:
      case LessonStatus.cancelledByStudentLate:
      case LessonStatus.studentAbsent:
        return AppColors.paperAccent;
    }
  }

  /// Build context badge and subscription badge row.
  Widget _buildBadgesRow(WidgetRef ref) {
    final memberships =
        ref
            .watch(activeStudentMembershipsProvider(lesson.studentId))
            .valueOrNull;
    final subscriptions =
        ref
            .watch(activeStudentSubscriptionsProvider(lesson.studentId))
            .valueOrNull;

    // Context badge from lesson class
    Widget? contextBadge;
    if (memberships != null && memberships.isNotEmpty) {
      final lessonClass =
          ref
              .watch(lessonClassProvider(memberships.first.lessonClassId))
              .valueOrNull;
      if (lessonClass != null) {
        final isAcademy = lessonClass.type == LessonClassType.academy;
        contextBadge = Text(
          isAcademy ? lessonClass.name : AppStrings.individualLesson,
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    final subscription =
        (subscriptions?.isNotEmpty == true) ? subscriptions!.first : null;

    if (contextBadge == null && subscription == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (contextBadge != null) Flexible(child: contextBadge),
          if (contextBadge != null && subscription != null)
            const SizedBox(width: 6),
          if (subscription != null)
            SubscriptionBadge(subscription: subscription, showIcon: false),
        ],
      ),
    );
  }
}
