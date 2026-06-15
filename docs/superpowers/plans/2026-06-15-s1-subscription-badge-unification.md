# S1 수강권 배지 통일 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 홈 레슨카드와 학생탭이 같은 수강권을 동일한 숫자(잔여)·색(긴급도)·형태(티켓 스탬프 박스)로 렌더하도록, 정본 위젯 `SubscriptionBadge` 하나가 시각·상태 로직을 독점하고 학생탭 래퍼는 데이터 해석만 위임한다.

**Architecture:** `SubscriptionBadge`(subscription/presentation, StatelessWidget) = 정본 — `Subscription` 입력, 상태→색·아이콘·라벨·박스 소유. `StudentSubscriptionMiniBadge`(students/presentation, ConsumerWidget) = 얇은 래퍼 — provider 구독 → 최긴급 수강권 해석 + 빈 상태만, 렌더는 정본에 위임. 죽은 위젯 3종 삭제.

**Tech Stack:** Flutter 3.29, Riverpod, GoogleFonts(IBM Plex Mono), Material Icons. 테스트: flutter_test + ProviderScope override.

**Spec:** `docs/specs/design/notebook/subscription_badge_unification.md`

**작업 위치:** worktree `lesson-app-s1-badge` (branch `feat/s1-subscription-badge`). 모든 경로는 `frontend/` 기준.

---

## File Structure

| 파일 | 책임 | 변경 |
|------|------|------|
| `lib/core/l10n/app_strings.dart` | 사용자 문자열 SSOT | 키 3종 추가 |
| `lib/features/subscription/presentation/widgets/subscription_badge.dart` | 정본 배지 | 통일 상태 모델로 재작성 + 죽은 클래스 2종 삭제 |
| `lib/features/students/presentation/widgets/student_subscription_badge.dart` | 학생탭 래퍼 | 위임 래퍼로 축소 + `StudentClassBadge` 삭제 |
| `lib/features/home/presentation/widgets/lesson_card.dart` | 홈 호출처 | `showIcon` 인자 제거 |
| `lib/features/subscription/subscription_ui_facade.dart` | 공개 API | (필요 시) `SubscriptionBadge` export 확인 |
| `test/.../subscription_badge_test.dart` | 정본 테스트 | 상태 매트릭스 갱신 + 죽은 group 삭제 |
| `test/.../student_subscription_badge_test.dart` | 래퍼 테스트 | **신규 생성** |

> 범위 외(손대지 않음): `ClassTypeFilter` enum(외부 참조 0이나 S1 무관 — 별도 정리), `AcademyOwnershipBadge`(S2), 배너 2종(S3·S4).

---

## Task 1: AppStrings 신규 키

**Files:**
- Modify: `lib/core/l10n/app_strings.dart` (기존 `subscriptionPackageBadgeFormat` 부근 ~L4171)

- [ ] **Step 1: 키 3종 추가**

기존 `subscriptionPackageBadgeFormat` 정의 아래에 추가:

```dart
  /// 입금대기 (badge — 후불 결제 미입금)
  static const subscriptionBadgeUnpaid = '입금대기';

  /// 수강권 없음 (badge — 활성 수강권 0건, 학생탭 래퍼 전용)
  static const subscriptionBadgeNone = '수강권 없음';

  /// D-$days (badge — 정기권 만료까지 일수. 기존 인라인 'D-$days' 형식화)
  static String subscriptionBadgeDday(int days) => 'D-$days';
```

재사용(신설 금지): `statusExpired`(만료), `subscriptionPackageBadgeFormat`(잔여), `subscriptionTypeTrial`(체험).

- [ ] **Step 2: analyze 통과 확인**

Run: `cd frontend && flutter analyze lib/core/l10n/app_strings.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/core/l10n/app_strings.dart
git commit -m "feat(subscription): 통일 배지 AppStrings 키 3종 추가

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Signed-off-by: 🐙 Autopus <noreply@autopus.co>"
```

---

## Task 2: SubscriptionBadge 통일 상태 모델 (TDD)

**Files:**
- Modify: `lib/features/subscription/presentation/widgets/subscription_badge.dart:18-93` (`SubscriptionBadge` 클래스)
- Modify: `lib/features/home/presentation/widgets/lesson_card.dart:216` (호출처)
- Test: `test/features/subscription/presentation/widgets/subscription_badge_test.dart`

상태 모델 (우선순위 — 위에서 첫 일치):

