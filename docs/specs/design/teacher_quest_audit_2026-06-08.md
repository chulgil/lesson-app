# 선생님 퀘스트 시스템 UX 감사 보고서

> 작성일: 2026-06-08
> 작성 기준: UX 전문가 20년차 관점 — 사용자 여정 / 정보 구조 / 인지 부하 / SSOT
> 범위: Teacher 역할의 퀘스트 시스템 + 가입 흐름 + 설정 화면 교집합
> Step 1 산출물 (Step 2 스펙 초안 / Step 3 데이터 모델 / Step 4 구현 PR 의 선행 자료)

---

## 1. 퀘스트 인벤토리 (현재 시스템)

| # | Quest | 표시 위젯 | 진입 라우트 | 완료 조건 | 상태 |
|---|---|---|---|---|---|
| 1 | 레슨 시간 설정 | quest_board_card.dart:156 | `teacherFirstAvailability` | `hasSlots` (TeacherSettings.availableSlots 비어있지 않음) | 구현 |
| 2 | 프로필 사진 | :158 | `basicInfoEdit` (lock by Q1) | `hasPhoto` | 구현 |
| 3 | 소개글 작성 | :168 | `basicInfoEdit` (lock by Q1) | `hasIntro` (≥20자) | 구현 |
| 4 | 레슨비 설정 | :178 | `lessonTimeSettings` (lock by Q1) | `hasPrice` (priceTable 있음) | 구현 |
| 5 | 입금 계좌 | :190 | `bankAccountEdit` (lock by Q1) | `hasBankAcc` | 구현 |
| 6 | 첫 학생 초대 | :201 | `invite` (lock by Q1) | `hasStudents` (homeStudents 비어있지 않음) | 구현 |
| 7 | 첫 수강권 발급 | :209 | `issueSubscription` (lock by Q6) | `hasSubscription` | 구현 |
| 8 | 첫 레슨 완료 | :221 | `lessons` (lock by Q1) | `hasCompletedLesson` | 구현 |
| 9 | 레슨 메모 작성 | :230 | `quickFeedbackList` (lock by Q1) | `hasLessonNote` | 구현 |
| 10 | 연습 과제 등록 | :242 | `assignmentDashboard` (lock by Q1) | `hasPracticeAssigned >0` | 구현 |
| 11 | 전화인증 (선택) | :258 | `teacherPhoneVerification` | `isPhoneVerified` | 구현 |

**총 11개 퀘스트, 전체 구현됨.** Step 1(레슨 시간 설정)이 사실상 게이트 — 나머지 9개를 lock.

---

## 2. UX 전문가 7차원 평가

### 차원 1 — 목적 명료성 (4/10)

> **퀘스트가 "학습 가이드"인가, "필수 설정"인가, "마케팅 trigger"인가?**

| 신호 | 관찰 |
|---|---|
| Step 1 lock 게이트 | "필수" 신호 |
| Step 2~10 lock 없음 (Q6→Q7 외) | "자유 선택" 신호 |
| "Step N" 명명 | 일직선 절차 신호 |
| 실제 선택 가능 | 자유로운 신호 |

**문제**: 시그널이 충돌. "Step"이라는 단어는 순차적 절차를 암시하지만 실제로는 자유 선택. 사용자 정신 모델 형성에 실패.

### 차원 2 — 사용자 여정 정합성 (3/10)

> **가입 흐름이 입력받은 데이터가 퀘스트의 완료 조건으로 자연스럽게 연결되는가?**

가입 흐름:
```
role_select → profile_setup (이름·악기·사진·소개) → first_availability_setup (가용시간) → tutorial → home
```

여정 도착 시 퀘스트 보드 상태:
- Q1 (레슨 시간 설정) → ✅ 자동 완료 (방금 first_availability에서 입력)
- Q2 (프로필 사진) → ⚠️ `hasPhoto` 자동 감지되면 완료 (profile_setup에서 입력했다면)
- Q3 (소개글 20자+) → ⚠️ 20자 이상 입력했을 경우만. 19자면 미완료, **사용자에게 임계값 안내 없음**

