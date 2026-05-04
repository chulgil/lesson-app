---
description: 새 feature 를 7-phase 워크플로우로 시작. Phase 1 인터뷰부터 진입.
---

# /new-feature

## 용도

Brand-new feature 를 처음부터 끝까지 하네스 프로토콜로 진행합니다.

## 흐름

1. 사용자에게 **feature 이름** 을 물음 (slug 형태: `lesson-booking`)
2. 오늘 날짜 + feature-slug 로 파일 경로 계산
3. **Phase 0 게이트**: `.harness/harness/current.md` 가 템플릿 상태(플레이스홀더 포함)이면 **Phase 0 (cg-brownfield-scan)** 을 먼저 실행하여 프로젝트 스택을 current.md 에 반영
4. **Phase 1 (cg-interview)** 을 스킬로 호출
   - `.harness/interview/{YYYY-MM-DD}-{feature-slug}.md` 생성
   - `.harness/knowledge/glossary.md` 에 신규 용어 반영
5. 사용자 승인 후 **Phase 2 (cg-spec-and-harness)** 진행
6. 이후 Phase 3 → 6 까지 순차 실행, 각 phase 경계에서 `/compact` 제안

## 스킵 조건

- 사용자가 "간단한 fix 야" 라고 명시 → Phase 2 (스펙 lite) 만 만들고 Phase 5 직행 허용
- docs only 변경 → 전체 스킵

## 체크포인트

각 phase 완료 시 아래를 확인하고 사용자에게 명시적 승인 요청:

```
[Phase N 완료]
- 산출물: {path}
- 다음 Phase: {next}
- 계속 진행하시겠습니까? (y/수정/중단)
```
