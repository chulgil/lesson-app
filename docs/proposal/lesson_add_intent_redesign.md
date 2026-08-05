# 레슨 추가 인텐트 재설계 — 수강권 기반 스케줄 생성 + 수기(미가입) 관리 경계

> 작성일: 2026-08-03
> 상태: **스펙 반영 완료 (2026-08-03)** — D1~D5 추천안 채택. 규범 SSOT 는 `subscription_required_spec.md` §2.6~2.7
> 외 §7 매핑 문서로 이관됨. 본 문서는 기획 이력/근거 보존용
> 근거: 스펙 5종 + 코드 실측 — 코드 인용은 전부 **origin/main 기준** (작성 시점 체크아웃이
> main 대비 201커밋 뒤처져 있어 `git grep origin/main` 으로 재검증함. 스펙 문서는 두 기준 간 diff 0)

---

## 0. 결론 (한 줄)

**"수기 vs 온라인" 이분법은 이미 해소되어 있다.** 수강권 필수화(Plan B)가 결정·구현되어 모든 레슨은 수강권에 귀속된다(없으면 체험 1회권 자동 생성). 남은 과제는 두 가지다:
1. **레슨 추가 화면이 선생님의 4가지 인텐트(다음 회차 / 보충 / 체험 / 신규 발급)를 명시적으로 분기**하지 않고 조용히 자동 처리하는 것 — 회계 왜곡·의도 불일치 위험.
2. **수기 관리의 경계를 "미가입(offline) 학생 전용"으로 명문화** — 가입 학생은 온라인 수강권 경로만.

---

## 1. 경계 결정 (사용자 지시 반영)

| 학생 유형 | 스케줄/레슨 관리 방식 | 데이터 경로 |
|---|---|---|
| **가입 학생** (isAppConnected) | 온라인 전용 — 수강권 제안/발급 + 학생 확인(주고받는 컨셉) | 예약 3경로(신청/직접예약/일정변경) + 확인 카드 |
| **미가입(수기) 학생** (offline, `user_id=null`) | 선생님 단독 관리 — 학생 확인 단계 생략, 선생님이 대리 확정 | **동일한 수강권 귀속 경로** (별도 수기 데이터 경로 없음) |

핵심: 수기 학생도 **레슨 데이터 모델은 온라인 학생과 동일**하다(수강권 귀속, `lesson.subscriptionId != null`). "수기"의 의미는 데이터 경로가 아니라 **"학생 확인 절차의 생략"** 으로 축소한다. 이렇게 하면:
- 별도 수기 사양이 없어 복잡도 증가 없음 (사용자 지시: "사양이 복잡하다면 수기 배제")
- 학생이 나중에 가입하면 전화번호 매칭으로 이력이 그대로 인계됨 (user_master §3.2 기존 규칙)
- 취소/보강/수익 분석이 전 레슨에서 동작 (Plan B 의 원래 목적)

---

## 2. 실태 분석 — 스펙 vs 코드 (2026-08-03 실측)

### 2.1 이미 구현된 것 (재구현 금지)

