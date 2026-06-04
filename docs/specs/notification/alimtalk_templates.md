# 카카오 알림톡 템플릿 — 입금 자동화 5종 (Alimtalk Templates)

> 작성일: 2026-06-01 (2026-06-04 — Phase 3 백엔드 구현 완료)
> 상태: **Phase 3 (백엔드) 완료** — Phase 2 (카카오 사업자/심사) 외부 선행 대기 중
> 출처: E2E 감사 Top 10 #2 E2-C2 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #423
> 관련 스펙: [kakao_alimtalk_spec.md](kakao_alimtalk_spec.md), [subscription_master.md §3·§4](../subscription/subscription_master.md), [notification_master.md](notification_master.md)
> 글로서리: [glossary.md](../../../.harness/knowledge/glossary.md) — "알림톡", "발신 프로필"

---

## 1. 문제 정의

E2E 감사 정량 입증: `grep alimtalk|LNZ_INVOICE backend/app/services/ frontend/lib/` = **0건**.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | 수강권 제안 후 입금 안내가 **앱 내부 알림에만 의존** | 학부모 미설치 → 도달률 0% |
| 2 | D+1·D+3·D+7 리마인드 자동 발송 채널 부재 | 학부모 망각 → 입금 누락 → E3 실패 |
| 3 | 입금 확인 후 학생/학부모 측 자동 안내 없음 | 신뢰 단절 — 학부모는 "받았는지" 불확실 |
| 4 | 5종 템플릿 본문·변수·정책이 코드 옆에 산재 | 템플릿 심사 변경 시 추적 어려움 |

> kakao_alimtalk_spec.md §4 에는 `LNZ_INVOICE`·`LNZ_PAYMENT_CONFIRM` 만 정의되어 있고, D+N 리마인드 3종이 누락되어 있다.

### 1.2 영향 범위 (펀넬)

E1 (수강권 제안 송신) → E2 (입금 추적) → E3 (입금 확인) 전 구간.
카톡 채널 도달률 ~95% vs 우리 현재 0% — 입금 회수율 직격.

### 1.3 범위 명시 — 송금 자동화 아님

> **본 스펙은 송금 자동화를 포함하지 않는다.**
>
> lesson-app 원칙 (`subscription_master.md §1.2`): **"돈은 앱 밖에서, 상태는 앱 안에서"**
>
> - 학부모는 외부 무통장입금/계좌이체 그대로 송금
> - 선생님은 통장에서 입금 확인 후 앱에서 [입금 확인] 1탭
> - 본 스펙은 **알림 발송·리마인드 자동화**만 다룸
> - 카드 결제·Stripe·토스·카카오페이 등 PG 도입은 **명시적으로 거절됨** (`subscription/payment_architecture.md §1`)

---

## 2. 설계 원칙

> **"학부모가 카톡으로 받지 않으면 입금은 일어나지 않는다."**

| 원칙 | 의미 |
|---|---|
| 단일 발신 프로필 | 모든 입금 관련 5종 템플릿은 동일 발신 프로필 사용 — 사용자 인식 일관성 |
| 본문 90자 이내 | 카카오 정보성 메시지 가이드 준수 + 미리보기 절단 방지 |
| 변수 최소화 | 각 템플릿은 6개 이하 변수 — 심사 통과율 + 치환 오류 감소 |
| 발신 가능 시간 준수 | 08:00-20:00 (한국 카카오 정책) — 야간 자동 지연 큐 |
| 실패 폴백 보장 | 알림톡 실패 → 앱 푸시 → SMS 순차 — 학생측 도달성 보장 |

---

## 3. 템플릿 5종 정의

### 3.1 발송 트리거 매핑

