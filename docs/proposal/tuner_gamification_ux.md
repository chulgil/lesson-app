# 튜너 게임화(Gamification) UX 설계서

> 작성일: 2025-01-04
> 버전: v1.0
> 목표: 10대~60대 모든 연령대가 쉽고 재미있게 사용할 수 있는 튜너

---

## 1. 설계 원칙

### 1.1 핵심 가치
```
"단순함 + 재미 + 성취감"

복잡한 기능 최소화 → 핵심 기능에 집중
게임적 요소 → 연습을 놀이처럼
즉각적 피드백 → 명확한 성취감
```

### 1.2 연령대별 고려사항

| 연령대 | 고려사항 | 적용 방안 |
|--------|----------|----------|
| **10대** | 게임적 재미, 시각적 보상 | 콤보 이펙트, 애니메이션 |
| **20-40대** | 효율성, 명확한 진행도 | 직관적 UI, 빠른 피드백 |
| **50-60대** | 큰 폰트, 단순한 조작 | 16pt+ 폰트, 큰 터치 영역 |

### 1.3 유니버설 디자인 원칙
- **폰트**: 최소 16pt (설정에서 확대 가능)
- **터치 영역**: 최소 44x44pt
- **색상 대비**: WCAG AA 기준 충족
- **피드백**: 시각 + 청각 (선택적 햅틱)

---

## 2. 게임화 요소

### 2.1 Perfect/Good/Miss 판정 시스템

#### 판정 기준 (난이도별)

| 난이도 | Perfect | Good | Miss |
|--------|---------|------|------|
| **초보** (Beginner) | ±15 cent | ±30 cent | 30+ cent |
| **중급** (Intermediate) | ±10 cent | ±20 cent | 20+ cent |
| **고급** (Advanced) | ±5 cent | ±10 cent | 10+ cent |

#### 난이도 자동 설정
```
사용자 프로필의 악기 레벨에 따라 자동 적용:
- 초보자 → Beginner 난이도
- 중급자 → Intermediate 난이도
- 고급자 → Advanced 난이도

수동 변경: 설정 > 튜너 > 판정 난이도
```

#### 판정 시 피드백

| 판정 | 고양이 표정 | 말풍선 | 색상 | 이펙트 |
|------|-----------|--------|------|--------|
| **Perfect** | 😻 기쁨 | "완벽해옹!" | 연두색 | 발광 + 별 |
| **Good** | 😺 미소 | "좋아옹!" | 노란색 | 약한 발광 |
| **Miss** | 😿 슬픔 | "다시 해봐옹~" | 회색 | 없음 |

### 2.2 콤보(Combo) 시스템

#### 콤보 규칙
```
Perfect 연속 달성 시 콤보 증가
Good은 콤보 유지 (증가 X)
Miss는 콤보 초기화
```

#### 콤보 단계별 이펙트

| 콤보 | 고양이 애니메이션 | 주변 이펙트 | 특별 메시지 |
|------|-----------------|------------|------------|
| 1-4 | 기본 표정 | 없음 | - |
| **5+** | 작은 점프 | ⭐ 별 1개 | "콤보 시작!" |
| **10+** | 큰 점프 | ⭐⭐ 별 2개 | "대단해옹!" |
| **20+** | 춤추기 | ⭐⭐⭐ + ✨ | "천재다옹!" |
| **50+** | 특별 춤 | 🌟 황금별 | "전설이다옹!" |

#### 콤보 UI 표시
```
┌─────────────────────────────────────┐
│                                     │
│            ⭐  ⭐                    │  ← 콤보 이펙트 (별)
│       B ┌─────┐ C#                  │
│      Bb │     │ Db                  │
│     A   │ 🐱  │   D                 │
│      Ab │COMBO│ D#                  │  ← 콤보 카운터
│       G │ 12  │ Eb                  │
│        F└─────┘ E                   │
│           F                         │
│                                     │
│   ──────────────────────────────    │
│   "대단해옹!"        A4 · 442Hz     │
│   ──────────────────────────────    │
│                                     │
└─────────────────────────────────────┘
```

