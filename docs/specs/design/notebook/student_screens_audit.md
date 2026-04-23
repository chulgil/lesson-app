# Student Screens — Notebook × Score 감사 매트릭스

> 생성: 2026-04-23
> 근거 스펙: `docs/specs/design/notebook/README.md` (§1 4대 시그니처, §7.17/§7.27/§7.30/§7.50)
> 방법: Grep 기반 정적 분석 + 컨텍스트 스캐닝 (§7.84 10-패턴 자동 판정 프로토콜)
> 범위: 학생 role 진입 경로 11개 도메인

---

## 1. 도메인별 잔재 통계 (`AppTypography.heading*`)

| 도메인 | 잔재 | 판정 |
|--------|------|------|
| `student_home/` | 22 | 9 §7.17 BLOCK · 2 §7.27 · 11 §7.30 예외 |
| `invite/` | 13 | 2 §7.17 BLOCK · 3 §7.17 후보 · 8 §7.30 예외 |
| `onboarding/` | 7 | **4 §7.17 BLOCK** · 3 §7.17 후보 |
| `gamification/` | 6 | 0 §7.17 · 6 §7.30 예외 (후보 1 재확인) |
| `search/` | 2 | 0 §7.17 · 2 §7.30 예외 (§7.84 이미 90% 처리분) |
| `auth/` | 2 | 0 §7.17 · 2 §7.30 예외 (코드 입력 letterSpacing) |
| `notifications/` | 0 | ✅ 포화 |
| `follow/` | 0 | ✅ 포화 |
| `relationship/` | 0 | ✅ 포화 |
| `lessons/` (학생 진입분) | — | §7.17 거의 완료(§7.53·§7.71·§7.72), 재확인 대상 없음 |
| `practice/` (학생 진입분) | — | §7.84 에서 0/9 §7.30 포화 확인 |

**총 §7.17 BLOCK 확정**: **15건** (student_home 9 + invite 2 + onboarding 4) + **후보 6건** (invite 3 + onboarding 3 + gamification 0~1) = **최대 21건**

---

## 2. student_home/ — 22건 상세

### 2.1 §7.17 BLOCK (9건) — Playfair sectionTitle 승격 대상

| # | 파일 | 라인 | 문자열 | 근거 |
|---|------|------|--------|------|
| 1 | `widgets/weekly_practice_widget.dart` | 96 | `'이번 주 연습'` | 정적 섹션 타이틀 |
| 2 | `widgets/weekly_practice_widget.dart` | 195 | `'이번 주 연습'` | loading variant — 동일 문자열 |
| 3 | `widgets/trial_bookings_section.dart` | 44 | `'내 체험레슨'` | 정적 섹션 타이틀 |
| 4 | `widgets/dashboard/practice_summary_section.dart` | 86 | `'이번 주 연습'` | 대시보드 섹션 |
| 5 | `widgets/dashboard/teacher_feedback_section.dart` | 29 | `'최근 피드백'` | 대시보드 섹션 |
| 6 | `widgets/student_subscription_summary.dart` | 67 | `'내 수강권'` | 정적 섹션 타이틀 |
| 7 | `screens/student_lessons_tab.dart` | 190 | `'스케줄'` | 탭 내 섹션 헤더 |
| 8 | `screens/student_practice_tab.dart` | 61 | `'내 연습'` | 탭 타이틀 (§7.27 또는 §7.17) |
| 9 | `screens/app_info_screen.dart` | 44 | `'Lessonaza'` | 앱 브랜드 타이틀 — §7.17/§7.27 판정 필요 |

### 2.2 §7.27 바텀시트 헤더 (2건) — Playfair sectionTitle

| # | 파일 | 라인 | 문자열 |
|---|------|------|--------|
| 10 | `widgets/language_select_sheet.dart` | 43 | `'언어 설정'` |
| 11 | `widgets/practice_reminder_sheet.dart` | 49 | `'연습 리마인더'` |

### 2.3 §7.30 예외 (11건) — Gothic 유지

