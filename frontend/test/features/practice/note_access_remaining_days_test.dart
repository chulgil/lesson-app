import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/note_access_request.dart';

/// Regression guard (2026-07-08 FE audit D5).
///
/// remainingDays 가 Duration.inDays(24시간 미만을 0 으로 버림)로 계산돼, 내일
/// 만료여도 "오늘까지"(0)로 하루 일찍 표시하던 버그의 가드. 캘린더 날짜 차이로
/// 계산해야 한다. fix 를 되돌리면(inDays 로 복귀) 내일 케이스가 0 이 되어 RED.
NoteAccessRequest _req(DateTime expiresAt) => NoteAccessRequest(
  id: 'r1',
  academyId: 'a1',
  academyName: '학원',
  reason: '노트 열람',
  expiresAt: expiresAt,
  status: NoteAccessStatus.consented,
  recipientUserId: 'u1',
  requestorUserId: 'u2',
  createdAt: DateTime(2026),
);

void main() {
  test('내일 만료면 remainingDays 는 1 (하루 일찍 표시 방지 — #D5)', () {
    final now = DateTime.now();
    // 내일 날짜의 이른 시각 — old(inDays)는 24h 미만이라 0, new(캘린더)는 1.
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    expect(_req(tomorrow).remainingDays, 1);
  });

  test('오늘 만료(아직 미만료)면 remainingDays 는 0 (#D5)', () {
    final now = DateTime.now();
    final laterToday = DateTime(now.year, now.month, now.day, 23, 59);
    // 23:59 가 이미 지난 심야에 돌면 만료 → 그때도 0 이므로 불변.
    expect(_req(laterToday).remainingDays, 0);
  });
}
