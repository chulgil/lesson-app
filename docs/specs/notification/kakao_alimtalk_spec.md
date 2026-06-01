# 카카오 알림톡 연동 스펙

> 작성일: 2026-05-31 (2026-06-01 — E2E 감사 #2 E2-C2 보강)
> 상태: 초안 (구현 대기)
> 관련 이슈: #423
> 관련 스펙: [notification_master.md](./notification_master.md), [payment_architecture.md](../subscription/payment_architecture.md)
> **5종 템플릿 본문 + 정책**: [alimtalk_templates.md](alimtalk_templates.md) (LNZ_INVOICE / LNZ_PAYMENT_REMINDER_D1/D3/D7 / LNZ_PAYMENT_CONFIRM / LNZ_TEACHER_VACATION)

---

## 1. 개요

### 1.1 왜 필요한가

한국 시장에서 앱 푸시 알림과 카카오 알림톡의 도달률은 현격한 차이가 있다.

| 채널 | 도달률 | 오픈율 | 특이사항 |
|------|--------|--------|---------|
| 앱 푸시 (FCM) | 60~70% | 20~30% | 앱 설치 + 알림 허용 필요 |
| 카카오 알림톡 | 98% | 50~60% | 카카오톡 설치만 필요 (국내 사용자 97% 이상) |
| SMS | 99% | 30~40% | 비용 높음, 스팸 필터 우려 |

Lessonaza 학부모 사용자 중 상당수가 앱을 설치하지 않은 상태에서 수강료 청구·레슨 리마인더를 받아야 한다. 앱 미설치 학부모에게 수강료 청구(paymentRequested), 입금 확인(paymentConfirmed), 레슨 리마인더(lessonReminder)를 전달하려면 카카오 알림톡 연동이 필수다.

### 1.2 카카오 비즈메시지 서비스 개요

카카오 비즈메시지는 카카오에서 운영하는 기업용 메시지 서비스다. 두 가지 유형이 있다.

- **알림톡(AlimTalk)**: 카카오 채널 추가 없이도 카카오톡 계정(전화번호 기반)으로 정보성 메시지 발송. 사전 템플릿 심사 필수.
- **친구톡(FriendTalk, 구 브랜드메시지)**: 채널 추가(친구추가) 사용자에게만 발송. 광고성 메시지 가능.

본 스펙은 **알림톡(1단계)** 기준이다.

### 1.3 채널 비교

| 항목 | 앱 푸시 (FCM) | 카카오 알림톡 | SMS |
|------|-------------|------------|-----|
| 수신 조건 | 앱 설치 + 알림 허용 | 카카오톡 가입 + 전화번호 일치 | 전화번호 |
| 광고성 메시지 | 가능 | 불가 (정보성만) | 가능 (수신동의 필요) |
| 야간 발송 | 가능 (긴급 알림 한정) | 제한 (광고성만 — 알림톡 정보성은 가능) | 20:00~08:00 수신동의 필요 |
| 비용 | 무료 (Firebase 무료 티어) | 건당 약 8원 (+ VAT, 대리점 요금 변동) | SMS 건당 10~20원, LMS 40~50원 |
| 템플릿 심사 | 불필요 | 필수 (영업일 2~3일) | 불필요 |
| 딥링크 버튼 | 가능 | 가능 (웹링크/딥링크) | 불가 |

---

## 2. 범위

### 2.1 이번 스펙 범위 (1단계: 알림톡)

- 사전 등록·심사된 템플릿 기반 단방향 정보성 메시지
- 수신자: 학생/학부모 (전화번호 등록 사용자)
- 주요 알림: 수강료 청구, 입금 확인, 레슨 리마인더, 레슨 취소, 수강권 만료 임박

### 2.2 2단계 (향후 별도 스펙)

- 카카오채널 친구톡 (양방향, 마케팅 메시지)
- 채널 추가 인센티브 연동

### 2.3 명시적 경계

- **카카오페이 결제 연동은 제외** — [payment_architecture.md](../subscription/payment_architecture.md) §1 참조. 현행 결제 정책은 무통장입금 기반이며 PG 연동은 별도 스펙
- **광고성 메시지(친구톡)는 제외** — 알림톡은 정보성 메시지만 허용
- **카카오 로그인 연동은 제외** — auth 스펙 별도

---

## 3. 사전 요구사항

### 3.1 카카오 계정 및 채널 등록

| 단계 | 내용 | 담당 | 소요 시간 |
|------|------|------|----------|
| 1 | [카카오 비즈니스](https://business.kakao.com) 사업자 계정 등록 | 운영팀 | 1~3일 |
| 2 | 카카오톡 채널(플러스친구) 개설 — 채널명이 발신자 이름으로 표시됨 | 운영팀 | 즉시 |
| 3 | 채널 비즈니스 인증 (사업자등록증 제출) | 운영팀 | 3~7일 |
| 4 | 카카오 비즈메시지 공식 딜러사와 계약 (예: NHN Cloud, 알리고, Bizgo, SOLAPI 등) | 운영팀 | 1~3일 |
| 5 | 딜러사에서 API 키(APP_KEY) 및 SenderKey 발급 | 운영팀 | 즉시~1일 |
| 6 | 알림톡 템플릿 등록 및 카카오 심사 요청 | 개발팀 | 영업일 2~3일/템플릿 |

### 3.2 API 키 종류

| 키 | 용도 | 관리 위치 |
|---|------|----------|
| `KAKAO_BIZ_APP_KEY` | API 인증 (딜러사 발급) | `.env` + AWS Secrets Manager |
| `KAKAO_BIZ_SENDER_KEY` | 발신 프로필 식별자 (채널 고유 키) | `.env` + AWS Secrets Manager |
| `KAKAO_ALIMTALK_ENABLED` | Feature flag (운영 중 on/off) | `.env` |

### 3.3 카카오 알림톡 정책 요약 (2026년 1월 이후 기준)

- **정보성 메시지만 허용**: 거래·계약에서 발생한 정보, 서비스 이용에 필수적인 안내
- **2026년 1월 정책 강화**: 일방적 혜택(쿠폰·마일리지 등) 사용 유도성 메시지 발송 금지. 명시적 거래 관계에서 발생한 지급 정보만 허용
- **야간 발송**: 알림톡(정보성)은 24시간 발송 가능. 단, **광고성 친구톡은 20:00~08:00 발송 금지**
- **수신 거부**: 수신자가 카카오톡에서 채널 차단 시 발송 실패 처리 (오류 코드 반환)

> 레슨앱의 수강료 청구, 입금 확인, 레슨 리마인더는 모두 거래 관계 기반 정보성 메시지에 해당하므로 알림톡 발송 가능하다.

---

## 4. 알림톡 템플릿 목록

### 4.1 템플릿 정의

카카오 알림톡은 **사전 심사를 통과한 템플릿만** 발송할 수 있다. 변수는 `#{변수명}` 형식으로 정의한다.

| 템플릿 코드 | 용도 | 대상 | 우선순위 | 카카오 분류 |
|------------|------|------|---------|-----------|
| `LNZ_INVOICE` | 수강료 청구 | 학생/학부모 | CRITICAL | 결제 안내 |
| `LNZ_PAYMENT_CONFIRM` | 입금 확인 완료 | 학생/학부모 | CRITICAL | 결제 안내 |
| `LNZ_LESSON_REMIND` | 레슨 리마인더 | 학생/학부모 | HIGH | 예약 안내 |
| `LNZ_LESSON_CANCEL` | 레슨 취소 알림 | 학생/학부모 | HIGH | 예약 안내 |
| `LNZ_SCHEDULE_CONFIRM` | 일정 확인 요청 | 학생/학부모 | HIGH | 예약 안내 |
| `LNZ_SUBSCRIPTION_EXPIRY` | 수강권 만료 임박 | 학생/학부모 | MEDIUM | 서비스 안내 |
| `LNZ_WELCOME` | 가입 환영 | 학생/학부모 | LOW | 가입 안내 |

### 4.2 템플릿 상세 정의

#### LNZ_INVOICE — 수강료 청구

```
[레슨나자] 수강료 안내

안녕하세요, #{studentName} 학생(보호자)님.
#{teacherName} 선생님께서 수강료 납부를 안내드립니다.

■ 수강권: #{subscriptionName}
■ 금액: #{amount}원
■ 납부 기한: #{dueDate}까지
■ 입금 계좌: #{bankName} #{bankAccount}
              예금주: #{accountHolder}

앱에서 입금 완료를 알려주시면 선생님이 확인 후 수강권을 발급해드립니다.
```

- 버튼: [앱에서 확인하기] — 딥링크 `lessonaza://subscription/proposal/{proposalId}`
- 변수: `studentName`, `teacherName`, `subscriptionName`, `amount`, `dueDate`, `bankName`, `bankAccount`, `accountHolder`, `proposalId`
- 심사 분류: 결제 안내 (정보성)
- Fallback: SMS LMS (내용 동일, 버튼 미포함)

#### LNZ_PAYMENT_CONFIRM — 입금 확인 완료

```
[레슨나자] 입금 확인 완료

안녕하세요, #{studentName} 학생(보호자)님.
수강료 입금이 확인되었습니다.

■ 수강권: #{subscriptionName}
■ 확인 금액: #{amount}원
■ 수강 횟수: #{lessonCount}회
■ 유효 기간: #{startDate} ~ #{endDate}

레슨나자에서 일정을 확인해보세요!
```

- 버튼: [수강권 확인하기] — 딥링크 `lessonaza://subscription/{subscriptionId}`
- 변수: `studentName`, `subscriptionName`, `amount`, `lessonCount`, `startDate`, `endDate`, `subscriptionId`
- 심사 분류: 결제 안내 (정보성)
- Fallback: SMS

#### LNZ_LESSON_REMIND — 레슨 리마인더

```
[레슨나자] 레슨 일정 안내

안녕하세요, #{studentName} 학생님.
#{teacherName} 선생님과의 레슨이 #{reminderTime}에 있습니다.

■ 일시: #{lessonDate} #{lessonTime}
■ 선생님: #{teacherName}
■ 과목: #{subject}

잊지 마세요!
```

- 버튼: [레슨 상세 보기] — 딥링크 `lessonaza://lesson/{lessonId}`
- 변수: `studentName`, `teacherName`, `reminderTime`, `lessonDate`, `lessonTime`, `subject`, `lessonId`
- 심사 분류: 예약 안내 (정보성)
- Fallback: SMS

#### LNZ_LESSON_CANCEL — 레슨 취소 알림

```
[레슨나자] 레슨 취소 안내

안녕하세요, #{recipientName}님.
#{cancellerName}님이 레슨을 취소하였습니다.

■ 취소된 레슨: #{lessonDate} #{lessonTime}
■ 사유: #{reason}

보충 레슨은 앱에서 별도 예약하실 수 있습니다.
문의사항은 앱 내 채팅을 이용해 주세요.
```

- 버튼: [앱에서 확인하기] — 딥링크 `lessonaza://lesson/{lessonId}`
- 변수: `recipientName`, `cancellerName`, `lessonDate`, `lessonTime`, `reason`, `lessonId`
- 심사 분류: 예약 안내 (정보성)
- Fallback: SMS

#### LNZ_SCHEDULE_CONFIRM — 일정 확인 요청

```
[레슨나자] 레슨 일정 변경 안내

안녕하세요, #{recipientName}님.
#{requesterName}님이 레슨 일정 변경을 제안하였습니다.

■ 기존 일정: #{originalDate} #{originalTime}
■ 변경 제안: #{proposedDate} #{proposedTime}

앱에서 수락 또는 거절해 주세요.
(미응답 시 #{expiryHours}시간 후 자동 만료됩니다)
```

- 버튼: [일정 확인하기] — 딥링크 `lessonaza://schedule/change/{changeId}`
- 변수: `recipientName`, `requesterName`, `originalDate`, `originalTime`, `proposedDate`, `proposedTime`, `expiryHours`, `changeId`
- 심사 분류: 예약 안내 (정보성)
- Fallback: SMS

#### LNZ_SUBSCRIPTION_EXPIRY — 수강권 만료 임박

```
[레슨나자] 수강권 만료 임박 안내

안녕하세요, #{studentName} 학생(보호자)님.
#{teacherName} 선생님과의 수강권이 곧 만료됩니다.

■ 수강권: #{subscriptionName}
■ 잔여 레슨: #{remainingLessons}회
■ 만료 예정일: #{expiryDate} (#{daysLeft}일 후)

앱에서 수강권 갱신을 요청하거나 선생님께 문의해보세요.
```

- 버튼: [수강권 갱신 요청] — 딥링크 `lessonaza://subscription/renew/{subscriptionId}`
- 변수: `studentName`, `teacherName`, `subscriptionName`, `remainingLessons`, `expiryDate`, `daysLeft`, `subscriptionId`
- 심사 분류: 서비스 안내 (정보성)
- Fallback: 앱 푸시만 (SMS는 선택)

#### LNZ_WELCOME — 가입 환영

```
[레슨나자] 가입을 환영합니다!

안녕하세요, #{userName}님.
레슨나자에 가입해 주셔서 감사합니다.

선생님과 연결하고 첫 레슨을 시작해보세요.
```

- 버튼: [시작하기] — 딥링크 `lessonaza://onboarding`
- 변수: `userName`
- 심사 분류: 가입 안내 (정보성)
- Fallback: 없음

### 4.3 Notification 타입 → 알림톡 템플릿 매핑

notification_master.md의 알림 타입과 알림톡 템플릿을 연결한다.

| notification_type | 알림톡 템플릿 | 발송 조건 |
|-------------------|------------|----------|
| `paymentRequested` | `LNZ_INVOICE` | 전화번호 등록 + 알림톡 동의 시 |
| `paymentReminder` | `LNZ_INVOICE` (리마인더 텍스트 변형) | 전화번호 등록 + 알림톡 동의 시 |
| `paymentConfirmed` | `LNZ_PAYMENT_CONFIRM` | 전화번호 등록 + 알림톡 동의 시 |
| `lessonReminder` | `LNZ_LESSON_REMIND` | 전화번호 등록 + 알림톡 동의 시 |
| `lessonCancelled` | `LNZ_LESSON_CANCEL` | 전화번호 등록 + 알림톡 동의 시 |
| `scheduleChangeRequested` | `LNZ_SCHEDULE_CONFIRM` | 전화번호 등록 + 알림톡 동의 시 |
| `subscriptionExpiringSoon` | `LNZ_SUBSCRIPTION_EXPIRY` | 전화번호 등록 + 알림톡 동의 시 |
| `connectionEstablished` | `LNZ_WELCOME` (최초 연결 시만) | 전화번호 등록 + 알림톡 동의 시 |

---

## 5. 아키텍처

### 5.1 발송 흐름

```
비즈니스 이벤트 발생
  (예: 수강권 제안 생성, 레슨 완료, 스케줄러 트리거)
         │
         ▼
NotificationService.create_notification()
  → Notification DB 레코드 저장
         │
         ├──► FcmService.send_push()     ← 기존 (앱 설치 사용자)
         │
         └──► KakaoAlimtalkService.send()  ← 신규
               │
               ├─ 수신자 전화번호 조회
               │   (UserProfile.phone_number)
               ├─ 알림톡 수신 동의 확인
               │   (UserNotificationPreference.alimtalk_enabled)
               ├─ 템플릿 코드 선택 + 변수 치환
               ├─ 카카오 비즈메시지 API 호출
               │   POST /v1/message/send_al
               ├─ AlimtalkLog DB 저장 (성공/실패)
               └─ 실패 시 → FallbackService.send_sms()
```

### 5.2 중복 발송 방지 정책

앱 푸시와 알림톡 동시 발송 시 사용자 경험 저하를 방지한다.

| 우선순위 | 조건 | 행동 |
|---------|------|------|
| 1 (최우선) | 알림톡 활성화 + 전화번호 등록 | 알림톡 발송. FCM 앱 푸시는 **발송하지 않음** |
| 2 | 전화번호 없거나 알림톡 비활성 | FCM 앱 푸시만 발송 |
| 3 | 알림톡 발송 실패 (수신 거부, 미가입 등) | FCM 앱 푸시로 즉시 fallback |
| 4 | FCM + 알림톡 모두 실패 | SMS fallback (CRITICAL 알림만) |

> 예외: `CRITICAL` 우선순위 알림(`paymentRequested`, `paymentConfirmed`)은 알림톡 + FCM 모두 발송한다. 금전 관련 누락 방지.

### 5.3 전화번호 관리 정책

- **형식**: E.164 표준 저장 (`+821012345678`), 표시는 한국 형식 (`010-1234-5678`)
- **소유자**: 각 User 엔티티의 `phone_number` 필드 (학생/학부모 프로필)
- **미등록 처리**: 전화번호가 없으면 알림톡 발송 생략, FCM만 발송
- **수신 거부**: 카카오 수신 거부(error_code: 7000~7999) 시 `alimtalk_phone_blocked = True` 플래그 저장, 이후 해당 사용자에게 알림톡 발송 중단

### 5.4 발송 시간 정책

알림톡(정보성)은 24시간 발송 가능하나, 사용자 경험을 위해 앱 자체 제한을 둔다.

| 알림 유형 | 발송 가능 시간 | 비고 |
|-----------|-------------|------|
| CRITICAL (`paymentRequested`, `paymentConfirmed`) | 24시간 | 수강료 관련이므로 즉시 발송 |
| HIGH (`lessonReminder`, `lessonCancelled`) | 07:00~22:00 (KST) | 야간 알림은 다음날 07:00으로 지연 |
| MEDIUM (`subscriptionExpiringSoon`) | 09:00~20:00 (KST) | |
| LOW (`welcome`) | 09:00~20:00 (KST) | |

---

## 6. 백엔드 구현 설계

### 6.1 KakaoAlimtalkService

파일 위치: `backend/app/services/kakao_alimtalk_service.py`

```python
class KakaoAlimtalkService:
    """
    카카오 비즈메시지 API를 통해 알림톡을 발송하는 서비스.
    딜러사 REST API 래퍼. 발송 결과는 AlimtalkLog에 저장.
    """

    async def send(
        self,
        template_code: str,
        receiver_phone: str,         # E.164 형식
        template_variables: dict,    # #{변수명} 치환값
        notification_id: str | None = None,
    ) -> AlimtalkResult:
        """알림톡 발송. 성공/실패 여부와 카카오 응답을 반환."""
        ...

    async def send_bulk(
        self,
        messages: list[AlimtalkMessage],
    ) -> list[AlimtalkResult]:
        """다수 수신자 일괄 발송 (스케줄러용)."""
        ...
```

#### 카카오 API 엔드포인트 (딜러사별 상이)

딜러사(예: NHN Cloud, SOLAPI, 알리고)를 통해 발송하므로 실제 엔드포인트는 딜러사 계약 후 확정한다. 공통 파라미터는 다음과 같다.

```
POST /v1/message/send_al   (딜러사별 경로 다름)
Content-Type: application/json

{
  "senderKey": "KAKAO_BIZ_SENDER_KEY",
  "templateCode": "LNZ_INVOICE",
  "recipientList": [
    {
      "recipientNo": "01012345678",
      "templateParameter": {
        "studentName": "홍길동",
        "amount": "150000",
        ...
      },
      "buttons": [
        {
          "ordering": 1,
          "type": "WL",           // WL=웹링크, AL=앱링크, BK=봇키워드, MD=메시지전달
          "name": "앱에서 확인하기",
          "linkMo": "https://lessonaza.page.link/...",
          "linkPc": "https://lessonaza.app/..."
        }
      ]
    }
  ]
}
```

응답 상태 코드 처리:

| 응답 코드 | 의미 | 처리 |
|---------|------|------|
| 0 | 성공 | AlimtalkLog status=SUCCESS |
| 2000~2999 | 발송 실패 (수신자 오류) | 로그 후 FCM fallback |
| 7000~7999 | 수신 거부 | phone_blocked=True 저장, 이후 발송 안 함 |
| 4000~4999 | 템플릿 오류 | 알람 (Slack), 개발팀 조치 필요 |
| 9000~ | 서버/인증 오류 | 재시도 큐 (최대 3회), 이후 FCM fallback |

### 6.2 DB 모델

#### AlimtalkLog 테이블

파일 위치: `backend/app/models/alimtalk_log.py`

```python
class AlimtalkLog(Base):
    """카카오 알림톡 발송 이력."""
    __tablename__ = "alimtalk_logs"

    id: Mapped[str]                    # UUID PK
    notification_id: Mapped[str | None] # FK → notifications.id (nullable: 스케줄러 직접 발송)
    user_id: Mapped[str]               # FK → users.id
    template_code: Mapped[str]         # LNZ_INVOICE 등
    phone_number: Mapped[str]          # 마스킹 저장: +82-010-****-5678
    status: Mapped[AlimtalkStatus]     # PENDING / SUCCESS / FAILED / BLOCKED
    kakao_message_id: Mapped[str | None]  # 카카오 응답 messageId
    kakao_error_code: Mapped[str | None]  # 실패 시 에러 코드
    kakao_response: Mapped[dict | None]   # 전체 응답 JSON (JSONB)
    sent_at: Mapped[datetime | None]      # 실제 발송 시각 (UTC)
    created_at: Mapped[datetime]          # 레코드 생성 시각 (UTC)
```

```python
class AlimtalkStatus(str, Enum):
    PENDING = "pending"    # 발송 대기
    SUCCESS = "success"    # 발송 성공 (카카오 수신 확인)
    FAILED = "failed"      # 발송 실패 (FCM fallback 진행)
    BLOCKED = "blocked"    # 수신 거부 (해당 사용자 이후 발송 안 함)
```

#### UserNotificationPreference 확장

기존 `UserNotificationPreference.settings` JSONB에 알림톡 설정 추가:

```json
{
  "alimtalk_enabled": true,        // 알림톡 수신 동의 (기본값: true)
  "alimtalk_phone_blocked": false  // 카카오 수신 거부 플래그
}
```

마이그레이션: 기존 사용자 `alimtalk_enabled: true`로 기본값 설정 (옵트인 방식이 아닌 옵트아웃).

### 6.3 환경 변수

```bash
# .env / AWS Secrets Manager
KAKAO_BIZ_APP_KEY=...           # 딜러사 발급 API 키
KAKAO_BIZ_SENDER_KEY=...        # 발신 프로필 SenderKey
KAKAO_ALIMTALK_ENABLED=true     # Feature flag (false 시 전체 비활성화)
KAKAO_ALIMTALK_DEALER=nhncloud  # 딜러사 식별자 (nhncloud | solapi | aligo)
KAKAO_ALIMTALK_BASE_URL=...     # 딜러사 API base URL
```

### 6.4 NotificationService 연동

기존 `notification_service.py`의 `create_and_send` 패턴 확장:

```python
# backend/app/services/notification_service.py (변경 위치)

async def _dispatch_push(
    self,
    notification: Notification,
    user: Any,
) -> None:
    """FCM + 알림톡 발송 디스패치 (기존 FCM 로직 유지, 알림톡 추가)."""
    phone = getattr(user, "phone_number", None)
    alimtalk_enabled = self._is_alimtalk_enabled(user)

    if phone and alimtalk_enabled:
        result = await self.alimtalk_service.send(
            template_code=self._map_to_template(notification.type),
            receiver_phone=phone,
            template_variables=self._build_template_vars(notification),
            notification_id=str(notification.id),
        )
        if result.status == AlimtalkStatus.SUCCESS:
            # CRITICAL 아니면 FCM 중복 발송 안 함
            if notification.priority != NotificationPriority.CRITICAL:
                return
    # FCM fallback 또는 앱 전용 발송
    await self._send_fcm(notification, user)
```

---

## 7. 프론트엔드 변경

### 7.1 전화번호 수집

#### 학부모 온보딩

- 연결 요청 수락 직후 또는 학생 등록 직후 전화번호 입력 유도
- 필수는 아니나 "알림톡 수신을 위해 입력 권장" 문구 표시
- 화면 위치: `features/student/presentation/screens/` 또는 연결 플로우 내

#### 학생 프로필 설정

- 기존 프로필 편집 화면에 전화번호 필드 추가 (미입력 가능)
- 형식 검증: 01X-XXXX-XXXX 한국 전화번호
- 저장 시 E.164 변환: `010-1234-5678` → `+821012345678`

### 7.2 알림톡 수신 동의 화면

- 위치: `features/notification/presentation/screens/alimtalk_consent_screen.dart`
- 진입점: 첫 전화번호 입력 시 또는 알림 설정 화면에서
- 필수 표시 사항:
  - 발신자: "레슨나자 (카카오채널)"
  - 발송 내용: 수강료 안내, 레슨 일정, 수강권 만료 안내
  - 수신 거부 방법: 앱 설정에서 알림톡 끄기 또는 카카오톡에서 채널 차단
- 동의 방식: 전화번호 입력 + 하단 동의 체크박스 (기본값: 동의)

### 7.3 알림 설정 화면 확장

기존 알림 설정(`push_notification_settings_spec.md`)에 알림톡 섹션 추가:

```
알림 설정
├── 앱 푸시 알림
│   ├── 레슨 리마인더
│   ├── 수강료 알림
│   └── ...
└── [신규] 카카오 알림톡
    ├── 알림톡 수신 (ON/OFF)
    │   └── 설명: "카카오톡으로 수강료·일정 알림을 받습니다"
    └── 전화번호: 010-XXXX-XXXX [변경]
```

---

## 8. 테스트 계획

### 8.1 단위 테스트

파일: `backend/tests/test_kakao_alimtalk_service.py`

```python
# Mock 테스트 항목
- test_send_success: 정상 발송 → AlimtalkLog status=SUCCESS
- test_send_phone_blocked: 7000번대 에러 → status=BLOCKED, phone_blocked=True 저장
- test_send_api_failure: 9000번대 에러 → 재시도 후 status=FAILED
- test_template_variable_substitution: 변수 치환 정확도
- test_feature_flag_disabled: KAKAO_ALIMTALK_ENABLED=false → 발송 안 함
```

### 8.2 통합 시나리오 테스트

파일: `backend/tests/test_scenario_alimtalk.py`

`scenario-testing.md` 프레임워크 사용:

```python
@pytest.mark.asyncio
async def test_fw_수강권_제안_알림톡_발송(teacher: TeacherActions, student: StudentActions):
    """수강권 제안 → 학부모 전화번호 등록 → 알림톡 발송 확인."""
    sid = await teacher.create_student("홍길동")
    await student.register_phone("+821012345678")
    proposal_id = await teacher.create_subscription_proposal(sid, amount=150000)
    # 알림톡 발송 확인
    log = await AlimtalkLog.query.filter_by(template_code="LNZ_INVOICE").first()
    assert log.status == AlimtalkStatus.SUCCESS

@pytest.mark.asyncio
async def test_fw_알림톡_차단_시_FCM_fallback(teacher: TeacherActions, student: StudentActions):
    """알림톡 수신 거부 사용자 → FCM fallback 발송."""
    sid = await teacher.create_student("홍길동")
    await student.register_phone("+821012345678")
    await student.block_alimtalk()  # 카카오 수신 거부 시뮬레이션
    proposal_id = await teacher.create_subscription_proposal(sid, amount=150000)
    # FCM으로 fallback 발송 확인
    log = await AlimtalkLog.query.filter_by(template_code="LNZ_INVOICE").first()
    assert log.status == AlimtalkStatus.BLOCKED
    # FCM 발송 확인 (mock FCM service)
    ...
```

### 8.3 실 계정 발송 테스트

- 카카오 비즈메시지 딜러사 계약 후 테스트 채널로 실 발송 확인
- 테스트 전화번호로 각 템플릿 발송 → 카카오톡 수신 확인
- 버튼 딥링크 동작 확인

---

## 9. 비용 분석

### 9.1 단가 기준 (2026년 기준, 딜러사별 상이)

| 메시지 유형 | 단가 | 비고 |
|-----------|------|------|
| 알림톡 | 약 8원/건 (VAT 별도) | 딜러사 요금에 따라 5~12원 변동 |
| SMS fallback | 약 10~20원/건 | 딜러사 요금 |
| LMS fallback | 약 40~50원/건 | 90자 초과 시 LMS |
| FCM (앱 푸시) | 무료 | Firebase 무료 티어 |

### 9.2 예상 발송량 및 비용

| 시나리오 | 알림 유형 | 월 발송 수 | 예상 비용 |
|---------|---------|----------|---------|
| 선생님 1명 × 학생 10명 | 수강료 청구 월 1회 | 10건 | 88원 |
| 선생님 1명 × 학생 10명 | 레슨 리마인더 주 1회 | 40건 | 352원 |
| 선생님 1명 × 학생 10명 | 수강권 만료 월 1회 | 10건 | 88원 |
| **선생님 1명 기준 합계** | | **~60건/월** | **~528원/월** |
| 선생님 100명 기준 (서비스 성장 시) | | ~6,000건/월 | ~52,800원/월 |

> 비용은 딜러사 선택, 발송량 할인, VAT에 따라 변동. 정확한 단가는 계약 시 확인.

### 9.3 비용 최적화 전략

- **알림톡 우선, FCM 중복 금지**: 알림톡 성공 시 FCM 발송 안 함 (비용 0원)
- **CRITICAL만 양쪽 발송**: 수강료 관련 최소 2채널 보장
- **수신 거부 누적 관리**: `phone_blocked` 플래그로 불필요한 API 호출 방지
- **SMS fallback 최소화**: 알림톡 실패율 모니터링 후 임계치 초과 시 알림

---

## 10. 구현 단계

| 단계 | 범위 | 담당 | 예상 공수 | 선행 조건 |
|------|------|------|----------|----------|
| **1단계** | 카카오 비즈니스 계정 + 채널 개설 + 딜러사 계약 | 운영팀 | 1주 | — |
| **2단계** | 알림톡 템플릿 7종 등록 및 카카오 심사 요청 | 개발팀 + 운영팀 | 1주 (심사 대기 포함) | 1단계 완료 |
| **3단계** | `KakaoAlimtalkService` 백엔드 구현 + `AlimtalkLog` DB 모델 | 백엔드 | 1주 | 2단계 완료 |
| **4단계** | `NotificationService` 연동 (디스패치 로직 확장) | 백엔드 | 3일 | 3단계 완료 |
| **5단계** | 프론트엔드: 전화번호 수집 + 알림톡 수신 동의 화면 | 프론트엔드 | 3일 | — |
| **6단계** | 베타 테스트 + 모니터링 대시보드 + SMS fallback 검증 | 풀스택 | 1주 | 3~5단계 완료 |

### 10.1 배포 플래그 전략

```
KAKAO_ALIMTALK_ENABLED=false  → 코드 배포 후 기능 비활성 (기존 동작 유지)
KAKAO_ALIMTALK_ENABLED=true   → 베타 검증 완료 후 활성화
```

3~5단계를 `KAKAO_ALIMTALK_ENABLED=false`인 상태로 배포하여 기존 기능에 영향 없이 단계적 롤아웃.

---

## 11. 관련 스펙 및 참고

| 문서 | 내용 |
|------|------|
| [notification_master.md](./notification_master.md) | 알림 타입 전체 목록 및 수신자 매핑 |
| [push_notification_settings_spec.md](./push_notification_settings_spec.md) | 앱 푸시 알림 설정 스펙 |
| [payment_architecture.md](../subscription/payment_architecture.md) | 수강료 무통장입금 정책 |

### 참고 외부 문서

- [카카오 비즈메시지 공식 가이드](https://kakaobusiness.gitbook.io/main/ad/infotalk)
- [알림톡 심사 가이드](https://kakaobusiness.gitbook.io/main/ad/infotalk/audit)
- [카카오 비즈메시지 API (카카오 i Connect)](https://docs.kakaoi.ai/kakao_i_connect_message/bizmessage/)
- [NHN Cloud 알림톡 API 가이드](https://docs.nhncloud.com/ko/Notification/KakaoTalk%20Bizmessage/ko/alimtalk-api-guide-v2.1/)

---

## 12. 변경 이력

| 날짜 | 버전 | 내용 | 작성자 |
|------|------|------|--------|
| 2026-05-31 | 1.0 | 초안 작성 | Claude |
