# academy/public_page_spec — 학원 공개 페이지

> 기준일: 2026-05-19
> 경로: `academy.lessonaza.app/{academy_slug}` (공개), `/page` (학원장 편집)
> 마일스톤: AC-M2 (공개 페이지 MVP), AC-M5 (후기·영상 노출)
> 선행: [console_overview_spec.md](console_overview_spec.md), [teacher_management_spec.md](teacher_management_spec.md), [../teacher/profile_spec.md](../teacher/profile_spec.md), [../../user/slug_lifecycle_spec.md](../../user/slug_lifecycle_spec.md), 옵시디언 `21-academy-요구사항.md` §3.1, §4.1

## 1. 범위

학원이 외부에 노출하는 **공개 마케팅 페이지** + 검토 큐 + 운영자 어드민.

- 학원장(R-AO) 이 콘솔에서 편집 → 검토 → 게시
- 강사 목록은 `public_page_consent=true` 강사만 자동 노출 (R-AT-3)
- 학생/학부모 후기 / 합주 영상은 명시 동의 사례만 (R-AS-5) — AC-M5
- SEO + schema.org `EducationalOrganization` + 카카오톡 OG 카드 (R-AO-5)

비교: `lessonaza.app/{teacher_slug}` (강사 개인) vs `academy.lessonaza.app/{academy_slug}` (학원). 강사는 학원에 속하지 않아도 독립 운영 가능.

### 1.1 데이터 SoR 패턴 (3채널 분담)

학원 데이터 SoR 는 백엔드. 본 스펙은 **`academy-renderer` 채널 (web 공개)** 만 다룬다. 같은 백엔드 API 가 다음 3채널을 지원한다:

| 채널 | 인증 | 컨테이너 | 본 스펙 적용 |
|---|---|---|---|
| 외부 방문자 (앱 미설치) | 비인증 | `academy-renderer` (web) | **본 스펙** |
| 학원장·강사 콘솔 | 인증 (academy_owner/teacher) | `academy-console` (web) | `console_overview_spec.md` |
| 앱 학생/학부모 (선생님 검색 결과) | 인증 (user) | `lesson-app /academies/:id` | `[AcademyDetailScreen](../../../frontend/lib/features/search/presentation/screens/academy_detail_screen.dart)` |

> `lesson-app` 의 `AcademyDetailScreen` 은 본 스펙과 동일한 학원 정보를 표시하되 모바일 네이티브 위젯으로 렌더링. AC-M2 작업 시 backend API 가 두 채널(web 렌더러 + 앱) 에 동일 데이터를 반환하도록 설계. mock → remote 전환만 필요.

## 2. 데이터 모델

```python
class Academy(Base):
    id = Column(PK)
    slug = Column(String, unique=True)              # gangnam-rhythm
    name = Column(String)
    bio_markdown = Column(Text)                     # 학원 소개 (Markdown)
    address = Column(String)
    address_lat = Column(Float, nullable=True)
    address_lng = Column(Float, nullable=True)
    phone = Column(String, nullable=True)
    kakao_channel_id = Column(String, nullable=True)
    instruments = Column(JSON)                      # ["피아노", "바이올린"]
    business_hours = Column(JSON)                   # {"mon": "10:00-22:00", ...}
    cover_image_url = Column(String, nullable=True)
    og_image_url = Column(String, nullable=True)    # OG 카드 1200x630
    status = Column(Enum("draft", "review", "public", "suspended", "archived"))
    review_requested_at = Column(DateTime, nullable=True)
    review_responded_at = Column(DateTime, nullable=True)
    review_decision = Column(Enum("approved", "rejected"), nullable=True)
    review_reason = Column(Text, nullable=True)
    reviewed_by_user_id = Column(FK users, nullable=True)
    published_at = Column(DateTime, nullable=True)
    suspended_at = Column(DateTime, nullable=True)
    suspension_reason = Column(Text, nullable=True)

class AcademyTestimonial(Base):
    """학생/학부모 후기 (R-AS-5, AC-M5)"""
    id = Column(PK)
    academy_id = Column(FK)
    academy_student_id = Column(FK, nullable=True)
    author_name = Column(String)                    # 익명/실명 선택
    body = Column(Text)
    rating = Column(Integer, nullable=True)         # 1-5
    consented_at = Column(DateTime)
    consent_user_id = Column(FK users)              # 학생 또는 학부모
    public = Column(Boolean, default=True)

class AcademyVideo(Base):
    """합주·연주회 영상 (R-AS-5, AC-M5)"""
    id = Column(PK)
    academy_id = Column(FK)
    title = Column(String)
    youtube_id = Column(String)
    appears_in_students = Column(JSON)              # [student_id, ...] 출연 학생
    consents = relationship("AcademyVideoConsent")
    public = Column(Boolean, default=False)         # 모든 출연자 consent 시 true

class AcademyVideoConsent(Base):
    video_id = Column(FK)
    user_id = Column(FK users)
    decision = Column(Enum("approved", "rejected"))
    decided_at = Column(DateTime)
```

