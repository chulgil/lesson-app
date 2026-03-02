# Lesson App - Lessons Module 분석

## 개요
lesson-app의 lessons 모듈은 레슨 관리, 결제, 팁 템플릿 등을 담당합니다.
Monorepo 구조: 루트 → frontend (Flutter) + backend (FastAPI 예정)

---

## 1. 화면 구조 (Screens)

### 1.1 AddLessonScreen
**파일**: `frontend/lib/features/lessons/presentation/screens/add_lesson_screen.dart`
**클래스**: `AddLessonScreen` (ConsumerStatefulWidget)

**기능**:
- 새로운 레슨 추가
- 학생 선택
- 날짜/시간 선택 (미래 날짜만)
- 레슨 시간 선택 (30분 ~ 2시간)
- 정기 레슨 설정 (매주 반복)
- 곡 이름, 메모, 리마인더 설정

**주요 상태**:
- `_selectedStudent`: 선택된 학생
- `_selectedDate`, `_selectedTime`: 날짜/시간
- `_lessonDuration`: 레슨 시간
- `_isRecurring`, `_recurringDays`: 정기 레슨 설정

**사용 Provider**:
- `lessonsNotifierProvider`: 레슨 추가 (ref.read)
- `lessonsProvider`: 캘린더 새로고침 (ref.invalidate)

**사용 위젯**:
- `LessonStudentSelector`: 학생 선택
- `LessonDateTimeSection`: 날짜/시간 선택
- `LessonDurationSelector`: 시간 선택
- `LessonRecurringSection`: 정기 레슨
- `LessonContentFields`: 곡 이름, 메모
- `LessonReminderSection`: 리마인더

**라우트**: `/lessons/add?studentId=...&date=...&hour=...`

---

### 1.2 EditLessonScreen
**파일**: `frontend/lib/features/lessons/presentation/screens/edit_lesson_screen.dart`
**클래스**: `EditLessonScreen` (StatefulWidget)

**기능**:
- 기존 레슨 편집
- 레슨 취소 (PopupMenu)
- 레슨 삭제 (PopupMenu)
- 변경사항 추적 (_hasChanges)

**주요 상태**:
- `_isLoading`: 데이터 로딩
- `_hasChanges`: 변경 여부 추적 (저장 버튼 활성화/비활성화)

**사용 위젯**:
- `EditLessonStudentCard`: 읽기 전용 학생 정보
- `LessonDateTimeSection`: 날짜/시간 선택
- `LessonDurationSelector`: 시간 선택
- `LessonContentFields`: 곡 이름, 메모
- `LessonReminderSection`: 리마인더
- `LessonActionButtons`: 취소/삭제 버튼
- `showEditLessonExitConfirmation()`: 종료 확인

**라우트**: `/lessons/:id/edit`

---

### 1.3 LessonDetailScreen
**파일**: `frontend/lib/features/lessons/presentation/screens/lesson_detail_screen.dart`
**클래스**: `LessonDetailScreen` (ConsumerStatefulWidget)

**기능**:
- 레슨 상세 정보 표시
- 3개 탭: 레슨 노트, 녹음, 과제
- 선생님/학생 뷰 구분 (isTeacher 파라미터)
- 녹음 FAB (FloatingActionButton)
- 레슨 수정/취소/삭제 메뉴

**주요 상태**:
- `_tabController`: 탭 컨트롤러
- `_isRecording`, `_recordingSeconds`: 녹음 타이머

**사용 Provider**:
- `lessonProvider(widget.lessonId)`: 레슨 상세 데이터 (ref.watch)
- `lessonsNotifierProvider`: 레슨 수정/취소/삭제 (ref.read)

**탭 구성**:
1. **레슨 노트 탭**: 피드백, 주요 포인트, 연습 팁
   - `LessonNoteEditor`: 피드백 편집
   - `KeyPointsList`: 주요 포인트 목록
   - `PracticeTipsCard`: 연습 팁
   - `AddTipBottomSheet`: 팁 추가 다이얼로그

2. **녹음 탭**: 녹음 파일 목록, AI 요약
   - `LessonRecordingCard`: 녹음 카드
   - `AISummaryCard`: AI 요약

3. **과제 탭**: 연습 항목 목록
   - `PracticeItemsSection`: 연습 항목 (우선순위별)

**라우트**: `/lessons/:id`

---

## 2. 라우트 설정 (Router)

### 2.1 AppRoutes 상수
**파일**: `frontend/lib/core/router/app_routes.dart`

