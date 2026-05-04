# Lore Trailer 마이그레이션 가이드

> 글로벌 규칙: [`~/.claude-forge/rules/lore-commit.md`](../../../tools/claude-forge/rules/lore-commit.md) (3 공식 키 + 트레일러 포맷).
> 본 가이드: 본 프로젝트의 **인라인 `**Lore-directive**:` 표기** 와 **git trailer** 의 경계 정책.

## 현황 (2026-04-27)

| 위치 | 표기 | 권장 |
|------|------|------|
| 커밋 메시지 본문 | `Lore-directive: ...` (마지막 빈 줄 뒤 trailer 영역) | **공식 채널** |
| `docs/specs/design/notebook/phase-log.md` | `**Lore-directive**: ...` (markdown 인라인) | **역사 보존만** |
| 신규 `docs/specs/**/*.md` | 인라인 표기 사용 금지 | git trailer 로 |
| 코드 주석 (`// Lore-...`) | 사용 금지 | git trailer 로 |

## 결정 트리 — 새 결정을 어디에 남길까?

```
새 의사결정 발생
    │
    ├─ 결정의 산출물이 코드 변경인가?
    │   └─ YES → 해당 커밋 trailer 에 Lore-directive/constraint/rejected 추가
    │              · 인라인 표기 금지 — 코드/주석/스펙에 박지 말 것
    │              · `git log --grep="^Lore-"` 으로 단일 진원지 조회
    │
    ├─ 결정의 산출물이 도메인 정책인가? (예: "휴가 색상 통일")
    │   └─ YES → 정책 본문은 `docs/specs/design/notebook/README.md` 또는
    │              해당 도메인 spec 에 평문으로 기록 (본문에서 정의)
    │              · `Lore-directive` 키 사용 금지 (스펙은 본문이지 trailer 가 아님)
    │              · 결정 사유는 정책 적용 커밋의 trailer 로
    │
    └─ phase-log.md 의 §7.X 신규 항목 추가인가?
        └─ YES → 본문 표기 가능 (역사적 보존 관행)
                · 단, 동일 결정의 git trailer 가 함께 존재해야 함
                · phase-log.md 의 표기는 **요약**, trailer 가 **공식 SSOT**
```

## 마이그레이션 정책

### 신규 작업 (2026-04-27 이후)

- **금지**: 새 spec/doc 에 `**Lore-directive**: ...` 인라인 추가
- **권장**: 결정은 git trailer 1지점, 본문은 정책/스펙 평문
- **예외**: phase-log.md `§7.X` 신규 항목은 인라인 보존 가능 (역사 컨벤션)

### 기존 인라인 표기 (phase-log.md)

- **보존**: 손대지 않는다 (Surgical Changes 원칙). 기록은 시점별 참조 가치
- **소급 트레일러 추가 금지**: 과거 커밋에 `git rebase -i + amend` 로 trailer 추가 금지 (history 변조)
- **검증**: `git log --grep="^Lore-directive:"` 으로 trailer 진원지 조회 후 phase-log 인라인이 그 사본임을 확인

## git trailer 작성 체크리스트

상위 규칙 [lore-commit.md](../../../tools/claude-forge/rules/lore-commit.md) 강제 + 본 프로젝트 추가:

| 키 | 본 프로젝트 사용 시점 |
|---|---|
| `Lore-directive:` | 디자인 시스템 토큰 추가/제거, 시그니처 적용 정책, 도메인 모델 변경 결정 |
| `Lore-constraint:` | 운영 현실 반영 (예: 근무시간 외 셀 클릭 활성), 보안/프라이버시 제약 |
| `Lore-rejected:` | 거절된 대안 + 이유 (반드시 `— ` 구분자) |

### 본 프로젝트 표준 예시

```
feat(notebook): §1.2 감사 시그니처 6대 SSOT 정렬

정체성 4대 (BLOCK 게이트) + 구조 2대 (점수 산식) 분리.

Lore-directive: 정체성 4 누락 = 점수 무관 BLOCK
Lore-directive: 구조 2 누락은 FLAG 단계 (점수 가중)
Lore-rejected: 6대를 단일 평면으로 측정 — Gaegu 누락 5/6 PASS 같은 정의 위반 점수 발생
```

## 조회 명령

```bash
# 본 프로젝트 모든 결정 history
git log --grep="^Lore-" --format="%h %s%n%b%n---" -- .

# 특정 도메인 결정만
git log --grep="^Lore-" -- docs/specs/design/notebook/

# 90일 이상 된 directive (재검토 후보)
git log --since="180 days ago" --until="90 days ago" --grep="^Lore-directive:"
```

## 자동화 후속 (Wave 4 후보)

- `.claude/hooks/check-lore-inline.sh` — 신규 spec/doc 추가 시 인라인 `**Lore-directive**:` 패턴 경고 (phase-log.md 제외)
- Lore trailer 조회: `git log --grep="^Lore-" -- <path>` (기존 `.claude/scripts/lore-context.sh`는 삭제됨)

## 책임 분배

| 역할 | 담당 |
|---|---|
| 인라인 → trailer 분리 강제 | 코드 리뷰어 + Wave 4 hook (예정) |
| trailer 형식 검증 | 글로벌 lore-commit.md (3 키만) |
| phase-log.md 인라인 보존 | Surgical Changes 원칙 (손대지 않음) |
| 신규 결정의 trailer 누락 | 작업자가 커밋 시점에 직접 추가 |
