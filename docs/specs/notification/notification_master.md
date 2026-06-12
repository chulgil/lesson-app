# 알림 시스템 Master Spec

> 구현 상태: ⚠️ 부분 구현 (95%) — FCM 인프라 구현, Firebase 설정 대기, 핵심 비즈니스 알림 4종 백엔드 발송 완료
> Last updated: 2026-06-12 (출시 준비도 감사 P1-1 — 알림 설정 화면 Phase 1.5 승격)
> 기존 스펙: [notification_system.md](notification_system.md), [kakao_alimtalk_spec.md](kakao_alimtalk_spec.md)
> 관련 이슈: #424

> **선생님 측 입금 미확인 푸시 3종 (2026-06-01 신규)**:
> - `payment.pending_d1` — D+1 첫 리마인드
> - `payment.pending_d3` — D+3 두번째 리마인드
> - `payment.pending_d7_final` — D+7 만료 직전 (선생님 액션 마지막 기회)
>
> 상세: [../subscription/payment_tracking_dashboard.md](../subscription/payment_tracking_dashboard.md). 학생 측 동등 알림톡은 [kakao_alimtalk_spec.md](kakao_alimtalk_spec.md) 참조.

## 1. 개요

레슨 앱의 알림 시스템. 레슨, 연습, 입금 상태, 관계, 수강권 등 앱 전반의 이벤트를 사용자에게 전달한다.

도서관의 게시판(인앱)과 문자(푸시)를 함께 운영하는 것과 같다. 중요한 소식은 문자로 즉시 보내고, 모든 소식은 게시판에 기록한다.

### 설계 원칙

1. **개인화** - 사용자별 최적 타이밍과 빈도
2. **피로도 관리** - 과도한 알림 방지 (일일 최대 제한), 반응 없으면 빈도 감소
3. **채널 보호** - 푸시 옵트아웃 방지를 위한 품질 관리
4. **선택권 제공** - 선생님/학생 모두 세밀한 설정 가능
5. **DND 우회** - 긴급 알림(레슨 시작, 취소, 노쇼)은 방해금지 무시

### 기존 스펙 대비 변경점

| 항목 | 기존 스펙 | 구현 현실 |
|------|----------|----------|
| 알림 유형 | 7개 카테고리 | 11개 카테고리 (스케줄 변경, 수강권 제안, 변경 허용 추가) |
| 서비스 구조 | 단일 NotificationService | 역할별 분리 (Connection, Proposal, Scheduler) |
| 설정 엔티티 | 개념 수준 | 학생/선생님 분리 구현 완료 |
| 알림 템플릿 | 미정의 | NotificationTemplate 클래스 구현 |
| Repository | Mock only | Mock + Remote 구현 |

---

## 2. 핵심 기능

### 2.1 수신자 역할 매핑 (targetRole)

> **2026-05-05 추가**: 모든 알림 타입은 수신자 역할이 명확히 정의되어야 한다.
> Mock 데이터와 백엔드 모두 이 매핑을 따른다.

#### 설계 원칙

1. **취소/변경 알림**: 요청자 본인은 이미 알고 있으므로 **상대방에게만** 발송
2. **만료/수강권 알림**: 양쪽 모두 관리가 필요하므로 **양쪽** 발송
3. **시스템 자동 발송**: 미수금 리마인더, 재수강 리마인더는 시스템이 학생에게 자동 발송 후 선생님에게 "발송됨" 통지
4. **선생님은 액션 불필요**: 미수금/재수강 리마인더는 시스템 자동. 선생님은 발송 사실만 확인

#### 수신자 매핑표

| 수신자 | 알림 타입 |
|--------|----------|
| **선생님 전용** | `newStudentRegistered`, `trialBookingRequest`, `studentPracticeReport`, `reviewReceived`, `paymentReceived`, `proposalAccepted`, `rescheduleAllowanceUsed`, `rescheduleAllowanceDepleted`, `generalAnnouncement`, `paymentReminderSentNotice`, `renewalReminderSentNotice` |
| **학생 전용** | `practiceReminder`, `practiceAssigned`, `streakWarning`, `streakMilestone`, `weeklyGoalAchieved`, `recordingFeedbackReceived`, `proposalReceived`, `proposalReminder24h/48h/72h`, `proposalExpired`, `paymentRequested`, `paymentReminder`, `paymentConfirmed`, `lessonsRunningLow`, `teacherNoshow`, `compensationApplied`, `lessonNoteShared` |
| **상대방에게만** | `lessonCancelled`, `lessonRescheduled`, `scheduleChange*` — 요청자 본인은 이미 알고 있으므로 상대방에게만 |
| **양쪽** | `lessonBooked`, `lessonReminder`, `lessonStarting`, `lessonCompleted`, `noshowWarning`, `noshowConfirmed`, `cancellationDeadline`, `connectionRequest*`, `connectionEstablished`, `connectionDisconnected`, `makeupLesson*`, `subscriptionExpiring*` |

#### 시스템 자동 발송 알림 (선생님 액션 불필요)

| 알림 | 트리거 | 학생에게 | 선생님에게 |
|------|--------|---------|----------|
| `paymentReminder` | 입금 안내 후 N일 경과 | "수강료 입금을 확인해주세요" | `paymentReminderSentNotice`: "OOO님에게 입금 리마인더가 발송되었습니다" |
| `subscriptionExpiringSoon` | 수강권 D-7/D-3/D-1 | "수강권이 N일 후 만료됩니다" | 동일 알림 (양쪽) |
| 재수강 리마인더 (신규) | 수강권 만료 후 D+3/D+7 | "수강을 이어가시겠어요?" | `renewalReminderSentNotice`: "OOO님에게 재수강 안내가 발송되었습니다" |

