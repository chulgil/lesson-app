# Authentication Flow

> 마지막 업데이트: 2026-03-02

## 개요

Google/Kakao/Apple OAuth 소셜 로그인 + JWT 토큰 기반 인증 시스템.
Flutter 앱에서 OAuth WebView(또는 네이티브 SDK)로 인증 후, 백엔드에서 JWT 토큰 쌍을 발급한다.

### 지원 Provider

| Provider | 대상 국가 | 비고 |
|----------|----------|------|
| Google | 전체 | 글로벌 기본 로그인 |
| Kakao | 한국 | 한국 사용자 주력 |
| Apple | 전체 (iOS 필수) | App Store 정책상 iOS 필수 |

> **향후 확장 고려**: LINE (일본), Facebook (미국/유럽)

---

## 인증 플로우

### 1. 소셜 로그인 (OAuth 2.0)

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Flutter App    │     │   Backend API    │     │  OAuth Provider  │
│                  │     │                  │     │ (Google/Kakao)   │
└────────┬─────────┘     └────────┬─────────┘     └────────┬─────────┘
         │                        │                        │
         │  1. OAuth WebView      │                        │
         │───────────────────────────────────────────────→ │
         │                        │                        │
         │  2. User consent       │                        │
         │ ←──────────────────────────────────────────────│
         │                        │                        │
         │  3. Authorization code │                        │
         │ ←──────────────────────────────────────────────│
         │                        │                        │
         │  4. POST /auth/oauth/{provider}                │
         │  { code, redirect_uri }│                        │
         │───────────────────────→│                        │
         │                        │                        │
         │                        │  5. Exchange code      │
         │                        │  for access_token      │
         │                        │───────────────────────→│
         │                        │                        │
         │                        │  6. Get user info      │
         │                        │ ←──────────────────────│
         │                        │                        │
         │                        │  7. Find or create     │
         │                        │  user + oauth_account  │
         │                        │                        │
         │  8. JWT tokens         │                        │
         │  { access, refresh,    │                        │
         │    user }              │                        │
         │ ←──────────────────────│                        │
```

### 2. API 호출 인증

```
Flutter App → API Request
  Header: Authorization: Bearer {access_token}

Backend:
  1. JWT 디코딩 → user_id 추출
  2. DB에서 User 조회
  3. 역할(role) 기반 권한 확인
  4. 요청 처리
```

### 3. 토큰 갱신

```
Flutter App                          Backend API
     │                                    │
     │  access_token 만료 (401)           │
     │ ←──────────────────────────────────│
     │                                    │
     │  POST /auth/token/refresh          │
     │  { refresh_token }                 │
     │───────────────────────────────────→│
     │                                    │
     │  { new access_token }              │
     │ ←──────────────────────────────────│
```

---

## JWT 토큰 구조

### Access Token (30분)

```json
{
  "sub": "user_uuid",
  "role": "teacher",
  "exp": 1709424000,
  "iat": 1709422200,
  "type": "access"
}
```

### Refresh Token (30일)

```json
{
  "sub": "user_uuid",
  "exp": 1712016000,
  "iat": 1709422200,
  "type": "refresh",
  "jti": "unique_token_id"
}
```

### 토큰 설정

| 항목 | 값 | 비고 |
|------|-----|------|
| Algorithm | HS256 | HMAC-SHA256 |
| Access TTL | 30분 | 짧은 수명 |
| Refresh TTL | 30일 | 긴 수명 |
| Secret Key | env | `.env`에서 로딩 |

---

## OAuth Provider 설정

### Google OAuth 2.0

```python
GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"
GOOGLE_SCOPES = ["openid", "email", "profile"]
```

**Google 응답 필드:**
- `id` → provider_user_id
- `email` → email
- `name` → name
- `picture` → profile_image_url

### Kakao OAuth 2.0

```python
KAKAO_AUTH_URL = "https://kauth.kakao.com/oauth/authorize"
KAKAO_TOKEN_URL = "https://kauth.kakao.com/oauth/token"
KAKAO_USERINFO_URL = "https://kapi.kakao.com/v2/user/me"
KAKAO_SCOPES = ["profile_nickname", "profile_image", "account_email"]
```

**Kakao 응답 필드:**
- `id` → provider_user_id
- `kakao_account.email` → email
- `kakao_account.profile.nickname` → name
- `kakao_account.profile.profile_image_url` → profile_image_url

### Apple Sign In

> **중요**: Apple은 다른 OAuth와 플로우가 다르다. Authorization code가 아닌 **identity_token (JWT)**을 직접 검증한다.

```python
APPLE_AUTH_URL = "https://appleid.apple.com/auth/authorize"
APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token"
APPLE_KEYS_URL = "https://appleid.apple.com/auth/keys"  # JWT 공개키
APPLE_SCOPES = ["name", "email"]
```

**Apple 인증 플로우 (다른 Provider와 차이점):**

```
Flutter App (sign_in_with_apple 패키지)
  → Apple 네이티브 로그인 UI
  → identity_token (JWT) + authorization_code + user (첫 로그인만)
  → Backend: POST /auth/oauth/apple
    → identity_token JWT 검증 (Apple 공개키로)
    → JWT에서 sub (provider_user_id), email 추출
    → user 정보는 첫 로그인 때만 Apple이 제공 → 반드시 저장