| 템플릿 | 트리거 | 대상 | 우선순위 |
|---|---|---|---|
| `LNZ_INVOICE` | E1 송신 직후 (`SubscriptionProposal.status = paymentRequested`) | 학생/학부모 | CRITICAL |
| `LNZ_PAYMENT_REMINDER_D1` | E1 송신 후 +1일 자동 cron | 학생/학부모 | HIGH |
| `LNZ_PAYMENT_REMINDER_D3` | E1 송신 후 +3일 자동 cron | 학생/학부모 | HIGH |
| `LNZ_PAYMENT_REMINDER_D7` | E1 송신 후 +7일 만료 직전 cron | 학생/학부모 | CRITICAL |
| `LNZ_PAYMENT_CONFIRM` | 선생님 [입금 확인] 직후 (`status = paymentConfirmed`) | 학생/학부모 | CRITICAL |

### 3.2 LNZ_INVOICE — 수강권 제안 + 입금 안내

**본문** (변수 치환 후 약 88자):

```
[레슨나자] #{studentName} 학생 수강료 안내

#{teacherName} 선생님
금액: #{amount}원
계좌: #{bankAccount}
만료: #{dueDate}
```

| 항목 | 값 |
|---|---|
| 변수 | `studentName`, `teacherName`, `amount`, `bankAccount`, `dueDate` (5개) |
| 버튼 | [앱에서 확인] — 딥링크 `lessonaza://subscription/proposal/{proposalId}` |
| 심사 분류 | 결제 안내 (정보성) |
| Fallback | 앱 푸시 → SMS LMS |
| 발송 가능 시간 | 08:00-20:00 (CRITICAL 도 본 알림은 학부모 휴식시간 배려) |

### 3.3 LNZ_PAYMENT_REMINDER_D1 — 입금 D+1 리마인드

**본문** (변수 치환 후 약 76자):

```
[레슨나자] 입금 확인 대기 안내

#{studentName} 학생 수강료
금액: #{amount}원
계좌: #{bankAccount}
```

| 항목 | 값 |
|---|---|
| 변수 | `studentName`, `amount`, `bankAccount` (3개) |
| 버튼 | [입금 정보 보기] — 딥링크 `lessonaza://subscription/proposal/{proposalId}` |
| 심사 분류 | 결제 안내 (정보성) |
| Fallback | 앱 푸시 |
| 발송 가능 시간 | 08:00-20:00 |

### 3.4 LNZ_PAYMENT_REMINDER_D3 — 입금 D+3 리마인드

**본문** (변수 치환 후 약 85자):

```
[레슨나자] 입금 확인 안 됨 — D+3

#{studentName} 학생 수강료
금액: #{amount}원
만료까지: #{daysLeft}일
```

| 항목 | 값 |
|---|---|
| 변수 | `studentName`, `amount`, `daysLeft` (3개) |
| 버튼 | [입금 정보 보기] — 딥링크 `lessonaza://subscription/proposal/{proposalId}` |
| 심사 분류 | 결제 안내 (정보성) |
| Fallback | 앱 푸시 → SMS |
| 발송 가능 시간 | 08:00-20:00 |

### 3.5 LNZ_PAYMENT_REMINDER_D7 — 입금 D+7 만료 직전

**본문** (변수 치환 후 약 89자):

```
[레슨나자] 오늘 만료 — 마지막 안내

#{studentName} 학생 수강료
금액: #{amount}원
오늘 자정 만료
```

| 항목 | 값 |
|---|---|
| 변수 | `studentName`, `amount` (2개) |
| 버튼 | [입금 정보 보기] — 딥링크 `lessonaza://subscription/proposal/{proposalId}` |
| 심사 분류 | 결제 안내 (정보성) |
| Fallback | 앱 푸시 → SMS (CRITICAL — 마지막 도달 시도) |
| 발송 가능 시간 | 08:00-20:00 |

### 3.6 LNZ_PAYMENT_CONFIRM — 입금 확인 완료

**본문** (변수 치환 후 약 84자):

```
[레슨나자] 입금 확인 완료

#{studentName} 학생 수강권 발급
횟수: #{lessonCount}회
유효: #{endDate}까지
```

| 항목 | 값 |
|---|---|
| 변수 | `studentName`, `lessonCount`, `endDate` (3개) |
| 버튼 | [수강권 보기] — 딥링크 `lessonaza://subscription/{subscriptionId}` |
| 심사 분류 | 결제 안내 (정보성) |
| Fallback | 앱 푸시 |
| 발송 가능 시간 | 08:00-20:00 |

