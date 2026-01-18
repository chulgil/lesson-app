# AVAudioEngine 기반 메트로놈 구현 가이드

> 마지막 업데이트: 2025-01-17
> 관련 이슈: #30

## 개요

이 문서는 iOS AVAudioEngine과 Android AudioTrack을 사용한 고정밀 메트로놈 구현 방법을 설명합니다.

---

## 1. 왜 AVAudioEngine인가?

### 1.1 Timer 기반의 한계

```
현재 방식: Timer.periodic(60ms) → play() → 타이밍 불안정
```

| 문제 | 원인 | 영향 |
|------|------|------|
| 앱 전환 시 밀림 | iOS가 백그라운드 Timer를 throttle | 박자가 점점 늦어짐 |
| 탭 전환 시 끊김 | Audio Session 재설정 | 일시적 무음 |
| 정확도 한계 | Timer는 ~10-50ms 오차 | 빠른 BPM에서 체감 |

### 1.2 AVAudioEngine의 장점

```
AVAudioEngine: scheduleBuffer(at: exactSampleTime) → 샘플 단위 정확
```

- **실시간 오디오 스레드**: iOS가 절대 throttle하지 않음
- **샘플 단위 정확도**: ~0.02ms (44100Hz 기준 1 샘플)
- **미래 시점 스케줄링**: `scheduleBuffer:atTime:`으로 정확한 시간에 재생

> "When dealing with audio, where precise timing is vital, you need to lean in to the real-time support provided by the audio subsystem."
> — Apple Developer Forums

---

## 2. 핵심 개념: scheduleBuffer 이중 버퍼 전략

### 2.1 기본 원리

AVAudioEngine의 `scheduleBuffer(at:)` 메서드는 **미래의 정확한 샘플 시간**에 오디오를 재생할 수 있습니다.

```swift
// 특정 샘플 시간에 버퍼 재생 예약
let beatTime = AVAudioTime(
    sampleTime: AVAudioFramePosition(nextBeatSampleTime),
    atRate: sampleRate  // 44100.0
)
player.scheduleBuffer(clickBuffer, at: beatTime, options: [])
```

### 2.2 이중 버퍼 전략 (Double Buffering)

**핵심 인사이트**: completionHandler는 버퍼가 **재생 중**일 때 호출됩니다. 따라서 "예비 버퍼"가 이미 스케줄되어 있어야 끊김이 없습니다.

```
시간축: ──────────────────────────────────────────────►

        [버퍼1 재생]  [버퍼2 재생]  [버퍼3 재생]  [버퍼4 재생]
              ↑           ↑           ↑           ↑
              │           │           │           │
              └──callback─┴──callback─┴──callback─┘
                 (버퍼3 스케줄) (버퍼4 스케줄) (버퍼5 스케줄)

미리 스케줄된 버퍼: 항상 2-4개 유지
```

### 2.3 구현 패턴

```swift
class MetronomeAudioEngine {
    private let beatsToScheduleAhead = 4  // 미리 스케줄할 박자 수
    private var beatsScheduled = 0
    private var nextBeatSampleTime: Double = 0

    private let syncQueue = DispatchQueue(label: "metronome.sync")

    func scheduleBeats() {
        // 항상 beatsToScheduleAhead개의 박자가 스케줄되도록 유지
        while beatsScheduled < beatsToScheduleAhead {
            let beatTime = AVAudioTime(
                sampleTime: AVAudioFramePosition(nextBeatSampleTime),
                atRate: sampleRate
            )

            let buffer = selectBufferForBeat(currentBeat)

            // completionHandler: 버퍼 재생이 시작되면 호출
            player.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
                self?.syncQueue.async {
                    self?.beatsScheduled -= 1
                    self?.scheduleBeats()  // 재귀적으로 다음 박자 스케줄
                }
            }

            // 다음 박자 시간 계산 (샘플 단위)
            let samplesPerBeat = sampleRate * 60.0 / Double(bpm)
            nextBeatSampleTime += samplesPerBeat
            beatsScheduled += 1
            currentBeat = (currentBeat % beatsPerMeasure) + 1

            // Flutter로 이벤트 전송
            sendBeatEvent(currentBeat, isAccent: currentBeat == 1)
        }
    }
}
```

---

## 3. 샘플 타임 계산

### 3.1 BPM → 샘플 간격 변환

```swift
let sampleRate: Double = 44100.0  // Hz
let bpm: Int = 120

// 1박자당 샘플 수
let samplesPerBeat = sampleRate * 60.0 / Double(bpm)
// 120 BPM: 44100 * 60 / 120 = 22050 샘플 (0.5초)
// 60 BPM:  44100 * 60 / 60  = 44100 샘플 (1초)
// 200 BPM: 44100 * 60 / 200 = 13230 샘플 (0.3초)
```

