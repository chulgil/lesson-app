# 자가 개선 하네스 — 구현 계획

> 작성일: 2026-04-22 (최근 갱신: 2026-04-23)
> 상태: ✅ 확정 (사용자 확정: 둘 다 / 적극적)
> 목표: 사용자 요청 → 자체 피드백 → 하네스 완성의 전주기 루프 구축

## 진행 현황 (2026-04-23)

| Phase | 상태 | 산출물 |
|-------|------|--------|
| 1. OBSERVE | ✅ 완료 | `~/.claude/hooks/harness-signal-capture.sh` (글로벌), `.claude/harness-signals/*.jsonl` (프로젝트), `.gitignore` 반영 |
| 2. CLASSIFY | ✅ 완료 | `~/.claude/skills/harness-improve/SKILL.md` |
| 3. APPLY | ✅ 커맨드 완료 (드라이런 기본) | `~/.claude/commands/harness-absorb.md` |
| 4. AUDIT | ✅ 기존 | `~/.claude/commands/harness-audit.md`, `harness-audit-reminder.sh` |
| 5. autopus 흡수 | ✅ 완료 (4/7 반영, 2 보류, 1 기존) | `~/.claude/rules/{lore-commit, hash-anchored-edit, adaptive-quality, frontend-verify}.md` |
| 6. 롤백 | ⏳ 대기 | Phase 5 후 |

**Phase 5 결과**:
- 반영(4): Lore Commit · Hash-Anchored Edit · Adaptive Quality · Frontend Verify
- 보류(2): @AX Annotation (범용성 약함) · Entropy Scan (improve-architecture 스킬과 범위 재검토 필요)
- 기존(1): Git Worktrees (`using-git-worktrees` 스킬 존재)
- 처리 이력: `~/.claude/homunculus/processed/2026-04/autopus-absorb.jsonl`
- 원안 6번 변경: `ux-consistency-check` 스킬은 플러그인 소유 → 신규 규칙 `frontend-verify.md` 로 대체

**수집기 정화 결과 (Phase 5 前)**:
- `harness-signal-capture.sh` 패치 (시스템 프롬프트 필터, regex word-boundary, slash_command 분리)
- `observations.jsonl` 노이즈 50건 → `observations.archive/legacy-noise-2026-04-23.jsonl` 분리
- 백업: `*.bak.2026-04-23`

**다음 액션**: Phase 6 롤백 — lesson-app 및 운영 프로젝트의 autopus 생성물(`.autopus/`, `autopus.yaml`, `.codex/`, `.gemini/`, `AGENTS.md`, `GEMINI.md` 등) 제거.

## 범위

- **스코프**: 프로젝트 하네스(`.claude/`) + 글로벌 하네스(`~/.claude/`) 둘 다
- **신호 민감도**: 적극적 (모든 수정·거부·반복·확인 캐치)
- **적용 원칙**: 자동 쓰기 금지 — 항상 사용자 승인 후 반영

## 피드백 루프 아키텍처

```
Layer 4: AUDIT (주간)  ← 죽은 규칙, 충돌, 중복 감지
Layer 3: APPLY (세션 종료 시)  ← 교훈 → rules/hooks/skills/memory/CLAUDE.md 라우팅
Layer 2: CLASSIFY (매 턴)  ← 일회성 vs 반복, 저장 위치 결정
Layer 1: OBSERVE (매 턴)  ← 신호 수집 (적극적)
```

## 적극적 신호 수집 규칙

| 신호 유형 | 트리거 키워드/패턴 | 신뢰도 |
|---|---|---|
| 명시적 거부 | "no", "stop", "don't", "다시", "틀렸", "아니" | HIGH |
| 명시적 확인 | "yes", "perfect", "맞다", "좋다", "그대로" | MEDIUM |
| 암묵적 수정 | 사용자가 내 출력을 재작성/편집 | HIGH |
| 반복 요청 | 같은 의도 요청 2회 이상 | HIGH |
| 범위 조정 | "더 간단하게", "더 자세히", "줄여" | MEDIUM |
| 방향 전환 | "다른 접근", "대신", "차라리" | HIGH |

임계값:
- HIGH 신호 1회 → 즉시 제안 후보
- MEDIUM 신호 2회 누적 → 제안 후보
- 제안 후보 → 사용자 승인 → 반영

## 구현 Phase

### Phase 1 — OBSERVE 레이어 (1.5시간)

**산출물**
- 훅: `.claude/hooks/session-signal-collect.sh` (PostToolUse + SessionEnd)
- 글로벌 훅: `~/.claude/hooks/session-signal-collect.sh`
- 저장: `.claude/harness-signals/YYYY-MM-DD.jsonl` (프로젝트) + `~/.claude/harness-signals/YYYY-MM-DD.jsonl` (글로벌)
- `.gitignore`에 `harness-signals/` 추가

**신호 JSONL 스키마**
```json
{"ts":"2026-04-22T14:30:00Z","type":"rejection","keyword":"다시","context":"...","scope":"project|global","confidence":"HIGH"}
```

### Phase 2 — CLASSIFY 라우터 (2시간)

**산출물**
- 신규 스킬: `~/.claude/skills/harness-improve/SKILL.md` (글로벌)
- 프로젝트 override: `.claude/skills/harness-improve-local/SKILL.md` (선택)

