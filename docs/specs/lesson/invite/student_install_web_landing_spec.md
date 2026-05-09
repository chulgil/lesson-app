# R2 학생 설치 웹 랜딩 및 공유 요약 스펙

> 작성일: 2026-05-10
> 상태: 설계 확정 전 초안
> 관련 이슈: #318 `feat: R2 웹 랜딩 페이지 + 레슨 요약 공유 API`
> 옵시디언 원문: `/Users/cglee/Dev/Personal/MyBrain/10 Projects/레슨앱/10-R2-학생설치-상세스펙.md`

## 1. 결정 사항

`lessonaza.com`의 Ghost 블로그 테마가 학생 설치 전 웹 경험을 담당한다.
FastAPI는 HTML/Jinja2 랜딩을 직접 렌더링하지 않고, Ghost 테마가 소비할 공개 읽기 API와 공유 토큰 API를 제공한다.

| 항목 | 결정 |
|------|------|
| 공개 도메인 | `https://lessonaza.com` |
| 웹 렌더링 | Ghost theme 커스터마이즈 |
| 백엔드 역할 | 초대/요약 데이터 API, 토큰 검증, 감사 로그 |
| 기존 Jinja2 계획 | 폐기. FastAPI 템플릿 디렉토리 추가하지 않음 |
| 민감 정보 | 공개 API에서는 최소 정보만 반환 |
| 앱 진입 | `lessonapp://...` 딥링크 + 앱스토어 fallback |

## 2. 목표

학생이 앱을 설치하지 않아도 초대의 맥락과 레슨 요약 가치를 먼저 확인하게 한다.
선생님은 학생 미설치 상태에서도 단독 모드로 레슨 운영을 계속할 수 있어야 한다.

## 3. URL 설계

### 3.1 Ghost 웹 URL

| 용도 | URL | 설명 |
|------|-----|------|
| 초대 랜딩 | `https://lessonaza.com/invite/{code}` | 카톡/문자 공유용 공개 URL |
| 레슨 요약 | `https://lessonaza.com/student/{token}/summary` | 토큰 기반 읽기 전용 요약 |

Ghost 테마는 위 경로를 라우팅하고, 필요한 데이터는 FastAPI 공개 API에서 가져온다.

### 3.2 앱 딥링크

| 용도 | 딥링크 |
|------|--------|
| 초대 연결 | `lessonapp://invite/{code}` |
| 레슨 요약 앱 열기 | `lessonapp://student/summary/{token}` |

딥링크의 iOS/Android 등록은 frontend/native 작업이다. 백엔드는 URL 계약과 응답 필드만 보장한다.

## 4. 백엔드 공개 API 계약

### 4.1 초대 랜딩 데이터 조회

`GET /api/v1/public/invites/{code}/landing`

인증은 필요 없다. 초대 코드가 유효하고 만료되지 않은 경우에만 최소 랜딩 데이터를 반환한다.

#### Response 200

```json
{
  "code": "PIANO7X",
  "status": "active",
  "teacher": {
    "id": "teacher-id",
    "name": "홍길동",
    "instrument": "피아노",
    "profile_image_url": "https://..."
  },
  "share": {
    "title": "홍길동 선생님의 레슨앱 초대",
    "description": "피아노 레슨 기록과 숙제를 함께 확인해요",
    "url": "https://lessonaza.com/invite/PIANO7X",
    "app_deep_link": "lessonapp://invite/PIANO7X"
  },
  "expires_at": "2026-05-17T09:00:00Z"
}
```

#### Error

| Status | 조건 |
|--------|------|
| 404 | 코드 없음 |
| 410 | 만료, 사용 완료, 폐기 |

### 4.2 레슨 요약 공유 토큰 생성

`POST /api/v1/lesson-summaries/{lesson_id}/share`

선생님 JWT가 필요하다. 선생님이 소유한 레슨에 대해서만 토큰을 발급한다.

#### Request

```json
{
  "expires_in_hours": 24
}
```

#### Response 201

```json
{
  "token": "opaque-token",
  "url": "https://lessonaza.com/student/opaque-token/summary",
  "app_deep_link": "lessonapp://student/summary/opaque-token",
  "expires_at": "2026-05-11T09:00:00Z",
  "share_text": "🎵 오늘 피아노 레슨 정리가 도착했어요\n\n📅 2026년 5월 10일 · 홍길동 선생님\n바이엘 30번 - 오른손 박자 연습\n\n👉 https://lessonaza.com/student/opaque-token/summary"
}
```

### 4.3 레슨 요약 공개 조회

`GET /api/v1/public/student-summaries/{token}`

토큰 자체가 접근 권한이다. 학생 계정이 없어도 읽을 수 있지만, 토큰 만료와 레슨 소유권은 서버에서 검증한다.

#### Response 200

