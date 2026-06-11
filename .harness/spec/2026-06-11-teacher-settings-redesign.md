# 선생님 설정화면 전면 재설계 스펙

> 작성일: 2026-06-11
> 단계: cg-harness Phase 2 — 스펙 초안 (Phase 6 통과 후 마스터 스펙들로 머지)
> 입력 자료:
> - [`docs/specs/profile/profile_master.md`](../../docs/specs/profile/profile_master.md) (2026-04-16 10x Vision)
> - [`docs/specs/schedule/availability_settings_ux_redesign_spec.md`](../../docs/specs/schedule/availability_settings_ux_redesign_spec.md) (2026-06-06 완료)
> - [`docs/specs/design/teacher_quest_audit_2026-06-08.md`](../../docs/specs/design/teacher_quest_audit_2026-06-08.md)
> - [`docs/specs/design/settings_information_architecture_spec.md`](../../docs/specs/design/settings_information_architecture_spec.md)
> - [`.harness/spec/2026-06-08-teacher-quest-system.md`](2026-06-08-teacher-quest-system.md)
> 글로서리: [`.harness/knowledge/glossary.md`](../knowledge/glossary.md)
> 관련 코드 (재설계 대상):
> - `frontend/lib/features/profile/presentation/screens/profile_tab.dart`
> - `frontend/lib/features/profile/presentation/screens/lesson_time_settings_screen.dart` (해체 예정)
> - `frontend/lib/features/schedule/presentation/screens/teacher_availability_split_page.dart`
> - `frontend/lib/features/home/presentation/widgets/quest_board_card.dart`
> - `frontend/lib/features/profile/domain/entities/teacher_settings.dart`
> - `frontend/lib/features/schedule/domain/entities/teacher_availability.dart`

---

## 1. 배경 — 3가지 어긋남

20년차 UX 전문가 관점 점검 결과, 선생님 설정화면에 다음 3가지 어긋남이 누적되어 있어 가입 직후 사용자에게 인지 부하를 강하게 발생시킨다.

### 1.1 카테고리 어긋남 (P0)

"레슨 시간 설정" 화면 안에 6개 섹션이 섞여 있다.

| 섹션 | 도메인 | 의미 |
|---|---|---|
| §1 기본 레슨 시간 옵션 | 수업방식 | 30/45/60분 단위 |
| §2 예약 설정 | 운영시간 + 수업방식 | 쉬는시간(운영) + 최소예약시간(수업규칙) |
| §3 가용 요일/시간 | 운영시간 | 요일별 슬롯 |
| §4 학생 안내 메시지 | 수업방식 | 예약 시 멘트 |
| §5 시험 레슨 무료 | 수강권/정산 | 첫 수강권 정책 |
| §6 악기·레벨별 가격표 | 수강권/정산 | 만원 단위 가격 |

시간(분) 도메인 화면에 가격(만원), 정책 토글, 안내 메시지가 섞여 멘탈 모델 무너짐.

### 1.2 운영시간 이원화 (P0)

같은 의미의 "주간 운영시간"이 두 데이터 모델 + 두 화면에 존재.

| 비교 항목 | profile 도메인 | schedule 도메인 | 일치 여부 |
|---|---|---|---|
| 주간 슬롯 | `TeacherSettings.availableSlots` (`TimeSlot[]`) | `TeacherAvailability.weeklySchedules` (`WeeklySchedule[]`) | ❌ 다른 필드 |
| 쉬는시간 | `breakTimeBetweenLessons` | `breakTimeBetweenLessons` | ⚠️ 중복 (동기화 메커니즘 없음) |
| 최소 사전예약 | `minBookingHours` | `minBookingHours` | ⚠️ 중복 |
| 레슨 1회 시간 | `defaultLessonDuration` (60분) | `slotDurationMinutes` (50분) | ❌ 다른 이름 + 다른 기본값 |
| 휴무·휴가 예외 | 없음 | `TimeException[]`, `Vacation[]` | schedule만 보유 |

