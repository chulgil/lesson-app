# 접근성 (a11y) Semantics 스펙

> Gap #8 | 우선순위: 🟡 MEDIUM | 예상: 3일

## 목적

핵심 화면에 Semantics 위젯 추가로 VoiceOver/TalkBack 지원 시작.

## 현재 상태

- Semantics 위젯 프로덕션 코드 4건만 존재
- 1,044 Dart 파일 중 대부분 접근성 미지원

## 구현 범위

핵심 화면 5개에 Semantics 추가:

### 1. 메트로놈 (`features/practice/presentation/screens/metronome_screen.dart`)

- 템포 표시: `Semantics(label: 'BPM $tempo')`
- 재생/정지 버튼: `Semantics(label: '메트로놈 재생', button: true)`
- 템포 슬라이더: `Semantics(label: '템포 조절', slider: true, value: '$tempo BPM')`
- 박자 선택: `Semantics(label: '$beats분의 $noteValue 박자')`

### 2. 튜너 (`features/practice/presentation/screens/tuner_screen.dart`)

- 음이름 표시: `Semantics(label: '현재 음: $noteName')`
- 피치 편차: `Semantics(label: '피치 편차: $cents 센트')`
- 튜닝 상태: `Semantics(label: '튜닝 $status')`  (정확/높음/낮음)

### 3. 선생님 홈 (`features/home/presentation/screens/home_screen.dart`)

- 오늘의 레슨 카드: `Semantics(label: '오늘 레슨 $count건')`
- 학생 카드: `Semantics(label: '$studentName, $instrument')`
- 대시보드 탭: `Semantics(label: '$tabName 탭', selected: isSelected)`

### 4. 레슨 상세 (`features/lessons/presentation/screens/lesson_detail_screen.dart`)

- 레슨 상태: `Semantics(label: '레슨 상태: $status')`
- 피드백 입력: `Semantics(label: '피드백 입력', textField: true)`
- 녹음 재생: `Semantics(label: '녹음 재생 $duration초', button: true)`

### 5. 연습 기록 (`features/practice/presentation/screens/practice_screen.dart`)

- 연습 시간: `Semantics(label: '오늘 연습 $minutes분')`
- 스트릭: `Semantics(label: '연속 $days일 연습')`
- 레퍼토리 목록: `Semantics(label: '$name - $composer, 진행률 $progress%')`

## 구현 방식

기존 위젯을 `Semantics` 위젯으로 래핑. 기존 UI에 영향 없음.

```dart
// Before
Text('$tempo BPM')

// After
Semantics(
  label: '현재 템포 $tempo BPM',
  child: Text('$tempo BPM'),
)
```

## 수용 기준

- [ ] 5개 핵심 화면에 Semantics 위젯 추가
- [ ] 기존 UI 레이아웃 변경 없음
- [ ] 한국어 라벨 사용 (AppStrings 통해)

## 영향 파일

- `frontend/lib/features/practice/presentation/screens/metronome_screen.dart`
- `frontend/lib/features/practice/presentation/screens/tuner_screen.dart`
- `frontend/lib/features/home/presentation/screens/home_screen.dart`
- `frontend/lib/features/lessons/presentation/screens/lesson_detail_screen.dart`
- `frontend/lib/features/practice/presentation/screens/practice_screen.dart`
