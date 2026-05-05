import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/schedule_facade.dart';
import '../../../students/students_facade.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';

enum ScheduleChangeRequestStatus { needsResponse, waitingResponse, completed }

ScheduleChangeRequestStatus scheduleChangeRequestStatus(
  RequestEvent event, {
  required String viewerRole,
}) {
  if (event.eventType == RequestEventType.scheduleChangeAccepted ||
      event.eventType == RequestEventType.scheduleChangeRejected) {
    return ScheduleChangeRequestStatus.completed;
  }

  final viewerIsTeacher = viewerRole == 'teacher';
  final viewerActor =
      viewerIsTeacher ? ProposerRole.teacher : ProposerRole.student;
  if (event.actorType == viewerActor) {
    return ScheduleChangeRequestStatus.waitingResponse;
  }
  return ScheduleChangeRequestStatus.needsResponse;
}

String scheduleChangeRequestStudentName(
  RequestEvent event, {
  required Map<String, Subscription> subscriptionsById,
  required Map<String, String> studentNames,
}) {
  final subscription = subscriptionsById[event.subscriptionId];
  final studentId =
      subscription?.studentId ??
      (event.actorType == ProposerRole.student ? event.actorId : null);
  if (studentId == null) return AppStrings.student;
  return studentNames[studentId] ?? AppStrings.student;
}

/// Schedule change request list with tab filtering (pending / completed / all).
class ScheduleChangeRequestListScreen extends ConsumerStatefulWidget {
  final String teacherId;

  const ScheduleChangeRequestListScreen({super.key, required this.teacherId});

  @override
  ConsumerState<ScheduleChangeRequestListScreen> createState() =>
      _ScheduleChangeRequestListScreenState();
}