| 항목 | 스펙 | 코드 실측 |
|---|---|---|
| 수강권 필수화 + 체험 1회권 자동 생성 | `subscription_required_spec.md` (Plan B) | `lesson_service.py` `_find_or_create_subscription`(:202) + `_create_trial_subscription`(:239) 구현 완료 |
| 레슨 추가 시 수강권 0/1/2+ 분기 | 위 스펙 §2.5 | `add_lesson_screen.dart` `_resolveSubscriptionForStudent` + `manual_lesson_subscription_section.dart` 구현 완료 |
| 잔여 0 시 보너스 확장 | 위 스펙 §2.3 | `lesson_service.py:206~227` (`total_lessons+=1, bonus_count+=1`) — **단, 무언(silent) 처리** |
| 보강 크레딧 (Make-up Bank) | `makeup_credit_spec.md` | BE 완비 (`makeup_credit_service.py`, `api/v1/makeup_credits.py`) + **학생측** 예약 화면(`lesson_booking_screen.dart:218~344`)에서 소비 + 선생님측 **조회/관리 UI 존재** (`teacher_makeup_credit_section.dart` — 학생 상세 정보 탭·크레딧 화면) + 학원 일괄휴강 보강 입력(`makeup_lesson_input_screen.dart`, academy 특수 경로) |
| 수기 학생 모델 | `relationship_master.md`, `user_master.md` §수기 등록 학생 | `TeacherStudentRelation.isManuallyRegistered` + `Student.user_id nullable` + 직접 등록 화면(`add_student_method_screen.dart`). **BE `StudentCreate` 스키마에 `user_id` 필드 자체가 없음** — 교사 생성 학생은 구조적으로 계정 없는 레코드 |
| 미가입 학생 수강권 발급 | — | **가능** — `SubscriptionService.create` 는 학생 계정 무관(교사 전화인증만 게이트). 학생 추가 직후 "수강권을 발급하시겠습니까?" 다이얼로그 기존재(`add_student_screen.dart:378`). 반면 **제안-수락 경로만 학생 계정 전제**(`subscriptions.py:683` respond API 가 응답자 계정 검증) |
| 수기/수강권 레슨 편집 분기 | `lesson_master.md` §13~14 | `lesson_action_sheet.dart` (수기=전체 편집, 수강권=곡·메모만) |
| 과거 레슨 기록 모드 | `quick_add_lesson.md` §Record Mode | add_lesson_screen 과거 날짜 → 기록 모드 + 자동 차감 |
| 수강권 발급/제안 Template-First | `subscription_master.md` §3.1 (v7) | 즉시 발급 + 제안 2경로, 진입점 4곳 |
| 예약 3경로 (학생측) | 메모리/스펙 정합 | A 신청(`UnifiedLessonRequestScreen`) / B 직접예약(`LessonBookingScreen`) / C 일정변경(수강권 상세 챗) |

### 2.2 스펙 드리프트 (문서 정정 필요)

| 문서 | stale 서술 | 현재 진실 |
|---|---|---|
| `lesson_master.md` §10.1/10.3 (2026-05-07) | "수강권 없이 추가된 레슨: 기록용 (횟수 차감 없음)" | Plan B 이후 수강권 없는 레슨은 존재하지 않음 — 체험 1회권 자동 생성·귀속 |
| `lesson_master.md` §10.2 배너 문구 | "수기로 레슨을 등록할 수 있으며..." | 실제 구현은 §2.5 분기 배너 (`manual_lesson_subscription_section.dart`) |
| `quick_add_lesson.md` | `_mockStudents` 제거 등 체크리스트 미완 표기 | 구현 완료 항목 다수 — 체크리스트 현행화 필요 |

---

## 3. UX 설계 — 레슨 추가 인텐트 분기

### 3.1 설계 원칙

1. **AddLessonScreen 을 갈아엎지 않는다.** §2.5 분기(0/1/2+)와 quick_add 3탭 목표는 그대로. 변경은 **학생 선택 직후의 배너/시트 1개 층**에만 추가한다 (기존 기능 비침해).
2. **모호할 때만 묻는다** (기존 §2.5 원칙 계승). 흔한 경우(활성 수강권 1개 + 잔여 있음)는 지금처럼 탭 수 증가 0.
3. **조용한 자동 처리 중 회계에 영향을 주는 것만 명시적 선택으로 승격** — 잔여 0 보너스 확장, 보강 크레딧 소비, 체험권 자동 발급.

### 3.2 학생 선택 후 상태별 분기 (핵심 표)

