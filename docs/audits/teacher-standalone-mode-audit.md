# 선생님 단독 모드 감사 (Teacher Standalone Mode Audit)

> 작성: 2026-06-13 | 이슈: #417 (Refs #318) | effort: S
> 방법: 23개 feature + tuner/metronome 를 4개 병렬 read-only 감사 → 핵심 충돌·PARTIAL 직접 재검증

## 결론 (먼저)

**P0/CRITICAL 블로커 없음.** 선생님은 학원 미소속 + 학부모 미연동 + 학생 앱 미설치 상태에서 핵심 레슨 운영(학생 로컬 관리 → 레슨 등록/기록 → 일정 → 수강권 제안/발급 → 분석)을 끝까지 수행할 수 있다.

| 판정 | 수 | 도메인 |
|------|----|--------|
| PASS | 22 | lessons, schedule, practice, students, subscription, billing, relationship, invite, share, notifications, auth, onboarding, profile, settings, home, search, analytics, tuner, metronome, inbox, follow, gamification |
| PARTIAL | 1 | academy |
| N/A (학생/학부모 전용) | 2 | student_home, parent_home |
| FAIL | 0 | — |

> 정정 (2026-06-13, 후속 검증): 1차 PARTIAL 4건 중 inbox·follow·gamification 3건은 직접 검증으로 PASS 해소 (아래 "후속 검증" 절). 남은 PARTIAL 1건(academy)은 결함이 아니라 "미소속 선생님에게 academy 기능을 노출할지"라는 제품 결정 사안.

## 감사 정의

"선생님 단독 모드" = 선생님이 다음 3가지가 모두 없는 상태에서 운영하는 시나리오 (스펙 근거: `docs/specs/lesson/invite/student_install_web_landing_spec.md` §2 — "선생님은 학생 미설치 상태에서도 단독 모드로 레슨 운영을 계속할 수 있어야 한다.").

1. 학원 미소속 (academy 없음)
2. 학부모 계정 미연동 (parent 없음)
3. 학생 앱 미설치 (선생님이 학생을 로컬로만 관리, `isManuallyRegistered=true`)

판정 기준:
- **PASS** — 정상 동작 또는 우아한 degrade (빈 상태 안내 포함)
- **PARTIAL** — 동작은 하나 어색한 빈 상태/오해 소지 UX, 또는 진입 가드 확인 필요
- **FAIL** — 깨짐 / NO-OP 버튼 / 없는 당사자 가정으로 단독 강사 차단
- **N/A** — 학생/학부모 본인 전용 화면 (선생님 라우팅에서 격리)

## 도메인별 결과

### 레슨 운영 코어

| 도메인 | 판정 | 근거 (file:line) | 비고 |
|--------|------|------------------|------|
| lessons | PASS | `add_lesson_screen.dart:283-301`, `:513` | 학생 picker = 로컬 `studentsProvider`. 학생 필수는 정상 도메인 규칙(레슨은 학생 귀속), 학생 앱 설치와 무관 |
| schedule | PASS | `schedule_tab.dart:54-72` | 달력/일정은 로컬 lesson 데이터만 사용 |
| practice | PASS | `note_access_provider.dart:17` (`EmptyNoteAccessRepository` fallback) | repertoire/녹음 단독 동작. note-access(악보 열람 동의)는 academy-mediated이나 미소속 시 empty (graceful) |
| students | PASS | `student_detail_screen.dart:354-358`, `:537` | 로컬 학생 CRUD 완전 동작. 학부모 초대는 opt-in — 코드 생성 후 카톡/문자 공유, 후속(학부모 앱 코드 입력)을 다이얼로그가 명시 |

### 수익 / 관계