| 순위 | 상태 | 트리거 | 색 | 아이콘 | 라벨 |
|------|------|--------|-----|--------|------|
| 1 | 입금대기 | `isUnpaid` | paperAccent | warning | `subscriptionBadgeUnpaid` |
| 2 | 만료 | `status==expired` 또는 monthly `daysUntilExpiration<=0` | paperAccent | warning | `statusExpired` |
| 3 | 임박 | `isExpiringSoon` | paperAccent | clock | 타입 라벨 |
| 4 | 정상 | else | inkSecondary | 없음 | 타입 라벨 |

타입 라벨: package=`subscriptionPackageBadgeFormat(remaining, total)`, monthly=`subscriptionBadgeDday(days)`, trial=`subscriptionTypeTrial`.

- [ ] **Step 1: 실패 테스트 작성**

`subscription_badge_test.dart`의 `group('SubscriptionBadge', ...)` 에 케이스 추가 (기존 package/monthly/trial 케이스는 유지, 색·아이콘 단언 보강):

```dart
testWidgets('입금대기 → "입금대기" + 버밀리온 + 경고 아이콘', (tester) async {
  final sub = _makeSub(type: SubscriptionType.package, status: SubscriptionStatus.active, unpaid: true);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubscriptionBadge(subscription: sub))));
  expect(find.text('입금대기'), findsOneWidget);
  expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  final text = tester.widget<Text>(find.text('입금대기'));
  expect(text.style?.color, AppColors.paperAccent);
});

testWidgets('만료 status → "만료" + 버밀리온', (tester) async {
  final sub = _makeSub(type: SubscriptionType.package, status: SubscriptionStatus.expired);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubscriptionBadge(subscription: sub))));
  expect(find.text('만료'), findsOneWidget);
  expect(tester.widget<Text>(find.text('만료')).style?.color, AppColors.paperAccent);
});

testWidgets('정상 회차권 → 중립 잉크 + 아이콘 없음', (tester) async {
  final sub = _makeSub(type: SubscriptionType.package, status: SubscriptionStatus.active, remaining: 7, total: 10);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubscriptionBadge(subscription: sub))));
  expect(find.text('7/10회'), findsOneWidget);
  expect(tester.widget<Text>(find.text('7/10회')).style?.color, AppColors.inkSecondary);
  expect(find.byType(Icon), findsNothing);
});
```

> `_makeSub` 헬퍼는 기존 테스트의 Subscription 생성 패턴을 따른다(기존 fixture 재사용). `isUnpaid`/`isExpiringSoon`은 엔티티 getter이므로 status/dueDate 등 입력으로 유도.

- [ ] **Step 2: 실패 확인**

Run: `cd frontend && flutter test test/features/subscription/presentation/widgets/subscription_badge_test.dart`
Expected: 신규 케이스 FAIL (showIcon/입금대기 미구현).

- [ ] **Step 3: SubscriptionBadge 재작성**

`subscription_badge.dart`의 `SubscriptionBadge` 클래스 전체를 교체:

```dart
class SubscriptionBadge extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionBadge({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();
    final icon = _stateIcon();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            _label(),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// monthly 는 daysUntilExpiration 이 음수일 수 있어 status==expired 와 병합.
  bool get _isExpired =>
      subscription.status == SubscriptionStatus.expired ||
      (subscription.type == SubscriptionType.monthly &&
          (subscription.daysUntilExpiration ?? 0) <= 0);

  /// 긴급도 모델: 조치 필요(입금대기·만료·임박)=버밀리온, 정상=중립 잉크.
  Color _accentColor() {
    if (subscription.isUnpaid || _isExpired || subscription.isExpiringSoon) {
      return AppColors.paperAccent;
    }
    return AppColors.inkSecondary;
  }

  /// 색맹 안전: 조치 필요 상태에만 상태 아이콘. 정상은 아이콘 없음.
  IconData? _stateIcon() {
    if (subscription.isUnpaid || _isExpired) {
      return Icons.warning_amber_rounded;
    }
    if (subscription.isExpiringSoon) return Icons.access_time;
    return null;
  }

  String _label() {
    if (subscription.isUnpaid) return AppStrings.subscriptionBadgeUnpaid;
    if (_isExpired) return AppStrings.statusExpired;
    switch (subscription.type) {
      case SubscriptionType.package:
        return AppStrings.subscriptionPackageBadgeFormat(
          subscription.remainingLessons ?? 0,
          subscription.totalLessonsForDisplay ?? 0,
        );
      case SubscriptionType.monthly:
        return AppStrings.subscriptionBadgeDday(
          subscription.daysUntilExpiration ?? 0,
        );
      case SubscriptionType.trial:
        return AppStrings.subscriptionTypeTrial;
    }
  }
}
```

