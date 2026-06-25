import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/presentation/screens/booking_cancel_screen.dart';

/// #523·#525: BookingCancelScreen 이 CancellationCreditPolicy(스펙 SSOT)를 따르는지.
/// - 마감 전: 변경권 0이어도 취소 가능(무료)  → 기존 버그(remaining>0 게이트)가 막던 것
/// - 마감 후 + 잔여 0: 차단(취소 불가)
/// - 마감 후 + 잔여>0: 가능(1회 차감)
///
/// 타이밍 결정성: 레슨은 항상 now+2일. deadlineHours 로 마감 전/후를 뒤집는다
/// (12h → deadline 미래=마감 전 / 100h → deadline 과거=마감 후). 벽시계 무관.
void main() {
  Future<void> pumpCancel(
    WidgetTester tester, {
    required int remaining,
    required int total,
    required int deadlineHours,
  }) async {
    final now = DateTime.now();
    final lessonDay = now.add(const Duration(days: 2));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: BookingCancelScreen(
            bookingId: 'b1',
            teacherName: '선생님',
            teacherId: 't1',
            studentId: 's1',
            subscriptionId: 'sub1',
            bookingDate: lessonDay,
            startTime: TimeOfDay(hour: now.hour, minute: now.minute),
            remainingReschedules: remaining,
            totalReschedules: total,
            cancelDeadlineHours: deadlineHours,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  VoidCallback? cancelButtonOnPressed(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed;

  testWidgets('마감 전 + 변경권 0 → 취소 버튼 활성 (무료 취소 허용)', (tester) async {
    await pumpCancel(tester, remaining: 0, total: 2, deadlineHours: 12);
    expect(cancelButtonOnPressed(tester), isNotNull);
  });

  testWidgets('마감 후 + 변경권 0 → 취소 버튼 비활성 (차단)', (tester) async {
    await pumpCancel(tester, remaining: 0, total: 2, deadlineHours: 100);
    expect(cancelButtonOnPressed(tester), isNull);
  });

  testWidgets('마감 후 + 변경권 2 → 취소 버튼 활성 (1회 차감)', (tester) async {
    await pumpCancel(tester, remaining: 2, total: 2, deadlineHours: 100);
    expect(cancelButtonOnPressed(tester), isNotNull);
  });
}
