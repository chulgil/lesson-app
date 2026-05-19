# profile_spec — 선생님 프로필 사이트

> 기준일: 2026-05-18
> 도메인: `profile.lessonaza.app/{teacher_slug}`
> 컨테이너: `ghost-profile` (Ghost 5.x + MySQL 8) — `ghost-www` 와 별도 인스턴스
> 선행: [README.md](README.md), [www_spec.md](www_spec.md), `mybrain/10 Projects/레슨앱/17-www-profile-시장조사.md`, `18-www-profile-요구사항.md`

## 1. 개요

선생님 개인의 **공개 명함/포트폴리오** 페이지. 학생/학부모가 검색·SNS·카카오톡에서 접근 가능한 단일 URL 을 제공.

**책임**:
- 선생님 1명당 1 페이지 (`/{slug}`) — 소개·이력·분야·가격·CTA
- 선생님이 자기 페이지를 Ghost 어드민에서 직접 편집
- 페이지 → lesson-app 다운로드 + 해당 선생님 자동 매칭

**비책임**:
- 선생님 인증/세션 (lesson-app 백엔드)
- 학생 후기 양식 입력 (lesson-app 내 후기와 분리)
- 결제 / 예약 (lesson-app 본 앱)

## 2. 성공 기준

- [SC-1] 선생님이 Ghost 어드민에서 자기 페이지를 5분 안에 편집·게시
- [SC-2] `profile.lessonaza.app/{slug}` 가 OG 카드로 카카오톡/페이스북 미리보기 정상 표시
- [SC-3] 페이지 LCP < 2.5s (3G), 모바일 우선
- [SC-4] 페이지 내 앱 다운로드 CTA → 설치 후 선생님 코드 자동 입력 → 매칭 (Deep Link)
- [SC-5] 선생님이 다른 선생님 페이지 편집 시도 시 즉시 알람 (운영 정책)
- [SC-6] Phase 2 전환 시 콘텐츠를 백엔드 모델로 무손실 마이그레이션

## 3. URL 구조 / 멀티테넌트 전략

### 3.1 URL

- 페이지: `profile.lessonaza.app/{teacher_slug}`
- 어드민: `profile.lessonaza.app/ghost`
- 인덱스: `profile.lessonaza.app/` → 운영자가 작성한 환영 페이지 또는 선생님 목록 (선택)

### 3.2 slug 규칙

상세 정책은 [slug_lifecycle_spec.md](../user/slug_lifecycle_spec.md) 참조.

- 영문 소문자 + 숫자 + 하이픈, 3~30자
- 선생님이 **가입 시 본인 선점** (실시간 중복 체크, 운영자 승인 불필요)
- Year 1: 가입 후 **60일 내 1회 변경 허용**
- 12개월 미활동 시 휴면 진입 → 13개월 회수 + 3개월 cooldown (LOL 방식)
- 운영자 즉시 회수 가능 (저작권/욕설/사기 신고)
- 예약어 (`SlugReservedWord` 테이블): `ghost`, `admin`, `api`, `www`, `terms`, `privacy`, `signup`, `login`, `verify-email`, `edit`, `static`, `well-known` 등

### 3.3 멀티테넌트 — Option B (Custom Edit UI + Ghost Admin API)

**선택지 비교**:

| 옵션 | 격리 수준 | 비용 | 채택 |
|---|---|---|---|
| Ghost Author 역할 (네이티브) | 약함 — 다른 페이지 목록 노출 | 낮음 | ❌ |
| Custom Edit UI + Ghost Admin API 백엔드 프록시 | 강함 — 다른 페이지 비노출 | 중간 | ✅ |
| 헤드리스 (Ghost 폐기, Astro) | 강함 | 높음 (Phase 2 백로그) | 보류 |

**채택**: Option B. lesson-app 백엔드가 Ghost Admin API 키를 단독 보관하고 모든 요청을 프록시.

```
선생님 (브라우저)
  ↓ HTTPS + JWT
lessonaza.app/edit (Custom Edit UI, Phase 1)
  ↓
POST /api/v1/teachers/me/profile (lesson-app 백엔드)
  ↓ 권한 체크: current_teacher.ghost_page_id 강제
Ghost Admin API (서버 간 통신, Admin Token)
  ↓
ghost-profile 컨테이너 (MySQL)
```

