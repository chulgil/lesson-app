# 앱스토어 평점 유도 프롬프트 (App Store Rating Prompt) Spec

> 버전: 1.0
> 작성일: 2026-05-07
> 상태: Draft
> 관련 스펙: [settings_master.md](settings_master.md)

---

## 1. 개요

### 1.1 문제 정의

레슨앱에는 현재 앱스토어 평점 유도 기능이 없다. 결과적으로:

- 앱스토어 평점 데이터 부재 → 신규 사용자 신뢰 획득 어려움
- 만족한 사용자가 자발적으로 평가를 남길 경로가 없다
- 경쟁 앱 대비 앱스토어 노출 순위 불리

### 1.2 해결 방향

사용자가 앱의 가치를 경험한 직후 — 레슨 완료, 연습 달성 직후 — 비침습적 2단계 프롬프트로 평점 유도.

병원 만족도 조사에 비유하면, 진료가 끝난 직후 "진료에 만족하셨나요?" 한 문장으로 묻고, 만족 시 앱스토어로, 불만족 시 내부 피드백 폼으로 연결한다.

### 1.3 기존 코드 현황

| 파일 | 내용 |
|------|------|
| `frontend/lib/features/settings/data/repositories/local_app_review_client.dart` | `InAppReview` 래퍼 (`LocalAppReviewClient`) 이미 구현됨 |
| `frontend/lib/features/settings/domain/repositories/app_release_repository.dart` | `AppReviewClient` 인터페이스 정의됨 |
| `pubspec.yaml` | `in_app_review: ^2.0.9` 이미 의존성 등록됨 |

평점 **트리거 로직 및 UI**가 미구현 상태. 이 스펙은 해당 부분을 완성한다.

### 1.4 범위

| 포함 | 제외 |
|------|------|
| 트리거 조건 판별 로직 | 서버 평점 집계/분석 |
| 2단계 프롬프트 다이얼로그 | 이메일 피드백 전송 (피드백 폼은 기존 경로 활용) |
| `AppReviewState` Hive 저장 | 앱스토어 딥링크 직접 열기 (OS 네이티브 API 사용) |
| 선생님/학생 역할별 트리거 조건 분리 | 관리자 대시보드 평점 현황 |

---

## 2. 트리거 조건

### 2.1 공통 조건 (모두 충족해야 프롬프트 표시)

| 조건 | 선생님 기준 | 학생 기준 |
|------|------------|---------|
| 충분한 앱 경험 | 완료된 레슨 5회 이상 | 완료된 연습 세션 3회 이상 |
| 충분한 사용 기간 | 최초 설치 후 7일 이상 경과 | 동일 |
| 재노출 방지 | 마지막 프롬프트 표시 후 90일 초과 | 동일 |
| 중복 방지 | `hasRated == false` AND `dismissCount < 3` | 동일 |

> **설계 결정**: `dismissCount >= 3` 에 도달하면 이후 프롬프트를 영구 표시하지 않는다.
> "3번 거절했으면 더 이상 원하지 않는다"는 의도를 존중한다.

### 2.2 프롬프트 표시 타이밍

| 역할 | 트리거 이벤트 | 표시 타이밍 |
|------|------------|-----------|
| 선생님 | 레슨 완료 처리 (`lessonCompleted`) | 레슨 완료 화면 진입 후 1.5초 지연 |
| 학생 | 연습 세션 완료 (`practiceSessionCompleted`) | 연습 완료 화면 진입 후 1.5초 지연 |

> 1.5초 지연: 화면 전환 애니메이션 완료 후 표시하여 레이아웃 충돌 방지.

### 2.3 트리거 판별 의사결정 트리

```
앱 이벤트 발생 (레슨 완료 / 연습 완료)
        │
        ▼
[AppReviewState 로드]
        │
        ├─ hasRated == true → 중단 (이미 평가함)
        │
        ├─ dismissCount >= 3 → 중단 (거절 횟수 초과)
        │
        ├─ lastPromptDate != null &&
        │  현재 시각 - lastPromptDate < 90일 → 중단 (재노출 방지)
        │
        ├─ 최초 설치일로부터 7일 미만 → 중단 (충분한 경험 미달)
        │
        ├─ 역할 == 선생님 && 완료 레슨 수 < 5 → 중단
        ├─ 역할 == 학생 && 완료 연습 수 < 3 → 중단
        │
        └─ 모든 조건 통과 → [1단계 프롬프트 표시]
```