## 3. 페이지 상태 머신 (R-AO-6)

```
       편집                 검토 요청              운영자 승인
draft ────────► draft ──────────────► review ──────────────► public
                                       │                       │
                                       │ 거절 + 사유            │ 위반 신고
                                       ▼                       ▼
                                     draft                  suspended
                                                               │
                                                               │ 학원장 정지
                                                               ▼
                                                            archived
```

- 첫 게시는 반드시 `review` 거쳐 운영자 승인 (R-AO-6, R-OP-A-1)
- 이후 편집은 자동 재검토 X — 가이드라인 위반 신고 시 운영자 개입 (R-OP-A-4)

## 4. 학원장 편집 (`/page`)

### 4.1 편집 화면 구조

```
┌─────────────────────────────────────────────┐
│ 학원 페이지 편집                            │
├─────────────────────────────────────────────┤
│ [기본 정보] [강사 노출] [후기·영상] [SEO]   │
├─────────────────────────────────────────────┤
│ 학원 이름 [_______________]                  │
│ Slug      academy.lessonaza.app/[_________] │
│ 소개      [Markdown 에디터]                  │
│ 주소      [_______________] [지도 미리보기] │
│ 연락처    전화 / 카톡 채널                   │
│ 분야      [✓피아노 ✓바이올린 □기타]         │
│ 영업시간  [요일별 표]                        │
│ 커버 이미지 [업로드]                         │
│                                              │
│ [미리보기] [저장 (draft)] [검토 요청]       │
└─────────────────────────────────────────────┘
```

### 4.2 강사 노출 탭

```
강사 목록 (노출 동의한 강사만 표시)

| 강사 | 동의 | 표시 |
|---|---|---|
| 이선생 | ✓ 동의 | 이름·악기·소개·프로필 링크 |
| 박선생 | ✗ 미동의 | 노출 안됨 |
| 김선생 | ✓ 동의 | 이름·악기 (소개 미작성) |

> 강사의 동의 여부는 강사 본인이 lesson-app 에서 토글 (학원장 권한 X).
> 미동의 강사를 노출하려면 강사에게 직접 요청 메시지 발송.
```

### 4.3 검토 요청

```
POST /api/v1/academies/{id}/page/submit-review
→ Academy.status='review', review_requested_at
→ 운영자 어드민 큐에 추가
→ 학원장에게 "검토 요청 접수 — 1~2영업일 내 결과 안내" 알림
```

검토 SLA: 영업일 기준 1~2일. 운영자 어드민은 [../auth/](../auth/) 도메인.

## 5. 공개 페이지 (`academy.lessonaza.app/{slug}`)

### 5.1 렌더링

**컨테이너**: `academy-renderer` (FastAPI + Jinja2 SSR, profile-renderer 패턴 재활용)
**라우팅**: Traefik → `academy.lessonaza.app` Host 매칭 → `academy-renderer` 컨테이너
**캐시**: ISR 패턴 — 변경 시 무효화, TTL 1h

### 5.2 페이지 구조

```
┌─────────────────────────────────────────────┐
│ [커버 이미지]                                │
│                                              │
│  [학원 로고] 강남리듬                        │
│  📍 서울 강남구 ... | 🎵 피아노·바이올린    │
│  [전화] [카톡 채널] [문의 폼]                │
├─────────────────────────────────────────────┤
│ 학원 소개 (Markdown)                         │
│ ...                                          │
├─────────────────────────────────────────────┤
│ 강사 (8명)                                   │
│ ┌────┐ ┌────┐ ┌────┐                        │
│ │이선생│ │박선생│ │김선생│ ...               │
│ │피아노│ │바이올린│ │첼로 │                  │
│ │ → 프로필│                                  │
│ └────┘ └────┘ └────┘                        │
├─────────────────────────────────────────────┤
│ 영업시간 + 위치 (지도)                       │
├─────────────────────────────────────────────┤
│ 후기 (AC-M5)                                 │
│ 합주 영상 (AC-M5)                            │
├─────────────────────────────────────────────┤
│ Powered by Lessonaza                         │
└─────────────────────────────────────────────┘
```

### 5.3 강사 카드 → 강사 프로필 페이지

강사 카드 클릭 시 `lessonaza.app/{teacher_slug}` 로 이동 (강사 본인 slug 보유 시).
강사 본인 slug 없으면 `academy.lessonaza.app/{slug}/teachers/{id}` 간이 페이지.

