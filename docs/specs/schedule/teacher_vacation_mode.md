# 선생님 휴가 모드 스펙 (Teacher Vacation Mode)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #4 H-001 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #425
> 관련 스펙: [teacher_availability_spec.md §3.5](teacher_availability_spec.md), [subscription_master.md §2](../subscription/subscription_master.md), [makeup_credit_spec.md](../subscription/makeup_credit_spec.md)
> 글로서리: [glossary.md §3](../../../.harness/knowledge/glossary.md) — "휴가 모드", "수강권 자동 연장"

---

## 1. 문제 정의

E2E 감사 정량 입증: `grep teacherVacation|VacationMode = 0건`.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | 선생님이 1주 휴가 시 해당 기간 레슨 N건을 **개별 취소**해야 함 | 운영 마찰 큼, 카톡 단톡방 회피 |
| 2 | 크레딧·노쇼 카운터 오염 (휴가가 학생 노쇼처럼 카운팅됨) | 학생-선생님 분쟁 |
| 3 | 수강권 자동 연장 부재 | 학생도 만료 임박 알림 받아 혼선 |
| 4 | 학생/학부모 일괄 알림 없음 (선생님이 개별 통보) | 누락 발생 |

`teacher_availability_spec.md §3.5` 의 방학 모드는 스펙만 존재하고 미구현. 본 스펙은 그것을 **휴가 모드 (Vacation Mode)** 로 통합·강화한다.

### 1.2 영향 범위 (펀넬)

H (일정 조절·갱신) 단계 일상 운영. 여름·겨울 시즌마다 운영 신뢰 붕괴 → 카톡 채널 회피 → 앱 미사용.

---

## 2. 설계 원칙

> **"휴가는 한 번에 등록하고, 영향 받는 모든 학생에게 자동으로 통보한다."**

| 원칙 | 의미 |
|---|---|
| 일괄 처리 | 기간 선택 → 영향 받는 레슨 N건 미리보기 → 1탭 일괄 처리 |
| 선택 가능 처리 | (a) 보강 자동 등록 (b) 무료 처리 (c) 다음 회차로 이월 — 학생 단위 또는 전체 일괄 |
| 자동 통보 | 학생/학부모에게 알림톡 (LNZ_TEACHER_VACATION) 자동 발송 |
| 회복 가능 | 휴가 등록 후 24h 내 일괄 취소 가능 (Recovery) |
| 수강권 보호 | 휴가 일수만큼 만료일 자동 연장 (수강권 자동 연장) |

---

## 3. 데이터 모델

### 3.1 TeacherAvailability 확장

기존 엔티티에 다음 필드 추가 (`teacher_availability_spec.md §3.5.2` 의 기존 `vacationMode` 단일 기간을 **다중 기간 리스트로 확장**):

| 필드 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `vacationPeriods` | `List<VacationPeriod>` | `[]` | 다중 휴가 기간 |

> 기존 `vacationMode`, `vacationStartDate`, `vacationEndDate`, `vacationReason` 단일 필드는 `vacationPeriods[0]` 으로 마이그레이션 후 deprecate.

### 3.2 VacationPeriod 신규 엔티티

```dart
class VacationPeriod {
  final String id;
  final String teacherId;
  final DateTime startDate;      // 포함
  final DateTime endDate;        // 포함
  final String? reason;          // "여름방학", "시험기간" 등 (선택)
  final VacationDisposition defaultDisposition;
  final DateTime createdAt;
  final DateTime? cancelledAt;   // 24h 내 일괄 취소 사용 시
}

enum VacationDisposition {
  makeupCredit,   // (a) 보강 크레딧 적립 (makeup_credit_spec 의존)
  freeCancel,     // (b) 무료 처리 (수강권 차감 없이 취소)
  rollForward,    // (c) 다음 회차로 이월 (만료일 자동 연장)
}
```