class _ScheduleChangeRequestListScreenState
    extends ConsumerState<ScheduleChangeRequestListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _rangeDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(
      pendingScheduleChangeRequestsProvider(widget.teacherId),
    );
    final subscriptionsAsync = ref.watch(
      teacherStudentSubscriptionsProvider(widget.teacherId),
    );
    final studentNames = ref.watch(studentNameMapProvider);

    return NotebookScreenScaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        title: const Text(AppStrings.scheduleChangeRequestTitle),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => Center(
              child: Text(
                AppStrings.errorOccurred,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ),
        data:
            (allRequests) => _buildContent(
              allRequests,
              subscriptionsById: {
                for (final subscription in subscriptionsAsync.maybeWhen(
                  data: (subscriptions) => subscriptions,
                  orElse: () => const <Subscription>[],
                ))
                  subscription.id: subscription,
              },
              studentNames: studentNames,
            ),
      ),
    );
  }

  Widget _buildContent(
    List<RequestEvent> allRequests, {
    required Map<String, Subscription> subscriptionsById,
    required Map<String, String> studentNames,
  }) {
    final now = DateTime.now();
    final filteredRequests =
        allRequests
            .where(
              (event) => now.difference(event.createdAt).inDays <= _rangeDays,
            )
            .toList();
    final pending =
        filteredRequests
            .where(
              (e) =>
                  scheduleChangeRequestStatus(e, viewerRole: 'teacher') !=
                  ScheduleChangeRequestStatus.completed,
            )
            .toList();
    final completed =
        filteredRequests
            .where(
              (e) =>
                  scheduleChangeRequestStatus(e, viewerRole: 'teacher') ==
                  ScheduleChangeRequestStatus.completed,
            )
            .toList();

    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          decoration: const BoxDecoration(color: AppColors.paperDark),
          child: TabBar(
            controller: _tabController,
            indicator: const BoxDecoration(color: AppColors.paperAccent),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.paper,
            unselectedLabelColor: AppColors.inkSecondary,
            labelStyle: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTypography.bodySmall,
            dividerHeight: 0,
            tabs: [
              Tab(text: '${AppStrings.tabPending}(${pending.length})'),
              Tab(text: '${AppStrings.tabCompleted}(${completed.length})'),
              Tab(text: '${AppStrings.tabAll}(${allRequests.length})'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        _buildRangeFilter(),
        const SizedBox(height: AppSpacing.space3),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(
                pending,
                subscriptionsById: subscriptionsById,
                studentNames: studentNames,
              ),
              _buildRequestList(
                completed,
                subscriptionsById: subscriptionsById,
                studentNames: studentNames,
              ),
              _buildRequestList(
                filteredRequests,
                subscriptionsById: subscriptionsById,
                studentNames: studentNames,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRangeFilter() {
    const ranges = [
      (label: AppStrings.rangeOneWeek, days: 7),
      (label: AppStrings.rangeOneMonth, days: 31),
      (label: AppStrings.rangeThreeMonths, days: 93),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children:
            ranges.map((range) {
              final isSelected = _rangeDays == range.days;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => setState(() => _rangeDays = range.days),
                    child: Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.paperAccent
                                : AppColors.paper,
                        border: Border.all(color: AppColors.inkQuaternary),
                      ),
                      child: Text(
                        range.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: isSelected ? AppColors.paper : AppColors.ink,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildRequestList(
    List<RequestEvent> requests, {
    required Map<String, Subscription> subscriptionsById,
    required Map<String, String> studentNames,
  }) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 48,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              AppStrings.noChangeRequests,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.space2),
      itemBuilder:
          (context, index) => _buildRequestItem(
            requests[index],
            subscriptionsById: subscriptionsById,
            studentNames: studentNames,
          ),
    );
  }

  Widget _buildRequestItem(
    RequestEvent event, {
    required Map<String, Subscription> subscriptionsById,
    required Map<String, String> studentNames,
  }) {
    final status = scheduleChangeRequestStatus(event, viewerRole: 'teacher');
    final studentName = scheduleChangeRequestStudentName(
      event,
      subscriptionsById: subscriptionsById,
      studentNames: studentNames,
    );

    // Resolve class context: subscription → membership → lessonClass
    final subscription = subscriptionsById[event.subscriptionId];
    final membershipId = subscription?.membershipId;

    return Consumer(
      builder: (context, ref, _) {
        // Lazy-watch membership + lessonClass per item
        String? classLabel;
        String? instrument;
        if (membershipId != null) {
          final membershipAsync = ref.watch(membershipProvider(membershipId));
          final membership = membershipAsync.valueOrNull;
          if (membership != null) {
            instrument = membership.instrument;
            final classAsync = ref.watch(
              lessonClassProvider(membership.lessonClassId),
            );
            final lessonClass = classAsync.valueOrNull;
            if (lessonClass != null) {
              classLabel =
                  lessonClass.type == LessonClassType.academy
                      ? lessonClass.name
                      : AppStrings.individualLesson;
            }
          }
        }

        // Subscription type label
        final typeLabel = subscription?.typeLabel ?? '';

        return GestureDetector(
          onTap: () {
            if (event.subscriptionId != null) {
              context.push(
                '${AppRoutes.subscriptionDetail.replaceFirst(':id', event.subscriptionId!)}?session=${event.sessionNumber ?? 1}',
                extra: {'viewerRole': 'teacher'},
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkQuaternary),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: AppSpacing.avatarSmall / 2,
                  backgroundColor: AppColors.paperAccentSoft,
                  child: Text(
                    studentName.isNotEmpty ? studentName[0] : '?',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.paperAccent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Info: 2 lines
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: name · instrument
                      Text(
                        [
                          studentName,
                          instrument,
                        ].where((s) => s != null && s.isNotEmpty).join(' · '),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.space1),

                      // Line 2: classLabel · typeLabel
                      Text(
                        [
                          classLabel,
                          typeLabel,
                        ].where((s) => s != null && s.isNotEmpty).join(' · '),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),

                // Right: status badge + elapsed time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(status),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      formatRelativeTime(event.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ScheduleChangeRequestStatus status) {
    // Unified 2-color scheme: paperAccent (my turn) / inkTertiary (wait/done)
    final color =
        status == ScheduleChangeRequestStatus.needsResponse
            ? AppColors.paperAccent
            : AppColors.inkTertiary;
    final label = switch (status) {
      ScheduleChangeRequestStatus.needsResponse => AppStrings.actionRequired,
      ScheduleChangeRequestStatus.waitingResponse => AppStrings.responseWaiting,
      ScheduleChangeRequestStatus.completed => AppStrings.statusCompleted,
    };

    return Container(
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
    );
  }
}
