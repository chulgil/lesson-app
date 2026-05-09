# 이슈: G4 i18n 1차 기반 구축

**우선순위:** 높음  
**상태:** 완료

## 배경

`/Users/cglee/Dev/Personal/MyBrain/10 Projects/레슨앱/16-기획갭-2차진단.md`의 G4는 i18n이 인프라 수준에서도 미착수라고 진단한다.

## 대상

- Flutter ARB 기반 l10n 설정을 추가한다.
- 한국어/영어 ARB 리소스 파일을 생성한다.
- 앱의 `MaterialApp`에 generated `AppLocalizations` delegate를 연결한다.
- 문서에서 지적한 학생/학부모 하단 탭 라벨 하드코딩을 `AppStrings`로 이관한다.
- i18n 인프라와 하드코딩 회귀를 architecture test로 검증한다.

## 완료 조건

- `frontend/l10n.yaml`이 존재해야 한다.
- `frontend/lib/core/l10n/arb/app_ko.arb`, `app_en.arb`가 존재해야 한다.
- generated `AppLocalizations`가 앱 delegate에 연결되어야 한다.
- 학생/학부모 하단 탭 라벨은 `AppStrings`를 사용해야 한다.
- `flutter gen-l10n`, `flutter analyze`, i18n architecture test가 통과해야 한다.

## 종료 요약

- `frontend/l10n.yaml`과 한국어/영어 ARB 리소스를 추가했다.
- generated `AppLocalizations`를 `MaterialApp` delegate에 연결했다.
- 학생/학부모 하단 탭 라벨을 `AppStrings`로 이관했다.
- `i18n_contract_test.dart`를 추가해 l10n 인프라와 하단 탭 하드코딩 회귀를 검사한다.
- `flutter --no-version-check gen-l10n`, i18n architecture test, `flutter --no-version-check analyze`를 통과했다.