`showIcon` 파라미터 제거. import 정리(GoogleFonts·AppColors·AppSpacing·AppStrings·Subscription 유지).

- [ ] **Step 4: 홈 호출처 갱신**

`lesson_card.dart:216`:
```dart
// before
SubscriptionBadge(subscription: subscription, showIcon: false),
// after
SubscriptionBadge(subscription: subscription),
```

- [ ] **Step 5: 테스트 + analyze 통과**

Run: `cd frontend && flutter test test/features/subscription/presentation/widgets/subscription_badge_test.dart && flutter analyze lib/features/subscription/presentation/widgets/subscription_badge.dart lib/features/home/presentation/widgets/lesson_card.dart`
Expected: 모든 SubscriptionBadge 케이스 PASS, analyze 0 이슈.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/features/subscription/presentation/widgets/subscription_badge.dart frontend/lib/features/home/presentation/widgets/lesson_card.dart frontend/test/features/subscription/presentation/widgets/subscription_badge_test.dart
git commit -m "feat(subscription): SubscriptionBadge 통일 상태 모델 — 긴급도 색 + 상태 아이콘 + 입금대기

Directive: 상태 우선순위 입금대기>만료>임박>정상, 색은 긴급도(조치 필요=버밀리온/정상=중립)
Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Signed-off-by: 🐙 Autopus <noreply@autopus.co>"
```

---

## Task 3: 죽은 클래스 삭제 (SubscriptionProgressMini · SubscriptionSummaryText)

**Files:**
- Modify: `lib/features/subscription/presentation/widgets/subscription_badge.dart:95-184` (두 클래스 삭제)
- Modify: `test/features/subscription/presentation/widgets/subscription_badge_test.dart:126-159` (`SubscriptionSummaryText` group 삭제)

- [ ] **Step 1: 참조 0 재확인**

Run: `cd frontend && grep -rn "SubscriptionProgressMini\|SubscriptionSummaryText" lib | grep -v "subscription_badge.dart"`
Expected: 출력 없음 (production 참조 0).

- [ ] **Step 2: 두 클래스 + 테스트 group 삭제**

`subscription_badge.dart`에서 `class SubscriptionProgressMini`(~L98)와 `class SubscriptionSummaryText`(~L147) 전체 제거. `subscription_badge_test.dart`의 `group('SubscriptionSummaryText', ...)` 제거. 고아 import(AppTypography가 두 클래스에서만 쓰였다면) 정리.

- [ ] **Step 3: 테스트 + analyze**

Run: `cd frontend && flutter test test/features/subscription/presentation/widgets/subscription_badge_test.dart && flutter analyze lib/features/subscription/presentation/widgets/subscription_badge.dart`
Expected: PASS, 0 이슈, unused import 경고 없음.

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/features/subscription/presentation/widgets/subscription_badge.dart frontend/test/features/subscription/presentation/widgets/subscription_badge_test.dart
git commit -m "refactor(subscription): 미사용 SubscriptionProgressMini·SubscriptionSummaryText 삭제

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Signed-off-by: 🐙 Autopus <noreply@autopus.co>"
```

---

## Task 4: StudentSubscriptionMiniBadge 래퍼 축소 + StudentClassBadge 삭제 (TDD)

**Files:**
- Modify: `lib/features/students/presentation/widgets/student_subscription_badge.dart` (전면)
- Test: `test/features/students/presentation/widgets/student_subscription_badge_test.dart` (**신규**)
- (확인) `lib/features/subscription/subscription_ui_facade.dart` — `SubscriptionBadge` export 존재

- [ ] **Step 1: 신규 래퍼 테스트 작성 (RED)**

