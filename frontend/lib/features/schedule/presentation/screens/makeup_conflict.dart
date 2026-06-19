import '../../../academy/domain/entities/bulk_closure.dart';

/// #768 ③ — 입력 중인 보강 일정끼리 시간이 겹치는 레슨을 찾는다.
///
/// 한 강사는 같은 시간대에 두 건의 보강을 진행할 수 없으므로, 입력된 보강
/// draft 들의 [start, start+레슨길이) 윈도우가 서로 교차하면 양쪽 모두 충돌로
/// 표시한다. 레슨 길이는 원 레슨의 `originalEndAt - originalStartAt` 를 쓰고,
/// 0 이하면 30분으로 폴백한다.
///
/// 순수 함수(Flutter 의존 없음) — 단위 테스트 대상.
Set<String> detectMakeupConflicts(
  List<AffectedLesson> lessons,
  Map<String, DateTime?> drafts,
) {
  const fallback = Duration(minutes: 30);
  final byId = {for (final l in lessons) l.lessonId: l};

  final windows = <({String id, DateTime start, DateTime end})>[];
  for (final entry in drafts.entries) {
    final at = entry.value;
    final lesson = byId[entry.key];
    if (at == null || lesson == null) continue;
    var dur = lesson.originalEndAt.difference(lesson.originalStartAt);
    if (dur <= Duration.zero) dur = fallback;
    windows.add((id: entry.key, start: at, end: at.add(dur)));
  }

  final conflicts = <String>{};
  for (var i = 0; i < windows.length; i++) {
    for (var j = i + 1; j < windows.length; j++) {
      final a = windows[i];
      final b = windows[j];
      // 교차: a 시작이 b 끝보다 이르고, b 시작이 a 끝보다 이를 때.
      // 끝=다음 시작(인접)은 교차 아님.
      if (a.start.isBefore(b.end) && b.start.isBefore(a.end)) {
        conflicts.add(a.id);
        conflicts.add(b.id);
      }
    }
  }
  return conflicts;
}
