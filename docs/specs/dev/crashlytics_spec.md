# Crashlytics 통합 스펙

> Gap #7 | 우선순위: 🔴 CRITICAL | 예상: 2일

## 목적

프로덕션 크래시를 Firebase Crashlytics로 수집하여 사각지대 제거.

## 현재 상태

- `firebase_core: ^3.12.1` 설치됨
- `firebase_crashlytics` 미설치
- `main.dart`에 글로벌 에러 핸들러 없음
- `FlutterError.reportError()` 1건만 존재 (practice_item_providers.dart, 임시)

## 구현 범위

### 1. pubspec.yaml

```yaml
# Crash Reporting
firebase_crashlytics: ^4.3.3
```

### 2. main.dart 수정

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapApp();

  // Crashlytics: Flutter 프레임워크 에러 캡처
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: Dart 비동기 에러 캡처
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    ProviderScope(observers: providerObservers(), child: const LessonazaApp()),
  );
}
```

### 3. app_bootstrap.dart 수정

`bootstrapApp()` 내에서 Firebase 초기화 후 Crashlytics 활성화:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// Crashlytics 비치명적 에러 수집 활성화
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
```

### 4. 사용자 식별

로그인 성공 시 Crashlytics에 사용자 ID 설정:

```dart
FirebaseCrashlytics.instance.setUserIdentifier(userId);
```

## 수용 기준

- [ ] 앱 빌드 성공 (iOS + Android)
- [ ] 의도적 크래시 테스트 → Firebase Console에 크래시 보고 확인
- [ ] 비치명적 에러도 수집됨
- [ ] 로그인 사용자의 userId가 크래시 보고에 포함

## 영향 파일

- `frontend/pubspec.yaml`
- `frontend/lib/main.dart`
- `frontend/lib/core/startup/app_bootstrap.dart`
- 로그인 성공 부분 (auth provider)
