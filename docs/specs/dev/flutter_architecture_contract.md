# Scalable Flutter Architecture Contract

> Obsidian Flutter advanced course의 Clean Architecture/Riverpod 기준에 맞춘 frontend 유지보수 계약.

## Decision

상태관리는 Riverpod으로 표준화한다. Bloc은 예측 가능한 event/state 모델이 강점이지만, 현재 앱은 Riverpod provider와 repository factory가 이미 핵심 구조라서 전환 비용이 크다. 목표는 교체가 아니라 Riverpod 사용 규칙, 계층 의존성, 계약 테스트를 강화하는 것이다.

## Course Alignment

기준 아키텍처는 Clean Architecture의 dependency rule을 따른다. 바깥 계층은 안쪽 계층을 알 수 있지만, 안쪽 계층은 바깥 계층을 알 수 없다.

```text
View/Widget -> Provider/Notifier -> UseCase/Domain Service -> Repository Interface
                                      ^                         ^
                                      |                         |
                                  Entity/Value              Data Adapter
```

이 앱의 실무 매핑:
- ViewModel은 Riverpod `Notifier`/`AsyncNotifier` 또는 screen-scoped provider로 구현한다.
- UseCase는 여러 repository, validation, side effect를 묶는 application/domain service로 구현한다.
- 단순 조회/저장은 provider가 repository interface를 직접 호출할 수 있다.
- Firebase, Hive, API client, local notification, platform IO는 data/core adapter로 둔다.
- domain은 business rule, entity, value object, repository contract, 순수 service만 둔다.

## Feature Layers

각 feature는 기본적으로 다음 구조를 따른다.

```text
features/<feature>/
  data/
    repositories/
    services/
    datasources/
  domain/
    entities/
    repositories/
    services/
    usecases/
  presentation/
    providers/
    screens/
    widgets/
```

의존성 방향:

```text
presentation -> domain <- data
```

규칙:
- `domain`은 entity, repository interface, 순수 domain service를 가진다.
- `data`는 repository implementation, API/Hive/Firebase/platform adapter, data service를 가진다.
- `presentation`은 provider factory, UI state, screen/widget orchestration을 가진다.
- `domain`과 `data`는 `/presentation/`을 import/export하지 않는다.
- `domain`은 `/data/`를 import/export하지 않는다.
- domain service는 Riverpod `Ref`를 직접 받지 않는다. 필요한 dependency는 생성자나 함수 인자로 받는다.
- domain service는 Firebase, Hive, `ApiClient`, `EnvironmentConfig`, local notification plugin, `dart:io` 같은 framework/driver를 import하지 않는다.
- 기존 Hive annotation entity는 legacy 예외로 남아 있으나 새 domain entity는 persistence annotation 없이 data mapper를 둔다.

## UseCases and Application Services

다음 조건 중 하나라도 있으면 provider에 로직을 직접 쌓지 않고 usecase/application service로 승격한다.

- 2개 이상의 repository/service를 조합한다.
- validation, permission, 상태 전이, 알림 발송 같은 business rule이 있다.
- 같은 workflow가 둘 이상의 화면에서 재사용된다.
- 실패/재시도/보상 처리가 필요하다.

위 조건이 없고 단순 read/write만 수행하면 `AsyncNotifier`가 repository를 직접 호출해도 된다.

## Repositories

규칙:
- repository interface는 `features/<feature>/domain/repositories/`에 둔다.
- implementation은 `features/<feature>/data/repositories/`에 둔다.
- repository 선택은 `createRepository<T>()` 또는 동등한 core factory를 통해 presentation/core provider에서 수행한다.
- `EnvironmentConfig.useMockData` 직접 분기는 `core/providers/repository_provider.dart`와 계약 테스트에 명시된 예외만 허용한다.
- domain repository 파일에서 data implementation을 re-export하지 않는다.
- mock/remote/local 구현은 모두 data repository로 취급한다.

기존 legacy 예외는 `frontend/test/architecture/layer_boundaries_test.dart`에 명시한다. 새 코드에서는 예외를 추가하지 않고 구조를 맞춘다.

## Riverpod Standards

신규/수정 provider는 `riverpod_annotation` code generation을 기본으로 한다.

Provider 생명주기:
- repository provider: `@Riverpod(keepAlive: true)`
- 앱 단위 singleton service: `@Riverpod(keepAlive: true)`
- 화면/검색/상세/필터 provider: 기본 autoDispose
- disposable resource는 `ref.onDispose`로 정리한다.

