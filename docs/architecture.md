# 레슨 앱 아키텍처

> 마지막 업데이트: 2026-03-11

## 개요

레슨 앱은 **Clean Architecture** 원칙과 **Feature-based 구조**를 결합한 Flutter 앱입니다.

- **20개 feature 도메인**, features/ 내 약 696개 파일
- **10개 core 모듈**
- 레거시 re-export: models/ 30개, providers/ 46개, repositories/ 22개

> ⚠️ **프로젝트 구조 변경 (2026-02-02)**
> Flutter 코드는 `frontend/` 폴더 아래에 위치합니다.
> 문서의 `lib/` 경로는 `frontend/lib/`를 의미합니다.

---

## 핵심 원칙

### 1. Feature-First 구조
각 기능(feature)은 독립적인 모듈로 구성됩니다.

### 2. Clean Architecture 레이어
```
feature/
├── domain/        # 비즈니스 로직, 엔티티
│   ├── entities/  # 도메인 모델
│   └── repositories/  # Repository 인터페이스 (선택)
├── data/          # 데이터 레이어
│   └── repositories/  # Repository 구현체
└── presentation/  # UI 레이어
    ├── screens/   # 화면
    ├── widgets/   # 위젯
    └── providers/ # Riverpod Provider
```

### 3. Re-export 패턴
하위 호환성 유지를 위해 기존 위치에서 새 위치로 re-export 합니다.

---

## 폴더 구조

```
frontend/lib/
├── core/                    # 공통 유틸리티 (10개 모듈)
│   ├── audio/               # 오디오 엔진 (메트로놈, 녹음, 튜너)
│   ├── auth/                # 인증 공통 로직
│   ├── config/              # 앱 설정/환경 구성
│   ├── constants/           # 앱 전역 상수
│   ├── models/              # 공유 enum (AgeGroup, ConnectionStatus)
│   ├── network/             # 네트워크/API 공통 레이어
│   ├── router/              # GoRouter 설정
│   │   ├── app_router.dart  # 메인 라우터 (import만)
│   │   ├── app_routes.dart  # 라우트 상수
│   │   └── routes/          # 도메인별 라우트
│   ├── theme/               # AppColors, AppTypography
│   ├── utils/               # 공통 유틸리티 함수
│   └── widgets/             # 공통 재사용 위젯 (Selectors, StatCard 등)
│
├── features/                # 기능별 모듈 (20개 도메인)
│   ├── analytics/           # 분석 대시보드
│   ├── auth/                # 인증
│   ├── calendar/            # 캘린더
│   ├── follow/              # 팔로우/연결
│   ├── gamification/        # 게이미피케이션
│   ├── home/                # 선생님 홈
│   ├── invite/              # 초대
│   ├── lessons/             # 레슨 관리
│   ├── notifications/       # 알림
│   ├── onboarding/          # 온보딩
│   ├── parent_home/         # 학부모 홈
│   ├── practice/            # 연습 관리
│   ├── profile/             # 프로필
│   ├── relationship/        # 선생님-학생 관계
│   ├── schedule/            # 스케줄
│   ├── search/              # 선생님 검색
│   ├── settings/            # 앱 설정
│   ├── student_home/        # 학생 홈
│   ├── students/            # 학생 관리
│   └── subscription/        # 수강권/결제
│
├── models/                  # 레거시 모델 (re-export, 30개 파일)
├── providers/               # 레거시 Provider (re-export, 46개 파일)
├── repositories/            # 레거시 Repository (re-export, 22개 파일)
└── services/                # 서비스 레이어
```

---

## Feature별 상세 구조

### analytics (분석 대시보드)
선생님 월별 통계, 수입/레슨 차트, 학생 연습률 랭킹을 제공하는 분석 대시보드.
- 주요 화면: `AnalyticsDashboardScreen`
- 주요 엔티티: 월별 통계, 수입 데이터, 연습률 랭킹

### auth (인증)
Google SSO 기반 로그인, 역할 선택(선생님/학생/학부모) 처리.
- 주요 화면: `LoginScreen`, `RoleSelectionScreen`
- 주요 Provider: `userRoleProvider`, `authStateProvider`

### calendar (캘린더)
월간/주간 캘린더 뷰로 레슨 일정을 시각화.
- 주요 화면: `CalendarScreen`
- 레슨/스케줄 데이터를 캘린더 형식으로 표시

### follow (팔로우/연결)
선생님-학생 간 팔로우/연결 관계 요청 및 승인 관리.
- 주요 엔티티: `FollowRequest`, `FollowStatus`
- 연결 요청 발송, 수락/거절 처리

### gamification (게이미피케이션)
연습/레슨 활동에 대한 포인트 적립, 레벨업, 뱃지 획득 시스템.
- 주요 화면: `GamificationDashboardScreen`
- 주요 엔티티: `UserPoints`, `Level`, `Badge`, `Achievement`

### home (선생님 홈)
선생님 메인 대시보드. 오늘 레슨, 빠른 도구, 학생 현황 요약 표시.
- 주요 화면: `DashboardTab`
- 탭 기반 네비게이션의 진입점