```

**Apple 특이사항:**
- `identity_token`: Apple이 서명한 JWT → 백엔드에서 Apple 공개키로 검증
- **이름/이메일은 최초 1회만 전달**: 첫 로그인 시 반드시 저장해야 함
- `sub` 필드: Apple user ID (provider_user_id로 사용)
- **Hide My Email**: 사용자가 이메일 비공개 선택 시 `xxxxx@privaterelay.appleid.com` 릴레이 주소 제공
- **App Store 정책**: iOS 앱에서 소셜 로그인 제공 시 Apple Sign In 필수

**Apple identity_token JWT 구조:**
```json
{
  "iss": "https://appleid.apple.com",
  "aud": "com.lessonapp.app",
  "exp": 1709424000,
  "iat": 1709422200,
  "sub": "001234.abcdef1234567890.0123",
  "email": "user@example.com",
  "email_verified": "true",
  "is_private_email": "false"
}
```

**Apple 검증 로직:**
```python
import jwt
from jwt import PyJWKClient

APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"

async def verify_apple_identity_token(identity_token: str) -> dict:
    """Apple identity_token을 검증하고 사용자 정보를 반환."""
    jwks_client = PyJWKClient(APPLE_JWKS_URL)
    signing_key = jwks_client.get_signing_key_from_jwt(identity_token)

    payload = jwt.decode(
        identity_token,
        signing_key.key,
        algorithms=["RS256"],
        audience=settings.apple_client_id,  # Bundle ID
        issuer="https://appleid.apple.com",
    )

    return {
        "id": payload["sub"],           # Apple user ID
        "email": payload.get("email"),   # 첫 로그인 또는 비공개 아닐 때만
        "is_private_email": payload.get("is_private_email") == "true",
    }