**Lesson 관련 경로**:
```
static const lessons = '/lessons';                      # 레슨 목록 (미사용)
static const addLesson = '/lessons/add';                # 레슨 추가
static const lessonDetail = '/lessons/:id';             # 레슨 상세
static const editLesson = '/lessons/:id/edit';          # 레슨 편집
```

---

### 2.2 LessonRoutes 설정
**파일**: `frontend/lib/core/router/routes/lesson_routes.dart`

```dart
GoRoute(
  path: '/lessons/add',
  builder: (context, state) {
    int? hour = int.tryParse(state.uri.queryParameters['hour'] ?? '');
    return AddLessonScreen(
      preselectedStudentId: state.uri.queryParameters['studentId'],
      preselectedDate: state.uri.queryParameters['date'],       // YYYY-MM-DD
      preselectedHour: hour,                                    // 0-23
    );
  },
),

GoRoute(
  path: '/lessons/:id',
  builder: (context, state) => LessonDetailScreen(
    lessonId: state.pathParameters['id'] ?? '',
  ),
),

GoRoute(
  path: '/lessons/:id/edit',
  builder: (context, state) => EditLessonScreen(
    lessonId: state.pathParameters['id'] ?? '',
  ),
),
```

---

## 3. Provider 구조

### 3.1 레슨 조회 Provider
**파일**: `frontend/lib/features/lessons/presentation/providers/lesson_crud_provider.dart`

```dart
// 모든 레슨
final lessonsProvider = FutureProvider<List<Lesson>>((ref) async)

// 단일 레슨
final lessonProvider = FutureProvider.family<Lesson?, String>((ref, id) async)

// 학생별 레슨
final lessonsByStudentProvider = FutureProvider.family<List<Lesson>, String>((ref, studentId) async)

// 날짜별 레슨
final lessonsByDateProvider = FutureProvider.family<List<Lesson>, DateTime>((ref, date) async)

// 다가오는 레슨 (최대 10개)
final upcomingLessonsProvider = FutureProvider<List<Lesson>>((ref) async)

// 최근 레슨 (최대 10개)
final recentLessonsProvider = FutureProvider<List<Lesson>>((ref) async)

// 오늘 레슨
final todayLessonsProvider = FutureProvider<List<Lesson>>((ref) async)
```

### 3.2 CRUD Notifier
**클래스**: `LessonsNotifier` (AsyncNotifier<List<Lesson>>)

**메서드**:
- `addLesson(Lesson lesson)`: 레슨 추가 → state 새로고침
- `updateLesson(Lesson lesson)`: 레슨 수정 → state 새로고침
- `deleteLesson(String id)`: 레슨 삭제 → state 새로고침
- `cancelLesson(String id)`: 레슨 취소 → state 새로고침
- `refresh()`: 강제 새로고침

```dart
final lessonsNotifierProvider = AsyncNotifierProvider<LessonsNotifier, List<Lesson>>(
  LessonsNotifier.new,
);
```

---

### 3.3 캘린더 Provider
**파일**: `frontend/lib/features/lessons/presentation/providers/lesson_calendar_provider.dart`

```dart
// 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now())

// 선택된 날짜의 레슨
final selectedDateLessonsProvider = FutureProvider<List<Lesson>>((ref) async)

// 캘린더 월
final calendarMonthProvider = StateProvider<DateTime>((ref) => DateTime(now.year, now.month, 1))

// 월별 레슨
final monthLessonsProvider = FutureProvider<List<Lesson>>((ref) async)

// 날짜별로 그룹화된 레슨 (월 뷰용)
final lessonsMapProvider = Provider<AsyncValue<Map<DateTime, List<Lesson>>>>((ref))

// 선택된 주의 시작일
final selectedWeekStartProvider = StateProvider<DateTime>((ref))

// 선택된 날짜 인덱스 (0 = Monday)
final selectedDayIndexProvider = StateProvider<int>((ref))

// 주별 레슨
final weekLessonsProvider = FutureProvider<List<Lesson>>((ref) async)

// 요일별로 그룹화된 레슨 (주 뷰용)
final weekLessonsMapProvider = Provider<AsyncValue<Map<int, List<Lesson>>>>((ref))
```

---

### 3.4 통계 Provider
**파일**: `frontend/lib/features/lessons/presentation/providers/lesson_stats_provider.dart`

```dart
final lessonStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref))
```

**반환 값**:
```dart
{
  'total': 전체 레슨 수,
  'scheduled': 예정된 레슨,
  'completed': 완료된 레슨,
  'thisWeek': 이번주 레슨,
  'today': 오늘 레슨,
}
```

