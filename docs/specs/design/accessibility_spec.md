# 접근성 (Accessibility) 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟡 MEDIUM (출시 후 6개월)
> 관련: [design_master.md](./design_master.md), [ux_guidelines.md](./ux_guidelines.md)

---

## 0. 개요

WCAG 2.1 AA 준수 + iOS VoiceOver / Android TalkBack 사용성. 음악 도구(메트로놈/튜너)도 시각장애 사용자가 사용 가능하도록.

---

## 1. 현황 진단

| 항목 | 상태 |
|------|------|
| `Semantics` 위젯 사용 | 🟡 일부 (자동 inference 의존) |
| 라벨 / hint 일관성 | ❌ 검증 부재 |
| 색 대비 (WCAG AA) | 🟡 design_master.md 명시 — 자동 검증 X |
| 포커스 순서 | 🟡 자동 — 명시 미검증 |
| 터치 영역 (48x48dp 최소) | 🟡 일부 위반 가능 |
| VoiceOver/TalkBack 테스트 | ❌ 없음 |
| 동적 글자 크기 | 🟡 부분 (`MediaQuery.textScaleFactor` 미명시 처리) |

---

## 2. 표준 적합성

### 2.1 WCAG 2.1 AA 핵심 기준

| 기준 | 요구 | Lessonaza 적용 |
|------|------|----------------|
| 1.1.1 Non-text content | 모든 이미지 alt text | `Semantics(label: ...)` |
| 1.3.1 Info & Relationships | 의미 구조 코드로 표현 | 헤딩 위계, 그룹 |
| 1.4.3 Contrast | 본문 4.5:1, 큰 글씨 3:1 | AppColors 토큰 검증 필요 |
| 2.1.1 Keyboard | 키보드 전체 조작 | 외장 키보드 미지원 (Year 2) |
| 2.4.7 Focus visible | 포커스 표시 | 기본 Material focus ring |
| 2.5.5 Target size | 44x44pt 이상 (AAA: 44, AA: 24+spacing) | `AppSpacing.touchTarget` |
| 3.3.2 Labels | 입력 필드 라벨 | 모든 TextField에 `decoration.labelText` |
| 4.1.2 Name/Role/Value | 위젯 의미 노출 | `Semantics` 적극 사용 |

### 2.2 모바일 OS 가이드

- iOS: Apple HIG Accessibility — VoiceOver / Dynamic Type / Reduce Motion
- Android: Material Accessibility — TalkBack / Switch Access / Font Scaling

---

## 3. Flutter 구현 가이드

### 3.1 Semantics 적극 사용

자동 inference가 안 되는 곳:

```dart
// 아이콘 버튼 — label 명시
IconButton(
  icon: Icon(Icons.delete),
  onPressed: onDelete,
  tooltip: AppStrings.delete,  // 자동 Semantics 라벨
)

// 커스텀 위젯 — Semantics wrapper
Semantics(
  label: '오늘 레슨 3건 중 1번째: 김민지 학생, 오후 3시',
  button: true,
  child: GestureDetector(...),
)
```

### 3.2 그룹화 / 헤딩

```dart
Semantics(
  header: true,
  child: Text('오늘의 레슨', style: AppTypography.h2),
)
```

### 3.3 상태 변화 알림

```dart
SemanticsService.announce(
  '레슨이 완료되었습니다',
  TextDirection.ltr,
);
```

### 3.4 메트로놈 접근성

| 기능 | 일반 사용자 | 시각장애 사용자 |
|------|-----------|---------------|
| BPM 조절 | 슬라이더 | `Slider(semanticFormatterCallback)` — "120 BPM" |
| 박자 표시 | 시각 점멸 | + 햅틱 + 음성 알림 옵션 |
| 시작/정지 | 큰 버튼 | "메트로놈 시작, 120 BPM, 4분의 4박자" |

### 3.5 튜너 접근성

- 음정 결과: 시각(색 + 바늘) → 음성 안내 옵션 ("A 음, 정확")
- 진동 피드백: 정확하면 짧은 햅틱

---

## 4. 동적 글자 크기

### 4.1 MediaQuery.textScaleFactor 대응

```dart
// 잘림 방지: 작은 컴포넌트는 textScale 제한
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaleFactor: math.min(1.3, MediaQuery.of(context).textScaleFactor),
  ),
  child: child,
)
```

채팅 말풍선, 일정 셀 등 제한된 공간만 적용. 본문은 무제한 허용.

### 4.2 폰트 크기 토큰

`AppTypography` 모든 사이즈는 `MediaQuery.textScaleFactor` 자동 적용 (Flutter 기본 동작) — 추가 작업 불필요.

---

## 5. 색 대비

### 5.1 자동 검증 (CI)

