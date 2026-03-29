# Firebase 설정 가이드

> FCM 푸시 알림을 위한 Firebase 프로젝트 설정 단계

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `lessonaza` (또는 원하는 이름)
4. Google Analytics 활성화 (선택)
5. 프로젝트 생성 완료

## 2. iOS 앱 등록

1. Firebase Console > 프로젝트 설정 > "앱 추가" > iOS
2. **Bundle ID**: `com.lessonaza.app` (Xcode에서 확인)
3. 앱 닉네임: `Lessonaza iOS`
4. `GoogleService-Info.plist` 다운로드
5. 파일 배치: `frontend/ios/Runner/GoogleService-Info.plist`

### APNs 설정 (필수)

1. [Apple Developer](https://developer.apple.com) > Certificates, Identifiers & Profiles
2. Keys > "+" > Apple Push Notifications service (APNs) 체크
3. Key 다운로드 (`.p8` 파일)
4. Firebase Console > 프로젝트 설정 > Cloud Messaging > iOS 앱 > APNs 인증 키 업로드
   - Key ID, Team ID 입력

## 3. Android 앱 등록

1. Firebase Console > "앱 추가" > Android
2. **패키지 이름**: `com.lessonaza.app` (AndroidManifest.xml에서 확인)
3. 앱 닉네임: `Lessonaza Android`
4. `google-services.json` 다운로드
5. 파일 배치: `frontend/android/app/google-services.json`

### Android Gradle 설정

`frontend/android/build.gradle`에 추가:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

`frontend/android/app/build.gradle` 하단에 추가:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## 4. 백엔드 서비스 계정

1. Firebase Console > 프로젝트 설정 > 서비스 계정
2. "새 비공개 키 생성" 클릭
3. JSON 파일 다운로드
4. 서버에 배치 (예: `/etc/secrets/firebase-service-account.json`)
5. 환경변수 설정:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/etc/secrets/firebase-service-account.json"
```

## 5. 설정 파일 확인 체크리스트

| 파일 | 위치 | 용도 |
|------|------|------|
| `GoogleService-Info.plist` | `frontend/ios/Runner/` | iOS Firebase 설정 |
| `google-services.json` | `frontend/android/app/` | Android Firebase 설정 |
| 서비스 계정 JSON | 서버 (gitignore) | 백엔드 FCM 전송 |
| APNs Key (.p8) | Firebase Console에 업로드 | iOS 푸시 전송 |

## 6. 테스트

### Flutter 앱 실행
```bash
cd frontend
flutter run
```

### FCM 토큰 확인
앱 실행 후 로그에서 FCM 토큰 확인:
```
FCM Token: <token_string>
```

### 테스트 푸시 전송
Firebase Console > Cloud Messaging > "첫 번째 캠페인 만들기"에서 테스트 메시지 전송

## 7. 보안 주의사항

- `GoogleService-Info.plist`과 `google-services.json`은 `.gitignore`에 추가
- 서비스 계정 JSON은 절대 코드에 포함하지 않음
- 환경변수로 경로만 전달
