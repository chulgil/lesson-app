# 선생님 앱 UX 종합 검토 보고서

> 작성일: 2026-03-07
> 상태: 검토 완료, 개선 작업 필요
> 범위: 선생님 앱 전체 화면 (홈/스케줄/학생/프로필)

---

## 1. 검토 요약

### 1.1 검토 방법

| 항목 | 검토 대상 |
|------|----------|
| 스펙 문서 | teacher_app_screens.md, role_based_screens.md, ux_guidelines.md, design_master.md |
| 구현 코드 | home_screen.dart, calendar_tab.dart, students_tab.dart, profile_tab.dart |
| UX 원칙 | Don't Make Me Think, Hick's Law, Miller's Law, Fitts's Law |
| 비교 기준 | 경쟁사 분석 (My Music Staff, Tonara, 스튜디오메이트) |

### 1.2 발견된 이슈 요약

| 심각도 | 이슈 수 | 요약 |
|:------:|:------:|------|
| CRITICAL | 2 | 프로필 탭 과부하 (20개 메뉴), 핵심 기능 접근 경로 과다 |
| HIGH | 4 | 기능 중복 배치, 뎁스 초과, 누락 화면 |
| MEDIUM | 5 | 네이밍 불일치, UI 패턴 일관성, 문서 중복 |
| LOW | 3 | 마이너 UX 개선 |

---

## 2. CRITICAL 이슈

### 2.1 프로필 탭 기능 과부하 (Miller's Law 위반)

**현재 상태**: 프로필 탭에 4개 섹션, **20개 메뉴 아이템** 존재 (코드 실사 기준)

```
프로필 탭 (현재 구현 - profile_tab.dart)
├── 레슨 관리 (9개)
│   ├── 프로필 상세 수정
│   ├── 악기 관리
│   ├── 레퍼토리 관리
│   ├── 레슨 시간 설정
│   ├── 가용 시간 관리
│   ├── 승인 대기 목록      ← 스케줄 관련 기능
│   ├── 수강료 관리          ← 결제 관련 기능
│   ├── 레슨 정책 설정
│   └── 템플릿 관리
├── 설정 (5개)
│   ├── 알림 설정
│   ├── 다크 모드
│   ├── 언어
│   ├── 녹음 백업
│   └── 전체 녹음 관리
├── 지원 (3개)
│   ├── 도움말
│   ├── 피드백 보내기
│   └── 앱 정보
└── 계정 (3개)
    ├── 이용약관
    ├── 개인정보처리방침
    └── 로그아웃
```

**문제점**:
- Miller's Law: 한 화면에 정보 7+-2개 초과 (**20개** — 기준치의 2.5배)
- "프로필" 탭인데 레슨 관리 9개 항목이 지배적 → 사용자가 기능 위치를 예측할 수 없음
- "승인 대기 목록", "수강료 관리"는 스케줄/결제 영역인데 프로필에 배치

**개선안**: 20개 → 10개로 축소

```
프로필 탭 (개선안)
├── 내 프로필 (3개)
│   ├── 프로필 상세 수정     ← 악기/레퍼토리/경력 통합
│   ├── 가용 시간 관리
│   └── 레슨 정책 설정       ← 수강료 + 시간 + 취소 정책 통합
├── 설정 (2개)
│   ├── 알림 설정
│   └── 데이터 관리           ← 녹음 관리 + 백업 + 다크모드 + 언어 통합
├── 지원 (3개)
│   ├── 도움말
│   ├── 피드백 보내기
│   └── 앱 정보
└── 계정 (2개)
    ├── 약관/개인정보
    └── 로그아웃
```

