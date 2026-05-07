# 메트로놈 시스템 마스터 스펙

> 구현 상태: ✅ 구현 완료 (Phase 1-2)
> 최종 수정: 2026-03-07
> 상태: Phase 2 구현 완료 / Phase 3 예정
> 통합 문서: metronome_system.md, metronome_sound.md, subdivision_ui_design.md, avaudioengine_guide.md

---

## 1. 개요

연습 시스템에 통합된 커스텀 메트로놈. **외부 메트로놈 패키지 사용 절대 금지** — 네이티브 엔진 직접 구현.

### 1.1 핵심 목적

1. **인앱 메트로놈** — 별도 앱 전환 없이 연습 중 사용
2. **녹음 시 메트로놈 분리** — 이어폰으로만 출력, 녹음에 포함 안 됨
3. **BPM 기록 관리** — 선생님/학생 모두 연습 기록 확인

### 1.2 핵심 사용자 스토리

```
선생님: "스즈키6권 라폴리아 1~10 메트로놈:60으로 연습해오세요"
         → 섹션에 목표 BPM 60 설정

학생:   "메트로놈 60으로 4번 연습했어요"
         → BPM 60 사용 기록 4회 저장
         → 녹음 시 메트로놈 ON 상태로 녹음 (이어폰 필수)

선생님: 레슨 시 학생의 연습 기록 확인
         → "BPM 60 x 4회" 표시 확인
```

---

## 2. 아키텍처

### 2.1 레이어 구조

```
┌─────────────────────────────────────────────────────┐
│  MetronomeProvider (Riverpod, @Riverpod keepAlive)  │
│  - MetronomeState 관리                               │
│  - 설정 저장/복원 (MetronomeStorageService)           │
│  - 오디오 인터럽션 처리                               │
└────────────────────┬────────────────────────────────┘
                     │ MetronomeEngineInterface
       ┌─────────────┼─────────────────┐
       ▼             ▼                 ▼
  NativeEngine    NativeEngine    SoLoudEngine
   (iOS)          (Android)       (macOS/Desktop)
   AVAudioEngine  Oboe C++       flutter_soloud FFI
```

### 2.2 플랫폼별 구현

| 플랫폼 | 엔진 | 통신 방식 | 타이밍 정밀도 |
|--------|------|----------|-------------|
| **iOS** | AVAudioEngine + AVAudioPlayerNode | MethodChannel + EventChannel | 샘플 단위 (~0.02ms at 44100Hz) |
| **Android** | Oboe (C++) | MethodChannel + JNI Bridge | 샘플 단위 (LowLatency + Exclusive mode) |
| **macOS** | SoLoud (FFI) + Isolate Timer | Dart Isolate 메시지 | ~0.1ms (Isolate 기반 Stopwatch) |

### 2.3 파일 구조

```
frontend/lib/
├── core/audio/
│   ├── metronome_engine_interface.dart    # 엔진 인터페이스 (추상)
│   ├── native_metronome_engine.dart       # iOS/Android Platform Channel 래퍼
│   ├── soloud_metronome_engine.dart       # macOS/Desktop SoLoud + Isolate 엔진
│   ├── metronome_engine.dart             # (레거시)
│   ├── metronome_package_engine.dart     # (레거시)
│   └── audio_session_manager.dart        # 오디오 세션/인터럽션 관리
│
├── features/practice/
│   ├── domain/entities/
│   │   └── metronome_settings.dart       # 설정 모델 + 모든 enum 정의
│   └── presentation/
│       ├── providers/
│       │   └── metronome_provider.dart   # Riverpod 상태 관리
│       └── widgets/metronome/
│           ├── cat_beat_indicator.dart    # 고양이 비트 인디케이터
│           ├── metronome_controller_bar.dart  # 하단 컨트롤러 바
│           └── metronome_full_screen_modal.dart # 풀스크린 모달

frontend/ios/Runner/
├── MetronomePlugin.swift                  # Flutter Plugin (Method/Event Channel)
└── Audio/
    └── MetronomeAudioEngine.swift         # AVAudioEngine 기반 엔진

frontend/android/app/src/main/
├── cpp/
│   ├── CMakeLists.txt                     # Oboe 빌드 설정
│   ├── MetronomeEngine.h/cpp              # Oboe AudioStreamDataCallback
│   └── jni_bridge.cpp                     # JNI <-> C++ 브릿지
└── kotlin/.../audio/
    └── OboeMetronomeEngine.kt             # Kotlin JNI 래퍼
```

