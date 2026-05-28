# teacher/ — 선생님 프로필 사이트

> 도메인: `profile.lessonaza.app/{slug}`
> 컨테이너: `profile-renderer` (FastAPI + Jinja2 SSR, Option D)

## 스펙

| 파일 | 범위 |
|---|---|
| [profile_spec.md](profile_spec.md) | 콘텐츠/UI/SEO 정책, 슬러그·휴면 정책 적용 |
| [profile_renderer_spec.md](profile_renderer_spec.md) | 렌더링 서버 운영 스펙 (캐시, 보안, 배포) |

## 관련

- 콘텐츠 모델: [../../profile/public_profile_content_spec.md](../../profile/public_profile_content_spec.md)
- 슬러그 생명주기: [../../user/slug_lifecycle_spec.md](../../user/slug_lifecycle_spec.md)
- 가입 흐름: [../auth/signup_spec.md](../auth/signup_spec.md)
- API 계약: [../auth/api_contract.md](../auth/api_contract.md)