### 3.2 AVAudioTime 구조

```swift
// 샘플 시간 기반 (권장)
let time = AVAudioTime(
    sampleTime: AVAudioFramePosition(nextBeatSampleTime),
    atRate: sampleRate
)

// 또는 호스트 시간 기반
let hostTime = mach_absolute_time()
let time = AVAudioTime(hostTime: hostTime + delayInHostTicks)
```

### 3.3 BPM 변경 시 처리

```swift
func setBpm(_ newBpm: Int) {
    syncQueue.async { [weak self] in
        guard let self = self else { return }
        self.bpm = newBpm
        // 이미 스케줄된 박자는 그대로 재생
        // 다음 scheduleBeats() 호출부터 새 간격 적용
    }
}
```

---

## 4. iOS 구현 상세

### 4.1 Audio Session 설정

```swift
func configureAudioSession() throws {
    let session = AVAudioSession.sharedInstance()

    // 카테고리: 재생 (백그라운드 허용)
    try session.setCategory(
        .playback,
        mode: .default,
        options: [.mixWithOthers]  // 다른 앱 오디오와 믹싱
    )

    // 샘플레이트 및 버퍼 크기 최적화
    try session.setPreferredSampleRate(44100.0)
    try session.setPreferredIOBufferDuration(0.005)  // 5ms 버퍼

    try session.setActive(true)
}
```

### 4.2 AVAudioEngine 초기화

```swift
private let engine = AVAudioEngine()
private let player = AVAudioPlayerNode()

func setupEngine() throws {
    // 플레이어 노드 연결
    engine.attach(player)

    // 출력 형식 가져오기
    let format = engine.outputNode.outputFormat(forBus: 0)
    sampleRate = format.sampleRate

    // 플레이어 → 메인 믹서 연결
    engine.connect(player, to: engine.mainMixerNode, format: format)

    // 엔진 시작
    try engine.start()
}
```

### 4.3 사운드 로딩

```swift
func loadSound(named name: String) throws -> AVAudioPCMBuffer {
    // Flutter assets에서 로드
    guard let url = Bundle.main.url(
        forResource: "Frameworks/App.framework/flutter_assets/assets/sounds/metronome/\(name)",
        withExtension: "wav"
    ) else {
        throw MetronomeError.soundNotFound
    }

    let file = try AVAudioFile(forReading: url)
    let format = file.processingFormat
    let frameCount = AVAudioFrameCount(file.length)

    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
        throw MetronomeError.bufferCreationFailed
    }

    try file.read(into: buffer)
    return buffer
}
```

### 4.4 인터럽트 처리

```swift
// 전화, 알람 등으로 인터럽트 시
NotificationCenter.default.addObserver(
    forName: AVAudioSession.interruptionNotification,
    object: nil,
    queue: .main
) { [weak self] notification in
    guard let info = notification.userInfo,
          let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
        return
    }

    switch type {
    case .began:
        self?.pause()
    case .ended:
        if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
           AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
            self?.resume()
        }
    @unknown default:
        break
    }
}
```

---

## 5. Android 구현 상세

### 5.1 AudioTrack 초기화

```kotlin
private val sampleRate = 44100
private lateinit var audioTrack: AudioTrack

fun setupAudioTrack() {
    audioTrack = AudioTrack.Builder()
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
        )
        .setAudioFormat(
            AudioFormat.Builder()
                .setSampleRate(sampleRate)
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                .build()
        )
        .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
        .setBufferSizeInFrames(sampleRate / 10)  // 100ms 버퍼
        .setTransferMode(AudioTrack.MODE_STREAM)
        .build()
}
```

### 5.2 PCM 프레임 카운팅

```kotlin
private var totalFramesWritten: Long = 0
private var framesPerBeat: Int = 0

fun audioLoop() {
    framesPerBeat = sampleRate * 60 / bpm

    while (isRunning) {
        // 클릭 사운드 쓰기
        audioTrack.write(clickBuffer, 0, clickBuffer.size)
        totalFramesWritten += clickBuffer.size / 2  // stereo

        // 박자 이벤트 전송
        currentBeat = (currentBeat % beatsPerMeasure) + 1
        sendBeatEvent(currentBeat, currentBeat == 1)

        // 무음으로 간격 채우기
        val silenceFrames = framesPerBeat - clickBuffer.size / 2
        val silenceBuffer = ShortArray(silenceFrames * 2)
        audioTrack.write(silenceBuffer, 0, silenceBuffer.size)
        totalFramesWritten += silenceFrames
    }
}
```

### 5.3 Flutter Assets 로딩

