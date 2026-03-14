# 메트로놈 개발 지침

> ⚠️ 반드시 커스텀 `MetronomePlugin`만 사용 (외부 패키지 금지)

| 레이어 | 파일 |
|--------|------|
| Provider | `features/practice/presentation/providers/metronome_provider.dart` |
| Dart Engine | `core/audio/native_metronome_engine.dart` (macOS: `soloud_metronome_engine.dart`) |
| iOS Plugin | `ios/Runner/MetronomePlugin.swift` |
| iOS Engine | `ios/Runner/Audio/MetronomeAudioEngine.swift` |

핵심: `soundPattern: [Bool]` 배열로 쉼표(rest) 패턴 지원, `AppDelegate`에 플러그인 등록 필수
