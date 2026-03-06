# Student Home Dashboard Master Spec

> Last updated: 2026-03-06

## 1. 개요

학생(Student) 역할 사용자의 메인 홈 화면. 마치 학생 수첩처럼, 다음 레슨 일정, 수강권 현황, 연습 기록, 선생님 피드백 등 학습에 필요한 모든 정보를 한 곳에서 확인할 수 있다. 하단 네비게이션 바로 4개 탭(홈, 스케줄, 연습, 프로필)을 전환한다.

## 2. 핵심 기능

### 2.1 메인 화면 (StudentHomeScreen)

- `IndexedStack` 기반 4탭 구조 (탭 전환 시 상태 유지)
- 진입 시 자동으로 `UserRole.student`로 역할 전환
- 시작 시 녹음 파일 복구 결과 SnackBar 표시 (recovered/cleanedUp 건수)
- `DebugWrapper`로 디버그 역할 전환 지원

**하단 네비게이션:**

| 인덱스 | 아이콘 | 라벨 | 탭 |
|--------|--------|------|----|
| 0 | home | 홈 | StudentDashboardTab |
| 1 | calendar_today | 스케줄 | StudentLessonsTab |
| (중앙) | - | - | PracticeCenterButton (연습 도구) |
| 2 | fitness_center | 연습 | StudentPracticeTab |
| 3 | person | 프로필 | StudentProfileTab |

### 2.2 대시보드 탭 (StudentDashboardTab)

스크롤 가능한 단일 페이지에 7개 섹션을 순서대로 배치:

#### 섹션 1: 헤더
- 날짜 표시 (`M월 d일 EEEE` 형식)
- "오늘도 화이팅!" 인사 메시지
- 선생님 초대 버튼 + 알림 버튼

#### 섹션 2: 액션 필요 배너
- **수강권 제안 배너**: 선생님이 보낸 수강권 제안이 있을 때 warning 색상 배너 표시
  - 1건: 해당 제안 상세 화면으로 이동
  - 2건 이상: 알림 화면으로 이동
  - 자동 제안: 할인 혜택 문구 / 수동 제안: 선생님 메시지 표시
- **레슨 요청 배너**: 활성 레슨 요청 상태 표시
  - 수강권 제안 도착: success 색상 + gift 아이콘
  - 대기 중: info 색상 + 모래시계 아이콘

#### 섹션 3: 다음 레슨 카드
- 가장 가까운 예정 레슨을 gradient 카드로 강조 표시
- D-Day 표시 (오늘/내일/D-N)
- 선생님명, 악기, 날짜/시간, 레슨 시간(분), 레슨 유형(정기/체험)
- 레슨 없을 시: "선생님 찾기" 버튼이 있는 빈 상태

#### 섹션 4: 수강권 요약 (StudentSubscriptionSummary)
- 활성 멤버십별 수강권 미니 카드 표시
- 레슨 클래스 아이콘 (학원: 🏫, 개인: 👤)
- 수강권 상태 배지 (정상: success, 곧 만료: warning, 만료: error, 미등록: tertiary)
- "전체 보기" 버튼 -> 수강권 목록 화면

#### 섹션 5: 체험 레슨 (TrialBookingsSection)
- 활성 체험 레슨 예약 최대 2개 표시
- `CompactTrialBookingCard`: 선생님 아바타, 이름, 악기, 시간, 상태 배지
- 빈 상태: "체험레슨 신청" 버튼
- 3개 이상일 때 "더보기" 버튼

#### 섹션 6: 연습 요약
- 3개 통계 카드: 연속 연습일, 이번 주 총 시간, 목표 달성률
- 주간 바 차트: 요일별 연습 진행률 (색상: good/normal/poor/미래)
- "상세 보기" -> 연습 통계 화면

#### 섹션 7: 선생님 피드백
- 최근 1개 피드백 카드 (선생님 아바타, 이름, 날짜, 내용, 태그)
- "더보기" 버튼 (TODO)

### 2.3 스케줄 탭 (StudentLessonsTab)

- 주간 캘린더 (`WeekCalendarWidget`) + 날짜별 레슨 목록
- 정기 레슨과 체험 레슨(booking) 통합 표시
- 날짜 헤더: 날짜 + "오늘" 배지 + 레슨 개수 + 정렬 드롭다운
- 정렬: 시간순 / 이름순 (`LessonSortType`)
- 레슨 카드 (`StudentLessonCard`): 시간, 선생님명, 악기, 장소, 곡 정보, D-Day 배지
- 체험 레슨 카드 (`TrialBookingCard`): 상태 배지, 시간, 변경 요청, 액션 버튼
- 빈 상태: "선생님 찾기" 버튼
- 헤더: "예약" 버튼 -> 선생님 검색

### 2.4 연습 탭 (StudentPracticeTab)