### 2.4 Platform Channel 정의

| 채널 | 이름 | 용도 |
|------|------|------|
| MethodChannel | `app.lessonaza/metronome` | 명령 전송 (init, start, stop, setBpm 등) |
| EventChannel | `app.lessonaza/metronome_events` | 비트/서브디비전 콜백 수신 |

**Method Channel 명령:**

| 메서드 | 인자 | 설명 |
|--------|------|------|
| `init` | `{bpm, beatsPerMeasure, accentPattern, subdivision, soundPattern, strongSound, mediumSound, weakSound}` | 엔진 초기화 |
| `start` | - | 재생 시작 |
| `stop` | - | 재생 중지 |
| `setBpm` | `int` | BPM 변경 |
| `setTimeSignature` | `int` (beatsPerMeasure) | 박자표 변경 |
| `setAccentPattern` | `String` | 악센트 패턴 변경 |
| `setSubdivision` | `int` (divisionsPerBeat) | 서브디비전 변경 |
| `setSoundPattern` | `List<bool>` | 사운드/쉼표 패턴 변경 |
| `setSound` | `{strongSound, mediumSound, weakSound}` | 사운드 파일 변경 |
| `playTapSound` | - | 탭 템포용 단일 사운드 재생 |
| `dispose` | - | 리소스 해제 |

**Event Channel 이벤트:**

| 타입 | 필드 | 설명 |
|------|------|------|
| `beat` | `{type: "beat", beat: int, isAccent: bool}` | 메인 비트 콜백 |
| `subdivision` | `{type: "subdivision", subBeat: int, isMainBeat: bool}` | 서브디비전 콜백 |

---

## 3. 핵심 기능

### 3.1 BPM 제어 & 탭 템포

| 항목 | 값 | 상태 |
|------|-----|------|
| BPM 범위 | 30~208 | ✅ 구현 |
| 기본값 | 60 BPM | ✅ 구현 |
| 조절 방식 | 슬라이더 + +-5 버튼 + 직접 입력 | ✅ 구현 |
| 탭 템포 | 화면 탭으로 BPM 측정 | ✅ 구현 |
| 템포 마킹 | Largo, Andante, Moderato 등 표시 | ✅ 구현 |
| 설정 저장 | MetronomeStorageService로 로컬 저장 | ✅ 구현 |

### 3.2 박자표 (Time Signature)

| 박자표 | beatsPerMeasure | beatUnit | 분류 | 상태 |
|--------|----------------|----------|------|------|
| 2/4 | 2 | 4 | 단순 (Simple) | ✅ |
| 3/4 | 3 | 4 | 단순 | ✅ |
| 4/4 | 4 | 4 | 단순 (기본값) | ✅ |
| 6/8 | 6 | 8 | 복합 (Compound) | ✅ |
| 9/8 | 9 | 8 | 복합 | ✅ |
| 12/8 | 12 | 8 | 복합 | ✅ |

복합 박자의 악센트: 매 3박마다 강세 (1, 4, 7, 10...).

### 3.3 사운드 패턴 (Strong / Weak / Medium / Rest)

**비트 강도 (BeatType):**

| 타입 | 용도 | 사운드 파일 접미사 |
|------|------|-------------------|
| `strong` | 첫 박 (악센트) | `_strong.wav` |
| `medium` | 중간 박 (4/4의 3박) | `_medium.wav` |
| `weak` | 약박 및 서브디비전 | `_weak.wav` |

**악센트 패턴 (AccentPattern):**

| 패턴 | 설명 | 4/4 예시 | 상태 |
|------|------|---------|------|
| `uniform` | 모든 박 동일 (medium) | 중-중-중-중 | ✅ |
| `firstBeatOnly` | 첫박만 강조 | **강**-약-약-약 | ✅ |
| `strongMediumWeak` | 강중약 (기본값) | **강**-약-*중*-약 | ✅ |

### 3.4 백그라운드 재생

- iOS: Audio Session 카테고리 `.playback` + `.mixWithOthers` 옵션
- 전화/알람 인터럽션 시 자동 정지 → 인터럽션 해제 시 오류 메시지 클리어
- `AudioSessionManager.onInterruption` 콜백으로 상태 관리

### 3.5 추가 피드백 옵션

