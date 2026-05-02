# .claude/skills/

Claude Code 가 로드하는 **7-phase 워크플로우 스킬** 모음. 각 스킬은 `SKILL.md` 를 엔트리 포인트로 갖습니다.

## 7-Phase (tenet 방식)

| # | Skill | 역할 |
|---|-------|------|
| 0 | `cg-brownfield-scan` | 기존 코드/프레임워크/이전 하네스 산출물 스캔 |
| 1 | `cg-interview` | 요구사항 인터뷰 — 기술 리서치 + 모호성 제거 |
| 2 | `cg-spec-and-harness` | 공식 스펙 + 품질 계약(harness/current.md) 작성 |
| 3 | `cg-visuals` | 아키텍처 다이어그램 + UI 목업 |
| 4 | `cg-decomposition` | 스펙을 DAG(의존성 그래프) 로 분해 |
| 5 | `cg-execution-loop` | 각 job 구현 + 커밋 + 검증 |
| 6 | `cg-evaluation` | 3-critic 평가 (code / test / e2e) |

## 원칙

- **Phase 를 건너뛰지 않는다**: 각 phase 는 다음 phase 의 입력. spec 없이 바로 execution 으로 가면 드리프트.
- **Oracle Problem**: Test critic 은 반드시 코드 작성 세션과 분리된 컨텍스트에서 평가.
- **Feature-scoped 네이밍**: 모든 feature 산출물은 `{YYYY-MM-DD}-{slug}.md`.
