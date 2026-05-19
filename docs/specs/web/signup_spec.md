# signup_spec — SSO 기반 가입 흐름 (선생님 / 학생)

> 기준일: 2026-05-19 (v3 — Option D 정렬)
> 도메인: `lessonaza.app/signup` (www), `profile.lessonaza.app/{slug}` (profile)
> 선행: [www_spec.md](www_spec.md), [profile_spec.md](profile_spec.md), [../profile/public_profile_content_spec.md](../profile/public_profile_content_spec.md), [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md), [account_lifecycle_spec.md](../user/account_lifecycle_spec.md)

## 1. 개요

웹에서 lesson-app 계정을 생성하는 1차 채널. **이메일+비밀번호 가입은 제공하지 않으며, SSO (구글/카카오/Apple) 만 사용**. 가입 즉시 lesson-app 백엔드에 정상 계정으로 저장된다.

### 1.1 목표 (3가지)

1. **웹 가입 편의** — SSO 30초 가입. 별도 비밀번호 생성·기억 부담 없음
2. **프로필 외부 공유** — 선생님은 가입 후 즉시 `profile.lessonaza.app/{slug}` 발급, 카카오톡/SNS 외부 공유 가능
3. **앱 홍보** — 가입 완료 후 앱 다운로드 CTA 노출. 가입자가 앱을 안 써도 프로필은 영구 유지

### 1.2 책임

- SSO 인증 흐름 (구글/카카오/Apple) + IdP 콜백 처리
- 약관/개인정보 동의 + 버전 기록 (SSO 콜백 직후 1회)
- 선생님: slug 선점 + `TeacherProfile` 자동 초기화 (status=draft)
- 학생: 별도 가입 흐름 (선생님과 분리)

### 1.3 비책임

- 이메일+비밀번호 가입 (M4 제공 안 함)
- 이메일 인증 토큰 (IdP가 검증)
- 결제 (해당 없음 — 가입은 무료)
- 학생 → 선생님 역할 전환 (별도 기획)
- 14세 미만 자녀 (`account_lifecycle_spec §3` 참조 — 부모 계정 자녀 프로필 경로)

## 2. 성공 기준

- [SC-1] SSO 버튼 클릭 → IdP 동의 → 약관 동의 → 계정 활성화까지 1분 이내
- [SC-2] 선생님 가입 시 slug 발급 + `TeacherProfile` 자동 초기화 (status=draft) + 인앱 편집 화면 진입. 첫 운영자 검토 통과 후 `profile.lessonaza.app/{slug}` 공개
- [SC-3] 가입자가 lesson-app 앱 로그인 시 동일 SSO 자격으로 정상 인증 (M5 이후 — M4 백엔드만 SSO)
- [SC-4] 약관 미동의 상태로 IdP 콜백만 완료된 계정은 **활성화되지 않음** (`terms_version_agreed` 미기록 = 가입 미완료 상태)
- [SC-5] slug 중복/예약어/형식 위반은 클라이언트 검증 + 서버 재검증
- [SC-6] 모든 동의는 `terms_versions` 테이블에 버전 + 시각 + IP 기록
- [SC-7] 같은 IdP 식별자(provider + provider_user_id) + 같은 역할 조합은 **하나의 User 만** 존재 (3-tuple unique)

## 3. IdP 출시 범위

| IdP | M4 (웹) | M5 (앱) | 비고 |
|---|---|---|---|
| **Google** | 포함 | 포함 | 글로벌 + 개발자 친숙, OAuth 2.0 Authorization Code + PKCE |
| **Kakao** | 포함 | 포함 | 한국 시장 90%+, 이메일 선택 동의 → 미동의 시 가입 거부 |
| **Apple** | 미포함 | 포함 (iOS 앱 출시 시점) | App Store 가이드라인 §4.8 강제. 웹은 M5에 함께 추가 검토 |

### 3.1 운영자/어드민 SSO 분리

- 일반 사용자 SSO 풀과 **별도 IdP 키** 사용 (운영자 노출 위험 차단)
- 운영자: **Google Workspace SSO** + 도메인 제한 (`@lessonaza.app` 만 허용) + 2FA 강제
- 어드민 진입점: `admin.lessonaza.app/login` (별도 서브도메인)

## 4. 역할 분리 — 선생님 / 학생 / 학부모

### 4.1 가입 진입점

