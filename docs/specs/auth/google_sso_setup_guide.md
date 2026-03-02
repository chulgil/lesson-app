# Google SSO 설정 가이드

> 마지막 업데이트: 2026-03-02

Lessonaza 앱에서 Google Sign-In을 사용하기 위한 Google Cloud Console 설정 및 연동 가이드.

---

## 목차

1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [Google Cloud Console 설정](#google-cloud-console-설정)
4. [앱 코드 설정](#앱-코드-설정)
5. [베타 서버 배포](#베타-서버-배포)
6. [테스트 방법](#테스트-방법)
7. [프로덕션 배포 시 추가 작업](#프로덕션-배포-시-추가-작업)
8. [FAQ](#faq)

---

## 개요

### 인증 플로우

```
Flutter 앱 (google_sign_in SDK)
  → Google 로그인 팝업 → 사용자 인증
    → serverAuthCode 획득
      → 백엔드 POST /auth/oauth/google 에 code 전달
        → 백엔드가 Google 토큰 엔드포인트에서 code → access_token 교환
          → Google userinfo API로 사용자 정보 조회
            → JWT 토큰 발급 → 앱에 반환
```

### 비용

| 항목 | 비용 |
|------|------|
| OAuth 동의 화면 설정 | **무료** |
| OAuth 2.0 클라이언트 ID 생성 | **무료** |
| Google Sign-In API 호출 | **무료** (한도 없음) |
| GCP 결제 계정 등록 | **불필요** |

> Google Cloud Console의 OAuth 기능은 완전 무료. 결제 계정은 Compute Engine, Cloud Storage 등 다른 GCP 서비스를 사용할 때만 필요.

---

## 아키텍처

### 클라이언트 ID 구조

베타와 운영은 **동일한 Google Cloud Console 프로젝트**를 사용한다. OAuth 클라이언트 ID도 공유.

```
Google Cloud Console 프로젝트 (1개)
  │
  ├── 웹 애플리케이션 클라이언트 ID (1개) ─── 공유 (베타/운영)
  │     └── Client ID + Client Secret
  │
  ├── iOS 클라이언트 ID (1개) ─── 공유 (베타/운영)
  │     └── Bundle ID: app.lessonaza
  │
  └── Android 클라이언트 ID
        ├── 디버그용 (1개) ─── 개발/베타 테스트
        │     └── 패키지명: app.lessonaza + 디버그 SHA-1
        └── 릴리스용 (1개, 나중에 추가) ─── Play Store 배포
              └── 패키지명: app.lessonaza + 릴리스 SHA-1
```

### 베타 vs 운영 차이점

| 항목 | 베타 | 운영 |
|------|------|------|
| Google Cloud Console | **동일** 프로젝트 | **동일** 프로젝트 |
| 클라이언트 ID | **동일** | **동일** |
| Client Secret | **동일** | **동일** |
| 서버 URL | `beta-lesson.chulgil.me` | `lesson.chulgil.me` |
| 앱 서명 키 | 디버그 키 | 릴리스 키 |
| DB | `lessonaza_beta` | `lessonaza` |

> 앱은 `--dart-define=API_BASE_URL=...`로 서버만 변경하면 된다. Google OAuth 설정은 동일.

---

## Google Cloud Console 설정

### Step 1: 프로젝트 생성

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단 프로젝트 선택 → **새 프로젝트**
   - 프로젝트 이름: `Lessonaza` (또는 기존 프로젝트 사용)
3. 프로젝트 선택 후 진행

### Step 2: OAuth 동의 화면 설정

1. 좌측 메뉴: **API 및 서비스** → **OAuth 동의 화면**
2. 사용자 유형: **외부** 선택 → 만들기
3. 앱 정보 입력:
   - 앱 이름: `Lessonaza`
   - 사용자 지원 이메일: 본인 이메일
   - 개발자 연락처 이메일: 본인 이메일
4. 범위(Scopes): 추가 → `email`, `profile` 선택
5. 테스트 사용자: 테스트에 사용할 Google 계정 이메일 추가 (최대 100명)
6. 저장

> **중요**: 테스트 모드에서는 등록한 테스트 사용자만 로그인 가능. 모든 사용자에게 열려면 프로덕션 모드 전환 + Google 검토 필요 (email/profile만 사용하면 검토가 간단함).

### Step 3: OAuth 클라이언트 ID 생성

좌측 메뉴: **API 및 서비스** → **사용자 인증 정보** → **사용자 인증 정보 만들기** → **OAuth 클라이언트 ID**

#### 3-1. 웹 애플리케이션 (필수 - 가장 먼저 생성)

| 항목 | 값 |
|------|-----|
| 애플리케이션 유형 | 웹 애플리케이션 |
| 이름 | `Lessonaza Web` |
| 승인된 JavaScript 원본 | `https://beta-lesson.chulgil.me`, `https://lesson.chulgil.me` (선택사항) |
| 승인된 리디렉션 URI | **비워두기** (모바일 SDK 방식이라 불필요) |

**결과물**:
- `GOOGLE_CLIENT_ID` (= Web Client ID) → 백엔드 `.env`와 Flutter `--dart-define`에 사용
- `GOOGLE_CLIENT_SECRET` → 백엔드 `.env`에만 사용

> 이 Web Client ID는 Flutter의 `serverClientId`로도 사용된다. 앱에서 `serverAuthCode`를 받을 때 이 ID가 필요.

#### 3-2. iOS

| 항목 | 값 |
|------|-----|
| 애플리케이션 유형 | iOS |
| 이름 | `Lessonaza iOS` |
| 번들 ID | `app.lessonaza` |

**결과물**:
- iOS 클라이언트 ID → `Info.plist`의 URL Scheme에 사용
- 다운로드한 plist 파일에서 `REVERSED_CLIENT_ID` 확인

#### 3-3. Android (디버그용)

| 항목 | 값 |
|------|-----|
| 애플리케이션 유형 | Android |
| 이름 | `Lessonaza Android (debug)` |
| 패키지 이름 | `app.lessonaza` |
| SHA-1 인증서 디지털 지문 | `C2:E9:57:85:A6:85:30:90:01:42:CC:EE:59:BE:04:39:2E:9A:42:E9` |

**SHA-1 확인 명령어**:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

**결과물**:
- Android 클라이언트 ID (앱 코드에서 직접 사용하지 않음, Google Play Services가 자동 처리)

### Step 4: 생성 결과 정리

총 **3개** 클라이언트 ID가 생성됨:

| # | 유형 | 용도 | 결과물 |
|---|------|------|--------|
| 1 | 웹 애플리케이션 | 백엔드 code 교환 + Flutter serverClientId | Client ID + Secret |
| 2 | iOS | iOS 앱 Google 로그인 | iOS Client ID |
| 3 | Android (debug) | Android 앱 Google 로그인 | Android Client ID |

---

## 앱 코드 설정

### 프론트엔드

#### iOS Info.plist

`frontend/ios/Runner/Info.plist`에 Google Sign-In URL Scheme 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- iOS 클라이언트 ID의 reversed client ID -->
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_PREFIX</string>
        </array>
    </dict>
</array>
```

> `YOUR_IOS_CLIENT_ID_PREFIX`는 iOS 클라이언트 ID 생성 후 plist 파일에서 `REVERSED_CLIENT_ID` 값을 복사.

#### Flutter 실행 명령어

```bash
# 베타 서버 연결
flutter run -d macos \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://beta-lesson.chulgil.me/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web Client ID>

# 운영 서버 연결
flutter run -d macos \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://lesson.chulgil.me/api/v1 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web Client ID>
```

### 백엔드

#### 환경변수 (.env.beta)

```env
GOOGLE_CLIENT_ID=<Web Client ID>
GOOGLE_CLIENT_SECRET=<Web Client Secret>
```

> 웹 애플리케이션 클라이언트 ID의 값을 사용. iOS/Android 클라이언트 ID가 아님!

---

## 베타 서버 배포

### 사전 준비

1. DNS: `beta-lesson.chulgil.me` → `108.61.162.25` A 레코드 추가
2. Google Cloud Console에서 3개 클라이언트 ID 생성 완료

### 배포 순서

```bash
# 1. 서버 접속
ssh codenavi

# 2. 소스 pull
cd ~/apps/lessonaza-backend && git pull

# 3. 환경변수 파일 생성 (env.beta.example을 복사)
cp env.beta.example .env.beta
vi .env.beta  # 실제 값 입력

# 4. 베타 DB 생성 (최초 1회)
docker exec mysql mysql -u root -p -e "
  CREATE DATABASE IF NOT EXISTS lessonaza_beta
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS 'lessonaza_beta'@'%' IDENTIFIED BY '<비밀번호>';
  GRANT ALL PRIVILEGES ON lessonaza_beta.* TO 'lessonaza_beta'@'%';
  FLUSH PRIVILEGES;
"

# 5. 베타 컨테이너 빌드 & 실행
docker-compose -f docker-compose.beta.yml up -d --build

# 6. Alembic 마이그레이션
docker-compose -f docker-compose.beta.yml exec app uv run alembic upgrade head

# 7. 시드 데이터
docker-compose -f docker-compose.beta.yml exec app uv run python scripts/seed_data.py

# 8. 헬스체크
curl https://beta-lesson.chulgil.me/health
```

---

## 테스트 방법

### 1. 베타 서버 헬스체크

```bash
curl https://beta-lesson.chulgil.me/health
# 기대 결과: {"status": "ok"}
```

### 2. Dev Login 테스트 (베타 서버)

```bash
curl -X POST https://beta-lesson.chulgil.me/api/v1/auth/dev-login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "role": "teacher", "name": "테스트"}'
```

### 3. Google SSO 테스트

1. Flutter 앱 실행 (베타 서버 연결):
   ```bash
   flutter run -d macos \
     --dart-define=USE_MOCK=false \
     --dart-define=API_BASE_URL=https://beta-lesson.chulgil.me/api/v1 \
     --dart-define=GOOGLE_SERVER_CLIENT_ID=<Web Client ID>
   ```
2. 로그인 화면에서 "Google로 계속하기" 버튼 탭
3. Google 계정 선택 → 로그인
4. 신규 유저: 역할 선택 화면 → 선생님/학생/학부모 선택
5. 기존 유저: 바로 홈 화면 진입

### 4. Google SSO 플로우 검증

| 단계 | 예상 동작 |
|------|---------|
| Google 로그인 팝업 | Google 계정 선택 화면 표시 |
| serverAuthCode 획득 | 앱 → 백엔드에 code 전송 |
| 백엔드 code 교환 | Google 토큰 엔드포인트에서 access_token 획득 |
| 유저 정보 조회 | Google userinfo API에서 email, name, picture 획득 |
| 신규 유저 | role=null → AuthNeedsRole → 역할 선택 화면 |
| 기존 유저 | role 있음 → AuthAuthenticated → 홈 화면 |

---

## 프로덕션 배포 시 추가 작업

### 1. 릴리스 서명 키 생성

```bash
keytool -genkey -v \
  -keystore lessonaza-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias lessonaza

# SHA-1 확인
keytool -list -v -keystore lessonaza-release.jks -alias lessonaza
```

### 2. Android 클라이언트 ID 추가 (릴리스용)

Google Cloud Console에서 **새 Android 클라이언트 ID** 생성:

| 항목 | 값 |
|------|-----|
| 이름 | `Lessonaza Android (release)` |
| 패키지 이름 | `app.lessonaza` |
| SHA-1 | 릴리스 키의 SHA-1 |

> Play App Signing 사용 시: Play Console > 설정 > 앱 서명에서 SHA-1 확인

### 3. OAuth 동의 화면 프로덕션 전환

1. Google Cloud Console → OAuth 동의 화면
2. "앱 게시" 클릭 → 프로덕션 모드 전환
3. email/profile scope만 사용하면 Google 검토가 간단함 (보통 자동 승인)

### 4. 최종 클라이언트 ID 현황

| # | 유형 | 이름 | 용도 |
|---|------|------|------|
| 1 | 웹 애플리케이션 | Lessonaza Web | 백엔드 code 교환 |
| 2 | iOS | Lessonaza iOS | iOS 앱 |
| 3 | Android (debug) | Lessonaza Android (debug) | 개발/베타 테스트 |
| 4 | Android (release) | Lessonaza Android (release) | Play Store 배포 |

---

## FAQ

### Q: 베타와 운영에서 같은 클라이언트 ID를 사용해도 되나?
**A: 네.** 클라이언트 ID는 앱을 식별하는 것이지 서버를 식별하는 것이 아닙니다. 앱이 어떤 서버를 바라보는지는 `--dart-define`으로 제어합니다.

### Q: GCP 유료 결제가 필요한가?
**A: 아니요.** OAuth 2.0은 완전 무료입니다. 결제 계정 없이 사용 가능합니다.

### Q: 승인된 리디렉션 URI에 뭘 넣어야 하나?
**A: 비워두세요.** 모바일 SDK 방식(serverAuthCode)은 브라우저 리다이렉션이 없으므로 redirect URI가 불필요합니다.

### Q: 테스트 모드에서 다른 사람이 로그인할 수 있나?
**A: 아니요.** 테스트 모드에서는 동의 화면의 "테스트 사용자"에 등록한 Google 계정만 로그인 가능합니다 (최대 100명).

### Q: Android 디버그 키와 릴리스 키의 차이는?
**A:** 디버그 키는 `~/.android/debug.keystore`에 자동 생성되는 공용 키. 릴리스 키는 직접 생성하는 고유 키로 Play Store 배포에 사용합니다. 각각 SHA-1이 다르므로 별도 클라이언트 ID가 필요합니다.

### Q: SHA-1은 서버에 등록하는 건가?
**A: 아니요.** Google Cloud Console 웹사이트에만 등록합니다. 서버(codenavi)와는 무관합니다. SHA-1은 앱 서명 키의 지문(fingerprint)일 뿐입니다.

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `backend/docker-compose.beta.yml` | 베타 Docker Compose |
| `backend/env.beta.example` | 베타 환경변수 템플릿 |
| `backend/app/services/auth_service.py` | OAuth 인증 서비스 |
| `backend/app/api/v1/auth.py` | 인증 API 엔드포인트 |
| `frontend/lib/core/config/environment.dart` | 환경 설정 (GOOGLE_SERVER_CLIENT_ID) |
| `frontend/lib/features/auth/presentation/screens/login_screen.dart` | 로그인 화면 (Google Sign-In 호출) |
| `frontend/lib/features/auth/presentation/screens/role_select_screen.dart` | 역할 선택 화면 |
| `frontend/lib/features/auth/data/repositories/remote_auth_repository.dart` | 백엔드 API 호출 |
| `frontend/ios/Runner/Info.plist` | iOS Google URL Scheme |
| `frontend/android/app/build.gradle.kts` | Android 패키지명 (app.lessonaza) |