| 기능 | 설명 | 기본값 | 상태 |
|------|------|--------|------|
| 시각 플래시 | 무음 모드에서 화면 깜빡임 | ON | ✅ |
| 진동 피드백 | 비트에 맞춰 햅틱 | OFF | ✅ |

---

## 4. 사운드 디자인

### 4.1 사운드 종류 & 미학

| 사운드 | 폴더명 | 설명 | 상태 |
|--------|--------|------|------|
| 펜 (기본값) | `pen/` | 깔끔한 펜 클릭 | ✅ |
| 드럼 | `drum/` | 하이브리드 드럼 | ✅ |
| 고양이 | `happy_kitten/` | 밝고 통통 튀는 "냐!" 느낌 | ✅ |
| 스틱 | `stick/` | 나무 스틱 | ✅ |
| 우드블록 | `woodblock/` | 나무가 부딪히는 중후한 소리 | ✅ |
| 무음 | - | 시각/진동만 | ✅ |

### 4.2 사운드 파일 규격

**디렉토리 구조:**

```
assets/sounds/metronome/
├── pen/
│   ├── pen_strong.wav
│   ├── pen_medium.wav
│   └── pen_weak.wav
├── drum/
│   ├── hybrid_strong.wav
│   ├── hybrid_medium.wav
│   └── hybrid_weak.wav
├── happy_kitten/
│   ├── happy_kitten_strong.wav
│   ├── happy_kitten_medium.wav
│   └── happy_kitten_weak.wav
├── stick/
│   ├── stick_strong.wav
│   ├── stick_medium.wav
│   └── stick_weak.wav
└── woodblock/
    ├── woodblock_strong.wav
    ├── woodblock_medium.wav
    └── woodblock_weak.wav
```

**오디오 파일 요건:**
- 포맷: WAV (PCM)
- 샘플레이트: 44100Hz
- 길이: ~0.25초 이하 (빠른 템포 대응)
- 특성: 거슬리지 않고 명료, 반복 재생에 적합한 톤 일관성

### 4.3 고양이 사운드 상세

> 좋은 음악을 실컷 듣고 아주 기쁜 고양이 버전.

**사운드 포인트:**
- 밝은 미드~하이 톤 (F2가 높은 "ny" 질감)
- 스쿱 업(상승) + 짧은 홀드 + 가벼운 안정(하강): "냐!" 제스처
- 1박에만 살짝 트윙클(sparkle) 추가 → 박 잡기 쉬움

**튜닝 팁:**
- 더 발랄하게: 1박 벨 +1dB, 업 스쿱 280~320 cents 확장
- 더 차분하게: 트윙클 제거, 스쿱 150~180 cents 축소
- 수업용: 강박만 중앙, 약박 +-8% 팬 분산

---

## 5. 서브디비전 시스템

### 5.1 서브디비전 패턴 전체 목록 (17개)

**기본 패턴 (모든 음 재생):**

| 패턴 | 분할수 | 시각 표현 | 심볼 | 상태 |
|------|--------|----------|------|------|
| quarter (기본) | 1 | `●` | ♩ | ✅ |
| eighth (8분음표) | 2 | `● ●` | ♪♪ | ✅ |
| triplet (셋잇단음) | 3 | `● ● ●` | ³ | ✅ |
| sixteenth (16분음표) | 4 | `● ● ● ●` | ♬ | ✅ |
| quintuplet (5연음) | 5 | `● ● ● ● ●` | ⁵ | ✅ |
| sextuplet (6연음) | 6 | `● ● ● ● ● ●` | ⁶ | ✅ |

**변형 패턴 (쉼표 포함):**

| 패턴 | 분할수 | 시각 표현 | 심볼 | 상태 |
|------|--------|----------|------|------|
| eighthOffbeat (뒷박) | 2 | `○ ●` | ♪ | ✅ |
| tripletFirst (셋잇단-첫음) | 3 | `● ○ ○` | ³¹ | ✅ |
| tripletLast (셋잇단-끝음) | 3 | `○ ○ ●` | ³³ | ✅ |
| tripletSkipFirst (첫음빼고) | 3 | `○ ● ●` | ³⁻ | ✅ |
| sixteenthOffbeat (16분-엇박) | 4 | `○ ● ○ ●` | ♬⁺ | ✅ |
| sixteenthSkipFirst (1빼고) | 4 | `○ ● ● ●` | ♬⁻ | ✅ |
| sixteenthFirstLast (처음끝) | 4 | `● ○ ○ ●` | ♬¹⁴ | ✅ |
| sixteenthMiddle (중간) | 4 | `○ ● ● ○` | ♬²³ | ✅ |
| sextupletFirst (6연음-첫음) | 6 | `● ○ ○ ○ ○ ○` | ⁶¹ | ✅ |
| sextupletAccents (6연음-3+3) | 6 | `● ○ ○ ● ○ ○` | ⁶⁺ | ✅ |