코드 참조: `NotificationTypeExtension.targetRole` (`notification.dart`)

### 2.2 알림 유형 (NotificationType) - 전체 목록

#### 레슨 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `lessonBooked` | normal | X | O |
| `lessonReminder` | normal | X | O |
| `lessonCancelled` | high | **O** | O |
| `lessonRescheduled` | high | **O** | O |
| `lessonStarting` | **urgent** | **O** | O |
| `lessonCompleted` | low | X | **X** |
| `lessonNoteShared` | normal | X | O |

#### 연습 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `practiceReminder` | normal | X | O |
| `streakWarning` | normal | X | O |
| `streakMilestone` | low | X | O |
| `practiceAssigned` | normal | X | O |
| `weeklyGoalAchieved` | low | X | O |

#### 입금 상태 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `paymentRequested` | high | X | O |
| `paymentReminder` | high | X | O |
| `paymentReceived` | normal | X | O |
| `paymentConfirmed` | normal | X | O |
| `lessonsRunningLow` | normal | X | O |

#### 노쇼/취소 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `noshowWarning` | **urgent** | **O** | O |
| `noshowConfirmed` | **urgent** | **O** | O |
| `teacherNoshow` | normal | X | O |
| `compensationApplied` | normal | X | O |
| `cancellationDeadline` | high | X | O |

#### 관리 알림 (선생님용)

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `newStudentRegistered` | normal | X | O |
| `trialBookingRequest` | normal | X | O |
| `studentPracticeReport` | low | X | **X** |
| `reviewReceived` | normal | X | O |

#### 연결/초대 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `connectionRequestReceived` | high | X | O |
| `connectionRequestAccepted` | high | X | O |
| `connectionRequestRejected` | low | X | O |
| `connectionEstablished` | high | X | O |
| `connectionDisconnected` | low | X | O |

#### 보강 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `makeupLessonCreated` | normal | X | O |
| `makeupLessonExpiring` | high | X | O |
| `makeupLessonExpired` | low | X | O |

#### 스케줄 변경 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `scheduleChangeRequested` | high | X | O |
| `scheduleChangeApproved` | high | X | O |
| `scheduleChangeRejected` | normal | X | O |
| `scheduleChangeAlternative` | normal | X | O |

#### 스케줄 확인 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `scheduleConfirmationRequired` | high | X | O |

#### 수강권 제안 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `proposalReceived` | high | X | O |
| `proposalReminder24h` | normal | X | O |
| `proposalReminder48h` | normal | X | O |
| `proposalReminder72h` | high | X | O |
| `proposalAccepted` | normal | X | O |
| `proposalExpired` | normal | X | O |

#### 수강권 상태 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `lessonsRunningLow` | high | X | O |
| `subscriptionExpiringSoon` | high | X | O |
| `subscriptionExpired` | high | X | O |

수강권 알림은 서버의 수강권 원장을 단일 진실 공급원으로 삼는다. `subscriptionExpiringSoon`은 실제 `endDate` 기준 D-14/D-7/D-3/D-1/D-0 같은 만료 임계값에 들어온 경우에만 발행한다. 남은 회차가 적지만 만료일이 임계값에 들어오지 않은 경우에는 `lessonsRunningLow`를 발행하고, 제목/본문에 "N일 후 만료" 같은 날짜 기반 문구를 넣지 않는다.

서버는 `/subscriptions/{subscriptionId}` 딥링크에 필요한 payload를 함께 내려준다. 필수 필드는 `subscriptionId`, `studentId`, `teacherId`, `remainingLessons`, `totalLessons`, `endDate`, `daysUntilExpiration`, `reason`이다. `reason`은 `dateExpiring`, `lessonsLow`, `expired`, `depleted` 중 하나를 사용한다. 프론트는 서버가 내려준 제목/본문을 표시하되, mock과 테스트에서는 알림 타입과 payload가 실제 수강권 상태와 일치하는지 검증한다.

#### 변경 허용 알림

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `rescheduleAllowanceUsed` | normal | X | O |
| `rescheduleAllowanceDepleted` | normal | X | O |

#### 리인게이지먼트 알림 (2026-05-07 추가)

> 비활성 사용자 재참여를 위한 알림. 백엔드 `User.last_active_at` 필드 필요.

| 타입 | 우선순위 | 트리거 | 수신자 | 제목 예시 |
|------|---------|--------|--------|----------|
| `inactivityReminder7d` | normal | 마지막 활동 7일 경과 | 양쪽 | "이번 주 레슨 정리가 기다리고 있어요" |
| `inactivityReminder14d` | high | 마지막 활동 14일 경과 | 양쪽 | "놓치고 있는 연습이 있어요" |
| `winBackOffer30d` | high | 마지막 활동 30일 경과 | 양쪽 | "다시 시작해볼까요? 특별 혜택" |

#### 프로필 완성 리마인더 (2026-05-31 추가)

> 신규 가입 선생님의 프로필 완성을 유도하는 자동 알림. 백엔드 `ProfileReminderService.dispatch_reminders()` 구현 완료.

| 타입 | 우선순위 | DND 우회 | 푸시 |
|------|---------|---------|------|
| `profileReminder24h` | normal | X | O |
| `profileReminder3d` | normal | X | O |
| `profileReminder7d` | normal | X | O |

### 2.2 알림 유형 상세 (Claude 구현 가이드)

아래 표는 주요 알림 유형별 트리거 조건, 제목, 본문 예시, 아이콘, 딥링크를 정리한 것이다. Claude가 알림 생성 로직을 구현할 때 이 표를 참조한다.