> `updatedAt` (nullable) 필드 추가 (코드 반영 2026-06-03). 휴가 기간 수정 시각 트래킹. `defaultDisposition` 기본값은 `rollForward` (코드 반영 2026-06-03).
>
> 파생 getter `vacationDays` (코드 반영 2026-06-03): 시작~종료 양끝 포함 일수. rollForward 선택 시 §5.3 수강권 자동 연장 예상치 표시에 사용 (음수면 0).

### 3.3 영향 레슨 추적

휴가 등록 시 영향 받는 `LessonBooking` 을 식별하고 각 레슨에 `vacationPeriodId` 외래키 부여 (rollback 용).

### 3.4 영향 미리보기 모델 (코드 반영 2026-06-03)

§4.1 step 2 영향 미리보기는 다음 값 객체로 표현된다. `GET /api/teacher/vacation/impact` 응답 매핑.

```dart
class VacationImpactPreview {
  final DateTime startDate;
  final DateTime endDate;
  final int impactedLessonCount;
  final int impactedStudentCount;
  final List<VacationImpactedStudent> impactedStudents;
}

class VacationImpactedStudent {
  final String studentId;
  final String? studentName;
  final int lessonCount;
}
```

---

## 4. 진입 UI

### 4.1 등록 흐름 (3단계)

```
1. 기간 선택
   ┌─────────────────────────────────────┐
   │  휴가 등록                           │
   │                                     │
   │  시작: [7/15(월)]                   │
   │  종료: [8/31(토)]                   │
   │                                     │
   │  사유 (선택): [여름방학]             │
   │                                     │
   │  [다음]                              │
   └─────────────────────────────────────┘

2. 영향 미리보기
   ┌─────────────────────────────────────┐
   │  영향 받는 레슨 14건                  │
   │                                     │
   │  ▼ 학생별 (7명)                      │
   │    김민수  2건                       │
   │    박서연  3건                       │
   │    이지원  2건                       │
   │    ...                              │
   │                                     │
   │  [뒤로]              [다음]          │
   └─────────────────────────────────────┘

3. 처리 옵션 선택
   ┌─────────────────────────────────────┐
   │  어떻게 처리할까요?                   │
   │                                     │
   │  ◉ 보강 크레딧 적립 (권장)            │
   │     학생이 나중에 보강 예약 가능      │
   │                                     │
   │  ○ 무료 처리                         │
   │     수강권 차감 없이 취소             │
   │                                     │
   │  ○ 다음 회차로 이월                   │
   │     수강권 만료일 48일 자동 연장      │
   │                                     │
   │  ☑ 학생/학부모에게 알림톡 발송        │
   │                                     │
   │  [등록 확정]                         │
   └─────────────────────────────────────┘
```

### 4.2 학생별 다른 처리 (선택)

미리보기 화면에서 학생별 long-press → 개별 처리 옵션 변경 가능 (예: A는 보강 크레딧, B는 이월).

> 구현 상세 (코드 반영 2026-06-03): 학생 행 tap/long-press → 바텀시트로 3옵션 + "기본값 사용" 선택. 오버라이드는 `Map<studentId, VacationDisposition>` 으로 폼 상태에 보관, 등록 시 `perStudentDisposition` 으로 전송. 키 부재 = 기본 처리 따름.

### 4.3 rollForward 연장 예상치 노출 (코드 반영 2026-06-03)

처리 옵션 화면에서 `rollForward` 선택 + 유효 기간일 때, `vacationDays` 기반 수강권 자동 연장 예상 일수를 인라인 표시 (`vacationAutoExtendProjection`). 실제 연장 일수는 BE 가 최종 확정.

### 4.4 라우트 (코드 반영 2026-06-03)

진입 라우트: `/schedule/vacation` (`AppRoutes.teacherVacationMode` → `TeacherVacationModeScreen`).

### 4.5 가용 시간 화면 휴가 배너 (코드 반영 2026-06-03)

선생님 가용 시간(availability) 화면 상단에 활성 휴가 기간을 안내하는 배너(`AvailabilityVacationBanner`) 노출. 취소되지 않은(`cancelledAt == null`) 휴가만 표시하며 기간·사유를 행 단위로 렌더. 캘린더 셀 음영은 예약 그리드 소유, 배너는 경량 안내만 담당.

