# 선생님 첫 가용시간 설정 스펙 (Teacher First Availability Setup)

> 작성일: 2026-06-01
> 상태: 스펙 초안
> 출처: E2E 감사 Top 10 #1 AB-C1 — `docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`
> 관련 이슈: #422
> 관련 스펙: [teacher_onboarding_v3_spec.md §3 Phase B](teacher_onboarding_v3_spec.md), [schedule/teacher_availability_spec.md](../schedule/teacher_availability_spec.md)
> 글로서리: [glossary.md §3 첫 가용시간](../../.harness/knowledge/glossary.md), [§3 레슨 1회 시간 / 쉬는 시간](../../.harness/knowledge/glossary.md)

---

## 1. 문제 정의

E2E 감사 정량 입증: `grep WeeklySchedule frontend/lib/features/onboarding/` = **0건**.

### 1.1 현재 결함

| # | 문제 | 영향 |
|---|---|---|
| 1 | 선생님 가입 직후 `WeeklySchedule` 가 비어 있음 | 학생이 예약할 슬롯 0개 |
| 2 | 가용시간 설정이 온보딩 필수 흐름에 없음 | D 단계(학생 초대) 진입해도 예약 불가 |
| 3 | 풀 가용시간 화면(`teacher_availability_spec.md`)이 너무 복잡 | 첫 등록 포기 → C 단계 이탈 |
| 4 | 가용시간 0개 상태에서 홈 진입 시 안내 부재 | 신규 선생님이 무엇을 해야 할지 모름 |

### 1.2 영향 범위 (펀넬)

B → C 단계 전이 게이트 깨짐. 학생 초대해도 "예약 가능 시간 없음" → 첫 인상 실패 → 학생-선생님 동시 이탈.

v3 spec §1 자체에서 "레슨 시간/가용 시간 설정이 온보딩에 없음 → 학생이 예약 불가" 를 **CRITICAL** 로 명시했으나 미구현.

---

## 2. 설계 원칙

> **"30초 안에 첫 가용시간을 등록한다. 풀 설정은 나중에."**

| 원칙 | 의미 |
|---|---|
| 블로커 퀘스트 | 가용시간 1개도 없으면 다른 퀘스트(학생 초대·레슨 등록) 잠금 |
| 단일 화면 | 요일 다중선택 + 시작/종료시각 1쌍 + 적용 1탭. 풀 설정은 별도 화면에서 |
| 합리적 기본값 | 레슨 1회 50분 / 쉬는 시간 10분 / 시작 간격 60분 (한국 음악 레슨 표준) |
| 가입 흐름 내 인라인 4단계 (스킵 가능, 2026-08-12 개정) | 가입 흐름의 `first_availability_setup_screen` 이 프로필(3단계) 직후 4번째 단계로 진입. 우측 상단 "나중에 설정"으로 즉시 스킵 가능 — §3.4 참조 |
| 점진적 공개 | 첫 등록 후에야 반복·예외·여러 블록 등 고급 옵션 노출 |

---

## 3. 흐름

```
[온보딩 Phase A — 이름 + 악기 입력 완료]
    │
    ▼
[가입 흐름 내 — first_availability_setup_screen 인라인 4단계 진입 (2026-08-12 개정)]
  간소 가용시간 설정 화면 (OnboardingStepHeader 4/4)
  요일 다중선택 + 시작/종료시각 1쌍 + [적용]   또는   AppBar "나중에 설정"
    │                                              │
    ▼ WeeklySchedule.isActive = true 1+개 생성       ▼ 슬롯 생성 없이 즉시
  셀레브레이션 시트 "첫 가용시간 등록 완료!"              context.go(/home)
    │
    ▼
[Step 2.5 — OnboardingCategoryPreviewScreen (W4, 2026-06-12)]
  새 5묶음 카테고리 미리보기 (운영시간/수업방식/수강권·정산/내 프로필/정책·알림·지원)
  [시작하기] / [건너뛰기] 둘 다 markShown + /home 라우트
  onboardingCategoryShownProvider (Hive) 영속 — 1회만 노출
    │
    ▼
[홈 진입] — 가용시간 1개 이상 보장 또는 "나중에 설정"으로 스킵
  퀘스트 보드 표시
  · 필수 퀘스트: 첫 학생 초대 (가용시간 보장 후 활성)
  · 필수 퀘스트: 첫 레슨 등록 (가용시간 보장 후 활성)
  · 스킵한 경우: NextMissionSpotlight(dashboard_tab.dart)/퀘스트 보드가 리마인더 역할
```

