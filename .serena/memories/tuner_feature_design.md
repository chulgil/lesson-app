# Tuner Feature Design Summary (v0.5 - 게임화 UX 포함)

## Core Concept: Pro Cat Circular Tuner
- Tonal Energy 스타일 + 레슨 앱 고양이 캐릭터
- 음악 전공생도 만족할 수 있는 전문가급 기능

## UI Elements (Updated)
- **Circle**: 12음계 색상 구분 (자연음=파랑, 반음=녹색)
- **Center**: 고양이 + cent 원형 게이지 + cent 수치
- **Animation**: ♪ note flies from cat to target note
- **Perfect**: 연두색 glow effect
- **Bottom Info**: "A4 · 442Hz · +5.2¢" 컴팩트 표시

## 음악 전공생용 기능 (MVP 포함)
| 기능 | 상세 |
|------|------|
| 기준 주파수 | 430-450Hz (0.1Hz 단위), 프리셋: 440/441/442/443Hz |
| 옥타브 표시 | A4, C5 등 하단 정보에 표시 |
| 조옮김 | C, Bb, F, Eb, A (관악기 지원) |
| 이명동음 | 단일(기본)/병기 선택 가능 |

## 색상 시스템
```dart
naturalNote = 0xFFB8D4E3      // 자연음: 연한 파랑
accidentalNote = 0xFFB8E3C8   // 반음: 연한 녹색
centPerfect = 0xFF90EE90      // 정확: 연두색
centFlat = 0xFFFF6B6B         // Flat: 빨강
centSharp = 0xFFFFB347        // Sharp: 주황
```

## Integration
- Metronome ↔ Tuner swipe transition
- Bottom tab navigation + Settings (⚙️)
- Share cat character with metronome

## Cat Feedback
| State | Expression | Speech |
|-------|------------|--------|
| Idle | 😺 Calm | - |
| Detecting | 🐱 Focused | "음..." |
| Flat | 😿 Sad | "더 높여봐옹~ ↑" |
| Sharp | 😾 Surprised | "조금 낮춰봐옹~ ↓" |
| Perfect | 😻 Happy | "완벽해옹!" |

## File Structure
```
lib/core/audio/
├── tuner_engine.dart
└── tuner_engine_interface.dart

lib/features/practice/presentation/
├── providers/tuner_provider.dart
├── screens/practice_tool_screen.dart
└── widgets/tuner/
    ├── circular_note_indicator.dart
    ├── tuner_cat_widget.dart
    ├── cent_gauge_widget.dart
    ├── pitch_display.dart
    └── tuner_settings_sheet.dart
```

## Gamification (v0.5)
- **Perfect/Good/Miss 판정**: 난이도별 (±5/10/15 cent)
- **콤보 시스템**: Perfect 연속 시 콤보 증가, 별 이펙트
- **고양이 애니메이션**: 점프(5콤보), 큰점프(10콤보), 춤(20콤보)
- **접근성**: 단순함 우선, 16pt+ 폰트, 큰 터치 영역

## Reference
Full proposal: docs/proposal/tuner_feature_proposal.md
Gamification UX: docs/proposal/tuner_gamification_ux.md
