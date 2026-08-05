# Figma Mirror Sync — 코드 → Figma 단방향 미러 유지

> 핵심 원칙: **코드가 SSOT. Figma 는 앱 화면의 미러다. 동기화는 코드 → Figma 단방향.**
> 결정 시점: 2026-08-03 (사용자 확정). 근거는 아래 §왜 단방향인가.

## 대상

Figma 파일 `nnBjRUgvEOsn3DprvGhWEF` (Lessonaza Design System) — Flutter 앱 화면의 미러.
커버 페이지 `00 · 시작하기 (READ ME)` 에 작업 규칙과 "마지막 동기화" 블록이 있다.

## 왜 단방향인가

Figma 에서 고친 것이 앱에 자동 반영되려면 **Code Connect** 가 필요한데, 이는
Org/Enterprise 플랜의 Dev/Full seat 를 요구한다. 현재 계정은 요건 미충족이다
(개인팀 `pro`+Full / org `View`). 따라서:

- Figma 프레임을 고쳐도 **앱은 바뀌지 않는다.**
- UI 개발자의 변경 제안은 **GitHub 이슈**로 남기고, 코드에 반영한 뒤 Figma 에 미러한다.
- 자동 반영이 필요해지면 플랜을 올리고 이 룰을 다시 쓴다.

## 원장 — `.harness/status/figma-sync.json`

Figma 가 **어느 커밋 기준으로** 미러됐는지 기록하는 단일 파일.

```json
{
  "file_key": "nnBjRUgvEOsn3DprvGhWEF",
  "synced_commit": "9e47e056",
  "synced_at": "2026-08-04",
  "frames": 169
}
```

**Figma 를 갱신한 사람이 같은 작업에서 이 파일도 커밋한다.** 갱신하지 않으면 훅이
계속 같은 경고를 내며, 원장이 실제보다 낡았다는 뜻이 되어 신호가 죽는다.

## 훅 — `.claude/hooks/scripts/figma-drift-check.py`

SessionStart 에서 원장의 `synced_commit` 이후 쌓인 **UI 커밋 수**를 세어 stderr 로 알린다.
**경고만 한다 — 항상 exit 0.** 무엇을 언제 반영할지는 사람이 정한다.

| 상황 | 동작 |
|---|---|
| UI 커밋 0건 | 조용히 종료 |
| 1건 이상 | 커밋 수·파일 수·영향 feature·미반영 커밋 목록 출력 |
| 5건 이상 | "반영을 검토하세요" 로 문구 강화 |
| 원장 없음 / git 없음 / 기준 커밋 부재 | 조용히 종료 (신규 클론·CI 방해 금지) |

UI 로 세는 경로는 `frontend/lib/**/presentation/**`, `core/theme/**`, `core/widgets/**`.
domain/data 변경은 화면 모양을 바꾸지 않으므로 제외한다.

## 갱신 절차

1. `git log --oneline <synced_commit>..HEAD -- 'frontend/lib/**/presentation/**'` 로 미반영 범위 확인
2. **origin/main worktree** 에서 실제 코드를 읽어 문구·구조 대조 (stale 브랜치 금지)
3. Figma 갱신 — 프레임 추가/수정. 색·타이포는 반드시 변수/스타일 바인딩
4. 커버의 "마지막 동기화" 블록 갱신
5. 원장의 `synced_commit`·`synced_at`·`frames` 갱신 후 커밋

## 반복해서 당한 함정

- **문구를 지어내지 말 것.** 프레임의 한글은 전부 `AppStrings` 실값이어야 한다. 과거에 상상으로 쓴 구간이 발견돼 전면 교정한 적이 있다.
- **변수 바인딩은 paint opacity 를 덮어쓴다.** `setBoundVariableForPaint` 후 `node.fills=[{...fills[0], opacity:N}]` 로 **다시** 설정해야 반투명이 산다.
- **Material 아이콘은 ligature 이름만 유효.** Flutter `Icons.checklist_rounded` → Figma `checklist`. `_rounded` 를 그대로 넣으면 "ROUNDED" 가 글자로 렌더된다.
- **크기 토큰이 없는 조합을 Figma 에 임의로 만들지 말 것.** 코드에서 먼저 이름을 정하고(#1221 방식) 내보낸다. 반대로 하면 드리프트를 고착시킨다.

## 상위 규칙과의 관계

- [doc-sync.md](doc-sync.md): 코드↔스펙 동기화. 이 룰은 코드↔**디자인** 동기화로 같은 형태.
- [frontend-verify.md](frontend-verify.md): UI 변경의 시각 검증. 그 결과가 Figma 갱신 대상이 된다.
- [ux-rules.md](ux-rules.md): C1~C8 일관성 계약 — Figma 프레임도 같은 토큰 체계를 따른다.
