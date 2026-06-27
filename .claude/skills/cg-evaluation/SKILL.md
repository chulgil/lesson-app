---
name: cg-evaluation
description: Phase 6 — 독립된 3-critic 평가 (code / test / e2e). Oracle Problem 을 방지하기 위해 각 critic 은 코드 작성 세션과 분리된 컨텍스트에서 실행.
---

# Phase 6 — Evaluation (3-Critic)

## 목적

구현이 **의도한 spec** 을 실제로 충족하는지 독립적으로 검증합니다. 작성자 편향을 제거하기 위해 3개의 critic 을 서로 독립된 컨텍스트에서 실행합니다.

> 같은 AI 가 코드+테스트를 함께 쓰면 테스트가 의도가 아닌 구현을 검증하게 됩니다 (정확도 ~6%, Oracle Problem). 그래서 critic 은 **반드시** Agent 도구로 분리 세션에서 실행합니다.

## 입력 / 출력

- 입력: Phase 5 의 구현 결과, `.harness/spec/{YYYY-MM-DD}-{feature}.md`
- 출력: `.harness/journal/{YYYY-MM-DD}-eval-{feature}.md`

## 절차 (요약)

```
Stage 1  Mechanical Verification (필수 선행)
         build → lint → test 를 .cg/mechanical.toml 순서로 실행.
         하나라도 실패 → 즉시 중단, Critic 1~3 전체 스킵.
   │ 모두 exit 0
Stage 2  LLM Critics (각각 독립 Agent 호출)
   ├── Critic 1   Code Critic    — spec 정렬·보안·엣지 케이스
   ├── Critic 2   Test Critic    — spec↔test 정렬만 (코드 비열람, Oracle Problem 핵심)
   ├── Critic 2.5 Security Reviewer — 공격자 관점 취약점 (ultra 필수)
   ├── Critic 2.7 교차 모델 리뷰   — 외부 CLI 독립 검증 (옵션, ultra 권장)
   └── Critic 3   E2E Eval        — 실제 실행 시나리오 (스크립트/Playwright/수동)
```

각 critic 은 코드 작성 세션과 분리된 컨텍스트에서 실행 — 자기확신 편향 제거.

## 종합 판정

| 결과 | 액션 |
|------|------|
| (Stage1 + 3-critic) 모두 PASS | Human Checkpoint 로 진행 |
| 하나라도 FAIL | Phase 5 로 복귀. 실패 컨텍스트를 재시도 프롬프트에 포함. |

## Human Checkpoint — 완료 선언 (필수)

**3-critic 모두 PASS 여도 사람이 명시적으로 "완료"를 선언해야 feature 가 locked 됩니다. 자동 진행 금지.**
critic 모두 PASS 라는 이유로 자동 merge / PR close 금지 — 사람의 명시적 "완료" 선언이 없으면 feature 는 `in-review` 상태로 유지.

> 완료 선언 체크리스트(상태 draft→locked, `Closes:` trailer, journal 엔트리)는 [reference.md](reference.md) 참조.

## Writer ≠ Evaluator — 격리 강제

같은 세션이 코드를 작성하고 평가하면 자기확신 편향으로 버그 발견율이 60%+ 떨어진다 (Anthropic 하네스 연구). 핵심 강제 규칙:

- Critic 은 **반드시** Agent 도구로 호출 (인라인/메인 직접 평가 → 즉시 FAIL)
- 프롬프트에 "당신은 작성자가 아닙니다" 명시, 입력은 **파일 경로**로만 전달
- Test Critic 은 `subagent_type="test-critic"` (코드 Read 차단)
- 한 세션에서 Critic 2개 이상 동시 호출 금지, 결과는 메인이 종합 판정

## 금지 사항

- **자가 평가 금지**: 코드 작성자가 critic 을 수행하면 원점. 반드시 컨텍스트 분리.
- **PASS 기준 완화 금지**: "대충 비슷" 은 FAIL.
- **Critic 결과 무비판 통과 금지**: Critic 도 틀릴 수 있다. 메인이 종합 판정.

> 상세: [reference.md](reference.md) — Stage 1 명령 표·출력 예, 각 Critic 의 전체 Agent 프롬프트,
> Critic 2.5/2.7 적용 기준·판정 조합 표, Human Checkpoint 체크리스트, 격리 게이트 6규칙·위반 신호·모드별 적용.