| 유형 | 트리거 | 제목 | 본문 예시 | 아이콘 | 딥링크 |
|------|--------|------|----------|--------|--------|
| `lessonBooked` | 선생님 레슨 등록 시 | 새 레슨 등록 | "2026-04-01 레슨이 등록되었습니다" | event | `/lessons/{id}` |
| `lessonReminder` | 레슨 30분 전 | 레슨 알림 | "김민수 바이올린 14:00" | calendar | `/lessons/{id}` |
| `lessonStarting` | 레슨 시작 시점 | 레슨 시작 | "김민수 바이올린 레슨이 시작됩니다" | alarm | `/lessons/{id}` |
| `lessonCancelled` | 레슨 취소 시 | 레슨 취소 | "김민수 3/7 14:00 레슨이 취소되었습니다" | cancel | `/lessons/{id}` |
| `lessonCompleted` | 레슨 종료 시 | 레슨 완료 | "김민수 바이올린 레슨이 완료되었습니다" | check_circle | `/lessons/{id}` |
| `lessonNoteShared` | 선생님 레슨 노트 작성 시 | 레슨 노트 | "선생님이 레슨 노트를 공유했습니다" | note | `/lessons/{id}/note` |
| `lessonsRunningLow` | 수강권 잔여 횟수 ≤ 2 | 수강권 임박 | "김민수 수강권 1회 남음" | warning | `/subscriptions/{id}` |
| `paymentRequested` | 수강권 입금 안내 발송 | 입금 안내 | "김민수 수강권 입금 안내가 도착했습니다" | payment | `/subscriptions/{id}` |
| `paymentReminder` | 입금 예정/입금대기(후불) 지속 | 입금 안내 알림 | "김민수 수강권 입금 확인을 부탁드립니다" | payment | `/subscriptions/{id}` |
| `paymentReceived` | 학생/학부모 입금 완료 알림 | 입금 완료 알림 | "김민수님이 입금 완료를 알렸습니다" | payment | `/subscriptions/{id}` |
| `streakMilestone` | 연속 N일 달성 | 연습 축하 | "7일 연속 연습!" | celebration | `/practice/stats` |
| `streakWarning` | 연속 기록 위기 (당일 미연습) | 스트릭 경고 | "연속 연습 기록이 끊어질 수 있어요" | warning | `/practice` |
| `practiceReminder` | 설정된 연습 리마인더 시간 | 연습 알림 | "오늘의 연습 목표를 달성해보세요" | music_note | `/practice` |
| `practiceAssigned` | 선생님 과제 등록 시 | 과제 등록 | "선생님이 새 연습 과제를 등록했습니다" | task | `/practice/assignments` |
| `trialBookingRequest` | 학생 체험 요청 시 | 레슨 요청 | "새 체험 요청이 있습니다" | person_add | `/schedule/lesson-requests` |
| `noshowWarning` | 레슨 시작 10분 경과, 미도착 | 노쇼 경고 | "김민수 레슨에 출석하지 않았습니다" | warning | `/lessons/{id}` |
| `noshowConfirmed` | 노쇼 확정 시 | 노쇼 확정 | "김민수 레슨이 노쇼 처리되었습니다" | error | `/lessons/{id}` |
| `connectionRequestReceived` | 연결 요청 수신 시 | 연결 요청 | "김민수님이 연결을 요청했습니다" | person | `/invite/requests` |
| `connectionEstablished` | 연결 수락 시 | 연결 완료 | "김선생님과 연결되었습니다" | check | `/profile/connections` |
| `proposalReceived` | 수강권 제안 수신 시 | 수강권 제안 | "김선생님이 수강권을 제안했습니다" | ticket | `/subscriptions/{id}` |
| `proposalExpired` | 수강권 제안 72시간 경과 | 제안 만료 | "수강권 제안이 만료되었습니다" | timer_off | `/subscriptions` |
| `makeupLessonCreated` | 보강 레슨 생성 시 | 보강 레슨 | "보강 레슨이 등록되었습니다" | event | `/lessons/{id}` |
| `makeupLessonExpiring` | 보강 유효기간 D-3 | 보강 임박 | "보강 레슨 유효기간이 3일 남았습니다" | warning | `/lessons/{id}` |
| `subscriptionIssued` | 수강권 발급 시 | 수강권 발급 | "4회 수강권이 발급되었습니다" | ticket | `/subscriptions/{id}` |
| `scheduleConfirmationRequired` | 스케줄 카드 생성 시 | 일정 확인 요청 | "선생님이 레슨 일정을 제안했습니다" | schedule | `/schedule/confirmation-cards/{id}` |
| `scheduleChangeRequested` | 스케줄 변경 요청 시 | 스케줄 변경 | "김민수 3/10 레슨 변경 요청" | schedule | `/schedule/{id}` |
| `profileReminder24h` | 가입 후 24시간, 완성도 <50% | 프로필 완성 안내 | "프로필을 완성하면 학생에게 노출돼요!" | profile | `/profile` |
| `profileReminder3d` | 가입 후 3일, 프로필 사진 없음 | 사진 추가 안내 | "프로필 사진만 추가하면 검색에 노출됩니다" | camera | `/profile` |
| `profileReminder7d` | 가입 후 7일, 소개글 없음 | 소개글 작성 안내 | "웹 프로필 링크를 만들어 카톡에 공유해보세요" | edit | `/profile` |
| `reviewReceived` | 학생 리뷰 작성 시 | 리뷰 알림 | "김민수님이 리뷰를 남겼습니다" | star | `/profile/reviews` |

> **참고**: `{id}` 부분은 `AppNotification.data` 맵에서 해당 리소스 ID를 추출하여 동적으로 치환한다.

### 2.3 알림 우선순위 (NotificationPriority)