**미구현 특수 패턴 (스펙 설계만 완료):**

| 패턴 | 설명 | 타이밍 | 상태 |
|------|------|--------|------|
| 점8분 (Dotted Eighth) | 긴-짧 (3:1) | 75%-25% | 📋 예정 |
| 스윙 (Swing) | 긴-짧 (2:1) | 66%-33% | 📋 예정 |
| 셔플 (Shuffle) | 3연음 기반 스윙 | 67%-33% | 📋 예정 |
| 3-2 클라베 | 라틴 리듬 | 커스텀 | 📋 예정 |
| 2-3 클라베 | 라틴 리듬 | 커스텀 | 📋 예정 |

> 참고: 스윙/셔플은 불균등 분할이므로 현재 균등 분할 엔진으로는 구현 불가. 별도 타이밍 로직 필요.

### 5.2 soundPattern 메커니즘

`soundPattern: List<bool>` — 각 서브디비전 위치에서 소리 재생(`true`) 또는 쉼표(`false`) 결정.

```dart
// 예: sixteenthOffbeat → [false, true, false, true]
// Beat: ○ ● ○ ●
//       쉼 음 쉼 음

bool shouldPlayAt(int index) => soundPattern[index % soundPattern.length];
```

이 패턴은 네이티브 엔진에도 `setSoundPattern` 메서드로 전달되어 오디오 스케줄링에 반영됨.

### 5.3 UI 설계 & 비트 인디케이터

**서브디비전 선택기 배치 (풀스크린 모달):**

```
┌──────────────────────────────────────┐
│  박자   ┃ 4/4 ┃ 3/4 ┃ 6/8 ┃ 2/4 ┃   │
├──────────────────────────────────────┤
│  서브   ┃  ●  ┃ ●○ ┃●○○┃●○○○┃ [>] │  ← 기본 4개 표시
│         └기본─┘└8분┘└3연┘└16분┘      │
│                                      │
│         ●    ○    ○   (현재 패턴)    │
│         1    +    a                  │
├──────────────────────────────────────┤
│  사운드  Wood  │  Click  │  Beep    │
└──────────────────────────────────────┘
```

**"더보기" 모달 — 전체 패턴 3개 카테고리:**
1. 기본 패턴 (기본, 8분, 셋잇단, 16분, 5연, 6연)
2. 변형 패턴 (쉼표 포함 패턴들)
3. 특수 패턴 (스윙, 셔플, 클라베 — 미구현)

**고양이 발바닥 인디케이터 연동:**

```
기본 (Quarter):     🐾 🐾 🐾 🐾
                    1  2  3  4

셋잇단음 (Triplet): 🐾 · · 🐾 · · 🐾 · · 🐾 · ·
                    1 + a 2 + a 3 + a 4 + a

8분음표 (Eighth):   🐾 · 🐾 · 🐾 · 🐾 ·
                    1 & 2 & 3 & 4 &
```

**사운드/햅틱 피드백:**

| 비트 타입 | 사운드 볼륨 | 햅틱 |
|----------|-----------|------|
| 악센트 (첫 박) | 100% (strong) | Heavy Impact |
| 메인 비트 (●) | 100% (medium/weak) | Medium Impact |
| 서브디비전 (○) | 70% (weak) | Light Impact |

---

## 6. 기술 상세

### 6.1 AVAudioEngine 가이드 (iOS)

#### 6.1.1 Timer 기반의 한계

| 문제 | 원인 | 영향 |
|------|------|------|
| 앱 전환 시 밀림 | iOS가 백그라운드 Timer를 throttle | 박자가 점점 늦어짐 |
| 탭 전환 시 끊김 | Audio Session 재설정 | 일시적 무음 |
| 정확도 한계 | Timer는 ~10-50ms 오차 | 빠른 BPM에서 체감 |

#### 6.1.2 AVAudioEngine의 장점

