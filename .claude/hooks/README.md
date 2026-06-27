# Hooks

> Claude Code 훅 와이어링은 **`.claude/settings.json` 의 `hooks` 블록**이 SSOT 입니다.
> Claude Code 는 이 디렉토리의 별도 json 파일을 읽지 않습니다 — 스크립트만 두고, 등록은 settings.json 에서 합니다.

## 기본 와이어링 (settings.json)

| 이벤트 | 스크립트 | 역할 |
|--------|----------|------|
| SessionStart | `scripts/session-start.py` | 하네스 상태 요약 주입 |
| UserPromptSubmit | `scripts/keyword-detector.py` | 대화 카테고리 감지 → 스킬 자동 추천 (상위 3) |
| PreToolUse (Bash) | `scripts/bash-guard.py` | 위험 명령 차단 |
| PostToolUse (Edit/Write/MultiEdit) | `scripts/drift-monitor.py` | spec 드리프트 신호 적재 |
| PostToolUse | `scripts/loop-detection.py` | 동일 파일 반복 편집 감지 |
| PostToolUse | `scripts/i18n-l10n-guard.py` | 하드코딩 UI 문자열 감지 |
| PostToolUse | `scripts/check-spec-claim.sh` | 스펙 "- [x] 완료" 주장 vs 실제 코드 괴리 경고 |
| PostToolUse | `scripts/check-version-leftover.sh` | 스펙 버전 전환(vN→vN+1) 후 코드 잔재 경고 |
| PostToolUse | `scripts/check-lore-inline.sh` | 스펙 인라인 Lore 표기 → git trailer 이동 권고 |
| Stop | `scripts/stop-journal-reminder.py` | journal 기록 리마인더 |
| PreCompact | `scripts/precompact-snapshot.py` | 컴팩션 직전 working-set 스냅샷 → `.harness/status/handoff.md` |
| SessionEnd | `scripts/session-end-snapshot.py` | 세션 종료 시 스냅샷 + journal 점검 |
| SubagentStop | `scripts/subagent-stop-log.py` | 서브에이전트 완료 로그(`subagent-log.jsonl`) + 독립검증 넛지 |

> `scripts/_snapshot.py` 는 훅이 아니라 PreCompact·SessionEnd 가 공유하는 헬퍼 모듈(settings.json 미등록).

## 스킬 자동 적용 2경로 (명령어 없이)

명령어(`/skill`) 없이 대화에 맞는 스킬이 적용되는 경로는 둘이다:

1. **모델 자동 호출** — 스킬 frontmatter `description`(트리거 조건)을 보고 Claude 가 스스로
   Skill 도구로 호출. 명령어 불필요(2단계 로딩). `description=WHEN`(skill-authoring.md)이 매칭률을 좌우. 모델 판단이라 100% 보장은 아님.
2. **훅 넛지(결정적)** — `keyword-detector.py` 가 매 프롬프트의 카테고리를 감지해
   `<skill-suggestion>` 블록을 주입 → Claude 가 추천을 보고 유도된다. (1)의 결정적 보완재.

카테고리·트리거·추천 스킬은 `keyword-detector.py` 의 `CATEGORY_MAP` 에서 프로젝트별로 가감한다.

## 훅 작성 규약 (advisory 원칙)

- **stderr 로만 경고, exit 0 유지** — 편집을 막지 않고 신호만 보낸다. 차단이 필요하면 PreToolUse + permissionDecision 사용.
- stdin 으로 JSON (`tool_input.file_path` 등) 을 받는다.
- 대상 파일이 아니면 즉시 `exit 0` (false-positive 억제).
- timeout 은 settings.json 에서 3–5초로 짧게.

## 새 훅 추가 절차

1. `scripts/check-<이름>.sh` 작성 (`chmod +x`)
2. `.claude/settings.json` 의 해당 이벤트 배열에 등록
3. 정책 근거를 `.claude/rules/<이름>.md` 에 문서화 (훅은 감지, 룰은 정책)

## Git 훅 (별도)

커밋/푸시 게이트가 필요하면 Claude Code 훅이 아닌 git 훅을 사용:

```bash
git config core.hooksPath .claude/hooks/git
```

언어별 권장 게이트는 `.cg/mechanical.toml` 의 build/test/lint 섹션과 `cg diagnose` 를 사용하세요.
