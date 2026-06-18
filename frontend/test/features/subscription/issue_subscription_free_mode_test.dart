import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/issue_form_sections.dart';

/// #770 — 직접 발급 무료(체험) 모드 데이터 무결성 가드.
///
/// 무료 모드 선택 시: 체험 타입 자동 + 제출 시 amount=0 · 결제 미기록.
/// 배치 모드(2학생, membership 없음)로 pump 해 per-student membership 조회를 우회한다
/// (기존 issue_subscription_created_id_test 하니스 차용).
/// 칩 좌표 탭은 lazy ListView 에서 취약하므로, scrollUntilVisible 로 PaymentStatusSection
/// 을 빌드시킨 뒤 onModeChanged(free) 를 직접 호출해 무료 선택을 결정적으로 트리거.

/// create() 로 들어온 Subscription 을 캡처(amount/type/paymentConfirmed 검증).
class _CapturingSubscriptionRepository extends MockSubscriptionRepository {
  final List<Subscription> created = [];
  @override
  Future<Subscription> create(Subscription subscription) async {
    created.add(subscription);
    return super.create(subscription);
  }
}

/// 경량 lesson-request repo — 무거운 mock 시드(pumpAndSettle hang)를 피한다.
class _FakeLessonRequestRepository implements UnifiedLessonRequestRepository {
  final Map<String, UnifiedLessonRequest> store = {};
  @override
  Future<UnifiedLessonRequest?> getById(String id) async => store[id];
  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async {
    store[request.id] = request;
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  testWidgets('무료 모드 직접 발급 → amount=0 · type=trial · 결제 미기록', (tester) async {
    final subRepo = _CapturingSubscriptionRepository();
    final requestRepo = _FakeLessonRequestRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(subRepo),
          unifiedLessonRequestRepositoryProvider.overrideWithValue(requestRepo),
        ],
        child: MaterialApp(
          home: IssueSubscriptionScreen(
            studentIds: const ['student-1', 'student-2'],
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final scrollable = find.byType(Scrollable).first;

    // 결제 섹션을 빌드시킨 뒤 무료 칩 노출 확인.
    await tester.scrollUntilVisible(
      find.byType(PaymentStatusSection),
      250,
      scrollable: scrollable,
    );
    await tester.pump();
    expect(
      find.text(AppStrings.methodFreeChip),
      findsOneWidget,
      reason: '직접 발급 결제 섹션에 무료 칩이 노출돼야 한다 (#770)',
    );

    // 무료 선택을 결정적으로 트리거(칩 좌표 탭 대신 콜백 직접 호출).
    final section = tester.widget<PaymentStatusSection>(
      find.byType(PaymentStatusSection),
    );
    section.onModeChanged(IssuePaymentMode.free);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 제출.
    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      250,
      scrollable: scrollable,
    );
    await tester.tap(find.byType(FilledButton));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(subRepo.created, isNotEmpty, reason: '무료 발급이 생성돼야 한다');
    for (final sub in subRepo.created) {
      expect(sub.amount, 0, reason: '무료 발급은 amount=0 (#770 데이터 무결성)');
      expect(sub.type, SubscriptionType.trial, reason: '무료 → 체험 타입 자동');
      expect(sub.paymentConfirmed, isFalse, reason: '무료는 결제 미기록');
    }
  });
}