| 진입 | URL | 대상 |
|---|---|---|
| 선생님 | `lessonaza.app/teachers` → `lessonaza.app/signup?role=teacher` | 레슨 제공자 |
| 학생 | `lessonaza.app/signup?role=student` | 레슨 수강자 |
| 학부모 | `lessonaza.app/signup?role=parent` (Year 1: 학생과 동일 흐름, role만 다름) | 자녀 관리자 |

### 4.2 별도 계정 원칙 (3-tuple unique)

- `auth_identities(provider, provider_user_id, role)` **3-tuple unique** 제약
- 같은 구글 계정으로 **선생님 + 학부모 별도 User 가능** (역할이 다르므로)
- 같은 구글 계정 + 같은 역할로 두 번 가입 시도 → 기존 계정 로그인으로 처리
- 데이터 모델: `User.role` enum (`teacher` | `student` | `parent` | `academy_owner`)

### 4.3 계정 연동 (다른 IdP, 같은 이메일)

- 구글로 가입한 사용자가 같은 이메일의 카카오로 로그인 시도 → **자동 연동하지 않음**
- 충돌 안내: "이 이메일은 이미 구글로 가입되어 있습니다. 구글로 로그인 후 [계정 연동] 메뉴에서 카카오를 추가하세요"
- 명시적 연동 흐름: 본 계정 로그인 → `/settings/linked-accounts` → 추가 IdP 인증 → `auth_identities` 행 추가

근거: IdP 이메일 변경 가능성 → 자동 연동 시 탈취 위험 (피해 사례: 카카오 이메일 변경 후 타인 계정 접근)

## 5. 가입 흐름

### 5.1 선생님 가입 (SSO)

```
1. lessonaza.app/teachers → "선생님으로 가입" CTA
2. /signup?role=teacher 페이지: 3개 SSO 버튼 (M4: 구글/카카오. M5: Apple 추가)
3. [구글로 가입] 클릭
   → GET /api/v1/auth/oauth/google/authorize?role=teacher
   → 백엔드가 state 토큰 발급 + 구글 OAuth URL 리다이렉트 (PKCE code_verifier 서버 저장)
4. 구글 동의 화면 → 사용자 승인
5. 구글 → 백엔드 callback (code + state)
   → POST /api/v1/auth/oauth/google/callback
   → 백엔드 처리:
     a. state 검증 (CSRF 방어)
     b. code → access_token 교환 (PKCE code_verifier 첨부)
     c. UserInfo 조회: { sub, email, email_verified, name }
     d. email_verified == false 또는 email 누락 → 가입 거부 ("이메일 인증된 계정만 가입 가능")
     e. auth_identities 조회: (google, sub, teacher) 매치 시 → 기존 User 로그인
     f. 매치 없음 → 신규 가입 흐름으로 진입 (아직 User 미생성)
   → 응답: { signup_session_token, prefilled: { email, display_name } }
6. /signup/complete?role=teacher 페이지 (신규 가입 시):
   - prefilled 정보 표시 (이메일, 이름 — 변경 가능)
   - profile_slug 입력 (실시간 중복 체크)
   - 분야 태그 (violin, piano 등) — 1개 이상
   - 활동 지역 (선택, 자유 텍스트)
   - 휴대폰 (선택, Year 2 SMS 알림 대비)
   - 약관 동의 + 개인정보 동의 (필수, 버전 기록)
   - 마케팅 수신 동의 (선택)
7. POST /api/v1/auth/signup/complete
   Headers: Authorization: Bearer {signup_session_token}
   Body: {
     "role": "teacher",
     "display_name": "이지원",
     "profile_slug": "jiwon-lee",
     "lesson_genres": ["violin"],
     "phone": null,
     "terms_version": "v1.2.0",
     "privacy_version": "v1.1.0",
     "marketing_consent": false
   }
8. 백엔드 처리:
   a. signup_session_token 검증 (IdP 인증 완료 + 미가입 상태)
   b. slug 중복/예약어/형식 검증 (slug_lifecycle_spec §3)
   c. User 레코드 생성 (signup_source="web", email_verified_at=now())
        ※ password_hash 없음 (M4 nullable, M5에 drop)
   d. auth_identities 레코드 생성 (provider, provider_user_id, role)
   e. SlugHistory 레코드 생성 (assigned_at=now)
   f. Teacher 레코드 생성 (profile_slug 매핑, profile_visibility="draft")
   g. TeacherProfile 레코드 생성 (teacher_id FK 1:1, status="draft", headline/bio_long 비어 있음) — public_profile_content_spec §8
   h. terms_versions 레코드 생성 (동의 증거 보존)
   i. AuditLog: signup_completed
   j. JWT 발급
9. 응답: 201 Created + { access_token, profile_edit_deeplink }
10. lesson-app 인앱 편집 화면으로 안내 (앱 미설치 시 스토어 CTA)
```

