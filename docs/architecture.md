# 레슨 앱 아키텍처

> 마지막 업데이트: 2026-01-24

## 개요

레슨 앱은 **Clean Architecture** 원칙과 **Feature-based 구조**를 결합한 Flutter 앱입니다.

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
lib/
├── core/                    # 공통 유틸리티
│   ├── audio/               # 오디오 엔진 (메트로놈, 녹음)
│   ├── models/              # 공유 enum (AgeGroup, ConnectionStatus)
│   ├── router/              # GoRouter 설정
│   │   ├── app_router.dart  # 메인 라우터 (import만)
│   │   ├── app_routes.dart  # 라우트 상수
│   │   └── routes/          # 도메인별 라우트
│   └── theme/               # AppColors, AppTypography
│
├── features/                # 기능별 모듈
│   ├── auth/                # 인증
│   ├── home/                # 선생님 홈
│   ├── student_home/        # 학생 홈
│   ├── parent_home/         # 학부모 홈
│   ├── lessons/             # 레슨 관리
│   ├── students/            # 학생 관리
│   ├── practice/            # 연습 관리
│   ├── profile/             # 프로필
│   ├── schedule/            # 스케줄
│   ├── search/              # 선생님 검색
│   ├── onboarding/          # 온보딩
│   ├── notifications/       # 알림
│   ├── calendar/            # 캘린더
│   └── invite/              # 초대
│
├── models/                  # 레거시 모델 (re-export)
├── providers/               # 레거시 Provider (re-export)
├── repositories/            # 레거시 Repository (re-export)
└── services/                # 서비스 레이어
```

---

## Feature별 상세 구조

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

### students (학생)
```
features/students/
├── domain/
│   └── entities/
│       ├── student.dart
│       ├── lesson_class.dart          # 🆕 클래스/소속 그룹 (학원/개인)
│       ├── class_membership.dart      # 🆕 학생-클래스 관계 (레슨 정보)
│       └── lesson_location.dart       # 🆕 레슨 장소
├── data/
│   └── repositories/
│       ├── mock_student_repository.dart
│       ├── mock_lesson_class_repository.dart    # 🆕
│       └── mock_membership_repository.dart      # 🆕
└── presentation/
    ├── screens/
    ├── widgets/
    │   └── student_detail/  # 분할된 위젯
    └── providers/
        ├── student_providers.dart
        ├── student_crud_provider.dart
        ├── student_stats_provider.dart
        ├── lesson_class_providers.dart          # 🆕
        └── membership_providers.dart            # 🆕
```

> 📐 **엔티티 설계**: [docs/specs/student/student_class_system.md](specs/student/student_class_system.md) 참조

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

### notifications (알림)
```
features/notifications/
├── domain/
│   └── entities/
│       ├── notification.dart
│       └── notification_settings.dart
└── presentation/
    └── providers/
        └── notification_providers.dart
```

---

## Provider 구조

### Provider 위치 규칙
| 타입 | 위치 | 예시 |
|------|------|------|
| Feature UI 상태 | `features/[domain]/presentation/providers/` | lesson_providers.dart |
| 공유 상태 | `features/auth/presentation/providers/` | user_role_provider.dart |
| 레거시 (re-export) | `lib/providers/[domain]/` | → feature로 연결 |

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
lib/core/models/shared_enums.dart  # AgeGroup, ConnectionStatus 등
```

### 레거시 모델 (re-export)
```dart
// lib/models/lesson.dart
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
lib/core/router/
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
// lib/models/student.dart (기존 위치)
export '../features/students/domain/entities/student.dart';

// lib/providers/lesson/lesson_providers.dart (기존 위치)
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
1. `features/[domain]/presentation/providers/` 에 생성
2. `@riverpod` 어노테이션 사용
3. `dart run build_runner build` 실행
4. 기존 호환성 필요시 `lib/providers/`에 re-export

### 모델 추가 시
1. `features/[domain]/domain/entities/` 에 생성
2. 공유 타입은 `lib/core/models/`
3. JSON 직렬화 필요시 `@JsonSerializable()` 추가
4. `dart run build_runner build` 실행

---

## 참고 문서

- [리팩토링 태스크](refactoring_tasks.md) - 진행 현황
- [docs/README.md](README.md) - 문서 인덱스
- [CLAUDE.md](../CLAUDE.md) - 프로젝트 가이드