- **실시간 오디오 스레드**: iOS가 절대 throttle하지 않음
- **샘플 단위 정확도**: ~0.02ms (44100Hz 기준 1 샘플)
- **미래 시점 스케줄링**: `scheduleBuffer(at:)` 로 정확한 시간에 재생

### 6.2 샘플 정확 스케줄링

#### 6.2.1 BPM → 샘플 간격 변환

```swift
let sampleRate: Double = 44100.0
let bpm: Int = 120

let samplesPerBeat = sampleRate * 60.0 / Double(bpm)
// 120 BPM: 44100 * 60 / 120 = 22050 샘플 (0.5초)
// 60 BPM:  44100 * 60 / 60  = 44100 샘플 (1초)

// 서브디비전 포함:
let samplesPerSubdivision = samplesPerBeat / Double(subdivision)
```

#### 6.2.2 이중 버퍼 전략 (Double Buffering)

```
시간축: ──────────────────────────────────────────────►

        [버퍼1 재생]  [버퍼2 재생]  [버퍼3 재생]  [버퍼4 재생]
              ↑           ↑           ↑           ↑
              └──callback─┴──callback─┴──callback─┘
                 (버퍼3 스케줄) (버퍼4 스케줄) (버퍼5 스케줄)

미리 스케줄된 버퍼: 항상 4개 유지 (beatsToScheduleAhead = 4)
```

completionHandler는 버퍼가 **재생 중**일 때 호출됨. 따라서 "예비 버퍼"가 미리 스케줄되어 있어야 끊김 없음.

#### 6.2.3 iOS 엔진 핵심 구현

```swift
class MetronomeAudioEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let beatsToScheduleAhead = 4
    private let syncQueue = DispatchQueue(label: "app.lessonaza.metronome.sync")

    func scheduleBeats() {
        while beatsScheduled < beatsToScheduleAhead && isRunning {
            let beatTime = AVAudioTime(
                sampleTime: AVAudioFramePosition(nextBeatSampleTime),
                atRate: sampleRate
            )
            let buffer = selectBuffer(forBeat: currentBeat, subBeat: currentSubBeat, isAccent: ...)
            if let buffer = buffer {
                player.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
                    self?.syncQueue.async {
                        self?.beatsScheduled -= 1
                        self?.scheduleBeats()  // 재귀적 스케줄링
                    }
                }
                beatsScheduled += 1
            }
            nextBeatSampleTime += samplesPerSubBeat
        }
    }
}
```

#### 6.2.4 Audio Session 설정

```swift
let session = AVAudioSession.sharedInstance()
try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
try session.setPreferredSampleRate(44100.0)
try session.setPreferredIOBufferDuration(0.005)  // 5ms 버퍼
try session.setActive(true)
```

#### 6.2.5 UI 콜백 분리 (MetronomeUICallback)

오디오 스케줄링과 UI 콜백은 **독립적으로** 동작:

- **오디오**: `scheduleBuffer(at:)` — 샘플 정확, 쉼표(rest)는 스케줄하지 않음
- **UI**: `DispatchSourceTimer` — 쉼표 포함 모든 틱에서 애니메이션 콜백 발생

```swift
struct MetronomeTiming {
    let bpm: Int, subdivision: Int, beatsPerMeasure: Int, sampleRate: Double

    var secondsPerBeat: Double { 60.0 / Double(bpm) }
    var secondsPerSubdivision: Double { secondsPerBeat / Double(subdivision) }
    var samplesPerBeat: Double { sampleRate * secondsPerBeat }
    var samplesPerSubdivision: Double { samplesPerBeat / Double(subdivision) }
}
```

### 6.3 Android Oboe 엔진

```
android/app/src/main/
├── cpp/
│   ├── CMakeLists.txt            # Oboe 빌드 설정
│   ├── MetronomeEngine.h/cpp     # Oboe AudioStreamDataCallback
│   └── jni_bridge.cpp            # JNI <-> C++ 브릿지
└── kotlin/.../audio/
    └── OboeMetronomeEngine.kt    # Kotlin JNI 래퍼
```

**Oboe 핵심 특징:**
- `PerformanceMode::LowLatency` — 저지연
- `SharingMode::Exclusive` — 단독 오디오 스트림
- `onAudioReady()` 콜백에서 샘플 단위 비트 스케줄링

**ProGuard 설정 필수:**