```bash
# AppColors 토큰 대비 검증 스크립트
flutter test test/accessibility/color_contrast_test.dart
```

`AppColors.text` vs `AppColors.background` → ≥ 4.5:1 확인. 위반 시 빌드 실패.

### 5.2 다크 모드 (Year 2)

현재 라이트 모드만. 다크 모드는 출시 후 사용자 요청 기준 우선순위 결정.

---

## 6. 터치 영역

| 위젯 | 최소 크기 |
|------|----------|
| 버튼 | 48x48dp (Material 권장) |
| 아이콘 버튼 | 48x48dp (`IconButton` 기본) |
| 체크박스/라디오 | 자체 + 8dp padding |
| 리스트 아이템 | 56dp 높이 이상 |

검증:
```bash
grep -rn "InkWell\|GestureDetector" --include="*.dart" features/ | \
  xargs grep -L "minimumSize\|constraints" | head
```

작은 탭 영역 발견 시 `GestureDetector(behavior: HitTestBehavior.opaque)` + padding으로 확장.

---

## 7. 핵심 흐름 a11y 테스트

### 7.1 5개 핵심 흐름

| # | 흐름 | 검증 |
|---|------|------|
| 1 | 회원가입 → 첫 학생 추가 | VoiceOver로 완료 가능 |
| 2 | 레슨 노트 작성 | 텍스트 입력 + 사진 첨부 라벨 인식 |
| 3 | 메트로놈 사용 | BPM 조절 + 시작/정지 음성 인식 |
| 4 | 수강권 발급 | 학생 선택 + 입금 확인 음성 안내 |
| 5 | 결제 (Pro 구독) | 가격/약관/버튼 음성 명확 |

### 7.2 자동화 테스트

```dart
testWidgets('a11y: 학생 추가 흐름 라벨 검증', (tester) async {
  await tester.pumpWidget(MyApp());

  // SemanticsTester로 라벨 트리 검증
  final handle = tester.ensureSemantics();

  await tester.tap(find.bySemanticsLabel('학생 추가하기'));
  await tester.pumpAndSettle();

  expect(find.bySemanticsLabel('학생 이름 입력'), findsOneWidget);
  expect(find.bySemanticsLabel('악기 선택'), findsOneWidget);

  handle.dispose();
});
```

---

## 8. Reduce Motion

`MediaQuery.disableAnimations` 또는 OS 설정 감지:

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
AnimatedSwitcher(
  duration: reduceMotion ? Duration.zero : 300.ms,
  child: ...,
)
```

화면 전환, 페이드, 슬라이드 애니메이션 단축. 메트로놈 점멸은 별도 OFF 토글 (설정 → 접근성).

---

## 9. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `a11ySettingsTitle` | 접근성 |
| `a11yMetronomeVoiceLabel` | 메트로놈 음성 안내 |
| `a11yReduceMotionLabel` | 애니메이션 줄이기 |
| `a11yHighContrastLabel` | 고대비 모드 (Year 2) |

---

## 10. 검증

### 10.1 도구

| 도구 | 용도 |
|------|------|
| Flutter `accessibility_test` | 자동화 트리 검증 |
| iOS Accessibility Inspector | VoiceOver 시뮬레이션 |
| Android TalkBack | 실기 검증 |
| `flutter_a11y_check` 패키지 | 위젯 트리 자동 스캔 |

### 10.2 출시 전 체크리스트

- [ ] AppColors 대비 ≥ 4.5:1 자동 통과
- [ ] 5개 핵심 흐름 VoiceOver 완주 가능
- [ ] 모든 IconButton에 tooltip 있음
- [ ] TextField에 labelText 있음
- [ ] 터치 영역 ≥ 48x48dp
- [ ] 메트로놈 음성 안내 옵션 작동

### 10.3 정기 점검

- 분기 1회 VoiceOver 회귀 테스트
- 신규 화면 추가 시 a11y 체크리스트 PR 게이트

---

## 11. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | WCAG 2.1 AA 목표 (AAA 아님) | 모바일 음악 앱 현실적 합격선 |
| 2026-05-18 | 다크 모드는 Year 2 | 라이트 모드 디자인 완성도 우선 |
| 2026-05-18 | 외장 키보드 지원은 Year 2 | 모바일 사용자 우선 |
| 2026-05-18 | 메트로놈 음성 안내는 옵션 (기본 OFF) | 일반 사용자에게는 노이즈 |

---

## 12. 관련 문서

- [design_master.md](./design_master.md) — 색 토큰 (대비 검증 대상)
- [ux_guidelines.md](./ux_guidelines.md) — 터치 영역 / 인터랙션
- [metronome_guide.md](../../../.claude/rules/metronome-guide.md) — 메트로놈 a11y 구현 위치
