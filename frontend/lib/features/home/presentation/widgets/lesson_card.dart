import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../../../../features/lessons/presentation/extensions/lesson_visuals.dart';
import '../../../subscription/subscription_ui_facade.dart';
import '../providers/home_lesson_summary_provider.dart';

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

  bool get _isDimmed =>
      lesson.displayStatus == LessonStatus.completed ||
      lesson.displayStatus == LessonStatus.cancelled ||
      lesson.displayStatus == LessonStatus.cancelledByStudentAdvance ||
      lesson.displayStatus == LessonStatus.cancelledByTeacher ||
      lesson.displayStatus == LessonStatus.cancelledMutual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimAlpha = _isDimmed ? 0.45 : 1.0;

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
          child: Opacity(
            opacity: dimAlpha,
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
                            decoration:
                                _isDimmed ? TextDecoration.lineThrough : null,
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
                              style: AppTypography.bodyMedium.copyWith(
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
            .watch(homeActiveStudentMembershipsProvider(lesson.studentId))
            .valueOrNull;
    final subscriptions =
        ref
            .watch(homeActiveStudentSubscriptionsProvider(lesson.studentId))
            .valueOrNull;

    // Context badge from lesson class
    Widget? contextBadge;
    if (memberships != null && memberships.isNotEmpty) {
      final lessonClass =
          ref
              .watch(
                homeLessonClassContextProvider(memberships.first.lessonClassId),
              )
              .valueOrNull;
      if (lessonClass != null) {
        contextBadge = Text(
          lessonClass.label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
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
      // Wrap(=Row 대체): contextBadge + SubscriptionBadge 가 한 줄에 안 맞으면
      // 배지가 다음 줄로 흐른다. Row 는 고정 폭 SubscriptionBadge(ellipsis 없음)
      // 때문에 좁은 info 칼럼에서 6.5px 넘침(#853) — Wrap 은 수평 오버플로우 원천 제거.
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (contextBadge != null) contextBadge,
          if (subscription != null)
            SubscriptionBadge(subscription: subscription),
        ],
      ),
    );
  }
}
