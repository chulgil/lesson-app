# Student Billing Research — 학생 측 IAP 도입 검토 자료

> 작성일: 2026-06-02
> 상태: **research / draft** (active SSOT 아님 — product 결정 자료)
> 관련: [paywall_spec.md](./paywall_spec.md), [payment_architecture.md](./payment_architecture.md) §3
> 작성 계기: 이슈 #415 audit 에서 paywall_spec §7 의 학생 화면 처리 공백 발견 → 학생 결제 모델 의사결정 자료 필요

---

## 0. 범위와 경계

본 문서는 **product 결정을 내리지 않는다.** Lessonaza 가 학생 user 에게 IAP 를 직접 부과할지 여부의 결정을 위한 **시장조사 보고서**다. 결정 이후 별도 spec (`student_paywall_spec.md` 등) 으로 분리 작성한다.

| 본 문서가 답하는 것 | 본 문서가 답하지 않는 것 |
|---------------------|---------------------------|
| 경쟁사가 학생에게 어떤 IAP 를 팔고 있는가 | Lessonaza 가 학생 IAP 를 도입해야 하는가 |
| 한국 시장이 학생 결제에 어떤 패턴을 보이는가 | 어떤 가격대를 택할지 |
| Lessonaza 에 후보가 될 만한 기능 카테고리 5–8개 | 어느 후보를 다음 분기에 구현할지 |

---

## 1. 배경

이슈 #415 (IAP 프론트엔드) 구현 후 audit 에서 다음 공백 발견:

- `paywall_spec.md` §7 의 Pro 전용 기능 (녹음 비교, 통계 리포트, 학원 다중 강사) 은 **선생님 관점** 으로 기술됨
- 코드에서는 같은 기능들이 학생 화면 (`practice_summary_section.dart`, `section_detail_screen.dart`) 에서도 진입 가능
- 그러나 학생이 결제하는 모델이 없으므로 "선생님 plan 으로 cascade", "학생 본인 결제", "학생은 항상 무료" 중 어느 것이 의도된 정책인지 spec 에 명시되지 않음
- `payment_architecture.md` §1: *"흐름 B (앱관리자 → 사용자) 는 아직 구현 대상이 아니다… 사용자 = 선생님/학생/학부모/학원 → 별도 스펙"*

→ 학생 결제 모델은 향후 정의 대상이며, 정의 전 단계로 시장 자료가 필요하다.

---

## 2. 현 상태

| 항목 | 상태 |
|------|------|
| 학생의 IAP 결제 가능 여부 | **불가** — backend 의 `BillingTier` enum 은 user 단위지만 IAP 진입점 자체가 선생님 plan 화면에만 노출 |
| 학생 화면의 Pro 기능 (녹음비교/통계) | **무료 접근** — #415 PR 의 Phase A 가드는 선생님 dashboard 만 적용 |
| 학부모 결제 가능 여부 | **불가** — `parent_dashboard_spec.md` 는 자녀 일정 / 입금 확인 / 출결만, 결제 흐름 없음 |
| paywall_spec.md 현 결정 | **2026-06-02 동기화**: 학생 화면 가드 제외를 명시 (본 보고서 작성과 동반 갱신) |

---

## 3. 글로벌 경쟁사 분석

학생/학부모에게 직접 IAP 를 부과하는 음악 학습 앱과, 선생님만 결제하는 SaaS 의 대비.

