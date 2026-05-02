# 문제 해결

```bash
# iOS 빌드 에러
cd frontend/ios && pod install && cd .. && flutter clean && flutter pub get

# Android 빌드 에러
cd frontend/android && ./gradlew clean && cd .. && flutter clean && flutter pub get

# Provider 코드 생성 에러
cd frontend && dart run build_runner build --delete-conflicting-outputs

# Mock 데이터 변경 후 앱 크래시 (Hive 캐시 충돌)
# 1) 앱 삭제 후 재설치 또는
# 2) flutter clean && flutter run (debug 모드로 먼저 확인)

# Flutter 3.29.0 ThemeData 타입 에러 (CardTheme → CardThemeData 등)
# flutter analyze로 감지 후 deprecated 타입을 새 타입으로 교체
cd frontend && flutter analyze 2>&1 | grep "Error:"

# intl 버전 충돌 (flutter_localizations SDK 호환)
# pubspec.yaml에서 intl: ^0.20.2 확인
cd frontend && flutter pub get
```