**문제**:
- 사용자가 가입 직후 home에 도착했는데 퀘스트가 일부 미완료로 보일 수 있음
- 가입에서 "충분히" 입력했다고 생각한 사용자가 "왜 또 입력해야 하지?"라는 의문

### 차원 3 — 퀘스트 vs 설정 역할 분리 (2/10)

> **퀘스트가 단축 진입점인가, 별도 입력 화면인가?**

| 항목 | 퀘스트 진입 | 설정 진입 | 중복도 |
|---|---|---|---|
| **레슨 시간 (가용시간)** | `first_availability_setup` (전용 화면) | `teacher_availability_split_page` | 🔴 **P0** — 별도 화면, 별도 provider, 별도 도메인 (profile vs schedule) |
| **프로필 사진/소개** | `basic_info_edit` | `basic_info_edit` | ✅ 같은 화면 (단축 진입점) |
| 레슨비 | `lesson_time_settings` | `lesson_time_settings` | ✅ 같은 화면 |
| 계좌 | `bank_account_edit` | `bank_account_edit` | ✅ 같은 화면 |
| 학생 초대 | `invite` | (학생 탭에서도 가능) | ⚠️ 추가 확인 필요 |

**문제**:
- Q1만 별도 화면. SSOT 위반. **P0 데이터 불일치 위험**.
- 나머지는 단축 진입점으로 작동 — 좋은 패턴.

### 차원 4 — 완료 기준 (5/10)

| 항목 | 사용자 가시성 |
|---|---|
| Q3 hasIntro `≥20자` | ❌ 임계값 미공개 — 19자 입력한 사용자 혼란 |
| Q4 hasPrice 기준 | ❓ 1원 입력해도 완료? 기준 모호 |
| Q10 hasPracticeAssigned `>0` | ⚠️ 1건이면 완료. 1회성 의미만 |

**문제**: 완료 임계값이 사용자에게 보이지 않음. "왜 안 끝나지?" 발생.

### 차원 5 — 진입점 일관성 (4/10)

- 대부분 퀘스트가 설정 메뉴에서도 같은 화면 진입 가능 — **OK**
- **first_availability_setup은 단일 진입점** (퀘스트만) — 가입 후 "첫 가용시간 설정 화면"을 다시 보고 싶을 때 경로 없음
- 사용자가 퀘스트에서 입력한 가용시간을 수정하려면 → 설정의 split_page (다른 화면). 인지적 부담

### 차원 6 — 스킵 정책 (3/10)

| 화면 | 정책 |
|---|---|
| profile_setup 이름·악기 | 필수 (validation) |
| profile_setup 사진·소개 | 선택 |
| first_availability_setup | **명시되지 않음** (코드 확인 필요) |
| Q11 전화인증 | 명시적 "선택 과제" |
| Q1~Q10 | 스킵 가능 여부 명시 없음 |

**문제**: 사용자가 "이건 꼭 해야 하나?"라는 의문. 압박감.

### 차원 7 — 재방문/수정 경로 (5/10)

- Q1 — 수정은 split_page (다른 화면). **비대칭**
- Q2~Q5 — 수정은 같은 화면. OK
- Q6/Q8 — 1회성 이벤트. "재방문" 개념 모호
- Q11 — 1회성 (인증 한 번)

**종합 점수: 26 / 70 (37%) — 시스템 차원 재설계 필요**

---

## 3. 핵심 발견 (우선순위순)

### 🔴 발견 1 — Q1 (레슨 시간 설정)의 이중 화면 + SSOT 위반

- `first_availability_setup_screen` (profile.TeacherSettings.availableSlots)
- `teacher_availability_split_page` (schedule.TeacherAvailability — 별도 엔티티/repository)
- 두 데이터는 **별개 저장소**, 동기화 안 됨

