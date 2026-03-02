# Waveform UI Improvements Specification

> 작성일: 2025-12-31
> 상태: 구현 완료

## Overview

녹음 및 재생 시 파형 UI 개선 스펙. 실시간 진폭 기반 녹음 시각화와 핀치 줌 기반 정밀 구간 설정 기능을 포함한다.

## User Decision Summary

| 항목 | 선택 |
|------|------|
| 녹음 스타일 | 모듈 선택 (웨이브 / 막대 그래프) |
| 줌 방식 | 핀치 줌 (GestureDetector.onScaleUpdate) |
| 마커 조작 | 드래그 핸들 (A-B 마커 직접 드래그) |
| 최소 녹음 시간 | 5초 |

---

## 1. Recording Waveform (녹음 시)

### 1.1 모듈 선택 방식

두 가지 파형 스타일을 모듈로 제공하며, 사용자가 선택 가능:

| 모듈 | 설명 | 용도 |
|------|------|------|
| **WaveWaveform** | 기존 곡선 웨이브 애니메이션 | 시각적 효과 중시 |
| **AmplitudeWaveform** | 실시간 진폭 막대 그래프 | 정확한 입력 확인 |

```dart
enum WaveformStyle {
  wave,       // 기존 곡선 웨이브 (기본값)
  amplitude,  // 실시간 진폭 막대 그래프
}
```

### 1.2 최소 녹음 시간

- **최소 5초** 이상 녹음해야 저장 가능
- 5초 미만 시 저장 버튼 비활성화 + 안내 메시지

```dart
const int minRecordingSeconds = 5;

// 저장 버튼 활성화 조건
bool get canSave => recordingDuration.inSeconds >= minRecordingSeconds;
```

### 1.3 기존 웨이브 모듈 (WaveWaveform)

현재 구현된 `RecordingWaveform` 유지:
- 곡선 사인파 애니메이션
- 장식적/감성적 효과
- AnimationController 기반

### 1.4 신규 막대 그래프 모듈 (AmplitudeWaveform)

```
┌────────────────────────────────────────────────────────┐
│                                                        │
│    ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌                    │
│  ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌                  │
│▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌                │
│▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌              │
│▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌     │  <- 실시간 진폭
│                                                    ●   │  <- 현재 위치
│                                             [REC]      │
└────────────────────────────────────────────────────────┘
```

### 1.3 기술 구현

#### 데이터 소스
```dart
// AudioRecorderService - 이미 존재
Stream<Amplitude> get amplitudeStream =>
    _recorder.onAmplitudeChanged(const Duration(milliseconds: 100));
```

#### 상태 관리
```dart
class RecordingAmplitudeState {
  final List<double> amplitudeHistory;  // 0.0 ~ 1.0 정규화
  final int maxBars;                     // 화면에 표시할 최대 막대 수
  final bool isRecording;
}
```

#### 시각화
```dart
class AmplitudeBarPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color barColor;
  final double barWidth;
  final double barSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    // 오른쪽에서 왼쪽으로 막대 그리기 (최신 데이터가 오른쪽)
    for (int i = 0; i < amplitudes.length; i++) {
      final x = size.width - (i * (barWidth + barSpacing));
      final height = amplitudes[i] * size.height;
      // 막대 그리기
    }
  }
}
```

### 1.4 디자인 스펙

| 속성 | 값 |
|------|-----|
| 막대 너비 | 3dp |
| 막대 간격 | 2dp |
| 막대 색상 | `AppColors.primary` |
| 배경 색상 | `AppColors.surfaceLight` |
| 업데이트 주기 | 100ms |
| 최대 막대 수 | 화면 너비 / (barWidth + barSpacing) |

---

## 2. Playback Waveform (재생 시)

### 2.1 현재 문제점

- 긴 녹음(10분+)에서 전체 파형이 압축됨
- 정밀한 A-B 루프 설정 어려움
- 웨이브폼 터치로 seek만 가능

### 2.2 개선안: 핀치 줌 + 드래그 핸들

```
줌 아웃 상태:
┌────────────────────────────────────────────────────────┐
│∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿│
│                         ●                              │
└────────────────────────────────────────────────────────┘

줌 인 상태 (핀치 줌 후):
┌────────────────────────────────────────────────────────┐
│      ∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿              │
│         [A]────────────────────────[B]                 │  <- 드래그 가능
│                    ●                                   │
└────────────────────────────────────────────────────────┘
```

### 2.3 기술 구현