### 5.2 학생 가입 (SSO)

```
1. /signup?role=student 페이지: 3개 SSO 버튼
2. [카카오로 가입] 클릭 → OAuth 흐름 (5.1 와 동일 골격)
3. 카카오 callback → 이메일 동의 확인:
   - 이메일 동의 누락 시 → 가입 거부 ("이메일 정보 동의 필요")
   - 이메일 동의 OK → /signup/complete?role=student
4. 가입 완료 폼:
   - prefilled 이름 표시 (변경 가능)
   - 생년월일 (만 14세 미만 판정 → 부모 계정 안내 — account_lifecycle_spec §3)
   - 약관/개인정보 동의
5. 14세 미만이면 즉시 차단 → 부모 가입 페이지로 리다이렉트
6. POST /api/v1/auth/signup/complete → User 생성 (slug/Ghost Page 없음)
7. 가입 완료 → "선생님 찾기" 또는 "앱 다운로드" CTA
```

학생 가입은 선생님과 흐름 골격은 동일하나 **slug/TeacherProfile 발급 없음**.

### 5.3 미완료 가입 정리

SSO 인증은 완료했으나 약관 동의/slug 입력 단계에서 이탈한 경우:
- `signup_session_token` 만 발급된 상태 — User 미생성
- 세션 토큰 만료: 1시간 (재시도 시 SSO 처음부터)
- 별도 정리 배치 불필요 (User 자체가 없음)

## 6. IdP 콜백 처리 상세

### 6.1 Google (OAuth 2.0 + PKCE)

| 단계 | 처리 |
|---|---|
| Authorize URL | `https://accounts.google.com/o/oauth2/v2/auth` + `code_challenge` (PKCE) |
| Scopes | `openid email profile` |
| UserInfo | `https://openidconnect.googleapis.com/v1/userinfo` |
| 식별자 | `sub` (Google account ID, 영구 불변) |
| 이메일 검증 | `email_verified=true` 필수 |

### 6.2 Kakao (OAuth 2.0)

| 단계 | 처리 |
|---|---|
| Authorize URL | `https://kauth.kakao.com/oauth/authorize` |
| Scopes | `account_email profile_nickname` (이메일 선택 동의) |
| UserInfo | `https://kapi.kakao.com/v2/user/me` |
| 식별자 | `id` (Kakao account ID) |
| 이메일 검증 | `kakao_account.email_needs_agreement=false` AND `kakao_account.is_email_valid=true` 필수 |
| **이메일 미제공 처리** | **가입 거부** (안내: "카카오 가입 시 이메일 정보 동의가 필요합니다") |

### 6.3 Apple (M5)

| 단계 | 처리 |
|---|---|
| Authorize URL | `https://appleid.apple.com/auth/authorize` |
| Scopes | `name email` |
| 식별자 | `sub` (Apple user ID, app-specific) |
| Private Relay | relay 이메일 그대로 저장 (Apple 포워딩 보장) |
| 이름 제공 | 최초 동의 시에만 제공 → 첫 콜백에서 반드시 저장 |

## 7. 약관 동의 (SSO 콜백 직후)

### 7.1 동의 화면

- SSO 콜백 후 `/signup/complete` 페이지에서 1회 노출
- 약관/개인정보 (필수) + 마케팅 (선택) 체크박스
- 약관/개인정보 미체크 시 가입 완료 버튼 비활성화

### 7.2 terms_versions 기록

`POST /api/v1/auth/signup/complete` 처리 시:
- `document_type="terms"`, `version="v1.2.0"`, IP, UA, agreed_at 기록
- `document_type="privacy"`, `version="v1.1.0"` 동일 기록
- 마케팅 동의는 `marketing_consent=true` 시에만 `document_type="marketing"` 행 추가