| # | 학생 상태 | 현재 동작 | 개선 후 |
|---|---|---|---|
| S1 | 활성 수강권 1개, 잔여 > 0 | 자동 귀속 + 배너 | **변경 없음** (배너에 "N/M회차로 차감" 유지) |
| S2 | 활성 수강권 2+ | 선택 시트 | **변경 없음** |
| S3 | 활성 수강권 있음, **잔여 0** | 무언의 보너스 확장 (`bonus_count+=1`) | **처리 방식 시트** (§3.3) — 보충/보너스/갱신 제안 중 선택 |
| S4 | **보강 크레딧 보유** (잔여 무관) | 크레딧 무시, 정규 차감 | 배너에 크레딧 잔량 노출 + **"보강으로 처리" 토글** → MakeupCredit 차감 |
| S5 | 활성 수강권 0개, 체험 이력 없음 | 체험 1회권 무언 자동 생성 | 배너 명시: "체험 1회권이 자동 발급됩니다" + **[정식 수강권 먼저 발급]** 보조 버튼 |
| S6 | 활성 수강권 0개, 체험 이력 있음 | 체험권 재생성 (남발 위험) | **[수강권 발급/제안]** 유도 우선 — 체험권 재발급은 D2 결정 |

### 3.3 잔여 0 처리 방식 시트 (S3, 신규)

```
+--- 처리 방식 선택 -------------------------------+
|            김민지 - 바이올린 8회권 (0회 남음)      |
|                                                  |
| ( ) 보강 레슨            보강 크레딧 2개 보유      |
|     크레딧 1개를 사용합니다                        |
| ( ) 보너스 레슨 (무료 추가)                        |
|     수강권에 +1회 무료 추가됩니다                   |
| (o) 수강권 갱신 제안 보내기          << 기본 강조   |
|     갱신 후 이 시간으로 예약됩니다                  |
|                                                  |
|                 [계속하기]                        |
+--------------------------------------------------+
```

- 보강 크레딧 0개면 첫 항목 숨김 (3항목 -> 2항목).
- "갱신 제안" 선택 시: 제안 발송 + **이 레슨은 `isPreview=true` 로 캘린더에 미리 표시** (기존 `Lesson.isPreview` 필드 재사용 — 신규 모델 없음). 입금 확인 시 정식 회차로 전환.
- 미가입(offline) 학생은 제안을 받을 수 없으므로 세 번째 항목이 **[갱신 발급 (입금 직접 확인)]** 으로 대체 → Template-First 즉시 발급 화면.

### 3.4 수강권 신규 발급 연속 플로우 (S5/S6 → 발급 → 스케줄 복귀)

사용자 요청 "학생 선택해서 수강권을 새로 발급받는 절차": **새 화면을 만들지 않고** 기존 Template-First 발급 화면(`issue_subscription_screen.dart`, 실측 라우트 진입 7곳 + 인라인 발급 2경로)에 add_lesson 진입점을 추가하고, 복귀 연속성만 설계한다.

```
AddLessonScreen (학생 선택됨, 수강권 0개)
  └→ [정식 수강권 먼저 발급] 탭
       └→ Template-First 화면 (학생 프리필, returnTo=addLesson)
            ├─ 가입 학생: [제안 보내기] → 학생 수락 대기
            │    └→ add_lesson 복귀 시 안내: "제안 대기 중 — 확정되면
            │        스케줄 확인 카드로 자동 예약됩니다" (폼 종료)
            └─ 즉시 발급 (입금 확인됨 / 무료 / 미가입 학생):
                 └→ 발급 완료 → AddLessonScreen 자동 복귀
                      └→ 새 수강권 자동 귀속 (S1 상태) → 날짜/시간 저장
```

- 가입 학생 + 제안 경로는 기존 "제안 → 수락 → 입금 확인 → 스케줄 확인 카드" 플로우를 침해하지 않는다 (레슨을 미리 만들지 않음).
- 즉시 발급 경로(특히 미가입 학생)만 add_lesson 으로 복귀해 그 자리에서 스케줄을 확정한다 — subscription_master §3.3.5 "앱 전환: 스케줄 선생님 직접 입력" 규칙의 일반화.

### 3.5 신규 학생 체험 레슨 (S5 의 앞 단계)