State 규칙:
- `StateProvider`는 enum/string/bool/date 같은 단순 UI state만 허용한다.
- 검증, 비동기, 복합 상태, side effect가 있는 상태는 `Notifier` 또는 `AsyncNotifier`로 승격한다.
- domain/data service가 provider를 읽어야 하면 service를 순수하게 유지하고 presentation provider에서 dependency를 주입한다.
- provider는 dependency wiring과 UI orchestration에 집중한다. business rule이 길어지면 usecase/application service로 이동한다.

Debug/profile 실행에서는 `ProviderObserver`로 provider add/update/dispose를 기록한다. Release 실행에서는 observer를 붙이지 않는다.

## Feature Public API

feature root에 facade를 둘 수 있지만 다음 중 하나로 명시한다.

- `feature/<name>_facade.dart`: 다른 feature가 사용할 public API만 export한다.
- facade는 feature의 public boundary다. 다른 feature가 provider를 써야 한다면 해당 provider를 facade에서 좁게 export하고, 소비자는 facade만 import한다.
- facade에서 export하는 provider는 repository provider, read-only query provider, application service provider처럼 외부 계약으로 인정된 API여야 한다.
- screen/widget 내부 상태, 임시 form 상태, private orchestration provider는 facade로 export하지 않는다.
- cross-feature 접근은 facade, domain contract, application service, shared core provider 중 하나를 통해 한다.
- 새 코드에서 다른 feature의 `presentation/providers`를 직접 import/export하지 않는다.
- 기존 cross-feature presentation provider import는 `frontend/test/architecture/feature_dependency_contract_test.dart`의 legacy baseline에만 남긴다.
- legacy import를 제거하면 baseline도 함께 줄인다. 새 baseline 항목 추가는 architecture debt 증가로 보고 별도 이슈와 설계 사유가 필요하다.
- 특정 feature의 상태/행동을 외부에서 재사용해야 하면 먼저 그 feature의 public API를 정의한다. public API는 UI widget 내부 provider가 아니라 domain-facing DTO, usecase, facade method, 또는 좁은 read-only provider로 노출한다.

예시:

```dart
// 허용: home feature가 onboarding public boundary만 의존
import 'package:lessonaza/features/onboarding/onboarding_facade.dart';

// 금지: 다른 feature의 내부 provider 파일 직접 의존
import 'package:lessonaza/features/onboarding/presentation/providers/onboarding_progress_storage_provider.dart';
```

## Local Persistence and UI Flags

Hive, SharedPreferences, SecureStorage 같은 로컬 저장소는 business entity에 직접 섞지 않는다.

규칙:
- 새 domain entity에 Hive annotation을 추가하지 않는다.
- 로컬 저장소 key/box 이름은 data adapter 또는 presentation/application storage provider 안에 캡슐화한다.
- 온보딩 완료 여부, 데모 오버레이 dismiss 여부, 최초 진입 안내처럼 UI/application flag는 `AsyncNotifier` 기반 storage provider로 둔다.
- 사용자별 상태는 반드시 user id scoped key를 사용한다. 예: `teacher:<userId>:completed`, `teacher:<userId>:demoOverlayDismissed`.
- 같은 기기에서 역할/계정이 바뀌어도 flag가 섞이지 않는 테스트를 추가한다.
- 저장소 provider를 다른 feature에서 써야 하면 feature facade에서 public API로 export한다.

온보딩 예시:

```text
features/onboarding/presentation/providers/onboarding_progress_storage_provider.dart
  - Hive box: onboarding_progress
  - state: teacherOnboardingCompleted, demoOverlayDismissed
  - public export: features/onboarding/onboarding_facade.dart
```

## UI Text and i18n

사용자에게 보이는 문구는 `AppStrings` 또는 l10n 계층으로 모은다.

- `AppStrings`는 현재 앱의 중앙 문자열 SSOT로 유지한다.
- Flutter ARB 기반 `AppLocalizations` 구조가 도입되기 전까지는 `AppStrings`를 presentation 계층의 공통 문자열 API로 사용한다.
- 다국어 적용이 필요해지면 `AppStrings`와 ARB를 중복 관리하지 않고, facade 또는 단계적 migration plan을 통해 하나의 런타임 accessor로 수렴시킨다.
- 새/수정 UI에서 하드코딩 Korean/English label을 추가하지 않는다.
- 일정 변경, 확정, 거절, 카운터 제안처럼 메시지/말풍선에 들어가는 문구는 공통 string API를 사용한다.
- 사용자가 입력한 확정 메시지와 시스템 이벤트 메시지는 별도 필드로 유지하고, 표시 단계에서 누락하지 않는다.
- n8n/automation으로 전달될 텍스트는 화면별 임의 문구가 아니라 공통 메시지 builder를 통해 생성한다.

### Localization Boundary