| 레벨 | 용도 | 아이콘 배경색 |
|------|------|-------------|
| `urgent` | 레슨 시작, 노쇼 | error (빨간) |
| `high` | 입금 상태, 취소, 연결 | secondary (오렌지) |
| `normal` | 리마인더 | primary (보라) |
| `low` | 성과, 보고서 | secondary (회색) |

### 2.4 알림 템플릿 (NotificationTemplate)

구현된 템플릿 (13개):
- 레슨: `lessonReminder`, `lessonStarting`
- 연습: `practiceReminder`, `streakWarning`, `streakMilestone`, `practiceAssigned`
- 연결: `connectionRequestReceived`, `connectionRequestAccepted`, `connectionEstablished`
- 보강: `makeupLessonCreated`, `makeupLessonExpiring`
- 스케줄: `scheduleChangeRequested`, `scheduleChangeApproved`, `scheduleChangeAlternative`

템플릿은 `{{placeholder}}` 패턴으로 동적 값 삽입 지원.

---

### 2.5 알림 배치/다이제스트 정책

> 시나리오: 월요일 학생 5명이 동시에 등록 → 15+ 알림이 10분 내 발생 → 스팸으로 인식.
> 목표: **선생님 피로도 관리**. 즉시성이 중요한 알림은 그대로, 정보성 알림은 묶거나 요약.

#### 2.5.1 우선순위별 처리

| Priority (2.3) | 일일 한도 적용 | 배치 묶음 | 다이제스트 |
|----------------|:-------------:|:---------:|:----------:|
| `urgent` (즉시 행동 필요) | ❌ 항상 즉시 | ❌ | ❌ |
| `high` (당일 응답) | ✅ | ❌ 즉시 발송 | ❌ |
| `normal` (정보 전달) | ✅ | ✅ 배치 가능 | ✅ 요약 가능 |
| `low` (참고) | ✅ | ✅ | ✅ |

`urgent` 예시: 입금 완료, 학생 노쇼, 결제 실패.
`normal` 예시: 새 학생 등록, 연습 리포트, 리뷰 수신.

#### 2.5.2 일일 한도 (maxDailyNotifications)

| 역할 | 기본값 | 적용 |
|------|--------|------|
| 학생 | 5 | 한도 초과 분은 다음 날 미발송 (소실) |
| 학부모 | 5 | 동일 |
| **선생님** | **15** | 한도 초과 분은 **다음 날 다이제스트로 묶어 발송** (1건 요약 알림) |

선생님 한도가 높은 이유: 학생 수가 많을수록 알림 양이 늘어남.

> 카테고리별 기본값(기본 ON/OFF 여부) → [push_notification_settings_spec.md §3.2 카테고리 기본값](push_notification_settings_spec.md) 참조.

#### 2.5.3 배치 윈도우 (batchWindowMinutes)

`normal` 우선순위 알림은 `batchWindowMinutes`(기본 10분) 내 발생한 같은 종류를 묶어 1건으로 발송:

```
시점     이벤트                          푸시 결과
─────────────────────────────────────────────────
10:00    학생 A 등록                    (대기)
10:03    학생 B 등록                    (대기)
10:07    학생 C 등록                    (대기)
10:10    배치 윈도우 마감 → 발송         "새 학생 3명 등록"
10:11    학생 D 등록                    (새 윈도우 시작)
```

배치 묶음 알림 본문 템플릿: `"{type} {count}건 — {firstItem} 외 {count-1}건"`

| 알림 종류 | 배치 메시지 예시 |
|-----------|-----------------|
| 새 학생 등록 | "새 학생 3명 등록 — 김민지 외 2명" |
| 연습 리포트 | "연습 리포트 5건 도착" |
| 레슨 신청 | "체험레슨 신청 2건" |

#### 2.5.4 주간 다이제스트 (weeklyDigestEnabled)

옵트인 옵션. 활성화 시:

| 항목 | 값 |
|------|-----|
| 발송 채널 | 이메일 (푸시 아님) |
| 발송 시점 | 매주 `weeklyDigestDay` 요일 09:00 (KST) |
| 포함 내용 | 지난 주 학생/연습/입금 요약 + 다음 주 레슨 일정 |
| 비활성 시 | 발송 안 함 (개별 알림만) |

본 스펙은 알림 정책만 정의. 이메일 발송 인프라/템플릿은 별도 스펙(`backend/email_digest_spec.md` 후속).

#### 2.5.5 한도 초과 시 동작

| 역할 | 초과 분 처리 |
|------|-------------|
| 학생/학부모 | 초과 분 미발송 (소실). 사용자 인식 부담 우선. |
| 선생님 | 초과 분 → 다음 날 08:30에 **요약 1건**으로 발송: "어제 알림 N건 (보지 못한 알림 {first} 외 N-1건)" — 탭하면 알림 목록 화면으로 이동 |

#### 2.5.6 DND와의 관계

`dndEnabled=true` 인 시간대(기본 22:00~08:00):
- `urgent` → 즉시 발송 (DND 우회)
- `high`/`normal`/`low` → DND 종료 시각까지 큐에 보관, 종료 시 배치 발송

DND + 배치 + 한도가 동시 적용되는 흐름:
```
야간 발생 알림 N건 (normal)
  ↓ DND 큐에 보관
다음날 08:00 DND 종료
  ↓ 배치 윈도우 적용 → 1~2건으로 묶음
  ↓ 한도(15)와 비교
  ↓ 즉시 발송 또는 다이제스트로 이월
```

#### 2.5.7 AppStrings 키

| 키 | 한국어 |
|----|--------|
| `notificationBatchedTitle` | {type} {count}건 |
| `notificationBatchedBody` | {firstItem} 외 {count}건 |
| `notificationDailyDigestTitle` | 어제 알림 {count}건 |
| `notificationDailyDigestBody` | {firstItem} 외 {count}건 — 탭하여 확인 |
| `notificationWeeklyDigestSubject` | 지난 주 레슨 요약 ({weekRange}) |
| `notificationSettingsBatchToggle` | 알림 묶음 발송 |
| `notificationSettingsWeeklyDigest` | 주간 이메일 요약 |