"신규 학생의 체험 레슨 스케줄" 시나리오: 학생이 아직 목록에 없을 때.

```
스케줄 탭 (+) → AddLessonScreen → 학생 선택 시트
  └→ 최상단 [+ 새 학생 등록] 항목 (신규)
       └→ add_student (직접 등록: 이름 + 연락처 최소 입력)
            └→ 등록 완료 → 시트 복귀 + 방금 학생 자동 선택
                 └→ S5 상태: "체험 1회권 자동 발급" 배너 → 날짜/시간 저장
```

- 체험 완료 후에는 기존 리드 관리 + 골든타임 자동 제안(subscription_master §3.4~3.6)이 그대로 이어진다 — 체험→정규 전환 퍼널에 자동 연결.
- 총 탭 수: 스케줄 (+) 1 + 새 학생 1 + 이름/연락처 입력 + 저장 1 + 시간 확인 + 저장 1 ≈ 4~5탭.
- 기존 등록 직후 "수강권을 발급하시겠습니까?" 다이얼로그(`add_student_screen.dart:378`)는 이 경로(returnTo=addLesson)에서는 **스킵** — 체험 1회권 자동 발급이 대신 담당하고, 정식 발급은 S5 배너의 보조 버튼으로 유도.

### 3.6 미가입(수기) 학생 특칙

| 항목 | 가입 학생 | 미가입 학생 |
|---|---|---|
| 수강권 발급 | 제안(수락 필요) 또는 즉시 발급 | **즉시 발급만** (제안 UI 숨김) |
| 스케줄 확정 | 학생 확인 카드 | **선생님 저장 = 즉시 확정** |
| 일정 변경 | 수강권 상세 챗 협상 | 선생님 단독 변경 (챗 협상 스킵) |
| 갱신 | 시스템 자동 제안 (학생 액션) | 선생님 수동 갱신 발급 |
| 알림/리마인더 | 앱 푸시 | 없음 (선생님 화면에만 표시) |
| 앱 연결 시 | — | 전화번호 매칭 → 이력·수강권 인계, 이후 가입 학생 규칙 적용 |

> BE 근거: 제안-수락 경로만 학생 계정을 전제한다 — `POST /subscriptions-proposals/{id}/respond` 가
> 응답자 계정을 검증(`subscriptions.py:683`). 즉 "미가입 학생 = 즉시 발급만" 특칙은 설계 선호가 아니라
> 현재 백엔드 계약과 정합하는 명문화다.

### 3.7 수강권 상세 → 다음 회차 배선 (G8 해소)

사용자 요구 "수강권이 있다면 해당 수강권에서 다음 회차 스케줄 조절"의 정확한 갭.
현재 수강권 상세는 일정 **변경**만 가능하고, 미정 회차를 **새로 잡는** 진입점이 없다
(안내 텍스트와 死문자열 `sessionBookingRequired` 만 존재 — UI 설계 후 미배선 상태).

| 뷰어 | 트리거 | CTA | 이동 |
|---|---|---|---|
| 선생님 | 미정 회차 존재 (scheduledLessons < remaining) | 회차 프로그레스바 아래 "[N회차 예약하기]" (`sessionBookingRequired` 재사용) | `AddLessonScreen?studentId=&subscriptionId=` 프리필 → S1 자동 귀속 저장 |
| 학생 | 회차권/보강 크레딧 + 미정 회차 | 동일 CTA | 직접예약 B (`/schedule/booking/direct`) — 기존 화면 재사용 |

- 기존 `subscription_schedule_management_spec.md` 의 미해소 갭 G-3(선생님 빈 시간대 UI 미연결)과 같은 문제의식 — 본 배선이 그 해소안을 겸한다.
- 정기권(주간 자동 생성)은 미정 회차가 없는 것이 정상이므로 CTA 비노출.

---

## 4. 갭 목록 (구현 대상)

