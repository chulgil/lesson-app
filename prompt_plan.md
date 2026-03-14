# 수강권 자동 갱신 제안 시스템 (SubscriptionRenewalService)

> 확정일: 2026-03-15

## 배경

재등록 플로우 UX 검증 결과, 체험 후 자동 제안(AutoProposalService)은 구현되어 있으나 **정규 레슨 수강권 소진/만료 시 자동 갱신 제안이 미구현**(GAP-2). 별도 SubscriptionRenewal 엔티티 대신 기존 SubscriptionProposal을 확장하여 중복 최소화.

## 핵심 UX 모델

**"선생님 원탭 + 학생 원탭" 하이브리드**
```
시스템 자동 감지 → 선생님 대시보드 카드 → 원탭 발송 → 학생 원탭 수락 → 입금 → 수강권 갱신
```

## Phase 1: 데이터 모델 + 핵심 서비스 + 스펙 문서

| # | 작업 | 파일 | 상태 |
|---|------|------|:----:|
| 1-1 | 스펙 문서 작성 | docs/specs/subscription/subscription_renewal_spec.md | todo |
| 1-2 | SubscriptionProposal 확장 (isRenewal, previousSubscriptionId) | domain/entities/subscription_proposal.dart | todo |
| 1-3 | ProposalSettings 확장 (autoRenewalEnabled) | domain/entities/proposal_settings.dart | todo |
| 1-4 | SubscriptionRenewalService 생성 | domain/services/subscription_renewal_service.dart | todo |
| 1-5 | SubscriptionExpiryMonitor 연결 | domain/services/subscription_expiry_monitor.dart | todo |
| 1-6 | Mock 데이터 추가 | mock_subscription_proposal_repository.dart | todo |

## Phase 2: 선생님 UX

| # | 작업 | 파일 | 상태 |
|---|------|------|:----:|
| 2-1 | 갱신 제안 카드 위젯 (원탭 발송) | widgets/renewal_suggestion_card.dart | todo |
| 2-2 | 대시보드 통합 | 선생님 대시보드 | todo |
| 2-3 | ExpiringSubscriptionsScreen 개선 | expiring_subscriptions_screen.dart | todo |

## Phase 3: 학생 UX

| # | 작업 | 파일 | 상태 |
|---|------|------|:----:|
| 3-1 | 갱신 제안 상세 화면 | renewal_detail_screen.dart | todo |
| 3-2 | 수강 이력 위젯 | subscription_history_widget.dart | todo |
| 3-3 | SubscriptionRenewalBanner 개선 | subscription_renewal_banner.dart | todo |

## Phase 4: 자동화 + 완성도

| # | 작업 | 파일 | 상태 |
|---|------|------|:----:|
| 4-1 | 자동 갱신 제안 (autoRenewalEnabled 시) | renewal_service.dart | todo |
| 4-2 | 레슨 완료 시 갱신 체크 연결 | lesson_detail_screen.dart | todo |

---

## 이전 계획

### 선생님/학생 UX 종합 점검 8차 (2026-03-11) - 완료