- 주간 캘린더 + 날짜별 레퍼토리 목록
- 연습된 날짜에 별도 표시 (`practicedDates`)
- 레퍼토리 카드 (`_RepertoireCard`):
  - 접기/펼치기 지원
  - 레퍼토리명, 기간, 섹션 추가 버튼
  - 섹션 타일: 체크박스(오늘만), 곡명, 범위, 반복 토글(오늘만), 상세 이동
- 정렬: 생성일 내림차순/오름차순, 이름순 (custom 제외)
- "레퍼토리 추가" 버튼, "히스토리" 버튼

### 2.5 프로필 탭 (StudentProfileTab)

**프로필 헤더:**
- gradient 배경 (primary -> primaryDark)
- 프로필 이미지 (현재 하드코딩: "홍길동"), 이메일, 악기 태그

**통계 요약:**
- 레슨 받은 횟수 / 총 연습 시간 / 레슨 기간 (현재 하드코딩)

**메뉴 항목:**
| 메뉴 | 동작 |
|------|------|
| 프로필 수정 | TODO |
| 내 선생님 | TODO |
| 레퍼토리 | TODO |
| 연습 기록 내역 | TODO |
| 레슨 녹음 파일 | 전체 녹음 관리 화면 이동 |
| 학부모 초대 | 초대 코드 다이얼로그 |

**설정 항목:**
| 설정 | 동작 |
|------|------|
| 알림 설정 | Switch (TODO) |
| 연습 리마인더 | TODO |
| 다크 모드 | Switch (TODO) |
| 언어 | TODO |
| 녹음 백업 | 백업 설정 화면 이동 |
| 도움말 | TODO |
| 앱 정보 | TODO |

**학부모 초대 기능:**
- 6자리 영숫자 초대 코드 자동 생성
- `ParentInvitation` 엔티티 생성 및 저장
- 24시간 유효
- 코드 복사/공유(share_plus) 기능

**로그아웃:**
- 확인 다이얼로그 후 로그인 화면으로 이동

## 3. 화면/UI 구조

```
StudentHomeScreen
├── BottomNavigationBar (5개 항목, 중앙 PracticeCenterButton)
└── IndexedStack
    ├── [0] StudentDashboardTab
    │   ├── 헤더 (날짜 + 인사 + 초대/알림 버튼)
    │   ├── 수강권 제안 배너
    │   ├── 레슨 요청 배너
    │   ├── 다음 레슨 카드 (gradient)
    │   ├── StudentSubscriptionSummary
    │   ├── TrialBookingsSection
    │   ├── 연습 요약 (통계 + 주간 차트)
    │   └── 선생님 피드백
    │
    ├── [1] StudentLessonsTab
    │   ├── 헤더 ("스케줄" + 예약 버튼)
    │   ├── WeekCalendarWidget
    │   ├── 날짜 헤더 + 정렬
    │   └── 레슨 목록 (StudentLessonCard + TrialBookingCard)
    │
    ├── [2] StudentPracticeTab
    │   ├── 헤더 ("내 연습" + 히스토리/추가 버튼)
    │   ├── WeekCalendarWidget (practicedDates)
    │   ├── 날짜 헤더 + 정렬
    │   └── 레퍼토리 목록 (_RepertoireCard -> _SectionTile)
    │
    └── [3] StudentProfileTab
        ├── 프로필 헤더 (gradient)
        ├── 통계 요약
        ├── 메뉴 섹션
        ├── 설정 섹션
        └── 로그아웃 버튼
```

## 4. 데이터 모델

### StudentTab (enum)

| 값 | 인덱스 | 라벨 |
|----|--------|------|
| `home` | 0 | 홈 |
| `lessons` | 1 | 레슨 |
| `practice` | 2 | 연습 |
| `profile` | 3 | 프로필 |

### WeeklyPracticeStatus

| 필드 | 타입 | 설명 |
|------|------|------|
| `dayLabels` | `List<String>` | 요일 라벨 (월~일) |
| `progress` | `List<double>` | 요일별 진행률 (0.0~1.0) |
| `todayIndex` | `int` | 오늘 인덱스 |
| `practicedDays` | `int` | 연습한 일수 |
| `totalPracticeTime` | `Duration` | 총 연습 시간 |
| `achievementRate` | `double` | 달성률 |

### TeacherFeedback

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | `String` | 피드백 ID |
| `teacherName` | `String` | 선생님 이름 |
| `teacherInitial` | `String` | 선생님 이니셜 |
| `feedbackDate` | `DateTime` | 피드백 날짜 |
| `content` | `String` | 피드백 내용 |
| `tags` | `List<String>` | 태그 목록 |

### NextLessonInfo

