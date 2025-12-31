# Smart Recording Spec (스마트 녹음)

> 작성일: 2025-12-31
> 구현 완료: 2025-12-31

## Overview

녹음 시작/종료 시 무음(약한 소리) 구간을 자동으로 트리밍하는 기능.
사용자가 악기/악보 준비하는 동안의 불필요한 구간을 자동 제거.

## User Story

```
AS A 학생
I WANT TO 녹음 시작 후 준비하는 시간이 자동으로 제거되길
SO THAT 나중에 수동으로 편집하지 않아도 깔끔한 녹음 파일을 얻을 수 있다
```

## Decision Summary

| 항목 | 결정 |
|------|------|
| 처리 방식 | 자동 트리밍 (후처리, 원본 보존) |
| 적용 범위 | 앞뒤 모두 (중간 무음은 유지) |
| 임계값 | 사용자 조절 가능 슬라이더 (기본 40%) |
| 버퍼 | 소리 시작 3초 전, 소리 종료 3초 후 유지 |
| 기능명 | 스마트 녹음 |

---

## Technical Spec

### 1. Amplitude Threshold

```dart
// 임계값 범위
static const double minThreshold = 0.20;  // 최소 20%
static const double maxThreshold = 0.60;  // 최대 60%
static const double defaultThreshold = 0.40;  // 기본 40%

// 버퍼: 소리 전후로 유지할 시간
const buffer = Duration(seconds: 3);
```

### 2. Recording State Machine

```
[녹음 시작]
    ↓
[대기 상태] ← amplitude < threshold
    ↓ amplitude >= threshold
[녹음 중 상태]
    ↓ amplitude < threshold
[종료 대기 상태]
    ↓
[녹음 종료]
    ↓
[자동 트리밍]
    → 앞: (soundStartTime - recordingStartTime) - 3초 버퍼
    → 뒤: (recordingEndTime - soundEndTime) - 3초 버퍼
    ↓
[저장 완료]
```

### 3. 트리밍 계산 로직

```dart
// 시작 트림 계산
if (soundStartTime != null) {
  final silenceAtStart = soundStartTime - recordingStartTime;
  trimmedStart = silenceAtStart - buffer;  // 3초 전까지 유지
  if (trimmedStart < Duration.zero) {
    trimmedStart = Duration.zero;  // 음수면 트림 안 함
  }
}

// 종료 트림 계산
if (soundEndTime != null) {
  final silenceAtEnd = recordingEndTime - soundEndTime;
  trimmedEnd = silenceAtEnd - buffer;  // 3초 후까지 유지
  if (trimmedEnd < Duration.zero) {
    trimmedEnd = Duration.zero;  // 음수면 트림 안 함
  }
}
```

**예시:**
- 녹음 총 20초, 소리 시작 6.6초, 소리 종료 13.4초
- 시작 트림: 6.6 - 3 = 3.6초 트림 (3.6초부터 재생)
- 종료 트림: (20 - 13.4) - 3 = 3.6초 트림 (16.4초에서 종료)
- 결과: 3.6초 ~ 16.4초 재생 (소리 시작 3초 전 ~ 소리 종료 3초 후)

### 4. Data Model

```dart
class SmartRecordingState {
  final bool isEnabled;           // 스마트 녹음 ON/OFF
  final double threshold;         // 임계값 (0.20 ~ 0.60)
  final RecordingPhase phase;     // waiting / recording / ending
  final DateTime? soundStartTime; // 소리 시작 시점
  final DateTime? soundEndTime;   // 소리 종료 시점
  final Duration trimmedStart;    // 트림된 앞부분 길이
  final Duration trimmedEnd;      // 트림된 뒷부분 길이
}

enum RecordingPhase {
  waiting,    // 대기 중 (소리 감지 전)
  recording,  // 녹음 중 (소리 감지됨)
  ending,     // 종료 대기 (소리 끊김)
}
```

### 5. Provider 설정

```dart
// keepAlive: true - 녹음 세션 동안 dispose 방지
@Riverpod(keepAlive: true)
class SmartRecordingNotifier extends _$SmartRecordingNotifier {
  // ...
}
```

### 6. 재생 시 트림 적용

```dart
// AudioPlayerService
Future<bool> load(String filePath) async {
  _trimMetadata = await AudioTrimmerService.instance.readTrimMetadata(filePath);
  // ...
}

Future<void> play() async {
  await _player.play(UrlSource(fileUrl));
  // 트림 시작 지점으로 seek
  if (_trimMetadata?.contentStart > Duration.zero) {
    await _player.seek(_trimMetadata!.contentStart);
  }
}

// 트림 종료 지점에서 자동 정지
_positionSubscription = _player.onPositionChanged.listen((pos) {
  if (pos >= _trimMetadata!.contentEnd) {
    stop();
    onComplete?.call();
  }
});
```

---

## Implementation Status

### Phase 1: Core Logic ✅
- [x] `SmartRecordingState` 모델 추가
- [x] `SmartRecordingProvider` 생성 (keepAlive: true)
- [x] Amplitude 모니터링 로직
- [x] 녹음 시작/종료 시점 트래킹
- [x] 3초 버퍼 적용

### Phase 2: Audio Trimming ✅
- [x] `AudioTrimmerService` 구현
- [x] 원본 파일 백업 (`recording_backups/`)
- [x] `.trim` 메타데이터 파일 생성
- [x] 트림된 오디오 저장

### Phase 3: Playback Integration ✅
- [x] `AudioPlayerService`에서 트림 메타데이터 로드
- [x] 재생 시 트림 시작 지점으로 자동 seek
- [x] 트림 종료 지점에서 자동 정지

### Phase 4: UI ✅
- [x] 스마트 녹음 토글 버튼 ("스마트" 라벨)
- [x] 녹음 화면 상태 표시
- [x] 설정 저장 (Hive)

---

## File Structure

```
lib/
├── models/
│   └── smart_recording.dart              # SmartRecordingState, Settings
├── providers/
│   └── smart_recording/
│       ├── smart_recording_provider.dart # NotIFier (keepAlive)
│       └── smart_recording_provider.g.dart
├── services/
│   └── audio_trimmer_service.dart        # 트리밍 + 메타데이터
└── features/practice/presentation/
    └── screens/
        └── section_detail_screen.dart    # 녹음 UI 통합
```

---

## Edge Cases

| 케이스 | 처리 |
|--------|------|
| 전체가 무음 | 트리밍 없이 저장 |
| 무음 < 3초 | 트림 없음 (버퍼보다 짧음) |
| 녹음 중간에 무음 | 무시 (앞뒤만 트림) |
| 스마트 녹음 OFF | 일반 녹음으로 동작 |

---

## Settings Default

```dart
SmartRecordingSettings.defaults = SmartRecordingSettings(
  smartRecordingEnabled: true,  // 기본 활성화
  trimThreshold: 0.40,          // 40% 임계값
);
```
