# Lessonaza 스펙-코드-UX 종합 리뷰 (Top-Down Overview)

> 작성일: 2026-04-17
> 모드: A (13개 마스터 스펙 × 21개 feature 빠른 매핑 + Top 10 이슈)
> 데이터 소스: 4개 Explore 에이전트 병렬 조사 결과
> 신뢰도: MEDIUM-HIGH (설계 문서 기준. 런타임 UX는 별도 검증 필요)

---

## 0. 한 줄 결론

**Lessonaza는 연습·구독·스케줄 영역의 구현 완성도는 높으나, UX 디자인 시스템 준수율이 낮고(1,103건 한글 하드코딩, 755건 EdgeInsets 직코딩), 레슨·알림·설정·팔로우 6개 도메인이 "설계 완료, 구현 부분"으로 블로킹 상태다.**

---

## 1. 도메인 × 구현 매트릭스 (한눈에 보기)

| # | 도메인 | 스펙 상태 | 코드 볼륨 | 구현 | 핵심 Gap |
|---|--------|----------|:--------:|:----:|----------|
| 1 | lessons | 통합 완료 | 8p/20P/13E | 부분 | 라우트 14개 중 6개 미매핑 |
| 2 | practice | 완료 | 17p/37P/28E | 완료 | 실시간 타이머 부재 |
| 3 | subscription | 완료 | 15p/10P/14E | 완료 | — |
| 4 | user | 통합 완료 | — | 부분 | 멀티소속 전환, 학부모 서브롤 미구현 |
| 5 | schedule | 완료 | 19p/10P/23E | 완료 | 라우트 1개 미매핑 |
| 6 | metronome | 완료 | — | 완료 | — |
| 7 | notification | 통합 완료 | 4p | **부분** | **FCM 미연동 (11개 카테고리 설계만)** |
| 8 | design | 부분 | — | 부분 | UX 법칙 전 화면 검증 미완 |
| 9 | calendar | 역공학 | 0~1p | **껍데기** | 도메인만 존재, UI 미구현 |
| 10 | onboarding | 역공학 | 6p | 완료 | — |
| 11 | student_home | 역공학 | 12p/6P/4E | 완료 | — |
| 12 | follow | 역공학 | 0~2p | **데이터만** | **FollowListScreen/FeedScreen 미구현** |
| 13 | settings | 역공학 | — | 부분 | 선생님 설정 UI 없음 (악기/타임슬롯/휴식) |

**Legend**: p=페이지, P=Provider, E=Entity

### 비핵심 도메인 요약 (feature 기준)

- **활성 (완성형)**: analytics, auth, gamification, invite, search, students (4-7 페이지)
- **중간**: relationship
- **껍데기**: booking (스키마만)

---

## 2. Top 10 이슈 (우선순위 순)

### 🔴 CRITICAL (즉시 조치)

#### #1 — 한글 UI 텍스트 하드코딩 대량 (1,103건 / 207파일)
- **현황**: `Text('한글')` 직접 사용, `AppStrings` 미경유
- **영향**: i18n 불가능. 국제화 로드맵 사실상 블로킹
- **핫스팟**: schedule(115건), student_home(71건), settings(47건)
- **조치**: `AppStrings` 마이그레이션 스프린트 1주 — 도메인별 순차 추출 (스크립트화 가능)
- **관련 규칙**: `.claude/rules/ux-rules.md` "AppStrings 상수 사용" 위반

#### #2 — FCM 푸시 알림 미연동
- **현황**: 알림 11개 카테고리 설계 완료 + Provider 있음, 그러나 Firebase 실장 0%
- **영향**: 레슨 리마인더·입금 알림·팔로우 소식 — 핵심 retention 기능 부재
- **조치**: Firebase 프로젝트 생성 → FCM 토큰 저장 → 백엔드 송출 파이프라인 (별도 이슈)
- **관련**: `docs/specs/notification/notification_master.md`

#### #3 — EdgeInsets 하드코딩 755건 (262파일)
- **현황**: `EdgeInsets.all(16)` 식 직코딩. `AppSpacing.space4` 미사용
- **영향**: 간격 일관성 무너짐. 반응형 스크린 크기 대응 어려움
- **핫스팟**: schedule 도메인이 과반. backup_widgets.dart 26회
- **조치**: 자동 변환 스크립트 + manual review. 도메인별 배치 PR

### 🟠 HIGH (2주 내 조치)