`student_subscription_badge_test.dart` 신규 생성. **import 3종 필수** — `SubscriptionBadge`는 `subscription_ui_facade.dart`에서, `Subscription`·`activeStudentSubscriptionsProvider`는 `subscription_facade.dart`에서, 위젯은 `student_subscription_badge.dart`에서:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesson_app/features/subscription/subscription_facade.dart';      // Subscription, activeStudentSubscriptionsProvider
import 'package:lesson_app/features/subscription/subscription_ui_facade.dart';   // SubscriptionBadge
import 'package:lesson_app/features/students/presentation/widgets/student_subscription_badge.dart';
// 패키지명은 pubspec(name:)을 따른다 — 기존 테스트 import 스타일과 일치시킬 것
```

```dart
testWidgets('수강권 0건 → "수강권 없음" 텍스트, SubscriptionBadge 없음', (tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [activeStudentSubscriptionsProvider('s1').overrideWith((ref) async => <Subscription>[])],
    child: const MaterialApp(home: Scaffold(body: StudentSubscriptionMiniBadge(studentId: 's1'))),
  ));
  await tester.pumpAndSettle();
  expect(find.text('수강권 없음'), findsOneWidget);
  expect(find.byType(SubscriptionBadge), findsNothing);
});

testWidgets('수강권 존재 → SubscriptionBadge 위임 렌더', (tester) async {
  final sub = _makeSub(type: SubscriptionType.package, remaining: 7, total: 10);
  await tester.pumpWidget(ProviderScope(
    overrides: [activeStudentSubscriptionsProvider('s1').overrideWith((ref) async => [sub])],
    child: const MaterialApp(home: Scaffold(body: StudentSubscriptionMiniBadge(studentId: 's1'))),
  ));
  await tester.pumpAndSettle();
  expect(find.byType(SubscriptionBadge), findsOneWidget);
  expect(find.text('7/10회'), findsOneWidget);
});
```

> provider override 정확한 시그니처는 `activeStudentSubscriptionsProvider` 정의(`membership_providers.dart`)를 따른다. family 인자/Async 형태 확인 후 맞춘다.

- [ ] **Step 2: 실패 확인**

Run: `cd frontend && flutter test test/features/students/presentation/widgets/student_subscription_badge_test.dart`
Expected: FAIL (위임 미구현 — 현재는 자체 `_buildSubscriptionBadge`).

- [ ] **Step 3: 래퍼로 축소 + StudentClassBadge 삭제**

`student_subscription_badge.dart`:
- `StudentClassBadge` 클래스 삭제(0 refs).
- `StudentSubscriptionMiniBadge`를 위임 래퍼로 교체:

```dart
class StudentSubscriptionMiniBadge extends ConsumerWidget {
  final String studentId;
  const StudentSubscriptionMiniBadge({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync =
        ref.watch(activeStudentSubscriptionsProvider(studentId));
    return subscriptionsAsync.when(
      data: (subscriptions) {
        final urgent = _mostUrgent(subscriptions);
        if (urgent == null) {
          return Text(
            AppStrings.subscriptionBadgeNone,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          );
        }
        return SubscriptionBadge(subscription: urgent);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Subscription? _mostUrgent(List<Subscription> subscriptions) {
    if (subscriptions.isEmpty) return null;
    final sorted = List<Subscription>.from(subscriptions)..sort((a, b) {
      if (a.isExpiringSoon && !b.isExpiringSoon) return -1;
      if (!a.isExpiringSoon && b.isExpiringSoon) return 1;
      final aR = a.remainingLessons ?? a.daysUntilExpiration ?? 999;
      final bR = b.remainingLessons ?? b.daysUntilExpiration ?? 999;
      return aR.compareTo(bR);
    });
    return sorted.first;
  }
}
```

- `_buildSubscriptionBadge`·`_buildNoSubscriptionBadge`·`_formatBadgeLabel` 삭제(시각 로직 위임으로 제거).
- **import (필수)**: `SubscriptionBadge`는 `subscription_ui_facade.dart`에만 export됨 → 래퍼에 `import '../../../subscription/subscription_ui_facade.dart';` **추가**. 기존 `subscription_facade.dart` import(Subscription·provider)는 유지. (`subscription_facade.dart`에는 `SubscriptionBadge` 없음 — 이것만 쓰면 컴파일 break.)
- 하드코딩 한글 전부 제거(AppStrings 이관 확인). `ClassTypeFilter` enum은 유지(S1 무관).

- [ ] **Step 4: 테스트 + analyze + 하드코딩 grep**

Run:
```bash
cd frontend && flutter test test/features/students/presentation/widgets/student_subscription_badge_test.dart \
  && flutter analyze lib/features/students/presentation/widgets/student_subscription_badge.dart \
  && grep -n "Text('[가-힣]" lib/features/students/presentation/widgets/student_subscription_badge.dart || echo "하드코딩 0"
```
Expected: PASS, 0 이슈, 하드코딩 한글 0.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/features/students/presentation/widgets/student_subscription_badge.dart frontend/test/features/students/presentation/widgets/student_subscription_badge_test.dart
git commit -m "refactor(students): MiniBadge를 SubscriptionBadge 위임 래퍼로 축소 + StudentClassBadge 삭제

Directive: 학생탭 배지는 데이터 해석+빈상태만, 시각은 정본 SubscriptionBadge 위임 — 중복 0
Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Signed-off-by: 🐙 Autopus <noreply@autopus.co>"
```

---

## Task 5: cross-view 일관성 회귀 + smoke (Red-Green)

**Files:**
- Test: `test/features/subscription/presentation/widgets/subscription_badge_test.dart` (회귀 group 추가)

- [ ] **Step 1: cross-view 회귀 테스트 작성**

동일 `Subscription` fixture가 어떤 surface든 동일 라벨·색을 내는지 단언 (결함 재발 방지). 통일 배지는 입력이 같으면 출력이 같음을 보장하므로, 핵심은 "학생탭 경로(위임)와 홈 경로(직접)가 동일 위젯"임을 고정:

```dart
testWidgets('회귀: 같은 수강권 → 홈 직접 / 학생탭 위임 동일 라벨', (tester) async {
  final sub = _makeSub(type: SubscriptionType.package, remaining: 7, total: 10);
  // 홈 경로
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SubscriptionBadge(subscription: sub))));
  expect(find.text('7/10회'), findsOneWidget); // 잔여, 사용([3/10]) 아님
  expect(find.text('[3/10]'), findsNothing);
});

testWidgets('smoke: 좁은 Row 제약에서 렌더 예외 없음', (tester) async {
  final sub = _makeSub(type: SubscriptionType.package, remaining: 7, total: 10);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: Row(children: [
    const Expanded(child: SizedBox()),
    SubscriptionBadge(subscription: sub),
  ]))));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Red-Green 확인**

Run: `cd frontend && flutter test test/features/subscription/presentation/widgets/subscription_badge_test.dart`
Expected: PASS. (회귀 검증: Task 2 이전 코드로 되돌리면 `[3/10]` 분기가 없으므로 학생탭 used 표기 결함은 위임으로 이미 차단됨을 확인.)

- [ ] **Step 3: Commit**

```bash
git add frontend/test/features/subscription/presentation/widgets/subscription_badge_test.dart
git commit -m "test(subscription): cross-view 일관성 회귀 + 좁은 제약 smoke

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
Signed-off-by: 🐙 Autopus <noreply@autopus.co>"
```

---

## Task 6: 전체 검증 + merge 준비

- [ ] **Step 1: 영향 도메인 전체 테스트**

Run: `cd frontend && flutter test test/features/subscription test/features/students test/features/home`
Expected: 전부 PASS (삭제 위젯 참조로 인한 컴파일 에러 0).

- [ ] **Step 2: 전체 analyze**

Run: `cd frontend && flutter analyze`
Expected: 변경 파일 0 이슈 (기존 baseline 대비 신규 경고 없음).

- [ ] **Step 3: 하드코딩 한글 회귀 grep**

Run: `cd frontend && grep -rn "Text('[가-힣]" lib/features/subscription/presentation/widgets/subscription_badge.dart lib/features/students/presentation/widgets/student_subscription_badge.dart`
Expected: 출력 없음.

- [ ] **Step 4: 성공 기준 체크리스트 대조**

스펙 §7 7개 기준을 코드로 확인 후, merge 핸드오프. PR 본문에 before/after(목업 서버 캡처 또는 설명) 첨부. `Closes` 없음(이슈 미생성 — 필요 시 생성).

---

## 검증 게이트 (merge 전)

- `flutter test test/features/{subscription,students,home}` 전부 green
- `flutter analyze` 신규 이슈 0
- 하드코딩 한글 grep 0
- 시각·상태 로직이 `SubscriptionBadge` 단일 위젯에만 존재 (래퍼 grep 으로 색/라벨 분기 0 확인)
- frontend-verify: 홈 레슨카드 + 학생탭 실기 스크린샷 1회(데스크탑+모바일) — 동일 배지 확인

## 후속 (별도 이슈, 본 플랜 범위 외)

S2 AcademyOwnershipBadge wiring(#391) · S3 lifetime_promo refit · S4 vacation 배너 정합. 스펙 §9 참조.