```proguard
-keep class com.lessonapp.lesson_app.audio.OboeMetronomeEngine {
    void onBeatCallback(int, boolean);
    void onSubdivisionCallback(int, boolean);
}
-keepclasseswithmembernames class * {
    native <methods>;
}
```

### 6.4 macOS/Desktop SoLoud 엔진

별도 Isolate에서 타이밍 루프를 실행하여 메인 스레드 간섭 방지:

```dart
// Isolate 내부 — Stopwatch 기반 정밀 타이밍
void _timingIsolateEntry(SendPort mainSendPort) {
    Stopwatch stopwatch = Stopwatch()..start();
    // 재귀적 타이머 스케줄링:
    // - 5ms 이상 남음: Timer(remainingUs - 2000) 사용 (효율)
    // - 0.5~5ms 남음: Timer(100us) 사용 (정밀)
    // - 그 이하: Timer.run (즉시) 사용
}
```

**SoLoud 사운드 재생**: `_soloud.play(source)` — 논블로킹, 네이티브 스레드에서 처리.

### 6.5 인터럽트 처리

```swift
// iOS: AVAudioSession.interruptionNotification 감시
// - .began: 재생 정지
// - .ended (.shouldResume): 재개

// Dart: AudioSessionManager.onInterruption 콜백
// - isInterrupted=true: stop() + 오류 메시지 표시
// - isInterrupted=false: 오류 메시지 클리어
```

### 6.6 메모리 관리

- 사운드 버퍼(AVAudioPCMBuffer)는 init 시 1회만 로드
- 사운드 변경 시 기존 소스 dispose 후 새로 로드
- dispose() 시 player.stop() → engine.stop() → 버퍼 nil 처리
- SoLoud: `disposeSource()` 로 각 AudioSource 해제

### 6.7 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 첫 박자 지연 | 사운드 로딩 지연 | `warmUp()` 으로 사전 로딩; `playTapSound()` 로 즉시 첫 박 재생 |
| completionHandler 지연 | 스케줄된 버퍼 부족 | `beatsToScheduleAhead = 4` 유지 |
| 백그라운드에서 중지 | Audio Session 미설정 | `.playback` 카테고리 설정 |
| Android 기기별 지연 차이 | 버퍼 크기 차이 | 기기별 버퍼 크기 조정 |
| 빈 화면 | Provider AutoDispose | `@Riverpod(keepAlive: true)` 사용 |

---

## 7. Enum 정의 (Dart)

> 모든 enum은 `features/practice/domain/entities/metronome_settings.dart`에 정의.

```dart
enum TimeSignature {
  twoFour,   // 2/4
  threeFour, // 3/4
  fourFour,  // 4/4 (기본값)
  sixEight,  // 6/8
  nineEight, // 9/8
  twelveEight; // 12/8
}

enum MetronomeSound {
  pen,         // 기본값
  drum,
  happyKitten,
  stick,
  woodblock,
  silent;
}

enum AccentPattern {
  uniform,           // 모든 박 동일
  firstBeatOnly,     // 첫박만 강조
  strongMediumWeak;  // 강중약 (기본값)
}

enum BeatType {
  strong,  // 첫 박 (악센트)
  medium,  // 중간 박
  weak;    // 약박 및 서브디비전
}

enum Subdivision {
  quarter,              // 1분할 (기본)
  eighth,               // 2분할
  triplet,              // 3분할
  sixteenth,            // 4분할
  quintuplet,           // 5분할
  sextuplet,            // 6분할
  eighthOffbeat,        // 뒷박
  tripletFirst,         // 셋잇단-첫음
  tripletLast,          // 셋잇단-끝음
  tripletSkipFirst,     // 첫음빼고
  sixteenthOffbeat,     // 16분-엇박
  sixteenthSkipFirst,   // 1빼고
  sixteenthFirstLast,   // 처음끝
  sixteenthMiddle,      // 중간
  sextupletFirst,       // 6연음-첫음
  sextupletAccents;     // 6연음-3+3
}
```

---

## 8. 데이터 모델

### 8.1 MetronomeSettings

```dart
class MetronomeSettings {
  final int bpm;                      // 30~208 (기본: 60)
  final TimeSignature timeSignature;  // 기본: 4/4
  final MetronomeSound sound;         // 기본: pen
  final AccentPattern accentPattern;  // 기본: strongMediumWeak
  final Subdivision subdivision;      // 기본: quarter
  final bool visualFlash;             // 기본: true
  final bool vibration;               // 기본: false
}
```

