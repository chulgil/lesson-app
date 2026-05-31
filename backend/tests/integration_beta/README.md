# Beta API 통합 테스트

GitHub issue #418의 원격 beta API 종단 시나리오 스캐폴드입니다.

## 실행

```bash
cd backend
INTERNAL_API_KEY=... uv run pytest tests/integration_beta -q
```

기본 대상은 `https://api-beta.lessonaza.app`입니다. 다른 환경을 확인하려면 `BETA_BASE_URL`을 지정합니다.

```bash
BETA_BASE_URL=https://api-beta.lessonaza.app INTERNAL_API_KEY=... uv run pytest tests/integration_beta -q
```

`INTERNAL_API_KEY`가 없으면 테스트는 skip됩니다. 시크릿을 커밋하지 않습니다.

## 현재 범위

- `GET /health`로 beta 서버 가용성을 확인합니다.
- `POST /api/v1/auth/dev-login`에 `X-Internal-API-Key`를 붙여 시드 선생님 로그인을 검증합니다.
- 발급된 access token으로 `GET /api/v1/auth/me`를 호출해 인증 왕복을 검증합니다.
- 신규 선생님 로그인 → `POST /api/v1/students` 학생 등록 → `GET /api/v1/students` 목록 반영을 검증합니다.
- 선생님 초대코드 생성 → 학생 초대코드 연결 요청 → 학생 sent 목록 → 선생님 pending 목록 → 선생님 수락 → 양쪽 connections 목록 반영을 검증합니다.

이후 #418의 Phase 2에 따라 레슨 신청, 일정 변경, 레슨 종료, 권한/토큰/KST 경계 시나리오를 같은 디렉터리에 추가합니다.
