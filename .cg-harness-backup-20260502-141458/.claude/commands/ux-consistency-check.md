# UX 일관성 점검

변경된 UI 코드를 기준으로 멀티 뷰 일관성, 플레이스홀더 UI, CTA 중복을 검사합니다.

## 트리거

코드 작성 후, 특히 다음 상황에서 실행:
- 스케줄/대시보드 등 멀티 뷰 위젯 수정 시
- 새 화면이나 탭 추가 시
- 버튼/FAB/CTA 추가 시

## 점검 항목

### 1. 멀티 뷰 색상 일관성 (교훈 #17)

같은 데이터를 표시하는 모든 뷰에서 색상 규칙이 동일한지 확인:

```bash
# 스케줄 관련 색상 규칙 적용 현황
grep -rn "scheduleMutedBackground\|scheduleMutedAccent" frontend/lib/features/schedule/
grep -rn "InstrumentColors.getColor" frontend/lib/features/schedule/
```

점검 기준:
- 주간/일간/타임라인 뷰가 동일한 past/today/future 색상 규칙을 사용하는가
- `_getDayType()` 또는 동등한 날짜 판단 로직이 모든 뷰에 있는가

### 2. 플레이스홀더 UI 감지 (교훈 #15)

기능이 연결되지 않은 UI 요소를 탐지:

```bash
# 빈 onPressed/onTap
grep -rn "onPressed: () {}" frontend/lib/
grep -rn "onTap: () {}" frontend/lib/
# TODO 콜백
grep -rn "// TODO.*onPressed\|// TODO.*onTap" frontend/lib/
# setState만 하고 실제 동작 없는 패턴
grep -rn "setState.*_is.*= !_is" frontend/lib/ | head -20
```

### 3. CTA 중복 검사 (교훈 #16)

같은 화면으로 이동하는 CTA가 여러 개인지 확인:

```bash
# 동일 라우트로 이동하는 위젯이 같은 부모에 2개 이상 있는지
grep -rn "context.push(AppRoutes" frontend/lib/features/home/
```

점검 기준:
- 하나의 섹션에 같은 AppRoutes 상수를 사용하는 CTA가 2개 이상이면 통합 검토

## 출력 형식

```
UX 일관성 점검 결과:

[멀티 뷰 색상]
  ✓ 주간 뷰: past=muted, today=vivid, future=light
  ✓ 일간 뷰: past=muted, today=vivid, future=light
  ✓ 타임라인: past=muted, today=vivid, future=light

[플레이스홀더 UI]
  ✓ 빈 콜백 없음
  ⚠ schedule_tab.dart:123 — setState만 있고 실제 동작 없음

[CTA 중복]
  ✓ 중복 CTA 없음
```