| 앱 | 결제 주체 | 학생에게 잠긴 기능 | 가격 (USD) | 비고 |
|---|---|---|---|---|
| **Yousician** | 학생/학부모 직접 | 전곡 라이브러리, 인기 아티스트, 멀티 악기, 고급 레슨 | ~$19.99/mo Premium; Premium+/Family; 7일 체험 | 학생 전용 plan 없음 |
| **Simply Piano (JoyTunes)** | 학생/학부모 직접 | 전 커리큘럼 (1,200+ 곡, 이론, 그룹 세션) | $12.50/mo 단일 tier; Family $199.99/yr (5 profile, iOS/web only) | Korean App Store 자동갱신 컴플레인 다수 |
| **Tonebase** | 학생 직접 (adult learner) | 마스터클래스 풀 라이브러리, 라이브 워크숍, PDF; Premium+ 는 코칭 | $59.95/mo, $359/yr, $895 lifetime; .edu 30% 할인 | adult 타겟 |
| **Trala** | 학생 직접 | 커리큘럼 챕터, 실시간 pitch/rhythm feedback, 악보 라이브러리 | $9.99/mo or $119.99/yr; private Zoom $44.99/lesson | violin 전용 |
| **Tonara** | **선생님 결제, 학생에게 pass-through 옵션** | 풀 studio 기능; 학생은 연결된 선생님 필요 | 선생님 $9.50–$23.95/mo (학생 수 기준); 선생님이 학생에게 부과할지 선택 [partially unverified — 서비스 종료 보도] | 가장 Lessonaza 와 유사한 모델 |
| **My Music Staff** | **선생님 only** | 학생 IAP 없음; 학생 포털 무료 포함 | 선생님 $14.95/mo 단일; Stripe/PayPal passthrough만 | teacher CRM SaaS |

**패턴**: 소비자 학습 앱 (Yousician/Simply Piano/Tonebase/Trala) 은 학생에게 직접 부과. teacher CRM SaaS (MyMusicStaff, Tonara, Forte 류) 는 선생님에게만 부과하고 학생 기능은 잠그지 않음.

→ Lessonaza 의 현재 포지션은 **teacher CRM SaaS** 에 가깝다. 학생 IAP 를 추가하면 두 모델의 hybrid 가 된다.

---

## 4. 한국 시장 특수성

한국 K-12 / 성인 학습자는 **가치 명확하면 직접 IAP 구매 의향 강함**:

- **야나두**: 평생수강 ₩1,250,000 lifetime + 클래스 옵션 ₩9,900/mo
- **말해보카**: 연간권 ₩98,000 → ₩119,000 인상 (2025-09) — 신규 구독자 대상
- **산타토익**: freemium + 3-tier 유료 패스, 점수 향상 시 환급 (성과 연동 hook)
- **피아노스쿨** (한국 자율학습 피아노 앱): ₩40,000/mo, ₩179,000/6mo, ₩239,000/yr — 첫 달 프로모 ₩4,900

**문화 변수**:
- **학부모 결제 (학부모-pays-for-child) 가 K-12 음악교육 지출의 다수**. Apple/Google Family Sharing 사용 활발 (flowkey 가 한국 App Store 에서 4인 가족 플랜 마케팅).
- **자동갱신 컴플레인이 부정 리뷰 1위 패턴** (Simply Piano ₩105,000 의도치 않은 결제 사례 다수). 체험/취소 UX 보수적 설계 필수.

→ Lessonaza 가 학생 IAP 를 도입한다면 한국 시장은 **학생 본인보다 학부모 결제 흐름** 이 우세할 가능성. 한 번 살펴볼 만한 케이스: 자녀 등록 → 학부모가 자녀 계정의 구독을 결제.

---

## 5. Lessonaza 학생 IAP 후보

paywall_spec §7 의 기존 Pro/Studio 라인업과 충돌하지 않는 새 SKU 후보. 각 후보는 선생님 Pro 가 이미 커버하는지를 우선 검토.

| 후보 | 가격 tier (₩) | 진입 위치 | 선생님 Pro 와 중복 위험 | 구현 effort |
|------|---------------|-----------|--------------------------|-------------|
| **악보/곡 라이브러리** | 4,900–9,900/mo | 연습 탭 곡 선택 화면 | LOW — 선생님 Pro 는 studio mgmt, 컨텐츠 아님 | L (라이선스 협상 필요) |
| **프리미엄 메트로놈** (고급 패턴, 광고 제거, custom subdivision) | 2,900/mo or 19,000 lifetime | 메트로놈 화면 | LOW — 선생님 Pro 가 메트로놈 컨텐츠 안 제공 | S (자체 플러그인 이미 보유) |
| **AI pitch/timing feedback (학생측)** | 7,900/mo | 연습 후 결과 화면 | **HIGH** — #415 가 AI feedback 을 선생님 Pro 에 게이트 → 이중 paywall 충돌 | M |
| **녹음 클라우드 백업 + 멀티 디바이스 동기화** | 3,900/mo | 녹음 리스트 / 설정 | MEDIUM — 선생님 Pro 가 공유 녹음 제공 시 중복 | M |
| **게이미피케이션 Pro** (스트릭, 뱃지, 리더보드) | 2,900/mo | 홈 / 프로필 | LOW | S |
| **가족 공유** (형제 단일 plan) | +2,000/seat | 결제 화면 | LOW — 새 dimension | M |
| **시험 준비 모듈** (콩쿠르/실기/음대 입시) | 14,900/mo | 별도 탭 | LOW — net-new content | L (커리큘럼 구축) |
| **프리미엄 튜너** (저잡음 허용, 고급 temperament) | one-time 9,900 | 튜너 화면 | LOW | S |