### 2.3 스트릭(Streak) 시스템 (선택적)

#### 일일 연습 스트릭
```
튜너를 사용한 날을 연속으로 카운트
연습 화면 또는 홈 화면에 표시
```

| 스트릭 | 보상 |
|--------|------|
| 3일 연속 | 🔥 불꽃 아이콘 표시 |
| 7일 연속 | 특별 메시지 |
| 30일 연속 | 달성 뱃지 |

---

## 3. 고양이 애니메이션 상세

### 3.1 기본 상태

| 상태 | 애니메이션 | 설명 |
|------|-----------|------|
| **대기** | 눈 깜빡임 | 2-3초마다 자연스럽게 |
| **감지 중** | 귀 쫑긋 | 음을 들을 때 |
| **튜닝 중** | 고개 기울임 | Flat/Sharp 방향으로 |

### 3.2 판정별 애니메이션

#### Perfect 애니메이션 시퀀스
```
1. 눈 반짝 (0.1s)
2. 양 앞발 들기 (0.2s)
3. 작은 점프 (0.15s)
4. 착지 + 미소 (0.15s)
5. 말풍선 "완벽해옹!" (1s 유지)

총 시간: ~1.6s
```

#### Good 애니메이션
```
1. 눈 반짝 (0.1s)
2. 고개 끄덕 (0.3s)
3. 말풍선 "좋아옹!" (0.8s 유지)

총 시간: ~1.2s
```

#### Miss 애니메이션
```
1. 귀 접기 (0.2s)
2. 눈 내리깔기 (0.2s)
3. 말풍선 "다시 해봐옹~" (1s 유지)

총 시간: ~1.4s
```

### 3.3 콤보 특별 애니메이션

#### 5콤보: 작은 점프
```dart
// Flutter 구현 예시
AnimationController _jumpController;

void playSmallJump() {
  _jumpController.forward().then((_) {
    _jumpController.reverse();
  });
}

// Transform.translate로 Y축 이동
Transform.translate(
  offset: Offset(0, -20 * _jumpAnimation.value),
  child: CatWidget(),
)
```

#### 10콤보: 큰 점프 + 회전
```dart
// 점프 + 약간의 회전
Transform(
  transform: Matrix4.identity()
    ..translate(0.0, -40 * _jumpAnimation.value)
    ..rotateZ(0.1 * sin(_jumpAnimation.value * pi)),
  child: CatWidget(),
)
```

#### 20콤보: 춤추기
```dart
// 좌우 흔들림 + 점프
Transform(
  transform: Matrix4.identity()
    ..translate(
      10 * sin(_danceAnimation.value * 2 * pi),
      -20 * abs(sin(_danceAnimation.value * 4 * pi)),
    ),
  child: CatWidget(),
)
```

### 3.4 이펙트 애니메이션

#### 별 이펙트 (콤보 시)
```dart
// 고양이 주변에 별이 반짝이며 나타남
class StarEffect extends StatefulWidget {
  // 별 개수: 콤보 단계에 따라 1-3개
  // 위치: 고양이 주변 랜덤
  // 애니메이션: 페이드인 + 스케일업 + 반짝임
}

// 애니메이션 시퀀스
1. 투명 → 불투명 (0.2s)
2. 작게 → 크게 (0.2s)
3. 반짝임 (깜빡임 2회, 0.4s)
4. 불투명 → 투명 (0.3s)
```

#### 발광 효과 (Perfect 시)
```dart
// 현재 음표에 연두색 글로우
Container(
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: TunerColors.glowPerfect,
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  ),
)
```

---

## 4. 단순함을 위한 UI 설계

### 4.1 메인 화면 (최소한의 요소)