| 도메인 | 판정 | 근거 (file:line) | 비고 |
|--------|------|------------------|------|
| subscription | PASS | `issue_subscription_screen.dart:34-64` (#693 검증에서 재확인) | 단독 제안→입금→발급, batch 지원. 학생 앱 무관 |
| billing | PASS | `billing_guard.dart:67-102` | 선생님 IAP only, 학부모 무관. free plan 5명 제한만 적용 |
| relationship | PASS | `teacher_student_relation.dart:59-60,108-114` | `isManuallyRegistered=true` 로 학생앱 미연동 명시 지원 (effectiveStatus active) |
| academy | PARTIAL | `academy_visibility_provider.dart:22-28` | 미소속 시 `listTeacherAcademies()` 빈 배열 (graceful) — 단 academy 기능이 "없음" 안내 없이 조용히 숨겨져 존재 인지 불가 |

### 학생측 / 참여

| 도메인 | 판정 | 근거 (file:line) | 비고 |
|--------|------|------------------|------|
| student_home | N/A | `home_routes.dart:20-25` | 학생 전용, 선생님 라우팅 격리 |
| parent_home | N/A | `home_routes.dart:28-32` | 학부모 전용, 선생님 라우팅 격리 |
| invite | PASS | `invite_provider.dart:35-43` | 선생님 초대 코드/QR 생성, 학생 미설치 무관 |
| share | PASS | `student_summary_screen.dart:127-145` | 토큰 기반 공개 읽기 전용 공유 (#318 R2 핵심) |
| notifications | PASS | `notifications_facade.dart:4-13` | 선생님 관련 알림만 표시, 학부모/학생 연동 미전제 |
| follow | PASS | `follow_list_screen.dart:69-78`, `follow_feed_screen.dart:42-56` | 진입은 profile 설정 BottomSheet(`profile_category_sheets.dart:250,259`)에만 — follower stat은 이미 "입금대기"로 교체됨. 두 화면 모두 `EmptyStateWidget` 으로 빈 상태 우아 처리 |
| gamification | PASS | `teacher_profile_completion_provider.dart`, `practice/.../badge_point_bridge.dart` | 선생님측 게이미피케이션 = 프로필 완성 quest(학생 없이 단독 동작). 학생 연습 게이미는 `practice/` provider 내부에서만 소비 — 선생님 화면에 빈 위젯 없음 |

### 계정 / 유틸 / 도구

| 도메인 | 판정 | 근거 (file:line) | 비고 |
|--------|------|------------------|------|
| auth | PASS | `role_select_screen.dart:78-89` | 역할 선택만 필수, 학원/학부모 연동 선택 |
| onboarding | PASS | `profile_setup_screen.dart:81-99` | 이름+악기만 필수, 학원 코드 미요구. 단독 강사 끝까지 완료 가능 |
| profile | PASS | `profile_tab.dart:38-51` | 선생님 기본정보만 렌더 |
| settings | PASS | `features/settings/` | 앱 설정/알림/계정, 학원 구조 무시 |
| home | PASS | `home_screen.dart:196-202` | 학생 빈 상태 우아한 처리 |
| search | PASS | `teacher_search_screen.dart` | 타 선생님 검색은 선택 |
| inbox | PASS | `notification_routes.dart:50-56` (`academyId` 필수), `academy_inquiry_screen.dart:53` | inbox 전체가 academy 문의 전용이나 라우트가 `academyId` 필수 + settings/home/profile/notifications 어디에도 진입 메뉴 없음(grep 공집합) → 비소속 선생님 도달 불가 = 이미 gated |
| analytics | PASS | `analytics_dashboard_screen.dart:24-79` | 레슨/학생/수입 모두 선생님 단독 데이터, 빈 차트 우아 |
| tuner | PASS | `practice/.../tuner_screen.dart:16-44` | 순수 음향 도구, 미의존 |
| metronome | PASS | `practice/.../` (metronome widget) | 순수 박자 도구, 미의존 |

## PARTIAL 후속 — sub-issue 처리

1차 PARTIAL 4건에 대해 sub-issue #720·#721·#722 를 생성한 뒤, 보고서가 권고한 hands-on 검증을 수행하여 3건을 해소했다.

### A. academy 미소속 선생님 UX 명확성 — #720 (열림, priority: low)

미소속 시 academy 데이터가 빈 배열로 graceful degrade 하나, academy 진입점/기능이 안내 없이 숨겨져 단독 강사가 "학원 연동" 기능의 존재를 인지하지 못한다.
- 성격: 결함 아님 — "미소속 선생님에게 academy 기능을 advertise 할지"라는 **제품 결정 사안**. 대부분의 단독 강사에게 학원 기능 숨김은 정당.
- 제안(채택 시): 설정에 "학원 미연동 — 학원 소속 시 단체 기능 사용 가능" 안내 1줄.
- 근거: `academy_visibility_provider.dart:22-28`

### B. inbox(academy 문의) 진입점 — #721 (검증 후 close, 비결함)

inbox feature 전체가 `academy_inquiry_*` 이나, 라우트가 `academyId` 경로 파라미터 필수 + settings/home/profile/notifications 어디에도 진입 메뉴 없음(grep 공집합). 비소속 선생님은 academyId 도 진입 UI 도 없어 **도달 불가 = 이미 gated**. 결함 아님.
- 근거: `notification_routes.dart:50-56`, 진입점 grep 공집합

### C. follow / gamification 단독 모드 빈 상태 — #722 (검증 후 close, 비결함)

- follow: 진입은 profile 설정 BottomSheet 에만(`profile_category_sheets.dart:250,259`), 두 화면 모두 `EmptyStateWidget` 으로 빈 상태 처리(`follow_list_screen.dart:69`, `follow_feed_screen.dart:42`). follower stat 은 이미 "입금대기"로 교체. 무맥락 빈 위젯 없음.
- gamification: 선생님측은 프로필 완성 quest(학생 무관 단독 동작), 학생 연습 게이미는 `practice/` provider 내부 소비 — 선생님 화면 빈 위젯 없음.

## 검증 노트 (에이전트 교차검증)

코드를 작성/감사한 에이전트의 결론을 맹신하지 않고, 충돌·PARTIAL 주장을 직접 재검증함.

| 항목 | 에이전트 1차 | 직접 재검증 | 교정 |
|------|--------------|-------------|------|
| lessons | Agent A: PASS / Agent D: **FAIL(P0)** | `add_lesson_screen.dart:513` 학생 필수는 정상 규칙. 단독 모드=학생앱 미설치≠학생 0명 | **PASS** — Agent D 과대평가(학생앱 없음과 학생 레코드 없음 혼동). 맹신 시 허위 P0 sub-issue 발생 |
| students | Agent A: PARTIAL | 학부모 초대 opt-in + 후속 다이얼로그 명시(`:537`) | **PASS** |
| practice | Agent A: PARTIAL | `EmptyNoteAccessRepository` fallback(`:17`) graceful | **PASS** (note-access는 academy-mediated, 미소속 empty) |
| inbox | Agent D: PARTIAL | 라우트 `academyId` 필수 + 진입 메뉴 grep 공집합 → 도달 불가 | **PASS** — Agent D 과대 추정. 이미 gated |
| follow | Agent C: PARTIAL("확인 필요") | 진입 BottomSheet only + 두 화면 `EmptyStateWidget` 처리 | **PASS** |
| gamification | Agent C: PARTIAL("확인 필요") | 선생님 quest 단독 동작, 학생 게이미는 practice 내부 소비 | **PASS** |

교훈: 에이전트의 "확인 필요"/단정 PARTIAL 5건 중 4건이 직접 검증으로 PASS 해소. 에이전트 결론(과대·과소 양방향)을 수용 전 file:line 으로 재검증해야 허위 sub-issue 를 막는다.

## 한계 (confidence)

- 직접 코드 재검증: lessons, students, practice(note-access), inbox, follow, gamification, subscription(#693 연계)
- 단일 패스 에이전트 보고(중간 신뢰): 그 외 PASS 도메인 (auth/onboarding/profile/settings/home/search/analytics/invite/share/notifications/schedule/billing/relationship)
- 미해소 제품 결정: academy 미소속 가시성(#720)
- 본 감사는 코드 정적 분석 기준. 실기 시나리오(신규 가입 선생님이 학생 0명 → 첫 학생 추가 → 첫 레슨 기록) 순서 흐름은 별도 실기 검증 권장