**격리 보증**:
- 선생님은 `/ghost` 어드민 URL 직접 접근 불가 (테마 또는 Traefik path-prefix middleware 차단)
- Ghost Admin API Key 는 백엔드 환경변수만 보관
- 백엔드는 `current_user` JWT 에서 `teacher_id` 추출 → 본인 `ghost_page_id` 만 조작
- 다른 페이지 ID 조작 시도 → 403 + AuditLog 기록

**Ghost 사용 범위 (Phase 1)**:
- 콘텐츠 SSOT (이중 동기화 회피)
- 공개 페이지 렌더링 (`profile.lessonaza.app/{slug}` → ghost-profile 컨테이너)
- 어드민은 **운영자만** 사용 (운영자가 수동 관리 작업 시)

### 3.4 Phase 2 트리거 (헤드리스 전환)

다음 중 하나 발생 시 Phase 2 검토:
- 선생님 ≥ 50명 도달 (Option B 로 Phase 1 한계 상향)
- Ghost 의존성 제거 결정 (라이선스/운영 비용 변경)
- Custom Edit UI 가 Astro 렌더링과 통합되는 시점

Phase 2 = lesson-app 백엔드 + Astro 정적 사이트. 본 스펙에서는 데이터 모델 초안만 제시 (§10).

## 4. 데이터 모델 (Phase 1: Ghost Page)

각 선생님 페이지의 콘텐츠는 Ghost Page 의 표준 필드로 관리.

| Ghost 필드 | 매핑 | 비고 |
|---|---|---|
| `title` | 선생님 표시 이름 | "이지원 바이올린 선생님" |
| `slug` | URL slug | `jiwon-lee` |
| `featured_image` | 메인 사진 | 1200×630 권장 |
| `excerpt` | 한 줄 소개 | OG description |
| `html` (본문) | 마크다운 → HTML | 자기소개, 이력, 분야 |
| `meta_title` | SEO 제목 | < 60자 |
| `meta_description` | SEO 설명 | < 155자 |
| `og_image`, `twitter_image` | 공유 이미지 | 자동 = featured_image |
| `visibility` | 공개/비공개 | `public` / `members` (비공개) |
| `tags` | 분야 태그 | `violin`, `piano`, `seoul-gangnam` |
| `authors` | Ghost 작성자 = 선생님 본인 | 권한 격리 정책 |
| `published_at` | 게시일 | - |

**커스텀 필드** (Ghost custom integration via code injection):
- `teacher_code` — lesson-app 의 선생님 코드 (예: `T-A8K2`)
- `app_deeplink` — `lessonaza://teacher/{teacher_code}` (Universal Link)
- `lesson_areas` — JSON ("강남", "온라인", "출장")
- `lesson_genres` — JSON ("클래식", "재즈")
- `price_range` — "5만원~ / 30분" 같은 자유 텍스트

커스텀 필드는 Ghost 테마의 `{{#get "pages"}}` 헬퍼 + handlebars `{{post.codeinjection_head}}` 또는 별도 `metadata` JSON 으로 관리.

## 5. 권한 모델 — Option B

### 5.1 Ghost 역할 (운영자 전용)

| 역할 | 부여 대상 | 권한 |
|---|---|---|
| Owner | 운영자 (1명) | 전체 (사이트 설정, 테마, 모든 페이지) |
| Administrator | 백업 운영자 (1명) | Owner 제외 전체 |
| **선생님** | **Ghost 계정 없음** | **lesson-app JWT 로 Custom Edit UI 사용** |

선생님은 Ghost 어드민 자체를 사용하지 않는다. 모든 편집은 `lessonaza.app/edit` Custom Edit UI 를 거쳐 lesson-app 백엔드를 통해 Ghost Admin API 로 전달된다.

### 5.2 백엔드 권한 격리

```python
@router.put("/teachers/me/profile")
async def update_my_profile(
    payload: ProfileUpdate,
    current_user: User = Depends(require_teacher),
):
    teacher = await teacher_service.get_by_user_id(current_user.id)
    if teacher is None or teacher.ghost_page_id is None:
        raise HTTPException(404, "프로필이 발급되지 않았습니다")
    # 핵심: 클라이언트가 보낸 ghost_page_id 무시, 백엔드에서 강제
    page_id = teacher.ghost_page_id
    await ghost_admin_client.update_page(page_id, payload.dict())
    await audit_log.write("profile_updated", user_id=current_user.id)
```

