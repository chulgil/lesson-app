# 메트로놈 패키지 비교: flutter_soloud vs metronome

> 작성일: 2025-12-30

## 1. 핵심 비교표

| 항목 | flutter_soloud | metronome | 비고 |
|------|:--------------:|:---------:|------|
| **타이밍 스케줄링** | Dart Timer 의존 | 네이티브 스케줄링 | metronome 우세 |
| **오디오 엔진** | C++ SoLoud (FFI) | 플랫폼 네이티브 | 둘 다 네이티브 |
| **레이턴시** | ~46ms (2048 버퍼) | 플랫폼 최적화 | metronome 우세 |
| **비트별 볼륨** | ✅ `play(volume: 0.7)` | ❌ 전체 볼륨만 | flutter_soloud 우세 |
| **복합 박자** | ✅ 커스텀 구현 가능 | ❌ 정수 박자만 | flutter_soloud 우세 |
| **3잇단음표** | ✅ 직접 구현 | ❌ 미지원 | flutter_soloud 우세 |
| **강/중/약 구분** | ✅ 3단계 이상 | ⚠️ 2단계 (main/accent) | flutter_soloud 우세 |
| **구현 복잡도** | 높음 | 낮음 | metronome 우세 |
| **유지보수** | 중간 | 쉬움 | metronome 우세 |

---

## 2. 정밀도 분석

### 2.1 flutter_soloud (SoLoud 엔진)

```
┌─────────────────────────────────────────────────────────────┐
│  SoLoud 엔진 레이턴시 특성                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  버퍼 크기        샘플레이트      레이턴시                    │
│  ─────────────────────────────────────────                  │
│  2048 샘플    ×   44100 Hz   =   ~46ms                     │
│  1024 샘플    ×   44100 Hz   =   ~23ms                     │
│  512 샘플     ×   44100 Hz   =   ~12ms                     │
│                                                             │
│  ⚠️ 주의: 버퍼가 작을수록 underrun 위험 증가                 │
│                                                             │
│  참고: "드럼 연주에서 40ms는 너무 길다"                       │
│        "천천히 변화하는 패드에서 200ms는 괜찮다"              │
│                                                             │
└─────────────────────────────────────────────────────────────┘

타이밍 스케줄링:
- playClocked() 함수 존재 (C++ SoLoud)
- flutter_soloud에서는 미노출 ❌
- Dart Timer에 의존 → UI 블로킹 영향 받음
```

### 2.2 metronome 패키지

```
┌─────────────────────────────────────────────────────────────┐
│  metronome 패키지 특성                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  iOS:    AVAudioEngine 기반 (추정)                          │
│  Android: AudioTrack/Oboe 기반 (추정)                       │
│                                                             │
│  장점:                                                       │
│  - 플랫폼 네이티브 타이머 사용                                │
│  - Dart UI 스레드와 독립                                     │
│  - BPM 600+ 지원 (고속에서도 안정)                           │
│                                                             │
│  단점:                                                       │
│  - 2파일 체계만 지원 (main/accent)                           │
│  - 비트별 볼륨 조절 불가                                      │
│  - 복합 박자 미지원                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 기능 상세 비교

### 3.1 박자 지원

| 박자 유형 | flutter_soloud | metronome |
|----------|:--------------:|:---------:|
| 2/4, 3/4, 4/4, 6/8 | ✅ | ✅ |
| 5/4, 7/8 (홀수 박자) | ✅ 커스텀 | ❌ |
| 3잇단음표 | ✅ 커스텀 | ❌ |
| 16분음표 세분화 | ✅ 커스텀 | ❌ |
| 복합 박자 변경 | ✅ 커스텀 | ❌ |

### 3.2 강약 패턴

| 패턴 | flutter_soloud | metronome |
|------|:--------------:|:---------:|
| 균일 (모두 동일) | ✅ | ✅ |
| 강/약 (2단계) | ✅ | ✅ |
| 강/중/약 (3단계) | ✅ `volume` 조절 | ❌ |
| 커스텀 악센트 | ✅ | ❌ |

### 3.3 API 비교

```dart
// flutter_soloud - 비트별 볼륨 조절 가능
await soloud.play(source, volume: 1.0);   // 강박
await soloud.play(source, volume: 0.7);   // 중박
await soloud.play(source, volume: 0.4);   // 약박