| # | 갭 | 근거 | 규모 |
|---|---|---|---|
| G1 | 잔여 0 시 무언 보너스 확장 — 선생님 의도 미확인 (보충인지 보너스인지 갱신인지) | `lesson_service.py:168~189` + FE 시트 부재 | FE 시트 1개 + BE `POST /lessons` 에 처리 방식 파라미터 |
| G2 | 선생님측 보강 크레딧 **소비** 배선 부재 — 조회/관리 UI(`teacher_makeup_credit_section`)와 학원 일괄휴강 입력은 있으나, 레슨 추가 폼에서 크레딧을 차감해 보강 레슨을 잡는 경로가 없음 (소비는 학생측 직접예약뿐, `features/lessons/` 내 makeup 참조 0건) | origin/main 실측 | FE 토글(S4) + BE 레슨 생성 시 크레딧 차감 연결 |
| G3 | 체험 1회권 반복 자동 생성 가드 부재 | `_find_or_create_subscription` 무조건 생성 | BE 가드 (D2 결정 후) |
| G4 | 발급 → 스케줄 연속 플로우 부재 (add_lesson → Template-First 진입점 없음) | 진입점 4곳에 add_lesson 없음 | FE 라우팅 + returnTo 파라미터 |
| G5 | 학생 선택 시트에 [+ 새 학생 등록] 부재 | add_lesson 학생 시트 | FE 소규모 |
| G6 | 스펙 드리프트 — lesson_master §10 stale (§2.2, **2026-08-03 정정 완료**) + `calendar_master.md:20` 이 레슨 추가 네비게이션을 `schedule_master.md` 소관으로 지목하나 실제 무언급 (끊긴 포인터) | 문서 실측 | 문서만 |
| G7 | `Lesson` 엔티티에 레슨 유형 필드 부재 — `LessonType{trial,regular,oneTime}` 은 booking 도메인(`core/booking/entities/lesson_booking.dart`) 전용, `features/lessons/` 사용 0건. "체험" 개념 자체가 3갈래 산재: `StudentStatus.trial`(학생 상태) / `RelationshipStatus.trialBooked`(관계) / `subscription.type == trial`(수강권). `Student.defaultTrialFee`(30000) 는 참조 0건 死상수 | origin/main 실측 | **신규 enum 추가 대신 기존 간접 표현 재사용 권고** (simplicity ladder): 체험 배지 = `subscription.type == trial`, 보강 배지 = MakeupCredit 연결. DB 변경 0. 死상수는 정리 대상 |
| G8 | **수강권 상세 → 다음 회차 예약 미배선** — `subscription_detail_screen.dart` 에 라우팅 참조 0건 (`Navigator.push` 2건은 전부 일정변경 전용). 회차권 안내는 텍스트만(`schedule_guide_info_box.dart`), `AppStrings.sessionBookingRequired`("N회차 예약 필요")는 정의만 있고 사용처 0건인 死문자열. 스펙 `subscription_schedule_management_spec.md` 도 상태 설계중 + G-1/G-3 미해소 | origin/main 실측 | §3.7 배선 설계 참조. 死문자열 재사용 |
| G9 | **학생 본인 앱 초대 진입점 부재** — 학생 상세의 초대는 학부모 초대 전용(`student_detail_screen.dart` "학생의 학부모를 초대합니다"). 미가입 학생을 앱으로 전환시킬 CTA 가 없어 §3.6 "앱 연결 시 인계" 퍼널의 입구가 막혀 있음 | origin/main 실측 | 미가입 학생 상세에 [학생 앱 초대] CTA — 기존 invite 기능(화면 7종·QR/URL/코드) 재사용, 신규 화면 0 |

---

## 5. 기존 기능 비침해 매트릭스

