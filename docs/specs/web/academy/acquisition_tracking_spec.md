# academy/acquisition_tracking_spec — 유입 채널 추적 + 마케팅 ROI

> 기준일: 2026-06-04
> 경로: `/marketing/channels`, `/marketing/funnel`
> 마일스톤: AC-M5 (UTM MVP) / AC-M8 (Growth — 채널 ROI 분석)
> 선행: [public_page_spec.md](public_page_spec.md), [parent_referral_spec.md](parent_referral_spec.md), [inbox_spec.md](inbox_spec.md), [dashboard_spec.md §3.6](dashboard_spec.md)
> 갭분석 input: `.harness/research/academy_spec_gap_2026.md` H#3

## 1. 배경 / 범위

학원 공개 페이지 (`academy.lessonaza.app/{slug}`) 방문자가 어디서 왔는지 추적이 부재 → 학원장이 어떤 채널이 효과 있는지 모름 → 마케팅 ROI 계산 불가.

소규모 음악학원의 신규 학생 유입 채널 (시장조사 추정):
- 학부모 추천: 60-70% ([parent_referral_spec.md](parent_referral_spec.md) 별도 추적)
- 카카오 검색 / 광고: 10-15%
- 네이버 지도 / 블로그: 10-15%
- 동네 광고지 / QR / 간판: 5-10%
- 직접 방문 (지나가다): 5%

본 스펙은 **추천 외 유입** 의 추적을 정의. 추천은 [parent_referral_spec.md](parent_referral_spec.md) SSOT.

**핵심 원칙:**
- UTM 표준 사용 (Google Analytics 호환 — 향후 통합 용이)
- 학원장이 추적 링크를 직접 생성·공유 (자동 추적 X)
- PII 비저장 (IP/세션은 hash 또는 즉시 폐기)
- 학원장 화면은 익명 집계만 (어느 학부모가 어디서 왔는지 X)

## 2. 데이터 모델

```python
class AcademyAcquisitionLink(Base):
    """학원장이 생성한 추적 링크 (1 학원 × N 캠페인)."""
    id = Column(PK)
    academy_id = Column(FK)
    label = Column(String)                                # "동네 광고지 5월"
    utm_source = Column(String)                           # naver / kakao / instagram / offline_qr
    utm_medium = Column(String)                           # cpc / banner / qr / referral_card
    utm_campaign = Column(String, nullable=True)          # "spring_2026"
    utm_content = Column(String, nullable=True)           # 광고지 종류 등
    short_code = Column(String, unique=True)              # 단축 URL 식별자 (URL 짧게)
    target_url = Column(String)                           # 최종 도착 (학원 페이지 + UTM)
    created_at = Column(DateTime)
    created_by_user_id = Column(FK users)                 # 학원장
    state = Column(Enum("active", "archived"), default="active")
    notes = Column(Text, nullable=True)


class AcademyAcquisitionEvent(Base):
    """공개 페이지 방문/문의/가입 이벤트 (PII 비저장)."""
    id = Column(PK)
    academy_id = Column(FK)
    occurred_at = Column(DateTime)
    event_type = Column(Enum(
        "page_view",       # 공개 페이지 로드
        "inquiry_start",   # 문의 폼 시작
        "inquiry_submit",  # 문의 폼 제출
        "trial_booked",    # 체험 레슨 예약
        "enrolled",        # 정식 등록 완료
    ))
    utm_source = Column(String, nullable=True)
    utm_medium = Column(String, nullable=True)
    utm_campaign = Column(String, nullable=True)
    utm_content = Column(String, nullable=True)
    acquisition_link_id = Column(FK, nullable=True)       # 매칭된 short_code
    session_hash = Column(String)                         # PII 비저장 hash (cookie 또는 fingerprint)
    referrer_domain = Column(String, nullable=True)       # search.naver.com / m.kakao.com (도메인만)
    is_mobile = Column(Boolean)
    region_hint = Column(String, nullable=True)           # 시/도 단위 추정 (IP→region)
    inquiry_id = Column(FK academy_inquiries, nullable=True)  # event_type=inquiry_submit 시
    student_id = Column(FK academy_students, nullable=True)   # event_type=enrolled 시

    __table_args__ = (
        Index("idx_acq_academy_time", "academy_id", "occurred_at"),
        Index("idx_acq_session", "session_hash"),
    )
```

## 3. 추적 링크 생성 (학원장)

`/marketing/links/new`:

