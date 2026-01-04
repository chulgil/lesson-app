# 튜너(Tuner) 기능 명세

> 작성일: 2025-01-04
> 상태: 구현 완료 (MVP)

---

## 1. 개요

Tonal Energy 스타일의 전문가급 원형 튜너 + 고양이 캐릭터 피드백

### 1.1 핵심 기능
- 크로마틱 튜너 (YIN 알고리즘 기반 피치 감지)
- 원형 12음계 인디케이터 (자연음/반음 색상 구분)
- 고양이 캐릭터 + 말풍선 피드백
- Perfect/Good/Miss 판정 + 콤보 시스템
- 음악 전공생 기능: 기준주파수(430-450Hz), 조옮김, 이명동음

---

## 2. 아키텍처

### 2.1 파일 구조

```
lib/
├── core/
│   └── audio/
│       ├── tuner_engine.dart              # Abstract interface
│       ├── mock_tuner_engine.dart         # Mock for testing
│       ├── record_tuner_engine.dart       # Real pitch detection (all platforms)
│       └── pitch_detection/
│           └── stability_filter.dart      # Noise filtering & stabilization
│
└── features/
    └── practice/
        ├── domain/
        │   └── entities/
        │       ├── tuner_types.dart       # TunerNote, TuningStatus, etc.
        │       └── tuner_settings.dart    # TunerSettings model
        │
        └── presentation/
            ├── providers/
            │   ├── tuner_provider.dart           # Main tuner state
            │   └── tuner_combo_provider.dart     # Combo counter
            │
            └── widgets/
                ├── practice_tools_modal.dart     # Metronome/Tuner tabs
                └── tuner/
                    ├── circular_tuner_indicator.dart  # 12-note circle
                    ├── tuner_cat_indicator.dart       # Cat + animations
                    ├── tuner_info_bar.dart            # A4·442Hz·+5¢
                    └── tuner_settings_sheet.dart      # Settings bottom sheet
```

### 2.2 엔진 구조

| 엔진 | 설명 | 플랫폼 |
|------|------|--------|
| `TunerEngine` | 추상 인터페이스 | - |
| `MockTunerEngine` | 테스트용 시뮬레이션 | All |
| `RecordTunerEngine` | 실제 마이크 입력 (record + YIN) | iOS, Android, macOS, Windows, Linux |

### 2.3 피치 감지 파이프라인

```
마이크 → PCM16 Stream → Float 변환 → YIN 알고리즘 → 안정화 필터 → TunerNote
         (record)                    (pitch_detector_dart)  (StabilityFilter)
```

---

## 3. UI 컴포넌트

### 3.1 원형 튜너 인디케이터

