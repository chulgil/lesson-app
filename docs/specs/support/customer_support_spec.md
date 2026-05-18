# 고객 지원 스펙

> 작성일: 2026-05-18
> 상태: 활성 (마스터 SSOT)
> 우선: 🟡 MEDIUM (출시 후 6개월)
> 관련: [account_lifecycle_spec.md](../user/account_lifecycle_spec.md), [seo_landing_spec.md](../growth/seo_landing_spec.md)

---

## 0. 개요

문의 접수 + 처리 + 알림. Phase 1 외부 헬프데스크 연동, Phase 2 인앱 티켓 트래커.

---

## 1. 현황 진단

| 항목 | 상태 |
|------|------|
| 인앱 문의 진입 | 🟡 설정 → "문의하기" (이메일 mailto) |
| 헬프데스크 도구 | ❌ |
| FAQ | ❌ |
| 인앱 채팅 | ❌ |
| 티켓 추적 | ❌ |
| SLA 정의 | ❌ |

---

## 2. Phase 1 — Zendesk 연동 (출시 후 6개월)

### 2.1 도구 선택

| 도구 | 가격 | 사유 |
|------|------|------|
| **Zendesk Support** | $19/월/agent | 표준, API 풍부 |
| Freshdesk | $15/월 | 저렴하나 API 제한 |
| Intercom | $99/월~ | 인앱 채팅 강점, 비쌈 |
| Help Scout | $20/월 | 이메일 중심 |

**Phase 1 채택: Zendesk** — Year 1은 1 agent ($19/월 = 23만원/월).

### 2.2 진입 흐름

```
설정 → 문의하기
  ↓
인앱 폼:
  - 카테고리 (계정/결제/기능/버그/기타)
  - 제목
  - 내용
  - 첨부 (스크린샷 최대 5장)
  ↓
[제출]
  ↓
Zendesk API → 티켓 생성 + 사용자 메타데이터 자동 첨부
  ↓
화면: "접수됐어요. 24시간 내 회신 드려요. 티켓번호: #12345"
```

### 2.3 사용자 프로필 자동 첨부

티켓에 자동 포함되는 정보 (운영자 참고용):

| 정보 | 값 |
|------|-----|
| user_id (hash) | abc123... |
| user_role | teacher / student / parent / academy_owner |
| plan | free / pro / lifetime |
| app_version | 1.2.3 |
| platform | iOS 17.5 / Android 14 |
| device_model | iPhone 15 / SM-A546 |
| account_created_at | 2026-01-15 |
| last_active_at | 2026-05-18 09:30 |
| recent_errors | (최근 24시간 Crashlytics ID 3개) |

PII는 포함 안 함 (이름/이메일은 Zendesk 시스템에 별도 — `account_lifecycle_spec` PII 정책 준수).

### 2.4 응답

운영자가 Zendesk에서 답장 → Zendesk가 사용자에게 이메일 발송 + 푸시 알림.

---

## 3. Phase 2 — 인앱 티켓 트래커 (Year 2 백로그)

> ⚠️ **Year 2 백로그 — Phase 1 출시 시점에 미구현.** Phase 1은 Zendesk 이메일만으로 운영. 1인 운영 부담을 줄이기 위해 인앱 트래커는 사용자 200K+ 또는 일 문의 50건+ 도달 시 검토. Year 1 운영 데이터로 ROI 판단 후 도입.

### 3.1 동기

이메일만으로는 사용자가 진행 상황을 알기 어려움. 인앱에서 직접 추적.

### 3.2 UI

```
설정 → 내 문의 (배지 N건)
  ↓
[활성] [완료]
  ↓
#12345 결제 환불 요청 — 답변 대기 (1일 전)
#12344 메트로놈 박자 안 맞음 — 답변 도착 (3일 전, 미확인)
#12342 ✅ 학생 추가 안 됨 — 완료 (1주 전)
```

### 3.3 데이터 모델

```python
class SupportTicket(Base):
    id: int  # 사용자에게 보여줌
    user_id: int (FK User)
    zendesk_ticket_id: str  # 외부 ID
    category: str
    subject: str
    status: str  # open / waiting_user / waiting_agent / solved / closed
    last_activity_at: datetime
    unread_for_user: bool
    created_at: datetime
```

Zendesk webhook → 백엔드 → SupportTicket 동기화.

### 3.4 푸시 알림

| 이벤트 | 알림 |
|--------|------|
| 답변 도착 | "문의 #12345에 답변이 도착했어요" |
| 해결 완료 | "문의 #12345 해결됐어요. 만족도를 평가해주세요." |

---

## 4. FAQ / 헬프 센터

### 4.1 위치

`lessonaza.com/support/faq` (seo_landing_spec § /support).

### 4.2 카테고리 (Phase 1: 20문항)

| # | 카테고리 | 예시 질문 |
|---|---------|----------|
| 1 | 시작하기 | 회원가입은 어떻게 하나요? |
| 2 | 학생 관리 | 학생을 어떻게 초대하나요? |
| 3 | 레슨 노트 | 사진/녹음을 어떻게 첨부하나요? |
| 4 | 수강권 | 입금 확인이 안 돼요. |
| 5 | 메트로놈/튜너 | 음정이 정확하지 않아요. |
| 6 | 결제 | Pro 구독을 어떻게 취소하나요? |
| 7 | 계정 | 비밀번호를 잊었어요. |
| 8 | 프라이버시 | 내 데이터를 어떻게 내려받나요? |

### 4.3 인앱 검색

설정 → 문의하기 → "혹시 이 답이 도움 될까요?" — 카테고리/제목 기반 FAQ 추천. 사용자가 클릭 시 티켓 생성률 감소.

### 4.4 운영

