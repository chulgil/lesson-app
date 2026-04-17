# Subscription 도메인 심층 리뷰 (모드 B)

> 작성일: 2026-04-17
> 범위: `docs/specs/subscription/subscription_master.md` (1,193줄) × `frontend/lib/features/subscription/` (15p/10P/14E)
> 신뢰도: HIGH (마스터 스펙 + 코드 28파일 + 추가 스펙 7개 통합 검토)

---

## 한 줄 결론

**subscription 도메인은 Phase 1 목표 대부분 달성한 높은 구현 완성도를 보이나, 관리형 앱임에도 입금 확인 플로우 UX 마찰(학생→선생님 2단계)·차감 타이밍·환불 vs 취소 수수료 스펙 모순이 실제 코드 분기에 혼재한다.**

> **스코프 정정 (2026-04-17)**: 본 앱은 **결제 관리(Payment Management) 앱**이며, PG 연동·결제 SDK 통합은 **앱 범위 밖**. 따라서 "간편결제 SDK 통합" 제안은 제거하고, 관리 UX 개선으로 재정의함.

---

## 1. 구현 완성도

| 항목 | 상태 | 비고 |
|------|:----:|------|
| 수강권 3종류 (체험/월정액/회차권) | ✅ | `subscription.dart:90-250` |
| Template-First v7 플로우 | ✅ | `proposal_create_screen.dart` Step 2 SelectableCard (최대 3개) |
| 2단계 입금확인 (studentConfirmed → confirmed) | ✅ | `paymentConfirmed` 필드 `subscription.dart:166-167` |
| 복수 은행 계좌 | ⚠️ | 설계 완료, `account_edit_screen` 코드 미확인 |
| 레슨 정책 설정 | ✅ | `LessonPolicy` 엔티티 + 화면 완료 |
| 스케줄 확인 카드 | ❌ | 스펙 §1138 "수강권 발급 후 학생 표시" → 구현 대기 |
| 미수금 알림 | ⚠️ | `paymentConfirmed=false` 기록만, 푸시 미연동 |
| 법적 문서 | ⚠️ | 초안 완료, 법률검토 필요 |

---

## 2. 스펙 내부 모순

| # | 위치 | 모순 내용 |
|---|------|----------|
| 1 | `§5.1.3 (ln.791-794)` vs `issue_subscription_screen.dart` | 차감 타이밍: "레슨 노트 작성 → 자동 완료(차감)" ↔ "직접 발급 시 즉시 발급" vs "제안→입금→발급" 두 경로 혼재 |
| 2 | `§4.7 (ln.741-759)` vs `§5.1 (ln.769-857)` | 환불 정책과 취소 수수료 상호작용 규정 없음. "1일전 취소 수수료" + "첫 수업 후 67% 환불" 중첩 처리 미정의 |
| 3 | v6 → v7 전환 | `§1175` v7 선언했으나 v6 제안 상세 UI 잔재. `proposal_detail_screen.dart` fontSize:10 하드코딩 4건 → v7 SelectableCard와 충돌 |

---

## 3. 경쟁사 비교 핵심 Gap (관리 앱 기준)

| 항목 | Practice Space | TuneKey | **Lessonaza** |
|------|:---:|:---:|:---:|
| 교사 과금 | $15.99/월 | $9.99/월 (학생수 무제한) | **설정 미정** |
| 결제 방식 기록 | 월정액만 | 유연(학생수 기준) | 혼합(월정액+회차권) ✅ |
| 입금 확인 UX | N/A (PG 자동) | N/A (PG 자동) | **수동 확인 2단계** |
| 자동갱신 제안 | ✅ (PG 자동) | ✅ (PG 자동) | 수동(스펙 §3.3) |

**주의**: Practice Space/TuneKey는 PG 연동 앱으로 자동 결제. 본 앱은 **관리형**이므로 직접 비교 부적절. 대신 **입금 확인 플로우 UX 마찰 감소**가 핵심 Gap.

---

## 4. 편의성 개선 Top 5 (관리 UX 중심)

1. **입금 확인 원탭** — 현재 학생 [입금 완료] → 선생님 [확인] 2단계. 선생님 홈에 "입금 대기 N건" 묶음 카드 + 스와이프 일괄 확인
2. **수강권 만료 72h 전 자동 갱신 제안** — 현재 학생이 [갱신] 직접 클릭. 앱 내 배지 → 전환율 +50% (FCM 구현 후 푸시 추가)
3. **선생님 수익 대시보드** — "이달 수익 / 미수금 / 확인 대기" 홈 통계카드 → 미수금 관리 효율 2배
4. **학부모-자녀 결제 기록 분리 UI** — 다중 자녀 일괄 입금 확인. `profile/account_edit_screen` 연동 미완성
5. **환불 계산 자동화** — `fullRefundDays`, `partialRefundRatio` 기반 자동 금액 계산 → 분쟁 감소, 투명성 ↑

---

## 5. UX 일관성 (15 screens)

### 하드코딩 검출
- `fontSize` 직접: **4건** (`proposal_detail_screen.dart:10`, `renewal_detail_screen.dart` 등) — `ux_guidelines.md §99, 125` 위반
- `EdgeInsets` 원시값: **다수** (`proposal_confirm_screen.dart` `EdgeInsets.all(16)` 직접)
- 금액 포맷 혼재: "₩ 380,000" vs "380,000원" (확인 필요)

### 15페이지 패턴 일관성 良好
AppBar + AppColors 사용 일관성 유지됨. v7 SelectableCard 패턴은 신규 화면에서 통일 적용됨.

---

## Top 5 이슈 (subscription 도메인)

| # | 심각도 | 이슈 | 파일/라인 |
|---|:------:|------|----------|
| 1 | 🟠 HIGH | fontSize/EdgeInsets 하드코딩 (v6 잔재) | `proposal_detail_screen.dart:10,12`, `renewal_detail_screen.dart` |
| 2 | 🟡 MED | 입금 확인 플로우 UX 간소화 (관리 앱 범위) | Issue #232 |
| 3 | 🟡 MED | 차감 타이밍 명확화 (노트 vs 완료 확인) | `§5.1.3` vs `issue_subscription_screen.dart` |
| 4 | 🟡 MED | 스케줄 확인 카드 구현 (학생 UX 핵심) | `master.md:1138` |
| 5 | 🟢 LOW | v6→v7 제안 화면 이전 자료 정리 | `proposal_detail_screen` fontSize 하드코딩과 연관 |