---

## 4. 발신 프로필 정책

### 4.1 단일 프로필

5종 모두 **동일 발신 프로필**을 사용한다.

| 항목 | 값 |
|---|---|
| 채널명 | "레슨나자" |
| SenderKey | `KAKAO_BIZ_SENDER_KEY` (단일 환경 변수) |
| 인증 상태 | 사업자 등록 + 채널 비즈니스 인증 완료 (선행 작업) |

분리 운영 (선생님별/학원별 채널) 은 본 스펙 범위 외. 추후 학원 모드 도입 시 별도 스펙.

### 4.2 발송 가능 시간

| 구간 | 처리 |
|---|---|
| 08:00-20:00 KST | 즉시 발송 |
| 20:00-08:00 KST | 큐에 적재 후 다음 08:00 일괄 발송 |

> 카카오 알림톡(정보성) 자체는 24시간 발송 가능하나, **사용자 경험 보호를 위해 앱 자체 제한**.
> 단, `LNZ_PAYMENT_REMINDER_D7` 의 만료 임박 (오늘 자정) 케이스는 야간이라도 즉시 발송 허용 (예외 1건).

---

## 5. 실패 폴백 정책

알림톡 발송 실패 시 채널 순차 폴백:

```
알림톡 시도 → 실패 (수신거부/미가입/API 오류)
   ↓
앱 푸시 (FCM) 시도 → 실패 (앱 미설치/알림 차단)
   ↓
SMS (CRITICAL 만) → 발송 또는 종료
```

| 알림 우선순위 | SMS 폴백 |
|---|---|
| CRITICAL (`LNZ_INVOICE`, `LNZ_PAYMENT_REMINDER_D7`, `LNZ_PAYMENT_CONFIRM`) | 발송 |
| HIGH (`LNZ_PAYMENT_REMINDER_D1`, `LNZ_PAYMENT_REMINDER_D3`) | 미발송 (앱 푸시 실패 시 종료) |

### 5.1 카카오 오류 코드 처리

`kakao_alimtalk_spec.md §6.1` 의 매핑 그대로 사용:

| 오류 범위 | 처리 |
|---|---|
| 2000~2999 (수신자 오류) | 앱 푸시 폴백 |
| 7000~7999 (수신 거부) | `phone_blocked = True` 저장, 이후 이 사용자 알림톡 발송 안 함 |
| 4000~4999 (템플릿 오류) | Slack 알람, 개발팀 조치 |
| 9000~ (서버/인증) | 재시도 큐 (최대 3회), 이후 앱 푸시 폴백 |

---

## 6. 비용 추정

### 6.1 단가

| 채널 | 단가 | 비고 |
|---|---|---|
| 알림톡 | 약 7원/건 (VAT 별도) | 사업자 협의 — 5~12원 범위 |
| SMS LMS 폴백 | 약 40~50원/건 | 90자 초과 시 LMS |
| 앱 푸시 (FCM) | 0원 | Firebase 무료 티어 |

### 6.2 예상 발송량 (선생님 1명 × 학생 10명)

| 시나리오 | 월 발송 | 월 비용 |
|---|---|---|
| `LNZ_INVOICE` (월 1회) | 10건 | 70원 |
| `LNZ_PAYMENT_REMINDER_D1` (입금 지연 50%) | 5건 | 35원 |
| `LNZ_PAYMENT_REMINDER_D3` (입금 지연 30%) | 3건 | 21원 |
| `LNZ_PAYMENT_REMINDER_D7` (입금 지연 10%) | 1건 | 7원 |
| `LNZ_PAYMENT_CONFIRM` (월 1회) | 10건 | 70원 |
| **합계 (1선생님 기준)** | **~29건/월** | **~203원/월** |
| 선생님 100명 환산 | ~2,900건/월 | ~20,300원/월 |

> 입금 회수율 +20-30% 개선 시 매출 증가가 비용을 압도. 정확한 단가는 사업자 계약 시 확정.

---

## 7. 의존성

### 7.1 선행 작업 (Blocker)