---

### 3.5 결제 Provider
**파일**: `frontend/lib/features/lessons/presentation/providers/payment_providers.dart`

```dart
// 모든 결제
final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async)

// 단일 결제
final paymentProvider = FutureProvider.family<Payment?, String>((ref, paymentId) async)

// 학생별 결제
final studentPaymentsProvider = FutureProvider.family<List<Payment>, String>((ref, studentId) async)

// 상태별 결제
final paymentsByStatusProvider = FutureProvider.family<List<Payment>, PaymentStatus>((ref, status) async)

// 보류 중인 결제
final pendingPaymentsProvider = FutureProvider<List<Payment>>((ref) async)

// 연체 결제
final overduePaymentsProvider = FutureProvider<List<Payment>>((ref) async)

// 결제 요약
final paymentSummaryProvider = FutureProvider<PaymentSummary>((ref) async)

// 월별 결제 요약
final monthlyPaymentSummaryProvider = FutureProvider.family<PaymentSummary, ({int year, int month})>((ref, params) async)

// 학생별 수강료 설정
final tuitionSettingsProvider = FutureProvider.family<TuitionSettings?, String>((ref, studentId) async)
```

### 3.6 결제 Notifier
**클래스**: `PaymentsNotifier` (AsyncNotifier<List<Payment>>)

**메서드**:
- `addPayment(Payment payment)`: 결제 추가
- `updatePayment(Payment payment)`: 결제 수정
- `markAsCompleted(String paymentId)`: 결제 완료 (선생님 확인 2단계)
  → `studentsNotifierProvider` 업데이트: 학생 상태 → active
- `markStudentConfirmed(String paymentId)`: 학생 확인 (1단계)
- `cancelPayment(String paymentId)`: 결제 취소
- `deletePayment(String paymentId)`: 결제 삭제
- `refresh()`: 새로고침

```dart
final paymentsNotifierProvider = AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);
```

---

### 3.7 Repository Provider
**파일**: `frontend/lib/features/lessons/presentation/providers/lesson_repository_provider.dart`

```dart
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return MockLessonRepository();
});
```

---

## 4. Widget 구조

### 4.1 폼 위젯 (lesson_form/)

#### LessonStudentSelector
- 선택된 학생 표시
- Avatar + 이름 + 악기 + 현재곡
- Tap으로 학생 선택 시트 열기

#### LessonDateTimeSection
- 날짜 선택 (캘린더 피커)
- 시간 선택 (시간 피커, 24시간 형식)
- 각각 아이콘 + 텍스트로 표시

#### LessonDurationSelector
- ChoiceChip으로 시간 선택
- 프리셋: 30분, 45분, 1시간, 1시간 30분, 2시간

#### LessonRecurringSection
- Switch로 정기 레슨 ON/OFF
- ON 시: 7개 요일 선택 (월~일)
- Info 배너: "4주간의 레슨이 자동으로 예약됩니다"

#### LessonContentFields
- `pieceController`: 레슨 곡 (TextFormField)
- `notesController`: 메모 (TextFormField, 3줄)

#### LessonReminderSection
- Switch: 리마인더 활성화
- Dropdown: 리마인더 시간 (5분, 10분, 15분, 30분 등)

#### LessonStudentPicker
- BottomSheet로 학생 목록 표시
- 학생 선택 시 선택됨

---

### 4.2 레슨 상세 페이지 위젯 (lesson_detail/)

#### LessonHeaderCard
- Student/Teacher 정보
- Avatar + 이름 + 악기 + 상태 배지
- 날짜/시간 표시

#### LessonNoteEditor
- 피드백 편집 (TextFormField)

#### KeyPointsList
- 주요 포인트 목록
- 추가/삭제 기능 (선생님만)

#### PracticeTipsCard
- 연습 팁 표시
- 편집/삭제 기능

#### LessonRecordingCard
- 녹음 파일 카드
- 제목, 재생 시간, 날짜 표시

#### AISummaryCard
- AI 요약 텍스트 표시

---

### 4.3 보조 위젯

#### PracticeItemsSection
- 레슨에 할당된 연습 항목
- 우선순위별 그룹화 (High, Medium, Low)
- 추가/편집/삭제 기능

#### AddTipBottomSheet
- 팁 추가 다이얼로그
- 악기별 카테고리 선택

#### LessonConfirmationDialog
- 레슨 완료 여부 확인
- 미완료 사유 선택:
  - 학생 사정으로 불참 (횟수 차감)
  - 선생님 사정으로 취소 (횟수 유지)
  - 상호 합의로 취소 (횟수 유지)
