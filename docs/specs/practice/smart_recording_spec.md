# Smart Recording Spec (스마트 녹음)

> 작성일: 2025-12-31

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
| 처리 방식 | 자동 트리밍 (후처리, 원본 보존 가능) |
| 적용 범위 | 앞뒤 모두 (중간 무음은 유지) |
| 임계값 | 사용자 조절 가능 슬라이더 (기본 40%) |
| UI | 실시간 상태 표시 + 트림 결과 미리보기 |
| 기능명 | 스마트 녹음 |

---

## Technical Spec

### 1. Amplitude Threshold

```dart
// 임계값 범위
static const double minThreshold = 0.20;  // 최소 20%
static const double maxThreshold = 0.60;  // 최대 60%
static const double defaultThreshold = 0.40;  // 기본 40%

// 최소 무음 지속 시간 (이보다 짧으면 트림 안 함)
static const Duration minSilenceDuration = Duration(seconds: 3);
```

### 2. Recording State Machine

```
[녹음 시작]
    ↓
[대기 상태] ← amplitude < threshold
    ↓ amplitude >= threshold (3초 이상 지속)
[녹음 중 상태]
    ↓ amplitude < threshold (3초 이상 지속)
[종료 대기 상태]
    ↓
[녹음 종료]
    ↓
[자동 트리밍] → 앞: soundStartTime - recordingStartTime
              → 뒤: recordingEndTime - soundEndTime
    ↓
[저장 완료] + "앞 X초 / 뒤 Y초 트림됨 [복구]"
```

### 3. Data Model

```dart
class SmartRecordingState {
  final bool isEnabled;           // 스마트 녹음 ON/OFF
  final double threshold;         // 임계값 (0.20 ~ 0.60)
  final RecordingPhase phase;     // waiting / recording / ending
  final Duration trimmedStart;    // 트림된 앞부분 길이
  final Duration trimmedEnd;      // 트림된 뒷부분 길이
  final String? originalFilePath; // 원본 파일 경로 (복구용)
}

enum RecordingPhase {
  waiting,    // 대기 중 (소리 감지 전)
  recording,  // 녹음 중 (소리 감지됨)
  ending,     // 종료 대기 (소리 끊김)
}
```

### 4. Settings Storage

```dart
// Hive 또는 SharedPreferences
class SmartRecordingSettings {
  bool smartRecordingEnabled = true;
  double trimThreshold = 0.40;
}
```

---

## UI Spec

### 1. 녹음 화면 상태 표시

#### 대기 상태 (Waiting)
```
┌─────────────────────────────┐
│  [파형 애니메이션 - 낮은 진폭]  │
│                             │
│     ⏳ 대기 중...            │
│   연주를 시작하세요          │
│                             │
│        00:05               │
│   (준비 시간 카운트)         │
└─────────────────────────────┘
```

#### 녹음 중 상태 (Recording)
```
┌─────────────────────────────┐
│  [파형 애니메이션 - 활성]     │
│                             │
│     🔴 녹음 중              │
│                             │
│        01:23               │
│   (실제 녹음 시간만 표시)     │
└─────────────────────────────┘
```

### 2. 녹음 완료 후 결과

```
┌─────────────────────────────┐
│  ✅ 녹음 저장됨              │
│                             │
│  총 길이: 1분 45초           │
│  ─────────────────────────  │
│  스마트 녹음 적용:           │
│  • 앞 8초 트림됨            │
│  • 뒤 3초 트림됨            │
│                             │
│  [원본 복구]  [확인]         │
└─────────────────────────────┘
```

### 3. 설정 화면 (토글 + 슬라이더)

```
┌─────────────────────────────┐
│  스마트 녹음                 │
│  ────────────────────────── │
│  [ON ○───────────── OFF]    │
│                             │
│  트림 민감도                 │
│  낮음 ●────────○──── 높음   │
│        [40%]                │
│                             │
│  ℹ️ 녹음 시작/종료 시        │
│     조용한 구간을 자동 제거   │
└─────────────────────────────┘
```

---

## Implementation Plan

### Phase 1: Core Logic
1. `SmartRecordingState` 모델 추가
2. `SmartRecordingProvider` 생성 (설정 관리)
3. Amplitude 모니터링 로직 확장
4. 녹음 시작/종료 시점 트래킹

### Phase 2: Audio Trimming
1. FFmpeg 또는 just_audio를 이용한 트리밍
2. 원본 파일 보존 로직
3. 트림된 파일 저장

### Phase 3: UI Integration
1. 녹음 화면 상태 표시 추가
2. 설정 화면 토글/슬라이더 추가
3. 완료 다이얼로그 트림 정보 표시
4. 원본 복구 기능

### Phase 4: Polish
1. 애니메이션 전환 효과
2. 사용자 온보딩 툴팁
3. 에러 핸들링

---

## Edge Cases

| 케이스 | 처리 |
|--------|------|
| 전체가 무음 | 트리밍 없이 저장 + 경고 표시 |
| 1초 미만 실제 녹음 | 저장 취소 + 안내 메시지 |
| 녹음 중간에 5초+ 무음 | 무시 (앞뒤만 트림) |
| 원본 복구 후 다시 트림 | 새로운 원본으로 트림 |

---

## Settings Default

```dart
// 첫 사용자: 스마트 녹음 활성화, 40% 임계값
SmartRecordingSettings.defaults = SmartRecordingSettings(
  smartRecordingEnabled: true,
  trimThreshold: 0.40,
);
```

## File Structure

```
lib/
├── models/
│   └── smart_recording.dart          # SmartRecordingState
├── providers/
│   └── smart_recording/
│       ├── smart_recording_provider.dart
│       └── smart_recording_provider.g.dart
├── services/
│   └── audio_trimmer_service.dart    # FFmpeg wrapper
└── features/practice/presentation/
    └── widgets/
        └── smart_recording/
            ├── smart_recording_indicator.dart
            └── smart_recording_settings.dart
```
