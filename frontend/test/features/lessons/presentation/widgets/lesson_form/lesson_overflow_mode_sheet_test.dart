import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_form/lesson_overflow_mode_sheet.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

Subscription _sub({required int total, required int used}) => Subscription(
  id: 's1',
  studentId: 'st1',
  membershipId: 'm1',
  type: SubscriptionType.package,
  totalLessons: total,
  usedLessons: used,
  amount: 100000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 1, 1),
);

/// S3 sheet — subscription_required_spec §2.6.2 (option set, D1 default,
/// unconnected swap, record-mode renewal hiding) + wire values.
Future<LessonOverflowChoice? Function()> _open(
  WidgetTester tester, {
  int credits = 0,
  bool connected = true,
  bool allowRenewal = true,
}) async {
  LessonOverflowChoice? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder:
            (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showLessonOverflowModeSheet(
                      context: context,
                      studentName: '김민지',
                      subscriptionName: '8회권',
                      availableCredits: credits,
                      isConnectedStudent: connected,
                      allowRenewal: allowRenewal,
                    );
                  },
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
  return () => result;
}

void main() {
  test('renewalIssueLocation — previewLessonId 를 발급 라우트에 배선 (§2.6.3 엣지 ①)', () {
    expect(
      renewalIssueLocation(studentId: 'stu-1', previewLessonId: 'L9'),
      '/subscriptions/issue?studentId=stu-1&previewLessonId=L9',
    );
  });

  group('mustPickSubscriptionBeforeSave — 시트 dismiss 가드 (§2.6.3 엣지 ②)', () {
    test('활성 수강권 있음 + 미선택 + 단건: 저장 전 선택 강제', () {
      expect(
        mustPickSubscriptionBeforeSave(
          selected: null,
          actives: [_sub(total: 10, used: 10)],
          isRecurring: false,
        ),
        isTrue,
      );
    });

    test('이미 선택됨: 가드 미발동', () {
      expect(
        mustPickSubscriptionBeforeSave(
          selected: _sub(total: 10, used: 0),
          actives: [_sub(total: 10, used: 0)],
          isRecurring: false,
        ),
        isFalse,
      );
    });

    test('활성 수강권 0개: 가드 미발동 — 체험 자동생성 경로 유지', () {
      expect(
        mustPickSubscriptionBeforeSave(
          selected: null,
          actives: const [],
          isRecurring: false,
        ),
        isFalse,
      );
    });

    test('정규(반복) 저장: 가드 미발동 — 레거시 경로 유지 계약', () {
      expect(
        mustPickSubscriptionBeforeSave(
          selected: null,
          actives: [_sub(total: 10, used: 10)],
          isRecurring: true,
        ),
        isFalse,
      );
    });
  });

  testWidgets('가입 학생 + 크레딧 0: 보강 숨김, 갱신 제안이 기본 강조(D1)', (tester) async {
    final getResult = await _open(tester);

    expect(find.text(AppStrings.overflowOptionMakeup), findsNothing);
    expect(find.text(AppStrings.overflowOptionBonus), findsOneWidget);
    expect(find.text(AppStrings.overflowOptionRenewal), findsOneWidget);
    expect(find.text(AppStrings.overflowOptionRenewalIssue), findsNothing);
    expect(
      find.text(AppStrings.overflowSheetSubtitle('김민지', '8회권')),
      findsOneWidget,
    );

    // D1 — 갱신 제안이 기본 선택 (계속하기 즉시 탭 시 renewal 반환)
    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();
    expect(getResult(), LessonOverflowChoice.renewalProposal);
  });

  testWidgets('크레딧 보유: 보강 항목 + 잔량 설명 노출', (tester) async {
    await _open(tester, credits: 2);

    expect(find.text(AppStrings.overflowOptionMakeup), findsOneWidget);
    expect(find.text(AppStrings.overflowOptionMakeupDesc(2)), findsOneWidget);
  });

  testWidgets('미가입 학생: 갱신 제안 대신 [수강권 갱신 발급] (§2.7)', (tester) async {
    await _open(tester, connected: false);

    expect(find.text(AppStrings.overflowOptionRenewal), findsNothing);
    expect(find.text(AppStrings.overflowOptionRenewalIssue), findsOneWidget);
  });

  testWidgets('기록 모드(allowRenewal=false): 갱신 숨김, 보너스가 기본', (tester) async {
    final getResult = await _open(tester, credits: 1, allowRenewal: false);

    expect(find.text(AppStrings.overflowOptionRenewal), findsNothing);
    expect(find.text(AppStrings.overflowOptionRenewalIssue), findsNothing);
    expect(find.text(AppStrings.overflowOptionMakeup), findsOneWidget);
    expect(find.text(AppStrings.overflowOptionBonus), findsOneWidget);

    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();
    expect(getResult(), LessonOverflowChoice.bonus);
  });

  testWidgets('선택 변경 후 계속하기 → 선택값 반환 + wire 값 매핑', (tester) async {
    final getResult = await _open(tester, credits: 3);

    await tester.tap(find.text(AppStrings.overflowOptionMakeup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.continueAction));
    await tester.pumpAndSettle();

    final choice = getResult();
    expect(choice, LessonOverflowChoice.makeupCredit);
    expect(choice!.wireValue, 'makeup_credit');
    expect(LessonOverflowChoice.bonus.wireValue, 'bonus');
    expect(LessonOverflowChoice.renewalProposal.wireValue, 'renewal_pending');
    expect(LessonOverflowChoice.renewalIssue.wireValue, 'renewal_pending');
  });

  testWidgets('시트 밖 탭 dismiss → null 반환 (저장 중단 계약)', (tester) async {
    final getResult = await _open(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(getResult(), isNull);
  });

  group('shouldPromptOverflowMode — S1/S2 회귀 고정 (AC-2.2)', () {
    test('S1: 잔여 > 0 단일 수강권 → 시트 없음 (기존 즉시 저장 불변)', () {
      expect(
        shouldPromptOverflowMode(
          subscription: _sub(total: 8, used: 2),
          isRecurring: false,
        ),
        isFalse,
      );
    });

    test('S2: 잔여 > 0 선택된 수강권 → 시트 없음', () {
      expect(
        shouldPromptOverflowMode(
          subscription: _sub(total: 10, used: 9),
          isRecurring: false,
        ),
        isFalse,
      );
    });

    test('S3: 잔여 0 → 시트 트리거', () {
      expect(
        shouldPromptOverflowMode(
          subscription: _sub(total: 8, used: 8),
          isRecurring: false,
        ),
        isTrue,
      );
    });

    test('수강권 미선택(0개/체험 자동생성) → 시트 없음', () {
      expect(
        shouldPromptOverflowMode(subscription: null, isRecurring: false),
        isFalse,
      );
    });

    test('정기 반복 저장 → 시트 없음 (레거시 경로 유지)', () {
      expect(
        shouldPromptOverflowMode(
          subscription: _sub(total: 8, used: 8),
          isRecurring: true,
        ),
        isFalse,
      );
    });
  });
}
