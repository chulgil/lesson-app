# 통합 레슨 신청 PAD

## GitHub Issues

| # | 이슈 | 차단 관계 |
|---|------|----------|
| #199 | Phase 1: 통합 신청 폼 + 승인/거절 | 없음 (시작점) |
| #200 | Phase 2: 시간 협상 (대안 3개 + 역제안) | Blocked by #199 |
| #201 | Phase 3-5: 수강권 + 가격표 + 대시보드 | Blocked by #199 |

```
#199 ──blocks──→ #200 (시간 협상)
#199 ──blocks──→ #201 (수강권 + 가격표)
#200 ↔ #201: 병렬 가능
```

## 문제 정의

학생이 선생님을 검색하고 "정규레슨"을 클릭하면 수강권이 없을 때 `NoSubscriptionView`가 표시되며, 학생이 할 수 있는 행동이 없는 막다른 길이 된다. 체험레슨은 즉시 예약 방식이라 선생님이 거절할 수 없다. 체험/정규/복귀 레슨이 각각 다른 화면과 플로우를 사용하여 코드 중복과 UX 불일치가 발생한다.

## 솔루션 개요

체험레슨, 정규레슨, 복귀 레슨 신청을 **하나의 요청-승인 플로우**로 통합한다. 학생은 항상 "레슨 신청" 폼을 통해 요청하고, 선생님이 검토 후 승인/대안 제안/거절한다. 시간 합의 후 수강권 제안 → 결제 → 발급으로 이어진다.

## 유저 스토리

### 학생 (신규)
- 학생으로서 선생님 프로필에서 [레슨 신청]을 누르면 체험/정규를 선택하고 악기, 목적, 경험수준, 희망 시간을 한 화면에서 입력할 수 있다.
- 학생으로서 희망 시간 선택 시 선생님의 주간 스케줄에서 빈 슬롯을 직접 클릭하여 선택할 수 있다.
- 학생으로서 신청 후 대시보드에서 진행 상태(확인 중/대안 도착/수강권 도착)를 확인할 수 있다.

### 학생 (복귀)
- 복귀 학생으로서 [다시 시작하기]를 누르면 이전 레슨 정보(악기, 요일, 시간)가 자동으로 채워져 빠르게 신청할 수 있다.

### 학생 (시간 협상)
- 학생으로서 선생님이 제안한 대안 시간 3개 중 하나를 선택하거나, 마음에 안 들면 다른 시간을 역제안할 수 있다.
- 학생으로서 역제안 시 선생님 스케줄에서 빈 슬롯을 클릭하고 메모를 추가할 수 있다.

### 학생 (결제)
- 학생으로서 수강권 제안을 받으면 내용을 확인하고 수락할 수 있다.
- 학생으로서 입금 완료 후 "결제 완료" 버튼을 눌러 선생님에게 알릴 수 있다.

### 선생님 (요청 검토)
- 선생님으로서 학생의 레슨 신청을 주간 스케줄 UI에서 확인하고 승인/거절/대안 제안을 할 수 있다.
- 선생님으로서 거절 시 기본 메시지("스케줄이 꽉 차서 다음에 신청해주세요")가 채워져 한 번 클릭으로 거절할 수 있다.

### 선생님 (시간 제안)
- 선생님으로서 대안 시간을 제안할 때 주간 스케줄 UI에서 빈 슬롯을 최대 3개 클릭하여 선택할 수 있다.
- 선생님으로서 메모를 추가하여 학생에게 맥락을 전달할 수 있다.

### 선생님 (수강권)
- 선생님으로서 시간 확정 후 학생에게 수강권 제안을 보낼 수 있다.
- 선생님으로서 가격 입력 시 악기x레벨 가격표의 매칭 금액이 기본값으로 표시되어 클릭하면 바로 채워진다.
- 선생님으로서 학생별로 가격을 조정할 수 있다.
- 선생님으로서 입금 확인 버튼을 눌러 수강권을 발급할 수 있다.

### 선생님 (체험 설정)
- 선생님으로서 레슨 운영 설정에서 체험레슨 무료/유료를 선택할 수 있다.

## 수용 기준

### Phase 1: 통합 신청 폼 + 승인/거절
- [ ] TeacherDetailScreen에 새 선생님은 [레슨 신청], 이전 선생님은 [다시 시작하기] 버튼 1개씩 표시
- [ ] UnifiedLessonRequestScreen에서 체험/정규 선택, 악기, 목적, 경험수준, 희망시간(스케줄UI), 메모 입력 가능
- [ ] 이전 선생님일 때 이전 레슨 정보 프리필
- [ ] 희망 시간 선택 시 선생님 주간 스케줄에서 빈 슬롯만 표시 (다른 학생 정보 숨김)
- [ ] 신청 데이터가 UnifiedLessonRequest 엔티티로 저장
- [ ] 선생님에게 앱 내 알림 발송
- [ ] 선생님이 요청 목록에서 승인/거절 가능
- [ ] 거절 시 기본 메시지 프리필 + 커스텀 입력 가능
- [ ] 기존 LessonBookingScreen, LessonRequestScreen, BookingConfirmationScreen 삭제
- [ ] flutter analyze 에러 0