**이동/통합 대상**:
| 기능 | 현재 위치 | 개선 | 이유 |
|------|----------|------|------|
| 악기 관리, 레퍼토리 관리 | 프로필 > 레슨 관리 (독립) | 프로필 상세 수정에 탭으로 통합 | 선생님 정보의 일부 |
| 레슨 시간 설정 | 프로필 > 레슨 관리 | 레슨 정책 설정에 통합 | 시간/수강료/정책은 한 화면 |
| 승인 대기 목록 | 프로필 > 레슨 관리 | 홈 > 즉시 확인 섹션 (이미 존재) | 긴급 기능은 홈에서 접근 |
| 수강료 관리 | 프로필 > 레슨 관리 | 레슨 정책 설정에 통합 | 수강료 템플릿은 정책 |
| 템플릿 관리 | 프로필 > 레슨 관리 | 레슨 노트 작성 화면에서 접근 | 사용 맥락에 배치 |
| 다크모드, 언어 | 설정 (독립) | 데이터 관리 > 일반 설정 | 설정 통합 |

### 2.2 동일 기능의 접근 경로 과다 (혼란 유발)

**예약 관리 접근 경로 (3곳)**:
1. 홈 > AppBar 예약 아이콘
2. 홈 > "즉시 확인 필요" > "레슨 요청 N건 대기"
3. 프로필 > 예약 관리

**미수금 접근 경로 (3곳)**:
1. 홈 > 미수금 StatCard
2. 학생 상세 > 수강권 섹션
3. 프로필 > 미수금 관리

**문제점**: 같은 기능이 3곳에서 접근 가능하면, 사용자가 "어디서 관리하는 게 맞지?" 혼란. 특히 프로필 탭에 있는 것은 발견하기 어려움.

**개선안**:
- 주 진입점을 1곳으로 확정 (홈 대시보드)
- 나머지는 바로가기(shortcut) 성격으로 유지
- 프로필 탭에서 레슨 관리 기능 제거

---

## 3. HIGH 이슈

### 3.1 홈 탭과 스케줄 탭 레슨 목록 중복

**현재**: 홈 탭에 "오늘의 레슨" 목록, 스케줄 탭에도 오늘 선택 시 동일한 레슨 목록 표시.

**문제점**: 동일한 LessonCard가 두 곳에 표시. 사용자가 어디서 레슨을 관리해야 하는지 모호.

**개선안**:
- 홈 탭: 오늘의 레슨은 **요약 카드** (최대 3개, "더보기" 링크)
- 스케줄 탭: **전체 레슨 관리** (CRUD, 상세 필터)
- 역할 명확화: 홈 = 대시보드(조회), 스케줄 = 관리(CRUD)

### 3.2 수강권 발급까지 4단계 (뎁스 초과)

**현재 경로**: 학생 탭 > 학생 카드 > 학생 상세 > 수강권 섹션 > [발급] 버튼

**문제점**: "2탭 이내 도달" 원칙 위반 (4단계)

**개선안**:
- 학생 카드에서 수강권 임박(2회 이하) 시 바로 [수강권 갱신] 버튼 표시
- 홈 > "즉시 확인 필요"에 "수강권 임박 N명" 항목 추가
- 학생 상세에서 수강권 발급은 유지 (정상 경로)

### 3.3 과제 관리 전용 화면 부재

**현재**: 과제 생성/관리는 레슨 상세 > 과제 탭에서만 가능.

**문제점**:
- 선생님이 "이번 주 학생들 과제 현황"을 한눈에 볼 수 없음
- 경쟁사(Tonara, My Music Staff)는 과제 대시보드 제공

**개선안**:
- 홈 탭에 "이번 주 과제 현황" 섹션 추가 (과제 미완료 학생 목록)
- 또는 학생 탭에 "과제" 필터 칩 추가

### 3.4 레슨 노트 검색/일괄 조회 화면 부재

**현재**: 레슨 노트는 레슨 상세 > 노트 탭에서만 조회 가능.

**문제점**:
- "김민수 학생의 지난 3개월 노트를 보고 싶다" → 레슨 하나하나 열어봐야 함
- 학부모 상담 시 과거 노트 검색 불가

**개선안**: 학생 상세에 "레슨 노트 히스토리" 섹션 추가 (날짜별 노트 목록 + 검색)

---

## 4. MEDIUM 이슈

### 4.1 스케줄 탭 네이밍/코드 불일치

| 항목 | 스펙 | 코드 |
|------|------|------|
| 탭 이름 | "스케줄" | CalendarTab (calendar_tab.dart) |
| 파일 위치 | features/schedule/ | features/calendar/ |

