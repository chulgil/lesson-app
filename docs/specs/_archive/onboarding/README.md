# Onboarding spec — Archived versions

> ⛔ 이 디렉토리의 파일은 **참조 전용 (read-only)** 입니다.
> 새 작업은 항상 공식 SSOT 인
> [`docs/specs/onboarding/teacher_onboarding_v3_spec.md`](../../onboarding/teacher_onboarding_v3_spec.md)
> 를 따르세요.

## 이관 기록

| 파일 | 이관일 | 후속 SSOT | 흡수 내용 |
|---|---|---|---|
| `onboarding_master_v1.md` | 2026-06-01 | v3 | 첫 가용시간 인터스티셜, 가입 → 대시보드 직진 |
| `onboarding_quest_v2.md` | 2026-06-01 | v3 | 퀘스트 보드, 프로필 완성도 게이지 |

## 왜 archive 했나

E2E 감사 (`docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md`) #8
AB-H3 "v1/v2/v3 SSOT 3중 충돌" — 세 개 spec 이 동시에 존재해 어느 게 정답인지
불명. FE 코드는 v1 를 따랐고 v3 는 신규. 작업자(또는 AI 세션)가 잘못된
spec 을 읽고 잘못된 코드를 생성하는 위험을 차단하기 위해 v3 를 단일 SSOT 로
확정하고 v1·v2 를 본 archive 로 이관.

## 새 spec 을 archive 로 이관하려면

1. 새 SSOT 파일 상단에 흡수 결정을 명시 (어떤 항목이 어디로 이동했는지)
2. 본 디렉토리에 deprecated 파일을 옮기고 상단에 ⛔ DEPRECATED 헤더 추가
3. `feature_hub.md` 의 도메인 행을 새 SSOT 단일 링크로 정리
4. 본 README 의 "이관 기록" 테이블에 한 행 추가