## 8. 백엔드 API (M4 — SSO 기준)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/auth/oauth/google/authorize?role=...` | 구글 OAuth URL 생성 + state 발급 |
| GET | `/api/v1/auth/oauth/kakao/authorize?role=...` | 카카오 OAuth URL 생성 + state 발급 |
| POST | `/api/v1/auth/oauth/google/callback` | 구글 콜백 처리 (code + state → signup_session_token 또는 JWT) |
| POST | `/api/v1/auth/oauth/kakao/callback` | 카카오 콜백 처리 |
| POST | `/api/v1/auth/signup/complete` | 약관 동의 + 역할별 추가 정보 → User/Teacher 생성. 선생님이면 `TeacherProfile`(status=draft) 동시 초기화 |
| POST | `/api/v1/auth/logout` | 세션 종료 |
| GET | `/api/v1/teachers/me/profile` | 본인 `TeacherProfile` 조회 (편집용 원본) |
| PUT | `/api/v1/teachers/me/profile` | 본인 `TeacherProfile` 수정 (`bio_long` markdown → `bio_long_html` sanitize) |
| POST | `/api/v1/teachers/me/profile/submit-review` | draft → review 전환 (운영자 검토 큐 진입) |
| POST | `/api/v1/teachers/me/profile/publish` | 첫 승인 이력 있는 선생님의 직접 public 전환 |
| POST | `/api/v1/teachers/me/profile/unpublish` | public → draft 되돌리기 |
| POST | `/api/v1/teachers/me/profile/images` | 이미지 업로드 (Vultr Object Storage presigned URL) |
| DELETE | `/api/v1/teachers/me/profile/images/{image_id}` | 이미지 삭제 |
| POST | `/api/v1/teachers/me/profile/preview` | 게시 전 미리보기 토큰 발급 |
| GET | `/api/v1/teachers/me/profile/slug/check?slug=...` | slug 가용성 확인 |
| PUT | `/api/v1/teachers/me/profile/slug` | slug 변경 (Year 1: 60일 내 1회만 — slug_lifecycle §4 참조) |
| GET | `/api/v1/users/me/linked-accounts` | 본인 연동 IdP 목록 |
| POST | `/api/v1/users/me/linked-accounts/{provider}` | 추가 IdP 연동 (본 계정 로그인 상태에서) |
| DELETE | `/api/v1/users/me/linked-accounts/{provider}` | 연동 해제 (최소 1개 IdP 유지 강제) |

상세 endpoint 스펙 (운영자 검토 큐, 내부 by-slug API 포함) 은 [backend_architecture.md](../backend/backend_architecture.md) §API + [public_profile_content_spec.md](../profile/public_profile_content_spec.md) §7.

### 8.1 권한 격리 (Option D)

모든 `/teachers/me/profile/*` 엔드포인트는:
```python
async def get_my_profile(current_user: User = Depends(require_teacher)):
    if current_user.role != "teacher":
        raise HTTPException(403)
    teacher = await teacher_service.get_by_user_id(current_user.id)
    return await teacher_profile_repo.get_by_teacher_id(teacher.id)
```

- 콘텐츠 SSOT 는 PostgreSQL `teacher_profiles` 테이블 — 외부 CMS 의존 없음
- 다른 선생님 `teacher_id` 조작은 백엔드 권한 체크로 차단 (서버가 `current_user` 의 teacher_id 강제)
- 공개 페이지는 web VPS 의 `profile-renderer` 가 내부 API (X-Internal-API-Token + IP whitelist) 로 읽기

### 8.2 앱 SSO (M5 별도 마일스톤)

- M4 범위: 백엔드 OAuth 흐름 + 웹 로그인만
- M5 범위: Flutter 앱 SSO (google_sign_in / kakao_flutter_sdk / sign_in_with_apple) + dev-login 대체 + 시드 데이터 SSO 식별자 매핑
- `signup_source="web"` 메타데이터는 분석용

## 9. 데이터 모델 변경

### 9.1 User 모델 (확장 필드)

```python
class User(Base):
    # 기존 필드 ...
    role = Column(Enum("teacher", "student", "parent", "academy_owner"), nullable=False)
    signup_source = Column(String(20), default="app")  # "app" | "web"
    email_verified_at = Column(DateTime, nullable=True)  # SSO 콜백 시 즉시 셋
    terms_version_agreed = Column(String(20), nullable=False)
    privacy_version_agreed = Column(String(20), nullable=False)
    marketing_consent = Column(Boolean, default=False)
    last_activity_at = Column(DateTime, default=func.now(), index=True)
    last_app_login_at = Column(DateTime, nullable=True)
    # password_hash 는 M4 에 nullable, M5(앱 SSO 전환 후) 에 drop 예정
```

