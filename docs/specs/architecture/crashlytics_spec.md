# Crashlytics / 에러 모니터링 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟡 MEDIUM (출시 후 6개월 내, 권장 출시 전 도입)
> 관련: `pubspec.yaml`, [event_tracking_spec.md](../analytics/event_tracking_spec.md)

---

## 0. 개요

프로덕션 크래시·예외 자동 수집. `firebase_crashlytics` 도입. **2일 작업** 분량이라 출시 전 권장.

---

## 1. 현황 진단

| 항목 | 상태 |
|------|------|
| `firebase_crashlytics` 패키지 | ❌ |
| `FlutterError.onError` 핸들러 | ❌ 기본값 (콘솔만) |
| Isolate 에러 캐치 | ❌ |
| 백엔드 Sentry/Rollbar | ❌ |
| 알림 (Slack 등) | ❌ |

---

## 2. 도입

### 2.1 패키지

```yaml
dependencies:
  firebase_crashlytics: ^4.0.0
```

### 2.2 초기화 (`main.dart`)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Flutter 프레임워크 에러
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // 비동기 (Zone 밖) 에러
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

### 2.3 디버그 모드 제외

```dart
FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
```

---

## 3. 보고 정책

### 3.1 자동 수집 대상

| 종류 | 보고 | 분류 |
|------|------|------|
| Flutter widget 에러 | ✅ | fatal |
| 비동기 미캐치 에러 | ✅ | fatal |
| 네이티브 크래시 (iOS/Android) | ✅ | fatal |
| 명시적 `recordError(non-fatal)` | ✅ | non-fatal |
| `print`/`debugPrint` | ❌ | — |

### 3.2 비치명적 에러 명시 보고

API 실패, 데이터 파싱 실패 등은 사용자 흐름을 중단하지 않지만 추적 필요:

```dart
try {
  await api.fetchLessons();
} catch (e, stack) {
  await FirebaseCrashlytics.instance.recordError(
    e, stack,
    fatal: false,
    reason: 'lessons fetch failed',
  );
  rethrow;  // 비즈니스 로직은 그대로
}
```

### 3.3 사용자 컨텍스트

```dart
FirebaseCrashlytics.instance.setUserIdentifier(hashedUserId);  // PII 해시
FirebaseCrashlytics.instance.setCustomKey('user_role', currentRole.name);
FirebaseCrashlytics.instance.setCustomKey('app_version', appVersion);
FirebaseCrashlytics.instance.setCustomKey('locale', currentLocale);
```

이메일/이름 등 PII 절대 금지 (`event_tracking_spec.md §3.3` 동일 정책).

### 3.4 breadcrumbs (사용자 경로)

```dart
FirebaseCrashlytics.instance.log('Tapped lesson card lessonId=hash123');
```

화면 진입, 주요 버튼 탭, API 호출 직전에 로그. PII 금지.

---

## 4. 백엔드 에러 모니터링

### 4.1 도구

| 도구 | 사유 |
|------|------|
| **Sentry** (권장) | Python/Flutter 통합, 무료 5K events/월 |
| Rollbar | 비싸지만 안정적 |
| 자체 구축 | 비추천 (운영 부담) |

### 4.2 백엔드 설정

```python
# FastAPI
import sentry_sdk
sentry_sdk.init(
    dsn=os.environ["SENTRY_DSN"],
    traces_sample_rate=0.1,  # 10% 샘플링
    environment=os.environ.get("ENV", "production"),
)
```

### 4.3 클라이언트 ↔ 백엔드 연관

요청 ID(`X-Request-ID`) 헤더로 양쪽 로그 연동:
- 클라이언트 Crashlytics breadcrumb: `request_id=abc`
- Sentry tag: `request_id=abc`

---

## 5. 알림

### 5.1 Slack 통합

| 채널 | 트리거 |
|------|--------|
| `#alerts-prod-crash` | 신규 크래시 (Crashlytics velocity > 1%) |
| `#alerts-prod-error` | Sentry 신규 issue |
| `#alerts-prod-anomaly` | 크래시율 시간당 2배 증가 |

### 5.2 PagerDuty (선택, Year 2)

- 크래시율 > 5% → on-call 호출
- 결제 API 5xx 비율 > 1% → on-call 호출

---

## 6. SLO

| 지표 | 목표 |
|------|------|
| 크래시-free user rate | > 99.5% |
| 크래시-free session rate | > 99.8% |
| 백엔드 5xx rate | < 0.1% |
| MTTR (Mean Time to Resolution) | < 4시간 (사용자 영향 크래시) |

---

## 7. 사용자 권리

### 7.1 옵트아웃

진입점: 설정 → "내 데이터 · 프라이버시" → "데이터 수집 끄기" (통합 토글)
- 기본값: ON (앱 안정성 우선)
- OFF 시 `setCrashlyticsCollectionEnabled(false)` 호출 (analytics opt-out과 동시 처리)

> **UI 진입점은 [settings_information_architecture_spec.md §4.1](../design/settings_information_architecture_spec.md) 참조.**
> Crashlytics 단독 토글로 UI 노출하지 않음. analytics opt-out과 통합되어 사용자에게는 "데이터 수집 끄기" 단일 결정으로 제공. 운영상 분리 필요 시 내부 키로 개별 제어 가능.

### 7.2 데이터 보존

- Crashlytics 기본 90일 보존
- 익명화된 stack trace + 메타데이터만
- 사용자 ID는 해시값 — 역추적 불가

---

## 8. 검증

### 8.1 도입 검증

```dart
// 임시 테스트 버튼 (release 전 제거)
ElevatedButton(
  onPressed: () => throw Exception("Test crash"),
  child: Text("Test crash"),
)
```

24시간 내 Firebase 콘솔에 표시되는지 확인.

### 8.2 정기 점검

| 빈도 | 작업 |
|------|------|
| 일일 | Slack `#alerts-prod-crash` 모니터링 |
| 주간 | Top 10 crashes 리뷰 (월요일) |
| 월간 | 크래시-free rate 추세 보고 |

---

## 9. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `crashReportOptInTitle` | 크래시 리포트 보내기 |
| `crashReportOptInSubtitle` | 앱이 멈췄을 때 익명화된 정보를 보내 안정성을 개선해요 |

---

## 10. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | firebase_crashlytics 채택 | firebase_core 이미 설치, 무료 |
| 2026-05-18 | 백엔드는 Sentry | Crashlytics는 모바일 전용 |
| 2026-05-18 | PII는 해시 식별자만 | 개인정보보호법 + GDPR |
| 2026-05-18 | 크래시 리포트 기본 ON | 출시 초기 안정성 데이터 확보 필수 |

---

## 11. 관련 문서

- [event_tracking_spec.md](../analytics/event_tracking_spec.md) — 동일 PII 정책
- [account_lifecycle_spec.md](../user/account_lifecycle_spec.md) — 데이터 삭제 시 Crashlytics 식별자도 익명화