**파급**:
- 사용자가 두 곳에서 본 가용시간이 다를 수 있음
- 퀘스트에서 입력한 값이 split_page에 안 보일 가능성

### 🔴 발견 2 — Step 1 게이트 정책의 일관성 부족

- Q1만 lock 게이트 (Q2~Q10 lock by Q1)
- 그러나 Q1 외 다른 퀘스트끼리는 자유 선택
- Q11은 lock 자체 없음 (선택 과제)
- 게이트 디자인이 "Step" 명명과 의미 충돌

### 🟡 발견 3 — 가입 흐름 입력 vs 퀘스트 완료 조건 비동기

- profile_setup에서 사진·소개 입력 → 즉시 Q2/Q3 완료 처리되는지 코드 검증 필요
- 가입 직후 home 도착 시 사용자가 "또 입력?"이라는 의문 가능

### 🟡 발견 4 — 완료 임계값 비공개

- Q3 `≥20자` 같은 임계값이 사용자에게 보이지 않음
- "왜 안 끝나지?"라는 의문

### 🟡 발견 5 — 스킵 정책 미명시

- 퀘스트 보드의 11개 항목 중 1개만 "선택 과제" 표기
- 나머지는 필수/선택 불명 → 사용자 압박감

### 🟢 발견 6 — Q2~Q5/Q9 단축 진입점 패턴 (잘 작동)

- 퀘스트와 설정이 같은 화면을 가리킴
- 이 패턴을 모든 퀘스트에 일관 적용 권장

---

## 4. 권고 (Step 2 스펙에 반영할 방향)

### A. 퀘스트의 본질 재정의

**"퀘스트 = 학습 가이드 + 단축 진입점"** 으로 명확히 정의:
- 의무 X — 모든 퀘스트는 선택 (강제는 가입 흐름에서만)
- 진입점 = 설정의 같은 화면 (단축 wrapper 금지)
- "Step" 명명 폐기 → "할 일" 또는 무번호 카드로 변경

### B. SSOT 강제

- Q1 first_availability_setup 제거
- 온보딩에서 split_page 직접 진입 (또는 split_page 의 온보딩용 simplified mode)
- profile.TeacherSettings.availableSlots 필드 제거 → schedule.TeacherAvailability 일원화

### C. 가입 ↔ 퀘스트 자동 완료 연계

- profile_setup에서 사진·소개 입력 시 즉시 Q2/Q3 완료
- 가입에서 입력한 가용시간 → Q1 자동 완료
- 사용자가 home 도착 시 이미 완료된 퀘스트는 "완료" 표시 (또는 숨김)

### D. 완료 임계값 공개

- Q3 `최소 20자` 임계값 입력 화면에 표시
- 완료 기준은 모두 퀘스트 본문에 명시

### E. 스킵 정책 일관 표기

- 모든 퀘스트에 "선택" 또는 "필수" 라벨
- 선택 퀘스트는 "나중에" / "건너뛰기" 버튼 명시

### F. lock 정책 단순화

- 강한 의존성(Q6→Q7)만 유지 (학생이 있어야 수강권 발급 의미 있음)
- Q1 → 나머지 lock 제거 (가용시간 없어도 학생 초대/계좌 입력 가능)

---

## 5. Step 1 후속 (Step 2 스펙 초안 대상)

### Step 2에서 결정할 항목

1. 퀘스트 분류 체계 (Onboarding / Operations / Marketing 등)
2. 각 퀘스트의 ID/목적/완료 조건/관련 화면 SSOT 표
3. UX 흐름 다이어그램 (Mermaid)
4. 가입 흐름의 단순화 범위
5. lock/dependency 그래프

### Step 3 (데이터 모델)

1. profile vs schedule 도메인의 가용시간 SSOT 결정
2. TeacherSettings vs TeacherAvailability 통합 또는 위임 관계
3. 마이그레이션 영향도

### Step 4 (구현 PR)

