# 레슨 앱 아키텍처

> 마지막 업데이트: 2026-05-02

## 개요

> **전방동기화 (Discipline 전환, 2026-06-26)**: 현재 20 도메인은 음악 전용 전제(Discipline 0). 멀티 Discipline 3계층(무관 코어 / 추상 슬롯 / 분야 구현) + Registry 추상화는 `36-멀티카테고리-Discipline-플랫폼-설계`(옵시디언) 설계 단계이며 **미구현**. 신규 도메인/추상 추가 시 `docs/SPEC_ROUTING.md` §0 + 36- Phase 매핑 확인 후 진행. 아래 디렉토리 매핑·도메인 건강도 표는 현행 음악 기준 유지.

레슨 앱은 **Clean Architecture** 원칙과 **Feature-based 구조**를 결합한 Flutter 앱입니다.

- **20개 feature 도메인**, features/ 내 **870개** 파일
- **14개 core 모듈** (booking Shared Kernel, l10n, providers, services 포함)
- 레거시 디렉토리 0개 (models/, providers/, repositories/, services/, shared/ 모두 제거 완료)

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

### 3. Shared Kernel (core/booking/)
schedule ↔ lessons 간 공유 타입(LessonBooking, TimeSlot, BookingRepository)은
`core/booking/`에 위치하여 순환 의존을 방지합니다.

### 4. Facade 패턴
- `features/booking/booking_facade.dart` — Booking API 단일 진입점
- `features/subscription/subscription_facade.dart` — Subscription API 단일 진입점

---

## 폴더 구조

```
frontend/lib/
├── core/                    # 공통 유틸리티 (14개 모듈)
│   ├── audio/               # 오디오 엔진 (메트로놈, 녹음, 튜너, 스토리지)
│   ├── booking/             # Shared Kernel (LessonBooking, TimeSlot)
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
│   ├── l10n/                # 다국어 문자열 (AppStrings)
│   ├── providers/           # 코어 Provider
│   ├── services/            # 코어 서비스 레이어
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
├── main.dart
└── firebase_options.dart
```

---

## 도메인 건강도 매트릭스 (2026-05-02)

### 프론트엔드 20개 도메인

| 도메인 | 파일 | 화면 | Provider | Repository | 백엔드 | 비고 |
|--------|:----:|:----:|:--------:|:----------:|:------:|------|
| **practice** | 176 | 16 | 39 | M5+R4 | ✅ | 최대 도메인, mixin 패턴 |
| **schedule** | 113 | 17 | 10 | M4+R4 | ✅ | +services, +utils |
| **subscription** | 99 | 14 | 10 | M6+R6 | ✅ | Facade 패턴 |
| **lessons** | 94 | 7 | 21 | M3+R3 | ✅ | +services, +constants |
| **students** | 86 | 5 | 20 | M4+R4 | ✅ | +services |
| profile | 51 | 15 | 9 | — | ✅ | cross-domain repo (onboarding, invite) |
| student_home | 42 | 8 | 6 | M+R | ✅ | |
| parent_home | 38 | 3 | 7 | R | ✅ | |
| gamification | 24 | 1 | 8 | M+R | ✅ | Phase 1-3 완료 |
| follow | 21 | 2 | 4 | M2+R2 | ✅ | Phase 2 부분 완료 |
| notifications | 21 | 1 | 4 | R | ✅ | Remote 전용 (Mock 없음) |
| auth | 20 | 5 | 3 | R | ✅ | |
| settings | 15 | 3 | 6 | R | ✅ | |
| home | 14 | 2 | 1 | — | — | UI 전용 (공유 서비스 사용) |
| search | 13 | 3 | 3 | R2 | ✅ | |
| onboarding | 12 | 5 | 3 | R | ✅ | |
| relationship | 11 | 0 | 2 | M+R | ✅ | 데이터 전용 (화면 없음) |
| analytics | 10 | 1 | 2 | M+R | ✅ | |
| invite | 9 | 7 | 0 | R | ✅ | |
| booking | 1 | 0 | 0 | — | — | Facade 전용 (core/booking/) |

> **M** = Mock, **R** = Remote. 예: M5+R4 = Mock 5개 + Remote 4개 repository

### 백엔드 27개 라우터 (252 엔드포인트)

| 라우터 | EP | 서비스 | 테스트 | 라우터 | EP | 서비스 | 테스트 |
|--------|:--:|--------|:------:|--------|:--:|--------|:------:|
| parents | 21 | parent_service | ✅ | schedule | 7 | schedule_service | ✅ |
| lessons | 20 | lesson_service | ✅ | locations | 7 | location_service | ❌ |
| subscriptions | 18 | subscription_service | ✅ | auth | 6 | auth_service | ✅ |
| settings_api | 16 | settings_service | ✅ | users | 6 | user_service | ✅ |
| practice | 15 | practice_service | ✅ | reviews | 5 | review_service | ✅ |
| groups | 15 | schedule_ext_service | ✅ | memberships | 4 | lesson_service | ❌ |
| lesson_requests | 13 | lesson_request_service | ❌ | notifications | 4 | notification_service | ✅ |
| students | 10 | student_service | ✅ | scheduler | 4 | attendance_scheduler | ❌ |
| teachers | 10 | teacher_service | ✅ | ai_notes | 2 | ai_notes_service | ❌ |
| relationships | 10 | relationship_service | ✅ | device_tokens | 2 | device_token_service | ❌ |
| bookings | 9 | schedule_service | ✅ | gamification | 2 | gamification_service | ✅ |
| invites | 8 | invite_service | ✅ | profile_images | 2 | profile_image_service | ❌ |
| practice_logs | 8 | practice_log_service | ✅ | | | | |
| recordings | 7 | recording_service | ✅ | | | | |

> 테스트 미작성 라우터 7개: lesson_requests, locations, memberships, scheduler, ai_notes, device_tokens, profile_images

### 특수 패턴

| 패턴 | 도메인 | 설명 |
|------|--------|------|
| **Facade** | booking, subscription | 단일 진입점으로 복잡한 하위 API 캡슐화 |
| **Cross-domain repo** | profile | Remote 구현체가 onboarding/, invite/에 위치 (의도적 재사용) |
| **데이터 전용** | relationship | 화면 없이 Provider만 제공 (다른 도메인에서 참조) |
| **UI 전용** | home | Repository 없이 공유 서비스/Provider 조합 |
| **Mixin 합성** | practice | 6개 mixin으로 repository 기능 합성 |

---

## Provider 구조

### Provider 위치 규칙
| 타입 | 위치 | 예시 |
|------|------|------|
| Feature UI 상태 | `features/[domain]/presentation/providers/` | lesson_providers.dart |
| 공유 상태 | `features/auth/presentation/providers/` | user_role_provider.dart |

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

### 공유 타입 (core/models/)
```dart
// frontend/lib/core/models/shared_enums.dart
// AgeGroup, ConnectionStatus 등 도메인 횡단 enum
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