- 12음계 원형 배치 (C부터 시계방향)
- 자연음: 파란색 계열
- 반음(#/b): 초록색 계열
- 활성 음: 강조 + 글로우 효과

**크기:**
- CircularTunerIndicator: 450px
- NoteButton 폰트: 활성 22px / 비활성 18px
- NoteButton 패딩: 14x8px

### 3.2 고양이 캐릭터

- TunerCatIndicator: 180px
- 표정 변화: idle, listening, tuned, flat, sharp
- Perfect 시 펄스 애니메이션
- 콤보 마일스톤 시 점프 애니메이션

### 3.3 상태 말풍선

| 상태 | 메시지 | 배경색 |
|------|--------|--------|
| 마이크 꺼짐 | "마이크를 켜주세요" | 회색 |
| 소리 대기 | "소리 감지 대기..." | 파란색 |
| 소리 감지 | "소리 감지중" | 주황색 |
| 완벽한 튜닝 | "완벽해요! 🎵" | 초록색 |

### 3.4 탭 네비게이션

- 메트로놈/튜너 탭 전환
- 탭 글자 크기: 선택 20px (bold) / 비선택 18px

---

## 4. 설정

### 4.1 TunerSettings

```dart
class TunerSettings {
  double referenceFrequency;     // 430-450Hz (기본: 442Hz)
  Transposition transposition;   // C, Bb, F, Eb, A
  EnharmonicMode enharmonicMode; // sharp, flat, both
  TunerDifficulty difficulty;    // beginner, intermediate, advanced
  bool showCombo;                // 콤보 표시 여부
  bool vibrationFeedback;        // 진동 피드백
}
```

### 4.2 난이도별 허용 오차

| 난이도 | Perfect | Good |
|--------|---------|------|
| Beginner | ±15 cent | ±30 cent |
| Intermediate | ±10 cent | ±20 cent |
| Advanced | ±5 cent | ±10 cent |

---

## 5. 안정화 필터

### 5.1 StabilityFilter

- 연속 프레임 안정화 (기본 2프레임)
- 확률 임계값 (기본 0.70)
- 주파수 스무딩 (EMA, 0.3 factor)

### 5.2 AmplitudeGate

- 노이즈 게이팅 (기본 0.01 RMS)
- Hold time (200ms) - 짧은 무음 무시

### 5.3 옥타브 에러 보정

YIN 알고리즘은 고주파에서 2nd harmonic을 감지하는 경향이 있음 (옥타브 에러).
Ratio 비교 방식으로 보정:

```
이전 안정 주파수 대비 새 주파수 비율이 1.9~2.1이면 → 주파수를 2로 나눔
```

**제한사항:**
- 낮은 음에서 시작해서 올라가면 보정됨
- 바로 고음(G6 이상)을 시작하면 옥타브 7로 표시될 수 있음
- 이는 업계 표준 해결 방식 (INTUNATOR 등도 동일)

### 5.4 고주파 센트 보정 테이블

YIN 알고리즘의 고주파 바이어스 보정 (Tonal Energy 튜너 대비 측정):

| 옥타브 | 보정 방식 |
|--------|-----------|
| 1-5 | 보정 없음 (정확) |
| 6 | 음별 보정 (F#, G, G# 특히 중요) |
| 7 | 음별 보정 (센트 오차 큼) |
| 8 | 음별 보정 (외삽) |

**6옥타브 음별 보정값:**
```
C:-0.1, C#:-0.1, D:-0.6, D#:-0.7, E:-0.8, F:-0.8
F#:-2.5, G:-4.4, G#:-1.0, A:-1.3, A#:-0.8, B:-2.1
```

**7옥타브 음별 보정값:**
```
C:-1.7, C#:-1.3, D:-1.1, D#:-1.0, E:-1.2, F:-1.6
F#:-2.8, G:-6.1, G#:-5.9, A:-3.0, A#:-3.5, B:-7.0
```

---

## 6. 의존성

```yaml
# pubspec.yaml
dependencies:
  record: ^6.0.0                 # Audio streaming (all platforms)
  pitch_detector_dart: ^0.0.7    # YIN algorithm pitch detection
```

---

## 7. 테스트 방법

### 7.1 macOS에서 테스트
```bash
flutter run -d macos
```
- RecordTunerEngine 사용 (실제 마이크)
- 마이크 권한 허용 필요

### 7.2 iPhone에서 테스트
```bash
flutter run -d <device_id> --release
```

---

## 8. 관련 문서

- [튜너 기능 제안서](../../proposal/tuner_feature_proposal.md)
- [튜너 게이미피케이션 UX](../../proposal/tuner_gamification_ux.md)
- [메트로놈 스펙](../metronome/README.md)

---

## 9. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2025-01-04 | MVP 구현 완료 |
| 2025-01-04 | RecordTunerEngine으로 전환 (전 플랫폼 지원) |
| 2025-01-04 | 상태 말풍선 추가 |
| 2025-01-04 | UI 크기 2배 확대 |
| 2025-01-04 | 고주파 보정 테이블 추가 (옥타브 6-8, 음별 보정) |
| 2025-01-04 | 옥타브 에러 보정 추가 (ratio 비교 방식) |
| 2025-01-04 | TE 튜너 대비 센트 보정 값 정밀 교정 |

## 10. TODO

- [ ] 튜너 설정값 Hive DB 저장 (앱 재설치 후에도 유지)