진입 메뉴도 2개("레슨 시간 설정" + "가용 요일/시간") 동시 노출 → 사용자는 둘 차이를 라벨로 구분 불가.

### 1.3 메뉴 라벨 모호 (P1)

프로필 탭에 다음 2메뉴가 나란히 있고 의미 차이가 라벨로 구분되지 않음:

- "레슨 시간 설정" — 실제로는 기본값 + 가용 시간 + 가격
- "가용 요일/시간" — 실제로는 `TeacherAvailabilitySplitPage`

---

## 2. 성공 기준

| # | 기준 | 측정 |
|---|---|---|
| SC-1 | 가입 직후 선생님이 5묶음 카테고리를 한 화면에서 인지 | Step 2.5 미리보기 화면 1회 노출 |
| SC-2 | 운영시간 SSOT 단일화 | `TeacherSettings.availableSlots` 필드 0개 read/write |
| SC-3 | "레슨 시간 설정" 화면 해체 | 라우트 deprecated, 메뉴에서 사라짐 |
| SC-4 | 운영시간 메뉴 라벨 1개 | "운영시간" 단일 (기존 2메뉴 → 1) |
| SC-5 | 퀘스트 100% 완료 시 메인에서 자동 hide | 7일 후 졸업 카드 dismiss |
| SC-6 | 퀘스트 진행도 = 완성도 게이지 1:1 | 두 값 동일 (테스트 필수) |
| SC-7 | 기존 가입 선생님 마이그레이션 무손실 | `availableSlots` → `weeklySchedules` 복사 완료 |

---

## 3. 정보 아키텍처 — 5묶음 카테고리 (SSOT)

행동/의도 중심 5묶음. 모든 설정 항목은 정확히 하나의 묶음에 속한다.

```
🏠 선생님 홈 (DashboardTab — 기존 위치 그대로)
├── 상단 영역 (기존 유지)
│   ├── 이름·악기·완성도 게이지
│   ├── 자주 쓰는 3카드 (입금대기 / 운영시간 / 수강권)
│   └── 퀘스트 보드 (졸업까지만 노출 — §8 참조)
│
├── 🕐 운영시간 ────────────────── "언제 가르치는가"
│   ├── 주간 운영시간 (요일별 시작·종료)
│   ├── 레슨 간 쉬는시간
│   ├── 임시 휴무 / 추가 오픈 (특정 날짜 예외)
│   └── 장기 휴가 모드 (다중 기간)
│
├── 🎓 수업 방식 ───────────────── "어떻게 가르치는가"
│   ├── 레슨 1회 시간 (`lessonDurationMinutes`)
│   ├── 최소 사전 예약 시간 (`minBookingHours`)
│   └── 학생 안내 메시지 (예약 시 멘트)
│
├── 💰 수강권·정산 ──────────────── "어떻게 받는가"
│   ├── 수강권 템플릿 (8회/12회/월정액)
│   ├── 악기·레벨별 가격표  ← lesson_time 에서 이동
│   ├── 시험 레슨 정책 (무료/유료)  ← lesson_time 에서 이동
│   ├── 취소·환불 기본값
│   ├── 입금 계좌 관리
│   └── 입금 대기 (후불 미수)
│
├── 👤 내 프로필 ────────────────── "나는 누구인가"
│   ├── 기본 정보 (이름·사진·소개)
│   ├── 악기 관리
│   ├── 학력·경력·자격증
│   ├── 레퍼토리
│   └── 공개 프로필 미리보기 + 공개 항목 제어
│
└── ⚙️ 정책·알림·지원
    ├── 레슨 취소 정책
    ├── 피드백·팁 템플릿
    ├── 알림 설정
    ├── 녹음 관리
    ├── 가이드 다시 보기 (퀘스트 졸업 후 fallback)
    ├── 뉴스·도움말·앱 정보
    └── 계정 (약관·개인정보·로그아웃)
```

### 메뉴 순서 원칙 (게임 디자인 차용)

