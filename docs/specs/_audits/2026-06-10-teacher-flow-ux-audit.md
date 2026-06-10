# 선생님 가입→설정 퀘스트→스케줄 조절 UX 점검 + 개선 디자인

> 작성일: 2026-06-10
> 작성자: Claude (UX 점검 세션)
> 상태: 사용자 검토 대기
> 범위: P0+P1+P2 11건

## 1. 점검 결론 (Inverted Pyramid)

3개 흐름 모두 **기능적으로는 동작**하지만, **11개의 UX 마찰/스펙 불일치**가 누적되어 신규 선생님이 "무리 없이" 도착하기 어렵습니다. 가장 큰 차단 요인은:

| # | 차단 요인 | 영향 |
|---|---|---|
| A1 | 소개글 validation 충돌 — 화면="선택", 코드="20자 필수" | 가입 진행 실패 가능 |
| B1 | 스펙(인터스티셜) vs 코드(가입 흐름 강제) 불일치 + dead code | 신규 개발자 혼란, 잘못된 기준 적용 |
| C1 | 주간 스케줄 시간대 **삭제 경로 없음** | 잘못 추가한 시간 제거 불가 |

## 2. 작업 범위 (11건)

### A. 회원가입 흐름

| # | 갭 | 우선 |
|---|---|---|
| A1 | Phase A 소개글: 화면=선택, 코드=20자 필수 → 가입 차단 | P0 |
| A2 | `AuthNeedsOnboarding` 단일 상태 — Phase 진행도 미추적 | P2 |

### B. 설정 퀘스트

| # | 갭 | 우선 |
|---|---|---|
| B1 | 스펙 vs 코드 불일치 + `showFirstAvailabilityInterstitial` dead code | P0 |
| B2 | Phase B 코치마크 3-step → 실제 1단계만 구현 | P1 |
| B3 | Q7~Q10 잠금 해제 보상 시각화 없음 | P1 |
| B4 | 자동 완료 카드 사운드/애니 없음 | P2 |

### C. 스케줄 조절

| # | 갭 | 우선 |
|---|---|---|
| C1 | 주간 스케줄 TimeChip 삭제 경로 없음 | P0 |
| C2 | 휴가 취소 진입점 분산 (Banner vs TimeException) | P1 |
| C3 | 가용시간 변경 시 기존 예약 영향 안내 부재 | P1 |
| C4 | 휴무 1일 vs 방학 모드 시각 구분 없음 | P2 |
| C5 | 풀 ↔ 간소 화면 흐름 명문화 부재 | P2 |

## 3. 사용자 결정 (이미 합의됨)

| 결정 | 선택 | 영향 |
|---|---|---|
| **C1 — 시간대 삭제 패턴** | Wrap chip 그리드 → ListTile 세로 그리드 + `SwipeActionTile` | UI 큰 변경, 일관성 개선 |
| **B3 — 잠금 해제 보상** | BottomSheet 축하 + 일첨 애니 | `FirstAvailabilityCelebrationSheet` 패턴 재사용 |
| **B1 — 스펙 SSOT 방향** | 코드가 맞다 — 스펙 갱신 + dead code 제거 | 스펙 1개 갱신, 파일 1개 삭제 |

## 4. 디자인 (갭별 구현 방향)

### 4.1 A1 — 소개글 validation 정리 (P0)

**현 상태**: `profile_setup_screen.dart` 의 `_introController` 가 화면엔 "선택"이라 표시되나, `TeacherOnboardingProfile.isValid` 가 `introduction.length >= 20` 을 강제.

**조치**:
- v3 스펙 §3.2 (Phase A=이름+악기만) 준수
- `_introController` + 소개글 입력 섹션 **완전 제거**
- `TeacherOnboardingProfile.isValid` → `name.isNotEmpty && instruments.isNotEmpty` 만
- 소개글은 Phase C 보상 퀘스트로 이동 (이미 스펙에 정의됨)

### 4.2 A2 — 라우터 redirect Phase 세분화 (P2)

**현 상태**: `AuthNeedsOnboarding` 단일 상태 → 부분 완료 사용자가 어디로 갈지 불명확.

**조치**:
- `AuthNeedsOnboarding` 에 `phase` 속성 추가 (`profileA` | `firstAvailability` | `complete`)
- `resolveAuthRedirect()` 분기:
  - `profileA` 미완료 → `profileSetup`
  - 가용시간 0개 → `firstAvailabilitySetup`
  - 둘 다 완료 → `home`