```

**Request 차이점 (Apple):**
```json
{
  "identity_token": "eyJraWQiOiJXNldjT...",
  "authorization_code": "c1234567890...",
  "user": {
    "name": { "firstName": "길동", "lastName": "홍" },
    "email": "user@example.com"
  }
}
```
> `user` 필드는 **최초 로그인 시에만** Apple이 전달. 이후에는 null.

---

## API 엔드포인트

### POST /auth/oauth/{provider}

소셜 로그인 처리. `provider` = `google` | `kakao` | `apple`

**Request (Google/Kakao):**
```json
{
  "code": "authorization_code",
  "redirect_uri": "com.lessonapp://oauth/callback"
}
```

**Request (Apple):**
```json
{
  "identity_token": "eyJraWQiOiJXNldjT...",
  "authorization_code": "c1234567890...",
  "user": {
    "name": { "firstName": "길동", "lastName": "홍" },
    "email": "user@example.com"
  }
}
```

**처리 로직:**
```python
async def oauth_login(provider: str, request: OAuthRequest, db: AsyncSession):
    if provider == "apple":
        # Apple: identity_token JWT 직접 검증
        user_info = await verify_apple_identity_token(request.identity_token)
        # user 필드는 첫 로그인 때만 존재 → 반드시 저장
        if request.user:
            user_info["name"] = f"{request.user.name.lastName}{request.user.name.firstName}"
            user_info["email"] = request.user.email or user_info.get("email")
    else:
        # Google/Kakao: authorization code → access_token 교환 → user info
        provider_token = await exchange_code(provider, request.code, request.redirect_uri)
        user_info = await get_user_info(provider, provider_token)

    # OAuth 계정 찾기
    oauth_account = await db.scalar(
        select(OAuthAccount).where(
            OAuthAccount.provider == provider,
            OAuthAccount.provider_user_id == user_info["id"],
        )
    )

    if oauth_account:
        # 기존 사용자
        user = await db.get(User, oauth_account.user_id)
    else:
        # 신규 사용자 생성
        # locale은 클라이언트 Accept-Language 또는 요청에서 추출
        user = User(
            email=user_info.get("email", f"{user_info['id']}@noemail.local"),
            name=user_info.get("name", ""),
            profile_image_url=user_info.get("picture"),
            role=None,  # 온보딩에서 선택
            locale=request.locale or "ko",
            country=request.country or "KR",
            timezone=request.timezone or "Asia/Seoul",
        )
        db.add(user)
        await db.flush()

        oauth_account = OAuthAccount(
            user_id=user.id,
            provider=provider,
            provider_user_id=user_info["id"],
            provider_email=user_info.get("email"),
        )
        db.add(oauth_account)

    # JWT 발급
    access_token = create_access_token(user.id, user.role)
    refresh_token = create_refresh_token(user.id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=UserRead.model_validate(user),
    )
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "홍길동",
    "role": "teacher",
    "profile_image_url": "https://...",
    "locale": "ko",
    "country": "KR",
    "timezone": "Asia/Seoul"
  }
}
```

### POST /auth/token/refresh

Access 토큰 갱신.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

### POST /auth/logout

로그아웃 (Refresh 토큰 무효화).

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

### GET /auth/me

현재 사용자 정보.

**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John",
  "role": "teacher",
  "profile_image_url": "https://...",
  "created_at": "2026-03-02T12:00:00Z"
}
```

---

## 역할 기반 접근 제어 (RBAC)

### 역할 정의

| 역할 | 설명 | 접근 범위 |
|------|------|----------|
| `teacher` | 선생님 | 자기 학생/레슨/클래스 관리 |
| `student` | 학생 | 자기 연습/레슨 조회 |
| `parent` | 학부모 | 자녀 레슨/연습 조회 |

### 권한 매트릭스

| 리소스 | Teacher | Student | Parent |
|--------|---------|---------|--------|
| Students CRUD | ✅ (자기 학생) | ❌ | ❌ |
| Lessons CRUD | ✅ | 🔍 (조회) | 🔍 (자녀) |
| Subscriptions | ✅ (관리) | 🔍 + 응답 | 🔍 (자녀) |
| Practice | 🔍 (학생 것) | ✅ (자기 것) | 🔍 (자녀) |
| Recordings | 🔍 | ✅ (자기 것) | 🔍 (자녀) |
| Schedule | ✅ (자기 것) | 🔍 | ❌ |
| Bookings | ✅ (관리) | ✅ (예약) | ✅ (자녀 대리) |
| Tuition Deposit Status | ✅ (수강권 입금 확인) | ✅ (입금 완료 알림) | ✅ (자녀 입금 완료 알림) |
| Notifications | ✅ | ✅ | ✅ |

### 의존성 주입 패턴

```python
# Role-specific dependencies
async def get_current_teacher(user = Depends(get_current_user)) -> Teacher: ...
async def get_current_student(user = Depends(get_current_user)) -> Student: ...
async def get_current_parent(user = Depends(get_current_user)) -> Parent: ...

# Usage in router
@router.get("/students")
async def list_students(
    teacher: Teacher = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
):
    # Only returns students belonging to this teacher
    ...
```

---

## Flutter 클라이언트 구현

### 토큰 저장

```dart
// flutter_secure_storage 사용
class AuthStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final storage = FlutterSecureStorage();

  Future<void> saveTokens(String access, String refresh) async {
    await storage.write(key: _accessKey, value: access);
    await storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> getAccessToken() => storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => storage.read(key: _refreshKey);
  Future<void> clearTokens() => storage.deleteAll();
}
```

