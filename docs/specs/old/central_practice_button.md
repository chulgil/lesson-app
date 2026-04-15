# Central Practice Button Specification

> Created: 2025-01-17

## Overview

학생 홈 화면의 하단 네비게이션 바에 중앙 돌출 버튼(Central Prominent Button)을 추가하여
메트로놈/튜너에 빠르게 접근할 수 있게 합니다.

### Design Inspiration

바나프레소(Banapresso) 커피 주문 앱의 중앙 "주문" 버튼 패턴을 참고합니다:
- 하단 네비게이션 바 중앙에 위치
- 다른 탭보다 크고 눈에 띄는 디자인
- Primary action으로서 시각적 강조

## User Interaction

### Touch (Tap)
- **Action**: 튜너 탭으로 모달 열기
- **Behavior**:
  1. PracticeToolsModal 열기 (initialTab: 1 = Tuner)
  2. 튜너 즉시 사용 가능

### Long Press
- **Action**: 메트로놈 탭으로 모달 열기
- **Behavior**:
  1. PracticeToolsModal 열기 (initialTab: 0 = Metronome)
  2. 메트로놈 즉시 사용 가능

## Icon Design

### Combination Icon: 튜닝포크 + 메트로놈
```
     ┃
    ╱ ╲    ← 튜닝포크 (fork prongs)
   ┃   ┃
   ┗━━━┛   ← 손잡이 겸 진자(pendulum)
     │
     ●     ← 추(weight)
```

### Implementation
- Custom Icon using Flutter's `CustomPainter`
- SVG asset 대신 코드로 구현 (색상 테마 대응)
- Size: 32x32 logical pixels

## Layout

```
┌──────────────────────────────────────────┐
│                                          │
│             Main Content                 │
│                                          │
├────────┬────────┬────────┬────────┬──────┤
│  홈    │  레슨  │   🎵   │  연습  │ 프로필│
│        │        │  ◯◯   │        │      │
│        │        │ (raised)│        │      │
└────────┴────────┴────────┴────────┴──────┘
```

### Dimensions
- Navigation bar height: 56dp (standard)
- Center button: 64x64dp (raised, circular)
- Button elevation: 8dp
- Button offset from bar: -16dp (raised above)

## Visual Design

### Default State
- Background: Primary gradient (`AppColors.primary` → `AppColors.primaryDark`)
- Icon: White (튜닝포크 + 메트로놈 조합)
- Shadow: Soft drop shadow (0, 4, 8, 0.3 primary color)

### Pressed State
- Scale: 0.95 (subtle press feedback)
- AnimatedScale for smooth transition

## File Changes

### Modified Files
1. `lib/features/student_home/presentation/screens/student_home_screen.dart`
   - Remove `floatingActionButton`
   - Modify `_buildBottomNavigation()` with center button

### New Files
1. `lib/core/widgets/practice_center_button.dart`
   - `PracticeCenterButton` widget
   - Custom icon painter

## State Management

### Provider Integration
```dart
// Quick metronome toggle
ref.read(metronomeProvider.notifier).toggle();

// Check metronome state for icon animation
ref.watch(metronomeProvider.select((s) => s.isPlaying));
```

## Accessibility

- Semantic label: "메트로놈/튜너 열기"
- Tooltip on long hover: "길게 누르면 설정"
- Contrast ratio: 4.5:1 minimum

## Implementation Phases

### Phase 1: Basic Button (Current)
- Center button with static icon
- Tap → open PracticeToolsModal
- No long press yet

### Phase 2: Quick Start
- Tap → start metronome immediately
- Long press → open PracticeToolsModal
- Active state animation

### Phase 3: Custom Icon
- Tuning fork + metronome combination icon
- Animated icon when metronome active

## Related Files

- `lib/features/practice/presentation/widgets/practice_tools_modal.dart`
- `lib/features/practice/presentation/providers/metronome_provider.dart`
- `lib/core/theme/app_colors.dart`
