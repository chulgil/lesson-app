# 이슈: 팝업 표면 투명창 회귀 방지

**우선순위:** 높음  
**상태:** 완료

## 대상

- 처리중/로딩 팝업이 투명 route 위 spinner만 표시되어 Notebook × Score 표면이 사라지는 문제를 차단한다.
- 커스텀 `Dialog`가 Material 기본 배경/틴트에 의존하지 않도록 `AppColors.paper` 표면을 명시한다.
- 같은 유형의 팝업 회귀를 아키텍처 테스트로 검증한다.

## 실행 계획

1. 프론트 팝업/다이얼로그 호출부 전수 스캔
2. 커스텀 다이얼로그 표면 계약 보정
3. Notebook 디자인 스펙과 하네스 계약 업데이트
4. `notebook_design_contract_test.dart`에 회귀 테스트 추가
5. `flutter analyze`와 관련 아키텍처 테스트 실행

## 완료 조건

- 투명 로딩 팝업 패턴이 production UI에 남아 있지 않아야 한다.
- 커스텀 `Dialog`는 paper 배경, 투명 surface tint, 각진 shape를 명시해야 한다.
- 관련 테스트가 통과해야 한다.

## 종료 요약

- 커스텀 `Dialog` 2곳에 Notebook paper 표면 계약을 명시했다.
- `notebook_design_contract_test.dart`에 투명 로딩 팝업과 커스텀 Dialog 표면 회귀 테스트를 추가했다.
- 스펙/하네스에 로딩 팝업 및 커스텀 Dialog 표면 규칙을 추가했다.
- `flutter --no-version-check analyze` 및 관련 테스트 통과를 확인했다.
