# Lessonaza 스펙 vs 코드 종합 분석 및 실행 계획

> 확정일: 2026-03-08

## 요약

핵심 기능(레슨 CRUD, 연습, 메트로놈/튜너, 수강권, 예약) 90%+ 완성.
차별화 기능(통계, 출석, 게이미피케이션) 미구현, 테스트 1%, 대형 파일 18개 기술 부채.

---

## Gap Analysis: 스펙 vs 코드

### 완전 미구현 (스펙만 존재)

| 스펙 | 영향도 |
|------|:------:|
| 통계/리포트 대시보드 (`analytics/`) | CRITICAL |
| 게이미피케이션 (포인트/레벨/뱃지) | HIGH |
| 빠른 레슨 등록 (자동완성) | MEDIUM |
| 레슨 요청 시스템 (재등록) | MEDIUM |

### 부분 구현

| 도메인 | 구현율 | 누락 |
|--------|:------:|------|
| 출석 관리 | 30% | Quick Action UI, 일괄 출석, 통계 |
| 노쇼/보강 추적 | 30-40% | UI/로직 |
| 그룹 레슨 | 30% | 정원/대기자/출석 체크 |
| 알림 시스템 | 40% | FCM 미연동 |
| 연습 노트/목표/공유/A-B비교 | 설계만 | 코드 미착수 |

### 누락된 문서 (코드 있으나 스펙 없음)

| 코드 모듈 | 비고 |
|-----------|------|
| `features/relationship/` (7파일) | 별도 스펙 없음 |
| `features/home/` (5파일) | 홈 위젯 구성 상세 스펙 없음 |
| `core/network/` (7파일) | 인증/인터셉터 스펙 없음 |
| 백엔드 Remote Repository 14개 | API 스펙 없음 |

---

## 리팩토링

### CRITICAL: 1,000줄+ 파일 4개 분할

| 파일 | 줄 수 | 분할 제안 |
|------|:-----:|----------|
| `issue_subscription_screen.dart` | 1,875 | 폼 섹션/프리뷰/확인 위젯 5분할 |
| `proposal_detail_screen.dart` | 1,285 | 제안/결제/액션 4분할 |
| ~~`weekly_schedule_screen.dart`~~ | ~~1,086~~ → 484 | **완료** (3분할) |
| ~~`lesson_requests_screen.dart`~~ | ~~1,041~~ → 407 | **완료** (3분할) |

### HIGH: 800~1,000줄 파일 14개

- `parent_profile_tab.dart` (968)
- `login_screen.dart` (962)
- `mock_subscription_repository.dart` (961)
- `lesson_booking.dart` (945)
- `teacher_search_screen.dart` (910)
- `section_detail_screen.dart` (905)
- `home_screen.dart` (900)
- `subscription_template_list_screen.dart` (898)
- `backup_widgets.dart` (860)
- `regular_lesson_widgets.dart` (855)
- `lesson_time_settings_widgets.dart` (841)
- `repertoire_management_widgets.dart` (825)
- `student_dashboard_tab.dart` (821)
- `practice_repertoire.dart` (810)

### 기타

- 테스트 커버리지 1% (677파일 대비 7개)
- Clean Architecture data/ 레이어 없음 7개 모듈
- 레거시 re-export 105개 파일
- AsyncValue 패턴 비일관
- 하드코딩 색상 (`Colors.white` 320건)

---

## 실행 Phases

### Phase 1: MVP 완성 + 긴급 부채 해소

| # | 작업 | 상태 |
|---|------|:----:|
| 1-1 | 학생 탭 클래스별 그룹화 | done |
| 1-2 | 프로필 탭 미수금 관리 | done |
| 1-3 | 기존 정기레슨 앱 전환 플로우 | done |
| 1-4 | 약관 동의 화면 | in-progress |
| 1-5 | Google SSO 연동 마무리 | in-progress |
| 1-6 | Mock -> Backend 전환 준비 | todo |
| 1-7 | **대형 파일 분할 (1,000줄+ 4개)** | todo |
| 1-8 | **백엔드 CRITICAL API Gap 3건** | todo |

### Phase 2: 핵심 차별화

| # | 작업 | 우선순위 |
|---|------|:--------:|
| 2-1 | 통계/리포트 대시보드 | CRITICAL |
| 2-2 | 출석 관리 Quick Action Phase 1 | CRITICAL |
| 2-3 | 게이미피케이션 Phase 1 | HIGH |
| 2-4 | 대시보드 정보 계층화 | HIGH |
| 2-5 | **테스트 인프라 + 핵심 로직 테스트** | HIGH |
| 2-6 | 수강권 카드 UI 개선 | MEDIUM |
| 2-7 | 예약 색상 체계 적용 | MEDIUM |

### Phase 3: 고급 기능

| # | 작업 | 우선순위 |
|---|------|:--------:|
| 3-1 | 출석 관리 Phase 2 (통계+그룹) | HIGH |
| 3-2 | 게이미피케이션 Phase 2 (뱃지+리더보드) | HIGH |
| 3-3 | 학생 연습 현황 상세 조회 | MEDIUM |
| 3-4 | 알림 시스템 FCM 고도화 | MEDIUM |
| 3-5 | **노쇼/보강 추적 UI 완성** | MEDIUM |
| 3-6 | **그룹 레슨 정원/대기자/출석 완성** | MEDIUM |
| 3-7 | 팔로우/소식 피드 | LOW |
| 3-8 | 인앱 메시징 | LOW |

### Phase 4: 확장 + 기술 부채

| # | 작업 | 우선순위 |
|---|------|:--------:|
| 4-1 | Clean Architecture data/ 레이어 완성 (7개) | MEDIUM |
| 4-2 | 레거시 re-export 점진적 제거 | LOW |
| 4-3 | AsyncValue 패턴 표준화 | MEDIUM |
| 4-4 | 학원 웹 대시보드 | MEDIUM |

---

## 즉시 행동 3가지

1. **1,000줄+ 대형 파일 4개 분할** — 유지보수 블로커
2. **백엔드 CRITICAL API Gap 해소** — 서버 전환 블로커
3. **테스트 인프라 구축** — 리팩토링/기능추가 안전망

---

## 이전 계획

### 학생 프로필 탭 누락 기능 (2026-03-08)

#### Phase A: 즉시 구현 가능 ✅ 완료

| # | 이슈 | 기능 | 상태 |
|---|------|------|:----:|
| 1 | #77 | 도움말 화면 | done |
| 2 | #78 | 앱 정보 화면 | done |
| 3 | #79 | 다크 모드 토글 | done |
| 4 | #80 | 언어 설정 | done |
| 5 | #81 | 알림 설정 화면 | done |

#### Phase B: 데이터 연동 필요

| # | 이슈 | 기능 | 복잡도 |
|---|------|------|:------:|
| 6 | #82 | 프로필 수정 화면 | M |
| 7 | #83 | 레퍼토리 조회 | S |
| 8 | #84 | 연습 리마인더 설정 | M |

#### Phase C: 새 화면 + Provider 필요

| # | 이슈 | 기능 | 복잡도 |
|---|------|------|:------:|
| 9 | #85 | 내 선생님 화면 | M |
| 10 | #86 | 연습 기록 내역 화면 | M |