```
┌─────────────────────────────────────┐
│                                     │
│        [원형 튜너 인디케이터]         │
│                                     │
│              🐱                      │
│          "완벽해옹!"                  │
│           COMBO 5                   │
│                                     │
│   ──────────────────────────────    │
│         A4 · 442Hz · +2¢           │
│   ──────────────────────────────    │
│                                     │
│  [🎵 튜너]  [🎼 메트로놈]  [⚙️]      │
└─────────────────────────────────────┘

표시 요소 (5개만):
1. 원형 인디케이터 (현재 음)
2. 고양이 + 말풍선
3. 콤보 카운터
4. 하단 정보 (음표, Hz, cent)
5. 네비게이션 탭
```

### 4.2 설정 화면 (단순화)

```
튜너 설정
─────────────────────────────────

기준 주파수
[440] [441] [442] [443]  [직접입력]

조옮김 (관악기용)
[C] [Bb] [F] [Eb] [A]

판정 난이도
[초보] [중급] [고급]
     └── 현재 프로필 기준 자동 설정됨

이명동음 표시
○ 단일 (C#)
○ 병기 (C#/Db)

─────────────────────────────────
```

### 4.3 접근성 옵션

```
접근성 설정
─────────────────────────────────

글꼴 크기
[작게] [보통] [크게] [매우 크게]

고대비 모드
○ 끄기
○ 켜기 (색상 대비 강화)

애니메이션
○ 모두 켜기
○ 최소화 (움직임 민감한 사용자용)

진동 피드백
○ 끄기
○ 켜기

─────────────────────────────────
```

---

## 5. Flutter 구현 가능성

### 5.1 구현 난이도 평가

| 기능 | 난이도 | 구현 방법 | 예상 시간 |
|------|--------|----------|----------|
| Perfect/Good 판정 | ⭐ 쉬움 | 조건문 분기 | 2시간 |
| 콤보 카운터 | ⭐ 쉬움 | StateNotifier | 1시간 |
| 고양이 점프 | ⭐⭐ 보통 | AnimationController | 4시간 |
| 별 이펙트 | ⭐⭐ 보통 | CustomPainter/Lottie | 6시간 |
| 고양이 춤추기 | ⭐⭐⭐ 어려움 | 복합 애니메이션 | 8시간 |
| 발광 효과 | ⭐ 쉬움 | BoxShadow | 1시간 |
| 말풍선 팝업 | ⭐ 쉬움 | AnimatedOpacity | 2시간 |

### 5.2 권장 구현 순서

```
Phase 1: MVP 게임화 (1주)
├── Perfect/Good/Miss 판정 로직
├── 고양이 말풍선 피드백
├── 기본 콤보 카운터
└── 발광 효과

Phase 2: 애니메이션 강화 (1주)
├── 고양이 점프 애니메이션
├── 별 이펙트
└── 콤보 단계별 애니메이션

Phase 3: 폴리싱 (3일)
├── 고양이 춤추기 (20+ 콤보)
├── 사운드 이펙트 (선택)
└── 접근성 옵션
```

### 5.3 추천 패키지

| 용도 | 패키지 | 비고 |
|------|--------|------|
| 애니메이션 | `flutter_animate` | 간편한 애니메이션 체이닝 |
| 파티클 이펙트 | `particles_flutter` | 별/반짝임 효과 |
| Lottie | `lottie` | 복잡한 애니메이션 (선택) |
| 햅틱 | `vibration` | 진동 피드백 |

### 5.4 성능 고려사항

```dart
// 애니메이션 최적화
1. RepaintBoundary로 리페인트 영역 제한
2. AnimationController 재사용
3. 복잡한 애니메이션은 Lottie로 대체

// 메모리 최적화
1. 이펙트 오브젝트 풀링
2. 사용하지 않는 애니메이션 dispose

// 배터리 최적화
1. 백그라운드 진입 시 애니메이션 정지
2. 저전력 모드 감지 시 이펙트 최소화
```