```
┌──────────────────────────────────────────────┐
│ 추적 링크 만들기                            │
├──────────────────────────────────────────────┤
│ 라벨: [동네 광고지 5월             ]        │
│                                              │
│ 채널 (utm_source):                          │
│   ○ 네이버 검색  ○ 네이버 블로그            │
│   ○ 카카오 채널 ○ 인스타그램                │
│   ● 오프라인 광고지 (offline)               │
│   ○ 기타: [        ]                        │
│                                              │
│ 매체 (utm_medium):                          │
│   ○ CPC 광고  ○ 배너  ○ QR 코드             │
│   ● 광고지/명함  ○ SMS                      │
│                                              │
│ 캠페인 (선택): [spring_2026         ]       │
│ 메모: [                  ]                   │
│                                              │
│ 미리보기 URL:                                │
│ https://academy.lessonaza.app/jaepark        │
│   ?utm_source=offline&utm_medium=flyer       │
│   &utm_campaign=spring_2026                  │
│                                              │
│ 단축 URL: lz.kr/p/X8K2  [복사][QR 다운로드] │
│                                              │
│              [링크 생성]                     │
└──────────────────────────────────────────────┘
```

생성된 `lz.kr/p/{short_code}` 가 학원 공개 페이지로 301 redirect (UTM 파라미터 부착). short_code 는 사람이 입력 가능한 길이 (4-8자, 영문+숫자, 헷갈리는 글자 제외).

## 4. 이벤트 수집

### 4.1 page_view (공개 페이지 로드 시)

```javascript
// academy-renderer 클라이언트 (Next.js / Astro 등)
window.addEventListener('load', () => {
  const params = new URLSearchParams(window.location.search);
  navigator.sendBeacon('/api/v1/public/acquisition/event', JSON.stringify({
    academy_slug: SLUG,
    event_type: 'page_view',
    utm_source: params.get('utm_source'),
    utm_medium: params.get('utm_medium'),
    utm_campaign: params.get('utm_campaign'),
    utm_content: params.get('utm_content'),
    referrer: document.referrer ? new URL(document.referrer).hostname : null,
    is_mobile: /Mobi|Android/i.test(navigator.userAgent),
    session_id: getOrCreateSessionId(),  // 1st-party cookie, 30분 만료
  }));
});
```

서버는 `session_id` 를 즉시 hash 처리 (`session_hash = sha256(session_id + academy_id + day_salt)`). 원본 보존 X.

### 4.2 후속 이벤트 (inquiry_start → submit → enrolled)

같은 `session_hash` 로 funnel 연결. 단:
- 학부모가 lesson-app 가입 후 컨텍스트 변경 → session 끊김
- 첫 접점부터 enrolled 까지 N일 (평균 2-7일) 추적 필요

해결: `AcademyInquiry.acquisition_session_hash` 컬럼 추가. 문의 제출 시 session_hash 보존 → enrolled 시 학생-문의 매핑으로 추적.

### 4.3 자연 유입 (UTM 없음) 분류

`utm_source` 비어 있으면 `referrer_domain` 으로 추정:
- `search.naver.com` / `www.google.com` → `organic_search`
- `m.kakao.com` / `pf.kakao.com` → `kakao_organic`
- `instagram.com` / `l.instagram.com` → `instagram_organic`
- 빈 referrer + 모바일 → `direct_mobile` (북마크 또는 카톡 메시지 직접 클릭 추정)
- 빈 referrer + 데스크탑 → `direct_desktop`

## 5. 학원장 화면

### 5.1 채널 대시보드 (`/marketing/channels`)

```
┌─────────────────────────────────────────────────────────┐
│ 유입 채널 (이번 달)                                    │
├─────────────────────────────────────────────────────────┤
│ 방문 → 문의 → 등록  (Conversion Funnel)                │
│ ─────────────────────────────────────────────────────── │
│ 전체:        4,200 → 87 (2.1%) → 18 (20.7%)            │
│                                                         │
│ 채널별:                                                 │
│ • 네이버 검색      1,800 → 42 → 9  (CPC ₩200/방문)    │
│ • 카카오 채널        800 → 18 → 4  (organic)           │
│ • 추천 (referral)    600 → 25 → 8  (자동 — 추천 SSOT) │
│ • 오프라인 광고지    400 → 4 → 1   (CPC ₩500/방문)    │
│ • 직접 방문          600 → 8 → 1   (organic)           │
│                                                         │
│ [채널별 LTV 비교 →]                                    │
└─────────────────────────────────────────────────────────┘
```

### 5.2 funnel 화면 (`/marketing/funnel`)

각 단계별 drop-off + 평균 소요 시간:

