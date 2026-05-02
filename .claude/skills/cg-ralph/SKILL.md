---
name: cg-ralph
description: "검증 통과까지 멈추지 않는 영속 루프. 구현 → 검증 → 실패 시 재시도. max_iterations 필수. Adapted from Q00/ouroboros (MIT)."
---

# cg-ralph — The Boulder Never Stops

**트리거 키워드**: "ralph", "계속", "멈추지 마", "될 때까지", "실패하면 다시"

## 개요

실패 → 분석 → 재시도를 루프로 돌려, QA PASS 에 도달할 때까지 세션 내에서 자율 반복. 각 반복은 최신 실패 신호(테스트 로그, 타입 오류, 드리프트)를 입력으로 삼는다.

`cg-evaluation` 과의 차이:
- `cg-evaluation` = 3-critic 포멀 검증 (1회 판정)
- `cg-ralph` = 경량 QA + 루프 (PASS 까지 계속)

## 선행 조건 (중단 조건)

다음 중 하나라도 미충족이면 ralph 를 시작하지 않는다:

- [ ] `.harness/spec/{feature}.md` §2 성공 기준 존재
- [ ] `max_iterations` 명시 (기본값 10, 사용자 지정 가능)
- [ ] 기계적 검증 명령 존재 (`.cg/mechanical.toml` 또는 명시된 test 명령)

조건 미충족 → `cg-interview` 또는 `cg-spec-and-harness` 로 먼저 유도.

## 루프 구조

```
iteration = 1
while iteration <= max_iterations:
  1. EXECUTE
     - 최근 실패 신호를 먼저 요약
     - 스펙 §2 성공 기준 중 미충족 항목만 타겟
     - 독립 작업은 병렬 (여러 파일 동시 수정)
     - 실패 재현 테스트를 먼저 씀 (TDD RED)

  2. VERIFY (경량 QA)
     - .cg/mechanical.toml 의 build/test/lint 실행
     - 출력 파싱 → 점수 0.0 ~ 1.0
     - verdict: PASS (>=0.80) / REVISE (0.40-0.79) / FAIL (<0.40)

  3. DECIDE
     - PASS → 종료, cg-evaluation 으로 포멀 검증 제안
     - REVISE → 실패 신호 요약 후 iteration += 1
     - FAIL → 즉시 중단, cg-unstuck 으로 에스컬레이션

  4. REPORT (반복마다)
     [Ralph Iteration {i}/{max}]
     QA Verdict: {PASS/REVISE/FAIL} ({score})
     실패 신호:
       - {signal 1}
       - {signal 2}
     The boulder never stops. 다음 시도: {action}
```

## 종료 처리

| 종료 사유 | 다음 단계 제안 |
|---|---|
| PASS 도달 | `cg-evaluation` 으로 3-critic 포멀 검증 |
| max_iterations 도달 | `cg-unstuck` 으로 측면 사고 시도 또는 `cg-interview` 로 스펙 재검토 |
| FAIL 에스컬레이션 | 즉시 `cg-unstuck` 호출 |
| 사용자 "stop" | 현재 iteration 결과 유지, 재개 가능 상태로 보고 |

## 반복 로그 (권장)

각 iteration 의 요약을 `.harness/journal/{YYYY-MM-DD}.md` 에 기록:

```markdown
## Ralph Session {session_id}
- Request: {원래 요청}
- Spec: {참조 spec 파일}
- Max iterations: {N}

### Iteration 1/N
- Verdict: REVISE (0.65)
- 실패 신호: 3개 테스트 여전히 실패, api.py 타입 오류
- 적용한 변경: type annotations 보강

### Iteration 2/N
- Verdict: PASS (1.0)
- 종료
```

## 예시

```
사용자: /cg-ralph 실패하는 모든 테스트 고쳐줘 (max_iterations=5)

[Ralph Iteration 1/5]
QA Verdict: REVISE (0.65)
실패 신호:
  - tests/test_api.py::test_timeout 실패 (TimeoutError 미처리)
  - src/api.py:42 타입 오류
The boulder never stops. 다음 시도: fetch_data() 에 try/except TimeoutError 추가

[Ralph Iteration 2/5]
QA Verdict: REVISE (0.88)
실패 신호:
  - tests/test_api.py::test_edge_case 엣지 케이스 실패
The boulder never stops. 다음 시도: parse_input() 경계 검사 추가

[Ralph Iteration 3/5]
QA Verdict: PASS (1.0)

Ralph COMPLETE
==============
총 iterations: 3
다음: /cg-evaluation 으로 3-critic 포멀 검증
```

## 원칙 — "The Boulder Never Stops"

- 실패는 종료가 아니라 **다음 시도의 입력**
- 단일 검증 기준 (QA verdict) 으로 수렴 판단
- 루프 안에서 새로운 복잡도 추가 금지 (scope creep 방지)
- max_iterations 는 **사용자가 명시**, 무한 루프 금지
