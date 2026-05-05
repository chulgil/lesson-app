import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../providers/subscription_providers.dart';
import '../../../schedule/domain/entities/request_event.dart';
import 'schedule_change_event_bubble.dart';

/// Scrollable chat-style list showing per-session schedule change events.
///
/// Each session has a collapsed/expanded header.
/// Past sessions are collapsed by default; selected session is expanded.
/// Shows only schedule change history (no subscription issued card).
class SubscriptionDetailChatList extends ConsumerStatefulWidget {
  final Subscription subscription;
  final int selectedSession;
  final String? instrument;
  final String viewerRole;
  final String? studentName;
  final String? teacherName;
  final VoidCallback? onOpponentAvatarTap;

  const SubscriptionDetailChatList({
    super.key,
    required this.subscription,
    required this.selectedSession,
    this.instrument,
    this.viewerRole = 'student',
    this.studentName,
    this.teacherName,
    this.onOpponentAvatarTap,
  });

  @override
  ConsumerState<SubscriptionDetailChatList> createState() =>
      _SubscriptionDetailChatListState();
}

class _SubscriptionDetailChatListState
    extends ConsumerState<SubscriptionDetailChatList> {
  final Map<int, GlobalKey> _sessionKeys = {};
  final Set<int> _expandedSessions = {};

  Subscription get subscription => widget.subscription;

  @override
  void initState() {
    super.initState();
    _expandedSessions.add(widget.selectedSession);
  }

  @override
  void didUpdateWidget(covariant SubscriptionDetailChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSession != widget.selectedSession) {
      _expandedSessions.add(widget.selectedSession);
      _scrollToSession(widget.selectedSession);
    }
  }

  void _scrollToSession(int sessionNumber) {
    final key = _sessionKeys[sessionNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  GlobalKey _keyForSession(int sessionNumber) {
    return _sessionKeys.putIfAbsent(sessionNumber, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final usageHistoryAsync = ref.watch(
      subscriptionUsageHistoryProvider(subscription.id),
    );

    return usageHistoryAsync.when(
      data: (usages) => _buildSessionListView(usages),
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (_, __) => Center(
            child: Text(
              AppStrings.noLessonRecords,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ),
    );
  }

  Widget _buildSessionListView(List<SubscriptionUsage> usages) {
    final total = subscription.totalLessonsForDisplay ?? 0;
    if (total == 0) return _buildEmptyState();

    final completedUsages =
        usages.where((u) => u.usageType == UsageType.normal).toList();
    final completedCount = completedUsages.length;

    // Show the current session, but keep a deep-linked schedule-change session
    // visible so list → detail navigation never opens on an empty history row.
    final nextSession = completedCount + 1;
    final requestedSession =
        widget.selectedSession > nextSession
            ? widget.selectedSession
            : nextSession;
    final visibleCount = requestedSession.clamp(1, total);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      itemCount: visibleCount,
      itemBuilder: (context, index) {
        final sessionNumber = index + 1;
        final isCompleted = sessionNumber <= completedCount;
        final isSelected = sessionNumber == widget.selectedSession;
        final isExpanded = _expandedSessions.contains(sessionNumber);

        // Find usage data for completed sessions
        final usage = isCompleted ? completedUsages[index] : null;

        return _SessionSection(
          key: _keyForSession(sessionNumber),
          subscription: subscription,
          sessionNumber: sessionNumber,
          isCompleted: isCompleted,
          isSelected: isSelected,
          isExpanded: isExpanded,
          usage: usage,
          instrument: widget.instrument,
          viewerRole: widget.viewerRole,
          studentName: widget.studentName,
          teacherName: widget.teacherName,
          onOpponentAvatarTap: widget.onOpponentAvatarTap,
          onToggle: () {
            setState(() {
              if (_expandedSessions.contains(sessionNumber)) {
                _expandedSessions.remove(sessionNumber);
              } else {
                _expandedSessions.add(sessionNumber);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 40, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space2),
          Text(
            AppStrings.noLessonRecords,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single session section: header (always visible) + expandable content.
class _SessionSection extends ConsumerWidget {
  final Subscription subscription;
  final int sessionNumber;
  final bool isCompleted;
  final bool isSelected;
  final bool isExpanded;
  final SubscriptionUsage? usage;
  final String? instrument;
  final String viewerRole;
  final String? studentName;
  final String? teacherName;
  final VoidCallback onToggle;
  final VoidCallback? onOpponentAvatarTap;

  const _SessionSection({
    super.key,
    required this.subscription,
    required this.sessionNumber,
    required this.isCompleted,
    required this.isSelected,
    required this.isExpanded,
    this.usage,
    this.instrument,
    required this.viewerRole,
    this.studentName,
    this.teacherName,
    required this.onToggle,
    this.onOpponentAvatarTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSessionHeader(context),
        if (isExpanded) _buildExpandedContent(ref),
      ],
    );
  }

  Widget _buildSessionHeader(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            // Divider line
            Expanded(
              child: Container(
                height: 1,
                color:
                    isSelected
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
              ),
            ),
            // Session label
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
              ),
              child: Text(
                _headerLabel,
                style: AppTypography.caption.copyWith(
                  color:
                      isSelected
                          ? AppColors.paperAccent
                          : AppColors.inkTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // Divider line
            Expanded(
              child: Container(
                height: 1,
                color:
                    isSelected
                        ? AppColors.paperAccent
                        : AppColors.inkQuaternary,
              ),
            ),
            // Expand/collapse icon
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  String get _headerLabel {
    if (isCompleted && usage?.usedAt != null) {
      return AppStrings.sessionCollapsedCompleted(
        sessionNumber,
        formatDateTimeMDHM(usage!.usedAt),
      );
    }
    if (isSelected) {
      // Current/next session with scheduled time
      return AppStrings.sessionCollapsedScheduled(
        sessionNumber,
        formatDateMDWithDay(DateTime.now()),
      );
    }
    return AppStrings.sessionCollapsedFuture(sessionNumber);
  }

  Widget _buildExpandedContent(WidgetRef ref) {
    final eventsAsync = ref.watch(
      subscriptionSessionEventsProvider(
        subscriptionId: subscription.id,
        sessionNumber: sessionNumber,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Schedule change events for this session
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) return _buildNoEvents();
              return _buildEventBubbles(events);
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.space2),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            error: (_, __) => _buildNoEvents(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEvents() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(color: AppColors.paperDark),
      child: Text(
        AppStrings.noChangeHistory,
        style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
      ),
    );
  }

  /// Render events as chat bubbles: student left, teacher right.
  /// Schedule change events show change type label + proposed slot info,
  /// matching RequestHistoryChat's slot display pattern.
  Widget _buildEventBubbles(List<RequestEvent> events) {
    return Column(
      children:
          events.asMap().entries.map<Widget>((entry) {
            final event = entry.value;
            final remainingCredits =
                subscription.totalRescheduleAllowance -
                subscription.usedRescheduleCount -
                1;

            return ScheduleChangeEventBubble(
              event: event,
              viewerRole: viewerRole,
              studentName: studentName,
              teacherName: teacherName,
              previousEvents: events.take(entry.key).toList(),
              rescheduleCreditsUsed: 1,
              rescheduleCreditsRemaining:
                  remainingCredits < 0 ? null : remainingCredits,
              onOpponentAvatarTap: onOpponentAvatarTap,
            );
          }).toList(),
    );
  }
}