**개선안**: 코드를 스펙에 맞게 리팩토링 (calendar → schedule)

### 4.2 학생 카드의 정보 밀도 불균형

**스펙의 StudentCard**:
```
[아바타] 김민수  바이올린 중급   [5/8]
         화 15:00  연습 6/7일
```

**현재 구현**: 기본적으로 동일하나, 연습률 표시(점 패턴)가 미구현.

**개선안**: 스펙대로 연습률 점(●●●●●○○) 표시 구현

### 4.3 빈 상태(Empty State) 불일치

**현재**: 학생 탭, 레슨 목록 등에서 빈 상태 UI가 각각 다른 패턴 사용.

**UX 가이드라인**: "일러스트 + 안내 문구 + CTA" 통일 패턴

**개선안**: `core/widgets/empty_state.dart` 공통 컴포넌트를 모든 빈 상태에 적용

### 4.4 레슨 추가(+) 버튼 위치 불일치

| 화면 | 현재 위치 | 스펙 위치 |
|------|----------|----------|
| 홈 > 오늘의 레슨 | 섹션 헤더 우측 | 섹션 헤더 우측 (일치) |
| 스케줄 탭 | AppBar 우측 | AppBar 우측 (일치) |
| 학생 탭 | FAB | FAB (일치) |

현재는 대체로 일치하나, 레슨 추가와 학생 추가의 + 버튼 스타일이 다름 (하나는 헤더 버튼, 하나는 FAB).

**개선안**: + 버튼 패턴 통일 - 리스트 화면은 FAB, 섹션 내 추가는 헤더 버튼

### 4.5 문서 중복: session/ vs proposal/ (해결 완료)

~~`docs/session/` 폴더에 3개 파일이 `docs/proposal/`과 중복 존재.~~

**해결 (2026-03-07)**:
- `2026-01-26_teacher_feedback.md` → 삭제 (proposal/teacher_feedback_session.md와 중복)
- `2026-02-06_payment_redesign.md` → `proposal/payment_subscription_integration.md`로 이동
- `session_2025-12-30_recording.md` → `proposal/recording_session_2025-12-30.md`로 이동
- `docs/session/` 폴더 제거 완료

---

## 5. LOW 이슈

### 5.1 AppBar 아이콘 접근성

홈 탭 AppBar에 알림(벨), 예약(메일) 아이콘이 있으나, 아이콘만으로 기능을 구분하기 어려움.

**개선안**: 알림 아이콘에 미읽은 수 뱃지, 예약 아이콘에 대기 수 뱃지 표시 (스펙에는 있으나 구현 확인 필요)

### 5.2 다크모드 일관성

스펙에 다크모드 색상 정의가 있으나, 구현 여부 미확인.

### 5.3 학생 상세 > 학부모 정보 접근

학부모 정보가 학생 상세 하단에 있어 스크롤 필요. 자주 사용하는 연락처 정보는 더 쉽게 접근 가능해야 함.

---

## 6. 스펙에서 누락된 선생님 화면/기능

### 6.1 누락 확인된 항목

| 기능 | 상태 | 필요 문서 |
|------|------|----------|
| 통계/리포트 화면 | 스펙 없음 (roadmap에 "예정" 표시) | specs/analytics/ |
| 출석 관리 화면 | 스펙 없음 (경쟁사 분석에서 언급) | specs/lesson/attendance_spec.md |
| 레슨 노트 히스토리/검색 | 스펙 없음 | specs/lesson/lesson_note_spec.md 확장 |
| 학생 연습 현황 상세 조회 | 스펙 없음 | specs/practice/ 확장 |
| 레슨 일괄 등록 (정기 레슨) | 부분적 | specs/lesson/ 확장 |
| 인앱 메시징 | 스펙 없음 (경쟁사 분석에서 "개선 기회") | specs/communication/ |
| 레슨 기록 내보내기 | 스펙 없음 | specs/lesson/ 확장 |

### 6.2 우선순위 제안

