# Workflow Rules

> 이 규칙은 매 세션 자동 로딩되어 워크플로우를 강제합니다.

## 7-Phase 기본 흐름

모든 비자명한 작업(3파일 이상 변경 or 새 feature)은 다음 순서를 따릅니다:

```
Phase 0: cg-brownfield-scan   (기존 코드 스캔, 처음 1회만)
Phase 1: cg-interview          (요구사항 인터뷰)
Phase 2: cg-spec-and-harness   (공식 스펙 작성)
Phase 3: cg-visuals            (Mermaid 다이어그램)
Phase 4: cg-decomposition      (DAG 분해)
Phase 5: cg-execution-loop     (구현 루프)
Phase 6: cg-evaluation         (3-critic 평가)
```

각 phase 의 상세는 `.claude/skills/<phase>/SKILL.md` 참조.

## 예외 (간단한 작업)

다음은 phase 전체를 건너뛸 수 있습니다:
- 오탈자 / docs 수정
- 1-2 파일 버그 수정
- 의존성 업데이트

단, `.harness/current.md` 의 품질 계약은 여전히 준수해야 합니다.

## 문서 우선 (Spec First)

**코드보다 스펙이 먼저 존재해야 합니다.** Phase 2 완료 없이 Phase 5 를 시작하지 마세요.

## 역피드백 (Feedback Loop)

- Phase 6 의 critic 이 FAIL 하면 Phase 5 로 복귀
- 스펙이 잘못된 걸 발견하면 Phase 2 로 복귀 (단방향 아님)
- Lore: 결정을 바꾸면 커밋 메시지 trailer 에 `Lore-directive:` 로 기록

## 컨텍스트 관리

- 작업의 자연스러운 경계(phase 전환)에서 `/compact` 허용
- 컨텍스트 50% 초과 시 새 세션 시작 고려
- 중요 결정은 `.harness/spec/` 또는 `.harness/knowledge/` 에 저장 (메모리 아님)
