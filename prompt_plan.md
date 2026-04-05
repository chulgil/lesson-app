# Phase C: 수강권 스케줄 관리 — 구현 계획

> 작성일: 2026-04-05
> 상태: ✅ 확정
> 스펙: docs/specs/subscription/subscription_schedule_management_spec.md

## 이전 계획

- Phase 3 (수강권 표시 — 학생 뷰) — 2026-04-04 완료
- Phase 3B (선생님 홈/목록/상세) — 2026-04-04 완료

---

## 결정 사항

| # | 결정 |
|---|------|
| 1 | 변경 요청 → 수강권 섹션 안 배지 |
| 2 | 회차별 챗 → 이전/현재/다음 3개 표시 |
| 3 | 스케줄 변경 → 항상 학생 동의 필요 |
| 4 | 정규권: 고정 스케줄 자동 생성 + 이번만/전체 변경 선택 |
| 5 | 회차권: 1회차만 생성 → 이후 학생이 빈 시간대 예약 |
| 6 | 온보딩 가이드 메시지 (유형별 첫 진입 시 표시) |

---

## 구현 Phase

### C-1: 티켓 카드 보강 + 학생 상세 교체

- SubscriptionTicketCard에 역할별 이름 표시 (선생님→학생이름, 학생→선생님이름)
- StudentSubscriptionSection의 _SubscriptionMembershipCard → SubscriptionTicketCard 교체
- 수정: subscription_ticket_card.dart, student_subscription_section.dart, teacher_subscription_section.dart

### C-2: RequestEvent 확장 + 회차 스케줄 자동 생성

- RequestEvent에 subscriptionId, sessionNumber 필드 추가
- subscriptionSessionEventsProvider 추가
- **정규권 발급 시**: 고정 요일/시간으로 전체 회차 스케줄 자동 생성
- **회차권 발급 시**: 1회차만 스케줄 생성, 나머지 "예약 필요" 상태
- build_runner 재생성
- 수정: request_event.dart, subscription_providers.dart, issue_subscription_actions.dart

### C-3: 회차별 챗 임베딩

- subscription_chapter_lessons.dart 리디자인 → 3개 회차 (이전/현재/다음) + 접기/펼치기
- 펼친 회차에 RequestHistoryChat 패턴으로 이벤트 렌더링
- 새 위젯: subscription_session_chat.dart (RequestHistoryChat 패턴 복제)
- 수정: subscription_chapter_lessons.dart, subscription_detail_screen.dart

### C-4: 변경 플로우 (유형별 + 양방향 동의)

- **정규권**: "이번 회차만" vs "앞으로 전체" 선택지 → ScheduleChangeTypeBottomSheet 재사용
  - 이번만 (singleLesson): 해당 회차 변경
  - 전체 (bulkChange): 현재~마지막 회차 새 고정 시간 적용
- **회차권**: 해당 회차만 변경 (선택지 없음)
- 학생: 변경 요청 → scheduleChangeRequested 이벤트
- 선생님: AlternativeTimeGrid로 시간 제안 → scheduleChangeProposed 이벤트
- 학생: TimeSlotPicker로 선택 → scheduleChangeAccepted 이벤트
- 기존 위젯 재사용: AlternativeTimeGrid, TimeSlotPicker, ScheduleChangeTypeBottomSheet

### C-5: 알림 + 배지 + 온보딩 가이드

- scheduleChangeRequested 알림 생성
- TeacherSubscriptionSection에 "변경요청 N건" 배지 추가
- 배지 탭 → 수강권 상세의 해당 회차로 이동
- **온보딩 가이드 메시지**: 유형별 첫 진입 시 상단 가이드 표시
  - 정규권: "고정 스케줄이 자동 생성되었습니다"
  - 회차권: "다음 레슨 시간을 선생님의 빈 시간대에서 선택하세요"
  - 변경취소권 경고: 잔여 1회 / 소진 시 가이드
- 수정: teacher_subscription_section.dart, notification_providers.dart, subscription_chapter_lessons.dart

### C-6: 수강권 전체 화면 확장

- SubscriptionListScreen 상단에 Summary (이용중/소진임박/만료 카운트)
- Pending 섹션 (승인 대기 변경 요청)
- 수정: subscription_list_screen.dart

---

## 실행 순서

```
C-1 (카드 보강) → C-2 (데이터 모델) → C-3 (챗 임베딩) → C-4 (변경 플로우) → C-5 (알림) → C-6 (전체 화면)
```

C-1, C-2는 독립 → 병렬 가능
C-3은 C-2 필요
C-4는 C-3 필요
C-5는 C-2 필요 (C-3과 병렬 가능)
C-6은 C-1 필요
