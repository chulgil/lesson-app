---
name: maintain-docs
description: 코드 변경 시 관련 문서를 함께 업데이트합니다.
allowed-tools: Read, Grep, Edit, Glob
---

# Maintain Docs Skill - Lesson App (Flutter/Dart)

코드 변경 시 **관련 문서를 동기화**하여 문서와 코드의 일관성을 유지합니다.

## 사용 시점

- 새 기능 구현 완료 후
- API/모델 변경 후
- 아키텍처 변경 후
- 버그 수정 후 (동작 변경 시)

## 문서 위치

```
docs/
├── architecture.md          # 아키텍처 가이드 (폴더 구조, 패턴)
├── refactoring_tasks.md     # 리팩토링 현황
├── README.md                # 문서 인덱스
├── requirement/             # 요구사항
├── proposal/                # 기획 제안서
└── specs/                   # 기능 명세 (도메인별)
    ├── design/              # UX 가이드라인
    ├── practice/            # 연습 기능
    ├── metronome/           # 메트로놈
    ├── recording/           # 녹음 기능
    └── invite/              # 초대 시스템
```

## 코드-문서 매핑

| 코드 위치 | 관련 문서 |
|----------|----------|
| `features/lessons/` | `docs/specs/lesson/` |
| `features/practice/` | `docs/specs/practice/` |
| `features/students/` | `docs/specs/student/` |
| `core/audio/metronome*` | `docs/specs/metronome/` |
| `core/audio/recording*` | `docs/specs/recording/` |
| `core/router/` | `docs/architecture.md` |
| 새 Provider 추가 | `CLAUDE.md #provider-mapping` |
| 새 모델 추가 | `CLAUDE.md #models` |

## 앵커 업데이트 규칙

### CLAUDE.md 앵커 목록
```
#overview, #quick-reference, #commands, #iphone-deploy
#project-structure, #issue-workflow, #claude-guidelines
#core-rules, #provider-mapping, #docs-structure, #models
#implementation-status, #priorities, #github-issues
#todo-management, #troubleshooting
```

### 앵커 추가 형식
```markdown
## 섹션 제목 {#anchor-id}
```

## 작업별 업데이트 체크리스트

### 새 기능 구현 시
- [ ] `docs/specs/[domain]/` 스펙 문서 추가/업데이트
- [ ] `CLAUDE.md #implementation-status` 상태 업데이트
- [ ] 관련 Provider → `#provider-mapping` 추가
- [ ] 관련 모델 → `#models` 추가

### 아키텍처 변경 시
- [ ] `docs/architecture.md` 업데이트
- [ ] `CLAUDE.md #project-structure` 업데이트
- [ ] `docs/refactoring_tasks.md` 현황 업데이트

### 버그 수정 시 (동작 변경)
- [ ] 관련 스펙 문서 동작 설명 업데이트
- [ ] `docs/specs/[domain]/` 예외 케이스 추가

### 명령어/설정 변경 시
- [ ] `CLAUDE.md #commands` 업데이트
- [ ] `#troubleshooting` 새 해결법 추가

## 사용법

```
"연습 기능 구현 완료했으니 문서 업데이트해줘"
"새 Provider 추가했는데 CLAUDE.md에 반영해줘"
"#implementation-status 업데이트해줘"
```

## 자동화 패턴

### 새 기능 완료 시
```
1. 기능 구현 완료
2. "문서 업데이트해줘" 요청
3. Claude가 자동으로:
   - 관련 스펙 문서 검색
   - CLAUDE.md 섹션 업데이트
   - 커밋 메시지에 docs 포함
```

### 커밋 메시지
```bash
# 코드 + 문서 함께 변경 시
git commit -m "feat(연습): 구간 반복 기능 추가

- lib/features/practice/에 section 관련 위젯 추가
- docs/specs/practice/section_repeat.md 스펙 추가
- CLAUDE.md 구현 현황 업데이트"
```

## 주의사항

- 문서 업데이트 없이 코드만 변경하면 경고
- 스펙과 구현이 다르면 스펙 우선 (또는 스펙 수정 요청)
- 앵커 ID는 kebab-case 사용 (`#my-anchor`)
