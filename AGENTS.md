# AGENTS.md

Codex 및 기타 코딩 에이전트가 이 저장소에서 작업할 때 따르는 공통 지침이다.

이 문서는 `CLAUDE.md`, `.claude/rules/`, `.harness/`의 프로젝트 규칙을 보완한다. 충돌이 있으면 사용자 지시, 시스템 지시, `CLAUDE.md`와 `.claude/rules/`의 구체 규칙을 우선한다.

참고 원문은 <https://github.com/datajuny/andrej-karpathy-skills/blob/main/AGENTS.md>이다.

## 1. 작업 전 확인

- 실제 파일을 읽기 전에는 구현을 단정하지 않는다.
- `rg`로 관련 코드와 테스트를 찾고, 수정할 파일과 주변 호출부를 먼저 확인한다.
- 요구가 모호하면 가정과 선택지를 드러낸다.
- 여러 해석이 가능하면 조용히 하나를 고르지 않고 tradeoff를 설명한다.

## 2. 단순성 우선

- 요청받지 않은 기능, 옵션, 추상화는 추가하지 않는다.
- 한 번만 쓰는 코드를 위해 새 abstraction을 만들지 않는다.
- 기존 패턴으로 충분하면 새 구조를 만들지 않는다.
- 변경 라인은 사용자 요청과 직접 연결되어야 한다.

## 3. 외과적 변경

- 필요한 파일만 수정한다.
- 인접 코드, 주석, 포맷을 임의로 정리하지 않는다.
- 내가 만든 unused import, 변수, 함수는 제거한다.
- 기존 dead code를 발견하면 삭제하지 말고 사용자에게 보고한다. 사용자가 삭제를 요청한 경우에만 제거한다.

## 4. 더러운 워크트리 존중

- uncommitted 변경은 사용자의 작업으로 간주한다.
- 관련 없는 변경은 되돌리거나 재포맷하지 않는다.
- 같은 파일에 사용자 변경이 있으면 먼저 읽고 그 위에 맞춘다.
- `git reset --hard`, `git checkout --`, 대량 삭제 같은 파괴적 명령은 명시 요청 없이는 실행하지 않는다.

## 5. 검증 가능한 목표

- 버그 수정은 재현 테스트를 먼저 만든 뒤 통과시킨다.
- 리팩토링은 아키텍처 계약 테스트 또는 기존 회귀 테스트로 검증한다.
- 작은 관련 테스트를 먼저 돌리고, 위험도가 높으면 더 넓은 테스트와 `flutter analyze`까지 실행한다.
- 완료 보고에는 실제 실행한 명령과 결과를 적는다.

## 6. Flutter 프로젝트 규칙

- 새 코드는 `frontend/lib/features/[domain]/` 또는 `frontend/lib/core/`의 책임에 맞는 위치에 둔다.
- 상태 관리는 Riverpod을 사용하고, 신규 provider는 가능한 `riverpod_annotation` codegen 패턴을 따른다.
- UI 문구는 `AppStrings`를 우선 사용한다.
- 색상은 `AppColors`를 사용하고 raw `Color(0x...)`를 추가하지 않는다.
- 화면 간 역할 차이는 `viewerRole` 같은 명시적 컨텍스트로 전달하고, 기본값 추론에 의존하지 않는다.
- feature presentation provider를 다른 feature에서 직접 import하는 경우는 legacy debt로만 허용한다. 새 코드는 facade 또는 feature-local application provider를 사용한다.

## 7. 문서와 하네스

- 스펙에 영향을 주는 변경은 `docs/specs/` 또는 `.harness/spec/`와 동기화한다.
- cg-harness 7-Phase 작업은 `.harness/README.md`와 `CLAUDE.md`의 흐름을 따른다.
- 사용자-facing 이슈, 스펙, 커밋 메시지는 한글로 작성한다.

## 8. 한국어 응답

- 사용자가 한국어로 요청하면 한국어로 답한다.
- 한국어 문장은 콜론으로 끝내지 않는다.
- 목록이 필요하면 문장을 마침표로 끝낸 뒤 다음 줄에 목록을 둔다.

## 9. 커밋

- 사용자가 커밋을 요청했거나 작업 단위가 명확하고 프로젝트 흐름상 필요한 경우에만 커밋한다.
- 커밋 메시지는 한글 Conventional Commits를 사용한다.
- unrelated 변경을 함께 stage 하지 않는다.
