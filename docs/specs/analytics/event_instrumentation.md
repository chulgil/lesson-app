# 계측 이벤트 정의서 (Event Instrumentation)

> 작성일: 2026-07-28
> 상태: 활성 (이벤트 정의 SSOT)
> 관련: [event_tracking_spec.md](./event_tracking_spec.md) (수집 인프라), [paywall_spec.md](../subscription/paywall_spec.md) (흐름 B 과금), [subscription_renewal_spec.md](../subscription/subscription_renewal_spec.md) (흐름 A 갱신 제안)
> Refs: #1210 (본 정의서), #1209 (퍼널 계측 구현)

---

## 0. 범위와 경계

수익화 판단에 필요한 **이벤트 이름 · 속성 · 발화 지점 · KPI 산식**을 확정한다. 대시보드가 숫자를 잘못 읽지 않도록 정의를 코드보다 먼저 고정하는 것이 목적이다.

analytics 도메인의 문서 3종은 역할이 다르다. 충돌 시 아래 소관을 따른다.

| 문서 | 소관 | 본 문서와의 관계 |
|------|------|-----------------|
| [event_tracking_spec.md](./event_tracking_spec.md) | 수집 **인프라** — 패키지 도입, 초기화, 동의(옵트아웃), 사용자 권리, 백엔드 적재 | 본 문서가 정의한 이벤트를 **어떻게 보낼지** |
| **event_instrumentation.md** (본 문서) | 이벤트 **정의** — 이름, 속성, 발화 지점, 구현 상태, KPI 산식 | **무엇을 언제 쏘고 어떻게 읽을지** |
| [analytics_dashboard_spec.md](./analytics_dashboard_spec.md) | 인앱 학생 진도 대시보드 (사용자 노출 화면) | 무관 — 사내 지표가 아닌 제품 기능 |

**현재 구현 상태 (2026-07-28 기준)**: `firebase_analytics` 미설치, 계측 코드 0건. 본 문서와 #1209 가 첫 배선이다.

---

## 1. 계측 원칙

| 원칙 | 내용 |
|------|------|
| **Fire-and-forget** | 이벤트 전송을 `await` 하지 않는다. 계측이 사용자 동작을 지연시키지 않는다. |
| **실패 무시** | 전송 실패는 `try/catch` 로 삼키고 앱 로직에 영향을 주지 않는다. 계측 실패로 결제/저장이 막히면 안 된다. |
| **PII 미포함** | 이벤트 속성에 개인정보를 넣지 않는다 (아래 §1.1). |
| **단일 발화** | 같은 사용자 행동을 프론트와 백엔드에서 이중 발화하지 않는다. 발화 주체를 §3, §4 표에 1곳으로 고정한다. |
| **정의 우선** | 이벤트를 코드에 먼저 넣지 않는다. 본 문서 갱신 후 구현한다 (§6.2). |

### 1.1 PII 금지 (HARD-GATE)

이벤트 속성에 **절대 포함하지 않는다**:

- 사용자/학생/학부모의 이름, 이메일, 전화번호, 주소
- 레슨 노트 본문, 채팅 메시지 본문
- 결제 카드 정보, 계좌번호
- 학생이 식별되는 자유 입력 문자열

대신 **익명 메타데이터만** 보낸다: 존재 여부(`has_note: bool`), 개수(`student_count: int`), 분류값(`method: "qr"`), 해시된 ID.

> 상세 등급과 역할별 접근 규칙은 `.claude/rules/data-privacy.md`. 수집 동의·사용자 권리는 [event_tracking_spec.md](./event_tracking_spec.md) §7.

---

## 2. 네이밍 컨벤션

| 대상 | 규칙 | 예 |
|------|------|-----|
| 이벤트명 | `snake_case`, 동사 과거형으로 끝냄 (완료된 사실 기록) | `trial_started`, `lesson_completed` |
| 속성명 | `snake_case`, 단위가 모호하면 단위를 이름에 포함 | `duration_min`, `days_inactive` |
| 도메인 접두 | 도메인 경계가 모호한 이벤트만 접두 사용 | `paywall_limit_reached` |
| bool 속성 | `is_` / `has_` / `from_` 접두 | `is_demo`, `has_note`, `from_trial` |

