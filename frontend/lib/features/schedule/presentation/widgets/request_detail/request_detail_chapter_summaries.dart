import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/widgets/chapter_summary.dart';
import '../../../domain/entities/request_event.dart';
import '../../../domain/entities/unified_lesson_request.dart';
import '../../extensions/unified_lesson_request_visuals.dart';
import '../request_history_chat.dart';

/// Builds collapsed chapter summaries for completed phases of a
/// [RequestDetailScreen] (Phase 1 request, Phase 2 subscription, Phase 3
/// lessons). [requestPhaseEvents] is the pre-filtered event list for
/// [RequestPhase.request] (needed only when that chapter is expanded).
List<Widget> buildRequestDetailChapterSummaries({
  required UnifiedLessonRequest request,
  required List<RequestEvent> events,
  required String viewerRole,
  required List<RequestEvent> requestPhaseEvents,
  required Set<RequestPhase> expandedChapters,
  required void Function(RequestPhase phase) onToggleChapter,
}) {
  final phase = request.currentPhase;
  final chapters = <Widget>[];

  // Phase 1: 레슨 신청 — show as collapsed if past Phase 1
  if (phase != RequestPhase.request && phase != RequestPhase.terminal) {
    final isExpanded = expandedChapters.contains(RequestPhase.request);
    chapters.add(
      ChapterSummary(
        icon: Icons.send,
        title: AppStrings.chapterRequest,
        completedDate: _phaseCompletedDate(request, RequestPhase.request),
        summary: _phaseSummary(request, events, RequestPhase.request),
        isExpanded: isExpanded,
        onTap: () => onToggleChapter(RequestPhase.request),
        child:
            isExpanded
                ? RequestHistoryChat(
                  events: requestPhaseEvents,
                  request: request,
                  shrinkWrap: true,
                  showGuide: false,
                  viewerId:
                      viewerRole == 'teacher'
                          ? request.teacherId
                          : request.studentId,
                  studentName: '',
                )
                : null,
      ),
    );
  }

  // Phase 2: 수강권 & 입금 — show if past Phase 2
  if (_isPhaseCompleted(phase, RequestPhase.subscription)) {
    final isExpanded = expandedChapters.contains(RequestPhase.subscription);
    chapters.add(
      ChapterSummary(
        icon: Icons.credit_card,
        title: AppStrings.chapterSubscription,
        completedDate: _phaseCompletedDate(request, RequestPhase.subscription),
        summary: _phaseSummary(request, events, RequestPhase.subscription),
        isExpanded: isExpanded,
        onTap: () => onToggleChapter(RequestPhase.subscription),
      ),
    );
  }

  // Phase 3: 레슨 진행 — show as active header if current
  if (phase == RequestPhase.lessons || phase == RequestPhase.completed) {
    final isActive = phase == RequestPhase.lessons;
    chapters.add(
      ChapterSummary(
        icon: Icons.music_note,
        title: AppStrings.chapterLessons,
        isActive: isActive,
        summary:
            isActive
                ? null
                : _phaseSummary(request, events, RequestPhase.lessons),
        completedDate:
            isActive
                ? null
                : _phaseCompletedDate(request, RequestPhase.lessons),
      ),
    );
  }

  return chapters;
}

/// Whether a phase is fully completed (current phase is past it).
bool _isPhaseCompleted(RequestPhase current, RequestPhase target) {
  const order = [
    RequestPhase.request,
    RequestPhase.subscription,
    RequestPhase.lessons,
    RequestPhase.completed,
  ];
  final currentIdx = order.indexOf(current);
  final targetIdx = order.indexOf(target);
  if (currentIdx == -1 || targetIdx == -1) return false;
  return currentIdx > targetIdx;
}

/// Get a display date for when a phase was completed.
String? _phaseCompletedDate(UnifiedLessonRequest request, RequestPhase phase) {
  if (phase == RequestPhase.request && request.confirmedAt != null) {
    final d = request.confirmedAt!;
    return '${d.month}/${d.day}';
  }
  return null;
}

/// Generate a one-line summary for a collapsed chapter.
String? _phaseSummary(
  UnifiedLessonRequest request,
  List<RequestEvent> events,
  RequestPhase phase,
) {
  switch (phase) {
    case RequestPhase.request:
      return request.typeDisplayLabel;
    case RequestPhase.subscription:
      return AppStrings.subscription;
    case RequestPhase.lessons:
      final completedCount =
          events
              .where((e) => e.eventType == RequestEventType.lessonCompleted)
              .length;
      if (completedCount > 0) return '$completedCount회 완료';
      return null;
    case RequestPhase.completed:
    case RequestPhase.terminal:
      return null;
  }
}
