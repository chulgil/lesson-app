# 학생 화면 Notebook × Score 전수 감사 & 수정 계획

> 작성일: 2026-04-23
> 모드: `/plan --eng`
> 상태: ✅ 완료 (Phase 1~4 전부 반영 — §7.87-a~i + §7.88/§7.89/§7.90 README 기록, 학생 화면 17 도메인 전수 감사 종결)

## 요구사항

1. 스펙: `docs/specs/design/notebook/README.md` (Notebook × Score — 4대 시그니처 + §7.17/§7.30/§7.50)
2. 학생 진입 경로 전 화면이 스펙을 실제 렌더 기준 충족하는지 검증
3. 갭 발견 시 surgical 수정, §7.30 예외는 근거 기록
4. 변경은 `notebook/README.md` §7.87+ 새 섹션에 기록

## 학생 화면 범위

- **직접 도메인**: `features/student_home/`, `features/onboarding/`
- **교차 도메인(학생 진입)**: auth, practice, lessons, schedule, subscription, invite, search, gamification, notifications, relationship, follow

## Phase

| Phase | 내용 | 파일 영향 | 상태 |
|------|------|----------|------|
| 1. 감사 | router 분석 + grep → `docs/specs/design/notebook/student_screens_audit.md` 생성 | 1 (신규) | ✅ 완료 |
| 2. 리뷰 | 매트릭스 제시 → 우선순위 확정 | 0 | ✅ 완료 |
| 3.A | student_home §7.17×9 + §7.27×2 (11 지점 / 10 파일) | 7 | ✅ 커밋 `7b1fe0ae` |
| 3.B | onboarding §7.17 BLOCK 4건 (2 파일) | 2 | ✅ 커밋 `5fe7f3be` |
| 3.C | invite §7.17 × 4 + §7.30 × 8 지점 재분류 | 1 | ✅ 커밋 `e6fd7f15` + §7.87-i/§7.89 재분류 |
| 3.D | gamification 6 + search 2 + auth 2 §7.30 재검증 | 0 | ✅ README §7.88 기록 |
| 3.E | onboarding 후보 3건 (tutorial·student_tutorial·phone_verification) | 3 | ✅ 커밋 `f5b7b488` |
| 3.F | 경계 6 도메인(notifications·follow·relationship·booking·settings·home) 재검증 | 0 | ✅ 커밋 `bb087761` — §7.90 기록 |
| 4. 검증 | flutter analyze 전체 + README §7.87~§7.90 추가 | 1 | ✅ 완료 (No issues found, 19.9s) |

각 배치는 사용자 승인 후 단일 커밋.

## 리스크

| 리스크 | 등급 | 완화 |
|-------|------|------|
| 학생 진입 화면 정의 모호 | HIGH | Phase 1에서 router 분석으로 명시화 |
| §7.30 예외 오판 | MED | 10-패턴 자동 판정(§7.84) |
| 범위 폭주 | MED | 배치마다 사용자 게이트 |
| 병행 세션 충돌 | LOW | 배치 시작 전 git status 확인 |

## 예상 복잡도: MEDIUM (4~7시간)

## 이전 계획

자가 개선 하네스 계획 (2026-04-22, Phase 1-6 완료) — `git log prompt_plan.md`로 추적.