### 5.3 운영 정책

| 위반 | 처리 |
|---|---|
| 다른 선생님 프로필 ID 조작 시도 (백엔드 차단) | 즉시 403 + AuditLog + Slack 경고 |
| 부적절 콘텐츠 (욕설, 광고, 저작권) | 즉시 비공개 + 운영자 검토 → 필요 시 slug 회수 |
| 휴면 진입 (12개월 미접속) | [slug_lifecycle_spec](../user/slug_lifecycle_spec.md) §6 자동 흐름 |

## 6. 페이지 템플릿 — Notebook × Score

### 6.1 레이아웃 (모바일 우선)

```
┌──────────────────────────────────────────┐
│  [Notebook 종이 배경, 옅은 가로선]            │
│                                          │
│  ♩ Lessonaza                  [앱 받기]    │  ← sticky 헤더
│                                          │
│  [선생님 사진 — 원형 보더]                    │
│                                          │
│  ★ 이지원 바이올린 선생님                     │
│  서울 강남 · 클래식 · 5년 경력                │
│                                          │
│  ─── 5선 구분선 (악보 모티프) ───              │
│                                          │
│  [자기소개 본문 — Pretendard]                │
│                                          │
│  📍 레슨 위치 — 강남, 온라인                  │
│  💰 가격대 — 5만원~ / 30분                   │
│  🎼 분야 — 클래식, 재즈                       │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  [이력 — 마크다운 리스트]                     │
│  • 한예종 기악과 졸업                          │
│  • 서울시향 객원                              │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ ♥ 이 선생님과 레슨하고 싶다면?         │  │
│  │ ① 앱 다운로드  ② 선생님 코드 입력      │  │
│  │ [QR 코드]   T-A8K2  [복사]            │  │
│  │ [App Store] [Google Play]              │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ─── 5선 구분선 ───                          │
│                                          │
│  [후기 — 정적 표시, 선생님이 직접 입력]         │
│                                          │
│  ⓒ Lessonaza · 약관 · 개인정보             │  ← 푸터
└──────────────────────────────────────────┘
```

### 6.2 NotebookGlyph 사용 (시그니처 영역)

- 헤더 로고: ♩
- 이름 앞: ★
- 후기 섹션: ♥
- 5선 구분선: 악보 5선 5px 간격 (SVG, `core/widgets/notebook` 시그니처 참조)
- 위치/가격/분야 아이콘: NotebookGlyph 또는 단순 그래픽 (📍 💰 🎼 은 유니코드 — 시그니처 영역 정책상 NotebookGlyph 권장하나 작은 인디케이터는 일반 영역으로 분류 허용)

### 6.3 색상

- 배경: `#FBF7F0` (notebook paper)
- 5선: `#D4D0C8` (옅은 회색)
- 텍스트 본문: `#1A1A1A`
- 강조(이름, CTA): `#D97757` (스코어 액센트)
- 사진 보더: `#1A1A1A` 2px

### 6.4 폰트

- 시그니처 (선생님 이름, 섹션 헤더, CTA): Gaegu
- 본문: Pretendard

## 7. lesson-app 연계

### 7.1 백엔드 변경

| 변경 | 위치 | 마일스톤 |
|---|---|---|
| `Teacher.profile_url` 컬럼 (nullable, VARCHAR(255), 절대 URL) | `backend/app/models/teacher.py` + Alembic 마이그레이션 | M4 |
| `GET /api/v1/teachers/{id}` 응답에 `profile_url` 포함 | `backend/app/schemas/teacher.py` | M4 |
| `Teacher.teacher_code` 가 페이지 커스텀 필드 `teacher_code` 와 일치 보증 | 데이터 정합성 — 운영자 수동 확인 또는 자동 검증 스크립트 | M4 |

### 7.2 앱 내 통합

| 변경 | 위치 |
|---|---|
| 선생님 상세 화면에 "공식 프로필 보기" 버튼 (profile_url 있을 때만) | `frontend/lib/features/student/presentation/screens/teacher_detail_page.dart` 등 |
| 버튼 탭 → 외부 브라우저 또는 인앱 WebView | `url_launcher` |
| Deep Link 처리: `profile.lessonaza.app/{slug}` → 앱 설치 시 자동 매칭 | `frontend/lib/core/deep_link/` |