#### #4 — 공통 위젯 활용도 극히 낮음 (15개 중 1개만 활용)
- **현황**: `core/widgets/` 15개 중 `LessonProgressBar`만 15회 사용. 나머지 14개 미활용
- **영향**: 동일 카드/배너/리스트 패턴이 각 화면마다 재구현됨. 유지보수 비용 ↑
- **핫스팟**: 상세 화면 3곳(student/request/lesson_detail) 하단 액션바 스타일 불일치
- **조치**: 공통 위젯 카탈로그 작성 → 미사용 위젯 쓸 자리 grep → 중복 구현 교체
- **관련 규칙**: `.claude/rules/ux-rules.md` "공통 위젯 우선"

#### #5 — 레슨 도메인 라우트 6개 미매핑
- **현황**: `/lessons/quick-feedback`, `/lessons/bulk-feedback`, `/lessons/lesson-request` 등 라우트 정의만 있고 페이지 없음
- **영향**: 딥링크 클릭 시 크래시 가능. 메뉴 숨김 처리 미흡
- **조치**: 라우트 제거 or 실제 페이지 구현 여부 결정 (제품 결정 필요)
- **관련 원칙**: `.claude/rules/design-principles.md` "설정 필드 = 로직 사용"

#### #6 — 학부모 서브롤 / 멀티소속 전환 미구현
- **현황**: `user_master.md`에 3자 관계(T/S/P) 설계 완료, 코드 없음
- **영향**: 학부모가 자녀 연습 열람만 가능. 경쟁사(Tonara) 대비 Gap
- **조치**: 역할 전환 UI + 소속 선택 Drawer. 최소 학부모 읽기 기능 우선

### 🟡 MEDIUM (백로그)

#### #7 — 실시간 연습 타이머 + 백그라운드 알림바 (경쟁사 Gap)
- **현황**: 연습 완료 후 수동 입력만 가능
- **경쟁사**: Practice Space — 타이머 + 알림바 지속 표시 + 자동 기록
- **사용자 임팩트**: HIGH (연습 시간 신뢰성 ↑)
- **연계**: Tonara 사례 — 게이미피케이션 결합 시 연습 시간 68% 증가
- **조치**: `practice_master.md` Phase 2 우선 순위 조정

#### #8 — 게이미피케이션 축소 (스트릭만 구현, 포인트/배지/리더보드 없음)
- **현황**: 스트릭은 구현. 포인트/주간 목표/리더보드 미구현
- **경쟁사**: Tonara (서비스 종료했지만 패턴은 유효), Yousician, Simply Piano
- **사용자 임팩트**: HIGH (동기부여)
- **조치**: 포인트 지급 규칙 설계 → 주간 배지 → 선택적 리더보드
- **관련**: `features/gamification/` 이미 10 Provider 존재

#### #9 — fontSize 하드코딩 168건 (87파일)
- **현황**: `AppTypography` 미사용, `fontSize: 14` 식 직접 지정
- **영향**: 타이포 스케일 붕괴, 접근성(글자 크기 조절) 대응 어려움
- **핫스팟**: backup_widgets.dart(15회), teacher_availability_screen
- **조치**: #3과 함께 일괄 마이그레이션

#### #10 — flutter_analyze 300개 이슈 (0 error, 3 warning, 297 info)
- **현황**: Riverpod 3.0 마이그레이션 필요. `AutoDisposeFutureProviderRef` deprecated
- **영향**: 당장은 작동하나 기술부채. Flutter 업그레이드 시 블로킹 위험
- **조치**: `activeColor` → `activeThumbColor` 등 단계적 대응. 스크립트 지원 가능
- **관련 규칙**: `.claude/rules/tech-patterns.md` "Flutter 3.29.0 breaking changes"

---

## 3. 스펙 내부 모순 & 미확정 (발견된 것)

| 도메인 | 모순/미확정 | 조치 |
|--------|-----------|------|
| lesson | 레슨 타입 enum 미모델링 — 스펙 섹션 10에 정의만, 코드 확인 안 됨 | enum 코드화 + 단위 테스트 |
| lesson | 정기 레슨 제안 → 입금 확인 → 스케줄 카드 자동화 설계만 있음 | E2E 플로우 1회 관통 검증 |
| notification | 11개 카테고리 ↔ 구현된 트리거 매핑 문서 없음 | 카테고리별 실제 발화 지점 지도 작성 |
| design | UX 법칙(Hick's/Miller's) 화면별 적용 근거 문서 없음 | 주요 화면 10개 audit 표 추가 |
| follow | FollowListScreen/FeedScreen — 데이터만 있고 UI 스펙 완성도 낮음 | 와이어프레임 또는 경쟁사 레퍼런스 추가 |