---

## 5. 처리 옵션 상세

### 5.1 (a) 보강 크레딧 자동 등록

영향 받는 각 레슨당 `MakeupCredit` 1건 생성 (`makeup_credit_spec.md` 의 적립 트리거 중 하나).

| 항목 | 값 |
|---|---|
| 적립 사유 (`MakeupCredit.reason`) | `teacherVacation` |
| 만료 | 휴가 종료일 + 30일 |
| 학생 측 UI | "보강 1회 적립 (휴가 사유)" 알림 |

### 5.2 (b) 무료 처리

영향 받는 레슨을 `LessonStatus.cancelledByTeacher` 로 변경. 수강권 횟수 차감 없음. `SubscriptionUsage` 미생성.

### 5.3 (c) 다음 회차로 이월 (수강권 자동 연장)

- 영향 받는 레슨 취소 (`cancelledByTeacher`)
- `Subscription.expiresAt += 휴가 일수` (자동 연장)
- `Subscription.autoExtendedDays += 휴가 일수` (분석용 트래킹)
- 학생 측 UI: "수강권 만료일이 48일 연장되었습니다"

---

## 6. 알림 정책

### 6.1 학생/학부모 알림톡

| 시점 | 템플릿 | 본문 예시 |
|---|---|---|
| 등록 직후 | `LNZ_TEACHER_VACATION` | "{teacherName} 선생님이 {startDate}~{endDate} 휴가입니다. 영향 받는 레슨 N건은 {disposition} 처리됩니다." |

> G2 #2 (kakao_alimtalk_spec) 의존. 알림톡 미구현 시 앱 푸시 폴백.

### 6.2 인앱 알림

각 영향 학생에게 인앱 알림 1건 생성. 처리 옵션별 메시지 분기:

- 보강 크레딧: "보강 N회 적립됨"
- 무료 처리: "N건 무료 취소됨"
- 이월: "만료일 N일 연장됨"

### 6.3 휴가 종료 후

휴가 종료일 다음 날 00:00 자동 비활성화. 학생에게 "선생님 복귀" 알림 1회.

---

## 7. Recovery (24시간 내 일괄 취소)

### 7.1 진입

선생님 → 스케줄 탭 → 휴가 모드 → 활성 휴가 카드 → "휴가 취소" 버튼.

### 7.2 조건

- 등록 후 **24시간 이내** 만 가능
- 첫 영향 레슨의 원래 일시가 이미 지났으면 불가 (이미 학생에게 영향 발생)

> 서버 오류 → 친화 메시지 매핑 (코드 반영 2026-06-03): "이미 시작" → 이미 시작됨 안내, "24" → 24h 윈도우 만료, "이미 취소" → 이미 취소됨. 그 외 → 일반 실패. 취소 전 `NotebookAlertDialog` 확인 (destructive).

### 7.3 자동 처리

- 모든 영향 레슨 복원 (`cancelledByTeacher` → 원 상태)
- 적립된 `MakeupCredit` 회수
- 연장된 `Subscription.expiresAt` 되돌림
- 학생에게 "휴가 취소" 알림톡 1회

---

## 8. 일반 휴무(TimeException) vs 휴가 모드 구분

| 항목 | TimeException | 휴가 모드 |
|---|---|---|
| 기간 | 1일~수일 | 1주 이상 권장 (제한 없음) |
| 일괄 처리 | 없음 (개별 취소) | 자동 (3옵션 중 선택) |
| 수강권 만료 연장 | 안 함 | 옵션 (c) 선택 시 자동 |
| 알림톡 | 기존 예약 있는 학생만 | 전체 학생/학부모 |
| 모델 | `TimeException` 레코드 | `VacationPeriod` 리스트 |
| Recovery | 없음 | 24h 내 일괄 취소 가능 |

> 휴가 모드는 내부적으로 `TimeException(type=vacation)` 레코드를 생성하지 않는다. 별도 `VacationPeriod` 로 관리.