| 기존 기능 | 영향 |
|---|---|
| 예약 3경로 A/B/C (학생측) | 무변경 — 본 설계는 전부 선생님측 |
| 스케줄 확인 카드 + recurring 생성 (`_generate_recurring_lessons`) | 무변경 — 제안 경로는 레슨 선생성 안 함 (§3.4) |
| AddLessonScreen §2.5 분기 (0/1/2+) | 유지 — 상태 배너/시트 층만 추가 |
| quick_add 3탭 목표 | S1/S2 (흔한 경우) 탭 수 불변 |
| 수기/수강권 레슨 액션 시트·편집 분기 (lesson_master §13~14) | 유지 |
| 과거 레슨 기록 모드 | 유지 — S3/S4 분기는 기록 모드에도 동일 적용 |
| 그룹레슨 Phase 5 (진행 중, appliesTo) | 독립 — 본 설계는 1:1 레슨 추가만. 그룹 회차는 별도 진입점 유지 |
| 보강 크레딧 학생측 소비 | 유지 — 선생님측 소비는 동일 서비스 재사용 |

---

## 6. 결정 항목 (2026-08-03 추천안 채택 확정 — 사용자 "스펙 반영 진행" 승인)

| # | 질문 | 채택안 |
|---|---|---|
| D1 | 잔여 0 시 기본 강조 옵션은? | **갱신 제안** (매출 보호 — 보너스 남발 방지). 보강 크레딧 있으면 보강을 첫 항목으로 |
| D2 | 체험 1회권 자동 생성을 학생당 1회로 제한? | **제한** — 2번째부터는 발급 유도. 단 offline 학생은 예외 검토 (체험 개념이 약함) |
| D3 | S4 보강 토글 기본값 — 크레딧 보유 시 자동 ON? | **OFF + 배너 노출** (makeup_credit_spec §5 "명시적 선택" 원칙 유지) |
| D4 | 미가입 학생에게 정식 수강권 발급을 강제? | **강제 안 함** — 체험 1회권 자동 귀속 허용 유지, 발급 유도 배너만 (스케줄 관리 목적의 가벼운 사용 보호) |
| D5 | 용어 확정 — "수기 레슨" 라벨을 "선생님 등록 레슨" 등으로 개칭? | **개칭 보류** — glossary 기존 용어(수기) 유지, 의미만 "미가입 학생 + 선생님 대리 확정"으로 재정의 |

---

## 7. 스펙 반영 계획 (D 확정 후 Phase 2 doc-sync)

| 문서 | 반영 내용 |
|---|---|
| `subscription_required_spec.md` | §2.6 신설 — 인텐트 분기 (S1~S6 표 + 시트) + G1/G2/G3 BE 규칙 |
| `lesson_master.md` §10 | Plan B 정합화 (stale 문구 정정) + §3.6 미가입 특칙 링크 |
| `quick_add_lesson.md` | 체크리스트 현행화 + [+ 새 학생 등록] 경로 추가 |
| `makeup_credit_spec.md` §5 | 선생님측 소비 (add_lesson 토글) 추가 |
| `subscription_master.md` §3.1.2 | 발급 진입점에 add_lesson(returnTo) 추가 |
| `subscription_schedule_management_spec.md` | §3.7 다음 회차 CTA 배선 반영 (기존 갭 G-1/G-3 해소안 겸함) + 상태 갱신 |
| `calendar_master.md` | 끊긴 포인터 정정 — 레슨 추가 네비게이션 소관을 실제 문서로 연결 (G6) |
| `.harness/knowledge/glossary.md` | "수기 학생/수기 레슨" 정의 갱신 (D5), "레슨 추가 인텐트" 신규 |

## 8. 참조

- `docs/specs/subscription/subscription_required_spec.md` (Plan B — 본 설계의 토대)
- `docs/specs/subscription/subscription_master.md` §3 (Template-First v7)
- `docs/specs/subscription/makeup_credit_spec.md` (Make-up Bank)
- `docs/specs/lesson/lesson_master.md` §2~3, §10, §13~14
- `docs/specs/lesson/quick_add_lesson.md`
- `docs/specs/user/user_master.md` §수기 등록 학생 / `docs/specs/relationship/relationship_master.md`
- `docs/specs/booking/unified_lesson_request_spec.md` (학생측 — 비침해 확인용)
