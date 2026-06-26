---
name: cg-plan-check
description: Phase 4.5 — 실행 전 계획 검증 게이트. cg-decomposition 산출(DAG+AC Tree)이 spec 목표를 실제로 달성하는지 fresh-context 로 goal-backward 검증하고 PASS/REVISE 판정. Phase 5 진입 전 필수. 트리거: plan check, 계획 검증, 실행 전 점검, decomposition 검토.
---

# Phase 4.5 — Plan Check (실행 전 계획 검증 게이트)

## 목적

**한 줄: 잘못된 계획을 실행으로 옮기기 전에 잡는다.**

cg 의 다른 검증은 전부 사후(post-hoc) — 코드를 짠 뒤 본다. 이 게이트는 Phase 4(분해)와
Phase 5(실행) 사이에서, 아직 코드가 없을 때 **계획 자체**가 spec 목표를 달성하는지
검증한다. 실행 컨텍스트를 태우기 전에 되돌리는 비용이 가장 싸다.

> 비유: 출발 전에 지도를 거꾸로 짚어보는 것 — 도착지(목표)에서 출발해 각
> 갈림길(job)이 정말 그 길로 이어지는지 역으로 확인한다(goal-backward).

## 입력

- `.harness/spec/{date}-{feature}.md` (성공 기준)
- `.harness/spec/decomposition-{date}-{feature}.md` (DAG)
- `.harness/spec/ac-tree-{date}-{feature}.md` (AC Tree)

## 격리 (필수)

이 검증을 **계획을 쓴 세션이 하면 편향된다**. `plan-checker` 에이전트(별개 컨텍스트)
로 호출한다 — test-critic 과 같은 Oracle Problem 방어.

## goal-backward 체크리스트

도착지(spec 성공기준 / AC Tree leaf)에서 출발해 거꾸로 짚는다:

| # | 질문 | REVISE 신호 |
|---|------|------------|
| 1 | spec 의 각 성공기준마다 담당 job 이 있는가? | 커버 안 되는 기준 존재 |
| 2 | **key link(와이어링)가 명시 job 인가?** | 통합/연결 지점이 어느 job 에도 없음 |
| 3 | 범위를 넘는 job(scope creep)이 있는가? | spec 에 없는 기능 job |
| 4 | 단일 job 이 한 세션 컨텍스트(50%)를 넘기는가? | 너무 큰 job — 쪼개야 함 |
| 5 | DAG 의존성에 빠진 엣지가 있는가? | 암묵적 선행관계 누락 |
| 6 | eval job 이 dev job 과 분리됐는가? | 섞임 (Oracle Problem) |

> #2 가 핵심: 연구상 **스텁의 80%는 "만들었지만 연결 안 한" 미연결 링크에 숨는다**.
> A 만들고 B 만들었는데 A↔B 를 잇는 job 이 없으면 실행 후에도 동작하지 않는다.

## 판정

- **PASS** → Phase 5(cg-execution-loop) 진입.
- **REVISE** → 구체적 갭 목록과 함께 Phase 4(cg-decomposition)로 복귀. 최대 3회.
- 3회 후에도 REVISE → 사용자에게 보고(스펙 자체가 모호할 가능성 — Phase 2 복귀 검토).

## 출력 포맷 (Verifier 역할, 200단어 이내)

```
**요약**: {feature} 계획 검증 — job {N}개 / 성공기준 {M}개
**판정**: PASS / REVISE
**커버리지**: 성공기준 {M}개 중 {k}개 담당 job 확인
**미연결 링크** (있으면): {A→B 연결 job 없음}
**REVISE 항목** (REVISE 시): {구체적 갭 + 어느 job 을 추가/수정}
```

## 금지

- 계획 작성 세션에서 인라인 평가 (격리 위반).
- "job 이 많으니 괜찮겠지" — 커버리지는 개수가 아니라 성공기준 대응으로 판정.
- REVISE 인데 "사소하니 진행" — 미연결 링크 1개가 기능 전체를 죽인다.

## 관련

- 입력: `cg-decomposition` (Phase 4) · 후행: `cg-execution-loop` (Phase 5)
- 에이전트: `plan-checker` (별개 컨텍스트)
- 사후 검증: `cg-evaluation` (Phase 6, 코드 작성 후)