### 7.3 Deep Link (Universal Link / App Link)

- iOS: `apple-app-site-association` 파일을 `profile.lessonaza.app/.well-known/apple-app-site-association` 에 호스팅
- Android: `assetlinks.json` 을 `profile.lessonaza.app/.well-known/assetlinks.json` 에 호스팅
- Traefik 라우팅: `PathPrefix:/.well-known` 매처를 정적 파일 컨테이너 (예: `nginx:alpine` with `/.well-known` mount) 로 보내 Ghost 라우팅 우회. priority 를 높여 ghost 라우터보다 먼저 매치되도록 한다.
- 앱 미설치 시: Ghost 페이지 노출 + 스토어 CTA
- 앱 설치 시: 앱 열기 + slug 또는 teacher_code 로 자동 검색

### 7.4 선생님 코드 자동 입력

- 페이지 내 QR 코드: `lessonaza://signup?teacher_code=T-A8K2`
- "코드 복사" 버튼: 클립보드 복사 + 토스트 "앱 설치 후 가입 화면에서 붙여넣기"
- 앱 가입 화면: 클립보드에 `T-XXXX` 형식 감지 시 자동 입력 제안 (`frontend/lib/features/auth/onboarding/`)

## 8. SEO / Open Graph

| 항목 | 값 |
|---|---|
| `<title>` | "{선생님 이름} {분야} 선생님 — Lessonaza" |
| `<meta description>` | excerpt (한 줄 소개) |
| `og:title` | title |
| `og:description` | excerpt |
| `og:image` | featured_image (1200×630) |
| `og:url` | canonical |
| `og:type` | `profile` |
| `twitter:card` | `summary_large_image` |
| `schema.org` | `Person` (선생님), `Service` (레슨) |

선생님이 이미지·excerpt 미입력 시 운영자가 기본값 강제 (Ghost 어드민 체크리스트).

## 9. 운영 정책

| 항목 | 정책 |
|---|---|
| 신규 선생님 페이지 발급 | 1) `lessonaza.app/signup?role=teacher` 진입 → SSO (구글/카카오) 인증 → 2) `/signup/complete` 에서 slug 본인 선점 + 약관 동의 → 3) 백엔드가 User + Teacher + Ghost Page 생성 (status="published" — IdP가 이메일 검증 완료) → 4) Custom Edit UI 진입 → 5) `Teacher.profile_url` 백엔드 저장 (신호: signup_spec §5.1) |
| slug 변경 | Year 1: 가입 후 60일 내 1회 허용. 60일 이후 운영자 수동 (slug_lifecycle_spec §4) |
| 콘텐츠 가이드라인 | 욕설/광고/저작권 침해 금지. 1차 경고 → 2차 비공개 → 3차 권한 회수 |
| 비공개 모드 | 선생님 휴직/일시 중단 시 `visibility: members` 로 변경 → 외부 접근 차단. 페이지 자체는 보존 |
| 페이지 삭제 | 선생님 탈퇴 시 운영자가 백업 후 페이지 삭제 + `Teacher.profile_url` NULL |
| 후기 모더레이션 | 선생님이 직접 입력 — 운영자 사후 검수 (월 1회) |

## 10. Phase 2 전환 계획 (헤드리스)

### 10.1 트리거

- 선생님 ≥ 10명 도달
- 권한 위반 incident 1건
- lesson-app 내 직접 편집 요구

### 10.2 목표 아키텍처

```
선생님 → lesson-app 앱 (마크다운 에디터) → POST /api/v1/teachers/{id}/profile-content
                                                   ↓
                                          backend (PostgreSQL)
                                                   ↓
                                          Astro 정적 사이트 (rebuild on update)
                                                   ↓
                                          profile.lessonaza.app/{slug}
```

### 10.3 백엔드 모델 초안 (현재 비활성, Phase 2 도입)

