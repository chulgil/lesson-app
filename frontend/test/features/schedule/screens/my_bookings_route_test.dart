import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/repositories/teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/teacher_availability_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/my_bookings_screen.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

/// 변경 슬롯/가용시간을 즉시 반환해 mock repo 의 Future.delayed Timer 를 없앤다.
class _NoDelayAvailabilityRepo implements TeacherAvailabilityRepository {
  @override
  Future<List<AvailabilitySlot>> getAvailableSlotsForDateRange(
    String teacherId,
    DateTime startDate,
    DateTime endDate, {
    String? currentStudentId,
  }) async => const <AvailabilitySlot>[];

  @override
  Future<TeacherAvailability?> getAvailability(String teacherId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// #522 회귀: 변경/취소 진입점이 변경권 수·subscriptionId 를 하드코딩(가짜 0/0)으로
/// 넘겨 버튼이 죽던 문제. MyBookingsRoute 가 학생의 활성 수강권(SSOT)에서 직접
/// 파생하는지 검증한다.
void main() {
  Subscription buildSub({int total = 3, int used = 1}) => Subscription(
    id: 'sub1',
    studentId: 's1',
    membershipId: 'm1',
    type: SubscriptionType.monthly,
    amount: 100000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    totalRescheduleAllowance: total,
    usedRescheduleCount: used,
  );

  Future<MyBookingsScreen> pumpRoute(
    WidgetTester tester, {
    required Future<Subscription?> Function() sub,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherAvailabilityRepositoryProvider.overrideWithValue(
            _NoDelayAvailabilityRepo(),
          ),
          activeSubscriptionBetweenProvider(
            studentId: 's1',
            teacherId: 't1',
          ).overrideWith((ref) => sub()),
        ],
        child: const MaterialApp(
          home: MyBookingsRoute(
            studentId: 's1',
            studentName: '학생',
            teacherId: 't1',
            teacherName: '선생님',
          ),
        ),
      ),
    );
    // 활성 수강권 + 슬롯 Future 해소 → MyBookingsRoute 가 MyBookingsScreen 렌더.
    // (pumpAndSettle 은 로딩 스피너가 무한 애니메이션이라 사용 불가)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
    return tester.widget<MyBookingsScreen>(find.byType(MyBookingsScreen));
  }

  testWidgets('활성 수강권의 변경권 수를 파생해 MyBookingsScreen 에 전달', (tester) async {
    final screen = await pumpRoute(tester, sub: () async => buildSub());

    expect(screen.remainingReschedules, 2); // total 3 - used 1
    expect(screen.totalReschedules, 3);
    expect(screen.subscriptionId, 'sub1');
  });

  testWidgets('활성 수강권 없으면 변경권 0 → 변경/취소 비활성', (tester) async {
    final screen = await pumpRoute(tester, sub: () async => null);

    expect(screen.remainingReschedules, 0);
    expect(screen.totalReschedules, 0);
    expect(screen.subscriptionId, isNull);
  });
}
