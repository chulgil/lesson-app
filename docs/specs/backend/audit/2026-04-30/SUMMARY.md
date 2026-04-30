# Backend Audit Summary — 2026-04-30

> 본 디렉토리는 Phase 3-2 audit 결과를 도메인별로 정리한다.
> 각 파일은 **격리 컨텍스트**에서 frontend SSOT vs backend 구현을 1:1 비교한 산출물.
> SSOT 정렬: `docs/specs/backend/backend_spec.md` 와 본 SUMMARY 가 동일 갭 매트릭스를 공유.

---

## 1. 점검 도메인 (3건)

| 도메인 | 산출물 | 프론트 상태 | 백엔드 상태 |
|--------|--------|----------|------------|
| analytics | [analytics.md](./analytics.md) | Phase 1+2 구현 (Mock) | **0%** — 라우터·모델·서비스 부재 |
| onboarding | [onboarding.md](./onboarding.md) | 5단계 완성 | **부분** — User.onboarding_completed 외 핵심 검증 API 부재 |
| home (선생님/학생/부모) | [home.md](./home.md) | 3 도메인 완성 | **재조합 가능** — 전용 endpoint 불필요 |

---

## 2. 우선순위 종합 (Pn 기준)

### P0 — 즉시 차단 (10건)

| # | 도메인 | 갭 | 영향 |
|---|--------|----|------|
| A1 | analytics | 월간 통계 조회 endpoint | 선생님 대시보드 빈 데이터 |
| A2 | analytics | 레슨 추이 (6개월 trend) | 차트 미동작 |
| A3 | analytics | 연습률 TOP 5 랭킹 | 학생 비교 불가 |
| A4 | analytics | TeacherMonthlyStats 응답 스키마 | 통계 카드 깨짐 |
| A5 | analytics | StudentPracticeRank 응답 스키마 | 랭킹 리스트 깨짐 |
| O1 | onboarding | Phone verification 발송/검증 API | 선생님 가입 차단 |
| O2 | onboarding | phone_verifications 테이블 | 인증 토큰 저장처 부재 |
| O3 | onboarding | Student.phone 컬럼 / 검증 플래그 | 학생 가입 시 동일 갭 |
| O4 | onboarding | Invite + Student 생성 원자성 | 부분 실패 시 고아 레코드 |

### P1 — 다음 sprint (8건)

| # | 도메인 | 갭 | 영향 |
|---|--------|----|------|
| A6 | analytics | 학생별 상세 리포트 endpoint | Phase 3 전체 |
| A7 | analytics | StudentReport 응답 스키마 | 동일 |
| A8 | analytics | 연습 데이터 조회 정렬 (시간순) | 히트맵 정확성 |
| A9 | analytics | 레퍼토리 진도 조회 | 학생 리포트 |
| A10 | analytics | 레슨 노트 학생별 시간순 조회 | 동일 |
| H1 | home (학생) | 다음 레슨 단일 응답 정렬/필터 | 5+ provider 순차 호출 → 지연 |
| H2 | home (부모) | 자녀별 통합 응답 (children rollup) | 자녀 N × 4탭 = N+1 |
| H3 | home (전체) | 통합 dashboard endpoint (옵션) | 재조합 비용 절감 |

### P2 — 백로그 (7건)

home.md §2 ~ §3 의 캐싱·재조합 정책, 알림 우선순위 sort, 부모 자녀 권한 필터 등.

---

## 3. 다음 행동

1. **Phase 3-1 완결** (본 PR): RequestEvent SSOT 라우터 + 마이그레이션 + 테스트.
2. **Phase 4 후보 (P0 우선)**: analytics 도메인 신설 (모델 → 서비스 → 라우터 → 응답 스키마).
3. **Phase 5 후보**: onboarding phone verification 보강 + Student.phone 컬럼 추가.
4. **Home 도메인은 별도 endpoint 생성하지 않음**. 클라이언트 재조합으로 충분, 캐싱 정책만 명시.

---

## 4. 갱신 정책

- 각 도메인 audit 파일은 **시점 동결** (2026-04-30 기준). 변경되면 새 폴더 (`audit/YYYY-MM-DD/`) 추가.
- 본 SUMMARY 는 **상위 인덱스**. 우선순위/갭 매트릭스 변경 시 P0/P1/P2 재정렬.
- `backend_spec.md` 와 본 SUMMARY 의 P0/P1 갭이 일치해야 함.
