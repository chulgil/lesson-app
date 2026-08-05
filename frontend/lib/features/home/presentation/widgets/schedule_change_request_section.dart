import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/widgets/notebook/section_header.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/presentation/extensions/unified_lesson_request_visuals.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../subscription/subscription_facade.dart';

/// Home dashboard section showing pending schedule change requests.
///
/// Uses the same card layout pattern as LessonRequestSection / RequestListItem:
/// Avatar + info lines + status chip + elapsed time.
class ScheduleChangeRequestSection extends ConsumerWidget {
  final String teacherId;

  const ScheduleChangeRequestSection({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(
      pendingScheduleChangeRequestsProvider(teacherId),
    );
    final studentNames = ref.watch(studentNameMapProvider);
    // v2: 레슨 요청에서 학생별 악기/레벨/소속 정보 매핑 (일관성)
    final requestsAsync = ref.watch(todayRequestsProvider(teacherId));
    final studentInfoMap = _buildStudentInfoMap(requestsAsync);
    final academyNames = ref.watch(academyNameMapProvider);

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        final displayRequests = requests.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, requests.length),
            const SizedBox(height: AppSpacing.space1),
            _buildChangeStats(requests),
            const SizedBox(height: AppSpacing.space2),

            // Notebook × Score: 카드 배경 제거, 상·하단 1px 잉크 라인으로 묶음
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.inkQuaternary),
                  bottom: BorderSide(color: AppColors.inkQuaternary),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < displayRequests.length; i++) ...[
                    if (i > 0)
                      const ThinRule(),
                    _ScheduleChangeListItem(
                      event: displayRequests[i],
                      studentName:
                          studentNames[displayRequests[i].actorId] ??
                          AppStrings.student,
                      studentInfo: studentInfoMap[displayRequests[i].actorId],
                      academyName: academyNames[displayRequests[i].actorId],
                      onTap:
                          displayRequests[i].subscriptionId != null
                              ? () => context.push(
                                _subscriptionDetailRoute(displayRequests[i]),
                                extra: {'viewerRole': 'teacher'},
                              )
                              : null,
                    ),
                  ],
                ],
              ),
            ),

            if (requests.length > 3) ...[
              const SizedBox(height: AppSpacing.space2),
              Center(
                child: TextButton(
                  onPressed:
                      () => context.push(
                        '${AppRoutes.scheduleChangeRequests}?teacherId=$teacherId',
                      ),
                  child: Text(
                    AppStrings.moreSubscriptions(requests.length - 3),
                    // H6 — 버튼처럼 눌리는 텍스트 액션은 밑줄로 affordance 를 준다.
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildChangeStats(List<RequestEvent> requests) {
    final changeCount =
        requests
            .where(
              (r) =>
                  r.eventType == RequestEventType.scheduleChanged ||
                  r.eventType == RequestEventType.scheduleChangeProposed ||
                  r.eventType == RequestEventType.scheduleChangeCountered,
            )
            .length;
    final cancelCount =
        requests
            .where((r) => r.eventType == RequestEventType.lessonCancelled)
            .length;
    final completedCount =
        requests
            .where(
              (r) => r.eventType == RequestEventType.scheduleChangeAccepted,
            )
            .length;

    final parts = <String>[];
    if (changeCount > 0) {
      parts.add(
        AppStrings.phaseStatLabel(AppStrings.changeTypeLabel, changeCount),
      );
    }
    if (cancelCount > 0) {
      parts.add(
        AppStrings.phaseStatLabel(AppStrings.cancelTypeLabel, cancelCount),
      );
    }
    if (completedCount > 0) {
      parts.add(
        AppStrings.phaseStatLabel(AppStrings.tabCompleted, completedCount),
      );
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space2),
      child: Text(
        parts.join(' · '),
        style: AppTypography.bodySmall.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCount) {
    return NotebookSectionHeader(
      label: '${AppStrings.scheduleChangeRequests} · $totalCount',
      trailing:
          totalCount > 3
              ? TextButton.icon(
                onPressed:
                    () => context.push(
                      '${AppRoutes.scheduleChangeRequests}?teacherId=$teacherId',
                    ),
                icon: const Icon(
                  Icons.list,
                  size: AppSpacing.iconXS,
                  color: AppColors.ink,
                ),
                label: Text(
                  AppStrings.viewAll,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              : null,
    );
  }
}

/// Student info extracted from lesson requests for consistent display.
class _StudentInfo {
  final String instrument;
  final String level;
  final String typeLabel;
  final bool isAcademy;

  const _StudentInfo({
    required this.instrument,
    required this.level,
    required this.typeLabel,
    required this.isAcademy,
  });
}

/// Build studentId → info map from lesson requests.
Map<String, _StudentInfo> _buildStudentInfoMap(
  AsyncValue<List<UnifiedLessonRequest>> requestsAsync,
) {
  final requests = requestsAsync.valueOrNull ?? const [];
  final map = <String, _StudentInfo>{};
  for (final r in requests) {
    map.putIfAbsent(
      r.studentId,
      () => _StudentInfo(
        instrument: r.instrument,
        level: r.experience.label,
        typeLabel: r.typeDisplayLabel,
        isAcademy: r.isAcademy,
      ),
    );
  }
  return map;
}

String _subscriptionDetailRoute(RequestEvent event) {
  final route = AppRoutes.subscriptionDetail.replaceFirst(
    ':id',
    event.subscriptionId!,
  );
  if (event.sessionNumber == null) return route;
  return '$route?session=${event.sessionNumber}';
}

/// List item for schedule change requests — same layout as RequestListItem.
/// Avatar + info column + right column (status chip + elapsed time).
class _ScheduleChangeListItem extends StatelessWidget {
  final RequestEvent event;
  final String studentName;
  final _StudentInfo? studentInfo;
  final String? academyName;
  final VoidCallback? onTap;

  const _ScheduleChangeListItem({
    required this.event,
    required this.studentName,
    this.studentInfo,
    this.academyName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: _buildInfo()),
            const SizedBox(width: AppSpacing.space3),
            _buildRightColumn(),
          ],
        ),
      ),
    );
  }

  /// Avatar — unified with RequestListItem (paperAccentSoft bg + paperAccent text)
  Widget _buildAvatar() {
    final initial = studentName.isNotEmpty ? studentName[0] : '?';
    final isUrgent = DateTime.now().difference(event.createdAt).inHours >= 24;

    final avatar = CircleAvatar(
      radius: AppSpacing.avatarSmall / 2,
      backgroundColor: AppColors.paperAccentSoft,
      child: Text(
        initial,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.paperAccent,
        ),
      ),
    );

    if (!isUrgent) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.paperAccent,
              border: Border.all(color: AppColors.paper, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Info column — unified with RequestListItem (2 lines)
  /// Line 1: 김민준 · 바이올린 · 초급 (이름 · 악기 · 레벨)
  /// Line 2: 개인레슨 · 정규레슨 · 3회차 시간변경 (소속 · 타입 · 이벤트)
  Widget _buildInfo() {
    final info = studentInfo;

    // Line 1: name · instrument · level (레슨 요청과 동일)
    final line1Parts = [studentName];
    if (info != null) {
      line1Parts.add(info.instrument);
      line1Parts.add(info.level);
    }

    // Line 2: source · type · event description
    final line2Parts = <String>[];
    if (info != null) {
      final source = info.isAcademy
          ? (academyName ?? AppStrings.academy)
          : AppStrings.individualLesson;
      line2Parts.add(source);
      line2Parts.add(info.typeLabel);
    }
    line2Parts.add(_descriptionText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line1Parts.join(' · '),
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          line2Parts.join(' · '),
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Right column — unified with RequestListItem:
  /// 2색 체계 (paperAccent = 내 차례 / inkTertiary = 대기·종료)
  Widget _buildRightColumn() {
    final isCompleted =
        event.eventType == RequestEventType.scheduleChangeAccepted ||
        event.eventType == RequestEventType.scheduleChangeRejected;
    final isMyTurn = !isCompleted && event.actorType != ProposerRole.teacher;

    final color = isMyTurn ? AppColors.paperAccent : AppColors.inkTertiary;
    final label =
        isCompleted
            ? AppStrings.statusCompleted
            : isMyTurn
            ? AppStrings.actionRequired
            : AppStrings.responseWaiting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          formatRelativeTime(event.createdAt),
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  String get _descriptionText {
    final sessionText =
        event.sessionNumber != null
            ? AppStrings.sessionNumberLabel(event.sessionNumber!)
            : '';
    final isBulk = event.scheduleChangeType == ScheduleChangeType.bulkChange;

    switch (event.eventType) {
      case RequestEventType.scheduleChanged:
        return isBulk
            ? '$sessionText ${AppStrings.changeTypeBulkLabel}'
            : '$sessionText ${AppStrings.sessionChangeRequest}';
      case RequestEventType.lessonCancelled:
        return '$sessionText ${AppStrings.sessionCancelRequest}';
      case RequestEventType.scheduleChangeProposed:
        return '$sessionText ${AppStrings.rescheduleRequest}';
      case RequestEventType.scheduleChangeAccepted:
        return '$sessionText ${AppStrings.tabCompleted}';
      default:
        return '$sessionText ${AppStrings.sessionChangeRequest}';
    }
  }
}
