---
name: cg-spec-and-harness
description: Phase 2 — 인터뷰를 공식 스펙으로 변환하고, 이 feature 에 적용될 품질 계약을 확정합니다. `.harness/spec/{YYYY-MM-DD}-{feature}.md` + `harness/current.md` 업데이트.
---

# Phase 2 — Spec & Harness

## 목적

인터뷰에서 얻은 요구사항을 **실행 가능한 스펙** 과 **품질 계약** 으로 굳힙니다. 이후 모든 phase 가 이 스펙을 절대 기준으로 삼습니다.

## 입력

- Phase 1 의 `interview/{YYYY-MM-DD}-{feature}.md`
- Phase 0 의 `harness/current.md`

## 출력

- `.harness/spec/{YYYY-MM-DD}-{feature-slug}.md`
- 필요 시 `harness/current.md` 업데이트 (예: 새 테스트 프레임워크 도입)

## 스펙 템플릿

```markdown
# Spec — {feature-slug}

> 날짜: {YYYY-MM-DD} | 상태: draft|locked
> 인터뷰: .harness/interview/{YYYY-MM-DD}-{feature-slug}.md

## 1. 목표 (한 문장)

## 2. 성공 기준 (측정 가능해야 함)
- [ ] ...

## 3. 사용자 시나리오 (Given/When/Then)
### 시나리오 1: 
- Given ...
- When ...
- Then ...

## 4. 스키마 / 인터페이스
### 새 엔티티
```
{타입/스키마 정의}
```

### API 엔드포인트
| Method | Path | Body | Response |
|--------|------|------|----------|

## 5. 비기능 요구사항
- 성능: p95 < ...ms
- 보안: ...
- 관측성: ...

## 6. 아키텍처 결정
- 채택 패턴:
- 거절한 대안 (이유 포함):

## 7. 품질 계약 (이 feature 에 적용)
- 단위 테스트 커버리지: ≥ N%
- E2E 시나리오: ...
- Lint 예외: 없음 | (있다면 사유)

## 8. 위험과 완화
| 위험 | 영향도 | 완화 |
|------|--------|------|

## 9. 범위 외
- ...
```

## 품질 계약 체크

`harness/current.md` 와 스펙이 충돌하지 않는지 확인:
- 새 lib 추가 → current.md 의 "허용 라이브러리" 업데이트
- 새 테스트 프레임 → current.md 의 "테스트" 섹션 갱신

## 완료 조건

1. 모든 성공 기준이 **측정 가능** (이진 또는 숫자)
2. 사용자가 "spec locked" 를 명시적으로 승인
3. `.harness/spec/...` 파일 커밋
