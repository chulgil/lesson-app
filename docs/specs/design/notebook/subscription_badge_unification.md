# S1 — 수강권 잔여 배지 통일 (Subscription Badge Unification)

> 작성: 2026-06-14
> 상태: 설계 확정 (구현 대기)
> 출처: [token_drift_remediation.md](./token_drift_remediation.md) §8 항목 5 — 실측 재진단 후 분리
> SSOT 관계: [README.md](./README.md) §1.3.1(각진)·§1.2(시그니처) 토큰 준수. 본 문서는 S1 슬라이스 설계 계약.

## 1. 한 줄 결론

홈 레슨카드와 학생탭이 **같은 학생의 같은 수강권**을 모순된 숫자·색·형태로 표시하는 cross-view 일관성 결함을, **정본 위젯 1개(`SubscriptionBadge`)가 시각·상태 로직을 독점**하고 학생탭 래퍼는 데이터 해석만 담당하는 구조로 제거한다.

## 2. 배경 — 발견된 결함 (2026-06-14 실측)

동일 수강권(회차권 10회 중 3사용=7잔여, 정상)이 화면마다 다르게 보임:

| 차원 | 홈 (`SubscriptionBadge`) | 학생탭 (`StudentSubscriptionMiniBadge`) | 충돌 |
|------|------|------|------|
| 숫자 | `7/10회` (**잔여**) | `[3/10]` (**사용**) | 7 ≠ 3 |
| 정상 색 | inkSecondary (중립) | paperOk (**녹색**) | 의미색 불일치 |
| 만료 색 | inkTertiary (약) | paperAccent (강) | 경고 강도 정반대 |
| 형태 | 1px 사각 박스 | 박스 없는 인라인 | 시각 단위 불일치 |
| 상태 수 | 3 | 4 (+입금대기) | 홈은 입금대기 미처리 |
| 입력 | `Subscription` 엔티티 | `studentId` + provider | 계약 불일치 |

프로젝트 규칙 #17(멀티 뷰 색상 일관성) 위반. token drift(각진/평면)와 무관한 **위젯 dedup + 표현 통일** 문제.

## 3. 범위

**In (S1):**
- `SubscriptionBadge`를 정본으로 확립 — 통일 상태 모델·색·라벨·형태 소유.
- `StudentSubscriptionMiniBadge`를 얇은 래퍼로 축소 — 데이터 해석 + 빈 상태만, 렌더는 위임.
- 죽은 형제 위젯 삭제: `StudentClassBadge`, `SubscriptionProgressMini`, `SubscriptionSummaryText`.
- 하드코딩 한글 라벨 → `AppStrings` 이관.

