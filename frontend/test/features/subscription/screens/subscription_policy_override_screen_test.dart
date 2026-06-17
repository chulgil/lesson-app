import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/academy/domain/entities/academy_enums.dart';
import 'package:lessonaza/features/profile/domain/entities/cancellation_defaults.dart';
import 'package:lessonaza/features/profile/presentation/providers/cancellation_defaults_provider.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/screens/subscription_policy_override_screen.dart';

class _FakeDefaultsNotifier extends CancellationDefaultsNotifier {
  _FakeDefaultsNotifier(this._defaults);

  final CancellationDefaults _defaults;

  @override
  Future<CancellationDefaults> build() async => _defaults;
}

void main() {
  CancellationDefaults makeDefaults() => CancellationDefaults(
    id: 'defaults-1',
    cancellationDeadlineHours: 12,
    studentCompensationExtraMinutesEnabled: true,
    includeExtraMinutesTextOnLateCancel: true,
    studentCompensationExtraMinutesMessage: '기본 안내 문구',
    notifyOwnerOnLateCancel: false,
    createdAt: DateTime(2026, 1, 1),
  );

  Subscription makeSubscription({SubscriptionOwnership? ownership}) =>
      Subscription(
        id: 'sub-1',
        studentId: 'student-1',
        membershipId: 'membership-1',
        type: SubscriptionType.monthly,
        amount: 200000,
        status: SubscriptionStatus.active,
        createdAt: DateTime(2026, 5, 1),
        ownership: ownership,
      );

  Widget pumpScreen({
    required Subscription sub,
    required CancellationDefaults defaults,
  }) {
    return ProviderScope(
      overrides: [
        cancellationDefaultsNotifierProvider.overrideWith(
          () => _FakeDefaultsNotifier(defaults),
        ),
      ],
      child: MaterialApp(
        home: SubscriptionPolicyOverrideScreen(subscription: sub),
      ),
    );
  }

  testWidgets('teacher-owned subscription shows editable fields and save', (
    tester,
  ) async {
    final sub = makeSubscription(ownership: SubscriptionOwnership.teacher);
    final defaults = makeDefaults();

    await tester.pumpWidget(pumpScreen(sub: sub, defaults: defaults));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('수강권 취소 정책'), findsWidgets);

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.length, greaterThanOrEqualTo(2));
    for (final s in switches) {
      expect(s.onChanged, isNotNull);
    }

    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('academy-owned subscription renders read-only banner', (
    tester,
  ) async {
    final sub = makeSubscription(ownership: SubscriptionOwnership.academy);
    final defaults = makeDefaults();

    await tester.pumpWidget(pumpScreen(sub: sub, defaults: defaults));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('학원 귀속 수강권입니다. 정책은 학원 관리자만 변경할 수 있습니다.'), findsOneWidget);
    expect(find.text('저장'), findsNothing);

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    for (final s in switches) {
      expect(s.onChanged, isNull);
    }
  });
  testWidgets('priority banner renders at 320px width without overflow', (
    tester,
  ) async {
    final sub = makeSubscription(ownership: SubscriptionOwnership.teacher);
    final defaults = makeDefaults();

    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(pumpScreen(sub: sub, defaults: defaults));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('기본 정책(전역)에서 가져온 값 · 이 수강권만 변경됩니다'), findsOneWidget);
    expect(find.text('개별 > 템플릿 > 전역 순으로 적용됩니다'), findsOneWidget);
  });

}