### 5.4 연락 CTA (FR-ACPUB-3)

세 가지 옵션 — 학원 설정에 따라 표시:

| CTA | 동작 |
|---|---|
| 전화 | `tel:` 링크 |
| 카톡 | 카톡 채널 deep link |
| 문의 폼 | `POST /api/v1/academies/{id}/inquiries` → 학원장 인박스 |

문의 폼 필드: 이름, 연락처, 자녀 이름·나이, 악기, 메시지, 개인정보 동의.

## 6. SEO + 메타 (FR-ACPUB-4)

### 6.1 메타 태그

```html
<title>강남리듬 — 강남구 피아노·바이올린 학원 | Lessonaza</title>
<meta name="description" content="강남구 역삼동 ...">
<meta property="og:title" content="강남리듬">
<meta property="og:description" content="...">
<meta property="og:image" content="https://.../og.jpg">
<meta property="og:url" content="https://academy.lessonaza.app/gangnam-rhythm">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
```

### 6.2 schema.org JSON-LD

```json
{
  "@context": "https://schema.org",
  "@type": "EducationalOrganization",
  "name": "강남리듬",
  "url": "https://academy.lessonaza.app/gangnam-rhythm",
  "logo": "...",
  "image": "...",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "서울 강남구 ...",
    "addressLocality": "Seoul",
    "addressCountry": "KR"
  },
  "geo": { "@type": "GeoCoordinates", "latitude": 37.5, "longitude": 127.0 },
  "telephone": "+82-2-...",
  "openingHoursSpecification": [...],
  "department": [
    {
      "@type": "EducationalOrganization",
      "name": "피아노 과정",
      "employee": [{"@type": "Person", "name": "이선생"}]
    }
  ]
}
```

### 6.3 카카오톡 OG 카드

`og_image_url` 1200x630, 카톡 캐시 무효화: 발행 시 `?v={timestamp}` 쿼리 자동 추가.

## 7. 학생/학부모 후기 (R-AS-5, AC-M5)

### 7.1 추가 흐름

```
1. 학원장 → /page → "후기 추가"
2. 학생 또는 학부모 선택 → 동의 요청 발송
3. 학생/학부모: lesson-app → "후기 동의" 화면
   - 본문 미리보기
   - 익명/실명 선택
   - "동의" 클릭 → AcademyTestimonial.public=true
4. 학원장: 검토 후 (수정 불가) 게시 ON/OFF
```

학생/학부모 본인이 "회수" 클릭 시 즉시 `public=false`.

### 7.2 영상 동의 (AC-M5)

출연한 모든 학생/학부모 동의 필요. 1명이라도 거절 시 게시 불가.

## 8. 운영자 어드민 / 위반 신고 (R-OP-A-1, R-OP-A-4)

### 8.1 검토 큐

[../auth/](../auth/) 도메인의 운영자 어드민에서 처리:
- `GET /api/v1/admin/academies/review-queue?status=review`
- 항목 클릭 → 학원 페이지 미리보기 + 가이드라인 체크리스트
- 승인 → status='public', published_at
- 거절 → status='draft', review_reason → 학원장 알림

### 8.2 위반 신고 처리

```
신고자(일반 사용자) → /page 의 "신고" → 사유 입력
   → 운영자 어드민 신고 큐
   → 1차 경고: 학원장에게 가이드라인 위반 알림
   → 2차 비공개: status='suspended'
   → 3차 권한 회수: status='archived' + Academy.owner_id 박탈
   → 모든 단계 AuditLog
```

## 9. Slug 관리

- 학원장 가입 시 slug 입력 → 검증 (정책: [../../user/slug_lifecycle_spec.md](../../user/slug_lifecycle_spec.md) 재활용)
- 예약어 (admin, api, www, 등) 금지
- 변경: 30일 1회 + 운영자 승인 (선생님 slug 정책과 동일)
- 변경 시 이전 slug 30일 301 redirect

## 10. 성능

- 페이지 LCP < 2.0s (모바일 4G)
- 강사 50명 학원 기준 페이지 크기 < 200KB (이미지 제외)
- 이미지 최적화: WebP + responsive `srcset`
- CDN: Cloudflare (정적 자산)
- ISR 캐시 무효화: 학원장 편집·강사 동의 변경·후기 추가 시

## 11. 변경 이력

- 2026-05-19: 초안
- 2026-05-21: §1.1 데이터 SoR 3채널 분담 추가 — academy-renderer (본 스펙), academy-console, lesson-app AcademyDetailScreen 의 역할 분담 명시. 백엔드 API 가 동일 데이터를 3채널에 제공.