#### 2.5.8 의사결정 로그

| 일자 | 결정 | 근거 |
|------|------|------|
| 2026-05-18 | 선생님 일일 한도 5 → 15로 차등 | 학생 10명+ 선생님 알림 폭주 방지 + 학생/학부모는 5 유지 |
| 2026-05-18 | 배치 윈도우 10분 기본 | 즉시성과 묶음의 절충 (5분은 짧고 30분은 길다) |
| 2026-05-18 | 주간 다이제스트 = 이메일, 옵트인 | 푸시 다이제스트는 즉시성과 충돌. 이메일은 광범위 정보 전달에 적합. |
| 2026-05-18 | 학생 한도 초과 분 = 소실 / 선생님 = 다이제스트 이월 | 학생은 인지 부담, 선생님은 업무 누락 방지 |

---

## 3. 화면/UI 구조

### 3.1 알림 벨 아이콘 (NotificationBellIcon)

모든 화면 앱바에 배치되는 재사용 위젯.

```
AppBar 우측
┌──────┐
│ 🔔 3 │  <- 읽지 않은 알림 수 뱃지 (빨간색, 99+ 표시)
└──────┘
```

- 위치: 앱바 actions
- 뱃지: 읽지 않은 알림 수 (0이면 숨김, 99 초과 시 "99+")
- 탭: `/notifications` 라우트로 이동

### 3.2 알림 목록 화면 (NotificationListScreen)

```
/notifications
┌──────────────────────────────────┐
│  <- 알림                 [모두 읽음] │
├──────────────────────────────────┤
│  오늘                             │
│  ┌──────────────────────────────┐│
│  │ [🎫] 수강권 제안이 도착했어요!    ││
│  │     체험레슨 후 72시간 골든타임... ││
│  │     [제안 확인하기]       1시간 전 ●││
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │ [✅] 연결 완료                   ││
│  │     김선생님과 연결되었습니다!     ││
│  │     [선생님 보기]         5분 전 ●││
│  └──────────────────────────────┘│
│                                  │
│  어제                             │
│  ┌──────────────────────────────┐│
│  │ [🎯] 연습 시간이에요!            ││
│  │     오늘의 연습 목표를 달성해보세요 ││
│  │                         어제    ││
│  └──────────────────────────────┘│
│                                  │
│  월요일                           │
│  ┌──────────────────────────────┐│
│  │ [🔥] 연속 연습 달성!             ││
│  │     7일 연속 연습을 달성했어요!    ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘

● = 읽지 않은 알림 (파란 점)
```

#### 날짜 그룹핑 규칙

| 기간 | 표시 |
|------|------|
| 오늘 | "오늘" |
| 어제 | "어제" |
| 최근 7일 | 요일명 (월요일, 화요일...) |
| 그 이전 | "M월 D일" |

#### 시간 표시 규칙

| 경과 시간 | 표시 |
|----------|------|
| < 1분 | "방금" |
| < 60분 | "N분 전" |
| < 24시간 | "N시간 전" |
| < 7일 | "N일 전" |
| >= 7일 | "M/D" |

### 3.3 개별 알림 항목 (NotificationItem)

| 요소 | 설명 |
|------|------|
| 아이콘 | 알림 유형별 이모지, 우선순위별 배경색 |
| 제목 | 굵은 글씨 (미읽음 시), 일반 (읽음 시) |
| 본문 | 최대 2줄, 말줄임 처리 |
| 시간 | 우측 상단 |
| 액션 버튼 | `actionLabel` 있을 때만 표시 (primary 색상) |
| 미읽음 표시 | 우측 파란 점, 배경 하이라이트 |
| 탭 동작 | 읽음 처리 + `actionUrl`로 딥링크 이동 |

---

## 4. 데이터 모델

### AppNotification 엔티티

```
AppNotification
├── id: String                    // 고유 ID
├── userId: String                // 수신 사용자 ID
├── type: NotificationType        // 알림 유형 (enum, 40+ 종류)
├── priority: NotificationPriority // 우선순위 (urgent/high/normal/low)
├── title: String                 // 알림 제목
├── body: String                  // 알림 본문
├── data: Map<String, dynamic>?   // 추가 데이터 (proposalId 등)
├── createdAt: DateTime           // 생성 시각
├── scheduledAt: DateTime?        // 예약 발송 시각
├── sentAt: DateTime?             // 실제 발송 시각
├── readAt: DateTime?             // 읽은 시각
├── isPush: bool                  // 푸시 발송 여부 (기본 true)
├── isInApp: bool                 // 인앱 표시 여부 (기본 true)
├── actionUrl: String?            // 탭 시 이동할 딥링크 URL
└── actionLabel: String?          // 액션 버튼 텍스트
```

### StudentNotificationSettings

```
StudentNotificationSettings
├── lessonReminderEnabled: bool          // 레슨 리마인더 (기본 true)
├── lessonReminderTimes: List<Duration>  // 리마인더 시간 (기본 24시간 전)
├── practiceReminderEnabled: bool        // 연습 리마인더 (기본 true)
├── practiceReminderTime: TimeOfDay      // 연습 리마인더 시간 (기본 19:00)
├── streakWarningEnabled: bool           // 스트릭 경고 (기본 true)
├── streakWarningTime: TimeOfDay         // 스트릭 경고 시간 (기본 21:00)
├── paymentReminderEnabled: bool         // 입금 안내/입금대기(후불) 알림 (기본 true)
├── dndEnabled: bool                     // 방해금지 (기본 true)
├── dndStart: TimeOfDay                  // DND 시작 (기본 22:00)
├── dndEnd: TimeOfDay                    // DND 종료 (기본 08:00)
└── maxDailyNotifications: int           // 일일 최대 (기본 5)
```

