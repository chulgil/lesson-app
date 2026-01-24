# 레퍼토리/섹션 날짜 관리 분석

> 작성일: 2026-01-24
> 목적: 타 서비스 비교 분석을 통한 최적의 날짜 관리 방식 도출

---

## 1. 타 서비스 분석

### 1.1 [Modacity](https://www.modacity.co/) - Practice List 방식

| 구조 | 날짜 관리 | 특징 |
|------|:--------:|------|
| Practice List (재생목록) | ❌ 없음 | 테마별 그룹화 |
| Practice Item (곡/연습) | ❌ 없음 | 타이머, 노트, BPM 설정 |

**핵심 특징:**
- 날짜 기반이 아닌 **리스트 기반** 관리
- "Winter Concert", "Upcoming Audition" 같은 목적별 리스트
- 항목은 완료할 때까지 리스트에 유지
- 시간 추적은 있지만 **마감일 개념 없음**

> "The pieces can then be arranged into playlists. People organize playlists by upcoming audition, recital, or even according to the day of the week."
> — [Modacity Blog](https://www.modacity.co/blog/using-playlists-can-improve-practice)

---

### 1.2 [Tonara](https://www.tonara.com/) - Assignment 방식

| 구조 | 날짜 관리 | 특징 |
|------|:--------:|------|
| Assignment (과제) | ✅ 과제 단위 | 선생님 → 학생 할당 |
| Practice Item (곡) | ❌ 없음 | 과제에 포함된 항목들 |

**핵심 특징:**
- 선생님이 과제(Assignment)를 생성하고 학생에게 전달
- **과제 단위로 기한 설정** (개별 곡 X)
- 한 과제에 여러 곡/연습 포함 가능

> "I DETESTED that I was forced to assign a time on individual assignments in Tonara."
> — [Teacher feedback](https://www.leilaviss.com/blog/transition-from-tonara-to-practice-space)

**교훈:** 개별 항목에 시간/날짜 강제 설정은 **사용자 불만 유발**

---

### 1.3 [Practice Space](https://www.practicespaceapp.com/) - Weekly Assignment 방식

| 구조 | 날짜 관리 | 특징 |
|------|:--------:|------|
| Weekly Assignment (주간 과제) | ✅ 주 단위 | 레슨 후 해당 주 과제 |
| Task (개별 항목) | ❌ 없음 | 체크박스로 완료 표시 |

**핵심 특징:**
- **주간 단위** 과제 관리 (날짜별 정렬)
- 개별 항목은 체크박스만 있음 (날짜 없음)
- "All past lesson assignments are organized by date"

---

### 1.4 [Yousician](https://yousician.com/) - Progress 방식

| 구조 | 날짜 관리 | 특징 |
|------|:--------:|------|
| Course/Path | ❌ 없음 | 레벨 기반 진행 |
| Lesson/Song | ❌ 없음 | 완료율, 별점 |

**핵심 특징:**
- 날짜 개념 없이 **진행률 기반**
- 완료하면 다음 단계로 진행
- 자기주도 학습에 적합

---

## 2. 분석 결과

### 2.1 공통점

| 패턴 | 앱 | 설명 |
|------|-----|------|
| **그룹 단위 날짜** | Tonara, Practice Space | 과제/주간 단위로만 날짜 관리 |
| **개별 항목 날짜 없음** | 전체 | 곡/섹션별 날짜 설정 없음 |
| **체크박스 완료** | Modacity, Practice Space | 개별 항목은 체크만 |

### 2.2 날짜 관리 계층 비교

```
서비스별 날짜 관리 위치:

Modacity:        List ────── Item
                  (없음)      (없음)

Tonara:          Assignment ─ Item
                  (날짜)      (없음)

Practice Space:  Week ─────── Task
                  (날짜)      (없음)

Yousician:       Path ─────── Lesson
                  (없음)      (없음)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

lesson-app (현재): Repertoire ─ Section
                    (날짜)       (날짜)  ← 중복!

lesson-app (제안): Repertoire ─ Section
                    (날짜)       (없음)  ← 단순화
```

---

## 3. 결론 및 권장안

### 3.1 권장: 레퍼토리 단위 날짜 관리

| 항목 | 현재 | 권장 | 이유 |
|------|:----:|:----:|------|
| 레퍼토리 날짜 | ✅ | ✅ | 유지 |
| 섹션 날짜 | ✅ | ❌ | **제거** - 타 앱 패턴, 사용자 혼란 방지 |

### 3.2 근거

1. **타 서비스 패턴**: 모든 주요 앱이 개별 항목에 날짜 없음
2. **사용자 피드백**: Tonara의 강제 시간 설정에 대한 부정적 반응
3. **심플함 원칙**: "음악인은 IT에 관심이 적으므로 최대한 심플하게"
4. **실제 사용**: 섹션별 다른 날짜 설정은 거의 사용 안 함

### 3.3 제안 모델

```dart
// 레퍼토리: 날짜 관리
class PracticeRepertoire {
  final String id;
  final String name;
  final DateTime startDate;     // ✅ 유지
  final DateTime? endDate;      // ✅ 유지
  final List<PracticeSection> sections;
}

// 섹션: 날짜 없음, 레퍼토리 기간 상속
class PracticeSection {
  final String id;
  final String pieceName;
  final SectionRangeType rangeType;
  // startDate, endDate 제거
  final bool isRepeat;          // 매일 반복 (레퍼토리 기간 동안)
  final int? repeatCount;       // N회 반복
}
```

### 3.4 UI 변경

**Before (현재):**
```
레퍼토리 추가
├── 이름, 설명
├── 시작일, 종료일      ← 레퍼토리
│
섹션 추가 (별도 화면)
├── 곡명, 범위
├── 시작일, 종료일      ← 섹션 (중복!)
```

**After (제안):**
```
레퍼토리 추가 (통합 화면)
├── 이름, 설명
├── 시작일, 종료일      ← 한 번만
│
└── 섹션 1: 곡명, 범위, N회 반복
└── 섹션 2: 곡명, 범위
└── [+ 섹션 추가]
```

---

## 4. 구현 계획

### Phase 1: UI 변경 ✅ 완료 (2026-01-24)

1. ✅ **UI에서만 숨기기** - 데이터 모델은 유지
2. ✅ `add_section_screen.dart` 에서 `DateRangeSection` 위젯 제거
3. ✅ `edit_section_screen.dart` 에서 `DateRangeSection` 위젯 제거
4. ✅ 새 섹션 생성 시 `startDate: null`, `endDate: null`, `isRepeat: true`로 설정

**수정된 파일:**
- `lib/features/practice/presentation/screens/add_section_screen.dart`
- `lib/features/practice/presentation/screens/edit_section_screen.dart`

### Phase 2: 데이터 마이그레이션 (선택, 미구현)

1. 기존 섹션의 날짜 데이터는 유지 (호환성)
2. 새 섹션은 날짜 null로 생성
3. 섹션 날짜가 null이면 레퍼토리 날짜 상속

---

## 5. 참고 자료

### Sources:
- [Modacity - Pro Music Practice App](https://www.modacity.co/)
- [Modacity Blog - Using Playlists](https://www.modacity.co/blog/using-playlists-can-improve-practice)
- [Tonara - Music Practice App](https://www.tonara.com/)
- [Practice Space - Music Practice App](https://www.practicespaceapp.com/)
- [Best Practice Apps for Musicians](https://www.ensembleschools.com/blog/apps-for-musicians/)
- [Teacher feedback on Tonara](https://www.leilaviss.com/blog/transition-from-tonara-to-practice-space)

---

## 6. 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-01-24 | 1.0 | 초안 작성 - 타 서비스 분석 및 권장안 |
| 2026-01-24 | 1.1 | Phase 1 구현 완료 - 섹션 화면에서 날짜 필드 제거 |