---

## 6. 아키텍처 설계

### 6.1 게임화 관련 Provider

```dart
// 튜너 판정 Provider
@riverpod
class TunerJudgement extends _$TunerJudgement {
  @override
  JudgementState build() => JudgementState.idle;

  void judge(double centDeviation, Difficulty difficulty) {
    final thresholds = _getThresholds(difficulty);

    if (centDeviation.abs() <= thresholds.perfect) {
      state = JudgementState.perfect;
      ref.read(comboProvider.notifier).increment();
    } else if (centDeviation.abs() <= thresholds.good) {
      state = JudgementState.good;
      // 콤보 유지 (증가 X)
    } else {
      state = JudgementState.miss;
      ref.read(comboProvider.notifier).reset();
    }
  }
}

// 콤보 Provider
@riverpod
class Combo extends _$Combo {
  @override
  int build() => 0;

  void increment() => state++;
  void reset() => state = 0;
}

// 고양이 애니메이션 상태 Provider
@riverpod
class CatAnimationState extends _$CatAnimationState {
  @override
  CatAnimation build() => CatAnimation.idle;

  void playJudgementAnimation(JudgementState judgement, int combo) {
    // 판정 + 콤보에 따른 애니메이션 결정
  }
}
```

### 6.2 파일 구조

```
lib/features/practice/presentation/
├── providers/
│   ├── tuner_provider.dart
│   ├── tuner_judgement_provider.dart  # NEW
│   ├── combo_provider.dart            # NEW
│   └── cat_animation_provider.dart    # NEW
│
└── widgets/
    └── tuner/
        ├── circular_note_indicator.dart
        ├── tuner_cat_widget.dart
        ├── cat_animations/             # NEW
        │   ├── cat_jump_animation.dart
        │   ├── cat_dance_animation.dart
        │   └── cat_expression_animation.dart
        ├── effects/                    # NEW
        │   ├── star_effect.dart
        │   ├── glow_effect.dart
        │   └── combo_effect.dart
        ├── judgement_popup.dart        # NEW
        └── combo_counter.dart          # NEW
```

---

## 7. 타사 사례 참고

### 7.1 Yousician / Simply Piano
- 별점 시스템 (1-3개 별)
- 레슨 완료 시 포인트
- 주간 챌린지/리더보드
- "중독성 있는" 게임화

### 7.2 Guitar Hero / 리듬 게임
- Pre-feedback (다가오는 노트 표시)
- Immediate feedback (히트 순간 시각/청각)
- Post-feedback (판정 표시)
- 스트릭으로 점수 증가

### 7.3 우리만의 차별점
```
타사: 복잡한 레벨/포인트/리더보드
우리: 단순함 + 고양이 캐릭터의 감성적 피드백

"포인트보다 고양이의 칭찬이 더 기분 좋다"
```

---

## 8. 참고 자료

### 게임화 UX
- [AppMaster - Music Learning App Development](https://appmaster.io/blog/developing-music-instrument-learning-app)
- [ROLI - From Guitar Hero to Music Learning](https://roli.com/blog/from-guitar-hero-to-roli-piano-how-rhythm-games-became-real-music-learning)
- [Pianoers - Simply Piano Review](https://pianoers.com/simply-piano-review-the-honest-truth-about-learning-piano-with-an-app/)

### 유니버설 디자인
- [시니어 UX 디자인 Tips](https://ditoday.com/ux-tips/)
- [유니버설 디자인이란](https://k-rnd.com/universal-design/)
- [게임 UX와 접근성](https://velog.io/@tjsdk88802/게임-UX란)

---

## 변경 이력

| 날짜 | 버전 | 내용 |
|------|------|------|
| 2025-01-04 | v1.0 | 초안 작성: 게임화 요소, 애니메이션, Flutter 구현 가능성 |