#### 핀치 줌
```dart
GestureDetector(
  onScaleStart: (details) {
    _baseScale = _currentScale;
  },
  onScaleUpdate: (details) {
    setState(() {
      _currentScale = (_baseScale * details.scale).clamp(1.0, 10.0);
      // 줌 중심점 기준으로 오프셋 조정
      _updateOffset(details.focalPoint);
    });
  },
  child: CustomPaint(
    painter: ZoomableWaveformPainter(
      waveform: _waveformData,
      scale: _currentScale,
      offset: _offset,
    ),
  ),
)
```

#### 드래그 핸들
```dart
class ABMarkerHandle extends StatelessWidget {
  final Duration position;
  final bool isPointA;
  final ValueChanged<Duration> onDrag;

  // 핸들 드래그로 A/B 마커 위치 조정
}
```

### 2.4 제스처 동작

| 제스처 | 동작 |
|--------|------|
| 탭 | 해당 위치로 seek |
| 핀치 아웃 | 줌 인 (최대 10x) |
| 핀치 인 | 줌 아웃 (최소 1x) |
| 수평 드래그 | 줌 상태에서 파형 스크롤 |
| A/B 핸들 드래그 | 마커 위치 조정 |

### 2.5 디자인 스펙

| 속성 | 값 |
|------|-----|
| 최소 줌 | 1.0x (전체 보기) |
| 최대 줌 | 10.0x |
| A-B 구간 색상 | `AppColors.primary.withOpacity(0.3)` |
| 마커 핸들 크기 | 24dp 원형 |
| 마커 핸들 색상 | `AppColors.primary` |

---

## 3. Implementation Status

### Phase 1: 녹음 파형 모듈화 - COMPLETED
1. `waveform/` 폴더 생성
2. `WaveformStyle` enum 및 팩토리 패턴 구현
3. 기존 `RecordingWaveform` → `WaveWaveform`으로 리팩토링
4. `AmplitudeWaveform` 위젯 신규 생성
5. `AudioRecorderService.normalizedAmplitudeStream` 추가
6. `minRecordingSeconds=5`, `maxRecordingSeconds=180` 상수 추가

### Phase 2: 재생 파형 개선 - COMPLETED
1. `ZoomableWaveformProgressBar` 위젯 생성
2. 핀치 줌 (1x ~ 10x) 제스처 구현
3. focal point 기준 줌 및 팬/스크롤 오프셋 관리
4. 미니맵 오버뷰 (1.5x 이상 줌 시 표시)

### Phase 3: A-B 마커 개선 - COMPLETED
1. A-B 마커 드래그 핸들 (20px 터치 영역)
2. 드래그 시 마커 위치 실시간 업데이트
3. `ABLoop` 클래스 별도 모듈 분리
4. `_handleMarkerDrag` 콜백으로 상태 관리 통합

---

## 4. File Structure (Implemented)

```
lib/
├── features/practice/presentation/
│   └── widgets/
│       ├── waveform/                    # 파형 모듈 폴더
│       │   ├── waveform_style.dart      # enum WaveformStyle (wave/amplitude)
│       │   ├── wave_waveform.dart       # 곡선 웨이브 애니메이션
│       │   ├── amplitude_waveform.dart  # 실시간 진폭 막대 그래프
│       │   ├── zoomable_waveform.dart   # 핀치 줌 재생 파형 + A-B 드래그
│       │   └── ab_loop.dart             # ABLoop 클래스 (공용)
│       ├── recording_waveform.dart      # 팩토리 위젯 + exports
│       └── recording_player_sheet.dart  # ZoomableWaveformProgressBar 사용
├── services/
│   └── audio_recorder_service.dart      # normalizedAmplitudeStream 추가
└── models/
    └── recording.dart                   # minRecordingSeconds=5, maxRecordingSeconds=180
```

---

## 5. Copyright Note

본 스펙의 UI 패턴은 저작권 문제가 없음:

- **막대 그래프 파형**: 기능적 UI 요소, 산업 표준
- **핀치 줌**: 제스처 자체는 저작권 보호 대상 아님
- **드래그 핸들**: 일반적 인터랙션 패턴

참고 앱 (동일 패턴 사용):
- iOS Voice Memos, GarageBand, TwistedWave, Ferrite
- Flutter: just_waveform 패키지

---

## References

- [iOS Voice Memos UX Analysis](https://developer.apple.com/design/human-interface-guidelines/)
- [Flutter GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [just_waveform package](https://pub.dev/packages/just_waveform)
