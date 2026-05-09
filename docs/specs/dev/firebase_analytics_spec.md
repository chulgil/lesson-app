# Firebase Analytics 통합 스펙

> Gap #3 | 우선순위: 🔴 CRITICAL | 예상: 3일

## 목적

사용자 행동 데이터를 Firebase Analytics로 수집하여 이탈 원인 분석 및 제품 개선 데이터 확보.

## 현재 상태

- `firebase_core: ^3.12.1` 설치됨
- `firebase_analytics` 미설치
- `logEvent` 호출 0건
- `features/analytics/` 디렉토리 존재 (내부 레슨/연습 통계 대시보드 UI, Firebase 무관)

## 구현 범위

### 1. pubspec.yaml

```yaml
# Analytics
firebase_analytics: ^11.4.4
```

### 2. AnalyticsService 생성

`frontend/lib/core/services/analytics_service.dart` 신규 생성:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // 사용자 식별
  Future<void> setUserId(String userId) =>
      _analytics.setUserId(id: userId);

  Future<void> setUserRole(String role) =>
      _analytics.setUserProperty(name: 'user_role', value: role);

  // 핵심 이벤트 10개
  Future<void> logOnboardingCompleted({required int step, required int durationSec}) =>
      _analytics.logEvent(name: 'onboarding_completed', parameters: {
        'step': step,
        'duration_sec': durationSec,
      });

  Future<void> logStudentAdded({required bool isDemo, required String method}) =>
      _analytics.logEvent(name: 'student_added', parameters: {
        'is_demo': isDemo,
        'method': method,
      });

  Future<void> logLessonCompleted({required int duration, required bool hasNote}) =>
      _analytics.logEvent(name: 'lesson_completed', parameters: {
        'duration': duration,
        'has_note': hasNote,
      });

  Future<void> logPracticeStarted({required String tool}) =>
      _analytics.logEvent(name: 'practice_started', parameters: {
        'tool': tool,
      });

  Future<void> logSubscriptionUpgraded({required String plan, required bool trial}) =>
      _analytics.logEvent(name: 'subscription_upgraded', parameters: {
        'plan': plan,
        'trial': trial,
      });

  Future<void> logInviteShared({required String channel}) =>
      _analytics.logEvent(name: 'invite_shared', parameters: {
        'channel': channel,
      });

  Future<void> logFeatureUsed({required String name}) =>
      _analytics.logEvent(name: 'feature_used', parameters: {
        'name': name,
      });

  Future<void> logAppOpened({required int sessionCount}) =>
      _analytics.logEvent(name: 'app_opened', parameters: {
        'session_count': sessionCount,
      });

  Future<void> logReviewPrompted({required String result}) =>
      _analytics.logEvent(name: 'review_prompted', parameters: {
        'result': result,
      });

  Future<void> logChurnRisk({required int daysInactive, required String lastAction}) =>
      _analytics.logEvent(name: 'churn_risk', parameters: {
        'days_inactive': daysInactive,
        'last_action': lastAction,
      });
}
```

### 3. Riverpod Provider

`frontend/lib/core/services/analytics_service.dart` 하단에 추가:

```dart
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) => AnalyticsService();
```

### 4. GoRouter Observer 연결

`AppRouter` 에서 `navigatorObservers`에 `analyticsService.observer` 추가.

## 핵심 이벤트 정의

| 이벤트 | 속성 | 트리거 시점 |
|--------|------|------------|
| onboarding_completed | step, duration_sec | 온보딩 마지막 단계 완료 |
| student_added | is_demo, method | 학생 추가 성공 |
| lesson_completed | duration, has_note | 레슨 상태 → completed |
| practice_started | tool (metronome/tuner/record) | 연습 도구 시작 |
| subscription_upgraded | plan, trial | 유료 전환 성공 |
| invite_shared | channel (kakao/url/qr) | 초대 공유 완료 |
| feature_used | name | 주요 기능 사용 |
| app_opened | session_count | 앱 포그라운드 진입 |
| review_prompted | result (yes/no/dismiss) | 리뷰 요청 응답 |
| churn_risk | days_inactive, last_action | 비활성 감지 시 (백엔드 연동 후) |

## 수용 기준

- [ ] 앱 빌드 성공
- [ ] AnalyticsService 싱글톤 Riverpod 프로바이더
- [ ] GoRouter observer 연결
- [ ] 핵심 이벤트 10개 메서드 정의
- [ ] 이벤트 호출은 이 PR에서 하지 않음 (서비스 인프라만 구축)

## 영향 파일

- `frontend/pubspec.yaml`
- `frontend/lib/core/services/analytics_service.dart` (신규)
- `frontend/lib/core/router/app_router.dart` (observer 추가)