---

## 9. 백엔드 API

### 9.1 신규 엔드포인트

| Method | 경로 | 설명 |
|---|---|---|
| POST | `/api/teachers/me/vacations` | 휴가 등록 (영향 레슨 일괄 처리 포함) |
| GET | `/api/teachers/me/vacations` | 휴가 목록 |
| GET | `/api/teachers/me/vacations/preview` | 기간 입력 시 영향 레슨 미리보기 |
| DELETE | `/api/teachers/me/vacations/:id` | 24h 내 일괄 취소 |

### 9.1.1 FE Repository 계약 (코드 반영 2026-06-03)

`VacationRepository` (Mock/Remote) 메서드:

| 메서드 | 매핑 |
|---|---|
| `previewImpact(startDate, endDate)` → `VacationImpactPreview` | GET preview |
| `registerVacation(startDate, endDate, reason?, defaultDisposition, perStudentDisposition?)` → `VacationPeriod` | POST 등록 |
| `listVacations({includeCancelled = false})` → `List<VacationPeriod>` | GET 목록. `includeCancelled` true 시 취소분 포함 |
| `cancelVacation(periodId)` → `VacationPeriod` | DELETE (24h Recovery) |

### 9.2 트랜잭션 처리

휴가 등록은 단일 트랜잭션:
1. `VacationPeriod` 생성
2. 영향 `LessonBooking` 일괄 변경
3. 처리 옵션별 후속 작업 (MakeupCredit 적립 / Subscription 연장)
4. 알림톡 발송 큐 적재

부분 실패 시 전체 롤백.

---

## 10. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 휴가 등록 후 수동 취소 건수 | `manual_cancel / total_vacation_impacted_lessons` | < 10% |
| Recovery 사용률 | `vacation_cancelled_within_24h / total_vacations` | 정상 범위 1-5% |
| 처리 옵션 분포 | makeupCredit / freeCancel / rollForward 비율 | 모니터링 |
| 알림톡 도달률 | `LNZ_TEACHER_VACATION delivered / sent` | > 95% |

### 10.1 정량 검증

```bash
# 백엔드 모델 정의 확인
grep -rn "VacationPeriod" backend/app/models/  # ≥ 1
# 프론트 엔티티 확인
grep -rn "VacationPeriod\|vacationPeriods" frontend/lib/features/schedule/  # ≥ 1
```

---

## 11. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- 본 스펙 작성
- glossary "휴가 모드", "수강권 자동 연장" 추가 (이미 완료)
- `teacher_availability_spec.md §3.5` 의 단일 기간 → 다중 기간으로 마이그레이션 노트

### Phase 2: 백엔드 (1-2주)

- `VacationPeriod` 엔티티 + 마이그레이션
- 신규 엔드포인트 4개
- 영향 레슨 일괄 처리 트랜잭션
- 알림톡 발송 (G2 #2 의존)

### Phase 3: 프론트엔드 (1-2주)

- 등록 3단계 UI
- 영향 미리보기 + 학생별 처리 변경
- 활성 휴가 카드 + Recovery 버튼

### Phase 4: 의존성 통합

- `MakeupCredit` 적립 트리거 연동 (`makeup_credit_spec.md`)
- 알림톡 템플릿 LNZ_TEACHER_VACATION 활성화

---

## 12. 의존성

| 의존 스펙 | 의존 항목 |
|---|---|
| [makeup_credit_spec.md](../subscription/makeup_credit_spec.md) | 처리 옵션 (a) 보강 크레딧 자동 등록 시 적립 트리거 |
| `kakao_alimtalk_spec.md` (G2 #2) | LNZ_TEACHER_VACATION 템플릿 |
| `subscription_master.md` §2 | `Subscription.autoExtendedDays`, `expiresAt` 연장 로직 |

---

## 13. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #4 H-001 대응. 기존 `teacher_availability_spec.md §3.5` 의 단일 기간 방학 모드를 다중 기간 휴가 모드로 확장 + 3옵션 처리 + Recovery |
