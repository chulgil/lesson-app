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
```