---

## 3. 프롬프트 플로우

### 3.1 1단계 — 만족도 확인

```
┌─────────────────────────────────────┐
│                                     │
│         ♪  (NotebookGlyph.note)     │  ← 노트 아이콘
│                                     │
│    레슨앱이 도움이 되고 있나요?        │  ← 제목
│                                     │
│    레슨과 연습을 함께 관리하는         │  ← 본문
│    경험이 어떠셨는지 알고 싶어요.      │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [아니요, 별로예요]   [네, 도움돼요!]  │  ← 액션 버튼
│                                     │
└─────────────────────────────────────┘
```

**버튼 동작**:
- **네, 도움돼요!** → [2단계 A: 스토어 평가 요청]
- **아니요, 별로예요** → [2단계 B: 피드백 수집]
- **다이얼로그 외부 탭 / 뒤로가기** → 무시 처리 (dismissCount 증가 없음, 배리어 불투명도)

### 3.2 2단계 A — 스토어 평가 요청 (만족 경로)

```
플랫폼별 처리:
  iOS     → InAppReview.instance.requestReview()  (네이티브 시스템 팝업)
  Android → InAppReview.instance.requestReview()  (인앱 리뷰 플로우)

결과 기록:
  hasRated = true
  lastPromptDate = now
  dismissCount 변경 없음
```

> iOS `requestReview()` 는 시스템이 표시 여부를 최종 결정한다 (연간 3회 제한).
> 함수 호출 성공 = hasRated 처리 (실제 별점 제출 여부는 알 수 없음).

### 3.3 2단계 B — 피드백 수집 (불만족 경로)

```
┌─────────────────────────────────────┐
│                                     │
│    어떤 점을 개선하면 좋을까요?        │  ← 제목
│                                     │
│    소중한 의견을 개발팀에 직접         │  ← 본문
│    전달할게요.                        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [나중에]          [피드백 보내기]     │  ← 액션 버튼
│                                     │
└─────────────────────────────────────┘
```

**버튼 동작**:
- **피드백 보내기** → 기존 피드백 폼 화면으로 이동 (`/settings/feedback`)
  - dismissCount 증가 없음, lastPromptDate 업데이트
- **나중에** → 다이얼로그 닫기
  - dismissCount += 1, lastPromptDate 업데이트

### 3.4 상태 전이 다이어그램

```
[조건 미달]
     │ 조건 충족
     ▼
[1단계 다이얼로그 표시]
  lastPromptDate = now 업데이트
     │
     ├─── "네, 도움돼요!" ──────► [requestReview() 호출]
     │                                    │
     │                           hasRated = true
     │
     ├─── "아니요, 별로예요" ────► [2단계 다이얼로그 표시]
     │                                    │
     │                      ┌─────────────┴─────────────┐
     │                      │                           │
     │               "피드백 보내기"                "나중에"
     │                      │                           │
     │              → 피드백 화면 이동          dismissCount += 1
     │
     └─── 외부 탭 닫기 ────────► (아무 상태 변경 없음)
```

---

## 4. 데이터 모델

### 4.1 AppReviewState (Hive 로컬 저장)

```dart
// frontend/lib/features/settings/domain/entities/app_review_state.dart

@freezed
class AppReviewState with _$AppReviewState {
  const factory AppReviewState({
    /// 마지막 프롬프트 표시 일시 (null = 한 번도 표시 안 됨)
    DateTime? lastPromptDate,

    /// 사용자가 "나중에" / 불만족 경로를 선택한 횟수
    @Default(0) int dismissCount,

    /// 사용자가 평가 버튼을 눌렀는지 (requestReview 호출 여부)
    @Default(false) bool hasRated,
  }) = _AppReviewState;

  factory AppReviewState.fromJson(Map<String, dynamic> json) =>
      _$AppReviewStateFromJson(json);

  /// 초기 상태 (설치 직후)
  factory AppReviewState.initial() => const AppReviewState();
}

extension AppReviewStateX on AppReviewState {
  /// 다음 프롬프트 표시 가능 여부 (90일 조건)
  bool get canShowAgain {
    if (lastPromptDate == null) return true;
    return DateTime.now().difference(lastPromptDate!).inDays > 90;
  }

  /// 프롬프트를 더 이상 표시하지 않아야 하는지 (영구 억제)
  bool get isPermanentlySuppressed => hasRated || dismissCount >= 3;
}
```