### TeacherNotificationSettings

```
TeacherNotificationSettings
├── lessonReminderEnabled: bool          // 레슨 리마인더 (기본 true)
├── lessonReminderTimes: List<Duration>  // 리마인더 시간 (기본 24시간 전)
├── newStudentAlert: bool                // 새 학생 (기본 true)
├── trialBookingAlert: bool              // 체험레슨 요청 (기본 true)
├── paymentReceivedAlert: bool           // 입금 완료 알림 (기본 true)
├── studentPracticeReport: bool          // 학생 연습 현황 (기본 false)
├── reviewReceivedAlert: bool            // 리뷰 알림 (기본 true)
├── dndEnabled: bool                     // 방해금지 (기본 true)
├── dndStart: TimeOfDay                  // DND 시작 (기본 22:00)
├── dndEnd: TimeOfDay                    // DND 종료 (기본 08:00)
├── maxDailyNotifications: int           // 일일 최대 (기본 15, §2.5 참조)
├── batchEnabled: bool                   // 배치 묶음 발송 (기본 true, §2.5)
├── batchWindowMinutes: int              // 배치 윈도우 (기본 10분, §2.5)
├── weeklyDigestEnabled: bool            // 주간 다이제스트 이메일 (기본 false, §2.5)
└── weeklyDigestDay: int                 // 주간 다이제스트 발송 요일 (0=월, 기본 0)
```

### NotificationRepository 인터페이스

| 메서드 | 설명 |
|--------|------|
| `getNotifications()` | 현재 사용자 알림 목록 |
| `markAsRead(id)` | 단건 읽음 처리 |
| `markAllAsRead()` | 전체 읽음 처리 |
| `getUnreadCount()` | 미읽음 수 |

### Provider 구성

| Provider | 용도 |
|----------|------|
| `notificationApiRepositoryProvider` | Remote Repository (keepAlive, null if mock) |
| `notificationServiceProvider` | LocalNotificationService 인스턴스 |
| `practiceReminderSchedulerProvider` | 연습 리마인더 스케줄러 |
| `connectionNotificationServiceProvider` | 연결 알림 서비스 |
| `proposalNotificationServiceProvider` | 수강권 제안 알림 서비스 |
| `studentNotificationSettingsNotifierProvider` | 학생 알림 설정 관리 |
| `teacherNotificationSettingsNotifierProvider` | 선생님 알림 설정 관리 |
| `userNotificationsProvider` | 사용자 알림 목록 (Mock/Remote) |
| `unreadNotificationCountProvider` | 미읽음 수 (뱃지용) |
| `notificationActionsProvider` | 알림 액션 (markAsRead, markAllAsRead, delete) |
| `notificationSchedulerServiceProvider` | 알림 스케줄링 서비스 (keepAlive) |

### Provider 설계 (Claude 구현 가이드)

아래는 주요 Provider의 코드 수준 설계이다. 새 Provider 추가 시 이 패턴을 따른다.

```dart
// 알림 목록 조회 (화면 진입 시 자동 fetch)
@riverpod
Future<List<AppNotification>> notifications(Ref ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getNotifications();
}

// 미읽음 수 (뱃지용, 여러 화면에서 참조)
@riverpod
Future<int> unreadNotificationCount(Ref ref) async {
  final repo = ref.read(notificationRepositoryProvider);
  return repo.getUnreadCount();
}

// 알림 액션 (읽음 처리, 전체 읽음, 삭제)
@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  @override
  Future<List<AppNotification>> build() async {
    final repo = ref.read(notificationRepositoryProvider);
    return repo.getNotifications();
  }

  Future<void> markAsRead(String id) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(id);
    ref.invalidateSelf();
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead();
    ref.invalidateSelf();
    ref.invalidate(unreadNotificationCountProvider);
  }
}

// 알림 설정 관리 (학생용)
@Riverpod(keepAlive: true)
class StudentNotificationSettingsNotifier extends _$StudentNotificationSettingsNotifier {
  @override
  StudentNotificationSettings build() {
    return StudentNotificationSettings.defaults();
  }

  void updateLessonReminder({bool? enabled, List<Duration>? times}) { ... }
  void updatePracticeReminder({bool? enabled, TimeOfDay? time}) { ... }
  void updateDnd({bool? enabled, TimeOfDay? start, TimeOfDay? end}) { ... }
}
```

> **참고**: `markAsRead` 호출 시 반드시 `unreadNotificationCountProvider`도 invalidate하여 뱃지가 즉시 갱신되도록 한다.

### 백엔드 API (RemoteNotificationRepository)

| 메서드 | API 엔드포인트 |
|--------|---------------|
| 목록 조회 | `GET /notifications` (Paginated) |
| 읽음 처리 | `PATCH /notifications/{id}/read` |
| 전체 읽음 | `PATCH /notifications/read-all` |
| 미읽음 수 | `GET /notifications/unread-count` |

#### 읽음 상태 계약

> 2026-05-05 백엔드 계약 고정: 빨간 뱃지와 알림 행의 미읽음 표시는 모두 `notifications.read_at` 하나를 기준으로 한다.

