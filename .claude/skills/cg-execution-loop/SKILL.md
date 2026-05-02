---
name: cg-execution-loop
description: Phase 5 — DAG 의 각 job 을 순서대로 구현하고 커밋합니다. Steer 메시지를 주기적으로 확인하고, 실패 시 재시도 컨텍스트와 함께 루프.
---

# Phase 5 — Execution Loop

## 목적

Phase 4 의 DAG 를 **실행** 합니다. 각 job 단위로 구현 → 커밋 → 다음 job 을 반복합니다.

## 입력

- Phase 4 의 `decomposition-{...}.md`
- `harness/current.md` (품질 계약)

## 출력

- 각 job 단위 커밋
- `.harness/journal/{YYYY-MM-DD}.md` 엔트리

## 루프

```
for job in topological_order(DAG):
    1. Steer inbox 확인 (.harness/steer/inbox.md)
       - emergency → 중단
       - directive → 우선순위 재계산
       - context → 기록만
    2. Job 컨텍스트 로드 (spec + 관련 이전 job 산출물)
    3. 구현
    4. 로컬 검증 (lint + 단위 테스트)
    5. 커밋 (한국어 Conventional Commits)
       - 실패 시 최대 3회 재시도 (실패 컨텍스트 포함)
    6. Journal 엔트리 추가
```

## 커밋 메시지 포맷

```
<type>(<scope>): <한 줄 요약>

- 무엇을 왜 바꿨는지 본문에 설명
- 스펙의 어느 성공 기준을 충족하는지 명시

Refs: .harness/spec/{YYYY-MM-DD}-{feature}.md#J1
```

## 실패 처리

| 실패 유형 | 조치 |
|---------|------|
| Lint 실패 | 자동 수정 후 재시도 |
| 단위 테스트 실패 | 원인 파악 → 코드 수정 → 재시도 (최대 3회) |
| 3회 실패 | 해당 job blocked 표시, 사용자 보고, 다음 독립 job 으로 진행 |

## 원칙

- **surgical changes**: 요청된 것만 변경. 주변 리팩토링 금지.
- **커밋 단위 = 검증 단위**: 커밋 전에 반드시 로컬 검증.
- **Journal 은 간결하게**: 무엇을 했고, 무슨 결정을 했는지 3-5줄.

## 경량 모드 — PGE (Plan-Generate-Evaluate)

> Anthropic 하네스 연구 (2026): Opus 4.x 환경에서는 마이크로태스크 ·
> 컨텍스트 리셋 · 스프린트 계약 같은 오버헤드 대부분이 불필요. 모델
> 능력에 맞춰 **3요소** 만 남기면 토큰 30-40% / 시간 50% 절감.

### 진입 조건 (모두 만족해야 PGE 사용 가능)

| 조건 | 기준 |
|---|---|
| 변경 파일 | 3개 미만 |
| 새 도메인 | 없음 (기존 도메인 내 확장만) |
| 마이그레이션 | 없음 (DB·파일·API 호환 깨짐 없음) |
| 보안/billing 영역 | 미해당 (`rules/adaptive-quality.md` ultra 트리거 아님) |
| 외부 인터페이스 | 변경 없음 |

하나라도 미충족 → 자동으로 7-Phase 회귀.

### PGE 3단계

```
Plan       — 한 줄 의도 + 영향 파일 + 성공 기준 (구두 합의 OK, spec 파일 생략 가능)
   ↓
Generate   — 구현 + 단위 테스트 (TDD 우선). cg-execution-loop 재진입.
   ↓
Evaluate   — cg-evaluation Stage 1 (mechanical) + Critic 1 (Code Critic) 만 호출.
              Test Critic / Codex Reviewer / E2E 는 생략.
              FAIL → Plan 으로 회귀 (최대 3회), 회귀 후도 FAIL → 7-Phase 강제.
```

