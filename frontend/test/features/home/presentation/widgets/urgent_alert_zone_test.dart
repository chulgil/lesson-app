import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/home/presentation/widgets/urgent_alert_zone.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

// Helper: build UrgentAlertZone with controlled provider overrides.
Widget _buildZone({
  required List<Override> overrides,
  int unpaidAmount = 0,
  int unpaidStudents = 0,
  List<Lesson> needsConfirmation = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320, // narrow viewport to catch layout overflow
          child: UrgentAlertZone(
            teacherId: 'teacher_test',
            unpaidSummary: AsyncValue.data((
              totalAmount: unpaidAmount,
              studentCount: unpaidStudents,
            )),
            needsConfirmation: AsyncValue.data(needsConfirmation),
          ),
        ),
      ),
    ),
  );
}

List<Override> _baseOverrides({
  List<Subscription> expiringSoon = const [],
  List<Subscription> expired = const [],
  int pendingBookings = 0,
}) {
  return [
    expiringSoonSubscriptionsProvider.overrideWith((_) async => expiringSoon),
    expiredSubscriptionsProvider.overrideWith((_) async => expired),
    pendingBookingsCountProvider(
      'teacher_test',
    ).overrideWith((_) async => pendingBookings),
  ];
}

void main() {
  group('UrgentAlertZone — policy #793: 최대 3건 항상 표시', () {
    testWidgets('알림 없음 → SizedBox.shrink (빈 위젯)', (tester) async {
      await tester.pumpWidget(_buildZone(overrides: _baseOverrides()));
      await tester.pump();

      expect(find.byType(UrgentAlertZone), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('알림 1건 → 항상 표시, 펼치기 없음', (tester) async {
      await tester.pumpWidget(
        _buildZone(overrides: _baseOverrides(pendingBookings: 2)),
      );
      await tester.pump();

      expect(find.text(AppStrings.pendingBookings(2)), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('서로 다른 타입 3건 → 모두 노출, 펼치기 없음', (tester) async {
      // 3 different types: unpaid + expired + pending bookings
      await tester.pumpWidget(
        _buildZone(
          overrides: _baseOverrides(expired: [_fakeSub()], pendingBookings: 1),
          unpaidAmount: 50000,
          unpaidStudents: 1,
        ),
      );
      await tester.pump();

      expect(
        find.text(AppStrings.urgentAlertOutstandingFormat(50000, 1)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.subscriptionExpired(1)), findsOneWidget);
      expect(find.text(AppStrings.pendingBookings(1)), findsOneWidget);
      // Exactly 3 items → no expand toggle
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('서로 다른 타입 4건 → 3건 표시 + 펼치기 토글', (tester) async {
      // 4 types: unpaid + expired + expiring soon + pending bookings
      await tester.pumpWidget(
        _buildZone(
          overrides: _baseOverrides(
            expired: [_fakeSub()],
            expiringSoon: [_fakeSub()],
            pendingBookings: 3,
          ),
          unpaidAmount: 10000,
          unpaidStudents: 2,
        ),
      );
      await tester.pump();

      // First 3 visible
      expect(
        find.text(AppStrings.urgentAlertOutstandingFormat(10000, 2)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.subscriptionExpired(1)), findsOneWidget);
      expect(find.text(AppStrings.subscriptionExpiringSoon(1)), findsOneWidget);

      // 4th hidden behind toggle
      expect(find.text(AppStrings.pendingBookings(3)), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('펼치기 탭 → 숨겨진 알림 노출 + 접기 아이콘 전환', (tester) async {
      await tester.pumpWidget(
        _buildZone(
          overrides: _baseOverrides(
            expired: [_fakeSub()],
            expiringSoon: [_fakeSub()],
            pendingBookings: 3,
          ),
          unpaidAmount: 10000,
          unpaidStudents: 2,
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pump();

      expect(find.text(AppStrings.pendingBookings(3)), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5건 모두 활성 → 3건 표시 + 외 2건 토글', (tester) async {
      // All 5 types: unpaid + expired + expiring soon + needsConfirmation + pending
      await tester.pumpWidget(
        _buildZone(
          overrides: _baseOverrides(
            expired: [_fakeSub()],
            expiringSoon: [_fakeSub()],
            pendingBookings: 1,
          ),
          unpaidAmount: 20000,
          unpaidStudents: 3,
          needsConfirmation: [_fakeLesson()],
        ),
      );
      await tester.pump();

      // First 3: unpaid, expired, expiring soon
      expect(
        find.text(AppStrings.urgentAlertOutstandingFormat(20000, 3)),
        findsOneWidget,
      );
      expect(find.text(AppStrings.subscriptionExpired(1)), findsOneWidget);
      expect(find.text(AppStrings.subscriptionExpiringSoon(1)), findsOneWidget);

      // Items 4+5 hidden
      expect(find.text(AppStrings.lessonsNeedConfirmation(1)), findsNothing);
      expect(find.text(AppStrings.pendingBookings(1)), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px 좁은 폭에서 레이아웃 오버플로 없음', (tester) async {
      await tester.pumpWidget(
        _buildZone(
          overrides: _baseOverrides(
            expired: [_fakeSub()],
            expiringSoon: [_fakeSub()],
            pendingBookings: 2,
          ),
          unpaidAmount: 99999999,
          unpaidStudents: 50,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

Subscription _fakeSub() => Subscription(
  id: 'sub_test',
  studentId: 'student_test',
  membershipId: 'membership_test',
  type: SubscriptionType.package,
  amount: 100000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 1, 1),
);

Lesson _fakeLesson() => Lesson(
  id: 'lesson_test',
  studentId: 'student_test',
  studentName: '테스트 학생',
  instrument: 'piano',
  date: DateTime(2026, 6, 1),
  startTime: '10:00',
  createdAt: DateTime(2026, 6, 1),
);