---

## 6. 권고

### Top 3 — 백로그 가치 있음

1. **프리미엄 메트로놈** (one-time ₩19,000 또는 ₩2,900/mo)
   - 이미 in-house 커스텀 플러그인 (`MetronomePlugin`) 보유 → 라이선스 비용 0
   - 선생님 Pro 와 중복 0
   - 기존 사용량이 매일 발생하는 기능이라 즉시 수익화 가능
   - 구현 effort S → 가장 빠른 1차 검증 SKU

2. **악보/곡 라이브러리** (₩4,900–9,900/mo)
   - 한국 시장 가격 검증됨 (피아노스쿨 ₩40k/mo benchmark 와 비교해 안전한 가격대)
   - 학생이 직접 선택하는 컨텐츠 (선생님이 배정하는 것 아님) → 학생 결제 동기 명확
   - 다만 라이선스 협상 effort L → 1차 SKU 아닌 2차

3. **시험 준비 모듈** (₩14,900/mo)
   - 한국 학부모의 willingness-to-pay 가 가장 높은 영역 (산타토익 환급반 모델 참고)
   - 음대 입시/콩쿠르 = 명확한 결제 segment
   - effort L 이지만 단가 높아 ROI 좋음

### Bottom — 안 하는 게 나음

- **AI pitch/timing feedback 학생 IAP**: 이슈 #415 가 AI feedback 을 선생님 Pro 에 게이트 → 학생용 별도 IAP 만들면 **이중 paywall 혼란**. 선생님 Pro only 유지가 옳음.
- **게이미피케이션 Pro**: 글로벌 선례 (Yousician/Trala) 가 게이미피케이션을 메인 구독에 번들, 별도 IAP 로 팔지 않음. 한국 학습 앱 시장에서도 스트릭/뱃지 단독 판매는 전환율 낮음.

---

## 7. 후속 product 결정 질문

본 보고서로 답할 수 없는 product 의사결정. 도입 결정 시 다음을 먼저 해소해야 함:

1. **결제 주체**: 학생 본인 vs 학부모 vs 둘 다 — Apple Family Sharing 활용 여부
2. **연령 정책**: 14세 미만은 학부모 결제 강제? (개인정보보호법, 자녀 보호 정책)
3. **기존 선생님 Pro 와의 가시성**: 학생이 "내 선생님이 Pro 면 나도 자동 이 기능 사용" 흐름을 기대할지 → 그 경우 SKU 분리는 학생 반발
4. **환불 / 자동갱신 UX**: 한국 학부모 자동결제 컴플레인 패턴 대비 보수적 설계 (체험 3일, 갱신 안내 푸시)
5. **학원 (Studio) 학생의 자동 부여**: Studio 학원 소속 학생은 학원의 SKU 로 자동 활성화? 분리?
6. **plan 명칭 충돌**: 학생 "Pro" vs 선생님 "Pro" 동일 이름 사용 시 혼란 — `Student Pro` 같은 별도 라벨 필요

---

## 8. 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-06-02 | 학생 결제 모델은 **현재 미도입**, 시장조사 자료로 향후 검토 | #415 audit 의 paywall_spec §7 공백 발견 후 product 가 "현재 학생 결제 기능 고려 안 함, 시장조사만 요청" 결정 |
| 2026-06-02 | paywall_spec.md 에 학생 화면 가드 제외를 명시 (현 상태 lock) | spec 공백을 spec 으로 채워 다음 audit 에서 false positive 방지 |

