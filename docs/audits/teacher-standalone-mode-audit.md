# 선생님 단독 모드 감사 (Teacher Standalone Mode Audit)

> 작성: 2026-06-13 | 이슈: #417 (Refs #318) | effort: S
> 방법: 23개 feature + tuner/metronome 를 4개 병렬 read-only 감사 → 핵심 충돌·PARTIAL 직접 재검증

## 결론 (먼저)

**P0/CRITICAL 블로커 없음.** 선생님은 학원 미소속 + 학부모 미연동 + 학생 앱 미설치 상태에서 핵심 레슨 운영(학생 로컬 관리 → 레슨 등록/기록 → 일정 → 수강권 제안/발급 → 분석)을 끝까지 수행할 수 있다.

| 판정 | 수 | 도메인 |
|------|----|--------|
| PASS | 18 | lessons, schedule, practice, students, subscription, billing, relationship, invite, share, notifications, auth, onboarding, profile, settings, home, search, analytics, tuner, metronome |
| PARTIAL | 4 | academy, inbox, follow, gamification |
| N/A (학생/학부모 전용) | 2 | student_home, parent_home |
| FAIL | 0 | — |

PARTIAL 4건은 모두 **academy/학생앱 연동을 전제한 기능이 단독 강사에게 "노출되지만 비어있는" UX 명확성** 문제로, 기능 차단이나 크래시가 아니다. 우선순위 low~medium.

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
| follow | PARTIAL | `follow_repository.dart:44-50` | 학생/학부모용 teacher-follow 기능. 선생님 앱 진입 경로 불명확 — 노출 시 빈 상태 (hands-on 확인 권장) |
| gamification | PARTIAL | `gamification_facade.dart:7-11` | 학생 연습 데이터 기반. 단독 모드(학생 데이터 없음)에서 선생님 화면 빈 위젯 노출 여부 (hands-on 확인 권장) |

### 계정 / 유틸 / 도구

| 도메인 | 판정 | 근거 (file:line) | 비고 |
|--------|------|------------------|------|
| auth | PASS | `role_select_screen.dart:78-89` | 역할 선택만 필수, 학원/학부모 연동 선택 |
| onboarding | PASS | `profile_setup_screen.dart:81-99` | 이름+악기만 필수, 학원 코드 미요구. 단독 강사 끝까지 완료 가능 |
| profile | PASS | `profile_tab.dart:38-51` | 선생님 기본정보만 렌더 |
| settings | PASS | `features/settings/` | 앱 설정/알림/계정, 학원 구조 무시 |
| home | PASS | `home_screen.dart:196-202` | 학생 빈 상태 우아한 처리 |
| search | PASS | `teacher_search_screen.dart` | 타 선생님 검색은 선택 |
| inbox | PARTIAL | `inbox/presentation/screens/academy_inquiry_*.dart` | inbox 전체가 academy 문의 전용. 비소속 선생님에게 빈 섹션 — 진입점 gating 확인 필요 |
| analytics | PASS | `analytics_dashboard_screen.dart:24-79` | 레슨/학생/수입 모두 선생님 단독 데이터, 빈 차트 우아 |
| tuner | PASS | `practice/.../tuner_screen.dart:16-44` | 순수 음향 도구, 미의존 |
| metronome | PASS | `practice/.../` (metronome widget) | 순수 박자 도구, 미의존 |

## PARTIAL 상세 + 후속 sub-issue 초안

아래는 보고서 단계의 **초안**이며, 실제 GitHub 이슈 생성은 사용자 승인 후 진행한다.

### A. academy 미소속 선생님 UX 명확성 (priority: low)

미소속 시 academy 데이터가 빈 배열로 graceful degrade 하나, academy 진입점/기능이 안내 없이 숨겨져 단독 강사가 "학원 연동" 기능의 존재 자체를 인지하지 못한다.
- 제안: 미소속 = 명시적 상태로 표기 (예: 설정에 "학원 미연동 — 학원 소속 시 단체 기능 사용 가능" 안내 1줄)
- 근거: `academy_visibility_provider.dart:22-28`

### B. inbox(academy 문의) 진입점 gating (priority: low~medium)

inbox feature 전체가 `academy_inquiry_*` 로만 구성. 비소속 선생님에게 빈 문의함이 노출되면 "기능이 비었다" 인상.
- 제안: academy 미소속 시 inbox 진입점 숨김 또는 빈 상태 안내 문구
- 확인 필요: notification_routes 경유 진입이 비소속 선생님에게 실제 노출되는지 (hands-on)
- 근거: `inbox/presentation/screens/academy_inquiry_screen.dart`, `notification_routes.dart:9-10`

### C. follow / gamification 단독 모드 빈 상태 (priority: low)

둘 다 학생 앱 연동/학생 수행 데이터를 전제. 선생님 단독 화면에 빈 위젯이 노출되는지 hands-on 확인 후, 노출된다면 빈 상태 안내로 정리.
- 근거: `follow_repository.dart:44-50`, `gamification_facade.dart:7-11`

## 검증 노트 (에이전트 교차검증)

코드를 작성/감사한 에이전트의 결론을 맹신하지 않고, 충돌·PARTIAL 주장을 직접 재검증함.

| 항목 | 에이전트 1차 | 직접 재검증 | 교정 |
|------|--------------|-------------|------|
| lessons | Agent A: PASS / Agent D: **FAIL(P0)** | `add_lesson_screen.dart:513` 학생 필수는 정상 규칙. 단독 모드=학생앱 미설치≠학생 0명 | **PASS** — Agent D 과대평가(학생앱 없음과 학생 레코드 없음 혼동). 맹신 시 허위 P0 sub-issue 발생 |
| students | Agent A: PARTIAL | 학부모 초대 opt-in + 후속 다이얼로그 명시(`:537`) | **PASS** |
| practice | Agent A: PARTIAL | `EmptyNoteAccessRepository` fallback(`:17`) graceful | **PASS** (note-access는 academy-mediated, 미소속 empty) |
| inbox | Agent D: PARTIAL | inbox 전체가 academy_inquiry 전용 확인 | **PARTIAL 확정** |

## 한계 (confidence)

- 직접 코드 재검증: lessons, students, practice(note-access), inbox, subscription(#693 연계)
- 단일 패스 에이전트 보고(중간 신뢰): 그 외 PASS 도메인
- hands-on(실기) 확인 권장: follow, gamification 빈 위젯 노출 여부, inbox 진입점 gating
- 본 감사는 코드 정적 분석 기준. 실기 시나리오(신규 가입 선생님이 학생 0명 → 첫 학생 추가 → 첫 레슨 기록) 순서 흐름은 별도 실기 검증 권장