### 8.2 MetronomeState (Provider)

```dart
class MetronomeState {
  final MetronomeSettings settings;
  final bool isPlaying;
  final int currentBeat;          // 1-based 현재 박
  final int currentSubdivision;   // 0-based 서브디비전 인덱스
  final bool isAccent;            // 현재 박이 악센트인지
  final bool isLoading;
  final bool isReady;             // 엔진 초기화 완료 여부
  final String? audioError;       // 오디오 오류 메시지
}
```

### 8.3 연습 기록 연동

```dart
// PracticeRecording 확장
class PracticeRecording {
  final bool usedMetronome;       // 메트로놈 사용 여부
  final int? metronomeBpm;        // 사용한 BPM
  final TimeSignature? timeSignature;
}

// PracticeSection 확장
class PracticeSection {
  final int? targetBpm;           // 선생님 설정 목표 BPM (null = 자유)
  final int? defaultBpm;
  final TimeSignature? timeSignature;
}

// PracticeLog — 녹음 없는 연습 기록
class PracticeLog {
  final String id;
  final String sectionId;
  final DateTime practicedAt;
  final int durationSeconds;
  final bool usedMetronome;
  final int? metronomeBpm;
  final TimeSignature? timeSignature;
}
```

---

## 9. UI 설계

### 9.1 디자인 컨셉: "고양이 메트로놈"

어린이 사용자를 고려한 친근한 비주얼. 고양이 두 마리가 눈을 감았다 뜨는 애니메이션.

### 9.2 하단 컨트롤러 바 (Compact Mode)

```
┌─────────────────────────────────────────────────────────┐
│  😺😸  │  60 BPM  │  [-5] ━━●━━━ [+5]  │  ▶  │  ⚙️     │
│ 고양이   숫자탭     슬라이더+버튼      재생   설정      │
└─────────────────────────────────────────────────────────┘
```

Compact 모드 고양이 깜박임:

| 파라미터 | 값 |
|----------|-----|
| Duration | 100ms |
| 스케일 피크 | 1.15 |
| Curve | easeOut |

### 9.3 풀스크린 모달

```
┌─────────────────────────────────────────────────────┐
│  ✕                     메트로놈                     │
├─────────────────────────────────────────────────────┤
│            🐾  🐾  🐾  🐾 (발바닥 인디케이터)       │
│                      4/4                            │
│                      60 BPM                         │
│      [-5]  ◀━━━━━━━●━━━━━━━▶  [+5]                 │
│              [  ▶  재생  ]                         │
│  박자   4/4 │ 3/4 │ 6/8 │ 2/4                      │
│  서브   ● │ ●○ │ ●○○ │ ●○○○ │ [더보기]             │
│  사운드  펜 │ 드럼 │ 고양이 │ 스틱 │ 우드블록        │
│  악센트  균일 │ 첫박강조 │ 강중약                    │
│  시각효과 [ON]     진동 [OFF]                       │
│       ─── 화면 탭하여 템포 측정 (탭 템포) ───       │
└─────────────────────────────────────────────────────┘
```

### 9.4 발바닥 애니메이션 상세

**드롭 애니메이션 ("툭 올려놓기" 모션):**

| 파라미터 | 값 |
|----------|-----|
| Duration | 140ms |
| Easing | cubic-bezier(0.22, 0.61, 0.36, 1) |

**BPM별 기본 드롭 거리:**

| BPM 범위 | 기본 거리 |
|----------|-----------|
| < 90 | 12px |
| 90~119 | 8px |
| >= 120 | 5px |

**박자별 드롭 배수:**

| 박자 유형 | 배수 | 설명 |
|----------|------|------|
| 강박 (1박) | 3.0x | 가장 큰 움직임 |
| 중간박 (3박, 4/4) | 2.0x | 중간 움직임 |
| 약박 (2, 4박) | 1.4x | 작은 움직임 |

**스케일 애니메이션:**

| 파라미터 | 값 |
|----------|-----|
| Duration | 120ms |
| Curve | easeOut |

| 박자 유형 | 스케일 피크 | 조건 |
|----------|------------|------|
| 강박 | 1.06 | BPM < 120 |
| 중간박 | 1.03 | BPM < 120 |
| 약박 | 1.0 (없음) | - |
| 고속 (>=120 BPM) | 1.0 (없음) | 모든 박자 |