### 4.2 AppReviewTriggerContext

```dart
// frontend/lib/features/settings/domain/entities/app_review_trigger_context.dart

/// 트리거 판별에 필요한 컨텍스트 값들
@freezed
class AppReviewTriggerContext with _$AppReviewTriggerContext {
  const factory AppReviewTriggerContext({
    /// 사용자 역할
    required UserRole userRole,

    /// 완료된 레슨 수 (선생님 기준)
    @Default(0) int completedLessonCount,

    /// 완료된 연습 세션 수 (학생 기준)
    @Default(0) int completedPracticeCount,

    /// 앱 최초 설치일 (null이면 판별 불가)
    DateTime? firstInstallDate,
  }) = _AppReviewTriggerContext;
}
```

### 4.3 Hive 어댑터 등록

```dart
// AppReviewState는 json_serializable 기반으로 Hive에 JSON 문자열로 저장
// (freezed 어댑터 자동 생성 불가 → Map<String, dynamic> 직렬화 후 단일 키에 저장)

const _kAppReviewStateBoxKey = 'app_review_state';
const _kAppReviewStateKey = 'state';
```

---

## 5. 트리거 서비스

```dart
// frontend/lib/features/settings/domain/services/app_review_trigger_service.dart

class AppReviewTriggerService {
  AppReviewTriggerService({
    required AppReviewStateRepository stateRepository,
    required AppReviewClient reviewClient,
  })  : _stateRepository = stateRepository,
        _reviewClient = reviewClient;

  final AppReviewStateRepository _stateRepository;
  final AppReviewClient _reviewClient;

  /// 프롬프트 표시 가능 여부 판별
  Future<bool> shouldShowPrompt(AppReviewTriggerContext context) async {
    final state = await _stateRepository.getState();

    // 영구 억제 체크
    if (state.isPermanentlySuppressed) return false;

    // 재노출 주기 체크
    if (!state.canShowAgain) return false;

    // 사용 기간 체크
    if (context.firstInstallDate != null) {
      final daysSinceInstall =
          DateTime.now().difference(context.firstInstallDate!).inDays;
      if (daysSinceInstall < 7) return false;
    }

    // 역할별 경험치 체크
    if (context.userRole == UserRole.teacher) {
      if (context.completedLessonCount < 5) return false;
    } else {
      if (context.completedPracticeCount < 3) return false;
    }

    return true;
  }

  /// 만족 경로: requestReview 호출 + 상태 업데이트
  Future<void> onSatisfied() async {
    final state = await _stateRepository.getState();
    await _reviewClient.requestReview();
    await _stateRepository.saveState(
      state.copyWith(
        hasRated: true,
        lastPromptDate: DateTime.now(),
      ),
    );
  }

  /// 불만족 경로 + 피드백 전송 선택
  Future<void> onFeedbackSent() async {
    final state = await _stateRepository.getState();
    await _stateRepository.saveState(
      state.copyWith(lastPromptDate: DateTime.now()),
    );
  }

  /// 불만족 경로 + "나중에" 선택
  Future<void> onDismissed() async {
    final state = await _stateRepository.getState();
    await _stateRepository.saveState(
      state.copyWith(
        dismissCount: state.dismissCount + 1,
        lastPromptDate: DateTime.now(),
      ),
    );
  }

  /// 프롬프트 표시 시 lastPromptDate 기록 (1단계 표시 직후 호출)
  Future<void> onPromptShown() async {
    final state = await _stateRepository.getState();
    await _stateRepository.saveState(
      state.copyWith(lastPromptDate: DateTime.now()),
    );
  }
}
```

---

## 6. Repository 인터페이스 및 구현

### 6.1 AppReviewStateRepository