- 알림센터 행의 미읽음 표시는 `readAt == null`일 때만 표시한다.
- 앱바 붉은 뱃지는 `GET /notifications/unread-count`의 `count > 0`일 때만 표시한다.
- `GET /notifications` 응답은 `id`, `user_id`, `type`, `priority`, `title`, `body`, `data`, `created_at`, `scheduled_at`, `sent_at`, `read_at`, `is_read`, `is_push`, `is_in_app`, `action_url`, `action_label`을 포함한다.
- `PATCH /notifications/{id}/read`는 현재 사용자 소유 알림만 처리한다. 이미 읽은 알림은 기존 `read_at`을 보존한다.
- `PATCH /notifications/read-all`은 현재 사용자 미읽음 알림만 일괄 갱신하며 다른 사용자 알림은 변경하지 않는다.

---

## 5. 구현 파일 위치

> `features/notifications/` 기준 상대 경로. 새 파일 추가 시 이 표를 업데이트한다.

| 레이어 | 파일 경로 | 설명 |
|--------|----------|------|
| **Entity** | `domain/entities/notification.dart` | AppNotification, NotificationType, NotificationPriority |
| **Entity** | `domain/entities/notification_settings.dart` | StudentNotificationSettings, TeacherNotificationSettings |
| **Entity** | `domain/entities/notification_template.dart` | NotificationTemplate (템플릿 패턴) |
| **Repository Interface** | `domain/repositories/notification_repository.dart` | NotificationRepository 인터페이스 |
| **Service** | `domain/services/connection_notification_service.dart` | 연결 알림 생성 |
| **Service** | `domain/services/proposal_notification_service.dart` | 수강권 제안 알림 생성 |
| **Service** | `domain/services/notification_scheduler_service.dart` | 알림 예약/취소 |
| **Remote Repository** | `data/repositories/remote_notification_repository.dart` | 백엔드 API 연동 (Mock 없음 — remote 전용) |
| **Provider** | `presentation/providers/notification_providers.dart` | 모든 알림 Provider |
| **Screen** | `presentation/screens/notification_list_screen.dart` | 알림 목록 화면 |
| **Widget** | `presentation/widgets/notification_bell_icon.dart` | 앱바 알림 벨 아이콘 |
| **Widget** | `presentation/widgets/notification_item.dart` | 개별 알림 항목 위젯 |
| **Widget** | `presentation/widgets/context_switch_toast.dart` | 컨텍스트(선생님/원장) 전환 완료 토스트 (3초 자동 해제) (코드 반영 2026-06-03) |
| **Navigation** | `presentation/navigation/notification_navigation_target.dart` | 알림 → 딥링크 타깃 해석(`resolveNotificationNavigationTarget`) (코드 반영 2026-06-03) |
| **Screen** | `presentation/screens/academy_announcements_screen.dart` | 학원 공지 목록 (academy 데이터 소비) (코드 반영 2026-06-03) |
| **Screen** | `presentation/screens/academy_announcement_detail_screen.dart` | 학원 공지 상세 (코드 반영 2026-06-03) |
| **Route** | `core/router/routes/notification_routes.dart` | 알림 관련 라우트 정의 |

### 알림 딥링크 viewerRole 전달 정책 (코드 반영 2026-06-03)

> 코드: `resolveNotificationNavigationTarget(notification, {viewerRole})` (`notification_navigation_target.dart`)

`actionUrl`이 비어 있지 않은 알림을 탭하면 해당 URL로 이동한다. 다음 경우에는 `extra`에 `{'viewerRole': ...}`를 함께 전달하여 도착 화면이 역할별로 분기하도록 한다.

- `actionUrl`이 `/subscriptions/` 또는 `/schedule/request/` 로 시작
- `type`이 `scheduleChange*`, `subscriptionExpiringSoon`, `subscriptionExpired`, `paymentReceived`, `paymentRequested`, `paymentReminder`, `paymentConfirmed` 중 하나

---

## 6. 구현 현황

### 완료

| 컴포넌트 | 파일 | 상태 |
|----------|------|:----:|
| AppNotification 엔티티 | `notifications/domain/entities/notification.dart` | 완료 |
| NotificationSettings 엔티티 | `notifications/domain/entities/notification_settings.dart` | 완료 |
| NotificationRepository | `notifications/domain/repositories/notification_repository.dart` | 완료 |
| RemoteNotificationRepository | `notifications/data/repositories/remote_notification_repository.dart` | 완료 |
| ConnectionNotificationService | `notifications/domain/services/connection_notification_service.dart` | 완료 |
| ProposalNotificationService | `notifications/domain/services/proposal_notification_service.dart` | 완료 |
| NotificationSchedulerService | `notifications/domain/services/notification_scheduler_service.dart` | 완료 |
| Notification Providers | `notifications/presentation/providers/notification_providers.dart` | 완료 |
| NotificationListScreen | `notifications/presentation/screens/notification_list_screen.dart` | 완료 |
| NotificationBellIcon | `notifications/presentation/widgets/notification_bell_icon.dart` | 완료 |
| NotificationItem | `notifications/presentation/widgets/notification_item.dart` | 완료 |

### 서비스별 역할

| 서비스 | 역할 |
|--------|------|
| `LocalNotificationService` | 인앱 알림 표시/관리 (core service) |
| `LocalNotificationService._onNotificationTapped` | 알림 탭 시 payload 파싱 → AppNotification stream emit |
| `ConnectionNotificationService` | 연결 요청/수락/완료 알림 생성 |
| `ProposalNotificationService` | 수강권 제안/수락/리마인더/만료 알림 생성 |
| `NotificationSchedulerService` | 미래 시점 알림 예약/취소 (인메모리 큐) |
| `PracticeReminderScheduler` | 연습 리마인더 스케줄링 |

### 백엔드 발송 구현 상태