```python
class TeacherProfileContent(Base):
    __tablename__ = "teacher_profile_contents"
    id = Column(Integer, primary_key=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id"), unique=True)
    slug = Column(String(30), unique=True, nullable=False)
    display_name = Column(String(100), nullable=False)
    excerpt = Column(String(155))
    body_markdown = Column(Text)
    featured_image_url = Column(String(500))
    lesson_areas = Column(JSON)         # ["강남", "온라인"]
    lesson_genres = Column(JSON)        # ["클래식", "재즈"]
    price_range = Column(String(50))
    visibility = Column(String(20), default="public")  # public / private
    meta_title = Column(String(60))
    meta_description = Column(String(155))
    published_at = Column(DateTime)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
```

### 10.4 마이그레이션 절차

1. Ghost Content API 로 모든 페이지 export → JSON
2. 백엔드 `TeacherProfileContent` 로 매핑 import
3. Astro 정적 사이트 빌드 + 배포
4. 트래픽 전환 (Traefik 라벨 교체 → 새 호스트 또는 동일 호스트 Astro 컨테이너)
5. ghost-profile 컨테이너 30일 보관 (롤백 대비) 후 폐기

## 11. 마일스톤 (M3 + M4 일부)

| 단계 | 작업 | 기간 |
|---|---|---|
| M3.1 | ghost-profile 컨테이너 + MySQL + TLS (www 와 동일 VPS, 별도 컨테이너) | 1일 |
| M3.2 | Lessonaza-notebook-profile 테마 (페이지 템플릿) | 4일 |
| M3.3 | 선생님 페이지 1번 시범 (운영자가 더미 슬러그 1개 생성, 디자인 검증) | 2일 |
| M3.4 | 선생님 1명 시범 운영 (Author 권한 부여 + 가이드 문서) | 3일 |
| M3.5 | 선생님 3명 확대 + 운영 정책 체크리스트 검증 | 4일 |
| **M3 종료** | **3명 선생님 페이지 운영** | **2주** |
| M4.1 | 백엔드 `Teacher.profile_url` 컬럼 + Alembic 마이그레이션 | 1일 |
| M4.2 | 앱 내 "공식 프로필" 버튼 + WebView | 2일 |
| M4.3 | Deep Link (Universal Link / App Link) + `.well-known` Traefik path-prefix 라우팅 | 3일 |
| M4.4 | 선생님 코드 클립보드 자동 입력 (앱 가입 화면) | 2일 |
| M4.5 | E2E 검증 (외부 링크 클릭 → 앱 설치 → 매칭) | 2일 |
| **M4 종료** | **lesson-app 통합 완료** | **+2주 = 누적 4주** |

## 12. 보안

- TLS 1.3, HSTS, CSP (Traefik 글로벌 headers middleware, Let's Encrypt 자동 갱신)
- 어드민 2FA 필수
- 어드민 경로 (`/ghost`) → 본문 페이지에서 노출 안 함 (테마에서 nav 제외)
- 가입은 SSO 전용 (구글/카카오, M4) — 이메일 인증 토큰 미발급 (IdP가 검증). 상세: [signup_spec.md](signup_spec.md)
- 페이지 폼 (연락 폼 추가 시) → reCAPTCHA 또는 동등 봇 방지
- 백업 매일 → Vultr Object Storage, 30일 보관

## 13. 미해결 질문

- [ ] 첫 시범 선생님 — 누구? (M3.4)
- [ ] 후기 입력 방식 — 선생님 직접 입력 vs 학생 입력 폼 (Phase 1 결정)
- [ ] 인덱스 페이지 (`profile.lessonaza.app/`) — 환영 페이지 vs 선생님 디렉토리 vs 404
- [ ] 선생님 페이지 통계 (조회수, 외부 유입) — 선생님 본인이 볼 수 있게? Phase 1 은 운영자만?
- [ ] Custom Edit UI 위치 — `lessonaza.app/edit` vs `profile.lessonaza.app/edit` (서브도메인 분리 시 CORS/JWT 흐름 고려)

## 14. 변경 이력

- 2026-05-18: 초안 (Ghost 별도 인스턴스 + Author 권한 + Phase 2 헤드리스 전환 계획)
- 2026-05-18 (v2): Option B 채택 — Custom Edit UI + Ghost Admin API 백엔드 프록시. Author 권한 모델 폐기. slug 자동 발급 + 휴면 정책 분리 ([slug_lifecycle_spec](../user/slug_lifecycle_spec.md)).