// metronome - 2파일 체계
await metronome.init(
  mainPath,           // 약박용
  accentedPath: path, // 강박용 (1박만)
);
```

---

## 4. 정밀도 실측 비교 (예상)

| 조건 | flutter_soloud | metronome | 목표 |
|------|:--------------:|:---------:|:----:|
| BPM 40 (1500ms) | ±15-25ms | ±3-8ms | ±5ms |
| BPM 60 (1000ms) | ±10-20ms | ±2-5ms | ±3ms |
| BPM 120 (500ms) | ±8-15ms | ±2-4ms | ±3ms |
| BPM 200 (300ms) | ±5-10ms | ±1-3ms | ±2ms |

> ⚠️ flutter_soloud의 지터는 Dart Timer 의존으로 인한 것
> metronome은 네이티브 스케줄링으로 더 안정적

---

## 5. 사용 시나리오별 권장

### 시나리오 A: 클래식 연습용 (정밀도 최우선)
**권장: metronome 패키지** ✅
- 이유: 네이티브 타이밍, 안정적인 박자
- 제한: 강/중/약 3단계 구분 불가

### 시나리오 B: 복합 박자/잇단음표 필요
**권장: flutter_soloud + 네이티브 타이머** ⚠️
- 이유: 유연한 커스터마이징
- 주의: Isolate 또는 네이티브 타이머 필요

### 시나리오 C: 최고 정밀도 + 모든 기능
**권장: 네이티브 구현 (AVAudioEngine/Oboe)** 🏆
- iOS: Apple Hello Metronome 참고
- Android: Sample-accurate AudioTrack
- 복잡도: 높음, 개발 시간 많이 소요

---

## 6. 하이브리드 접근법 (권장)

```
┌─────────────────────────────────────────────────────────────┐
│  Phase 1: metronome 패키지로 기본 기능 제공                   │
│  - 정확한 타이밍, 강/약 2단계                                 │
│  - 빠른 구현, 안정적                                          │
├─────────────────────────────────────────────────────────────┤
│  Phase 2: 고급 기능 추가 (선택)                               │
│  - 3잇단음표: BPM×3 + timeSignature=3 workaround            │
│  - 또는 flutter_soloud로 전환 + Isolate 타이밍              │
├─────────────────────────────────────────────────────────────┤
│  Phase 3: 네이티브 구현 (필요시)                              │
│  - TE Tuner 수준의 전문 기능 필요시                          │
│  - iOS/Android 별도 네이티브 코드                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 7. 결론

| 기준 | 승자 | 이유 |
|------|:----:|------|
| **타이밍 정밀도** | metronome | 네이티브 스케줄링 |
| **기능 유연성** | flutter_soloud | 비트별 볼륨, 복합 박자 |
| **구현 용이성** | metronome | 패키지 API 단순 |
| **클래식 연습** | metronome | 정밀도 > 기능 |
| **고급 리듬 연습** | flutter_soloud | 3잇단음표 등 지원 |

### 현재 선택: metronome 패키지 ✅
- 정밀도가 가장 중요한 요구사항
- 향후 고급 기능 필요시 flutter_soloud 또는 네이티브 전환 검토

---

## 8. 구현 최적화 (2025-12-30)

### 8.1 플레이 버튼 지연 문제 해결

metronome 패키지 사용 시 발생한 플레이 버튼 지연(~3초) 문제와 해결책:

| 문제 | 원인 | 해결 |
|------|------|------|
| 첫 플레이 지연 | 엔진 초기화 대기 | 앱 시작 시 사전 초기화 |
| 매번 플레이 지연 | async/await 블로킹 | 동기 함수로 변경 |
| UI 응답 지연 | 상태 업데이트 후 엔진 호출 | 상태 먼저 업데이트, 엔진은 fire-and-forget |

### 8.2 최적화된 코드 패턴

```dart
// Before (느림 - async 대기)
Future<void> start() async {
  await _ensureReady();
  await _engine?.start();
  state = state.copyWith(isPlaying: true);
}

// After (빠름 - 동기 + fire-and-forget)
void start() {
  if (state.isPlaying) return;
  state = state.copyWith(isPlaying: true);  // UI 즉시 업데이트
  _engine?.start();  // await 없이 호출
}
```

### 8.3 사전 초기화 (Pre-warming)

```dart
// main.dart - 앱 시작 시 메트로놈 엔진 초기화
class _LessonAppState extends ConsumerState<LessonApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(metronomeProvider.notifier).warmUp();
    });
  }
}
```

### 8.4 핵심 원칙

1. **UI 응답 최우선**: 상태 업데이트는 항상 동기적으로
2. **엔진 호출 비동기**: await 없이 fire-and-forget 패턴
3. **사전 초기화**: 앱 시작 시 엔진 미리 로드
4. **중복 호출 방지**: 상태 체크로 불필요한 호출 차단

---

## 참고 자료

- [SoLoud Concepts](https://solhsa.com/soloud/concepts.html)
- [flutter_soloud](https://pub.dev/packages/flutter_soloud)
- [metronome](https://pub.dev/packages/metronome)
- [Apple Hello Metronome](https://developer.apple.com/library/archive/samplecode/HelloMetronome/)
