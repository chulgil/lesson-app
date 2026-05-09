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
import '../utils/subscription_status_colors.dart';

/// Chapter 3: Lesson progress — per-session expandable list with chat events.
///
/// 3-session view: previous (completed) + current (expanded) + next (upcoming).
/// Remaining sessions collapse into a "더보기" row.
class SubscriptionChapterLessons extends ConsumerStatefulWidget {
  final Subscription subscription;

  const SubscriptionChapterLessons({super.key, required this.subscription});

  @override
  ConsumerState<SubscriptionChapterLessons> createState() =>
      _SubscriptionChapterLessonsState();
}

class _SubscriptionChapterLessonsState
    extends ConsumerState<SubscriptionChapterLessons> {
  /// Index of the currently expanded session (null = none).
  int? _expandedSessionIndex;

  /// Whether the collapsed "더보기" section is expanded.
  bool _showAllSessions = false;

  @override
  Widget build(BuildContext context) {
    final usageHistoryAsync = ref.watch(
      subscriptionUsageHistoryProvider(widget.subscription.id),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSummary(),
          const SizedBox(height: AppSpacing.space3),
          _buildGuideMessage(),
          const SizedBox(height: AppSpacing.space3),
          usageHistoryAsync.when(
            data: (usages) => _buildSessionList(usages),
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.space4),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error: (_, __) => _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Progress Summary
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProgressSummary() {
    final remaining = widget.subscription.remainingLessons ?? 0;
    final total = widget.subscription.totalLessonsForDisplay ?? 0;
    final used = widget.subscription.usedLessons;
    final statusColor = SubscriptionStatusColors.getColor(widget.subscription);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.08)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.usageProgress(used, total),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              Text(
                AppStrings.remainingCount(remaining),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            child: LinearProgressIndicator(
              value: total > 0 ? used / total : 0,
              minHeight: 8,
              backgroundColor: AppColors.inkQuaternary,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Guide Message
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGuideMessage() {
    final isPackage = widget.subscription.type == SubscriptionType.package;
    final message =
        isPackage
            ? AppStrings.packageGuideMessage
            : AppStrings.monthlyGuideMessage;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.06)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Session List
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionList(List<SubscriptionUsage> usages) {
    final total = widget.subscription.totalLessonsForDisplay ?? 0;
    if (total == 0) return _buildEmptyState();

    final isPackage = widget.subscription.type == SubscriptionType.package;
    final completedUsages =
        usages.where((u) => u.usageType == UsageType.normal).toList();
    final completedCount = completedUsages.length;

    // Build all session models
    final sessions = _buildSessionModels(
      total: total,
      completedUsages: completedUsages,
      completedCount: completedCount,
      isPackage: isPackage,
    );

    // Determine the "current" session index (first non-completed)
    final currentIndex = sessions.indexWhere(
      (s) => s.status != _SessionStatus.completed,
    );
    final effectiveCurrentIndex = currentIndex >= 0 ? currentIndex : 0;

    // Auto-expand current session on first build
    _expandedSessionIndex ??= effectiveCurrentIndex;

    // 3-session window: previous, current, next
    final windowSessions = _getWindowSessions(
      sessions: sessions,
      currentIndex: effectiveCurrentIndex,
    );

    // Remaining sessions outside the window
    final remainingSessions = _getRemainingSessions(
      sessions: sessions,
      windowSessions: windowSessions,
    );

    return Column(
      children: [
        // 3-session window
        for (final session in windowSessions)
          _buildSessionTile(
            session: session,
            isLast: session == windowSessions.last && remainingSessions.isEmpty,
          ),

        // Collapsed remaining sessions
        if (remainingSessions.isNotEmpty && !_showAllSessions)
          _buildMoreSessionsRow(remainingSessions),

        // Expanded remaining sessions
        if (remainingSessions.isNotEmpty && _showAllSessions)
          for (final session in remainingSessions)
            _buildSessionTile(
              session: session,
              isLast: session == remainingSessions.last,
            ),
      ],
    );
  }

  List<_SessionModel> _buildSessionModels({
    required int total,
    required List<SubscriptionUsage> completedUsages,
    required int completedCount,
    required bool isPackage,
  }) {
    final sessions = <_SessionModel>[];

    // Completed sessions
    for (int i = 0; i < completedCount; i++) {
      final usage = completedUsages[i];
      sessions.add(
        _SessionModel(
          sessionNumber: i + 1,
          status: _SessionStatus.completed,
          dateTime: usage.usedAt,
          teacherName: usage.teacherName,
          usage: usage,
        ),
      );
    }

    if (isPackage) {
      // Package: next session = "예약 필요"
      if (completedCount < total) {
        sessions.add(
          _SessionModel(
            sessionNumber: completedCount + 1,
            status: _SessionStatus.bookingRequired,
          ),
        );
      }
      // Remaining package sessions (no date, just placeholders)
      for (int i = completedCount + 1; i < total; i++) {
        sessions.add(
          _SessionModel(sessionNumber: i + 1, status: _SessionStatus.pending),
        );
      }
    } else {
      // Monthly: all remaining sessions are scheduled
      for (int i = completedCount; i < total; i++) {
        sessions.add(
          _SessionModel(
            sessionNumber: i + 1,
            status:
                i == completedCount
                    ? _SessionStatus.scheduled
                    : _SessionStatus.upcoming,
          ),
        );
      }
    }

    return sessions;
  }

  /// Get the 3-session window around current.
  List<_SessionModel> _getWindowSessions({
    required List<_SessionModel> sessions,
    required int currentIndex,
  }) {
    final indices = <int>{};

    // Previous (completed before current)
    if (currentIndex > 0) {
      indices.add(currentIndex - 1);
    }
    // Current
    indices.add(currentIndex);
    // Next
    if (currentIndex + 1 < sessions.length) {
      indices.add(currentIndex + 1);
    }

    return indices.map((i) => sessions[i]).toList();
  }

  /// Sessions not in the 3-session window.
  List<_SessionModel> _getRemainingSessions({
    required List<_SessionModel> sessions,
    required List<_SessionModel> windowSessions,
  }) {
    final windowNumbers = windowSessions.map((s) => s.sessionNumber).toSet();
    return sessions
        .where((s) => !windowNumbers.contains(s.sessionNumber))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // Session Tile
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionTile({
    required _SessionModel session,
    bool isLast = false,
  }) {
    final isExpanded = _expandedSessionIndex == session.sessionNumber - 1;

    return Column(
      children: [
        _buildSessionRow(
          session: session,
          isExpanded: isExpanded,
          isLast: isLast && !isExpanded,
        ),
        if (isExpanded)
          _buildSessionEventArea(session: session, isLast: isLast),
      ],
    );
  }

  Widget _buildSessionRow({
    required _SessionModel session,
    required bool isExpanded,
    required bool isLast,
  }) {
    final icon = _iconForStatus(session.status);
    final iconColor = _iconColorForStatus(session.status);
    final isCurrent =
        session.status == _SessionStatus.scheduled ||
        session.status == _SessionStatus.bookingRequired;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedSessionIndex == session.sessionNumber - 1) {
            _expandedSessionIndex = null;
          } else {
            _expandedSessionIndex = session.sessionNumber - 1;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(icon, size: 20, color: iconColor),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.inkQuaternary,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.space2),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: isCurrent ? AppSpacing.space2 : 4,
              ),
              decoration:
                  isCurrent
                      ? BoxDecoration(
                        color: AppColors.paperAccentSoft,
                        border: Border.all(color: AppColors.paperAccent),
                      )
                      : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleForSession(session),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: _titleColorForStatus(session.status),
                          ),
                        ),
                        if (session.teacherName != null &&
                            session.dateTime != null)
                          Text(
                            '${formatTimeHM(session.dateTime!)} · ${session.teacherName}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.inkTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Session Event Area (expandable chat)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSessionEventArea({
    required _SessionModel session,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: AppSpacing.space3),
      child: Consumer(
        builder: (context, ref, _) {
          final eventsAsync = ref.watch(
            subscriptionSessionEventsProvider(
              subscriptionId: widget.subscription.id,
              sessionNumber: session.sessionNumber,
            ),
          );

          return eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildEmptyEventArea();
              }
              return _buildEventBubbles(events);
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.space2),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            error: (_, __) => _buildEmptyEventArea(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyEventArea() {
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
  Widget _buildEventBubbles(List<dynamic> events) {
    return Column(
      children:
          events.map<Widget>((event) {
            // Chat bubble rendering — follows RequestHistoryChat pattern.
            // actorType determines alignment: student=left, teacher=right.
            final isTeacher = event.actorType?.name == 'teacher';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space2),
              child: Align(
                alignment:
                    isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color:
                        isTeacher
                            ? AppColors.paperAccentSoft
                            : AppColors.paperDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppSpacing.radiusLarge),
                      topRight: const Radius.circular(AppSpacing.radiusLarge),
                      bottomLeft: Radius.circular(
                        isTeacher ? AppSpacing.radiusLarge : 4,
                      ),
                      bottomRight: Radius.circular(
                        isTeacher ? 4 : AppSpacing.radiusLarge,
                      ),
                    ),
                  ),
                  child: Text(
                    event.message ?? event.chatDisplayMessage ?? '',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // More Sessions Row
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMoreSessionsRow(List<_SessionModel> remaining) {
    final first = remaining.first.sessionNumber;
    final last = remaining.last.sessionNumber;

    return GestureDetector(
      onTap: () => setState(() => _showAllSessions = true),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              '${AppStrings.moreSessionsLabel(first, last)} (${AppStrings.showMore})',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Empty State
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════

  String _titleForSession(_SessionModel session) {
    switch (session.status) {
      case _SessionStatus.completed:
        final dateLabel =
            session.dateTime != null
                ? formatDateMDWithDay(session.dateTime!)
                : '';
        return AppStrings.sessionCompleted(session.sessionNumber, dateLabel);
      case _SessionStatus.scheduled:
        return AppStrings.sessionScheduled(session.sessionNumber);
      case _SessionStatus.upcoming:
        return AppStrings.sessionPending(session.sessionNumber);
      case _SessionStatus.bookingRequired:
        return AppStrings.sessionBookingRequired(session.sessionNumber);
      case _SessionStatus.pending:
        return AppStrings.sessionPending(session.sessionNumber);
    }
  }

  IconData _iconForStatus(_SessionStatus status) {
    switch (status) {
      case _SessionStatus.completed:
        return Icons.check_circle;
      case _SessionStatus.scheduled:
      case _SessionStatus.bookingRequired:
        return Icons.schedule;
      case _SessionStatus.upcoming:
      case _SessionStatus.pending:
        return Icons.radio_button_unchecked;
    }
  }

  Color _iconColorForStatus(_SessionStatus status) {
    switch (status) {
      case _SessionStatus.completed:
        return AppColors.paperOk;
      case _SessionStatus.scheduled:
      case _SessionStatus.bookingRequired:
        return AppColors.paperAccent;
      case _SessionStatus.upcoming:
      case _SessionStatus.pending:
        return AppColors.inkTertiary;
    }
  }

  Color _titleColorForStatus(_SessionStatus status) {
    switch (status) {
      case _SessionStatus.completed:
      case _SessionStatus.scheduled:
      case _SessionStatus.bookingRequired:
        return AppColors.ink;
      case _SessionStatus.upcoming:
      case _SessionStatus.pending:
        return AppColors.inkTertiary;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Internal Models
// ═══════════════════════════════════════════════════════════════

enum _SessionStatus { completed, scheduled, upcoming, bookingRequired, pending }

class _SessionModel {
  final int sessionNumber;
  final _SessionStatus status;
  final DateTime? dateTime;
  final String? teacherName;
  final SubscriptionUsage? usage;

  const _SessionModel({
    required this.sessionNumber,
    required this.status,
    this.dateTime,
    this.teacherName,
    this.usage,
  });
}