### 9.2 Teacher 모델 (확장 필드)

```python
class Teacher(Base):
    # 기존 필드 ...
    profile_slug = Column(String(30), unique=True, nullable=True)
    profile_url = Column(String(500), nullable=True)  # https://profile.lessonaza.app/{slug}
    profile_visibility = Column(String(20), default="draft")  # draft|public|dormant|archived
    # 휴면 트래킹 (slug_lifecycle_spec 참조)
    dormant_notice_6m_at = Column(DateTime, nullable=True)
    dormant_notice_9m_at = Column(DateTime, nullable=True)
    dormant_entered_at = Column(DateTime, nullable=True)
    slug_released_at = Column(DateTime, nullable=True)
    # 공개 콘텐츠는 1:1 분리된 TeacherProfile 로 이전 (public_profile_content_spec)
```

### 9.3 신규 테이블 (SSO 전용)

```python
class AuthIdentity(Base):
    """SSO IdP 연동 정보 — 3-tuple unique (provider, provider_user_id, role)"""
    __tablename__ = "auth_identities"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    provider = Column(String(20), nullable=False)  # "google" | "kakao" | "apple"
    provider_user_id = Column(String(255), nullable=False)  # IdP의 sub/id
    provider_email = Column(String(255), nullable=True)  # IdP 보고 이메일 (변경 가능, 식별자 아님)
    created_at = Column(DateTime, server_default=func.now())
    last_login_at = Column(DateTime, nullable=True)
    __table_args__ = (
        # 3-tuple unique: 같은 IdP + 같은 sub + 같은 역할 중복 가입 차단
        UniqueConstraint("provider", "provider_user_id", "user_id_role_proxy", name="uq_auth_identity_3tuple"),
        # 실제 구현: provider + provider_user_id + (User.role join) 조합. user_id 단독 unique 는 X (한 user가 여러 IdP 연동 가능)
    )

class TermsVersion(Base):
    """동의 증거 보존 — 약관/개인정보 버전 변경 이력"""
    __tablename__ = "terms_versions"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    document_type = Column(String(20))  # "terms" | "privacy" | "marketing"
    version = Column(String(20), nullable=False)
    agreed_at = Column(DateTime, server_default=func.now())
    ip_address = Column(String(45))
    user_agent = Column(String(500))
```

### 9.4 삭제 대상 테이블

- ~~`email_verification_tokens`~~ — IdP가 이메일 검증. M4 마이그레이션에서 생성하지 않음 (v1 초안에서 제안되었으나 SSO-only 전환으로 폐기)

`SlugHistory`, `SlugReservedWord` 는 `slug_lifecycle_spec` 에서 정의.

## 10. 보안

- **비밀번호 처리 없음** (SSO-only) — bcrypt/Argon2 비밀번호 해시 코드 미존재
- IdP `state` 토큰 (32B random) — CSRF 방어
- PKCE (Google): `code_verifier` 32B random + `code_challenge` SHA-256
- 가입 폼 reCAPTCHA v3 (자동 봇 IdP 시도 차단)
- Rate limit:
  - `/auth/oauth/*/authorize`: IP당 시간당 20회
  - `/auth/oauth/*/callback`: state당 1회 (재사용 차단)
  - `/auth/signup/complete`: signup_session_token당 1회
- `signup_session_token`: JWT (1시간 만료, IdP 인증 완료 + 미가입 상태 표시)
- HTTPS 강제 (HSTS)
- AuditLog: oauth_callback, signup_completed, linked_account_added, linked_account_removed

## 11. UX / 텍스트 (한국어)

