---
name: ux-consistency-check
description: UX 일관성 점검
user_invocable: true
---

# UX 일관성 점검 스킬

브랜드 디자인 시스템 스펙 (`docs/specs/design/brand_design_system.md`) 기준으로
변경된 코드의 UX 일관성을 자동 검증합니다.

## 트리거

- `/ux-consistency-check` — 직접 호출
- `/auto` 파이프라인의 code-review 단계 후 자동 호출 권장

## 실행 순서

### 1단계: 변경 파일 감지

```bash
git diff --name-only HEAD~1 | grep "\.dart$" | grep -E "(screen|widget|page)"
```

변경된 UI 파일이 없으면 "UI 변경 없음 — 스킵" 출력 후 종료.

### 2단계: 5-Point 자동 점검

변경된 각 파일에 대해 grep 기반으로 점검:

#### CHECK 1: 하드코딩 색상 (CRITICAL)
```
Pattern: Color(0x
Verdict: FAIL if found (AppColors.xxx 사용 필수)
```

#### CHECK 2: 하드코딩 텍스트 스타일 (HIGH)
```
Pattern: TextStyle(fontSize:
Verdict: FAIL if found (AppTypography.xxx 사용 필수)
Exception: .copyWith(fontSize:) 는 허용
```

#### CHECK 3: 매직 넘버 스페이싱 (MEDIUM)
```
Pattern: EdgeInsets.*\b\d+\.?\d*\b (AppSpacing 상수가 아닌 숫자)
Verdict: WARN if found
Exception: 0, 1, 2 허용 (미세 조정)
```

#### CHECK 4: 파일 크기 (MEDIUM)
```
Verdict: WARN if > 500 lines
Verdict: FAIL if > 800 lines
```

#### CHECK 5: 공통 위젯 미사용 (LOW)
```
Pattern: showDialog / showModalBottomSheet 에서 커스텀 위젯 사용
Verdict: INFO — core/widgets/ 확인 권장
```

### 3단계: 결과 출력

```
════════════════════════════════════════════════════
  UX 일관성 점검 (Brand Design System v1.0)
════════════════════════════════════════════════════

  점검 파일: [N]개

  ✅ PASS: [N]개
  ⚠️ WARN: [N]개
  ❌ FAIL: [N]개

  상세:
    [파일명:줄] Color(0xFF...) → AppColors.xxx 사용 필요
    [파일명:줄] TextStyle(fontSize: 16) → AppTypography.bodyLarge 사용

  자동 수정 가능: [N]건
  수동 확인 필요: [N]건

════════════════════════════════════════════════════
```

### 4단계: 자동 수정 (--fix 옵션)

`/ux-consistency-check --fix` 호출 시:
- `Color(0xFF6B5B95)` → `AppColors.primary` 자동 치환
- `Color(0xFFFFFAF5)` → `AppColors.backgroundLight` 자동 치환
- 기타 알려진 색상 매핑 자동 적용

## 참조 문서

- 브랜드 디자인 시스템: `docs/specs/design/brand_design_system.md`
- AppColors 정의: `frontend/lib/core/theme/app_colors.dart`
- AppTypography 정의: `frontend/lib/core/theme/app_typography.dart`
- AppSpacing 정의: `frontend/lib/core/theme/app_spacing.dart`

## /auto 통합

`/auto` 파이프라인에서 code-review 단계 직후에 이 스킬을 호출하면
UI 변경에 대한 브랜드 일관성을 자동으로 검증할 수 있습니다.

```
plan → tdd → code-review → ux-consistency-check → handoff-verify → commit
```