---

## 4. 경쟁 서비스 대비 편의성 개선 Top 5

> 상세 근거: `docs/research/competitive_analysis.md`, `docs/research/tonara_app_analysis.md`

| # | 제안 | 참고 | 복잡도 | 임팩트 |
|---|------|------|:------:|:------:|
| 1 | 실시간 연습 타이머 + 백그라운드 알림바 | Practice Space | 중 | HIGH |
| 2 | 포인트/주간 배지 (스트릭 외 확장) | Tonara | 낮 | HIGH |
| 3 | 레슨 평가 템플릿 (음악용어 자동완성) | MyTractice | 낮 | MED |
| 4 | 인앱 메시징 (학생↔선생님) | Practice Space | 높 | MED |
| 5 | 학부모 읽기 전용 대시보드 | Tonara 3자 소통 | 중 | HIGH |

**Lessonaza 고유 강점 (유지 필수)**:
- 한국어 네이티브 (경쟁사 전무)
- 레퍼토리 템플릿 기반 연습 관리 (차별화)
- 학생 중심 데이터 소유권 (Practice Space는 선생님 중심)

---

## 5. UX 일관성 — 위반 카운트 요약

| 항목 | 카운트 | 룰 | 심각도 |
|------|:------:|----|:------:|
| `Color(0x...)` 하드코딩 | **0건 ✅** | AppColors | — |
| `fontSize:` 직접 | 168건 (87파일) | AppTypography | 🟡 |
| `EdgeInsets.` 숫자 직접 | 755건 (262파일) | AppSpacing | 🔴 |
| `Text('한글')` 직접 | 1,103건 (207파일) | AppStrings | 🔴 |
| `label/hint: '한글'` | 331건 (104파일) | AppStrings | 🟠 |
| `onTap: () {}` NO-OP | **0건 ✅** | 액션 필수 | — |
| `onPressed: null` | 0건 ✅ | 액션 필수 | — |
| '준비 중/Coming soon' | 16건 | 플레이스홀더 금지 | 🟡 |

**패턴 분석**: AppColors 규칙은 100% 준수됐으나, AppStrings/AppSpacing/AppTypography는 사실상 "선택 사항" 상태. 최근 추가된 UX rule(#UX-AppStrings)이 과거 코드에 역적용 안 됨.

---

## 6. 권장 실행 로드맵 (Top 10 기준)

### Sprint 1 (1주) — CRITICAL 해결
- [ ] #1 AppStrings 마이그레이션 (schedule 먼저, 도메인별 PR 분할)
- [ ] #2 FCM 연동 설계 착수 (별도 플랜 필요)
- [ ] #3 AppSpacing 스크립트 마이그레이션 (schedule/backup_widgets 우선)

### Sprint 2 (1주) — HIGH
- [ ] #4 공통 위젯 활용 audit + 중복 교체 1차
- [ ] #5 미매핑 라우트 정리 (제품 결정)
- [ ] #6 학부모 읽기 전용 대시보드 MVP

### Backlog — MEDIUM
- [ ] #7 실시간 타이머 스펙 승격
- [ ] #8 게이미피케이션 확장 (포인트/배지)
- [ ] #9 fontSize 일괄 마이그레이션 (#3과 병행 가능)
- [ ] #10 Riverpod 3.0 마이그레이션 계획 수립

---

## 7. 방법론 주석

- **데이터**: 4개 Explore 에이전트(스펙/코드/UX/경쟁)를 병렬로 돌린 결과를 합성
- **제한**: 런타임 동작(사용자가 앱을 실제로 쓸 때 느끼는 감정) 검증 없음 — 디바이스 테스트 별도 필요
- **다음 추천 세션**:
  - 모드 B (lesson/practice/subscription 심층) — 이 리포트에서 식별된 블로커 상세 파기
  - UX 리뷰 세션 — Top 3 UX 이슈를 실기기에서 검증
- **하네스 점검**: 별도 세션에서 진행 중 (사용자 확인)

---

## Changelog

| 날짜 | 내용 |
|------|------|
| 2026-04-17 | 초안 작성 — Top-Down Overview 모드 |