### invite (초대)
선생님이 학생/학부모에게 초대 코드를 발송하고 확인하는 기능.
- 주요 엔티티: `Invite`, `InviteCode`
- 초대 링크 생성, 코드 검증

### lessons (레슨)
```
features/lessons/
├── domain/
│   └── entities/
│       ├── lesson.dart
│       ├── payment.dart
│       └── tip_template.dart
├── data/
│   └── repositories/
│       └── mock_lesson_repository.dart
└── presentation/
    ├── screens/
    ├── widgets/
    │   ├── lesson_detail/   # 분할된 위젯
    │   └── section_detail/
    └── providers/
        ├── lesson_providers.dart
        ├── lesson_crud_provider.dart
        ├── payment_providers.dart
        ├── booking_providers.dart
        └── tip_template_providers.dart
```

### notifications (알림)
앱 내 알림 센터. 레슨/연습/결제 관련 알림 수신 및 읽음 처리.
- 주요 엔티티: `Notification`, `NotificationSettings`
- 주요 Provider: `notificationProviders`

### onboarding (온보딩)
신규 사용자 회원가입 플로우. 역할별 프로필 설정, 악기 선택 등.
- 주요 화면: `OnboardingScreen`, `ProfileSetupScreen`
- 역할(선생님/학생/학부모)에 따른 분기 처리

### parent_home (학부모)
```
features/parent_home/
├── domain/
│   └── entities/
│       ├── parent.dart
│       ├── parent_child_relation.dart
│       └── parent_notification_settings.dart
└── presentation/
    ├── screens/
    └── providers/
        ├── parent_providers.dart
        ├── child_profile_provider.dart
        └── user_profile_provider.dart
```

### practice (연습)
```
features/practice/
├── domain/
│   └── entities/
│       ├── practice_task.dart
│       ├── practice_log.dart
│       ├── practice_streak.dart
│       ├── practice_repertoire.dart
│       └── recording.dart
├── data/
│   └── repositories/
│       └── mock_practice_repository.dart
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/
        ├── practice_providers.dart
        ├── practice_crud_provider.dart
        ├── practice_streak_provider.dart
        ├── practice_item_providers.dart
        ├── practice_repertoire_providers.dart
        ├── metronome_provider.dart
        ├── recording_provider.dart
        └── smart_recording_provider.dart
```

### profile (프로필)
```
features/profile/
├── domain/
│   └── entities/
│       ├── invite.dart
│       └── review.dart
└── presentation/
    ├── screens/
    └── providers/
        ├── invite_provider.dart
        └── teacher_extended_profile_provider.dart
```

### relationship (선생님-학생 관계)
선생님-학생 연결 상태 관리. 관계 생성/해제, 상태 조회.
- 주요 엔티티: `Relationship`, `ConnectionStatus`
- 학생 목록과 연결 상태 동기화

### schedule (스케줄)
레슨 스케줄 관리, 예약/취소, 그룹수업 시간표, 가용 시간 설정.
- 주요 화면: `ScheduleTab`, `AvailabilityScreen`
- 주요 엔티티: `ScheduleCard`, `AvailabilityBlock`, `GroupLesson`

### search (선생님 검색)
학생/학부모가 선생님을 검색하고 필터링하는 기능.
- 주요 화면: `TeacherSearchScreen`
- 악기, 지역, 레슨 유형 등 필터 지원

### settings (앱 설정)
앱 환경설정, 데이터 백업/복원, 녹음 파일 관리.
- 주요 화면: `SettingsScreen`
- 백업, 알림 설정, 녹음 저장소 관리

### student_home (학생 홈)
학생 메인 대시보드. 연습 현황, 다음 레슨, 체험 레슨 신청 등.
- 주요 화면: `StudentDashboardTab`
- 연습 통계, 과제 목록, 게이미피케이션 위젯 포함

### students (학생 관리)
```
features/students/
├── domain/
│   └── entities/
│       ├── student.dart
│       ├── lesson_class.dart          # 클래스/소속 그룹 (학원/개인)
│       ├── class_membership.dart      # 학생-클래스 관계 (레슨 정보)
│       └── lesson_location.dart       # 레슨 장소
├── data/
│   └── repositories/
│       ├── mock_student_repository.dart
│       ├── mock_lesson_class_repository.dart
│       └── mock_membership_repository.dart
└── presentation/
    ├── screens/
    ├── widgets/
    │   └── student_detail/  # 분할된 위젯
    └── providers/
        ├── student_providers.dart
        ├── student_crud_provider.dart
        ├── student_stats_provider.dart
        ├── lesson_class_providers.dart
        └── membership_providers.dart
```

> 📐 **엔티티 설계**: [docs/specs/student/student_class_system.md](specs/student/student_class_system.md) 참조

### subscription (수강권/결제)
수강권 생성/관리, 결제 기록, 선생님 제안 기능.
- 주요 엔티티: `Subscription`, `SubscriptionPlan`, `Payment`
- 수강권 유효기간, 잔여 횟수 추적

---

## Provider 구조

