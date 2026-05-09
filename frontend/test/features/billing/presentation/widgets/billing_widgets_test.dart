// Smoke tests for billing widgets — BillingPlanBadge, FreeLimitSheet, BillingPlansScreen.
//
// Verifies widgets render without layout exceptions under various constraints.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/presentation/providers/billing_provider.dart';
import 'package:lessonaza/features/billing/presentation/widgets/billing_plan_badge.dart';
import 'package:lessonaza/features/billing/presentation/widgets/free_limit_sheet.dart';
import 'package:lessonaza/features/billing/presentation/screens/billing_plans_screen.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

void main() {
  // ── Helpers ──────────────────────────────────────────────────

  List<Override> billingOverrides({
    BillingStatus status = BillingStatus.defaultFree,
    List<Student> students = const [],
  }) {
    return [
      billingStatusNotifierProvider.overrideWith(
        () => _FakeBillingStatusNotifier(status),
      ),
      studentsNotifierProvider.overrideWith(
        () => _FakeStudentsNotifier(students),
      ),
      billingProductsProvider.overrideWith(
        (ref) async => const [
          BillingProduct(
            productId: 'pro_monthly',
            plan: 'pro',
            description: 'Pro 월간 구독',
          ),
        ],
      ),
      storeProductsProvider.overrideWith((ref) async => []),
    ];
  }

  Future<void> pumpWithOverrides(
    WidgetTester tester,
    Widget widget, {
    BillingStatus status = BillingStatus.defaultFree,
    List<Student> students = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: billingOverrides(status: status, students: students),
        child: MaterialApp(home: Scaffold(body: widget)),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ── BillingPlanBadge ────────────────────────────────────────

  group('BillingPlanBadge', () {
    testWidgets('free plan — no badge rendered', (tester) async {
      await pumpWithOverrides(tester, const BillingPlanBadge());
      expect(tester.takeException(), isNull);
      expect(find.text('Pro'), findsNothing);
    });

    testWidgets('pro plan — shows Pro badge', (tester) async {
      await pumpWithOverrides(
        tester,
        const BillingPlanBadge(),
        status: const BillingStatus(
          plan: 'pro',
          isActive: true,
          features: {'ai_notes': true},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets('trial plan — shows 체험 중 badge', (tester) async {
      await pumpWithOverrides(
        tester,
        const BillingPlanBadge(),
        status: BillingStatus(
          plan: 'trial_pro',
          isActive: true,
          daysRemaining: 10,
          trialEndsAt: DateTime.now().add(const Duration(days: 10)),
          features: const {'ai_notes': true},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('체험 중'), findsOneWidget);
      expect(find.text('10일'), findsOneWidget);
    });

    testWidgets('renders in tight Row without overflow', (tester) async {
      await pumpWithOverrides(
        tester,
        const SizedBox(
          width: 120,
          child: Row(
            children: [
              Text('Name'),
              BillingPlanBadge(),
            ],
          ),
        ),
        status: const BillingStatus(
          plan: 'pro',
          isActive: true,
          features: {},
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ── FreeLimitSheet ──────────────────────────────────────────

  group('FreeLimitSheet', () {
    testWidgets('renders without layout exception', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: billingOverrides(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showFreeLimitSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('무료 플랜 학생 수 초과'), findsOneWidget);
      expect(find.text('14일 무료 체험 시작'), findsOneWidget);
      expect(find.text('구독 플랜 보기'), findsOneWidget);
    });
  });

  // ── BillingPlansScreen ──────────────────────────────────────

  group('BillingPlansScreen', () {
    testWidgets('renders free plan state without exception', (tester) async {
      await pumpWithOverrides(
        tester,
        const BillingPlansScreen(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('구독 플랜 보기'), findsOneWidget);
      expect(find.text('Free'), findsWidgets);
      expect(find.text('Pro'), findsWidgets);
    });

    testWidgets('renders pro plan state without exception', (tester) async {
      await pumpWithOverrides(
        tester,
        const BillingPlansScreen(),
        status: const BillingStatus(
          plan: 'pro',
          isActive: true,
          daysRemaining: 25,
          features: {'ai_notes': true, 'recording': true},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('현재'), findsOneWidget);
    });

    testWidgets('renders in narrow viewport (375px)', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpWithOverrides(
        tester,
        const BillingPlansScreen(),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

// ── Fake Notifiers ──────────────────────────────────────────────

class _FakeBillingStatusNotifier extends BillingStatusNotifier {
  final BillingStatus _status;
  _FakeBillingStatusNotifier(this._status);

  @override
  Future<BillingStatus> build() async => _status;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> startTrial() async {}

  @override
  Future<void> verifyPurchase({
    required String storePlatform,
    required String productId,
    required String transactionId,
    required String receiptData,
  }) async {}

  @override
  Future<void> restorePurchase() async {}
}

class _FakeStudentsNotifier extends StudentsNotifier {
  final List<Student> _students;
  _FakeStudentsNotifier(this._students);

  @override
  Future<List<Student>> build() async => _students;
}