> **격리 강제**: PGE 의 Critic 1 호출도 `cg-evaluation` §Writer ≠ Evaluator
> 게이트의 규칙 1, 2 (Agent 도구 호출 + "당신은 작성자가 아닙니다" 명시) 가
> 적용된다. 인라인 평가 금지. 경량 모드라고 격리를 생략하면 자기확신 편향
> 차단 효과가 사라진다.

### 7-Phase 회귀 트리거

PGE 진행 중 다음 신호가 잡히면 즉시 7-Phase 로 전환 (진입조건 5개와 1:1 대응):

- 영향 파일이 3개를 넘어감 (예상 빗나감)
- 새 도메인 도입 발견 (기존 도메인 가정 깨짐)
- 마이그레이션 신호 발견 (DB·파일·API 호환 깨짐)
- 보안/billing 키워드가 코드에 등장
- 외부 인터페이스 변경 발견 (계약 깨짐)
- spec 정렬 위반 발견 (구두 합의 부족)
- Critic 1 FAIL 3회 연속

회귀 시 손실 없이 Phase 1 (Interview) 부터 재시작 (Phase 0 brownfield-scan 은 동일 도메인이면 생략 가능).

### 산출물

- 커밋 trailer 에 `Mode: PGE` 명시 (회고 시 식별용)
- Journal 엔트리: 1-2줄 ("PGE 완료, Critic 1 PASS")

## 학습 누적 (Recipe Promotion)

Phase 5 종료 후 권장 단계. 이번 루프에서 **반복된 명령**을 학습 자산으로 굳힙니다.

### 트리거 조건 (둘 중 하나)

- 이번 phase 의 journal 엔트리에 **3회 이상 동일 명령**이 등장.
- 이전 propose 이후 새 journal 엔트리가 **10개 이상** 누적.

### 실행

```bash
cg recipe propose                 # 임계 3회 (기본) 로 스캔
cg recipe propose --threshold 5   # 진짜 빈번한 패턴만
```

### 사람 게이트 (필수)

candidate 는 `.harness/recipes/{slug}.md` 에 작성됨. **검토 후** 승격:

```bash
cg recipe promote {slug}          # → .claude/skills/{slug}/SKILL.md
```

자동 promote 금지. cg-harness 철학(`golden-principles §12 Surgical Changes`)
유지를 위해 사용자가 직접 검토·승인해야 합니다.

상세: `.claude/skills/cg-recipe-promotion/SKILL.md`.

## 결정 누적 (Lore Proposal)

Phase 5 종료 후, 이번 루프의 **의사결정** 을 git trailer 후보로 누적.
Recipe Promotion 이 "반복 명령 → 스킬" 이라면, Lore Proposal 은
"의사결정 → trailer" 입니다.

### 트리거 조건

- journal 엔트리에 `결정:` 블록이 작성되었음.
- 아키텍처 선택 / 라이브러리 채택 / 범위 제한 결정 발생.

### 실행

```bash
cg lore propose                   # git log Lore-* 와 비교 후 미기록 결정만
cg lore propose --json            # CI/스크립트
```

### 사람 게이트 (필수)

candidate 는 `.harness/lore/{slug}.md` 에 작성됨. 사용자가 **직접**:

1. candidate 검토 (단순 작업 vs 재검토 가치)
2. 적합한 커밋에 trailer 추가:
   ```
   Lore-directive: <결정 한 줄>
   Lore-rejected: <대안> — 이유
   ```
3. trailer 가 커밋되면 archive 로 이동:
   ```bash
   cg lore promote {slug}         # → .harness/lore/archive/{slug}.md
   ```

`cg` 가 git commit 을 자동 생성하지 않습니다. 사용자 명시 동작만.

상세: `.claude/skills/cg-lore-proposal/SKILL.md`.

## Journal 엔트리 포맷

```markdown
## {HH:MM} — {job-id}: {요약}

결정:
- ...

산출물:
- commit: abc1234
- files: ...

비고:
- 예상 대비 실제:
```
