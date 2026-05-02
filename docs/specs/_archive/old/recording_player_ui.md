# 녹음 재생 플레이어 UI 스펙

> 작성일: 2025-12-30
> 최종 수정: 2026-03-02
> 상태: 구현 완료

## 1. 개요

녹음 재생을 위한 바텀시트 플레이어 UI. iOS Voice Memos 스타일의 웨이브폼 시각화, 재생 속도 조절, A-B 루프, 외부 공유 기능을 포함.

**핵심 결정사항**:
| 항목 | 선택 |
|------|------|
| UI 스타일 | 웨이브폼 + 컨트롤 (다크 모드 바텀시트) |
| 파일명 | UUID.m4a (DB 메타데이터 분리) |
| 파형 줌 | 핀치 줌 1x~10x, 미니맵 오버뷰 |
| 마커 조작 | A-B 마커 드래그 핸들 |

---

## 2. 바텀시트 레이아웃

```
┌─────────────────────────────────────────────────────┐
│                    ─────                            │  Drag handle
│               녹음 제목 또는 날짜                    │
│                                                     │
│  ∿∿∿∿∿∿∿∿∿∿∿∿●∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿  │  Waveform (터치/핀치줌)
│                                                     │
│      00:45                              02:30       │  Current / Total time
│                                                     │
│   [A][B]  ×1.0 ▼  [📤]                    ▶/⏸      │  Controls
│                                                     │
└─────────────────────────────────────────────────────┘
```

**컨트롤 배치 (좌→우)**:
- A-B Loop 버튼 (36dp 사각형) + 연결선
- Speed 드롭다운 (`grey[800]` 배경, 둥근 모서리)
- Share 버튼 (`Icons.ios_share`, Speed와 동일 스타일)
- Spacer
- Play/Pause (56dp 원형, `AppColors.primary`)

---

## 3. 컴포넌트 상세

### 3.1 색상

```dart
static const playerBackground = Color(0xFF1C1C1E);  // iOS dark sheet
static const playerWaveformPlayed = AppColors.primary;
static const playerWaveformUnplayed = Color(0xFF3A3A3C);
static const playerSeekIndicator = Colors.white;
```

### 3.2 재생 속도

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

### 3.3 A-B 루프

```dart
class ABLoop {
  Duration? pointA;  // 시작점
  Duration? pointB;  // 종료점
  bool get isActive => pointA != null && pointB != null;
}
```

- A 탭 → 현재 위치를 A점 설정 (재탭: 해제)
- B 탭 → 현재 위치를 B점 설정 (A 이후만 가능)
- 활성 시 구간 반복 재생 + 웨이브폼 하이라이트

### 3.4 외부 공유 버튼

```dart
// Controls Row에서 Speed 버튼 뒤, Spacer 앞 위치
GestureDetector(
  onTap: () => _shareToExternal(context),
  child: Container(/* grey[800] 배경, 둥근 모서리 */),
)

Future<void> _shareToExternal(BuildContext context) async {
  final file = File(widget.recording.localPath);
  if (!await file.exists()) {
    // 스낵바: '녹음 파일을 찾을 수 없습니다'
    return;
  }
  await SharePlus.instance.share(
    ShareParams(files: [XFile(widget.recording.localPath)]),
  );
}
```

- `share_plus` 패키지 사용 (기존 백업/초대 패턴과 동일)
- 카카오톡, 메시지, 이메일 등 OS 공유 시트 표시

---

## 4. 파형 시각화

### 4.1 녹음 시 파형

두 가지 모듈 선택 가능:

| 모듈 | 설명 | enum |
|------|------|------|
| WaveWaveform | 곡선 웨이브 애니메이션 | `WaveformStyle.wave` |
| AmplitudeWaveform | 실시간 진폭 막대 그래프 | `WaveformStyle.amplitude` |

**막대 그래프 스펙**: 너비 3dp, 간격 2dp, 업데이트 100ms, 최소 녹음 5초

### 4.2 재생 시 파형 (핀치 줌)

| 제스처 | 동작 |
|--------|------|
| 탭 | 해당 위치로 seek |
| 핀치 아웃 | 줌 인 (최대 10x) |
| 핀치 인 | 줌 아웃 (최소 1x) |
| 수평 드래그 | 줌 상태에서 파형 스크롤 |
| A/B 핸들 드래그 | 마커 위치 조정 (20px 터치 영역) |

- 1.5x 이상 줌 시 미니맵 오버뷰 표시
- A-B 구간 하이라이트: `AppColors.primary.withOpacity(0.3)`
- 마커 핸들: 24dp 원형, `AppColors.primary`

---

## 5. 파일 저장

### 5.1 파일명 규칙
```
{UUID}.m4a    (예: a1b2c3d4-e5f6-7890-abcd-ef1234567890.m4a)
```

### 5.2 저장 경로
```
Documents/recordings/{repertoireId}/{UUID}.m4a
Documents/recordings/{repertoireId}/{UUID}.m4a.trim  # 스마트 녹음 메타데이터
```

### 5.3 녹음 설정

| 항목 | 값 |
|------|-----|
| 포맷 | M4A (AAC-LC) |
| 비트레이트 | 128kbps |
| 샘플레이트 | 44100Hz |
| 채널 | Mono |
| 최대 길이 | 180초 (3분) |

### 5.4 Hive DB 모델

```dart
@HiveType(typeId: 22)
class Recording {
  @HiveField(0) final String id;
  @HiveField(1) final String repertoireId;
  @HiveField(2) final String studentId;
  @HiveField(3) final RecordingType type;
  @HiveField(4) final String localPath;
  @HiveField(5) final String? serverUrl;
  @HiveField(6) final int durationSeconds;
  @HiveField(7) final bool isRepresentative;
  @HiveField(8) final DateTime recordedAt;
  @HiveField(9) final DateTime? sharedAt;
  @HiveField(10) final StorageStatus storageStatus;
  @HiveField(11) final String? title;
}
```

---

## 6. 구현 상태 (전체 완료)

- [x] Phase 1: 바텀시트 플레이어, 웨이브폼, 기본 컨트롤
- [x] Phase 2: 재생 속도 조절, A-B 루프, 스마트 녹음 연동
- [x] Phase 3: UUID 파일명, 경로 구조, Hive 메타데이터
- [x] Phase 4: 날짜별 필터링, 대표녹음, 녹음 초기화
- [x] 녹음 시 막대 그래프 모듈, 핀치 줌, A-B 드래그 핸들
- [x] 외부 앱 공유 버튼 (share_plus)

---

## 7. 파일 구조

```
frontend/lib/features/practice/presentation/
├── screens/
│   └── practice_recording_screen.dart  # 녹음 화면 + PopupMenu 공유
├── widgets/
│   ├── recording_waveform.dart         # 팩토리 위젯 + exports
│   ├── recording_player_sheet.dart     # 바텀시트 플레이어 + 공유 버튼
│   ├── section_detail/
│   │   └── section_recording_list_item.dart  # PopupMenu 공유
│   └── waveform/
│       ├── waveform_style.dart         # enum WaveformStyle
│       ├── wave_waveform.dart          # 곡선 웨이브 애니메이션
│       ├── amplitude_waveform.dart     # 실시간 진폭 막대 그래프
│       ├── zoomable_waveform.dart      # 핀치 줌 + A-B 드래그
│       └── ab_loop.dart               # ABLoop 클래스
```