| 알림 타입 | 트리거 위치 | 구현 상태 |
|-----------|-----------|----------|
| `lessonBooked` | `lesson_service.create()` | ✅ 구현 (2026-05-31) |
| `lessonNoteShared` | `lesson_service.update_feedback()` | ✅ 구현 (2026-05-31) |
| `subscriptionIssued` | `subscription_service.create()` | ✅ 구현 (2026-05-31) |
| `scheduleConfirmationRequired` | `schedule_confirmation_service.create_card()` | ✅ 구현 (2026-05-31) |
| `lessonCancelled` | `bulk_teacher_action_service` | ✅ 구현 |
| `paymentReceived` | `subscription_service.confirm_payment_by_teacher()` | ✅ 구현 |
| `paymentConfirmed` | `subscription_service.confirm_payment_by_teacher()` | ✅ 구현 |
| `subscriptionExpiringSoon` | `subscription_expiry_dispatcher` | ✅ 구현 |
| `connectionRequestReceived` | `invite_service` | ✅ 구현 |
| `connectionRequestAccepted` | `ConnectionNotificationService` (프론트) | ✅ 구현 |
| `generalAnnouncement` | `bulk_teacher_action_service`, `announcement_service` | ✅ 구현 |
| `attendanceUnconfirmed` | `attendance_scheduler_service` | ✅ 구현 |
| `lessonReminder` | 서버 스케줄러 | ❌ 미구현 |
| `lessonStarting` | 서버 스케줄러 | ❌ 미구현 |
| `practiceReminder` | 로컬 스케줄러 (프론트) | ✅ 프론트 구현 |
| `profileReminder24h` | `profile_reminder_service.dispatch_reminders()` | ✅ 구현 (2026-05-31) |
| `profileReminder3d` | `profile_reminder_service.dispatch_reminders()` | ✅ 구현 (2026-05-31) |
| `profileReminder7d` | `profile_reminder_service.dispatch_reminders()` | ✅ 구현 (2026-05-31) |
| `lessonCancelled` (단일) | `lesson_service` | ❌ 미구현 |
| `lessonRescheduled` | `lesson_service` | ❌ 미구현 |

### 미구현 (예정)

| 항목 | 우선순위 | 비고 |
|------|---------|------|
| ~~FCM 푸시 알림 인프라~~ | ✅ 완료 (코드 구현, Firebase 설정 대기) | |
| 알림 설정 화면 — 마스터 토글 + 6 카테고리 토글 | **Phase 1.5 (출시 전 필수)** | 설정 메뉴 진입점이 이미 존재하나 화면이 없어 "기능 없는 메뉴" 상태(#15 플레이스홀더 위반). 알림 폭주 시 사용자가 끌 수단이 푸시 전체 차단뿐이므로 채널 보호 원칙(§1 설계 원칙 #3)에도 위배. 상세 범위: [push_notification_settings_spec.md](push_notification_settings_spec.md) §10 참조 |
| 알림 설정 Hive 영속화 | Phase 1.5 | 설정 화면과 함께 구현 |
| DND/방해금지 시간대 설정 (시간대 직접 지정) | Phase 2 | 마스터+카테고리 토글과 분리하여 후속 구현 |
| 알림 빈도 조절 (단계별 슬라이더) | Phase 2 | |
| 알림 빈도 관리 / 개인화 | Phase 3 | |
| 서버 기반 알림 스케줄링 | Phase 3 | |
| 알림 통계/분석 | Phase 3 | |

---

## 7. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [notification_system.md](notification_system.md) | 기존 스펙 (알림 채널, 타이밍, 와이어프레임 상세) |
| [수강권 시스템](../subscription/subscription_system_spec.md) | 수강권 만료 알림 |
| [초대 시스템](../lesson/invite/invite_system_v2.md) | 학원 관련 알림 |
| [수강권 기반 관계](../lesson/invite/subscription_based_relationship.md) | 관계 상태 변경 알림 |
| [팔로우 시스템](../follow/follow_master.md) | 팔로우 알림 (NEW_FOLLOWER 등) |

---

## 8. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-12-27 | 기존 스펙 작성 (notification_system.md) |
| 2026-01-27 | 인앱 알림 UI 구현 완료 |
| 2026-03-06 | 구현 코드 기반 Master Spec 작성 (기존 스펙 + 구현 현실 통합) |
| 2026-03-07 | 알림 유형 상세 테이블(트리거/제목/본문/아이콘/딥링크), Provider 코드 설계, 구현 파일 위치 섹션 추가 |
| 2026-03-30 | FCM 푸시 알림 인프라 구현 (FcmService, DeviceToken 모델/API, Firebase 설정 가이드) |
| 2026-05-31 | 백엔드 알림 발송 구현: lessonBooked, lessonNoteShared, subscriptionIssued, scheduleConfirmationRequired. 백엔드 발송 구현 상태 테이블 추가. 프로필 리마인더 3종(profileReminder24h/3d/7d) 추가. LocalNotificationService.\_onNotificationTapped payload 파싱 역할 명시 |
| 2026-06-04 | FE `NotificationType` enum 에 7종 추가 — BE 가 발송하지만 FE 가 매핑/렌더링하지 못한 갭 해소: 결제 미확인 3종(paymentPendingD1/D3/D7Final), 스케줄 확정 1종(scheduleConfirmationRequired), 프로필 리마인더 3종(profileReminder24h/3d/7d). targetRole 매핑(학생/선생/both) + 우선순위(D3/D7Final/scheduleConfirm/profile7d=high) 분기 추가 |
| 2026-06-12 | 출시 준비도 감사 P1-1 — 알림 설정 화면(마스터+6카테고리 토글)을 Phase 2 → Phase 1.5(출시 전 필수)로 승격. 사유: 설정 메뉴 진입점 존재 + 화면 미구현 = #15 플레이스홀더 위반, 채널 보호 원칙 위배. DND/빈도조절은 Phase 2 유지. §2.5.2에 push_notification_settings_spec.md §3.2 상호 참조 추가 |
