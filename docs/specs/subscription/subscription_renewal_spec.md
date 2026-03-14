# 수강권 갱신 제안 시스템 (SubscriptionRenewalService)

> v1.0 | 2026-03-15 | Refs #169

## 1. 개요

### 1.1 문제 정의

정규 레슨 수강권이 소진/만료되면, 선생님이 수동으로 대시보드에서 수강권을 발급해야만 재등록이 진행됩니다. 학생 측에서는 자발적으로 "레슨 요청"을 보내야 하지만, 이 경로를 모를 수 있습니다.

### 1.2 해결 방식

**"시스템 자동 감지 + 선생님 원탭 발송 + 학생 원탭 수락"** 하이브리드 모델.

넷플릭스가 매달 "곧 갱신됩니다" 알림을 보내듯, 시스템이 수강권 소진을 자동 감지하고 선생님에게 알려주면, 선생님이 원탭으로 갱신 제안을 발송합니다.

### 1.3 설계 원칙

- **기존 인프라 재사용**: SubscriptionProposal + AutoProposalService 패턴의 90% 활용
- **최소 클릭**: 선생님 1탭 + 학생 1탭
- **이전 수강 조건 자동 채움**: 횟수, 가격, 시간대를 이전 수강권에서 복사
- **알림 피로 방지**: 최대 3회 제한 + 스누즈 + 24h 쿨다운

---

## 2. 갱신 트리거 (시스템 자동 감지)

| 단계 | 조건 | 선생님 대시보드 | 학생 알림 |
|---|---|---|---|
| **사전 안내** | 잔여 3회 | 갱신 준비 배지 (info) | 없음 (부담 방지) |
| **갱신 권유** | 잔여 ≤2회 또는 D-7 | 갱신 카드 (warning) + 원탭 발송 | "수강권이 2회 남았어요" |
| **긴급 갱신** | 잔여 1회 또는 D-3 | 긴급 카드 (error) | "마지막 1회입니다" |
| **만료 후** | 잔여 0회 또는 만료 | 만료 알림 + 갱신 버튼 | "수강권이 만료되었습니다" |

### 트리거 조건 코드 매핑

```dart
// SubscriptionExpiryMonitor에서 갱신 서비스 호출
if (sub.remainingLessons != null && sub.remainingLessons! <= 2) {
  renewalService.triggerOnSubscriptionLow(sub);
}
if (sub.daysUntilExpiration != null && sub.daysUntilExpiration! <= 7) {
  renewalService.triggerOnSubscriptionLow(sub);
}
```

---

## 3. 선생님 UX

### 3.1 대시보드 갱신 카드

```
┌─────────────────────────────────────┐
│ 🔄 갱신 제안 필요                     │
├─────────────────────────────────────┤
│  김서연 · 바이올린 8회권              │
│  잔여 2/8회 · D-15                  │
│  이전: 3개월 연속 수강               │
│                                     │
│  [같은 수강권 제안]    [상세 보기]     │
│                                     │
│  ☑ 앞으로 자동 발송                  │
└─────────────────────────────────────┘
```

### 3.2 원탭 갱신 플로우

"같은 수강권 제안" 버튼 1번 탭으로:
1. 이전 수강권과 동일한 templateId 자동 선택
2. SubscriptionProposal 생성 (`isRenewal: true`, `previousSubscriptionId` 연결)
3. 학생에게 인앱 알림 발송
4. ProposalReminderService로 24h/48h/72h 리마인더 자동 예약

### 3.3 자동 발송 옵션

ProposalSettings의 `autoRenewalEnabled` 토글로 활성화. 활성 시 선생님 탭 없이 시스템이 자동으로 갱신 제안 발송.

---

## 4. 학생 UX

### 4.1 갱신 제안 상세 화면

```
┌─────────────────────────────────────┐
│ ← 수강권 갱신 제안                    │
├─────────────────────────────────────┤
│  🔄 김선생님이 수강권 갱신을 제안했어요 │
│                                     │
│  바이올린 8회권                       │
│  380,000원 · 60분 · 2개월            │
│  💡 지난번과 동일한 수강권입니다       │
│                                     │
│  📊 수강 이력                        │
│  수강 기간: 2025.12 ~ 2026.03        │
│  총 수강: 3개월 · 24회 완료           │
│  출석률: 100%                        │
│                                     │
│  [수강권 선택하기]                    │
│  [다른 수강권 보기]                   │
│  [나중에 할게요]                      │
└─────────────────────────────────────┘
```

### 4.2 갱신 대시보드 배너

SubscriptionRenewalBanner에서 갱신 제안 도착 시 갱신 상세 화면으로 연결.

---

## 5. 데이터 모델 변경

### 5.1 SubscriptionProposal 확장

```dart
@HiveField(24)
final bool isRenewal;  // 갱신 제안 여부 (기본값: false)

@HiveField(25)
final String? previousSubscriptionId;  // 이전 수강권 ID

@HiveField(26)
final RenewalInitiator? renewalInitiator;  // system | teacher
```

### 5.2 ProposalSettings 확장

```dart
@HiveField(9)
final bool autoRenewalEnabled;  // 자동 갱신 제안 on/off (기본: false)
```

### 5.3 RenewalInitiator enum

```dart
enum RenewalInitiator {
  system,   // 시스템 자동 발송
  teacher,  // 선생님 수동 발송
}
```

---

## 6. 알림 시스템

### 6.1 갱신 알림 시퀀스

| 시점 | 알림 타입 | 수신자 | 내용 |
|---|---|---|---|
| 잔여 ≤2회 감지 | subscriptionExpiringSoon | 학생 | "수강권이 2회 남았어요" |
| 갱신 제안 발송 | proposalReceived (isRenewal) | 학생 | "선생님이 갱신을 제안했어요" |
| 24h 후 미응답 | proposalReminder24h | 학생 | "갱신 제안을 확인해주세요" |
| 학생 수락 | proposalAccepted | 선생님 | "학생이 갱신을 수락했어요" |
| 입금 확인 | paymentConfirmed | 학생 | "갱신이 완료되었습니다" |

### 6.2 피로도 관리

- 동일 수강권에 대해 최대 3회 갱신 알림
- 학생이 "나중에" 선택 시 24h 쿨다운
- 갱신 제안 활성 시 추가 알림 차단

---

## 7. 기존 인프라 재사용 매핑

| 기존 인프라 | 재사용 방식 |
|---|---|
| AutoProposalService | 패턴 복제 → triggerOnSubscriptionLow() |
| SubscriptionExpiryMonitor | 직접 확장 → 갱신 서비스 호출 추가 |
| ProposalSettings | 필드 추가 (autoRenewalEnabled) |
| SubscriptionProposal | 필드 추가 (isRenewal, previousSubscriptionId) |
| ProposalReminderService | 그대로 재사용 |
| ProposalDetailScreen | 갱신 제안도 동일 화면 사용 |
| SubscriptionRenewalBanner | 갱신 제안 연결 개선 |

---

## 8. 파일 위치

| 파일 | 역할 |
|---|---|
| `domain/services/subscription_renewal_service.dart` | 핵심 서비스 |
| `domain/entities/subscription_proposal.dart` | 엔티티 확장 |
| `domain/entities/proposal_settings.dart` | 설정 확장 |
| `presentation/widgets/renewal_suggestion_card.dart` | 선생님 대시보드 카드 |
| `presentation/screens/renewal_detail_screen.dart` | 학생 갱신 상세 (Phase 3) |
