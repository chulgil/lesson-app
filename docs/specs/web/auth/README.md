# auth/ — 공통 인증 (SSO / Slug)

> 도메인: SSO 로그인·가입·슬러그 발급 — 모든 역할(선생님/학생/학부모/학원장) 공통
> 시점: M4 (SSO-only, Google + Kakao). Apple SSO 는 M5.

## 스펙

| 파일 | 범위 |
|---|---|
| [signup_spec.md](signup_spec.md) | 가입 흐름 (역할 선택 → SSO → 약관 → 슬러그 발급) |
| [api_contract.md](api_contract.md) | 백엔드 API 계약 (SSO, 프로필, 슬러그, 운영자 검토 큐) |

## 관련

- 슬러그 생명주기: [../../user/slug_lifecycle_spec.md](../../user/slug_lifecycle_spec.md)
- 계정 생명주기: [../../user/account_lifecycle_spec.md](../../user/account_lifecycle_spec.md)
- DB 모델: [../../backend/backend_architecture.md](../../backend/backend_architecture.md) §웹 가입 / 프로필 / Slug — DB 모델