```dart
// frontend/lib/features/settings/domain/repositories/app_review_state_repository.dart

abstract class AppReviewStateRepository {
  Future<AppReviewState> getState();
  Future<void> saveState(AppReviewState state);
  Future<void> reset(); // 디버그/테스트용
}
```

### 6.2 HiveAppReviewStateRepository

```dart
// frontend/lib/features/settings/data/repositories/hive_app_review_state_repository.dart

class HiveAppReviewStateRepository implements AppReviewStateRepository {
  HiveAppReviewStateRepository({required Box<String> box}) : _box = box;

  final Box<String> _box;

  @override
  Future<AppReviewState> getState() async {
    final raw = _box.get(_kAppReviewStateKey);
    if (raw == null) return AppReviewState.initial();
    return AppReviewState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> saveState(AppReviewState state) async {
    await _box.put(_kAppReviewStateKey, jsonEncode(state.toJson()));
  }

  @override
  Future<void> reset() async {
    await _box.delete(_kAppReviewStateKey);
  }
}
```

---

## 7. Provider 설계

```dart
// frontend/lib/features/settings/presentation/providers/app_review_providers.dart

/// Hive Box 프로바이더 (keepAlive)
@Riverpod(keepAlive: true)
Future<Box<String>> appReviewBox(Ref ref) async {
  return Hive.openBox<String>(_kAppReviewStateBoxKey);
}

/// Repository 프로바이더
@Riverpod(keepAlive: true)
AppReviewStateRepository appReviewStateRepository(Ref ref) {
  final box = ref.watch(appReviewBoxProvider).requireValue;
  return HiveAppReviewStateRepository(box: box);
}

/// TriggerService 프로바이더
@Riverpod(keepAlive: true)
AppReviewTriggerService appReviewTriggerService(Ref ref) {
  return AppReviewTriggerService(
    stateRepository: ref.watch(appReviewStateRepositoryProvider),
    reviewClient: ref.watch(appReviewClientProvider),
  );
}

/// AppReviewClient 프로바이더 (기존 LocalAppReviewClient 활용)
@Riverpod(keepAlive: true)
AppReviewClient appReviewClient(Ref ref) {
  return LocalAppReviewClient();
}

/// 현재 AppReviewState 조회
@riverpod
Future<AppReviewState> appReviewState(Ref ref) async {
  final repo = ref.watch(appReviewStateRepositoryProvider);
  return repo.getState();
}
```

---

## 8. UI 구현

### 8.1 AppRatingPromptDialog

```dart
// frontend/lib/features/settings/presentation/widgets/app_rating_prompt_dialog.dart

/// 1단계: 만족도 확인 다이얼로그
class AppRatingPromptDialog extends StatelessWidget {
  const AppRatingPromptDialog({
    super.key,
    required this.onSatisfied,
    required this.onDissatisfied,
  });

  final VoidCallback onSatisfied;
  final VoidCallback onDissatisfied;

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      icon: const NotebookGlyph(
        glyph: NotebookGlyphData.note,  // ♪
        size: 32,
      ),
      title: AppStrings.ratingPromptTitle,
      content: Text(
        AppStrings.ratingPromptBody,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: onDissatisfied,
          child: Text(
            AppStrings.ratingPromptNo,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onSatisfied,
          child: Text(
            AppStrings.ratingPromptYes,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// 2단계 B: 피드백 수집 다이얼로그
class AppRatingFeedbackDialog extends StatelessWidget {
  const AppRatingFeedbackDialog({
    super.key,
    required this.onFeedback,
    required this.onLater,
  });

  final VoidCallback onFeedback;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return NotebookAlertDialog(
      title: AppStrings.ratingFeedbackTitle,
      content: Text(
        AppStrings.ratingFeedbackBody,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.inkSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: onLater,
          child: Text(
            AppStrings.ratingFeedbackLater,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onFeedback,
          child: Text(
            AppStrings.ratingFeedbackSend,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
```

### 8.2 프롬프트 표시 헬퍼 함수