**Out (후속 이슈로 분리):**
- S2: `AcademyOwnershipBadge` wiring(#391 완성) + Notebook 잉크 재피부.
- S3: `lifetime_promo_banner` ③ refit (paperAccent fill → NotebookBanner/Card).
- S4: `availability_vacation_banner` → NotebookBanner 채택 검토.

## 4. 통일 배지 사양

### 4.1 상태 모델 (우선순위 — 위에서 첫 일치)

| 순위 | 상태 | 트리거 | 색 | 아이콘 | 라벨 |
|------|------|--------|-----|--------|------|
| 1 | 입금대기 | `subscription.isUnpaid` | alert | warning | `AppStrings.subscriptionBadgeUnpaid` (입금대기) |
| 2 | 만료 | `status == expired` **또는** monthly `daysUntilExpiration <= 0` | alert | warning | `AppStrings.statusExpired` (만료, 기존 재사용) |
| 3 | 임박 | `isExpiringSoon` | alert | clock | §4.2 타입 라벨 |
| 4 | 정상 | (else) | neutral | 없음 | §4.2 타입 라벨 |

> 만료 가드: monthly는 `daysUntilExpiration`가 음수일 수 있으므로(`endDate - now`), status가 active로 남아도 `<= 0`이면 순위 2(만료)로 처리 — 기존 `subscription_badge.dart`의 `days > 0 ? 'D-$days' : statusExpired` 가드를 상태 모델로 승격. `D-0`/`D--3` 출력 금지.

- `alert` = `AppColors.paperAccent` (테두리·텍스트·아이콘 동색)
- `neutral` = `AppColors.inkSecondary` (테두리·텍스트)

### 4.2 타입 라벨 (정상·임박 공통)

| 타입 | 라벨 | 소스 |
|------|------|------|
| package | `{remaining}/{total}회` (**잔여**) | `AppStrings.subscriptionPackageBadgeFormat(remainingLessons, totalLessonsForDisplay)` |
| monthly | `D-{daysUntilExpiration}` | `AppStrings.subscriptionBadgeDday(daysUntilExpiration)` (신설) |
| trial | `체험중` | `AppStrings.subscriptionTypeTrial` |
| monthly (만료/<=0) | (§4.1 순위 2로 처리) | `AppStrings.statusExpired` |

> 잔여 표기로 확정. **홈(`SubscriptionBadge`)은 이미 `subscriptionPackageBadgeFormat`(잔여)로 올바름 — 무변경.** 결함은 학생탭의 `[used/total]`(사용) 단 하나이며, 래퍼가 정본에 위임하면서 자동으로 잔여로 전환됨.

### 4.3 형태 (티켓 스탬프)

- 컨테이너: `Container(padding: symmetric(horizontal: space2, vertical: 2), decoration: BoxDecoration(border: Border.all(color: <state>, width: 1)))` — 각진(borderRadius 없음, §1.3.1 준수).
- 텍스트: `GoogleFonts.ibmPlexMono(fontSize: 10, w600, letterSpacing: 0.5, color: <state>)`.
- 아이콘: 상태 아이콘만, `size: 11, color: <state>`, 텍스트 앞 `space1` 간격. 정상 상태는 아이콘 없음.
- 기존 `showIcon` 파라미터 **제거** — 아이콘은 상태가 결정(타입 아이콘 폐기, 홈은 이미 `showIcon:false`).
- Notebook 아이콘 정책: `subscription_badge.dart`는 시그니처 영역(*_stamp/*_masthead/notebook/) 아님 → Material `Icons.access_time`·`Icons.warning_amber_rounded` 허용.

### 4.4 빈 상태 (래퍼 전용)

- 트리거: 학생의 활성 수강권 0건.
- 표현: 박스 없는 회색 텍스트 `AppStrings.subscriptionBadgeNone` (수강권 없음), `AppColors.inkTertiary`.
- 홈 레슨카드는 항상 수강권 존재 → 빈 상태 미발생. 빈 상태 책임은 래퍼에만.

## 5. 아키텍처

```
SubscriptionBadge (subscription/presentation/widgets) — 정본 presentational
  입력: Subscription (non-null)
  소유: 상태 모델(§4.1) · 색 · 아이콘 · 라벨(§4.2) · 박스 형태(§4.3)
  무상태 StatelessWidget. provider/Ref 의존 없음.

StudentSubscriptionMiniBadge (students/presentation/widgets) — 얇은 래퍼 ConsumerWidget
  입력: studentId
  책임: activeStudentSubscriptionsProvider 구독 → 최긴급 수강권 해석(_getMostUrgentSubscription 유지)
        · 0건이면 빈 상태(§4.4) 렌더
        · 1건+ 이면 SubscriptionBadge(subscription: urgent) 위임 (시각 0줄)
```

- flutter-architecture 준수: 라벨·색 변환은 presentation(`SubscriptionBadge`)에만. `Subscription` 엔티티에 표시 getter 추가 금지.
- i18n-l10n 준수: 모든 사용자 노출 문자열은 `AppStrings`. domain/data는 AppStrings 미의존(영향 없음 — 양쪽 다 presentation).
- 홈(`lesson_card`)은 기존대로 `SubscriptionBadge(subscription:)` 직접 호출 → 입금대기 상태 자동 획득(덤 수정).

## 6. 삭제 · 이관

| 대상 | 처리 | 동반 |
|------|------|------|
| `StudentClassBadge` | 삭제 | #42 클래스 그룹 헤더로 대체됨, 0 refs |
| `SubscriptionProgressMini` | 삭제 | 0 refs (테스트 포함) |
| `SubscriptionSummaryText` | 삭제 | 0 production, 테스트 동반 삭제 |
| 하드코딩 한글 (`입금대기(후불)`·`만료됨`·`수강권 없음`·`월정액`·`체험중`) | `AppStrings` 신설/재사용 | i18n 위반 해소 |

신설 AppStrings 키: `subscriptionBadgeUnpaid`(입금대기), `subscriptionBadgeDday(int)`(=`'D-$days'`, 기존 인라인 리터럴 형식화), `subscriptionBadgeNone`(수강권 없음). 재사용(신설 금지): `statusExpired`(만료), `subscriptionPackageBadgeFormat`(잔여), `subscriptionTypeTrial`(체험중).

## 7. 성공 기준 (Acceptance Criteria)

1. 홈 레슨카드와 학생탭이 동일 수강권에 대해 **동일한 숫자·색·형태** 렌더 (cross-view 일관성).
2. 모든 패키지 수강권 숫자는 **잔여** 표기 (`{remaining}/{total}회`).
3. 정상=중립 잉크, 조치 필요(입금대기·만료·임박)=버밀리온+아이콘.
4. 입금대기 상태가 홈·학생탭 양쪽에서 표시됨 (기존 홈 누락 해소).
5. `StudentClassBadge`·`SubscriptionProgressMini`·`SubscriptionSummaryText` 코드·테스트 제거 후 `flutter analyze` 0 에러.
6. 사용자 노출 한글 문자열 하드코딩 0건 (`grep "Text('[가-힣]"` 통과).
7. 시각·상태 로직이 `SubscriptionBadge` 단일 위젯에만 존재 (래퍼에 중복 0줄).

## 8. 테스트 계획

- **SubscriptionBadge 상태 매트릭스** (`subscription_badge_test.dart` 갱신): 4 상태 × 3 타입 → 색·라벨·아이콘 검증. 입금대기 케이스 신규.
- **래퍼 위임 테스트** (`student_subscription_badge_test.dart`): 0건→빈 상태, 1건+→`SubscriptionBadge` 렌더(`find.byType(SubscriptionBadge)`), 최긴급 선택 로직.
- **cross-view 일관성 회귀**: 동일 `Subscription` fixture를 두 surface에 주입 → 동일 라벨·색 출력 단언 (결함 재발 방지 — Red-Green).
- **widget smoke**: 통일 배지 pump + `takeException() isNull` (좁은 제약 Row 컨텍스트 포함).
- 삭제 위젯 테스트 제거: `subscription_badge_test.dart`의 `SubscriptionSummaryText` group(현 L126~159) · `SubscriptionProgressMini`(존재 시) 제거. `academy_ownership_badge_test.dart`는 S2로 이관(삭제 아님). 제거 후 `flutter test` 컴파일 통과 확인.

## 9. 후속 이슈 (S2~S4 요약)

| # | 제목 | 핵심 |
|---|------|------|
| S2 | 학원 귀속 배지 wiring (#391 완성) | `AcademyOwnershipBadge`를 `subscription_card`에 ownership==academy 조건 노출 + profileBlue → 잉크 토큰 재피부 + smoke |
| S3 | lifetime_promo 배너 refit | paperAccent fill → NotebookBanner(①) 또는 NotebookCard(②) 중 택1, smoke 동반 |
| S4 | vacation 배너 정합 | `availability_vacation_banner` → NotebookBanner 채택 검토 (시각 변경 동반, 사용자 확인) |

## 10. 참조

- 정의 SSOT: [README.md](./README.md) §1.3.1·§1.2
- 상위 추적: [token_drift_remediation.md](./token_drift_remediation.md) §8
- 정본 위젯: `frontend/lib/features/subscription/presentation/widgets/subscription_badge.dart`
- 래퍼: `frontend/lib/features/students/presentation/widgets/student_subscription_badge.dart`
- 계약 테스트: `frontend/test/architecture/notebook_design_contract_test.dart`