---

## 9. 출처

### 글로벌 경쟁사

- Yousician: [pricing overview](https://www.guitarchalk.com/yousician-cost/), [Membership Plans](https://account.yousician.com/plans)
- Simply Piano: [2026 pricing breakdown](https://www.alibaba.com/product-insights/how-much-is-simply-piano-in-2026-full-pricing-breakdown.html), [help center](https://piano-help.hellosimply.com/en/articles/2728030-subscribe-to-simply-piano)
- Tonebase: [pricing page](https://checkout.tonebase.co/pricing), [review with pricing](https://mordents.com/tonebase-review/)
- Trala: [App Store](https://apps.apple.com/us/app/trala-learn-violin/id1143205265), [Google Play](https://play.google.com/store/apps/details?id=com.trala.learn.violin&hl=en_US)
- Tonara: [pricing](https://www.tonara.com/pricing/), [student cost helpdesk](https://www.tonara.com/helpcenter/knowledge-base/students-pay-tonara-studio/), [Musically: 360 model](https://musically.com/2018/07/03/tonara-360-takes-a-new-spin-on-music-education-subscriptions/)
- My Music Staff: [pricing](https://www.mymusicstaff.com/pricing/), [student portal](https://www.mymusicstaff.com/student-portal/)

### 한국 시장

- 야나두: [LG U+ 매거진 — 평생수강](https://www.lguplus.com/pogg/magazine/%ED%8F%89%EC%83%9D-%EC%88%98%EA%B0%95-%EC%95%BC%EB%82%98%EB%91%90-%EA%B0%80%EA%B2%A9%EC%9D%80-%EC%98%81%EC%96%B4%ED%9A%8C%ED%99%94%EC%96%B4%ED%94%8C-%EA%B3%A0%EB%AF%BC-%ED%95%B4%EA%B2%B0%ED%95%98%EA%B8%B0), [클래스 월 구독권](https://www.lguplus.com/pogg/product/%EC%95%BC%EB%82%98%EB%91%90-%ED%81%B4%EB%9E%98%EC%8A%A4-%EC%9B%94-%EA%B5%AC%EB%8F%85%EA%B6%8C)
- 말해보카: [나무위키 가격 인상 이력](https://namu.wiki/w/%EB%A7%90%ED%95%B4%EB%B3%B4%EC%B9%B4)
- 피아노스쿨: [공식](https://www.pianoschool.kr/)
- Simply Piano 한국: [Korean App Store (학부모 결제 사례)](https://apps.apple.com/kr/app/simply-piano-%EB%B9%A0%EB%A5%B4%EA%B2%8C-%ED%94%BC%EC%95%84%EB%85%B8%EB%A5%BC-%EB%B0%B0%EC%9A%B0%EC%84%B8%EC%9A%94/id1019442026)
- flowkey 한국: [App Store (가족 공유 마케팅)](https://apps.apple.com/kr/app/flowkey-%ED%94%8C%EB%A1%9C%EC%9A%B0%ED%82%A4-%ED%94%BC%EC%95%84%EB%85%B8-%EB%B0%B0%EC%9A%B0%EA%B8%B0/id1020357408)
- 산타토익: [비즈니스 모델 분석 (brunch)](https://brunch.co.kr/@047f36f4a620451/28)

---

## 10. 관련 문서

- [paywall_spec.md](./paywall_spec.md) — 선생님 측 IAP SSOT (본 보고서가 채워 넣은 §7 학생 처리 공백)
- [payment_architecture.md](./payment_architecture.md) §3 — 흐름 B (앱관리자 → 사용자) 미래 정책 자리
- [subscription_master.md](./subscription_master.md) — 수강권 도메인 (흐름 A, 흐름 B 와 분리)
- [parent_dashboard_spec.md](../user/parent_dashboard_spec.md) — 학부모 화면 (현재 결제 흐름 없음, 향후 학부모 IAP 의 진입 후보)