```dart
// frontend/lib/features/settings/presentation/widgets/app_rating_prompt_dialog.dart (계속)

Future<void> showAppRatingPromptIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required AppReviewTriggerContext triggerContext,
}) async {
  final service = ref.read(appReviewTriggerServiceProvider);
  final should = await service.shouldShowPrompt(triggerContext);
  if (!should || !context.mounted) return;

  // 1.5초 지연 (화면 전환 완료 대기)
  await Future.delayed(const Duration(milliseconds: 1500));
  if (!context.mounted) return;

  await service.onPromptShown();

  final result = await showDialog<_RatingResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AppRatingPromptDialog(
      onSatisfied: () => Navigator.of(context).pop(_RatingResult.satisfied),
      onDissatisfied: () => Navigator.of(context).pop(_RatingResult.dissatisfied),
    ),
  );

  if (result == _RatingResult.satisfied) {
    await service.onSatisfied();
    return;
  }

  if (result == _RatingResult.dissatisfied && context.mounted) {
    final feedbackResult = await showDialog<_FeedbackResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppRatingFeedbackDialog(
        onFeedback: () => Navigator.of(context).pop(_FeedbackResult.send),
        onLater: () => Navigator.of(context).pop(_FeedbackResult.later),
      ),
    );

    if (feedbackResult == _FeedbackResult.send) {
      await service.onFeedbackSent();
      if (context.mounted) {
        context.push('/settings/feedback');
      }
    } else {
      await service.onDismissed();
    }
  }
}

enum _RatingResult { satisfied, dissatisfied }
enum _FeedbackResult { send, later }
```

### 8.3 트리거 지점 연결 예시 (레슨 완료 화면)

```dart
// frontend/lib/features/lessons/presentation/screens/lesson_complete_screen.dart

@override
void initState() {
  super.initState();
  // 화면 빌드 완료 후 트리거 체크
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkRatingPrompt();
  });
}

void _checkRatingPrompt() {
  final context = this.context;
  final ref = this.ref;
  showAppRatingPromptIfNeeded(
    context: context,
    ref: ref,
    triggerContext: AppReviewTriggerContext(
      userRole: ref.read(currentUserRoleProvider),
      completedLessonCount: ref.read(completedLessonCountProvider),
    ),
  );
}
```

---

## 9. AppStrings 추가 항목

```dart
// 1단계 만족도 확인
static const ratingPromptTitle = '레슨앱이 도움이 되고 있나요?';
static const ratingPromptBody = '레슨과 연습을 함께 관리하는\n경험이 어떠셨는지 알고 싶어요.';
static const ratingPromptYes = '네, 도움돼요!';
static const ratingPromptNo = '아니요, 별로예요';

// 2단계 피드백 수집
static const ratingFeedbackTitle = '어떤 점을 개선하면 좋을까요?';
static const ratingFeedbackBody = '소중한 의견을 개발팀에 직접 전달할게요.';
static const ratingFeedbackSend = '피드백 보내기';
static const ratingFeedbackLater = '나중에';
```

---

## 10. 플랫폼별 주의사항

### 10.1 iOS

- `requestReview()` 는 **연간 3회** 표시 제한 (Apple 정책). 앱이 요청해도 시스템이 거부할 수 있음.
- 시뮬레이터에서는 항상 표시되지 않을 수 있음 → 실기기 테스트 필수.
- `Info.plist`에 추가 설정 불필요 (`in_app_review` 패키지가 처리).

### 10.2 Android

- `in_app_review` 패키지의 인앱 리뷰는 **Play 스토어 배포 앱**에서만 작동 (디버그 빌드 제한적).
- `canRequestReview()` 가 `false`를 반환하는 경우: 미배포 앱, Play 스토어 미지원 기기.
- `canRequestReview() == false` 시 폴백: 조용히 넘어감 (외부 스토어 링크 강제 노출 안 함).

### 10.3 공통

- `in_app_review`가 실제 평가 제출 여부를 앱에 알려주지 않는다. `requestReview()` 호출 성공 = `hasRated = true` 처리.
- 개발/스테이징 환경에서 불필요한 실제 리뷰 요청 방지: `kDebugMode` 플래그로 `LocalAppReviewClient`를 Mock으로 교체.

---

## 11. 테스트 전략

### 11.1 단위 테스트 (`AppReviewTriggerService`)