- 메모 입력 (선택)

---

## 5. 헬퍼 함수

**파일**: `frontend/lib/features/lessons/presentation/widgets/lesson_form/lesson_form_helpers.dart`

```dart
String formatLessonTime(TimeOfDay time)               // HH:MM 형식

Future<DateTime?> selectLessonDate(context, initialDate)
  // 미래 날짜만 선택 (today ~ today+365일)

Future<TimeOfDay?> selectLessonTime(context, initialTime)
  // 24시간 형식

Future<DateTime?> selectLessonDateForEdit(context, initialDate)
  // 과거/미래 날짜 모두 선택 (today-365일 ~ today+365일)
```

---

## 6. 데이터 흐름

### 레슨 추가 흐름
```
AddLessonScreen
  ↓ _saveLesson()
  ├─ 1. 학생, 날짜 유효성 검사
  ├─ 2. Lesson 객체 생성 (LessonPiece 포함)
  ├─ 3. ref.read(lessonsNotifierProvider.notifier).addLesson(lesson)
  │   └─ LessonsNotifier.addLesson()
  │       ├─ repository.createLesson()
  │       └─ state = AsyncValue.data(updatedLessons)
  ├─ 4. ref.invalidate(lessonsProvider)  # 캘린더 새로고침
  └─ 5. context.pop() + SnackBar
```

### 레슨 상세 조회 흐름
```
LessonDetailScreen(lessonId)
  ↓ ref.watch(lessonProvider(lessonId))
  ├─ LessonRepository.getLesson(id)
  └─ AsyncValue.data(lesson)
     ├─ _buildContent()
     ├─ LessonHeaderCard(lesson)
     ├─ TabBar
     └─ TabBarView
       ├─ 탭 0: 노트 (LessonNoteEditor, KeyPointsList, PracticeTipsCard)
       ├─ 탭 1: 녹음 (LessonRecordingCard[], AISummaryCard)
       └─ 탭 2: 과제 (PracticeItemsSection)
```

---

## 7. 모델/타입

### Lesson
```dart
class Lesson {
  String id;
  String studentId;
  String studentName;
  String? teacherName;
  String instrument;
  DateTime date;
  String startTime;      // "HH:MM" 형식
  int duration;          // 분 단위
  LessonStatus status;   // scheduled, completed, cancelled, ...
  List<LessonPiece> pieces;
  String? feedback;      // 선생님 피드백
  List<String>? keyPoints;
  String? practiceTips;
  List<LessonRecording>? recordings;
  DateTime createdAt;
}
```

### LessonStatus
```dart
enum LessonStatus {
  scheduled,
  completed,
  studentAbsent,       // 학생 불참
  cancelledByTeacher,
  cancelledMutual,
  cancelled,
}
```

### Payment
```dart
class Payment {
  String id;
  String studentId;
  PaymentType type;        // trial, regular
  PaymentStatus status;    // pending, studentConfirmed, confirmed, cancelled
  int amount;
  bool studentConfirmed;
  DateTime? studentConfirmedAt;
  DateTime? paymentDate;
}
```

### LessonNonCompletionReason (enum)
```dart
enum LessonNonCompletionReason {
  studentAbsent,       // 횟수 차감
  teacherCancelled,    // 횟수 유지
  mutualCancelled,     // 횟수 유지
}
```

---

## 8. 주요 특징

### 원샷 UX 원칙 준수
- 레슨 추가 시 모든 정보 한 번에 입력
- 정기 레슨 4주 자동 생성

### 학생/선생님 뷰 구분
- `LessonDetailScreen(isTeacher: true/false)`로 뷰 변경
- 선생님: 노트 편집, 피드백 작성
- 학생: 선생님 피드백 읽기

### 유연한 레슨 관리
- 레슨 완료/미완료 선택
- 미완료 시 사유별 처리 (횟수 차감 여부)
- 취소/삭제/기록 수정

### 2단계 결제 확인
1. 학생 확인 (studentConfirmed)
2. 선생님 최종 확인 (status = confirmed)

---

## 9. 레거시 호환성

**re-export 위치**:
- `frontend/lib/models/lesson.dart`
- `frontend/lib/providers/lesson_providers.dart`
- `frontend/lib/repositories/lesson_repository.dart`

**새 코드 위치** (Clean Architecture):
- `frontend/lib/features/lessons/domain/entities/`
- `frontend/lib/features/lessons/presentation/providers/`
- `frontend/lib/features/lessons/data/repositories/`