2026-08-12 이전에는 `first_availability_setup_screen` 이 실제 가입 흐름에서 도달 불가능했다 (#430 이 프로필 저장 직후 `completeOnboarding()` + 홈 직행으로 변경하며, #422/#646 이 만든 라우터 phase 게이트를 우회). `OnboardingStepHeader.teacherSteps` 는 4단계를 표시했지만 실제로는 3단계에서 끝났다 (teacher-journey 감사 2026-08-11, P1-7). 본 개정은 `ProfileSetupScreen` 의 다음 화면을 홈에서 이 화면으로 바꾸는 인라인 네비게이션만으로 해결했다 — `completeOnboarding()` 호출 시점은 그대로이므로 라우터의 `AuthNeedsOnboarding` 리다이렉트 가드와 충돌하지 않는다 (§3.4).

### 3.3 Step 2.5 — 카테고리 미리보기 (2026-06-12 신규)

teacher-settings-redesign W4 머지 — 가입 직후 신규 5묶음 IA (`profile_master.md §2.1`) 를 1회 인지.

| 항목 | 내용 |
|---|---|
| 화면 | `OnboardingCategoryPreviewScreen` (`features/onboarding/presentation/screens/`) |
| 노출 시점 | first_availability_setup 완료 후 1회 (스킵 가능, 영속 후 재노출 X) |
| 콘텐츠 | 5묶음 카테고리 카드 (🕐 운영시간 / 🎓 수업방식 / 💰 수강권·정산 / 👤 내 프로필 / ⚙️ 정책·알림·지원) 미리보기 그리드 + 한 줄 안내 |
| 액션 | [시작하기] / [건너뛰기] 두 버튼 모두 `markShown()` + `context.go(/home)` |
| 영속 | `onboardingCategoryShownProvider` (Hive box `onboarding_state` / key `category_preview_shown`) |
| 마이그레이션 재활용 | W6 의 `TeacherMigrationOverlayGate` 가 기존 가입자 ProfileTab 첫 진입 시 동일 화면을 overlay 로 1회 재활용 (W6 §10.1) |

### 3.1 종착 조건

`WeeklySchedule` 엔티티에서 `isActive = true` 인 항목이 **1개 이상** 존재하면 본 단계 완료.

### 3.2 풀 설정 이관 경로

첫 등록 후 선생님이 "더 자세히 설정" 탭 시 기존 `teacher_availability_spec.md` 화면으로 이동. 본 스펙의 간소 UI 는 **최초 1회만 노출**.

### 3.4 인라인 4단계 진입 + 스킵 (2026-08-12 개정)

| 항목 | 내용 |
|---|---|
| 진입 | `ProfileSetupScreen._submit()` 성공 시 `context.go(AppRoutes.teacherFirstAvailability)` — 기존의 `context.go(AppRoutes.home)` 을 대체 |
| completeOnboarding 시점 | 프로필 저장 직후(기존과 동일) — 이 화면 도달 시점엔 이미 `AuthAuthenticated` 상태이므로 라우터의 `AuthNeedsOnboarding` phase 게이트(`OnboardingPhase.firstAvailability`, #646)는 관여하지 않는다. 홈의 `NextMissionSpotlight` 가 `context.push(AppRoutes.teacherFirstAvailability)` 로 진입하는 기존 경로와 동일한 방식 |
| 스킵 CTA | AppBar 우측 상단 "나중에 설정" (`AppStrings.firstAvailabilitySkipAction`) — 상시 노출, 스크롤 불필요. 탭 시 슬롯 생성 없이 `context.go(AppRoutes.home)` |
| 스킵 후 리마인더 | 홈의 `NextMissionSpotlight`(`dashboard_tab.dart`) + 퀘스트 보드가 기존과 동일하게 안내를 이어받는다 |
| 참고 | §2 "가입 흐름 내 강제(스킵 불가)" 원칙은 이 개정으로 완화되었다. 실제로는 #430 이후 이미 스킵 가능한 상태였고(도달 자체가 불가능했으므로), 본 개정은 그 실태를 인라인 UX 로 명시적으로 인정한 것 |

---

## 4. UI 정의

### 4.1 인터스티셜 모달 — **폐기됨 (2026-06-10)**

> **폐기 사유**: 가입 흐름 내 `first_availability_setup_screen` 이 슬롯 1개 이상을 이미 강제하므로 홈 진입 시 인터스티셜은 중복이다.
> **대체 구현**: §3 흐름 다이어그램 (가입 흐름 내 게이트). 코드 SSOT 는 `auth/presentation/screens/auth_landing_screen.dart` 의 redirect 분기.
> **삭제된 파일**: `frontend/lib/features/onboarding/presentation/widgets/first_availability_interstitial.dart`, `onboarding_facade.dart` 의 `showFirstAvailabilityInterstitial` export.

원본 모달 디자인은 변경 이력 (2026-06-01) 참조. 본 섹션은 향후 동일 정책 재도입 시 비교 기준으로 보존한다.

### 4.2 간소 가용시간 설정 화면

```
┌────────────────────────────────────────┐
│  ← 첫 가용시간 설정                     │
│                                        │
│  레슨 가능한 요일                       │
│  ┌────┬────┬────┬────┬────┬────┬────┐ │
│  │ 월 │ 화 │ 수 │ 목 │ 금 │ 토 │ 일 │ │
│  │ ●  │ ●  │    │ ●  │ ●  │    │    │ │ ← 다중선택
│  └────┴────┴────┴────┴────┴────┴────┘ │
│                                        │
│  레슨 가능한 시간                       │
│  시작: [14:00 ▼]  종료: [18:00 ▼]      │
│                                        │
│  ─────────────────────────────────────  │
│  기본값 (나중에 변경 가능)               │
│  · 레슨 1회 시간: 50분                  │
│  · 쉬는 시간: 10분                      │
│  · 시작 간격: 60분                      │
│                                        │
│  ┌──────────────────────────────┐      │
│  │           적용하기             │      │
│  └──────────────────────────────┘      │
│                                        │
│  [더 자세히 설정]                       │
└────────────────────────────────────────┘
```

#### 4.2.1 입력 검증

| 필드 | 검증 |
|---|---|
| 요일 다중선택 | 1개 이상 선택 필수 |
| 시작 시각 | 00:00~23:00 (30분 단위) |
| 종료 시각 | 시작 시각보다 늦어야 함, 최소 1시간 차이 |

#### 4.2.2 적용 시 동작

선택된 요일별로 `WeeklySchedule` 인스턴스 1개씩 생성:

```dart
for (final day in selectedDays) {
  WeeklySchedule(
    dayOfWeek: day,
    startTime: startTime,
    endTime: endTime,
    slotDurationMinutes: 50,         // 레슨 1회 시간
    breakTimeBetweenLessons: 10,     // 쉬는 시간
    slotStartInterval: 60,           // 시작 간격
    isActive: true,
  )
}
```

### 4.3 셀레브레이션 시트

```
┌────────────────────────────────────────┐
│              🎉                         │
│       첫 가용시간 등록 완료!             │
│                                        │
│  이제 학생이 이 시간에 레슨을           │
│  예약할 수 있어요.                      │
│                                        │
│  다음 단계: 첫 학생 초대하기             │
│                                        │
│  ┌──────────────────────────────┐      │
│  │       다음 퀘스트으로          │      │
│  └──────────────────────────────┘      │
└────────────────────────────────────────┘
```

---

## 5. 백엔드 영향

### 5.1 신규 필드/엔티티

**없음.** 기존 `WeeklySchedule` 엔티티 그대로 사용. 본 스펙은 UI/플로우 변경.

### 5.2 신규 API

**없음.** 기존 `POST /api/teachers/:id/weekly-schedules` 사용.

### 5.3 메트릭 이벤트

| 이벤트 | 트리거 | 페이로드 |
|---|---|---|
| `onboarding.first_availability.shown` | 인터스티셜 모달 노출 | `teacherId`, `timestamp` |
| `onboarding.first_availability.completed` | WeeklySchedule 1+개 생성 | `teacherId`, `dayCount`, `durationMinutes` |
| `onboarding.first_availability.skipped` | "더 자세히 설정" 탭 (간소 화면 우회) | `teacherId` |

---

## 6. 측정 기준

| 지표 | 측정 방법 | 목표 |
|---|---|---|
| 간소 UI 코드 존재 | `grep WeeklySchedule frontend/lib/features/onboarding/` | ≥ 1 |
| 24h 내 첫 가용시간 등록률 | `onboarding.first_availability.completed / signup` | > 80% |
| 간소 UI 완료 평균 시간 | 모달 노출 ~ 적용 탭 | < 60초 |
| 가용시간 0개 상태 홈 진입 차단율 | 인터스티셜 노출 / WeeklySchedule.count=0 | 100% |
| 간소 → 풀 설정 이동률 | `onboarding.first_availability.skipped` / `shown` | < 20% (간소가 충분히 쓸 만한지 검증) |

---

## 7. 구현 범위 (Phase 별)

### Phase 1: 스펙 + 글로서리 (본 작업)

- [x] `teacher_first_availability_setup.md` 신규 작성
- [x] `glossary.md` "첫 가용시간" 추가 (이미 §3에 반영)
- [x] `teacher_onboarding_v3_spec.md` §3 Phase B 에 본 스펙 참조 추가 (메인 세션 처리)

### Phase 2: 프론트엔드 (3-5일)

- 인터스티셜 모달 컴포넌트 (`OnboardingFirstAvailabilityModal`)
- 간소 가용시간 화면 (`FirstAvailabilitySetupScreen`)
- 홈 진입 시 가용시간 0개 감지 + 모달 트리거
- 셀레브레이션 시트 (기존 `CelebrationSheet` 재사용)
- 라우터 가드 (가용시간 0개면 다른 퀘스트 진입 차단)

### Phase 3: 메트릭 + 검증 (1-2일)

- 메트릭 이벤트 3종 발송
- 위젯 스모크 테스트 (`first_availability_setup_screen_test.dart`)
- 인터스티셜 차단 통합 테스트

---

## 8. 변경 이력

| 버전 | 날짜 | 내용 |
|---|---|---|
| 1.0 | 2026-06-01 | 초안 — E2E 감사 #1 AB-C1 대응 (이슈 #422) |
| 1.1 | 2026-06-10 | §2/§3/§4.1 인터스티셜 정책 폐기 → 가입 흐름 내 강제 게이트로 일원화 (감사 §4.3 B1). dead code 제거: `first_availability_interstitial.dart`, `showFirstAvailabilityInterstitial` export. |
| 1.2 | 2026-08-12 | §2/§3/§3.4 — `first_availability_setup_screen` 을 `ProfileSetupScreen` 직후 인라인 4단계로 승격 + "나중에 설정" 스킵 CTA 추가 (teacher-journey 감사 2026-08-11, P1-7). #430 이후 이 화면이 실제 가입 흐름에서 도달 불가능했던 드리프트를 해소. §2 "스킵 불가" 원칙을 스킵 가능으로 완화. |