**라우팅 테이블**
| 신호 패턴 | 목적지 | 스코프 결정 |
|---|---|---|
| "이렇게 하지 마" (반복 가능) | `rules/{topic}.md` | 여러 프로젝트 적용 가능 → 글로벌 |
| "이 검증 자동화" | `hooks/{check}.sh` | 프로젝트 한정 |
| "이 절차 반복" | `skills/{name}/SKILL.md` | 일반화 가능 → 글로벌 |
| "이 사실 기억해" | `memory/{name}.md` | 프로젝트 한정 |
| "프로젝트 불변" | `CLAUDE.md` | 프로젝트 |

**스코프 판정 규칙**:
- 도메인·기술 중립적 규칙 → 글로벌
- 특정 프로젝트 파일/테이블/팀명 포함 → 프로젝트
- 모호하면 사용자에게 질문

### Phase 3 — APPLY 프로토콜 (1.5시간)

**커맨드**: `/harness-absorb [source]`

**동작**
1. `harness-signals/`에서 미처리 신호 로드
2. CLASSIFY 라우터로 분류 → 제안 목록 생성
3. 사용자에게 제안 테이블 표시 (파일 경로 + diff 요약)
4. 승인받은 항목만 파일 수정
5. 처리 완료 신호는 `harness-signals/processed/`로 이동

**첫 번째 테스트 케이스**: `/harness-absorb autopus-patterns`
- 입력: lesson-app `.claude/skills/autopus/` 5개 파일 (@AX / Lore / Hash-Anchored / Entropy / Adaptive)
- 출력: 글로벌/프로젝트 rules·hooks·skills 제안

### Phase 4 — AUDIT & 검증 (1.5시간)

**커맨드**: `/harness-audit`

**검사 항목**
- 죽은 규칙: 60일 이상 미참조 (MEMORY.md/rules/에서 검색)
- 중복 규칙: 임베딩 유사도 또는 키워드 중복
- 상충 규칙: "A하라" vs "A하지 마라" 패턴
- 고아 훅: 참조되지 않는 훅 파일

**자동 실행**: SessionStart 훅에서 주 1회 힌트 ("하네스 감사 X일 지남")

### Phase 5 — autopus 패턴 흡수 (Phase 3 프로토콜 사용, 1시간)

원 계획의 7개 패턴을 `/harness-absorb autopus-patterns` 로 실행:
1. @AX Annotation → `~/.claude/rules/ax-annotation.md` + 프로젝트 훅
2. Lore Commit → `~/.claude/rules/lore-commit.md`
3. Hash-Anchored Edit → `~/.claude/rules/hash-anchored-edit.md`
4. Entropy Scan → `~/.claude/skills/entropy-scan/SKILL.md`
5. Adaptive Quality → `~/.claude/rules/adaptive-quality.md`
6. Frontend Verify → 기존 `ux-consistency-check` 확장
7. Git Worktrees → `~/.claude/rules/git-worktrees.md`

### Phase 6 — 롤백 (autopus 생성물 제거, 30분)

lesson-app + 운영 3개 프로젝트에서 내가 생성한 autopus 파일 제거:
- `autopus.yaml`, `.autopus/`, `.codex/`, `.gemini/`, `AGENTS.md`, `GEMINI.md`, `config.toml`, `opencode.json`
- lesson-app은 `git checkout`으로 `.claude/settings.json`, `CLAUDE.md`, `.gitignore`, `.claude/commands/auto.md` 복구

## 실행 순서

```
Phase 1 (OBSERVE) → Phase 2 (CLASSIFY) → Phase 3 (APPLY)
                                            ↓
                                      Phase 5 (autopus 흡수 실행)
                                            ↓
                                      Phase 4 (AUDIT 구축)
                                            ↓
                                      Phase 6 (롤백)
```

총 복잡도: **MEDIUM-HIGH** (8시간)

## 운영 3개 프로젝트

lesson-app 검증 후 별도 세션에서 진행 (사용자 확정).

## 리스크

| 리스크 | 수준 | 완화 |
|---|---|---|
| 적극적 수집이 너무 시끄러움 | HIGH | 임계값(반복 횟수) 조정 + 사용자 일시 정지 명령 제공 |
| 자동 분류 오류로 rules 오염 | HIGH | 항상 승인 후 쓰기, 자동 쓰기 금지 |
| 글로벌 스킬 중복 생성 | MEDIUM | 라우팅 1순위: "기존 글로벌 스킬과 중복 → 생성 안 함" |
| 신호 저장소 용량 증가 | LOW | 월 1회 `processed/` 아카이브 압축 |
| autopus 패턴 검증 부재 | MEDIUM | 각 패턴 흡수 후 Red-Green 규칙 적용 테스트 |

## 성공 기준

- Phase 1 완료: 이 대화에서 생성한 신호가 `harness-signals/`에 JSONL로 저장됨
- Phase 2 완료: `/harness-absorb` 드라이런이 제안 테이블 출력
- Phase 3 완료: 승인한 1개 신호가 실제 파일로 반영됨
- Phase 5 완료: autopus 7개 패턴 중 최소 5개가 글로벌 rules/skills로 반영됨
- Phase 4 완료: `/harness-audit`가 죽은 규칙 0건 감지 (초기 상태 기준)

## 이전 계획

Phase C: 수강권 스케줄 관리 구현 계획 (2026-04-05) — 완료된 것으로 보이므로 아카이브.
내용은 git history로 추적 가능 (`git log prompt_plan.md`).