1. **자주 쓰는 카드 3개** (상단): 빈번 인터랙션 우선
2. **운영시간 → 수업방식 → 수강권·정산** (돈 흐름 순서): 신규 선생님이 "받기 시작"하기 위해 거치는 순서
3. **내 프로필**: 한 번 채우면 자주 안 봄
4. **정책·알림·지원**: 가끔 보는 것

---

## 4. 항목 재분류 (이동 표)

| 현재 위치 (해체) | 항목 | 새 위치 (5묶음) | 사유 |
|---|---|---|---|
| `LessonTimeSettingsScreen` §1 | 레슨 1회 시간 (30/45/60) | 🎓 수업방식 | 수업 단위 길이 |
| `LessonTimeSettingsScreen` §2 (쉬는시간) | 레슨 간 쉬는시간 | 🕐 운영시간 | 캘린더 슬롯 계산 결부 |
| `LessonTimeSettingsScreen` §2 (최소예약) | 최소 사전예약 시간 | 🎓 수업방식 | 학생 인터랙션 규칙 |
| `LessonTimeSettingsScreen` §3 | 가용 요일/시간 | 🕐 운영시간 | 시간 도메인 단일화 |
| `LessonTimeSettingsScreen` §4 | 학생 안내 메시지 | 🎓 수업방식 | 예약 시 멘트 |
| `LessonTimeSettingsScreen` §5 | 시험 레슨 무료 토글 | 💰 수강권·정산 | 첫 수강권 정책 |
| `LessonTimeSettingsScreen` §6 | 악기·레벨별 가격표 | 💰 수강권·정산 | 만원 단위 가격 |
| 프로필 탭 메뉴 | "레슨 시간 설정" | (삭제) | 카테고리 어긋남 해소 |
| 프로필 탭 메뉴 | "가용 요일/시간" | "운영시간" 으로 리네임 | 라벨 명확화 |

---

## 5. 운영시간 데이터 통일

### 5.1 SSOT 결정

**`TeacherAvailability`(schedule 도메인) = 운영시간 단일 진실 소스.**

근거: 마스터 스펙 `availability_settings_ux_redesign_spec.md`(2026-06-06 완료)가 이미 split 레이아웃까지 schedule 방향으로 구현. profile 쪽 `availableSlots` 는 레거시.

### 5.2 폐기·통일 필드