**투명도 (Opacity):**

| 상태 | 투명도 |
|------|--------|
| 비활성 | 0.4 (40%) |
| 활성 - 강박/중간박 | 1.0 (100%) |
| 활성 - 약박 (strongMediumWeak) | 0.85 (85%) |

**고박자(6/8, 8/8 이상) 발바닥 레이아웃:**

- 단일 라인 표시 최대 치(기본): `6`
- `beatCount > 6`일 때는 다음 행으로 자동 래핑한다.
- 행 간 간격: `2px` (`SizedBox(height: 2)`).
- 각 행의 발바닥 너비: `minWidth = max(28, containerWidth / 6)`로 계산하여 너비 과장/축소를 억제한다.
- 표시 안정성을 위해 배경이 긴 박자군(예: 8/8, 9/8, 12/8)은 2줄 이상 표시한다.

---

## 10. 구현 현황

### Phase 1: 기본 메트로놈 (MVP) ✅ 완료

- 인앱 메트로놈 (30~208 BPM, 재생/정지)
- BPM 저장, 사운드 템플릿
- 하단 컨트롤러 바 + 풀스크린 모달
- 녹음 화면 BPM 표시

### Phase 1.5: 고양이 비트 인디케이터 ✅ 완료

- 고양이 발바닥 드롭 애니메이션
- 박자별 강세 표현 (강박/중간박/약박)
- BPM 연동 드롭 거리 자동 조절
- Compact 모드 깜박임 효과

### Phase 2: 확장 기능 ✅ 완료

- 박자 패턴 (2/4, 3/4, 4/4, 6/8, 9/8, 12/8)
- 사운드 옵션 (5종 + 무음)
- 악센트 패턴 (uniform, firstBeatOnly, strongMediumWeak)
- 시각 플래시, 진동 피드백, 템포 마킹
- iOS AVAudioEngine + Android Oboe 네이티브 엔진
- 서브디비전 기본/변형 패턴 17종

### Phase 3: 예정

| 기능 | 설명 | 상태 |
|------|------|------|
| 섹션별 기본 BPM | 선생님이 목표 BPM 설정 | 📋 예정 |
| 점진적 템포 증가 | 연습 중 자동 BPM 증가 | 📋 예정 |
| 특수 서브디비전 | 스윙/셔플/클라베 (불균등 분할) | 📋 예정 |
| BPM 통계 | 주간/월간 BPM 변화 그래프 | 📋 예정 |

---

## 11. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-12-25 | 초안 작성 |
| 2025-12-26 | Phase 1.5 완료: 고양이 비트 인디케이터, 발바닥 애니메이션, 하단 바 깜박임 |
| 2025-12-26 | 사운드 이펙트 스펙 작성 (고양이 사운드 상세) |
| 2026-01-04 | Phase 2 완료: 템포 마킹, 사운드 템플릿, BPM null 표시 |
| 2026-01-12 | 문서 업데이트: 구현 현황 정리 |
| 2026-01-17 | 서브디비전 UI 설계 문서 작성, AVAudioEngine 가이드 작성 |
| 2026-01-19 | Android Oboe 엔진 구현: C++ Oboe 기반 저지연 메트로놈, JNI 브릿지, ProGuard 설정 |
| 2026-03-06 | **마스터 스펙 통합**: 4개 문서(metronome_system, metronome_sound, subdivision_ui_design, avaudioengine_guide)를 단일 문서로 통합. 실제 구현 코드 기준으로 데이터 모델 및 아키텍처 정보 업데이트 |
| 2026-03-07 | Dart enum 정의 섹션 추가, 깨진 링크 수정 (practice_system→practice_master), 섹션 번호 정리 |

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [practice_master.md](../practice/practice_master.md) | 연습 시스템 마스터 스펙 |
| [architecture.md](../../architecture.md) | 전체 아키텍처 가이드 |

## 참고 자료

**Apple 공식:**
- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Hello Metronome Sample Code](https://developer.apple.com/library/archive/samplecode/HelloMetronome/Introduction/Intro.html)

**Android 공식:**
- [Low latency audio (Oboe)](https://developer.android.com/games/sdk/oboe/low-latency-audio)

**Flutter:**
- [Writing custom platform-specific code](https://docs.flutter.dev/platform-integration/platform-channels)