| 순위 | 기능 | 이유 |
|:----:|------|------|
| 1 | 통계/리포트 | 선생님 가치 제안의 핵심 (학부모에게 근거 제시) |
| 2 | 출석 관리 | 수강권 차감과 직결, 경쟁사 기본 기능 |
| 3 | 레슨 노트 히스토리 | 레슨 연속성, 학부모 상담 시 필수 |
| 4 | 학생 연습 현황 상세 | 선생님이 레슨 전 학생 연습 확인 |
| 5 | 인앱 메시징 | 카톡 대체, 장기 로드맵 |

---

## 7. 문서 재구성 제안

### 7.1 현재 문서 구조 문제점

1. **레지스트리(registry.md) 미갱신**: practice 도메인만 등록, 나머지 미등록
2. **requirement.md 링크 깨짐**: `specs/payment_system.md` 등 old 경로 참조
3. **session/ 폴더 존재 이유 불명**: proposal/에 통합 가능
4. **마스터 문서 vs 개별 문서 중복**: design_master.md가 개별 문서 내용을 복사

### 7.2 Claude 작업 효율화를 위한 문서 인덱스

```
docs/
├── DOCUMENT_INDEX.md          ← NEW: Claude가 작업 시작 시 읽는 인덱스
├── architecture.md            ← 기존 유지
├── requirement/
│   ├── requirement.md         ← 링크 수정 필요
│   ├── requirement2.md
│   └── implementation_status.md ← 날짜 갱신 필요
├── proposal/                  ← session/ 내용 통합
│   ├── teacher_feedback_session.md  ← 2026-01-26 세션 내용 통합
│   └── ... (기존 유지)
├── specs/
│   ├── design/
│   │   ├── design_master.md       ← SSOT: 디자인 시스템 전체
│   │   ├── teacher_app_screens.md ← SSOT: 선생님 화면 설계
│   │   ├── ux_guidelines.md       ← SSOT: UX 원칙
│   │   ├── teacher_ux_review.md   ← NEW: 이 문서
│   │   └── ... (기존 유지)
│   ├── lesson/
│   │   ├── lesson_master.md       ← SSOT: 레슨 시스템 전체
│   │   └── ...
│   ├── subscription/
│   │   ├── subscription_master.md ← SSOT: 수강권 시스템 전체
│   │   └── ...
│   ├── schedule/
│   │   ├── schedule_master.md     ← SSOT: 스케줄 시스템 전체
│   │   └── ...
│   ├── user/
│   │   ├── user_master.md         ← SSOT: 사용자 시스템 전체
│   │   └── ...
│   ├── analytics/                 ← NEW: 통계/리포트 스펙
│   │   └── (예정)
│   └── dev/
│       ├── implementation_roadmap.md
│       └── ...
├── schema/entities/               ← 기존 유지
├── _components/                   ← 기존 유지
├── _patterns/                     ← 기존 유지
└── _tokens/                       ← 기존 유지
```

### 7.3 DOCUMENT_INDEX.md 역할

Claude가 작업 시작 시 이 파일 하나만 읽으면:
- 어떤 도메인에 어떤 마스터 문서가 있는지 파악
- 각 마스터 문서가 어떤 하위 스펙을 포함하는지 파악
- 구현 상태와 우선순위 파악
- 중복 없이 필요한 문서만 참조 가능

---

## 8. 실행 계획

### Phase 1: 문서 정리 (완료)