### HTTP 인터셉터

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = authStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try refresh
      final newToken = await refreshToken();
      if (newToken != null) {
        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      }
      // Refresh failed → logout
      await logout();
    }
    handler.next(err);
  }
}
```

---

## 보안 고려사항

| 항목 | 대응 |
|------|------|
| JWT Secret | `.env` 환경변수, 서버에만 존재 |
| Refresh Token 재사용 | `jti` (JWT ID)로 일회성 보장 |
| HTTPS | Nginx + Let's Encrypt SSL |
| CORS | 허용 origin 명시적 설정 |
| Rate Limiting | `/auth/*` 엔드포인트 분당 10회 제한 |
| Token Blacklist | 로그아웃 시 refresh token을 DB/Redis에 블랙리스트 |
| Password | 소셜 로그인 전용 → 비밀번호 없음 |
| OAuth State | PKCE + state 파라미터로 CSRF 방어 |
| Apple JWT 검증 | Apple 공개키(JWKS)로 identity_token 서명 검증 |
| Apple 이메일 릴레이 | `@privaterelay.appleid.com` 주소 허용 |
| Apple 이름 저장 | 최초 1회만 전달 → oauth_accounts에 provider_name 저장 |

---

## DB 스키마 (인증 관련)

```sql
-- users 테이블 (i18n 필드 포함)
CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('teacher', 'student', 'parent') DEFAULT NULL,
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    -- i18n fields
    locale VARCHAR(10) NOT NULL DEFAULT 'ko' COMMENT 'IETF BCP 47: ko, en, ja',
    country VARCHAR(2) NOT NULL DEFAULT 'KR' COMMENT 'ISO 3166-1 alpha-2: KR, US, JP',
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Seoul' COMMENT 'IANA timezone',
    currency VARCHAR(3) NOT NULL DEFAULT 'KRW' COMMENT 'ISO 4217: KRW, USD, JPY',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- OAuth 계정 (Apple 포함)
CREATE TABLE oauth_accounts (
    id CHAR(36) PRIMARY KEY,
    user_id CHAR(36) NOT NULL,
    provider ENUM('google', 'kakao', 'apple') NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    provider_email VARCHAR(255),
    -- Apple 전용: 첫 로그인 때 받은 이름 저장
    provider_name VARCHAR(100),
    is_private_email BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Apple Hide My Email',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_provider_user (provider, provider_user_id)
);

-- Refresh 토큰 블랙리스트
CREATE TABLE token_blacklist (
    id CHAR(36) PRIMARY KEY,
    jti VARCHAR(255) NOT NULL UNIQUE,
    user_id CHAR(36) NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_jti (jti),
    INDEX idx_expires (expires_at)
);
```

---

## 온보딩 플로우

```
1. 소셜 로그인 → user.role = NULL
2. GET /auth/me → role 확인
3. role이 NULL → 온보딩 화면
4. locale/country 자동 설정 (기기 설정 기반) 또는 수동 선택
5. PUT /users/me/role → { role: "teacher" | "student" | "parent" }
6. PUT /users/me/locale → { locale: "ko", country: "KR", timezone: "Asia/Seoul" }
7. 역할별 프로필 생성:
   - teacher → POST /teachers (TeacherProfile 생성)
   - student → (선생님이 등록)
   - parent → POST /parents (Parent 프로필 생성)
8. 온보딩 완료
```

---

## 국가별 Provider 전략

| 국가 | 기본 Provider | 보조 Provider | 비고 |
|------|--------------|--------------|------|
| 한국 (KR) | Kakao | Google, Apple | 카카오가 주력 |
| 미국 (US) | Google | Apple | 카카오 비노출 |
| 일본 (JP) | Google | Apple | 향후 LINE 추가 고려 |
| 기타 | Google | Apple | 글로벌 기본 |

Flutter 앱에서 `country` 기반으로 로그인 버튼 노출 순서/가시성 제어.
iOS에서는 Apple Sign In 버튼 항상 표시 (App Store 정책).
