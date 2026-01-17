# Recording Player UI Specification

> 작성일: 2025-12-30
> 최종 수정: 2026-01-12
> 상태: 구현 완료

## Overview

녹음 재생을 위한 바텀시트 플레이어 UI 스펙. iOS Voice Memos 스타일의 웨이브폼 시각화와 고급 재생 기능을 포함한다.

## User Decision Summary

| 항목 | 선택 |
|------|------|
| UI 스타일 | Option B: 웨이브폼 + 컨트롤 |
| 추가 기능 | 재생 속도 조절, 구간 반복 (A-B Loop) |
| 파일 저장 | UUID + DB 메타데이터 |

---

## 1. UI Design

### 1.1 바텀시트 레이아웃

```
┌─────────────────────────────────────────────────────┐
│                    ─────                            │  <- Drag handle
│                                                     │
│  ∿∿∿∿∿∿∿∿∿∿∿∿●∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿  │  <- Waveform (터치로 seek)
│                                                     │
│      00:45                              02:30       │  <- Current / Total time
│                                                     │
│   [A][B]  ×1.0 ▼                          ▶/⏸      │  <- Controls (한 줄)
│                                                     │
└─────────────────────────────────────────────────────┘
```

**컨트롤 배치:**
- 왼쪽: A-B Loop 버튼 + 재생 속도
- 오른쪽: 재생/정지 버튼

### 1.2 컴포넌트 상세

#### Header (Drag Handle)
- 너비: 40dp, 높이: 4dp
- 색상: `AppColors.textSecondaryLight`
- 상단 마진: 12dp

#### Waveform Area
- 높이: 80dp
- 배경: `AppColors.surfaceLight`
- 파형 색상 (재생 전): `AppColors.textSecondaryLight`
- 파형 색상 (재생 후): `AppColors.primary`
- 현재 위치 인디케이터: 2dp 흰색 세로선 + 원형 노브
- 터치 제스처: 탭/드래그로 seek 가능

#### Time Display
- 폰트: `AppTypography.bodyMedium`
- 좌측: 현재 재생 시간
- 우측: 전체 녹음 시간
- 색상: `AppColors.textPrimaryLight`

#### Control Buttons (한 줄 배치)
- **재생/정지**: 56dp 원형, `AppColors.primary`, 오른쪽 정렬
- **A-B Loop**: 왼쪽 정렬, A/B 버튼 36dp 사각형
- **Speed**: A-B Loop 옆, 드롭다운 버튼

#### A-B Loop Control
- A 버튼: 시작점 설정 (누르면 현재 위치 기록)
- B 버튼: 종료점 설정 (누르면 현재 위치 기록)
- 구간 표시: 웨이브폼에 하이라이트로 표시
- 활성 시: 구간만 반복 재생
- 해제: A 또는 B 길게 눌러 해제

#### Speed Control
- 드롭다운/버튼 토글
- 옵션: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x
- 기본값: 1.0x
- 선택된 속도 표시: `×1.0` 형식

### 1.3 색상 정의

```dart
// Player specific colors
static const playerBackground = Color(0xFF1C1C1E);  // iOS dark sheet
static const playerWaveformPlayed = AppColors.primary;
static const playerWaveformUnplayed = Color(0xFF3A3A3C);
static const playerSeekIndicator = Colors.white;
static const playerButtonActive = AppColors.primary;
static const playerButtonInactive = Color(0xFF636366);
```

### 1.4 애니메이션

| 요소 | 애니메이션 | Duration |
|------|-----------|----------|
| 바텀시트 열기 | slideUp + fade | 300ms |
| 바텀시트 닫기 | slideDown + fade | 200ms |
| 재생 버튼 | scale pulse | 150ms |
| 웨이브폼 진행 | linear | realtime |
| A-B 마커 | bounce | 200ms |

---

## 2. File Storage

### 2.1 파일명 규칙

```
{UUID}.m4a
```

- UUID v4 형식 (예: `a1b2c3d4-e5f6-7890-abcd-ef1234567890.m4a`)
- 중복 불가능
- 파일명에 메타데이터 포함하지 않음

### 2.2 저장 경로

```
Documents/
└── recordings/
    └── {repertoireId}/
        ├── a1b2c3d4-e5f6-7890-abcd-ef1234567890.m4a
        ├── b2c3d4e5-f6a7-8901-bcde-f12345678901.m4a
        └── ...
```