```
공개 페이지 방문 (4,200)
    ↓ (2.1%, 평균 1.5분 체류)
문의 폼 시작 (87)
    ↓ (95%, 평균 3분 작성)
문의 제출 (83)
    ↓ (학원장 답변 SLA — inbox_spec)
체험 예약 (35)
    ↓ (51%, 평균 7일 후)
정식 등록 (18)
```

각 drop-off 클릭 시 가설 (예: "체험 → 등록 전환률 낮음, 첫 수업 경험 점검 필요").

### 5.3 채널별 LTV 비교

[parent_referral_spec.md §8](parent_referral_spec.md) ROI 분석과 동일 패턴:

```
채널별 신규 학생 평균 LTV (12개월 기준):
1. 학부모 추천      ₩3,200,000  (재학률 92%)
2. 네이버 검색      ₩2,400,000  (재학률 78%)
3. 인스타그램       ₩1,800,000  (재학률 65%)
4. 오프라인 광고지  ₩1,200,000  (재학률 55%)
5. 카카오 채널      ₩2,100,000  (재학률 72%)
```

학원장 의사결정:
- "추천 학생 LTV 가장 높음 → [parent_referral_spec.md](parent_referral_spec.md) 보상 인상"
- "오프라인 광고지 LTV 낮음 → 광고지 디자인 점검 또는 채널 중단"

## 6. 광고비 입력 (수기)

자동 광고비 추적 X (네이버/카카오 광고 API 미연동 — Year 2). 학원장이 수기 입력:

`/marketing/spend`:

```
┌──────────────────────────────────────────────┐
│ 광고비 입력 (이번 달)                       │
├──────────────────────────────────────────────┤
│ 네이버 검색 CPC:  [   500,000] 원           │
│ 카카오 채널광고:  [   200,000] 원           │
│ 인스타 광고:      [   150,000] 원           │
│ 광고지 제작:      [    80,000] 원           │
│                                              │
│ 합계 (수기): ₩930,000                        │
│ 이번 달 신규 등록: 18명 (₩51,667/명)        │
│ 이번 달 신규 LTV 합계: ₩40M  (ROI 43배)     │
│                                              │
│         [저장]                              │
└──────────────────────────────────────────────┘
```

월말 학원장이 CAC (Customer Acquisition Cost) + ROI 한눈에 파악. 채널별 CAC 도 자동 계산.

## 7. 카톡 채널 클릭 추적

학원이 카카오 채널 운영 시 — 학부모가 카카오 채널에서 "학원 가기" 버튼 클릭 → `academy.lessonaza.app/{slug}?utm_source=kakao&utm_medium=channel`.

학원장 화면에서:
- 카카오 채널 친구 수 (수기 입력 or 카카오 BizMessage API — Year 2)
- 채널에서 페이지 진입 전환률
- 채널 → 문의 전환률

## 8. 데이터 보존 / 익명화

- `session_hash` 는 30일 후 자동 익명화 (= NULL 처리, 통계만 보존)
- `referrer_domain` 만 보존, 풀 URL 비저장
- `region_hint` 는 시/도 단위만 (구/동 차단)
- IP 주소 비저장 (직접 추출 후 즉시 폐기)

## 9. 권한 / 보안

- 링크 생성/조회: `Depends(current_academy_owner)`
- 이벤트 수집 (`POST /public/acquisition/event`): 인증 X + rate limit (학원당 IP당 분당 60건)
- 분석 화면: 학원장 전용 + AuditLog (분석 화면 접근 로그)
- 학부모 PII 노출 X — 익명 집계만

## 10. 비기능

- 이벤트 수집 < 100ms (학부모 페이지 로드 영향 X — sendBeacon 사용)
- 채널 대시보드 < 1s (월간 집계 캐시 TTL 30분)
- 광고비 ROI 계산은 학원당 < 500ms

## 11. 실패 / 예외

| 상황 | 처리 |
|---|---|
| UTM 파라미터 변조 (사용자 임의 입력) | 학원이 발급한 short_code 와 매칭 시 신뢰 / 매칭 안 되면 "기타" |
| 학부모 ad-blocker 로 이벤트 수집 실패 | 통계 누락 — server-side 추정 폴백 (referrer만) |
| 채널 = "추천" 인데 학부모 코드 입력 안 함 | "추천 (코드 미입력)" 별도 카테고리 |
| 이벤트 폭주 (학원 페이지 viral) | rate limit + 5분 burst window |

## 12. 변경 이력

- 2026-06-04: 초안 (갭분석 H#3 응답: UTM 추적 부재 해소. 표준 utm_source/medium/campaign + 학원장 수기 링크 생성 + short_code + funnel + 채널별 LTV/CAC/ROI + 수기 광고비 입력. PII 비저장 원칙)
