import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../providers/subscription_providers.dart';

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

    return Scaffold(
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
        data: (allRequests) => _buildContent(allRequests),
      ),
    );
  }

  Widget _buildContent(List<RequestEvent> allRequests) {
    final pending = allRequests.where((e) => _isPending(e.eventType)).toList();
    final completed =
        allRequests.where((e) => !_isPending(e.eventType)).toList();

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

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(pending),
              _buildRequestList(completed),
              _buildRequestList(allRequests),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList(List<RequestEvent> requests) {
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
      itemBuilder: (context, index) => _buildRequestItem(requests[index]),
    );
  }

  Widget _buildRequestItem(RequestEvent event) {
    final isPending = _isPending(event.eventType);
    final changeTypeLabel = _changeTypeLabel(event.eventType);
    final sessionLabel =
        event.sessionNumber != null
            ? AppStrings.sessionNumberLabel(event.sessionNumber!)
            : '';

    return GestureDetector(
      onTap: () {
        if (event.subscriptionId != null) {
          context.push(
            AppRoutes.subscriptionDetail.replaceFirst(
              ':id',
              event.subscriptionId!,
            ),
            extra: {'viewerRole': 'teacher'},
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top line: session + change type
            Row(
              children: [
                if (sessionLabel.isNotEmpty) ...[
                  Text(
                    sessionLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space1),
                ],
                Text(
                  changeTypeLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),

            // Bottom line: relative time + status badge
            Row(
              children: [
                Text(
                  formatRelativeTime(event.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(isPending),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isPending) {
    final color = isPending ? AppColors.ink : AppColors.paperOk;
    final label = isPending ? AppStrings.tabPending : AppStrings.tabCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Determine if an event type represents a pending (unresolved) change request.
  bool _isPending(RequestEventType type) {
    return type == RequestEventType.scheduleChangeProposed;
  }

  /// Get display label for the change request type.
  String _changeTypeLabel(RequestEventType type) {
    switch (type) {
      case RequestEventType.scheduleChangeProposed:
        return AppStrings.sessionChangeRequest;
      case RequestEventType.scheduleChangeAccepted:
        return AppStrings.scheduleChangeAccept;
      case RequestEventType.scheduleChangeRejected:
        return AppStrings.scheduleChangeReject;
      case RequestEventType.scheduleChangeCountered:
        return AppStrings.scheduleChangeCounter;
      default:
        return AppStrings.sessionChangeRequest;
    }
  }
}
