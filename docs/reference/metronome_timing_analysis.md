# 메트로놈 타이밍 정확도 분석 및 개선

> 작성일: 2025-12-29

## 1. 문제 정의

### 1.1 현상
- 메트로놈 박자 사운드 간격이 일정하지 않음
- 특히 BPM 40 같은 저속에서 발바닥 애니메이션과 소리가 맞지 않음
- 클래식 전공자가 정확한 박자로 연습하기 어려움

### 1.2 원인 분석

#### Dart Timer의 근본적 한계
```
Dart Main Thread (UI Thread)
┌─────────────────────────────────────────────────────────────┐
│  Timer.periodic(1ms)                                        │
│       ↓                                                     │
│  콜백 실행 ──→ UI 렌더링에 의해 블로킹됨                      │
│       ↓                                                     │
│  _tick() → play() → onBeat() (UI update)                   │
└─────────────────────────────────────────────────────────────┘

문제점:
- Dart는 단일 스레드 이벤트 루프 기반
- UI 프레임 렌더링 (16ms) 동안 타이머 콜백 지연
- GC(가비지 컬렉션)가 타이밍을 방해
- 타이머 정밀도: 요청 1ms → 실제 1~20ms 지터
```

#### 클래식 음악 연습자 요구사항
| BPM | 간격 | 허용 오차 | 기존 상태 |
|-----|------|----------|----------|
| 40 | 1500ms | ±5ms | ~20ms 지터 |
| 120 | 500ms | ±3ms | ~15ms 지터 |
| 200 | 300ms | ±2ms | ~10ms 지터 |

**클래식 연주자는 ±5ms 이내의 정밀도 필요**

---

## 2. 검토한 해결책

### 2.1 옵션 비교표

| 방법 | 정확도 | 복잡도 | 유지보수 | 선택 |
|------|:------:|:------:|:--------:|:----:|
| `metronome` 패키지 | ⭐⭐⭐⭐ | 낮음 | 쉬움 | ✅ 채택 |
| flutter_soloud + Isolate | ⭐⭐⭐⭐ | 높음 | 중간 | 대안 |
| Sample-accurate 네이티브 | ⭐⭐⭐⭐⭐ | 매우 높음 | 어려움 | 전문가용 |
| Dart Timer (기존) | ⭐⭐ | 낮음 | 쉬움 | ❌ 부적합 |

### 2.2 각 방식 상세

#### A. metronome 패키지 (채택)
- **장점**: 플랫폼 네이티브 최적화, BPM 600+ 지원, 검증된 패키지
- **단점**: 2파일 체계(main/accent)만 지원, 3잇단음표 미지원
- **URL**: https://pub.dev/packages/metronome

#### B. flutter_soloud + 실시간 볼륨
- **장점**: 비트별 볼륨 조절 가능, 유연한 커스터마이징
- **단점**: 타이밍은 여전히 Dart Timer에 의존
- **적용 시나리오**: 강/중/약 세밀한 볼륨 제어 필요 시

#### C. Sample-accurate 네이티브
- **원리**: 시스템 타이머 대신 오디오 프레임 카운팅
- **장점**: 가장 정확한 타이밍 (±1ms 이내)
- **단점**: iOS/Android 별도 구현 필요, 높은 개발 비용
- **참고**: https://moshenskyi.medium.com/building-a-sample-accurate-metronome-with-audiotrack-in-android

#### D. Isolate 기반 타이밍
- **원리**: 별도 스레드에서 타이밍 루프 실행
- **장점**: UI 스레드 블로킹 영향 없음
- **단점**: 메인 스레드와 통신 오버헤드

---

## 3. 오디오 파일 전략

### 3.1 문제: 다른 파일 = 다른 인지 타이밍

```
기존 방식:
pen_strong.wav  → Attack: 2ms,  Peak: -3dB
pen_medium.wav  → Attack: 5ms,  Peak: -6dB
pen_weak.wav    → Attack: 8ms,  Peak: -12dB

⚠️ Attack 시간이 다르면 "찍"하는 순간이 달라짐
→ 클래식 연주자가 느끼는 타이밍 불일치의 원인
```

### 3.2 해결책 옵션

| 방식 | 설명 | 채택 |
|------|------|:----:|
| 사전 정규화된 오디오 | 동일 샘플을 볼륨만 다르게 저장 | 대안 |
| 실시간 볼륨 조절 | play(source, volume: 0.7) | flutter_soloud용 |
| 2파일 체계 | main(약박) + accent(강박) | ✅ 채택 |

### 3.3 채택된 방식: 2파일 체계
- **main**: 약박용 (medium 볼륨)
- **accent**: 강박용 (strong 볼륨)
- **핵심**: 같은 샘플의 두 버전 → 동일한 Attack 시간 → 일관된 타이밍 인지

---

## 4. 복합 박자 지원

### 4.1 현재 지원 범위

```
metronome 패키지:
timeSignature: int (정수만)
├── 2 → 2/4
├── 3 → 3/4
├── 4 → 4/4
└── 6 → 6/8

❌ 미지원:
- 3잇단음표 (Triplet)
- 16분음표 세분화
- 복합 박자 (5/4, 7/8)
- Subdivision
```

### 4.2 향후 구현 방안

#### 3잇단음표 구현 (Workaround)
```
원하는 것: ♩= 60 에서 3잇단음표
구현 방법: BPM = 60 × 3 = 180, timeSignature = 3
```

#### 완전한 Subdivision 지원 (향후)
- 커스텀 타이머 구현 필요
- 또는 flutter_soloud로 전환 후 직접 구현

---

## 5. 구현 이력

### 5.1 변경 내역

| 날짜 | 변경 | 결과 |
|------|------|------|
| 2025-12-29 | audioplayers → flutter_soloud | 소리 재생됨, 타이밍 불안정 |
| 2025-12-29 | flutter_soloud + 마이크로초 정밀도 | 개선되었으나 여전히 지터 |
| 2025-12-29 | flutter_soloud → metronome 패키지 | **채택** |

### 5.2 최종 구현

```dart
// lib/core/audio/metronome_engine.dart
import 'package:metronome/metronome.dart' as pkg;

class MetronomeEngine implements MetronomeEngineInterface {
  pkg.Metronome? _metronome;

  Future<void> init() async {
    await _metronome!.init(
      mainPath,           // 약박용 오디오
      accentedPath: accentPath,  // 강박용 오디오
      bpm: _settings.bpm,
      volume: 100,
      enableTickCallback: true,
      timeSignature: _mapTimeSignature(_settings.timeSignature),
    );
  }
}
```

---

## 6. 테스트 체크리스트

- [ ] BPM 40에서 타이밍 일관성 확인
- [ ] BPM 60에서 타이밍 일관성 확인
- [ ] BPM 120에서 타이밍 일관성 확인
- [ ] BPM 200에서 타이밍 일관성 확인
- [ ] 강박/약박 구분 확인
- [ ] 발바닥 애니메이션 동기화 확인
- [ ] 장시간 재생 시 드리프트 확인

---

## 7. 참고 자료

- [metronome 패키지](https://pub.dev/packages/metronome)
- [flutter_soloud 패키지](https://pub.dev/packages/flutter_soloud)
- [Flutter Timer 정밀도 분석](https://medium.com/geekculture/flutter-case-study-timer-precision-a1154b431e8)
- [Sample-accurate Android Metronome](https://moshenskyi.medium.com/building-a-sample-accurate-metronome-with-audiotrack-in-android)