| 필드 | 타입 | 설명 |
|------|------|------|
| `teacherName` | `String` | 선생님 이름 |
| `teacherInitial` | `String` | 선생님 이니셜 |
| `instrument` | `String` | 악기 |
| `lessonDate` | `DateTime` | 레슨 날짜 |
| `daysUntil` | `int` | 남은 일수 |

### 주요 Providers

| Provider | 설명 |
|----------|------|
| `currentUserIdProvider` | 현재 로그인 학생 ID |
| `currentUserRoleProvider` | 현재 사용자 역할 |
| `studentBookingsProvider(studentId)` | 학생 예약 목록 |
| `studentLessonRequestsProvider(studentId)` | 학생 레슨 요청 |
| `pendingStudentProposalsProvider(studentId)` | 대기 중인 수강권 제안 |
| `activeStudentMembershipsProvider(studentId)` | 활성 멤버십 |
| `activeStudentSubscriptionsProvider(studentId)` | 활성 수강권 |
| `lessonsProvider` | 전체 레슨 목록 |
| `repertoiresForDateProvider` | 날짜별 레퍼토리 |
| `studentRepertoiresProvider(studentId)` | 학생 전체 레퍼토리 |
| `studentSelectedDateProvider` | 스케줄 탭 선택 날짜 |
| `studentLessonSortTypeProvider` | 레슨 정렬 타입 |
| `repertoireSortTypeProvider` | 레퍼토리 정렬 타입 |
| `weeklyPracticeItemsProvider(studentId)` | 주간 연습 항목 |
| `sectionCrudProvider` | 섹션 CRUD 조작 |
| `invitationsNotifierProvider(studentId)` | 학부모 초대 관리 |

### 사용하는 외부 엔티티

- `Lesson` / `LessonStatus` - 레슨 정보 및 상태
- `LessonBooking` / `LessonType` - 레슨 예약 (정기/체험)
- `PracticeRepertoire` / `PracticeSection` - 연습 레퍼토리 및 섹션
- `PracticeItem` / `PracticeType` / `PracticePriority` - 연습 항목
- `Subscription` / `SubscriptionStatus` - 수강권
- `ClassMembership` / `LessonClass` - 멤버십 및 레슨 클래스
- `LessonRequest` / `LessonRequestStatus` - 레슨 요청
- `ParentInvitation` / `InvitationSource` - 학부모 초대

## 5. 구현 현황

| 기능 | 상태 |
|------|------|
| 4탭 네비게이션 + 중앙 연습 버튼 | 구현 완료 |
| 대시보드 헤더 | 구현 완료 |
| 수강권 제안 배너 | 구현 완료 |
| 레슨 요청 배너 | 구현 완료 |
| 다음 레슨 카드 | 구현 완료 |
| 수강권 요약 위젯 | 구현 완료 |
| 체험 레슨 섹션 | 구현 완료 |
| 연습 요약 (통계 + 차트) | 구현 완료 (하드코딩 데이터) |
| 선생님 피드백 | 구현 완료 (하드코딩 데이터) |
| 스케줄 탭 (주간 캘린더 + 레슨) | 구현 완료 |
| 레슨 카드 (정기 + 체험) | 구현 완료 |
| 연습 탭 (캘린더 + 레퍼토리) | 구현 완료 |
| 섹션 완료 토글 | 구현 완료 |
| 섹션 반복 토글 | 구현 완료 |
| 프로필 헤더 | 구현 완료 (하드코딩) |
| 프로필 통계 | 구현 완료 (하드코딩) |
| 학부모 초대 코드 | 구현 완료 |
| 녹음 파일 관리 이동 | 구현 완료 |
| 녹음 백업 설정 이동 | 구현 완료 |
| 로그아웃 | 구현 완료 |
| 프로필 수정 | 미구현 (TODO) |
| 내 선생님 상세 | 미구현 (TODO) |
| 피드백 전체 보기 | 미구현 (TODO) |
| 실제 연습 통계 연동 | 미구현 (하드코딩) |
| 실제 프로필 데이터 연동 | 미구현 (하드코딩) |
| 알림/리마인더 설정 | 미구현 (TODO) |
| 다크 모드 | 미구현 (TODO) |
| 언어 설정 | 미구현 (TODO) |

## 6. 관련 스펙

- `docs/specs/calendar/calendar_master.md` - 선생님 캘린더 (유사 구조)
- `docs/specs/design/ux_guidelines.md` - UX 가이드라인
- `core/widgets/week_calendar_widget.dart` - 공통 주간 캘린더 위젯
- `core/widgets/practice_center_button.dart` - 중앙 연습 버튼
- `features/subscription/` - 수강권 도메인
- `features/practice/` - 연습 도메인
- `features/schedule/` - 스케줄/예약 도메인
- `features/students/` - 학생/멤버십 도메인

## 7. 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-06 | 기존 구현 기반 스펙 문서 생성 (역공학) |