**금지**: camelCase, 한글 이벤트명, 이벤트명에 값 포함 (`upgrade_to_pro` 대신 `subscription_upgraded` + `plan: "pro"`).

---

## 3. 수익화 퍼널 (#1209 구현)

무료 한도 차단부터 유료 결제까지 3단계. 이 3종이 없으면 "한도에 막힌 사용자 중 몇 %가 결제하는가"를 답할 수 없다.

### 3.1 이벤트 정의

| 이벤트 | 속성 | 트리거 | 발화 지점 |
|--------|------|--------|----------|
| `paywall_limit_reached` | `plan` (string), `student_count` (int) | Free 플랜 학생 수 한도(5명)에 막혀 `FreeLimitSheet` 노출 | `frontend/lib/features/billing/presentation/utils/billing_guard_actions.dart` |
| `trial_started` | `plan` (string) | 14일 Pro 체험 개시 성공 | 같은 파일 `handleStartTrial` |
| `subscription_upgraded` | `plan` (string), `from_trial` (bool) | IAP 구매 + 영수증 검증 성공 | 같은 파일 `handleBuyPro` |

**속성 값 규약**

- `plan`: 발화 시점의 현재 플랜 (`free` / `pro` / `studio` / `lifetime`). `subscription_upgraded` 에서는 **구매한** 플랜.
- `student_count`: 차단 시점의 보유 학생 수. 한도(5)와 같아야 정상이며, 초과값은 가드 우회 버그 신호다.
- `from_trial`: 체험 상태(`status=trial`)에서 결제로 넘어왔는지. 체험 없이 바로 결제한 경우 `false`.

> 플랜 정의와 한도 수치의 SSOT 는 [paywall_spec.md](../subscription/paywall_spec.md) §1. 본 문서는 값을 복제하지 않고 참조한다.

### 3.2 퍼널 KPI 산식

| 지표 | 산식 | 읽는 법 |
|------|------|--------|
| 한도 도달률 | `paywall_limit_reached` 고유 사용자 / 활성 Free 강사 | 무료 한도가 실제로 압력을 만드는가 |
| 체험 개시율 | `trial_started` 고유 사용자 / `paywall_limit_reached` 고유 사용자 | 차단 화면이 체험으로 이어지는가 |
| 전환율 | `subscription_upgraded` 고유 사용자 / `trial_started` 고유 사용자 | 체험이 결제로 이어지는가 |
| 전체 전환율 | `subscription_upgraded` 고유 사용자 / `paywall_limit_reached` 고유 사용자 | 차단부터 결제까지 종단 효율 |

**측정 주의 (HARD-GATE)**

1. **모든 비율은 고유 사용자(unique user) 기준.** `paywall_limit_reached` 는 한 사용자가 학생 추가를 반복 시도하면 여러 번 발화한다. 이벤트 수로 나누면 분모가 부풀어 전환율이 실제보다 낮게 보인다.
2. **분모 기간과 분자 기간을 맞춘다.** 체험이 14일이므로 전환율은 최소 14일 지연이 있다. 같은 달 안에서 `trial_started` 와 `subscription_upgraded` 를 나누면 전환율이 과소 집계된다. 코호트(체험 개시 주차) 기준으로 본다.
3. **"활성 Free 강사"** 는 해당 기간 `app_opened` 가 1회 이상이면서 `plan=free` 인 사용자로 정의한다. 가입만 하고 미사용인 계정을 분모에 넣지 않는다.

---

## 4. 핵심 이벤트 10종