### Phase 2: 시간 협상
- [ ] 선생님이 대안 시간 최대 3개 제안 가능 (스케줄 UI에서 선택)
- [ ] 학생이 대안 중 1개 선택 또는 역제안 가능 (스케줄 UI에서 선택)
- [ ] 각 턴에 메모 첨부 가능
- [ ] 최대 3라운드(6턴) 후 미합의 시 만료 처리
- [ ] 협상 히스토리가 TimeProposal 리스트로 추적

### Phase 3: 수강권 연동
- [ ] 시간 확정 후 선생님이 수강권 제안 발송 가능
- [ ] 체험(무료) 시 시간 확정만으로 예약 완료
- [ ] 체험(유료)/정규 시 수강권 제안 → 학생 수락 → 결제 완료 알림 → 입금 확인 → 발급
- [ ] 기존 SubscriptionProposal 플로우 재사용

### Phase 4: 가격표
- [ ] 선생님 설정에 악기별 x 레벨별(초/중/고) 가격 매트릭스 입력 가능
- [ ] 학생 신청 시 매칭된 참고 가격 표시
- [ ] 수강권 제안 시 가격표 금액이 기본값으로 채워짐

### Phase 5: 대시보드 + 체험 설정
- [ ] 학생 대시보드에 선생님별 진행 상태 카드 표시
- [ ] 상태: 확인 중 / 대안 도착 / 수강권 도착 / 결제 대기
- [ ] 선생님 레슨 운영 설정에 체험레슨 무료/유료 토글

## 구현 결정 사항

### 엔티티 전략
- 기존 `LessonRequest` 엔티티를 확장하여 `UnifiedLessonRequest`로 발전 (instrument, goal, experience, timeProposals 필드 추가)
- 기존 `LessonGoal`, `ExperienceLevel` enum 재사용
- 시간 협상은 `TimeProposal` 리스트로 append-only 추적
- `LessonRequestStatus` enum 확장 (negotiating, timeConfirmed, proposalSent 등 추가)

### 화면 전략
- 3개 화면 삭제 → 1개 통합 화면(`UnifiedLessonRequestScreen`) 신규
- 선생님 요청 검토는 기존 `LessonRequestsScreen` 확장
- 시간 선택 UI는 기존 `schedule_weekly_grid_view.dart`의 읽기 전용 버전 재사용

### 가격 전략
- 학생마다 가격이 다르므로 가격표는 "참고 기본값"일 뿐, 선생님이 수강권 제안 시 최종 결정
- 가격표는 `TeacherSettings`에 `Map<String, Map<String, int>>` (악기 → 레벨 → 가격) 추가
- 체험레슨 무료 여부는 `TeacherSettings.isTrialFree` boolean

### 라우팅 전략
- `AppRoutes.lessonBooking` → 새 `UnifiedLessonRequestScreen`으로 교체
- `AppRoutes.lessonRequest` → 삭제, 통합 화면으로 대체
- 기존 라우트를 참조하는 모든 코드 업데이트

### 알림 전략
- Phase 1~5에서는 앱 내 알림만 사용
- FCM 푸시는 별도 프로젝트로 후속 구현
- 기존 `AppNotification` + `NotificationType` enum 확장

## 영향받는 모듈

### 삭제
- `features/schedule/presentation/screens/lesson_booking_screen.dart` (864줄)
- `features/schedule/presentation/screens/lesson_request_screen.dart` (452줄)
- `features/schedule/presentation/screens/booking_confirmation_screen.dart` (461줄)

### 신규 생성
- `features/schedule/domain/entities/unified_lesson_request.dart` — 통합 요청 엔티티 + TimeProposal
- `features/schedule/presentation/screens/unified_lesson_request_screen.dart` — 통합 신청 폼
- `features/schedule/presentation/screens/request_status_screen.dart` — 진행 상태 화면
- `features/schedule/presentation/widgets/schedule_slot_picker.dart` — 읽기 전용 스케줄 슬롯 선택 위젯

### 수정
- `features/search/presentation/screens/teacher_detail_screen.dart` — 버튼 2개 → 1개 + "다시 시작하기"
- `features/schedule/presentation/screens/lesson_requests_screen.dart` — 선생님 검토 UI 확장 (승인/거절/대안)
- `features/profile/presentation/screens/lesson_time_settings_screen.dart` — 체험 무료 토글 + 가격표
- `features/student_home/presentation/screens/student_dashboard_tab.dart` — 진행 상태 카드 섹션
- `core/router/routes/schedule_routes.dart` — 라우트 교체
- `core/router/app_routes.dart` — 라우트 상수 정리
- `features/notifications/domain/entities/notification.dart` — NotificationType 확장
