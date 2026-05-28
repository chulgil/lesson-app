# Web Auth API Contract — SSO / Slug / Profile (M4)

> 기준일: 2026-05-19
> 도메인: 웹 가입·로그인·프로필·슬러그 관리의 백엔드 API 계약
> 선행: [signup_spec.md](signup_spec.md), [../teacher/profile_spec.md](../teacher/profile_spec.md), [../teacher/profile_renderer_spec.md](../teacher/profile_renderer_spec.md), [../../user/slug_lifecycle_spec.md](../../user/slug_lifecycle_spec.md)
> 백엔드 본 문서: [backend_architecture.md](../../backend/backend_architecture.md)

## 1. 범위

M4 (SSO 전용) 의 가입·로그인·프로필 편집·슬러그 관리 API 표면. 본 문서는 **계약(스펙)** 이며, 구현은 backend FastAPI 코드에 있다. DB 모델 정의는 [backend_architecture.md](../../backend/backend_architecture.md) §3 참조.

**핵심 원칙** (M4):
- SSO 전용 — Google + Kakao. 이메일+비밀번호 가입 없음
- Apple SSO 는 M5 (iOS 앱 출시 시점)
- 운영자 SSO 는 별도 IdP 키 + `admin.lessonaza.app` + Workspace 도메인 제한 + 2FA — 일반 사용자 SSO 풀과 분리

## 2. 인증 / 가입 (SSO)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/auth/oauth/google/authorize?role=...` | 구글 OAuth URL 생성 + state 발급 (PKCE) |
| GET | `/api/v1/auth/oauth/kakao/authorize?role=...` | 카카오 OAuth URL 생성 + state 발급 |
| POST | `/api/v1/auth/oauth/google/callback` | 구글 콜백 (code+state) → 기존 User 로그인 또는 `signup_session_token` 발급 |
| POST | `/api/v1/auth/oauth/kakao/callback` | 카카오 콜백 + 이메일 동의 누락 시 가입 거부 |
| POST | `/api/v1/auth/signup/complete` | 약관 동의 + 역할별 추가 정보 → User/Teacher 생성 (Option D: Ghost Page 발급 없음) |
| POST | `/api/v1/auth/logout` | 세션 종료 |
| GET | `/api/v1/users/me/linked-accounts` | 본인 연동 IdP 목록 |
| POST | `/api/v1/users/me/linked-accounts/{provider}` | 추가 IdP 연동 (본 계정 로그인 상태) |
| DELETE | `/api/v1/users/me/linked-accounts/{provider}` | 연동 해제 (최소 1개 IdP 유지 강제) |

## 3. 선생님 본인 프로필 (Option D — Custom Edit UI + TeacherProfile SSOT)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/teachers/me/profile` | 본인 `TeacherProfile` 조회 (draft 포함) |
| PUT | `/api/v1/teachers/me/profile` | 본인 `TeacherProfile` 부분 수정 (검증 화이트리스트) |
| POST | `/api/v1/teachers/me/profile/publish` | `draft → review` (첫 게시 시 운영자 검토 큐) 또는 `draft → public` (재게시) |
| POST | `/api/v1/teachers/me/profile/unpublish` | `public → draft` (본인 비공개) |
| POST | `/api/v1/teachers/me/profile/images` | 이미지 업로드 (Vultr Object Storage, S3 호환) |
| DELETE | `/api/v1/teachers/me/profile/images/{image_id}` | 갤러리 이미지 삭제 |
| POST | `/api/v1/teachers/me/profile/preview` | 게시 전 미리보기 토큰 (profile-renderer 가 검증) |
| GET | `/api/v1/teachers/me/profile/slug/check?slug=...` | slug 가용성 확인 (형식/예약어/cooldown) |
| PUT | `/api/v1/teachers/me/profile/slug` | slug 변경 (Year 1: 가입 후 60일 내 1회만) |

## 4. 운영자 프로필 검토 큐

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/admin/profile-reviews?state=pending` | 검토 대기 목록 |
| POST | `/api/v1/admin/profile-reviews/{teacher_id}/approve` | `status=public` 전환 + AuditLog |
| POST | `/api/v1/admin/profile-reviews/{teacher_id}/reject` | `status=draft` 복귀 + `review_notes` + 이메일 |

## 5. 내부 (profile-renderer 전용)

| Method | Path | 책임 |
|---|---|---|
| GET | `/api/v1/internal/teachers/by-slug/{slug}` | profile-renderer SSR 용 (X-Internal-API-Token + IP 화이트리스트 이중 보호) |

상세 렌더러 호출 패턴: [../teacher/profile_renderer_spec.md](../teacher/profile_renderer_spec.md), [../../profile/public_profile_content_spec.md](../../profile/public_profile_content_spec.md).

## 6. 운영자 slug 관리

| Method | Path | 책임 |
|---|---|---|
| POST | `/api/v1/admin/teachers/{id}/revoke-slug` | 운영자 즉시 회수 + cooldown 설정 + AuditLog |
| GET | `/api/v1/admin/slug-reserved-words` | 예약어 목록 조회 |
| POST | `/api/v1/admin/slug-reserved-words` | 예약어 추가 |

## 7. 권한 격리 원칙 (Option D)

- 모든 `/teachers/me/profile/*` 는 `Depends(require_teacher)` + `teacher_id = current_user.teacher_id` 강제
- 다른 선생님 `teacher_id` 조작 시도 → 403 + AuditLog
- 내부 API (`/internal/teachers/by-slug/{slug}`) 는 X-Internal-API-Token + IP 화이트리스트 이중 보호 — profile-renderer 만 호출 가능
- 운영자 검토 큐 (`/admin/profile-reviews`) 는 운영자 IdP 분리 + 2FA 필수

## 8. 관련 DB 모델

본 API 가 사용하는 DB 모델 정의는 백엔드 측에 있다. 컬럼 변경 시 본 문서와 backend 양쪽 동기화 필수.

- `User` 확장 필드 (M4): role, signup_source, email_verified_at, terms/privacy_version_agreed, marketing_consent, last_activity_at, last_app_login_at
- `Teacher` 확장 필드 (M4): profile_slug, profile_url, profile_visibility, dormant_notice_*_at, dormant_entered_at, slug_released_at
- 신규 테이블: `auth_identities`, `terms_versions`, `slug_history`, `slug_reserved_words`, `teacher_profiles`

상세 컬럼 정의: [backend_architecture.md §웹 가입 / 프로필 / Slug 계약](../../backend/backend_architecture.md).

## 변경 이력

- 2026-05-19: backend_architecture.md §3 에서 분리. 웹 도메인 API 계약을 web/auth/ 로 이관.
