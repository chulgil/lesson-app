# UI Action Priority Contract (2026-05-08)

> 상태: Active

## 목표

동일 화면에서 동일 목적의 추가 액션이 헤더와 본문에서 동시에 노출되어 UX 노이즈를 유발하지 않도록 한다.

## 규칙

- `AppBar`에 `Icons.add`(또는 같은 의미의 즉시 추가) 액션이 있는 경우
  동일한 화면 안에서 `FloatingActionButton`, `EmptyStateWidget`, `FilledButton.icon`,
  `OutlinedButton.icon`, `ElevatedButton.icon`에 의해 노출되는 `Icons.add` 기반 추가 CTA가
  중복되어 노출되지 않는다.
- 중복이 필요한 화면은 없다면, 헤더 액션을 우선 추가 입구로 유지한다.
- 헤더 액션이 없는 화면에서만 바디 내 add CTA(빈 상태 액션, FAB 등)를 허용한다.

## 적용 범위

- `lib/features/*/presentation/screens/`
- `+` 중복 여부는 정적 스캔으로 점검한다.

## 검증

- 테스트: `flutter --no-version-check test frontend/test/architecture/header_primary_action_contract_test.dart`
- 실패 시 조치:
  - 헤더가 실제 추가 진입점이면 본문/빈 상태의 중복 액션 제거
  - 본문 액션이 실질적 진입점이면 헤더 액션 삭제 후 본문 우선으로 정합화

## 검토 기준

- `AppBar` + 본문 동시 노출은 다음 우선순위로 금지한다:
  1. `floatingActionButton` + `Icons.add`
  2. `EmptyStateWidget` + `actionLabel` + `actionIcon: Icons.add` + `onAction`
  3. `FilledButton.icon` + `Icons.add` + `onPressed`
  4. `OutlinedButton.icon` + `Icons.add` + `onPressed`
  5. `ElevatedButton.icon` + `Icons.add` + `onPressed`