스펙 기준 surgical PR 분할 — 데이터 마이그레이션 / UI 통합 / 퀘스트 자동 완료 wiring 등 단위로.

---

**평가 의견**: 현재 시스템은 11개 퀘스트가 모두 "구현"은 됐지만 시스템 차원에서 **정신 모델 충돌(목적 모호) + SSOT 위반(Q1) + 가입 흐름 비연계(자동 완료 미작동)** 3대 문제를 안고 있음. 코드 라인 단위 수정으로 해결 불가 — 기획 차원의 재정의가 선행되어야 함.

---

## 6. 졸업 메커니즘 (2026-06-12 — W5 구현 결과)

teacher-settings-redesign W5 머지로 Q1~Q10 100% 완료 시 자동 hide + 7일 grace + 재노출 메뉴 구현.

### 6.1 졸업 판정

`quest_celebrated_at` 컬럼의 의미를 재정의:
- **이전**: 축하 카드 dismiss 시각
- **현재 (W5)**: **Q1~Q10 전체 100% 완료 시각** (졸업 시각 SSOT)

판정 시 `QuestNotifier` 가 모든 퀘스트의 status==completed 를 확인하고 `quest_celebrated_at` 을 PATCH.
`questBonusShownProvider` (FE 영속) — 축하 카드 1회 노출 여부 별도 관리 (졸업과 분리).

### 6.2 7일 Grace + Hide

`kQuestGraduationGrace = Duration(days: 7)` (`frontend/lib/core/constants/durations.dart`).

```
quest_celebrated_at 기준:
  - 0 ~ 7일 → QuestBoardCard "졸업했어요 🎉" 모드 (graduated 라벨 + 게이지 100%)
  - 7일+ → 메인에서 완전 hide (QuestCelebrationState.graduated)
```

`QuestCelebrationState` enum 두 분기 (`visible` / `graduated`) — W5 Task 5.3.

### 6.3 재노출

"⚙️ 정책·알림·지원 → 가이드 다시 보기" 메뉴 (`GuideReshowScreen`, W5 Task 5.6) 로 졸업한 보드를 사용자 임의 재노출.

---

## 7. 게이지 1:1 정합성 (2026-06-12 — W5 Task 5.5)

프로필 완성도 게이지 (`profile_master.md §2.2`) 와 퀘스트 완료율을 **1:1 매핑**.

### 7.1 수식

```
computeProfileCompletionPercent = Σ(완료 퀘스트 가중치)
  Q1 가용시간:        15%
  Q2 수강권 템플릿:    10%
  Q3a 프로필 사진:    20%
  Q3b 자기소개:        6%  (W5 Task 5.5 신규 추가)
  Q4 악기:            15%
  Q5 입금 계좌:        10%
  Q6 경력·학력:        10%
  Q7~Q10 (탐색):      14%
  ───────────────────
  합계:              100%
```

가중치 합 100 보장 (`teacher_profile_completion_provider_test`).

### 7.2 1:1 정합성

```
퀘스트 10개 100% 완료 ⇔ 게이지 100% ⇔ quest_celebrated_at 기록 ⇔ 7일 grace 시작
```

회귀 테스트: `teacher_profile_completion_provider_test` + `quest_board_card_test`.
SC-6 검증 통과 (teacher-settings-redesign §2 SC-6).

---

## 8. 관련 구현 산출물

- `core/constants/durations.dart` — `kQuestGraduationGrace`
- `features/profile/presentation/providers/teacher_profile_completion_provider.dart` — Q3b 6% 추가
- `features/home/presentation/widgets/quest_board_card.dart` — graduated 모드
- `features/profile/presentation/screens/guide_reshow_screen.dart` — 재노출 진입점
- `features/profile/presentation/providers/quest_bonus_shown_provider.dart` — 축하 카드 1회 노출 영속

PR: [#686](https://github.com/chulgil/lesson-app/pull/686) (W5).