```json
{
  "lesson": {
    "id": "lesson-id",
    "date": "2026-05-10",
    "start_time": "15:00",
    "duration_minutes": 60,
    "session_number": 3,
    "status": "completed"
  },
  "teacher": {
    "name": "홍길동",
    "instrument": "피아노",
    "profile_image_url": "https://..."
  },
  "student": {
    "name": "김학생"
  },
  "summary": {
    "title": "바이엘 30번 - 오른손 박자 연습",
    "lesson_note": "오늘은 오른손 박자 안정화에 집중했습니다.",
    "homework": "메트로놈 70으로 10분씩 연습",
    "next_lesson_at": "2026-05-17T15:00:00+09:00"
  },
  "share": {
    "title": "오늘 피아노 레슨 정리",
    "description": "홍길동 선생님이 보낸 레슨 요약",
    "url": "https://lessonaza.com/student/opaque-token/summary",
    "app_deep_link": "lessonapp://student/summary/opaque-token"
  }
}
```

#### Error

| Status | 조건 |
|--------|------|
| 404 | 토큰 없음 |
| 410 | 토큰 만료 또는 폐기 |

## 5. DB 설계

레슨 요약 공유는 별도 토큰 테이블로 정규화한다. URL 문자열이나 JWT 원문을 레슨 테이블에 직접 저장하지 않는다.

### `lesson_summary_share_tokens`

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | String(36) PK | UUID |
| `lesson_id` | String(36), FK `lessons.id` | 공유 대상 레슨 |
| `teacher_id` | String(36), FK `users.id` | 발급 선생님 |
| `student_id` | String(36), nullable | 공유 대상 학생 |
| `token_hash` | String(128), unique | 원문 토큰 해시 |
| `expires_at` | timestamptz | 만료 시각 |
| `revoked_at` | timestamptz nullable | 수동 폐기 |
| `last_accessed_at` | timestamptz nullable | 마지막 조회 |
| `access_count` | integer | 조회 횟수 |
| `created_at` | timestamptz | 생성 시각 |
| `updated_at` | timestamptz | 수정 시각 |

### 제약

- `expires_at > created_at`
- `access_count >= 0`
- `token_hash`는 원문 토큰 저장 금지
- 선생님은 자신이 소유한 레슨에 대해서만 토큰 생성 가능

## 6. Ghost 테마 책임

Ghost는 페이지 렌더링과 SEO/공유 미리보기를 담당한다.

| 책임 | 내용 |
|------|------|
| 라우팅 | `/invite/{code}`, `/student/{token}/summary` |
| 데이터 로딩 | FastAPI 공개 API 호출 |
| OG 메타 | 선생님 이름, 악기, 초대/요약 제목 반영 |
| CTA | 앱 열기, 앱스토어 이동, 나중에 보기 |
| 오류 화면 | 만료/폐기/없는 초대 또는 토큰 안내 |

Ghost Admin API 키는 브라우저에 노출하지 않는다. Ghost Content API는 공개 콘텐츠 조회에만 사용한다.

## 7. 카톡 공유 텍스트

### 초대

```text
🎵 홍길동 선생님의 레슨앱에 초대받았어요

피아노 레슨 기록, 숙제, 연습 일정을
선생님과 함께 확인할 수 있어요

👉 https://lessonaza.com/invite/PIANO7X
```

### 레슨 요약

```text
🎵 오늘 피아노 레슨 정리가 도착했어요

📅 2026년 5월 10일 · 홍길동 선생님
바이엘 30번 - 오른손 박자 연습

👉 https://lessonaza.com/student/{token}/summary
```

## 8. 보안 및 개인정보

- 공개 초대 API는 선생님 이름, 악기, 프로필 이미지 정도만 노출한다.
- 학생 이름은 레슨 요약 토큰이 유효할 때만 노출한다.
- 레슨 요약에는 결제, 연락처, 내부 메모, 다른 학생 정보가 포함되면 안 된다.
- 공유 토큰은 원문 저장 금지, 해시 저장만 허용한다.
- 토큰 조회는 rate limit 후보로 분류한다. Redis 도입 시 IP/token 기반 제한을 붙인다.
- 모든 공개 조회는 감사 로그 또는 최소 `last_accessed_at`, `access_count`로 추적한다.

## 9. 구현 순서

1. 백엔드 공개 초대 랜딩 API 추가
2. 공유 토큰 모델/마이그레이션 추가
3. 레슨 요약 공유 토큰 생성 API 추가
4. 레슨 요약 공개 조회 API 추가
5. 공유 텍스트 생성 유틸을 초대/요약에서 재사용
6. Ghost 테마에서 두 URL을 렌더링
7. iOS/Android 딥링크 등록
8. 20개 도메인 선생님 단독 모드 감사 문서 갱신

## 10. 테스트 기준

| 테스트 | 검증 |
|--------|------|
| 초대 랜딩 공개 조회 | 인증 없이 유효 초대만 200 |
| 만료 초대 | 410 |
| 없는 초대 | 404 |
| 레슨 요약 토큰 생성 | 소유 선생님만 생성 가능 |
| 타 선생님 레슨 | 403 |
| 공개 요약 조회 | 유효 토큰만 200 |
| 만료/폐기 토큰 | 410 |
| 개인정보 필터 | 연락처/결제/내부 메모 미포함 |
| 아키텍처 | router 직접 DB 접근 금지 |

## 11. 참조

- Ghost Custom Integrations: https://ghost.org/integrations/custom-integrations/
- Ghost Content API: https://docs.ghost.org/content-api
- Ghost Admin API: https://docs.ghost.org/admin-api