| 변경 | 필드 | 영향 |
|---|---|---|
| 폐기 (TeacherSettings) | `availableSlots: List<TimeSlot>` | schedule.weeklySchedules 가 SSOT |
| 폐기 (TeacherSettings) | `breakTimeBetweenLessons` | schedule 로 이전 (운영시간 묶음) |
| 폐기 (TeacherAvailability) | `minBookingHours` 의 schedule 중복본 (반대 방향) | **TeacherSettings 만 보유 (수업방식 묶음)**. `breakTimeBetweenLessons` 와 반대 방향 — schedule → profile 이동 (architect P1 #3 정합) |
| 이름 통일 | `slotDurationMinutes`(schedule) + `defaultLessonDuration`(profile) → **`lessonDurationMinutes`** | TeacherSettings 에서 단일 정의 |
| 기본값 통일 | 50분 (마스터 스펙 §3 schedule 기준) | profile 의 60분 기본 폐기 |

### 5.3 매핑 매트릭스 (확정)

| 5묶음 | 엔티티 | 필드 |
|---|---|---|
| 🕐 운영시간 | `TeacherAvailability` (schedule) | `weeklySchedules`, `breakTimeBetweenLessons`, `TimeException[]`, `Vacation[]` |
| 🎓 수업방식 | `TeacherSettings` (profile) | `lessonDurationMinutes`, `minBookingHours`, `studentGuideMessage` |
| 💰 수강권·정산 | `TeacherSettings` + 별도 | `priceTable[]`, `trialLessonPolicy`, `cancellationDefaults`, `SubscriptionTemplate[]`, `BankAccount[]`, `OutstandingPayment[]` |
| 👤 내 프로필 | `TeacherProfile` / `Instrument` / `Credential` | 기존 유지 |
| ⚙️ 정책 | `CancellationPolicy` 등 | 기존 유지 |

### 5.4 마이그레이션 (앱 부팅 시 1회)

```
if TeacherSettings.availableSlots 비어있지 않음:
    if TeacherAvailability.weeklySchedules 비어있음:
        TeacherSettings.availableSlots → TeacherAvailability.weeklySchedules 복사
    else:
        TeacherAvailability 우선 (schedule 이 더 풍부함 — 예외/휴가 포함)
    TeacherSettings.availableSlots = []   // 폐기
```

충돌 시 (architect P1 #3 정합):
- `breakTimeBetweenLessons` 충돌 → **schedule 우선** (운영시간 묶음 SSOT)
- `minBookingHours` 충돌 → **profile 우선** (수업방식 묶음 SSOT — `breakTimeBetweenLessons` 와 반대 방향)
- 동일하면 무영향

테스트 시나리오 (Red-Green):
- 가입한 신규 선생님 (profile 만 있음) → schedule 로 복사 후 0 손실
- 기존 선생님 (둘 다 있음) → schedule 유지
- 기존 선생님 (profile 만 채워짐, schedule 비어있음) → schedule 로 복사

---

## 6. 카테고리별 화면 구조

### 6.1 🕐 운영시간 화면

- **재사용**: 기존 `TeacherAvailabilitySplitPage` (마스터 스펙 §4 split 레이아웃)
- **수정**: 화면 제목 "레슨 운영 시간 설정" → "운영시간" (단순화)
- **섹션 순서**: ①주간 운영시간 ②레슨 간 쉬는시간 ③임시 휴무·추가 오픈 ④장기 휴가 모드
- **실시간 미리보기**: 마스터 스펙 §4 그대로 유지

### 6.2 🎓 수업방식 화면 (NEW)

- **신규 화면**: `LessonStyleSettingsScreen` (수업방식 전용)
- **위치**: `frontend/lib/features/profile/presentation/screens/lesson_style_settings_screen.dart`
- **라우트**: `AppRoutes.lessonStyleSettings = '/profile/lesson-style'`
- **섹션**:
  - 레슨 1회 시간 (선택: 30/45/50/60분, 기본 50분)
  - 최소 사전 예약 시간 (몇 시간 전부터 받기)
  - 학생 안내 메시지 (TextField)

### 6.3 💰 수강권·정산 화면

- **재사용 + 확장**: 메인 진입은 기존 메뉴 카드들 (수강권 템플릿, 계좌 관리, 입금 대기) 그룹화
- **신규 화면**: `PriceTableScreen` (악기·레벨별 가격표 — `LessonTimeSettingsScreen` §6 에서 분리)
- **신규 위치**: `frontend/lib/features/profile/presentation/screens/price_table_screen.dart`
- **시험 레슨 정책**: **`SubscriptionTemplatesScreen` 내부 "시험 레슨" 섹션 확정** (PLAN O1 결정) — 별도 화면 신설 회피, 첫 수강권 발급 흐름과 한 화면에서 결정

### 6.4 👤 내 프로필 화면

- 기존 화면들 그대로 유지 (기본정보 / 악기관리 / 자격증 / 레퍼토리 / 공개 미리보기)

### 6.5 ⚙️ 정책·알림·지원 화면

- 기존 화면들 그대로 + **"가이드 다시 보기"** 신규 메뉴 (퀘스트 졸업 후 fallback, §8.4)

---

## 7. 메인 홈 (DashboardTab) 변경

### 7.1 노출 요소 순서 (게임 디자인 spotlight 친화)

```
1. 요청/컨텍스트 배너 (긴급)
2. 오늘 레슨
3. 통계 카드
4. 퀘스트 보드 (졸업까지만 — §8)
5. 자주 쓰는 3카드 (입금대기 / 운영시간 / 수강권)
6. 5묶음 카테고리 메뉴 (NEW — 한 화면 안에 5개 카드 그리드)
```

### 7.2 5묶음 카테고리 메뉴 영역 (NEW)

```
┌─ 설정 ──────────────────────────────────┐
│ 🕐 운영시간          [설정완료 ✓]        │
│ 🎓 수업방식          [3/4 항목]          │
│ 💰 수강권·정산       [미설정 ⚠]   ●     │
│ 👤 내 프로필         [설정완료 ✓]        │
│ ⚙️ 정책·알림·지원   [기본값]            │
└────────────────────────────────────────┘
```

- 각 카드 우측에 진행 상태 라벨 + 미설정 시 노란 점 affordance
- 탭 → 해당 카테고리 화면 진입
- "레슨 시간 설정" / "가용 요일/시간" 메뉴 항목 삭제 (5묶음으로 흡수)

---

## 8. 퀘스트 보드 위치 (게임 디자인 결정)

### 8.1 결정: Notion 모델 — 메인 노출 유지 + 자연 졸업

별도 메뉴로 빼지 않는다. 게임 디자인 onboarding quest 의 표준 패턴 (Notion / GitHub / Slack onboarding) 차용.

### 8.2 졸업 메커니즘 (NEW)

```
0~99% 완료     → 메인 중간 영역 노출 (현재 위치 유지)
                  · 완료 quest 는 카드에서 축소/접힘
                  · 잠긴 quest (Q7~10) 는 자물쇠 표시

100% 완료      → 졸업 카드 1주일 노출 후 자동 dismiss
                  · 졸업 후 메인에서 자동 사라짐
                  · "가이드 다시 보기" 는 ⚙️ 정책·알림·지원 메뉴에서만 접근

명시적 dismiss → 사용자가 X 탭하면 "잠시 숨김" → 1주 후 다시 노출 (졸업 전에만)
```

### 8.3 데일리/이벤트 quest (미래)

이번 스펙 범위 밖. 추후 추가 시 별도 화면 신설 검토 (LoL lobby Missions 패턴).

### 8.4 "가이드 다시 보기" fallback

⚙️ 정책·알림·지원 → "가이드 다시 보기" 메뉴 추가:
- 졸업한 퀘스트 보드 다시 노출
- 5묶음 카테고리 미리보기 (Step 2.5) 재실행 가능

### 8.5 학생 quest

이번 스펙 범위 밖. 학생용 quest 시스템은 별도 의사결정.

---

## 9. 가입 후 첫 진입 흐름

### 9.1 단계 (게임 First-Session 원칙)

```
Step 1: ProfileSetupScreen (기존)
        이름·사진·악기

Step 2: FirstAvailabilitySetupScreen (기존)
        운영시간 1회 간소 설정 (최소 1개 슬롯)

Step 2.5: CategoryPreviewScreen (NEW)
        5묶음 카테고리 한 화면 미리보기
        [시작하기] 또는 [건너뛰기] — 스킵 가능, 1회만
        → questFirstShownProvider 와 별도 onboardingCategoryShownProvider 로 영속

Step 3: 메인 DashboardTab 첫 진입
        questFirstShownProvider == false:
          → 1회 spotlight (화면 어둡게 + 다음 미션 카드 1개만 highlight)
          → "여기부터 시작하시면 끝나요" 말풍선
          → [시작] tap → spotlight 종료, 미션 화면 진입
          → [나중에] tap → spotlight 종료, 메인 평상 상태
          → 두 번째 진입부터 spotlight 없음
```

### 9.2 Step 2.5 화면 시안

```
┌─ 환영합니다! 5가지 묶음으로 정리해뒀어요 ─┐
│                                          │
│  🕐 운영시간      🎓 수업방식             │
│  💰 수강권·정산   👤 내 프로필            │
│  ⚙️ 정책·알림                            │
│                                          │
│  나머지는 퀘스트가 안내해드려요            │
│                                          │
│           [시작하기]   [건너뛰기]          │
└──────────────────────────────────────────┘
```

신규 화면: `OnboardingCategoryPreviewScreen`
위치: `frontend/lib/features/onboarding/presentation/screens/onboarding_category_preview_screen.dart`

### 9.3 진행 추적 정합성 (SC-6)

```
퀘스트 100% 완료 == 프로필 완성도 게이지 100%
```

현재 약간 어긋난 부분 (Q11 보너스가 게이지에 영향 주는지) 명시:
- **Q11 (전화인증, 보너스)** 는 게이지 100% 에 미포함 (선택)
- **Q1~Q10 (필수)** 만 게이지 산정

테스트 (필수):
- Q1~Q10 모두 완료 → 게이지 100%
- Q11 만 완료 → 게이지 0%
- Q1~Q10 + Q11 완료 → 게이지 100% (Q11 보너스 표시만 추가)

### 9.4 졸업 영속 (BE 컬럼 신설 없음 — architect P0 #2)

기존 `User.quest_celebrated_at` (`backend/app/models/user.py:61`) 의 의미를 재정의:
- **변경 전**: "Q1~Q11 모두 완료 (11/11) 시 1회 축하 카드" 트리거
- **변경 후**: "**Q1~Q10 (필수) 100% 완료 = 졸업** 시점". Q11 보너스 표시는 별도 FE Hive flag (`quest_bonus_shown_provider`)

근거:
- spec §14 비범위 "백엔드 API 스키마 변경" 준수
- glossary 원칙 §1 "하나의 개념 = 하나의 이름" — 졸업/축하 의미 동일하므로 두 컬럼 공존 회피
- 7일 dismiss 카운트 (§8.2) 는 `quest_celebrated_at` 기준 + `kQuestGraduationGrace` 상수 (`core/constants/durations.dart`)

---

## 10. 기존 선생님 마이그레이션 (이미 가입한 사용자)

### 10.1 1회 overlay (앱 업데이트 후 첫 진입)

기존 가입 선생님이 새 5묶음 카테고리를 처음 인지하도록:

- Step 2.5 화면을 1회 overlay 로 재활용
- 스킵 가능
- `onboardingCategoryShownProvider` 영속 → 1회만 노출

### 10.2 메뉴 NEW 배지

새 5묶음 카테고리 카드에 7일간 NEW 점 표시:
- 한 번 진입하면 해당 카드의 NEW 점 사라짐
- 7일 경과 자동 dismiss

### 10.3 메뉴 매핑 안내 (1회)

기존 사용자가 "레슨 시간 설정" 메뉴를 찾아 클릭 시도하면:
- 메뉴 자체는 사라졌으므로 이 경로 없음
- 대신 search/검색 결과에서 매핑: "레슨 시간 설정" 키워드 → "5묶음으로 정리됐어요, 어디로 이동하시겠어요?" 1회 안내 dialog (운영시간 / 수업방식 / 수강권·정산 3선택)

(검색 진입로 없으면 이 단계 생략 — 구현 시 결정)

### 10.4 데이터 마이그레이션 (앱 부팅 시 1회)

§5.4 마이그레이션 로직 동일. 무손실 보장.

---

## 11. 빈 상태 affordance + 진행 추적

### 11.1 5묶음 카테고리 카드 라벨 규칙

| 카테고리 | 라벨 조건 |
|---|---|
| 🕐 운영시간 | 슬롯 1개 이상 + 쉬는시간 설정 → "설정완료 ✓" / 없으면 "미설정 ⚠ ●" |
| 🎓 수업방식 | 모든 3항목 입력 → "설정완료 ✓" / 부분 → "N/3 항목" |
| 💰 수강권·정산 | 가격표 + 계좌 → "설정완료 ✓" / 가격표만 → "계좌 미설정 ⚠ ●" |
| 👤 내 프로필 | 이름·사진·악기 → "설정완료 ✓" / 부분 → "N/M 항목" |
| ⚙️ 정책·알림·지원 | 항상 "기본값" (선택적 설정이므로) |

### 11.2 진행 추적 = 퀘스트와 1:1

§9.3 정합성 규칙 + 위 빈 상태 affordance 가 동기화되도록:
- 카테고리 "설정완료" 조건 ⊃ 해당 퀘스트의 완료 조건
- 카테고리 라벨이 "설정완료 ✓" 인데 퀘스트 미완료 = 불가능

---

## 12. 관련 마스터 스펙 갱신 항목 (Phase 6 후 머지)

| 마스터 스펙 | 변경 사항 |
|---|---|
| `docs/specs/profile/profile_master.md` | §2 메뉴 구조를 5묶음 IA 로 교체. §3 기존 화면 목록에서 LessonTimeSettingsScreen 삭제, LessonStyleSettingsScreen + PriceTableScreen + OnboardingCategoryPreviewScreen 추가. |
| `docs/specs/schedule/availability_settings_ux_redesign_spec.md` | §4 화면 제목 "운영시간"으로 변경. SSOT 단일화 명시 (§5.1 인용). |
| `docs/specs/design/settings_information_architecture_spec.md` | 5묶음 IA 를 메인 IA 로 채택. |
| `docs/specs/design/teacher_quest_audit_2026-06-08.md` | §8 졸업 메커니즘 + §9.3 게이지 1:1 매핑 추가. |
| `docs/specs/onboarding/teacher_first_availability_setup.md` | Step 2.5 카테고리 미리보기 추가 명시. |
| `docs/specs/subscription/lesson_policy_settings.md` | 시험 레슨 정책 위치를 명시 (LessonTimeSettingsScreen 에서 이동). |

---

## 13. 유비쿼터스 언어 갱신 (glossary 동기화)

`.harness/knowledge/glossary.md` 추가/변경:

| 용어 | 정의 | 사용 금지 표현 |
|---|---|---|
| **운영시간** (Operating Hours) | 선생님이 가르치는 요일별 시간대 + 쉬는시간 + 휴무 + 휴가. `TeacherAvailability` 엔티티 | 가용시간, 가용 슬롯, 가용 요일, available slot, 레슨 시간 |
| **수업방식** (Lesson Style) | 레슨 1회 시간 + 사전예약 규칙 + 학생 안내 메시지. `TeacherSettings` 의 lesson* 필드 | 수업설정, 레슨방식, 수업 옵션 |
| **수강권·정산** (Subscription & Billing) | 수강권 템플릿 + 가격표 + 시험레슨 정책 + 계좌. | 결제, 빌링 (개별 용어는 OK) |
| **lessonDurationMinutes** | 레슨 1회 시간 (분). 기본값 50. | defaultLessonDuration, slotDurationMinutes (모두 deprecated) |
| **카테고리 미리보기** (Category Preview) | 가입 직후 Step 2.5 5묶음 인지 화면. | 카테고리 가이드, 5묶음 가이드 |
| **퀘스트 졸업** (Quest Graduation) | Q1~Q10 100% 완료 후 메인에서 자동 hide. | 퀘스트 완료 (개별 quest 완료와 구분) |

`docs/specs/glossary.md` (사용자 열람용) 도 같은 커밋에서 갱신.

---

## 14. 비범위 (Out of Scope)

- 학생용 quest 시스템
- 데일리/이벤트 quest
- 백엔드 API 스키마 변경 (운영시간 SSOT 통일은 클라이언트 로컬 마이그레이션만 — 백엔드 동기화는 별도 spec)
- 부원장/조교 관련 권한 위임
- 학원 모드 (대표 선생님 vs 소속 선생님 권한 분리)
- 다국어 (l10n ARB 파일 확장은 별도)

---

## 15. 평가 기준 (Phase 6 rubric)

| 기준 | 가중치 | 최소 합격 | 평가 방법 |
|---|---|---|---|
| 완성도 | 40% | 8/10 | SC-1~7 7개 기준 모두 통과 |
| 견고성 | 30% | 7/10 | 마이그레이션 3 시나리오 + 게이지 정합성 3 시나리오 테스트 통과 |
| 일관성 | 20% | 8/10 | 도메인 린터·UX 룰·glossary 위반 0건 |
| 간결성 | 10% | 7/10 | 새 화면 3개 (LessonStyle/PriceTable/CategoryPreview) + 1개 라우트 deprecated. 800줄 초과 파일 0. |

PASS 조건: 가중 평균 7.5+ AND 어느 항목도 5 미만 아님.

---

## 16. 적용 워크플로우 (worktree 병렬 개발)

`.claude/rules/worktree-parallel-workflow.md` 규칙에 따라:

1. 본 스펙 승인 후 `EnterWorktree({name: "teacher-settings-redesign"})` 로 worktree 진입
2. 구현 단계는 다음 분할 (병렬 가능):
   - **W1**: 데이터 마이그레이션 + 엔티티 통일 (`lessonDurationMinutes` 리네임 + `availableSlots` deprecated)
   - **W2**: 5묶음 카테고리 메뉴 + ProfileTab 재배치
   - **W3**: LessonStyleSettingsScreen + PriceTableScreen 신규
   - **W4**: OnboardingCategoryPreviewScreen + Step 2.5 흐름
   - **W5**: 퀘스트 졸업 메커니즘 + 게이지 1:1 정합성
   - **W6**: 기존 사용자 마이그레이션 overlay + NEW 배지
3. 각 W 는 작업 완료 후 `/handoff-verify` 통과 + Playwright 스크린샷 회귀 → main 으로 PR merge
4. 모든 W merge 후 통합 회귀 1회 + Phase 6 rubric 평가

---

## 16.5. PLAN OPEN 결정 통합 (architect 검토 반영 후 확정)

| # | 항목 | 확정 결정 |
|---|---|---|
| O1 | 시험 레슨 정책 위치 | `SubscriptionTemplatesScreen` 내부 섹션 (§6.3 반영 완료) |
| O2 | 가격표 화면 명칭 | `PriceTableScreen` |
| O3 | 5묶음 카드 진행 라벨 데이터 | FE entity 직접 계산 (BE API 변경 없음) |
| O4 | 마이그레이션 overlay 트리거 | `onboardingCategoryShownProvider` (SharedPreferences) — 기존+신규 통합 |
| O5 | 검색 진입로 매핑 | 생략 (현재 검색 진입로 없음) |
| O6 | 졸업 dismiss 카운트 시작 | **기존 `User.quest_celebrated_at` 재사용** + 의미 재정의 (§9.4) — BE 컬럼 신설 없음 (architect 검토 반영) |
| O7 | `lessonDurationMinutes` 마이그레이션 시점 | 앱 부팅 시 1회 (`teacher_settings_provider` init) |
| O8 | "운영시간" 라벨 변경 시점 | W2 (메뉴 재배치) 단계에서 일괄 (`AppStrings` 단일 i18n key) |

## 17. 다음 단계

1. **사용자 검토** — 본 스펙 검토 후 OK 시
2. **glossary 갱신** — `.harness/knowledge/glossary.md` + `docs/specs/glossary.md` 동기화
3. **Plan 단계 진입** (`writing-plans` 스킬) — 구현 계획 작성
4. **worktree 생성 + 병렬 구현**
5. **Phase 6 평가** → 통과 후 마스터 스펙들로 머지 (§12)

---

## 부록 A — 관련 코드 위치 (참조용)

| 영역 | 경로 |
|---|---|
| 프로필 메인 | `frontend/lib/features/profile/presentation/screens/profile_tab.dart` |
| 해체 대상 | `frontend/lib/features/profile/presentation/screens/lesson_time_settings_screen.dart` (861줄) |
| 운영시간 SSOT | `frontend/lib/features/schedule/presentation/screens/teacher_availability_split_page.dart` |
| 운영시간 엔티티 | `frontend/lib/features/schedule/domain/entities/teacher_availability.dart` |
| profile 엔티티 (마이그레이션 대상) | `frontend/lib/features/profile/domain/entities/teacher_settings.dart` |
| 퀘스트 보드 | `frontend/lib/features/home/presentation/widgets/quest_board_card.dart` |
| 가입 흐름 | `frontend/lib/features/onboarding/presentation/screens/first_availability_setup_screen.dart` |
| 메인 홈 | `frontend/lib/features/home/presentation/widgets/dashboard_tab.dart` |
| 라우트 | `frontend/lib/core/router/app_routes.dart` |
| Provider (마이그레이션 필요) | `frontend/lib/features/profile/presentation/providers/quest_*_provider.dart` |
