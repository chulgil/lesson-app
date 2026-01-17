# Central Practice Button Feature

> Implemented: 2025-01-17

## Summary

하단 네비게이션 바 중앙에 돌출된 메트로놈/튜너 버튼 추가 (바나프레소 앱 UX 패턴 참고)

## Key Files

### New Files
- `lib/core/widgets/practice_center_button.dart` - 중앙 버튼 위젯
- `docs/specs/practice/central_practice_button.md` - 스펙 문서

### Modified Files
- `lib/features/student_home/presentation/screens/student_home_screen.dart` - 커스텀 네비게이션 바
- `lib/core/theme/app_colors.dart` - successDark 색상 추가

## Features

### User Interaction
- **탭**: 메트로놈 즉시 시작/정지
- **길게 누르기**: PracticeToolsModal 열기 (튜너/메트로놈 설정)

### Visual Design
- 커스텀 튜닝포크+메트로놈 조합 아이콘 (CustomPainter)
- 64x64dp 원형 버튼, -16dp 상단 돌출
- Primary gradient (기본), Success gradient (재생 중)
- BPM 동기화 펄스 애니메이션

## Implementation Notes

- BottomNavigationBar 대신 커스텀 Row 레이아웃 사용
- Stack으로 중앙 버튼 오버레이
- ConsumerStatefulWidget + SingleTickerProviderStateMixin for animation
