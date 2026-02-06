# 체험 레슨 예약 플로우

> 마지막 업데이트: 2026-02-06

선생님-학생 연결 후 체험 레슨을 예약하는 플로우입니다.

👉 [전체 플로우 인덱스](flow_with_app.md)

---

## 시퀀스 다이어그램

```mermaid
sequenceDiagram
    autonumber
    participant S as 🎓 학생/학부모
    participant App as 📱 Lesson App
    participant Push as 🔔 푸시 알림
    participant T as 🎻 선생님

    Note over S,T: 📱 Phase 1: 앱에서 체험 신청 (연결 후)

    S->>App: 선생님 프로필 → "체험 신청"
    App-->>S: 선생님 가용 시간 캘린더 표시

    Note over App: ✅ 해결: 실시간 가용 시간<br/>핑퐁 메시지 없이 바로 확인

    Note over App: 🎯 "생각없이 예약" UI<br/>가용 시간만 칩 버튼으로 표시<br/>⭐ 평소 시간 추천

    S->>App: 토요일 15:30 칩 탭 (원클릭 선택)
    App-->>S: 신청 정보 입력 폼

    Note over App: 학생 이름, 악기 경험,<br/>희망 사항 등 한 번에 입력

    S->>App: 정보 입력 → 신청 완료

    App->>Push: 선생님에게 푸시 알림
    Push->>T: "🔔 새 체험레슨 요청\n토요일 15:30 / 김민수"

    Note over S,T: ⏱️ 선생님 응답 대기 (실시간 알림)

    T->>App: 알림 탭 → 요청 확인
    App-->>T: 학생 정보, 희망 시간 표시

    T->>App: "승인" 버튼 탭

    App->>Push: 학생에게 승인 알림
    Push->>S: "🎉 체험레슨 확정!\n토요일 15:30 / 선생님 A"

    App-->>S: 레슨 정보 카드 표시
    Note over App: 일시, 장소, 선생님 연락처,<br/>체험비, 준비물 등 모든 정보

    Note over S,T: ✅ 해결: 정보 누락 없음<br/>필요 정보 자동 전달

    Note over S,T: 🔔 Phase 2: 자동 리마인더

    App->>Push: D-1 자동 리마인더
    Push->>S: "📅 내일 15:30 체험레슨\n선생님 A / 강남역 OO빌딩"
    Push->>T: "📅 내일 15:30 체험레슨\n김민수 학생"

    Note over App: ✅ 해결: 자동 알림<br/>선생님 수동 발송 불필요

    Note over S,T: ✅ 체험 레슨 완료
```

---

## 개선 효과 비교

| 단계 | 앱 미사용 | 앱 사용 | 개선율 |
|------|----------|--------|:------:|
| 일정 조율 | 5-10회 메시지 | **1클릭 선택** | 🔥 95% |
| 정보 교환 | 여러 번 왕복 | **자동 전달** | 🔥 100% |
| 리마인더 | 수동 | **자동 푸시** | 🔥 100% |