```kotlin
fun loadSound(assetPath: String): ShortArray {
    val assetManager = context.assets
    val inputStream = assetManager.open("flutter_assets/$assetPath")

    // WAV 헤더 파싱 및 PCM 데이터 추출
    val header = ByteArray(44)
    inputStream.read(header)

    val dataSize = inputStream.available()
    val data = ByteArray(dataSize)
    inputStream.read(data)

    // ByteArray → ShortArray 변환
    val shortBuffer = ShortArray(dataSize / 2)
    ByteBuffer.wrap(data)
        .order(ByteOrder.LITTLE_ENDIAN)
        .asShortBuffer()
        .get(shortBuffer)

    return shortBuffer
}
```

---

## 6. Flutter Platform Channel

### 6.1 MethodChannel 정의

```dart
class NativeMetronomeEngine implements MetronomeEngineInterface {
  static const _methodChannel = MethodChannel('com.lessonapp/metronome');
  static const _eventChannel = EventChannel('com.lessonapp/metronome_events');

  @override
  Future<void> init() async {
    await _methodChannel.invokeMethod('init', {
      'bpm': settings.bpm,
      'beatsPerMeasure': settings.timeSignature.beatsPerMeasure,
      'accentPattern': settings.accentPattern.name,
      'strongSound': settings.sound.getAssetPath(BeatType.strong),
      'mediumSound': settings.sound.getAssetPath(BeatType.medium),
      'weakSound': settings.sound.getAssetPath(BeatType.weak),
    });
  }

  @override
  Future<void> start() async {
    await _methodChannel.invokeMethod('start');
  }

  @override
  Future<void> stop() async {
    await _methodChannel.invokeMethod('stop');
  }

  @override
  Future<void> setBpm(int bpm) async {
    await _methodChannel.invokeMethod('setBpm', bpm);
  }
}
```

### 6.2 EventChannel 정의

```dart
StreamSubscription? _beatSubscription;

void _setupEventChannel() {
  _beatSubscription = _eventChannel.receiveBroadcastStream().listen(
    (event) {
      final data = Map<String, dynamic>.from(event);
      final beat = data['beat'] as int;
      final isAccent = data['isAccent'] as bool;
      onBeat?.call(beat, isAccent);
    },
    onError: (error) {
      debugPrint('Metronome event error: $error');
    },
  );
}
```

---

## 7. 트러블슈팅

### 7.1 일반적인 문제

| 문제 | 원인 | 해결 |
|------|------|------|
| 첫 박자 지연 | 사운드 로딩 지연 | `warmUp()`으로 사전 로딩 |
| completionHandler 지연 | 이미 스케줄된 버퍼 부족 | `beatsToScheduleAhead` 증가 |
| 백그라운드에서 중지 | Audio Session 미설정 | `.playback` 카테고리 설정 |
| Android 기기별 지연 차이 | 버퍼 크기 차이 | 기기별 버퍼 크기 조정 |

### 7.2 디버깅 팁

```swift
// 타이밍 로그
let actualTime = player.lastRenderTime?.sampleTime ?? 0
let scheduledTime = beatTime.sampleTime
let drift = Double(actualTime - scheduledTime) / sampleRate * 1000
print("Beat \(currentBeat): drift = \(drift)ms")
```

### 7.3 메모리 관리

```swift
// 사운드 버퍼는 한 번만 로드
private var strongBuffer: AVAudioPCMBuffer?
private var mediumBuffer: AVAudioPCMBuffer?
private var weakBuffer: AVAudioPCMBuffer?

// dispose 시 해제
func dispose() {
    player.stop()
    engine.stop()
    strongBuffer = nil
    mediumBuffer = nil
    weakBuffer = nil
}
```

---

## 8. 참고 자료

### Apple 공식
- [AVAudioEngine Documentation](https://developer.apple.com/documentation/avfaudio/avaudioengine)
- [Hello Metronome Sample Code](https://developer.apple.com/library/archive/samplecode/HelloMetronome/Introduction/Intro.html)
- [AVAudioPlayerNode](https://developer.apple.com/documentation/avfaudio/avaudioplayernode)

### Android 공식
- [Low latency audio (Oboe)](https://developer.android.com/games/sdk/oboe/low-latency-audio)
- [AudioTrack Documentation](https://developer.android.com/reference/android/media/AudioTrack)

### 커뮤니티
- [Metronome-using-AVAudioEngine (GitHub)](https://github.com/Alexander-Nagel/Metronome-using-AVAudioEngine)
- [Making Sense of Time in AVAudioPlayerNode](https://medium.com/@mehsamadi/making-sense-of-time-in-avaudioplayernode-475853f84eb6)

### Flutter
- [Writing custom platform-specific code](https://docs.flutter.dev/platform-integration/platform-channels)
