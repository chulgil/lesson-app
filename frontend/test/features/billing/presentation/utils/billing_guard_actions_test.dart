// #415 R4 Phase B — guardAddStudentNavigation 분기 테스트.
//
// allowed → onPass 즉시 실행, blocked → FreeLimitSheet 노출.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/billing/domain/entities/app_billing_snapshot.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_plan.dart';
import 'package:lessonaza/features/billing/domain/entities/billing_status.dart';
import 'package:lessonaza/features/billing/domain/repositories/app_billing_repository.dart';
import 'package:lessonaza/features/billing/presentation/providers/app_billing_provider.dart';
import 'package:lessonaza/features/billing/presentation/utils/billing_guard_actions.dart';
import 'package:lessonaza/features/billing/presentation/widgets/free_limit_sheet.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/domain/repositories/student_repository.dart';
import 'package:lessonaza/features/students/presentation/providers/student_repository_provider.dart';

class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository(this._count);
  final int _count;

  @override
  Future<List<Student>> getStudents() async {
    return List.generate(
      _count,
      (i) => Student(
        id: 's$i',
        name: 'student_$i',
        instrument: 'violin',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppBillingSnapshot _snapshot({
  required BillingPlan plan,
  required BillingStatus status,
  bool trialUsed = false,
}) {
  return AppBillingSnapshot(
    id: 'p',
    userId: 'u',
    plan: plan,
    status: status,
    startedAt: DateTime.utc(2026, 1, 1),
    expiresAt: null,
    source: 'test',
    originalTransactionId: null,
    trialUsed: trialUsed,
  );
}

Widget _harness({
  required AppBillingSnapshot snapshot,
  required int studentCount,
  required void Function(BuildContext, WidgetRef) onTap,
}) {
  return ProviderScope(
    overrides: [
      appBillingRepositoryProvider.overrideWithValue(
        _FakeBillingRepository(snapshot),
      ),
      studentRepositoryProvider.overrideWithValue(
        _FakeStudentRepository(studentCount),
      ),
    ],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onTap(context, ref),
                child: const Text('go'),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _FakeBillingRepository implements AppBillingRepository {
  _FakeBillingRepository(this._snapshot);
  final AppBillingSnapshot _snapshot;
  @override
  Future<AppBillingSnapshot> fetchSnapshot() async => _snapshot;
}

/// 표준 테스트 surface(800x600) 는 BottomSheet 내용을 다 못 담아 RenderFlex
/// overflow 가 난다. 모바일 세로 사이즈로 키워 sheet 가 정상 렌더되도록 한다.
Future<void> _useTallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('free + count < 5 → onPass 즉시 실행, sheet 미노출', (tester) async {
    await _useTallSurface(tester);
    var pass = 0;
    await tester.pumpWidget(
      _harness(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.active,
        ),
        studentCount: 3,
        onTap: (ctx, ref) async {
          await guardAddStudentNavigation(
            context: ctx,
            ref: ref,
            onPass: () => pass++,
          );
        },
      ),
    );
    // 첫 빌드에서 FutureProvider/Notifier 데이터 적재.
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(pass, 1);
    expect(find.byKey(FreeLimitSheet.buyProButtonKey), findsNothing);
  });

  testWidgets('free + count == 5 → sheet 노출, onPass 미실행', (tester) async {
    await _useTallSurface(tester);
    var pass = 0;
    await tester.pumpWidget(
      _harness(
        snapshot: _snapshot(
          plan: BillingPlan.free,
          status: BillingStatus.active,
        ),
        studentCount: 5,
        onTap: (ctx, ref) async {
          await guardAddStudentNavigation(
            context: ctx,
            ref: ref,
            onPass: () => pass++,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(pass, 0);
    expect(find.text(AppStrings.paywallFreeLimitTitle), findsOneWidget);
    expect(find.byKey(FreeLimitSheet.buyProButtonKey), findsOneWidget);

    // "나중에" 로 닫기 → onPass 여전히 미실행.
    await tester.tap(find.byKey(FreeLimitSheet.laterButtonKey));
    await tester.pumpAndSettle();
    expect(pass, 0);
  });

  testWidgets('pro 무제한 → 개수 무관 통과', (tester) async {
    await _useTallSurface(tester);
    var pass = 0;
    await tester.pumpWidget(
      _harness(
        snapshot: _snapshot(
          plan: BillingPlan.pro,
          status: BillingStatus.active,
        ),
        studentCount: 50,
        onTap: (ctx, ref) async {
          await guardAddStudentNavigation(
            context: ctx,
            ref: ref,
            onPass: () => pass++,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(pass, 1);
  });

  testWidgets('expired → 만료 sheet 노출 (trial 카드 숨김)', (tester) async {
    await _useTallSurface(tester);
    var pass = 0;
    await tester.pumpWidget(
      _harness(
        snapshot: _snapshot(
          plan: BillingPlan.pro,
          status: BillingStatus.expired,
        ),
        studentCount: 10,
        onTap: (ctx, ref) async {
          await guardAddStudentNavigation(
            context: ctx,
            ref: ref,
            onPass: () => pass++,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(pass, 0);
    expect(find.text(AppStrings.paywallPlanExpiredTitle), findsOneWidget);
    expect(find.byKey(FreeLimitSheet.startTrialButtonKey), findsNothing);
  });
}