| 이벤트 | 속성 | 의미 | 구현 상태 |
|--------|------|------|----------|
| `onboarding_completed` | `step`, `duration_sec` | 온보딩 완료 | backlog |
| `student_added` | `is_demo`, `method` | 학생 추가 | **#1209 구현** (속성 없이 발화 — 생성 notifier 에서 진입점 구분 불가, `is_demo`/`method` 는 backlog) |
| `lesson_completed` | `duration`, `has_note` | 레슨 완료 | backlog |
| `practice_started` | `tool` (metronome/tuner/record) | 연습 시작 | backlog |
| `subscription_upgraded` | `plan`, `trial` | 유료 전환 (퍼널과 동일 이벤트) | **#1209 구현** |
| `invite_shared` | `channel` (kakao/url/qr) | 초대 공유 | backlog |
| `feature_used` | `name` | 기능 사용 | backlog |
| `app_opened` | `session_count` | 앱 열기 | **#1209 구현** (속성 없이 발화 — `session_count` 는 backlog) |
| `review_prompted` | `result` (yes/no/dismiss) | 리뷰 요청 | backlog |
| `churn_risk` | `days_inactive`, `last_action` | 이탈 위험 | backlog (백엔드 발화) |

`paywall_limit_reached` 와 `trial_started` 는 위 10종에 포함되지 않는 퍼널 전용 추가 이벤트다 (§3).

### 4.1 표기 미확정 항목 (구현 전 확정 필요)

[event_tracking_spec.md](./event_tracking_spec.md) §3.1 과 본 문서의 표기가 다른 항목이다. **아직 구현된 코드가 없으므로 이름이 고정되지 않았다.** 각 이벤트를 실제 배선하는 시점에 아래 중 하나를 택하고 두 문서를 같은 커밋에서 일치시킨다.

| 이벤트 | event_tracking_spec.md 표기 | 본 문서 표기 | 권고 |
|--------|----------------------------|-------------|------|
| 이탈 위험 | `churn_risk_detected` | `churn_risk` | 미정 |
| 레슨 소요 | `duration_min` | `duration` | `duration_min` — §2 단위 명시 규칙 |
| 전환 체험 여부 | `was_trial` | `from_trial` | `from_trial` — #1209 구현 확정값 |
| 전환 매출 | `mrr_delta` | (없음) | 미정 — IAP 금액은 스토어 콘솔에서 확인 가능 |

> `subscription_upgraded` 의 체험 속성은 #1209 가 `from_trial` 로 구현하므로 **`from_trial` 이 확정값**이다. §3.1 을 따른다. 위 표의 `trial` 표기는 §4 표의 축약이며 실제 속성명이 아니다.

---

## 5. KPI 정의 주의 — 재구매율 (HARD-GATE)

### 5.1 "갱신율" 을 지표명으로 쓰지 않는다

**수강권에는 자동 갱신이 없다.** 학생이 선생님에게 내는 수강료는 앱 밖에서 무통장입금/현금으로 처리되고, 매 수강권마다 선생님이 제안하고 학생이 수락하고 입금하는 **수동 재결제**다. 자동 갱신 구독의 "갱신율"(가만히 두면 유지되는 비율)과는 분모·분자의 의미가 다르다.

넷플릭스는 해지하지 않으면 유지되지만, 수강권은 매번 새로 사야 한다. 전자의 이탈은 "해지 행동"이고 후자의 이탈은 "아무것도 안 함"이다. 같은 85%라도 난이도가 전혀 다르다.

| 표현 | 사용 |
|------|------|
| 갱신율 (renewal rate) | 지표명으로 **금지** — 자동 갱신을 전제하는 용어 |
| **재구매율 (re-purchase rate)** | 수강권 지표의 **공식 명칭** |

> **주의**: 도메인 용어로서의 "갱신 제안"([subscription_renewal_spec.md](../subscription/subscription_renewal_spec.md) 의 `SubscriptionRenewalService`, 사용자 노출 문구 "갱신")은 그대로 유지한다. 금지 대상은 **지표 이름**으로서의 "갱신율" 이다. 기능명은 갱신 제안, 측정값은 재구매율.

### 5.2 재구매율 정의

```
재구매율 = 만료 후 N일 내 신규 수강권 결제가 확인된 학생 수
           / 해당 기간에 수강권이 만료(소진)된 학생 수
```