### 4.3 B1 — 스펙 갱신 + dead code 제거 (P0)

**현 상태**: 
- `teacher_first_availability_setup.md` §3 흐름이 "홈 진입 시 인터스티셜 모달" 이지만
- 실제 정책은 가입 흐름 내 `first_availability_setup_screen.dart` 강제 (#422 폐기 결정 적용됨)

**조치**:
- `teacher_first_availability_setup.md` §3 흐름 다이어그램 갱신: "온보딩 흐름 내 강제 → 홈 진입 시 가용시간 1개 이상 보장됨"
- §2 "인터스티셜 차단" 원칙 제거, "온보딩 흐름 내 게이트" 로 대체
- `frontend/lib/features/onboarding/presentation/widgets/first_availability_interstitial.dart` 삭제
- `onboarding_facade.dart` 의 `show showFirstAvailabilityInterstitial` export 제거
- `teacher_onboarding_v3_spec.md` §3.3 보강 인용 갱신

### 4.4 B2 — Phase B 3-step 코치마크 (P1)

**현 상태**: `coach_mark_scope.dart` 에 `lesson_time_settings` 1단계만 등록.

**조치**:
- 코치마크 2: `first_student_invite` — 학생 탭 → "학생 추가" 버튼 하이라이트
- 코치마크 3: `first_lesson_register` — "+" 플로팅 버튼 또는 레슨 탭 하이라이트
- 각 화면에 `GlobalKey` 부여, `CoachMarkScope` 에 sequence 등록
- 시퀀스 종료 시 `퀘스트 보드 표시` 트리거

### 4.5 B3 — 잠금 해제 BottomSheet 축하 (P1)

**현 상태**: Q7~Q10 lock 상태 tap → toast 만.

**조치**:
- 신규 위젯: `QuestUnlockCelebrationSheet` (`FirstAvailabilityCelebrationSheet` 패턴 차용)
- Q6 완료 시 Q7~Q10 자동 unlock → sheet 1회 표시
- 일첨(unlock) 애니: ScaleTransition(0.8 → 1.0) + Opacity(0 → 1) 400ms
- AppStrings 추가: `questUnlockCelebrationTitle`, `questUnlockCelebrationMessage`

### 4.6 B4 — 자동 완료 카드 사운드/애니 (P2)

**현 상태**: `quest_celebration_provider.dart` 의 자동 카드 2초 표시 — 사운드/애니 없음.

**조치**:
- `SystemSound.click` 1회 재생
- `ScaleTransition(0.9 → 1.0, 300ms)` + 1초 sustain + `FadeOut(500ms)`

### 4.7 C1 — Wrap chip → ListTile + SwipeActionTile (P0)

**현 상태**: `_DayRow.title` 의 `Wrap` 안에 `_TimeChip` 들 가로 배치, 삭제 불가.

**조치**:
- `_DayRow` 구조 변경:
  - leading: 요일 라벨 (유지)
  - title: 첫 시간대 (또는 "쉬는 날")
  - subtitle (요일에 2+개 시간대일 때): 나머지 시간대를 세로로 펼침
- **각 시간대를 별도 `SwipeActionTile` 행으로 분리** + 요일 그룹 헤더로 시각적 묶음 유지
- swipe 액션: `SwipeAction(label: "삭제", icon: Icons.delete_outline, tone: SwipeActionTone.destructive)`
- 삭제 전 확인 다이얼로그 (영향 받는 예약 카운트 안내 — C3과 통합)

#### 변경 후 레이아웃 스케치

```
┌── 화 ──────────────────────────────────┐
│ ⇆  14:00 - 16:00         [✏]          │ ← SwipeActionTile (swipe→삭제)
│ ⇆  17:00 - 19:00         [✏]          │
│ ⇆  20:00 - 21:00         [✏]          │
│                              [+ 추가]   │
└────────────────────────────────────────┘
┌── 수 ──────────────────────────────────┐
│         (쉬는 날)              [+ 추가] │
└────────────────────────────────────────┘
```

### 4.8 C2 — 휴가 취소 진입점 통합 (P1)

**현 상태**: `AvailabilityVacationBanner._VacationRow` 에 trailing 액션 없음, 취소는 `TimeExceptionScreen` 가야 함.

**조치**:
- `_VacationRow` 에 trailing `IconButton(Icons.close)` 추가
- `TimeExceptionScreen` 과 동일한 confirmation dialog 공유 (`_showCancelVacationDialog`)
- 취소 후 banner 자동 사라짐

### 4.9 C3 — 변경 시 기존 예약 영향 경고 (P1)

**현 상태**: WeeklySchedule 삭제/수정 시 영향 받는 예약 있어도 경고 없음.

**조치**:
- WeeklySchedule 삭제/수정 전: `getAffectedBookingsCount(weeklyScheduleId)` provider 호출
- 영향 > 0 시 confirmation dialog 강화:
  > "이 시간대를 삭제하면 N개 예약이 영향을 받습니다. 학생에게 자동 취소 알림이 전송됩니다."
- 영향 = 0 시 일반 확인 (Are you sure?)

### 4.10 C4 — 휴무 1일 vs 방학 모드 시각 구분 (P2)

**조치**:
- `AvailabilityVacationBanner` 에서 type 별 아이콘/색상 분기:
  - `vacation` (방학): `Icons.beach_access` + `paperAccent` 톤
  - `oneDay` (1일 휴무): `Icons.event_busy` + `inkSecondary` 톤
- 방학은 "{startDate} ~ {endDate} 방학 중", 휴무는 "{date} 휴무"

### 4.11 C5 — 풀 ↔ 간소 화면 흐름 명문화 (P2)

**조치**:
- `teacher_availability_spec.md` 에 §3.6 "간소(온보딩) ↔ 풀(설정) 화면 관계" 신규 섹션 추가:
  - 간소: 가입 흐름 1회성 (`first_availability_setup_screen.dart`)
  - 풀: 평시 조절 (`teacher_availability_split_page.dart`)
  - 진입 경로: 홈 → 설정 → 가용시간 / 간소에서 "더 자세히 설정" → 풀
- 간소 화면에 "더 자세히 설정" 진입 버튼 wiring 확인

## 5. 스펙 업데이트 대상

| 파일 | 변경 |
|---|---|
| `docs/specs/onboarding/teacher_first_availability_setup.md` | §2/§3 인터스티셜 폐기 → 가입 흐름 강제 명문화 |
| `docs/specs/onboarding/teacher_onboarding_v3_spec.md` | §3.2 소개글 완전 제거, §3.3 보강 인용 갱신 |
| `docs/specs/schedule/teacher_availability_spec.md` | §3.6 신규 (간소 ↔ 풀 관계), §7.1 주간 스케줄 UI 갱신 (chip→list) |
| `docs/specs/schedule/availability_settings_ux_redesign_spec.md` | §3.5 시간대 추가/삭제 UX 명문화 (swipe) |

## 6. 구현 분할 (Worktree 3개 병렬)

### Worktree A — `feat/teacher-signup-cleanup`
- 갭: **A1, A2**
- 영향 파일: `auth/`, `onboarding/profile_setup_screen.dart`, `core/router/`
- 예상 변경: 약 6-8 파일

### Worktree B — `feat/quest-spec-align`
- 갭: **B1, B2, B3, B4**
- 영향 파일: `onboarding/widgets/`, `home/providers/`, `home/widgets/quest_board_card.dart`, `core/widgets/coach_mark/`, `quest_celebration_provider.dart`
- 영향 스펙: 2개 갱신
- 예상 변경: 약 10-15 파일

### Worktree C — `feat/schedule-edit-ux`
- 갭: **C1, C2, C3, C4, C5**
- 영향 파일: `schedule/screens/teacher_availability_split_page.dart`, `schedule/widgets/`, `schedule/widgets/availability/availability_vacation_banner.dart`, `schedule_edit_bottom_sheet.dart`
- 영향 스펙: 2개 갱신
- 예상 변경: 약 12-18 파일

## 7. 검증 계획

각 worktree:
- `flutter analyze` exit 0
- 위젯 스모크 테스트 (변경된 top-level 위젯마다)
- 변경된 UX 흐름 시각 확인 (메모리 노트 frontend-verify 규칙 준수)

main 머지 전 통합:
- 3개 worktree 통합 시 충돌 0
- 핵심 흐름 E2E: 가입 → 가용시간 등록 → 홈 → 설정 → 스케줄 조절

## 8. 변경 이력

| 날짜 | 변경 |
|---|---|
| 2026-06-10 | 초안 작성 — 11건 갭 카탈로그 + 사용자 합의 3건 반영 |