| 항목 | 담당 | 소요 |
|---|---|---|
| 카카오 비즈니스 사업자 등록 | 운영팀 | 1~3일 |
| 카카오톡 채널 비즈니스 인증 | 운영팀 | 3~7일 |
| 카카오 비즈메시지 딜러사 계약 (NHN Cloud/SOLAPI 등) | 운영팀 | 1~3일 |
| 5종 템플릿 카카오 심사 요청 | 개발팀 | 영업일 2~3일/템플릿 |

본 스펙의 코드 구현은 위 4개 선행 작업 완료 후 시작 가능.

### 7.2 후속 작업 (본 스펙 후)

- `kakao_alimtalk_spec.md §4` 에 본 5종 템플릿 인덱스 추가 (메인 세션이 처리)
- `subscription_master.md §3·§4` 에 본 5종 발송 트리거 명시 (메인 세션이 처리)
- `notification_master.md` 의 `notification_type` 매핑 테이블에 D+1/D+3/D+7 3종 추가
- `payment_tracking_dashboard.md` 의 [입금 대기] 카드 발송 액션과 연결

---

## 8. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 알림톡 발송 성공률 | `LNZ_INVOICE` 성공 / 시도 | ≥ 90% |
| 입금 회수율 | E1 송신 → E3 paymentConfirmed | 현재 추정 대비 +20-30% |
| 만료율 (D+7 까지 미입금) | expired / E1 전체 | < 10% |
| 야간 발송 지연 만족도 | 사용자 불만 건수 | < 1% (앱 내 신고) |
| 수신 거부율 | `phone_blocked = True` 누적 / 발송 사용자 | < 5% |

---

## 9. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업) — DONE

- 본 파일 작성
- glossary 에 "알림톡", "발신 프로필", "입금 대기" 추가 (메인 세션)
- `kakao_alimtalk_spec.md §4` 인덱스 갱신 (메인 세션)

### Phase 2: 카카오 사업자/심사 (2주, 운영팀 주도) — 외부 대기

- 사업자 등록, 채널 인증, 딜러사 계약
- 5종 템플릿 등록 및 심사 요청

### Phase 3: 백엔드 (1-2주) — DONE (2026-06-04)

- [x] 5종 발송 트리거
  - [x] `subscription_service.py` 에 `LNZ_INVOICE` 즉시 발송 (line 1399)
  - [x] `subscription_service.py` 에 `LNZ_PAYMENT_CONFIRM` 즉시 발송 (line 821)
  - [x] cron `LNZ_PAYMENT_REMINDER_D1/D3/D7` (`backend/app/jobs/payment_reminder_jobs.py`)
- [x] 발신 가능 시간 게이트 08:00-20:00 KST (`alimtalk_service._in_send_window`)
- [x] `LNZ_PAYMENT_REMINDER_D7` 야간 예외 (`_WINDOW_BYPASS_TEMPLATES`)
- [x] 야간 큐 적재 (`_record_deferred` — `error="deferred: outside 08:00-20:00 KST send window"`)
- [x] 멱등성 — `(proposal_id, template_id)` / `(subscription_id, template_id)` 유일
- [x] 폴백 — 알림톡 실패 시 FCM 푸시 1회 (재귀 방지) — `_DefaultPushFallback` (2026-06-04 추가)
- [x] 발송 로그 — `AlimTalkLog` 테이블 + `fallback_channel` 컬럼
- [x] 캐리어 추상화 — `AlimTalkClient` Protocol, `MockAlimTalkClient` (테스트/로컬), `KakaoAlimTalkClient` (실 발신, 대행사 키 대기)
- [x] 테스트 — `tests/test_alimtalk_service.py` 15케이스 PASS

### Phase 4: 측정 + 튜닝 (1주) — TODO (Phase 2 후)

- 발송 성공률 대시보드
- 입금 회수율 비교 (도입 전후)

---

## 10. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #2 E2-C2 대응 |
| 1.1 | 2026-06-04 | Phase 3 백엔드 구현 완료 — 5종 트리거 / 발신 시간 게이트 / 폴백 / 15 테스트 PASS. Phase 2 카카오 사업자 등록 대기 |
