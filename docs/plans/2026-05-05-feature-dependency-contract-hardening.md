# Feature Dependency Contract Hardening

GitHub issue: https://github.com/chulgil/lesson-app/issues/268

## Goal

확장성 높은 Flutter 아키텍처 기준에서 남아 있는 가장 큰 위험인 feature 간 presentation provider 직접 의존을 더 이상 늘어나지 않게 잠근다.

## Scope

- `flutter_architecture_contract.md`에 feature 간 public API/facade 의존 규칙을 보강한다.
- 현재 cross-feature presentation provider import/export를 명시적인 legacy baseline으로 기록한다.
- 새 cross-feature presentation provider 의존이 추가되면 architecture test가 실패하게 한다.
- notification provider와 backend 계획 문서 등 현재 다른 작업자가 수정 중인 파일은 건드리지 않는다.

## Verification

- `cd frontend && flutter test test/architecture`
- `cd frontend && flutter analyze`
- domain/data의 presentation provider import 금지 검사는 기존 계약 테스트로 유지한다.