| 파라미터 | 기본값 | 근거 |
|----------|--------|------|
| N (관측 창) | 30일 | 주 1회 레슨 기준 약 4주. 창을 좁히면 정상 재등록을 이탈로 오판한다. |
| 만료 기준 | 잔여 0회 **또는** 만료일 경과 | 둘 중 먼저 오는 시점 |
| 결제 확인 시점 | 선생님의 **입금 확인 처리** | 앱은 결제를 처리하지 않으므로 입금 확인이 앱이 관측 가능한 유일한 신호 |
| 동일 관계 한정 | 동일 선생님-학생 쌍 | 다른 선생님으로 옮긴 경우는 재구매가 아님 (이탈) |

**측정 한계 (반드시 함께 보고)**: 입금 확인은 선생님의 수동 조작이다. 선생님이 확인을 누르지 않거나 늦게 누르면 재구매율이 실제보다 낮게 나온다. 이 지표는 **선생님의 기록 성실도에 영향받는 하한값**이며, 정확도를 높이려면 입금 확인 UX 개선이 선행되어야 한다.

### 5.3 두 축 구분 — 수강권 vs 앱 구독

수익 축이 둘이고 결제 성격이 반대다. 대시보드에서 절대 합산하지 않는다.

| 구분 | 흐름 A — 수강권 (수강료) | 흐름 B — 앱 구독 (앱 사용료) |
|------|------------------------|---------------------------|
| 돈 내는 사람 | 학생/학부모 | 선생님/학원 |
| 받는 사람 | 선생님/학원 | Lessonaza |
| 결제 수단 | 무통장입금/현금 (앱 밖) | IAP (StoreKit2 / PlayBilling) |
| 자동 갱신 | **없음** | **있음** |
| 재결제 방식 | 선생님 제안 + 학생 수락 + 입금 | 스토어 자동 청구 |
| 모델 | `Subscription`, `SubscriptionProposal` | `AppBillingPlan` |
| 유지 지표 | **재구매율** (§5.2) | **갱신율/이탈률** (스토어 기준, 용어 사용 가능) |
| 계측 경로 | 백엔드 (입금 확인 시점) | `subscription_upgraded` + 스토어 콘솔 |

> 흐름 정의의 SSOT 는 [paywall_spec.md](../subscription/paywall_spec.md) §0. 본 문서는 지표 관점의 차이만 정리한다.

**대시보드 규칙**: "구독", "갱신", "MRR" 이라는 라벨이 붙은 지표는 **흐름 B 전용**이다. 흐름 A 수치를 같은 카드에 넣지 않는다. 흐름 A 는 "수강권", "재구매" 라벨을 쓴다.

---

## 6. 참고

### 6.1 데이터 위치

| 대상 | 위치 |
|------|------|
| 이벤트 원본 | Firebase Analytics 콘솔 (GA4 property) |
| 실시간 검증 | Firebase Analytics DebugView (배선 직후 확인용) |
| 장기 분석 | GA4 -> BigQuery 일일 export ([event_tracking_spec.md](./event_tracking_spec.md) §5.2) |
| 흐름 B 매출 | App Store Connect / Google Play Console (이벤트가 아닌 스토어 원장이 매출 SSOT) |
| 흐름 A 재구매 | 백엔드 DB (`subscriptions` 입금 확인 이력) — Firebase 아님 |

### 6.2 이벤트 추가 절차

```
1. 본 정의서에 이벤트 행 추가 (이름/속성/트리거/발화 지점/구현 상태)
2. 표기 충돌 확인 — event_tracking_spec.md §3.1 과 다르면 §4.1 에 기록하고 하나로 확정
3. 구현 (발화 지점 1곳, fire-and-forget)
4. DebugView 로 실제 발화 확인
5. 구현 상태 컬럼을 backlog -> 구현 으로 갱신
```

**역순 금지**: 코드에 이벤트를 먼저 넣고 문서를 나중에 맞추면, 대시보드가 정의 없는 숫자를 읽게 된다. 이름이 한번 데이터에 쌓이면 소급 변경 비용이 크다.

### 6.3 후속 과제

- [ ] `재구매율` 을 `.harness/knowledge/glossary.md` 에 등록 (신규 도메인 용어, glossary-sync 규칙)
- [ ] §4.1 표기 미확정 4건을 각 이벤트 구현 시점에 확정
- [ ] 흐름 A 재구매율의 백엔드 집계 쿼리 정의 (Firebase 경로 아님)
