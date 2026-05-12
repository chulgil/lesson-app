---
name: cg-subagent-dev
description: "구현 계획을 태스크 단위 서브에이전트로 실행. 2단계 리뷰(스펙 준수 → 코드 품질). Adapted from superpowers (MIT)."
---

# Subagent-Driven Development

**Trigger Keywords**: "subagent", "서브에이전트", "SDD", "병렬 구현", "태스크별 에이전트"

## Overview

구현 계획의 각 태스크를 독립 서브에이전트에 파견하고, 2단계 리뷰(스펙 준수 → 코드 품질)로 품질을 보장한다.

**Core Principle**: Fresh subagent per task + 2단계 리뷰 = 컨텍스트 오염 없는 고품질 구현.

## When to Use

- 구현 계획이 있고, 태스크가 대부분 독립적인 경우
- 같은 세션에서 연속 실행 (세션 전환 없음)
- Phase 5 (`cg-execution-loop`) 의 서브에이전트 버전

## Process

```
1. 계획 파일을 읽고 모든 태스크 + 컨텍스트 추출
2. TaskCreate 로 전체 태스크 등록

Per Task:
3. 구현 서브에이전트 파견 (태스크 전문 + 컨텍스트 전달)
   → 서브에이전트가 질문하면 답변 후 재파견
   → 구현 + 테스트 + 셀프리뷰 + 커밋

4. 스펙 리뷰 서브에이전트 파견
   → ✅ 통과 → 5단계
   → ❌ 미달 → 구현 서브에이전트가 수정 → 재리뷰

5. 코드 품질 리뷰 서브에이전트 파견
   → ✅ 통과 → 태스크 완료
   → ❌ 이슈 → 구현 서브에이전트가 수정 → 재리뷰

6. 모든 태스크 완료 후 최종 통합 리뷰
7. `cg-finish-branch` 로 브랜치 완료
```

## 서브에이전트 프롬프트 가이드

### 구현 서브에이전트
- 태스크 전문(full text) + 컨텍스트 제공 (계획 파일 읽기 금지)
- TDD 준수 (`tdd-loop` 스킬 참조)
- 셀프리뷰 후 커밋

### 스펙 리뷰 서브에이전트
- 스펙 문서 경로 + 구현 diff 전달
- **코드를 읽지 않고 스펙만 보고** 준수 여부 판단 (Oracle Problem 대응)
- 판정: ✅ Spec Compliant / ❌ Issues (목록)

### 코드 품질 리뷰 서브에이전트
- git SHA 범위 전달
- 코딩 스타일, 보안, 성능 검토
- 판정: ✅ Approved / ❌ Issues (목록)

## Red Flags

**Never:**
- 리뷰 건너뛰기 (스펙 리뷰 AND 코드 품질 리뷰 모두 필수)
- 미해결 이슈가 있는 상태로 다음 태스크 진행
- 여러 구현 서브에이전트를 동시 파견 (충돌 위험)
- 서브에이전트에게 계획 파일을 직접 읽게 하기 (전문 제공)
- 스펙 리뷰 전에 코드 품질 리뷰 시작 (순서 엄수)
- "close enough" 수용 — 스펙 리뷰어가 이슈 발견 = 미완료

## Integration

- **입력**: `cg-decomposition` (Phase 4) 산출물
- **출력**: 검증된 커밋 + `cg-finish-branch` 로 완료
- **대안**: `cg-execution-loop` (Phase 5) — 서브에이전트 없이 직접 실행
