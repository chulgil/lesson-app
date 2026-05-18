# SEO / 랜딩 페이지 / 콘텐츠 전략 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟠 HIGH (출시 후 3개월)
> 관련: [teacher_referral_spec.md](../lesson/invite/teacher_referral_spec.md), [student_install_web_landing_spec.md](../lesson/invite/student_install_web_landing_spec.md)

---

## 0. 개요

웹 존재감 0 → 자연 유입 확보. 앱스토어 외 유입 채널 구축 + "음악 레슨 관리 앱" 검색 시 1페이지 노출.

기존 `student_install_web_landing_spec.md`는 초대 링크 전용 — 본 스펙은 **마케팅 본진** lessonaza.com.

---

## 1. 현황 진단

| 항목 | 상태 |
|------|------|
| 초대 링크 랜딩 (`/i/{code}`) | ✅ `student_install_web_landing_spec.md` |
| 메인 랜딩 (`lessonaza.com`) | ❌ 없음 |
| `/pricing` | ❌ |
| `/features` | ❌ |
| `/about` | ❌ |
| `/blog` | ❌ |
| SEO 메타태그 | ❌ |
| Open Graph | ❌ |
| robots.txt / sitemap.xml | ❌ |

---

## 2. 기술 스택

| 항목 | 선택 | 사유 |
|------|------|------|
| 정적 사이트 | Next.js 15 (App Router) | SEO 우수, Vercel 무료 호스팅, 차후 dynamic 확장 |
| 호스팅 | Vercel | CDN + edge function 무료 |
| CMS | 마크다운 파일 (`/content/blog/*.md`) | 별도 CMS 불필요 (Year 1) |
| 분석 | GA4 (앱과 동일 property — `lessonaza.com` 스트림 추가) | 일관성 |
| 도메인 | `lessonaza.com` | 메인 / `app.lessonaza.com`은 백엔드 API |

---

## 3. 페이지 구조

```
lessonaza.com/
├── /                       메인 랜딩 (hero + features + pricing 미니 + CTA)
├── /features              기능 소개
│   ├── /teacher           선생님용 기능
│   ├── /student           학생/학부모용 기능
│   └── /academy           학원용 기능
├── /pricing               요금제 (paywall_spec과 동기화)
├── /about                 회사 소개 / 비전
├── /blog/                 블로그 인덱스
│   └── /blog/{slug}       포스트 상세
├── /support/              헬프 센터 (customer_support_spec과 연동)
│   └── /support/faq       FAQ
├── /legal/                약관/개인정보처리방침 (앱과 동일 내용)
│   ├── /legal/terms
│   └── /legal/privacy
├── /i/{inviteCode}        초대 링크 (기존)
├── /r/{referralCode}      추천 링크 (teacher_referral_spec)
└── /download              앱스토어 리다이렉트
```

---

## 4. 메인 랜딩 (/)

### 4.1 hero 섹션

```
[Logo]                          [로그인] [무료 시작하기]

음악 레슨, 이제 종이가 아닌 앱에서.

선생님 · 학생 · 학부모가 한 앱에서 만나는
유일한 음악 레슨 관리 도구

[App Store]  [Play Store]
```

### 4.2 features 섹션

| 카드 | 메시지 |
|------|--------|
| 레슨 노트 디지털화 | "수기 노트를 사진/녹음/태그로" |
| 자녀 진도 실시간 | "학부모도 같이 보는 레슨 기록" |
| 메트로놈/튜너 내장 | "연습 도구가 손 안에" |
| 수강권 관리 | "입금부터 만료까지 자동 추적" |

### 4.3 social proof

- 사용자 수치 (출시 후 채워짐)
- 선생님 인터뷰 카드 3개
- 별점 (앱스토어 평점 임베드)

### 4.4 footer CTA

"오늘 시작하면 14일간 Pro 무료로 사용해보실 수 있어요"

---

## 5. SEO 전략

### 5.1 타겟 키워드 (네이버 + Google)

| 키워드 | 월간 검색량 (추정) | 우선 |
|--------|------|------|
| 음악 레슨 관리 앱 | 500+ | 🔴 |
| 피아노 레슨 관리 | 800+ | 🔴 |
| 바이올린 학원 관리 | 200+ | 🟠 |
| 레슨 노트 앱 | 100+ | 🟠 |
| 음악 학원 출석 관리 | 400+ | 🟠 |
| 메트로놈 앱 | 5000+ | 🟡 (경쟁 치열) |
| 튜너 앱 | 8000+ | 🟡 |
| 자녀 음악 레슨 기록 | 50+ | 🟡 |

### 5.2 페이지별 메타태그

```html
<!-- 메인 -->
<title>Lessonaza — 음악 레슨 관리 앱</title>
<meta name="description" content="선생님, 학생, 학부모가 한 앱에서 만나는 음악 레슨 관리 도구. 레슨 노트, 수강권, 연습 기록을 한 번에." />

<!-- /features/teacher -->
<title>선생님을 위한 레슨 관리 — Lessonaza</title>
<meta name="description" content="학생 관리부터 레슨 노트, 수강권 입금 추적까지. 음악 선생님이 매일 쓰는 도구." />
```

### 5.3 Open Graph

모든 페이지:
```html
<meta property="og:image" content="https://lessonaza.com/og-{slug}.png" />
<meta property="og:title" content="..." />
<meta property="og:description" content="..." />
```