| # | 파일 | 라인 | 패턴 # | 근거 |
|---|------|------|--------|------|
| 12 | `widgets/dashboard/next_lesson_card.dart` | 147 | #4 | `dDayText` 동적 D-Day |
| 13 | `screens/student_profile_tab.dart` | 191 | #2 | `name` 학생 동적 이름 |
| 14 | `screens/student_profile_tab.dart` | 270 | #3 | `value` stat (숫자) |
| 15 | `screens/student_profile_tab.dart` | 607 | #10 | 초대코드 digit (동적 문자 분해) |
| 16 | `screens/student_lessons_tab.dart` | 231 | #4 | `formatDateMDWithDayLong()` 동적 날짜 |
| 17 | `screens/student_practice_tab.dart` | 132 | #4 | `_formatDate()` |
| 18 | `screens/student_practice_tab.dart` | 177 | #4 | loading variant 동일 |
| 19 | `screens/student_practice_tab.dart` | 190 | #4 | error variant 동일 |
| 20 | `screens/my_teachers_screen.dart` | 509 | #6 | `teacher.initial` 아바타 이니셜 |
| 21 | `widgets/student_subscription_summary.dart` | 268 | #3 | `'${usedLessons}/$_totalSessions'` stat 값 |
| 22 | `widgets/practice_reminder_sheet.dart` | 147 | #3 | `settings.formattedTime` 동적 시간 |

---

## 3. onboarding/ — 7건 상세

### 3.1 §7.17 BLOCK (4건 확정)

| # | 파일 | 라인 | 문자열 | 근거 |
|---|------|------|--------|------|
| 1 | `student_profile_setup_screen.dart` | 158 | `'프로필 설정'` | 정적 스텝 타이틀 |
| 2 | `student_profile_setup_screen.dart` | 438 | `'악기 선택'` | 정적 필드 섹션 |
| 3 | `profile_setup_screen.dart` | 206 | `'프로필 설정'` | (선생님/학생 공용) |
| 4 | `profile_setup_screen.dart` | 687 | `'악기 선택'` | 동일 |

### 3.2 §7.17 후보 (3건, 읽기 필요)

| # | 파일 | 라인 |
|---|------|------|
| 5 | `tutorial_screen.dart` | 255 |
| 6 | `student_tutorial_screen.dart` | 252 |
| 7 | `phone_verification_screen.dart` | 193 |

---

## 4. invite/ — 13건 상세

### 4.1 §7.17 BLOCK (2건 확정)

| # | 파일 | 라인 | 문자열 | 근거 |
|---|------|------|--------|------|
| 1 | `my_connections_screen.dart` | 309 | (읽기 필요 — 섹션 헤더 패턴 추정) | 후보 |
| 2 | `invite_confirm_screen.dart` | 132 | (읽기 필요 — 초대 확인 섹션) | 후보 |

### 4.2 §7.30 예외 (확정 8건)

| # | 파일 | 라인 | 패턴 # | 근거 |
|---|------|------|--------|------|
| 3 | `invite_screen.dart` | 239 | #10 | `invite.inviteCode` letterSpacing 8 |
| 4 | `my_connections_screen.dart` | 105 | #7 | `'아직 연결된 X가 없습니다'` 빈 상태 |
| 5 | `my_connections_screen.dart` | 315 | #2 | `otherName` 동적 이름 |
| 6 | `code_input_screen.dart` | 221 | #10 | TextField 입력 letterSpacing |
| 7-10 | `invite_confirm_screen.dart` | 84/393/468 | 혼합 | 읽기 후 재판정 |
| 11-13 | `invite_history_screen.dart` | 81/283 / `pending_requests_screen:237` / `my_connections:553` | 혼합 | 읽기 후 재판정 |

---

## 5. gamification/ — 6건 (§7.30 예외 수렴 예상)

| # | 파일 | 라인 | 추정 |
|---|------|------|------|
| 1 | `weekly_ranking_card.dart` | 87 | §7.30 #9 게임화 토큰 (이미 §7.39 에서 카드 제목 승격됨 — 중복?) |
| 2 | `badge_collection_screen.dart` | 94 | §7.30 #9 뱃지 이름 |
| 3 | `badge_collection_screen.dart` | 103 | §7.30 #9 뱃지 수 |
| 4 | `level_up_dialog.dart` | 72 | §7.30 #9 레벨 값 |
| 5 | `level_up_dialog.dart` | 84 | §7.30 #9 축하 메시지 |
| 6 | `badge_award_sheet.dart` | 126 | §7.30 #9 뱃지 이름 |