### 2.3 메타데이터 (Hive DB)

```dart
@HiveType(typeId: 22)
class Recording {
  @HiveField(0) final String id;           // UUID (파일명과 동일)
  @HiveField(1) final String repertoireId;
  @HiveField(2) final String studentId;
  @HiveField(3) final RecordingType type;
  @HiveField(4) final String localPath;    // 전체 경로
  @HiveField(5) final String? serverUrl;
  @HiveField(6) final int durationSeconds;
  @HiveField(7) final bool isRepresentative;
  @HiveField(8) final DateTime recordedAt;
  @HiveField(9) final DateTime? sharedAt;
  @HiveField(10) final StorageStatus storageStatus;
  @HiveField(11) final String? title;      // 사용자 지정 제목 (선택)
}
```

### 2.4 녹음 설정

| 항목 | 값 |
|------|-----|
| 포맷 | M4A (AAC-LC) |
| 비트레이트 | 128kbps |
| 샘플레이트 | 44100Hz |
| 채널 | Mono |
| 최대 길이 | 180초 (3분) |

---

## 3. Playback Features

### 3.1 기본 재생

- 재생/일시정지 토글
- 슬라이더로 위치 이동 (웨이브폼 터치)
- 재생 완료 시 자동 정지 및 처음으로

### 3.2 재생 속도 조절

```dart
enum PlaybackSpeed {
  x0_5(0.5, '0.5x'),
  x0_75(0.75, '0.75x'),
  x1_0(1.0, '1.0x'),   // default
  x1_25(1.25, '1.25x'),
  x1_5(1.5, '1.5x'),
  x2_0(2.0, '2.0x');
}
```

- 현재 속도 유지 (다음 녹음에도 적용)
- UI에 현재 속도 표시

### 3.3 구간 반복 (A-B Loop)

```dart
class ABLoop {
  Duration? pointA;  // 시작점 (null = 설정 안됨)
  Duration? pointB;  // 종료점 (null = 설정 안됨)
  bool get isActive => pointA != null && pointB != null;
}
```

**동작 플로우:**
1. A 버튼 탭 → 현재 위치를 A점으로 설정
2. B 버튼 탭 → 현재 위치를 B점으로 설정
3. A-B 설정 완료 시 → 해당 구간만 반복 재생
4. A 또는 B 길게 누름 → 해당 점 해제
5. 둘 다 해제 시 → 전체 재생 모드

**UI 피드백:**
- 웨이브폼에 A-B 구간 하이라이트 표시
- A, B 버튼 활성화 시 색상 변경

---

## 4. Implementation Status

### Phase 1: 기본 플레이어 UI ✅
- [x] `RecordingPlayerBottomSheet` 위젯 생성
- [x] 웨이브폼 시각화 (`RecordingWaveform`)
- [x] 기본 컨트롤 (재생/정지, seek)
- [x] 시간 표시
- [x] 핀치 줌 (웨이브폼 확대/축소)

### Phase 2: 고급 기능 ✅
- [x] 재생 속도 조절 (0.5x ~ 2.0x)
- [x] A-B Loop 구간 반복
- [x] 스마트 녹음 연동 (트림 메타데이터)

### Phase 3: 파일 시스템 정리 ✅
- [x] UUID 기반 파일명
- [x] 경로 구조 정리 (`recordings/{repertoireId}/`)
- [x] Hive 메타데이터 저장

### Phase 4: 추가 기능 ✅
- [x] 날짜별 필터링/정렬
- [x] 대표녹음 시스템 (첫 녹음 자동 지정)
- [x] 녹음 초기화 (전체 삭제)
- [x] 삭제 시 대표녹음 자동 재지정

---

## 5. File Structure

```
lib/
├── features/practice/presentation/
│   ├── screens/
│   │   └── practice_recording_screen.dart  # 기존
│   └── widgets/
│       ├── recording_waveform.dart         # 기존 (수정)
│       └── recording_player_sheet.dart     # 신규
├── providers/recording/
│   └── recording_provider.dart             # 수정 (속도, A-B loop)
└── services/
    └── audio_player_service.dart           # 수정 (속도, seek)
```

---

## References

- [Tubik Studio - Echo Music App UX/UI](https://blog.tubikstudio.com/case-study-echo-designing-uxui/)
- [Onething Design - Music Streaming UX](https://www.onething.design/post/tuning-ux-for-music-streaming-apps)
- iOS Human Interface Guidelines - Controls