| 키 | 한국어 |
|---|---|
| `signupTeacherTitle` | "선생님으로 가입하기" |
| `signupStudentTitle` | "학생으로 가입하기" |
| `signupOauthGoogle` | "구글로 계속하기" |
| `signupOauthKakao` | "카카오로 계속하기" |
| `signupOauthApple` | "Apple로 계속하기" *(M5)* |
| `signupKakaoEmailRequired` | "카카오 가입 시 이메일 정보 동의가 필요합니다" |
| `signupSlugHint` | "프로필 주소 (영문/숫자/하이픈)" |
| `signupSlugCheckAvailable` | "사용 가능한 주소입니다" |
| `signupSlugCheckTaken` | "이미 사용 중인 주소입니다" |
| `signupSlugCheckReserved` | "사용할 수 없는 예약어입니다" |
| `signupTermsAgree` | "[이용약관] 동의 (필수)" |
| `signupPrivacyAgree` | "[개인정보처리방침] 동의 (필수)" |
| `signupMarketingAgree` | "마케팅 정보 수신 동의 (선택)" |
| `signupLinkedAccountConflict` | "이 이메일은 이미 {provider}로 가입되어 있습니다. {provider}로 로그인 후 [계정 연동] 메뉴에서 추가해주세요" |
| `signupComplete` | "환영합니다! 프로필을 작성해보세요" |

## 12. 마일스톤

| 단계 | 작업 | 기간 |
|---|---|---|
| M4.0 | DB 마이그레이션 (User/Teacher 확장 + auth_identities + terms_versions) | 1일 |
| M4.1 | OAuth 클라이언트 (Google/Kakao IdP 등록 + 시크릿 관리) | 1일 |
| M4.2 | `/auth/oauth/*/authorize` + `/callback` (Google) | 2일 |
| M4.3 | 카카오 OAuth + 이메일 동의 누락 처리 | 2일 |
| M4.4 | `/auth/signup/complete` + 약관 동의 + terms_versions | 2일 |
| M4.5 | 선생님 가입 폼 (lessonaza.app/signup?role=teacher) + 3 SSO 버튼 | 3일 |
| M4.6 | 학생 가입 폼 + 14세 미만 분기 | 2일 |
| M4.7 | `TeacherProfile` 자동 초기화 (status=draft) — `/auth/signup/complete` 통합 | 1일 |
| M4.8 | `/teachers/me/profile` CRUD + sanitize 파이프라인 + 운영자 검토 큐 | 4일 |
| M4.9 | 인앱 편집 화면 (`features/profile/teacher_profile_edit/`) — 별도 마일스톤 (`teacher_profile_edit_spec`) | — |
| M4.10 | 계정 연동 메뉴 (`/settings/linked-accounts`) | 2일 |
| M4.11 | 운영자 SSO 분리 (admin.lessonaza.app + Google Workspace 도메인 제한) | 2일 |
| M4.12 | reCAPTCHA + Rate limit + AuditLog | 1일 |
| M4.13 | E2E (SSO 가입 → 약관 → slug → 인앱 편집 → 검토 → 게시 → 외부 공유) | 2일 |
| **M4 종료** | **웹 SSO 가입 + TeacherProfile 운영** | **약 4주** |

별도 마일스톤:
- **M5**: Flutter 앱 SSO 전환 + Apple SSO 추가 + dev-login 대체 + `User.password_hash` drop

## 13. 미해결 질문

- [ ] 분야 태그 — 자유 입력 vs 마스터 데이터 (운영자 관리) — Phase 1 결정 필요
- [ ] 학부모 가입 흐름 — `signup_spec` 에 포함 vs `account_lifecycle_spec` 으로 분리
- [ ] Apple SSO 웹 추가 시점 — M5 일괄 vs 별도
- [ ] 카카오 ID 변경 (정책상 거의 없으나) 대응 — provider_user_id 변경 감지 + 재연동 UX

## 14. 변경 이력

- 2026-05-18 v1: 초안 — 이메일+비번 가입 + 이메일 인증 토큰 + 9개 엔드포인트
- 2026-05-18 v2: **SSO-only 전환** — 이메일+비번 폐기, `email_verification_tokens` 폐기, `auth_identities` 신설, OAuth callback 흐름 + 약관 동의 분리 페이지 + 3-tuple unique (provider, provider_user_id, role) + 운영자 SSO 분리 + Apple은 M5 일정으로 분리
- 2026-05-19 v3: **Option D 전환** — Ghost Page 발급 폐기, `TeacherProfile` 1:1 분리 모델로 대체. `ghost_page_id` 컬럼 제거. 인앱 편집 화면으로 편집 채널 이전 (웹 Custom Edit UI 제거). 운영자 첫 게시 검토 큐 추가. 상세는 [public_profile_content_spec.md](../profile/public_profile_content_spec.md), [profile_spec.md](profile_spec.md) v3.