- 월 1회 FAQ 갱신 (티켓 빈도 기반 추가)
- "이 답변이 도움 됐어요?" 👍/👎 — 👎가 많은 답변 재작성

---

## 5. SLA (Service Level Agreement)

### 5.1 응답 / 해결 목표

| 우선순위 | 정의 | 응답 | 해결 |
|---------|------|------|------|
| 🔴 Critical | 결제 실패, 데이터 손실 | 4시간 | 24시간 |
| 🟠 High | 핵심 기능 작동 안 함 | 12시간 | 72시간 |
| 🟡 Medium | 일반 기능 문의 | 24시간 | 1주일 |
| 🟢 Low | 개선 제안, 일반 질문 | 48시간 | 2주일 |

### 5.2 운영 시간

| 시점 | 처리 |
|------|------|
| 평일 09:00–18:00 KST | 정상 |
| 평일 외 / 주말 | 익영업일 처리 (응답 시간 산정 제외) |
| 공휴일 | 익영업일 |

### 5.3 야간 / 주말 자동 응답

```
"문의 주셔서 감사합니다. 영업시간(평일 9–18시) 외라
다음 영업일에 회신 드립니다. 결제 긴급 문의는
앱 내 '긴급 결제 문제' 버튼을 이용해주세요."
```

긴급 결제 문제는 별도 채널 → Slack 즉시 알림 (담당자 on-call).

---

## 6. 사용자 만족도 (CSAT)

### 6.1 측정

티켓 해결 후 푸시:
```
"문의 #12345 해결됐어요. 평가해주세요."

😞   😐   🙂   😊   🤩
1    2    3    4    5
```

### 6.2 KPI (Year 1 말)

| 지표 | 목표 |
|------|------|
| CSAT 평균 | 4.2 / 5 |
| First Response Time (avg) | 8시간 |
| Resolution Time (avg) | 36시간 |
| 응답 후 만족도 | 80%+ (4-5점) |

---

## 7. 백엔드 API

```
POST /api/v1/support/tickets               # 티켓 생성 (Phase 1+)
GET  /api/v1/support/tickets               # 내 티켓 목록 (Phase 2)
GET  /api/v1/support/tickets/{id}          # 티켓 상세 (Phase 2)
POST /api/v1/support/tickets/{id}/reply    # 추가 메시지 (Phase 2)
POST /api/v1/support/tickets/{id}/csat     # 만족도 점수

POST /webhooks/zendesk                     # Zendesk → 백엔드 동기화
```

---

## 8. 운영자 도구 (Admin)

### 8.1 Admin 대시보드 (Year 2)

`/admin/support` — Zendesk 외부에서도 빠르게 확인:
- 활성 티켓 수 / 응답 대기 / 해결 완료
- SLA 위반 임박 (응답 시간 90% 도달)
- 우선순위 자동 분류 (Critical 키워드 감지)

### 8.2 자동 분류

```python
def auto_prioritize(subject: str, body: str) -> Priority:
    text = (subject + " " + body).lower()
    if any(kw in text for kw in ["결제", "환불", "돈", "billing"]):
        return Priority.CRITICAL
    if any(kw in text for kw in ["크래시", "안 켜져", "버그"]):
        return Priority.HIGH
    return Priority.MEDIUM
```

---

## 9. 통계 / 분석

월간 보고:

| 지표 | 측정 |
|------|------|
| 신규 티켓 / DAU | 비율 모니터링 (1% 미만 목표) |
| 카테고리별 분포 | Top 3 → 제품 개선 시그널 |
| SLA 준수율 | Critical 95%+, High 90%+ |
| FAQ 클릭률 | 신규 FAQ 작성 우선순위 |

---

## 10. AppStrings 키

| 키 | 한국어 |
|----|--------|
| `supportInquireTitle` | 문의하기 |
| `supportCategoryAccount` | 계정 |
| `supportCategoryBilling` | 결제 |
| `supportCategoryFeature` | 기능 |
| `supportCategoryBug` | 버그 |
| `supportCategoryOther` | 기타 |
| `supportSubmitted` | 문의가 접수됐어요. 영업일 기준 {hours}시간 내 회신 드려요. |
| `supportTicketNumber` | 문의번호: #{id} |
| `supportFaqSuggest` | 혹시 이 답이 도움 되시나요? |
| `supportCsatPrompt` | 답변이 도움 됐나요? |
| `supportEmergencyBilling` | 긴급 결제 문제 |

---

## 11. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | Phase 1 Zendesk (Intercom 대신) | 비용 5배 차이, Year 1 인앱 채팅 불필요 |
| 2026-05-18 | 인앱 티켓 트래커는 Year 2 | Phase 1은 이메일로 충분, 트래커는 사용자 200K+ 시점 |
| 2026-05-18 | SLA Critical 4시간 / High 12시간 | 산업 표준 (Pro급 SaaS는 1-2시간이나 1인 운영 현실) |
| 2026-05-18 | PII는 Zendesk에 별도 격리 (티켓 메타데이터 X) | account_lifecycle_spec PII 정책 일관 |
| 2026-05-18 | 야간/주말 자동 응답 + 긴급 결제 별도 채널 | 1인 운영 한계 + 결제 사고 SLA 유지 |

---

## 12. 관련 문서

- [account_lifecycle_spec.md](../user/account_lifecycle_spec.md) — PII / AuditLog
- [account_recovery_spec.md](../user/account_recovery_spec.md) — 신분증 복구 운영 흐름
- [seo_landing_spec.md](../growth/seo_landing_spec.md) — `/support/faq` 위치
- [crashlytics_spec.md](../architecture/crashlytics_spec.md) — recent_errors 자동 첨부
- [event_tracking_spec.md](../analytics/event_tracking_spec.md) — 만족도 이벤트 (`support_csat_submitted`)
