import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_picker_sheet.dart';

Subscription _sub({
  required String id,
  String? instrument,
  int totalLessons = 8,
  int usedLessons = 0,
}) {
  return Subscription(
    id: id,
    studentId: 'st1',
    membershipId: 'm_$id',
    instrument: instrument,
    type: SubscriptionType.package,
    totalLessons: totalLessons,
    usedLessons: usedLessons,
    amount: 100000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('SubscriptionPickerSheet 는 예외 없이 렌더되고 카드를 표시한다', (tester) async {
    final subs = [
      _sub(id: 's1', instrument: '피아노'),
      _sub(id: 's2', instrument: '바이올린'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionPickerSheet(
            subscriptions: subs,
            recommendedId: 's1',
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SubscriptionPickerCard), findsNWidgets(2));
    // 악기 칩이 보인다
    expect(find.text('피아노'), findsOneWidget);
    expect(find.text('바이올린'), findsOneWidget);
  });

  testWidgets('카드 탭 시 해당 수강권으로 onSelected 콜백이 호출된다', (tester) async {
    Subscription? selected;
    final subs = [
      _sub(id: 's1', instrument: '피아노'),
      _sub(id: 's2', instrument: '바이올린'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubscriptionPickerSheet(
            subscriptions: subs,
            recommendedId: 's1',
            onSelected: (sub) => selected = sub,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('바이올린'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.id, 's2');
  });

  testWidgets('showSubscriptionPickerSheet 는 탭한 수강권을 반환한다', (tester) async {
    final subs = [
      _sub(id: 's1', instrument: '피아노'),
      _sub(id: 's2', instrument: '바이올린'),
    ];
    Subscription? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed: () async {
                    result = await showSubscriptionPickerSheet(
                      context: context,
                      subscriptions: subs,
                      recommendedId: 's1',
                    );
                  },
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('피아노'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.id, 's1');
  });
}