### 5.4 구조화 데이터 (JSON-LD)

`/`에 SoftwareApplication schema, `/blog/{slug}`에 Article schema.

### 5.5 사이트맵

- `robots.txt` — 허용/거부 정책
- `sitemap.xml` — 주간 빌드 자동 생성
- 네이버 웹마스터 + Google Search Console 등록

---

## 6. 블로그 콘텐츠 전략

### 6.1 발행 빈도

- Year 1: 월 2개 (총 20개)
- Year 2: 주 1개 (총 50개+)

### 6.2 첫 12개 글 토픽

| # | 제목 | 타겟 키워드 |
|---|------|------------|
| 1 | 피아노 선생님을 위한 레슨 관리 가이드 (2026) | 피아노 레슨 관리 |
| 2 | 음악 학원 운영, 디지털화로 바뀌는 5가지 | 음악 학원 관리 |
| 3 | 자녀의 레슨 진도, 학부모는 어디까지 봐야 할까 | 자녀 음악 레슨 |
| 4 | 바이올린 레슨 노트, 종이 vs 앱 비교 | 바이올린 학원 |
| 5 | 메트로놈 앱 비교 — 무료부터 프로까지 | 메트로놈 앱 |
| 6 | 음악 학원 수강권, 효율적 관리 방법 | 음악 학원 수강권 |
| 7 | 음대 입시 준비, 매일 연습 기록의 힘 | 음대 입시 |
| 8 | 1:1 vs 그룹 레슨, 운영 차이는? | 음악 학원 운영 |
| 9 | 레슨비 입금 관리, 무통장 입금 한계를 넘다 | 음악 학원 입금 |
| 10 | 음악 선생님 첫 학원 차리기 체크리스트 | 음악 학원 창업 |
| 11 | 학부모와의 소통, 어떤 방식이 효과적일까 | 음악 학원 학부모 |
| 12 | 코로나 이후, 음악 레슨 시장은 어떻게 변했나 | 음악 레슨 시장 |

### 6.3 콘텐츠 SOP

- 글당 1500자~3000자
- 헤딩(H2/H3) 3개 이상 (스크롤 후크)
- 이미지 3개 이상 (alt 텍스트 필수)
- 내부 링크 3개 (다른 블로그 + features 페이지)
- CTA 1개 (블로그 하단 "무료로 시작하기")

### 6.4 YouTube 채널 병행

- Year 1 목표: 5개 영상
- 토픽: 앱 사용법 튜토리얼, 선생님 인터뷰
- 블로그와 상호 임베드

---

## 7. 광고 / 유료 트래픽 (선택)

| 채널 | 예산 (월) | 타겟 |
|------|----------|------|
| Google Ads (검색) | 30만원 | "피아노 레슨 관리 앱" 등 키워드 |
| 인스타 광고 | 20만원 | 음악 선생님 인플루언서 |
| 네이버 검색광고 | 20만원 | 한국 키워드 |

출시 후 3개월부터 점진 도입. ROI 모니터링 후 확대.

---

## 8. 분석

### 8.1 추적 지표

| 지표 | 목표 (Year 1 말) |
|------|-----------------|
| 월간 방문자 | 5,000+ |
| 자연 검색 비율 | 50%+ |
| 블로그 → 다운로드 전환 | 5%+ |
| `/r/{code}` 추천 링크 클릭 | 월 200+ |

### 8.2 GA4 이벤트

| 이벤트 | 속성 |
|--------|------|
| `landing_page_view` | path, source |
| `blog_post_read` | slug, scroll_depth |
| `app_download_clicked` | platform, page |
| `referral_landing_view` | referral_code |

---

## 9. 운영

| 항목 | 담당 | 빈도 |
|------|------|------|
| 블로그 신규 글 작성 | 외주 작가 + 내부 감수 | 월 2회 |
| SEO 키워드 점검 | 내부 | 분기 1회 |
| 페이지 성능 (Core Web Vitals) | 자동 (Vercel) | 상시 |
| 백링크 빌드 | 점진적 | 출시 후 6개월부터 |

---

## 10. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | Next.js 15 채택 (Gatsby/Hugo 대신) | SEO 우수 + 향후 dynamic 확장 가능 |
| 2026-05-18 | 마크다운 CMS로 시작 | Year 1은 글 수가 적어 별도 CMS 불필요 |
| 2026-05-18 | 네이버 SEO 별도 신경 (Google 외) | 한국 시장 우선, 네이버 검색 점유율 30%+ |
| 2026-05-18 | 메트로놈/튜너 키워드는 후순위 | 경쟁 치열 + 핵심 사용자(선생님)와 무관 |

---

## 11. 관련 문서

- [student_install_web_landing_spec.md](../lesson/invite/student_install_web_landing_spec.md) — `/i/{code}` 초대 랜딩
- [teacher_referral_spec.md](../lesson/invite/teacher_referral_spec.md) — `/r/{code}` 추천 랜딩
- [paywall_spec.md](../subscription/paywall_spec.md) — `/pricing` 페이지 콘텐츠 SSOT
- [event_tracking_spec.md](../analytics/event_tracking_spec.md) — 웹 GA4 통합
- [competitive_moat_spec.md](./competitive_moat_spec.md) — 브랜드 해자 전략