```dart
// frontend/test/features/settings/app_review_trigger_service_test.dart

group('shouldShowPrompt', () {
  test('hasRated true → false 반환', () async { ... });
  test('dismissCount 3 → false 반환', () async { ... });
  test('lastPromptDate 80일 전 → false 반환 (90일 미충족)', () async { ... });
  test('lastPromptDate 91일 전 → true 반환', () async { ... });
  test('설치 5일 → false 반환 (7일 미충족)', () async { ... });
  test('선생님 레슨 4회 → false 반환', () async { ... });
  test('선생님 레슨 5회 + 모든 조건 충족 → true 반환', () async { ... });
  test('학생 연습 2회 → false 반환', () async { ... });
  test('학생 연습 3회 + 모든 조건 충족 → true 반환', () async { ... });
});

group('onDismissed', () {
  test('dismissCount 1씩 증가', () async { ... });
  test('dismissCount 2 → 3 → isPermanentlySuppressed true', () async { ... });
});
```

### 11.2 Widget Smoke Test

```dart
// frontend/test/features/settings/app_rating_prompt_dialog_test.dart

testWidgets('AppRatingPromptDialog renders without exception', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppRatingPromptDialog(
          onSatisfied: () {},
          onDissatisfied: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});

testWidgets('AppRatingFeedbackDialog renders without exception', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppRatingFeedbackDialog(
          onFeedback: () {},
          onLater: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});
```

---

## 12. 구현 단계

### Phase 1 — 도메인 레이어 (0.5일)

- [ ] `AppReviewState` freezed 엔티티 + `fromJson/toJson`
- [ ] `AppReviewTriggerContext` freezed 엔티티
- [ ] `AppReviewStateRepository` 인터페이스
- [ ] `AppReviewTriggerService` 구현
- [ ] `build_runner` 코드 생성
- [ ] `AppReviewTriggerService` 단위 테스트 (9개 케이스)

### Phase 2 — 데이터 레이어 (0.5일)

- [ ] `HiveAppReviewStateRepository` 구현
- [ ] Hive Box 초기화 (`main.dart` 또는 앱 부트스트랩에서 `openBox` 호출)
- [ ] `HiveAppReviewStateRepository` 통합 테스트 (저장/읽기/리셋)

### Phase 3 — Provider 및 Widget (0.5일)

- [ ] `app_review_providers.dart` Riverpod codegen Provider 4개
- [ ] `AppRatingPromptDialog` 위젯
- [ ] `AppRatingFeedbackDialog` 위젯
- [ ] `showAppRatingPromptIfNeeded` 헬퍼 함수
- [ ] Widget smoke test 2개
- [ ] `AppStrings` 상수 추가

### Phase 4 — 트리거 지점 연결 (0.5일)

- [ ] 레슨 완료 화면에 트리거 연결 (선생님)
- [ ] 연습 세션 완료 화면에 트리거 연결 (학생)
- [ ] `kDebugMode` 플래그로 Mock 교체 처리
- [ ] `flutter analyze` 0 오류

### Phase 5 — 검증 (0.5일)

- [ ] 실기기(iOS) `requestReview()` 호출 확인
- [ ] 조건 미달 시 프롬프트 미표시 확인
- [ ] `dismissCount 3` 도달 후 영구 억제 확인
- [ ] 90일 조건 (lastPromptDate 조작 테스트)

---

## 13. 기존 코드와의 관계

| 기존 파일 | 이 스펙의 활용 방식 |
|-----------|-------------------|
| `local_app_review_client.dart` | `AppReviewTriggerService` 내부에서 `AppReviewClient`로 주입 (변경 없음) |
| `app_release_repository.dart` | `AppReviewClient` 인터페이스 그대로 사용 (변경 없음) |
| `app_release_provider.dart` | `appReviewClientProvider`로 `LocalAppReviewClient` 등록 |
| `NotebookAlertDialog` | `AppRatingPromptDialog`, `AppRatingFeedbackDialog`의 베이스 다이얼로그 |

> **기존 `AppReviewClient` 인터페이스와 `LocalAppReviewClient` 구현은 수정하지 않는다.**
> Surgical Changes 원칙 준수: 트리거 서비스와 UI만 신규 추가.
