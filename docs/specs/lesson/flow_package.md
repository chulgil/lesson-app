# 회차권 레슨 플로우

> 마지막 업데이트: 2026-02-06

회차권(N회권) 레슨의 결제, 예약, 소진, 연장 플로우입니다.

👉 [전체 플로우 인덱스](flow_with_app.md) | [결제 플로우](flow_payment.md)

---

## 시퀀스 다이어그램

```mermaid
sequenceDiagram
    autonumber
    participant S as 🎓 학생/학부모
    participant App as 📱 Lesson App
    participant Push as 🔔 푸시 알림
    participant T as 🎻 선생님
    participant Bank as 🏦 외부 결제

    Note over S,T: 🎫 Phase 1: 회차권 안내 및 결제

    T->>App: 수강권 템플릿 선택
    Note over App: - 10회권: 90만원<br/>- 유효기간: 3개월

    T->>App: 학생에게 결제 안내 발송

    App->>Push: 결제 안내 알림
    Push->>S: "💳 10회권 결제 안내\n90만원 / 국민 xxx-xxxx"

    S->>Bank: 결제 (계좌이체)

    S->>App: "결제 완료" 알림 (선택)
    App->>Push: 선생님에게 알림
    Push->>T: "💰 김민수 결제 완료 알림"

    Note over T,App: 💳 Phase 1-1: 입금 확인 → 수강권 발급

    T->>T: 계좌 입금 확인 (90만원)
    T->>App: 입금 확인 체크 ✓

    T->>App: 수강권 발급 버튼
    App-->>T: 수강권 설정 확인
    Note over App: - 10회권<br/>- 유효기간: 3개월<br/>- 금액: 90만원

    T->>App: 발급 확인

    App->>App: 관계 active + 수강권 활성화 (잔여 10회)

    App->>Push: 수강권 발급 알림
    Push->>S: "🎫 수강권 발급 완료\n10회 / 유효: ~4/26"

    App-->>S: 잔여 횟수 대시보드 표시
    Note over App: 잔여: 10회 | 유효기간: ~4/26

    Note over App: ✅ 해결: 입금 확인 → 수강권 발급<br/>선생님이 확인 후 수강권 끊어줌<br/>학생도 실시간 확인 가능

    Note over S,T: 📅 Phase 2: 스마트 레슨 예약

    T->>App: 다음 레슨 시간 제안
    App-->>T: 캘린더에서 가능 시간 선택

    T->>App: 금요일 18:00 제안 (기본 1개)

    App->>Push: 학생에게 시간 확인 요청
    Push->>S: "📅 레슨 시간 확인\n금 18:00 [확인] [다른 시간]"

    S->>App: 확인 탭 (원클릭)

    App->>App: 자동 일정 확정
    App->>Push: 양쪽에 확정 알림
    Push->>T: "✅ 레슨 확정: 금 18:00"
    Push->>S: "✅ 레슨 확정: 금 18:00"

    Note over App: ✅ 해결: 원클릭 확인<br/>기본 제안 수락 = 탭 1번

    Note over S,T: 레슨 진행 후

    T->>App: 레슨 완료 처리
    App->>App: 잔여 횟수 자동 차감 (10→9)

    App->>Push: 학생에게 알림
    Push->>S: "✅ 레슨 완료\n잔여 9회 | 유효기간: ~4/26"

    Note over App: ✅ 해결: 자동 횟수 관리<br/>선생님 수동 기록 불필요

    Note over S,T: ⚠️ Phase 3: 소진 임박 알림

    Note over App: 잔여 2회 시점

    App->>Push: 자동 알림 (양쪽)
    Push->>S: "⚠️ 수강권 잔여 2회\n연장하시겠어요?"
    Push->>T: "📊 김민수 수강권 잔여 2회"

    S->>App: 알림 탭 → 연장 결정

    alt 연장함
        T->>App: 새 회차권 결제 안내 발송
        App->>Push: 결제 안내
        Push->>S: "💳 10회권 연장 안내\n90만원"

        S->>Bank: 결제 (계좌이체)
        S->>App: "결제 완료" 알림

        T->>T: 계좌 입금 확인
        T->>App: 입금 확인 체크 ✓

        T->>App: 수강권 발급 버튼
        App->>App: 새 수강권 활성화
        App-->>S: 잔여 횟수 합산 (2+10=12)

        Note over App: 기존 잔여 + 신규 발급 = 합산
    else 연장 안 함
        S->>App: "나중에 결정"
        App->>App: 소진 시 관계 expired로 전환
    end

    Note over App: ✅ 해결: 자동 연장 안내<br/>선생님 문의 부담 없음<br/>입금 확인 후 수강권 발급
```

---

## 개선 효과 비교

| 단계 | 앱 미사용 | 앱 사용 | 개선율 |
|------|----------|--------|:------:|
| 매 예약 | 3-5회 메시지 | **1-2회 탭** | 🔥 90% |
| 횟수 관리 | 수동 기록 | **자동 차감** | 🔥 100% |
| 잔여 안내 | 선생님이 알림 | **앱에서 확인** | 🔥 100% |
| 연장 안내 | 선생님이 문의 | **자동 알림** | 🔥 100% |

**10회권 총 메시지: 40-60회 → 10-15회**