### Provider 위치 규칙
| 타입 | 위치 | 예시 |
|------|------|------|
| Feature UI 상태 | `features/[domain]/presentation/providers/` | lesson_providers.dart |
| 공유 상태 | `features/auth/presentation/providers/` | user_role_provider.dart |
| 레거시 (re-export) | `frontend/lib/providers/[domain]/` | → feature로 연결 |

### Provider 네이밍 규칙
```
[domain]_repository_provider.dart   # Repository 인스턴스
[domain]_providers.dart             # Query Provider 모음
[domain]_crud_provider.dart         # CRUD Notifier
[domain]_[action]_provider.dart     # 특정 기능 (stats, calendar 등)
```

### @riverpod 어노테이션 사용
```dart
// 읽기 전용 Provider
@riverpod
Future<List<Lesson>> allLessons(Ref ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getAllLessons();
}

// 상태 관리 Notifier
@riverpod
class LessonsNotifier extends _$LessonsNotifier {
  @override
  Future<List<Lesson>> build() async { ... }

  Future<void> addLesson(Lesson lesson) async { ... }
}
```

---

## 모델 위치

### 도메인 엔티티 (권장)
```
features/[domain]/domain/entities/[model].dart
```

### 공유 타입
```
frontend/lib/core/models/shared_enums.dart  # AgeGroup, ConnectionStatus 등
```

### 레거시 모델 (re-export)
```dart
// frontend/lib/models/lesson.dart
export '../features/lessons/domain/entities/lesson.dart';
```

---

## Repository 패턴

### 구조
```
features/[domain]/
├── domain/repositories/
│   └── [domain]_repository.dart      # 인터페이스 (추상)
└── data/repositories/
    └── mock_[domain]_repository.dart # Mock 구현
```

### 예시
```dart
// domain/repositories/lesson_repository.dart
abstract class LessonRepository {
  Future<List<Lesson>> getAllLessons();
  Future<Lesson?> getLessonById(String id);
  Future<Lesson> createLesson(Lesson lesson);
}

// data/repositories/mock_lesson_repository.dart
class MockLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> getAllLessons() async { ... }
}
```

---

## 라우팅 구조

### 중앙 라우터
```
frontend/lib/core/router/
├── app_router.dart      # ShellRoute + import 조합
├── app_routes.dart      # 라우트 경로 상수
└── routes/
    ├── auth_routes.dart
    ├── home_routes.dart
    ├── lesson_routes.dart
    ├── practice_routes.dart
    └── ...
```

### 라우트 추가 방법
1. `routes/[domain]_routes.dart`에 라우트 추가
2. `app_router.dart`에 import 확인
3. 필요시 `app_routes.dart`에 경로 상수 추가

---

## 코드 생성

### build_runner 사용
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 코드 생성 대상
| 패키지 | 파일 | 용도 |
|--------|------|------|
| riverpod_generator | *.g.dart | Provider 생성 |
| json_serializable | *.g.dart | JSON 직렬화 |
| hive_generator | *.g.dart | Hive TypeAdapter |

---

## 위젯 분할 규칙

### 대형 스크린 분할
800줄 이상 스크린은 하위 위젯으로 분할:
```
widgets/[screen_name]/
├── [widget1].dart
├── [widget2].dart
└── [screen_name]_widgets.dart  # barrel file
```

### 예시
```
widgets/lesson_detail/
├── lesson_header_card.dart
├── lesson_recording_card.dart
├── add_tip_bottom_sheet.dart
└── lesson_detail_widgets.dart
```

---

## 하위 호환성

### Re-export 패턴
기존 import를 유지하면서 새 위치로 이동:

```dart
// frontend/lib/models/student.dart (기존 위치)
export '../features/students/domain/entities/student.dart';

// frontend/lib/providers/lesson/lesson_providers.dart (기존 위치)
export '../../features/lessons/presentation/providers/lesson_providers.dart';
```

### 점진적 마이그레이션
1. 새 위치에 파일 생성
2. 기존 위치에 re-export 설정
3. 새 코드는 새 위치에서 import
4. 레거시 import도 동작 유지

---

## Claude 작업 가이드

### 새 기능 추가 시
1. 해당 feature 폴더 확인
2. domain/entities에 모델 추가 (필요시)
3. presentation/providers에 Provider 추가
4. presentation/screens에 화면 추가
5. core/router/routes에 라우트 추가

### Provider 추가 시
1. `frontend/lib/features/[domain]/presentation/providers/` 에 생성
2. `@riverpod` 어노테이션 사용
3. `cd frontend && dart run build_runner build` 실행
4. 기존 호환성 필요시 `frontend/lib/providers/`에 re-export

### 모델 추가 시
1. `frontend/lib/features/[domain]/domain/entities/` 에 생성
2. 공유 타입은 `frontend/lib/core/models/`
3. JSON 직렬화 필요시 `@JsonSerializable()` 추가
4. `dart run build_runner build` 실행

---

## 참고 문서

- [리팩토링 태스크](refactoring_tasks.md) - 진행 현황
- [docs/README.md](README.md) - 문서 인덱스
- [CLAUDE.md](../CLAUDE.md) - 프로젝트 가이드