| 작업 | 상태 |
|------|:----:|
| DOCUMENT_INDEX.md 생성 | 완료 |
| session/ 폴더 → proposal/ 통합 | 완료 |
| registry.md 갱신 | 완료 |
| UX 검토 이슈 등록 (#63~#73) | 완료 |

### Phase 2: UX 개선 (이슈 등록)

| 작업 | 이슈 | 우선순위 | 상태 |
|------|------|:--------:|:----:|
| 프로필 탭 메뉴 재구성 | [#63](https://github.com/chulgil/lesson-app/issues/63) | CRITICAL | 구현 완료 |
| 홈 대시보드 접근 경로 정리 | [#64](https://github.com/chulgil/lesson-app/issues/64) | CRITICAL | 구현 완료 |
| 홈/스케줄 역할 명확화 | [#65](https://github.com/chulgil/lesson-app/issues/65) | HIGH | 구현 완료 |
| 수강권 발급 뎁스 축소 | [#66](https://github.com/chulgil/lesson-app/issues/66) | HIGH | 구현 완료 |
| 과제 현황 대시보드 | [#67](https://github.com/chulgil/lesson-app/issues/67) | HIGH | 구현 완료 |
| 레슨 노트 히스토리 | [#68](https://github.com/chulgil/lesson-app/issues/68) | HIGH | 구현 완료 |
| CalendarTab 리네이밍 | [#69](https://github.com/chulgil/lesson-app/issues/69) | MEDIUM | 구현 완료 |
| 빈 상태 UI 통일 | [#70](https://github.com/chulgil/lesson-app/issues/70) | MEDIUM | 구현 완료 |
| 학생 카드 연습률 표시 | [#71](https://github.com/chulgil/lesson-app/issues/71) | MEDIUM | 구현 완료 |
| 통계/리포트 스펙 작성 | [#72](https://github.com/chulgil/lesson-app/issues/72) | MEDIUM | 스펙 완료 |
| 출석 관리 스펙 작성 | [#73](https://github.com/chulgil/lesson-app/issues/73) | MEDIUM | 스펙 완료 |

### Phase 3: 선생님 UX 종합 점검 (2026-03-11)

Phase 1~2 핵심 UX 개선 + 편의성 개선

| 작업 | 이슈 | 우선순위 | 상태 |
|------|------|:--------:|:----:|
| 빈 상태 CTA 버튼 추가 (학생탭 + 홈) | [#104](https://github.com/chulgil/lesson-app/issues/104) | HIGH | 구현 완료 |
| 레슨 카드 스와이프 Quick Action (완료/취소) | [#105](https://github.com/chulgil/lesson-app/issues/105) | HIGH | 구현 완료 |
| QuickFeedback 확장 (포인트+팁) | [#106](https://github.com/chulgil/lesson-app/issues/106) | HIGH | 구현 완료 |
| 학생 등록 후 수강권 발급 안내 | [#107](https://github.com/chulgil/lesson-app/issues/107) | HIGH | 구현 완료 |
| 피드백 저장 확인 인디케이터 | [#108](https://github.com/chulgil/lesson-app/issues/108) | MEDIUM | 구현 완료 |
| 학생 추가 폼 필수 필드 시각 구분 | [#109](https://github.com/chulgil/lesson-app/issues/109) | MEDIUM | 구현 완료 |
| 학생 목록 정렬 기능 구현 | [#110](https://github.com/chulgil/lesson-app/issues/110) | MEDIUM | 구현 완료 |
| 가용시간 블록 past/cancelled 시각 구분 | [#111](https://github.com/chulgil/lesson-app/issues/111) | MEDIUM | 구현 완료 |
| 레슨 완료 시 피드백 작성 유도 배너 | [#112](https://github.com/chulgil/lesson-app/issues/112) | MEDIUM | 구현 완료 |

### Phase 4: 선생님 UX 종합 점검 2차 (2026-03-11)

선생님 입장 전체 플로우 점검: 로그인 → 학생 초대 → 스케줄 관리 → 학생 관리 → 레슨노트 작성

| 작업 | 이슈 | 우선순위 | 상태 |
|------|------|:--------:|:----:|
| EditStudentScreen Provider 연동 (DB 저장/삭제) | [#118](https://github.com/chulgil/lesson-app/issues/118) | CRITICAL | 구현 완료 |
| 신규 선생님 시작 가이드 카드 (0명 학생 시) | [#119](https://github.com/chulgil/lesson-app/issues/119) | HIGH | 구현 완료 |
| 요일별 레슨 시간 개별 설정 | [#120](https://github.com/chulgil/lesson-app/issues/120) | MEDIUM | 구현 완료 |
| 초대 상태 추적 (최근 초대 목록) | [#121](https://github.com/chulgil/lesson-app/issues/121) | MEDIUM | 이미 구현됨 |
| 레슨노트 피드백 프리셋/음성 버튼 | [#122](https://github.com/chulgil/lesson-app/issues/122) | MEDIUM | 구현 완료 (프리셋만) |
| 스케줄 레슨추가 학생 퀵셀렉트 | [#123](https://github.com/chulgil/lesson-app/issues/123) | LOW | 구현 완료 |

### Phase 5: 선생님 UX 종합 점검 4차 (2026-03-11)

선생님 입장 전체 플로우 재점검: 로그인 → 학생 초대 → 스케줄 관리 → 학생 관리 → 레슨노트 작성

| 작업 | 이슈 | 우선순위 | 상태 |
|------|------|:--------:|:----:|
| 레슨 스케줄 충돌 검증 (추가/수정 시) | [#128](https://github.com/chulgil/lesson-app/issues/128) | CRITICAL | 구현 완료 |
| 학생 편집 삭제 버튼 중복 제거 | [#129](https://github.com/chulgil/lesson-app/issues/129) | MEDIUM | 구현 완료 |
| 대시보드 레이아웃 개선 + 시작 가이드 수정 | [#130](https://github.com/chulgil/lesson-app/issues/130) | MEDIUM | 구현 완료 |
| 퀵피드백 프리셋 칩 + 저장 피드백 | [#131](https://github.com/chulgil/lesson-app/issues/131) | HIGH | 구현 완료 |

### Phase 6: 선생님 UX 종합 점검 5차 (2026-03-11)

선생님 앱 전체 플로우 5차 점검: 시작 가이드 경로, 하드코딩, 코드 품질

| 작업 | 이슈 | 우선순위 | 상태 |
|------|------|:--------:|:----:|
| GettingStartedCard Step 2-3 경로 수정 | [#133](https://github.com/chulgil/lesson-app/issues/133) | CRITICAL | 구현 완료 |
| teacherName 하드코딩 제거 | [#133](https://github.com/chulgil/lesson-app/issues/133) | HIGH | 구현 완료 |
| 피드백 프리셋 중복 제거 + 날짜 포맷 통일 | [#133](https://github.com/chulgil/lesson-app/issues/133) | HIGH | 구현 완료 |
| 정기 레슨 저장 로직 미구현 | [#134](https://github.com/chulgil/lesson-app/issues/134) | HIGH | 설계 검토 필요 |

### Phase 7: 선생님 UX 종합 점검 6차 (2026-03-11)

선생님 앱 전체 플로우 6차 점검: 레슨 완료 UI, 날짜 포맷, 에러 처리, 경로 정리

| 작업 | 이슈 | 우선순위 | 상태 |
|------|------|:--------:|:----:|
| 레슨 완료 처리 메뉴 추가 (scheduled→completed) | [#136](https://github.com/chulgil/lesson-app/issues/136) | MEDIUM | 구현 완료 |
| quick_feedback 날짜 포맷 YYYY.MM.DD 통일 | [#136](https://github.com/chulgil/lesson-app/issues/136) | HIGH | 구현 완료 |
| feedback/memo 저장 trim() + 에러 처리 | [#136](https://github.com/chulgil/lesson-app/issues/136) | HIGH | 구현 완료 |
| 과제 설명 입력 maxLines 2→5 | [#136](https://github.com/chulgil/lesson-app/issues/136) | MEDIUM | 구현 완료 |
| 하드코딩 경로 → AppRoutes 상수 통일 | [#136](https://github.com/chulgil/lesson-app/issues/136) | MEDIUM | 구현 완료 |
| parentName 엔티티 추가 | — | CRITICAL | 설계 검토 필요 |

---

## 관련 문서

| 문서 | 역할 |
|------|------|
| [teacher_app_screens.md](teacher_app_screens.md) | 선생님 화면 설계 SSOT |
| [ux_guidelines.md](ux_guidelines.md) | UX 원칙 SSOT |
| [design_master.md](design_master.md) | 디자인 시스템 통합 문서 |
| [role_based_screens.md](role_based_screens.md) | 역할별 화면 개요 |
| [DOCUMENT_INDEX.md](../../DOCUMENT_INDEX.md) | 문서 인덱스 (신규) |
