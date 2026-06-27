# Worktree Parallel Workflow — tmux + git worktree 병렬 개발 강제

> 자동 적용: 모든 비자명 개발 작업은 별도 tmux + git worktree 에서 진행. main 직접 작업 금지.
> 위반 사례: 2026-06-08 main 직접 작업 중 다른 세션 rebase 와 충돌 → 파일 손실 (Quest BE 컬럼/마이그레이션/테스트). dangling commits 만 reflog 에 남음.
> 사용자 명시: "모든 작업은 tmux git worktree로 병렬로 진행되어야합니다. 기존 소스코드에 영향없이 작업이 끝났을경우만 main 으로 merge."

## 핵심 규칙

| 단계 | 행동 |
|------|------|
| 새 작업 시작 | git worktree 생성 + tmux 세션 분리 |
| 코드 작성 | worktree 안에서만 — main 직접 편집/커밋 금지 |
| 검증 | worktree 내 테스트/빌드/린트 통과 (`cg diagnose`) + 프론트 변경 시 UI 회귀 |
| 병합 | 검증 통과 후 main 으로 merge (PR 권장) |
| 정리 | merge 후 worktree 제거 |

## 적용 대상 (자동 권장)

다음 작업을 시작할 때 Claude 는 worktree 생성을 **먼저 권장**한다 (사용자 명시적 반대 없으면 진행):

- 새 feature / 기능 추가
- 리팩토링 (3+ 파일 변경)
- 도메인/스펙 변경
- UI 재설계
- 백엔드 마이그레이션
- 의존성 메이저 업그레이드

## 예외 — main 직접 작업 허용

다음만 main 에서 직접 가능:

- 문서/주석 1-2줄 수정
- 룰·메모리 갱신 (`.claude/`, `~/.claude/`)
- 빠른 읽기 명령 (`git status`, `git log`, grep, 파일 read)
- hotfix 1-2줄 (긴급 + 사용자 명시 승인)

## 새 작업 시작 흐름

### 옵션 A — Claude Code 내장 (권장)

```
EnterWorktree({name: "<feature-slug>"})
```

`.claude/worktrees/<feature-slug>` 자동 생성 + 세션 디렉토리 전환. base ref 는 origin/main 기본.

### 옵션 B — 수동 (사용자 tmux 직접 관리)

```bash
git worktree add ../lesson-app-<feature> -b feat/<feature>
cd ../lesson-app-<feature>
tmux new -s lesson-<feature>
```

## 다중 세션 충돌 방지

작업 시작 전 격리 확인:

```bash
git worktree list           # 활성 worktree 목록
git branch -a               # 다른 브랜치 작업 여부
```

- 같은 브랜치를 두 worktree 에서 동시 체크아웃 금지 (git 자체가 차단)
- rebase / reset 은 **본인 worktree 안에서만** — main worktree 에서 절대 금지

## 병합 전 검증

worktree 작업 완료 시:

1. `/handoff-verify` 또는 `/verify-loop` 실행 (테스트 + 빌드 + 린트)
2. 프론트 변경 시 `frontend-verify.md` 의 Playwright 스크린샷 회귀 1회
3. PASS 시 main 으로 merge:
   - PR 흐름 (권장): `gh pr create` → 리뷰 → merge
   - 직접 merge: `git checkout main && git merge --ff-only feat/<feature>` (PR 권장)
4. merge 후 worktree 정리:
   - `ExitWorktree({action: "remove"})`
   - 또는 `git worktree remove ../lesson-app-<feature>`

## 병렬 worktree 권장 시점

다음 상황은 worktree 를 **동시에 2개 이상** 띄우는 것이 효율적:

- 프론트 + 백엔드를 분리 작업
- 같은 도메인의 독립 feature 2개 (예: 운영시간 재설계 + 가격표 분리)
- 긴 빌드 중 다른 도메인 진행

각 worktree 는 별도 tmux 세션. 결과 종합 후 순차 merge.

## 금지 사항

- main 브랜치에서 직접 커밋 (위 예외 외)
- 검증 통과 전 main merge
- 두 작업이 같은 working tree 공유
- `git push --force` 를 main 에 (어떤 경우든 금지)
- worktree 안에서 다른 worktree 의 브랜치를 reset/rebase

## 책임 분배

| 행위 | 주체 |
|------|------|
| worktree 생성 제안 | Claude (작업 시작 시 자동) |
| tmux 세션 관리 | 사용자 (필요 시) |
| 검증 실행 | Claude (`/handoff-verify`) |
| main merge 결정 | 사용자 (PR 머지 승인) |
| worktree 정리 | Claude (`ExitWorktree` after merge) |

## 상위 규칙과의 관계

- [adaptive-quality.md](adaptive-quality.md): worktree 안에서 ultra/balanced/fast 모드 결정
- [verification.md](verification.md): merge 전 증거 요구 (Iron Law)
- [git-workflow-v2.md](git-workflow-v2.md): 커밋/PR 작성 규칙
- [frontend-verify.md](frontend-verify.md): 프론트 변경 시 스크린샷 회귀
- 메모리 SSOT: `~/.claude/projects/.../memory/feedback_worktree_parallel_workflow.md` — 이 룰의 historical context

## 자동 반영 약속

> 다음 세션부터 사용자가 "worktree 사용해" 라고 명시하지 않아도 위 규칙을 자동 적용한다.
> Claude 는 새 feature 작업 시작을 인지하면 "이 작업은 worktree 에서 진행하겠습니다" 라고 선언 후 `EnterWorktree` 호출.