§7.79 에서 `settings/gamification` 0/6 포화 확정된 것과 동일 계보.

---

## 6. search/ · auth/ — 4건 (§7.30 예외 수렴)

| 파일 | 라인 | 판정 |
|------|------|------|
| `teacher_detail_screen.dart` | 158 | #2 `profile.name` 동적 이름 (Colors.white 전경 — §7.50도 재검토) |
| `academy_detail_screen.dart` | 145 | 동일 패턴 추정 |
| `student_invite_code_screen.dart` | 96 | #10 TextFormField 코드 입력 |
| `parent_invite_code_screen.dart` | 97 | 동일 |

---

## 7. 4대 시그니처 적용 현황 (렌더 기준)

| 화면 | Playfair | 로마숫자 | Vermillion | Gaegu | 판정 |
|------|:-:|:-:|:-:|:-:|------|
| `student_home_screen` 쉘 | ✓ (NotebookMasthead) | ✓ (로마숫자 네비) | ✓ (paperAccent active) | — | PASS (§7.63) |
| 대시보드 탭 | ✓ (Programme Title) | ✓ (로마숫자 섹션) | ✓ | ✓ (teacher_feedback) | PASS (§7.12) |
| 연습 탭 | 부분 (제목 §7.17 갭) | — | ✓ | ✓ | **FLAG** §7.17 갭 |
| 레슨 탭 | 부분 (스케줄 §7.17 갭) | — | ✓ | — | **FLAG** §7.17 갭 |
| 프로필 탭 | ✓ | — | ✓ | — | PASS (§7.74) |
| 연습 리마인더 시트 | 갭 (§7.27) | — | ✓ | — | **FLAG** |
| 언어 설정 시트 | 갭 (§7.27) | — | — | — | **FLAG** |
| onboarding 프로필 설정 | 갭 (§7.17) | — | ✓ | — | **FLAG** §7.17 갭 |

---

## 8. 레거시 팔레트 잔재 (참고)

| 도메인 | `Color(0x` / `Colors.white` / `primaryLight` 등 | 비고 |
|--------|:-:|------|
| `student_home/` | **0건** | ✅ §7.50 스윕 완료 |
| 교차 도메인 | 별도 감사 (§7.74/§7.86 에서 대부분 완결) | — |

---

## 9. 권장 배치 계획

| 배치 | 대상 | 파일 | 예상 수정 |
|------|------|------|----------|
| **3.A** (P0) | `student_home/` §7.17 BLOCK 9건 + §7.27 시트 2건 | 7 files | 11 지점 |
| **3.B** (P0) | `onboarding/` §7.17 BLOCK 4건 | 2 files | 4 지점 |
| **3.C** (P1) | `invite/` §7.17 후보 재확인 (invite_confirm / my_connections / invite_history / pending_requests) 5건 분석 | 4 files | ≤5 지점 |
| **3.D** (P2) | §7.30 예외 확정 재검증 (gamification 6 + search 2 + auth 2 + §7.30 예외 student_home 11) | — | 0 지점 (문서화만) |
| **3.E** (P2) | `onboarding/` §7.17 후보 3건 재확인 (tutorial/student_tutorial/phone_verification) | 3 files | ≤3 지점 |

**총 수정 예상**: **20~23 지점, ≤16 파일** (기존 Phase 계획의 ≤29 파일보다 감소).

---

## 10. 판정 규칙 재확인 (§7.84)

| 자동 §7.30 패턴 | 적용 |
|-----------------|------|
| #2 동적 이름 (`template.name`, `student.name`, `teacher.name`) | ✓ |
| #3 stat value (`value`, `price`, `count`) | ✓ |
| #4 월/일자/D-Day 레이블 | ✓ |
| #6 아바타 이니셜 (`initial`) | ✓ |
| #7 빈 상태 headline (icon + 메시지) | ✓ |
| #9 게임화 토큰 (뱃지/레벨/pts) | ✓ |
| #10 동적 인덱스 / 코드 문자열 | ✓ |

해당 패턴 매칭 시 **파일 읽기 생략 + §7.30 확정 판정**.