문자열 SSOT는 유지하되 domain/data 계층이 직접 의존하지 않는다.

금지:
- `features/*/domain/**` 에서 `AppStrings`, `AppLocalizations`, `core/l10n` import
- `features/*/data/**` 에서 `AppStrings`, `AppLocalizations`, `core/l10n` import
- `core/domain/**`, `core/booking/entities/**`, `core/booking/repositories/**` 에서 Flutter/l10n import
- domain enum/entity에 `label`, `title`, `emoji`, `statusLabel`, `displayText`, `homeRoute`처럼 화면 표시 목적의 getter 추가

허용:
- `presentation/screens`, `presentation/widgets`, `presentation/providers`
- `presentation/extensions`
- `core/presentation` 또는 공통 UI widget
- l10n facade 자체와 message builder 구현체

예시:

```dart
// domain: 순수 상태 값만 유지
enum LessonRequestStatus { pending, confirmed }

// presentation/extensions/lesson_request_status_visuals.dart
extension LessonRequestStatusVisuals on LessonRequestStatus {
  String get label => switch (this) {
    LessonRequestStatus.pending => AppStrings.lessonRequestPending,
    LessonRequestStatus.confirmed => AppStrings.lessonRequestConfirmed,
  };
}
```

이 규칙의 목적은 `AppStrings`를 제거하는 것이 아니라, localization 변경이 business rule, repository contract, 서버 payload, 테스트 데이터 구조까지 전염되지 않게 막는 것이다.

## Cross-Feature Domain Services

여러 feature의 repository/service를 조합하는 workflow는 application/domain service로 분리하되, wiring은 presentation provider가 담당한다.

규칙:
- service constructor는 domain repository interface와 순수 service interface만 받는다.
- service 내부에서 Riverpod provider, facade, presentation provider를 import하지 않는다.
- service provider는 각 dependency를 해당 feature facade 또는 local provider에서 주입한다.
- 특정 feature의 repository provider가 다른 feature에서 필요하면 먼저 source feature facade가 public export한다.
- service가 notification, schedule event, subscription 같은 side effect를 함께 수행하면 targeted unit test에서 fake repository/service를 모두 주입한다.
- domain model에 없는 UI 편의 필드를 가정하지 않는다. 회차, 잔여 변경권, request id 같은 파생 값은 repository 조회 또는 mapper/service helper에서 계산한다.

예시:

```dart
@riverpod
BulkTeacherActionService bulkTeacherActionService(Ref ref) {
  return BulkTeacherActionService(
    lessonRepository: ref.watch(lessonRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
    requestRepository: ref.watch(schedule.unifiedLessonRequestRepositoryProvider),
    subscriptionRepository: ref.watch(subscriptionRepositoryProvider),
  );
}
```

위 provider는 presentation layer에 있고, `BulkTeacherActionService` 자체는 Riverpod과 presentation provider를 모른다.

## Startup Bootstrap

`main.dart`는 현재 Firebase, audio session, Hive, recording recovery, app run 책임을 모두 가진다. 이후 변경에서는 다음처럼 작은 bootstrap 계층으로 이동한다.

```text
core/startup/
  app_bootstrap.dart
  startup_recovery.dart
  startup_provider_observer.dart
```

원칙:
- platform 초기화와 recovery 로직은 `main.dart` 밖으로 이동한다.
- bootstrap 함수는 side effect 순서를 명확히 드러내고 테스트 가능한 작은 함수로 나눈다.
- UI 진입점은 `runApp(ProviderScope(...))`만 남기는 방향으로 축소한다.

## Contract Tests

`frontend/test/architecture/layer_boundaries_test.dart`가 다음을 검사한다.

- domain/data에서 presentation import/export 금지
- domain에서 data import/export 금지
- domain service에서 framework driver/API/environment import 금지
- domain layer에 새 Hive persistence annotation/import 추가 금지
- domain/data/core booking 순수 계층에서 Flutter/l10n/AppStrings 의존 금지
- repository interface와 implementation 위치 규칙
- `EnvironmentConfig.useMockData` 직접 분기의 허용 위치

`frontend/test/architecture/feature_dependency_contract_test.dart`가 다음을 검사한다.

- 다른 feature의 `presentation/providers` 직접 import/export는 legacy baseline에 명시된 항목만 허용
- baseline에 없는 새 cross-feature presentation provider 의존 추가 금지
- 제거된 legacy 의존은 baseline에서도 제거하도록 강제

검증 명령:

```bash
cd frontend
flutter test test/architecture
flutter analyze
rg -n "presentation/providers" lib/features/*/domain lib/features/*/data --glob '*.dart' --glob '!*.g.dart'
```
