# 통합 레슨 신청 v2.0 PAD

> **작성일**: 2026-03-28
> **관련 스펙**: `docs/specs/booking/unified_lesson_request_spec.md` (v2.0)
> **체크리스트**: `docs/specs/booking/unified_lesson_request_checklist.md`

---

## 문제 정의

현재 레슨 신청 플로우에 다음 문제가 있다:

1. **희망 일자 없음** — 요일+시간만 수집하여 "언제 첫 레슨인지" 알 수 없다
2. **1안 제출 → 평균 2-3회 메시지 교환** — 선생님-학생 간 시간 맞추기에 메신저보다 불편
3. **회차권 타입 부재** — 체험/정규 2개만 존재, 매번 예약하는 학생 대응 불가
4. **재수강 시 스케줄 정보 미표시** — 별도 `LessonRequest` 시스템에는 스케줄 피커가 없음
5. **3라운드 협상** — 과도하게 복잡하여 메신저 대비 장점이 사라짐
6. **신청 후 안내 부재** — "다음에 뭘 해야 하지?" 상태
7. **악기 1개 선생님도 악기 선택 UI 노출** — 불필요한 인지 부하

**핵심 목표**: 선생님과 학생이 메신저/구두로 여러 번 대화해서 스케줄을 확정하는 것을 앱이 더 편리하게 대체한다. 이 수순보다 복잡하거나 불편하면 안 된다.

---

## 솔루션 개요

**학생 3안 제출 → 선생님 1택 → 끝.** 90% 케이스에서 1라운드 확정.

- 3타입 통합 (체험/정규/회차권) → 하나의 폼에서 UI 전환
- 주간 캘린더 (이전/다음, 4주) + 클릭 순환 (❶❷❸) 으로 3안 선택
- 네이버 예약 벤치마크: 안내 메시지, 스텝 가이드, 소요시간, 취소 정책
- 재수강은 동일 폼 + 이전 일정 프리필 (기존 `LessonRequest` 시스템 폐기)
- 시간 협상 3라운드 → 2라운드 축소

---

## 유저 스토리

### 학생

- 학생으로서 **체험/정규/회차권 중 선택**하면 해당 타입에 맞는 날짜 선택 UI가 나타난다
- 학생으로서 **주간 캘린더에서 최대 3개 희망 시간**을 우선순위와 함께 제출하면 선생님이 가장 적합한 시간을 수락한다
- 학생으로서 **체험/회차권 신청 시 특정 날짜+시간**을 선택하면 정확한 일자가 전달된다
- 학생으로서 **정규레슨 신청 시 캘린더에서 날짜를 찍으면** "매주 X요일 Y시"로 자동 변환되어 전달된다
- 학생으로서 **재수강 시 이전 고정일자가 자동 선택**되어 있어 바로 제출할 수 있다
- 학생으로서 이전 시간이 불가하면 **"현재 불가합니다" 안내**를 받고 다른 시간을 선택한다
- 학생으로서 **신청 완료 후 5단계 가이드**를 보고 다음에 무엇이 일어나는지 안다
- 학생으로서 **선생님 안내 메시지**를 읽고 레슨 신청에 참고한다
- 학생으로서 **예상 레슨 시간과 취소 정책**을 폼에서 확인한다
- 학생으로서 악기가 1개인 선생님에게 신청하면 **악기 선택 없이** 바로 진행한다

### 선생님

- 선생님으로서 **학생의 3안을 한눈에 보고** 가장 적합한 시간을 수락한다
- 선생님으로서 **3안 모두 불가하면 역제안 3안**을 주간 캘린더에서 선택하여 보낸다
- 선생님으로서 **레슨 신청 안내 메시지를 커스텀**하여 학생에게 사전 안내한다
- 선생님으로서 안내 메시지를 설정하지 않으면 **디폴트 메시지**가 자동 표시된다

---

## 수용 기준

> 상세 체크리스트: `unified_lesson_request_checklist.md` (100+ 항목)

### 필수 (Must Have)

- [ ] 3타입 (체험/정규/회차권) SegmentedButton으로 전환 가능
- [ ] 주간 캘린더에 이전/다음 버튼, 4주 앞까지 표시
- [ ] 클릭 순환 (❶→❷→❸→초기화) 동작, 같은 요일+시간 중복 불가
- [ ] 캘린더 아래에 선택한 3안 리스트 항상 표시 (삭제 가능)
- [ ] 체험/회차권: 날짜 포함 표시, 정규: "매주 X요일" 형식
- [ ] 재수강 시 이전 일정 프리필 (불가 시 안내 메시지)
- [ ] 신청 완료 페이지: 5단계 수직 가이드 + 신청 요약 + 메인으로 가기
- [ ] 선생님 안내 메시지: 디폴트 제공 + 커스텀 가능 (TeacherSettings)
- [ ] 악기 1개 선생님: 악기 선택 UI 숨김 + 자동 매칭
- [ ] 시간 협상 최대 2라운드

### 선택 (Should Have)

- [ ] 예상 레슨 시간 표시 (60분)
- [ ] 취소/변경 정책 안내 표시
- [ ] 참고 가격 자동 매칭 (악기 × 경험 수준)
- [ ] 과거 날짜 비활성 처리
- [ ] 가용 슬롯 0개 시 안내 메시지

### 추후 (Nice to Have)

- [ ] FCM 푸시 알림
- [ ] 선생님 안내 메시지에 이미지 첨부
- [ ] 회차권 다회 예약 (첫 3회 한번에)

---

## 구현 결정 사항

### 데이터 모델

- `UnifiedLessonRequest`에 `PreferredTimeSlot` 리스트 추가 (1~3개)
- `PreferredTimeSlot`: 체험/회차는 `date` 사용, 정규는 `dayOfWeek` 사용
- `LessonRequestType` enum에 `perSession` 추가
- `TeacherSettings`에 `bookingGuidanceMessage` (String?, null이면 디폴트)
- `TimeProposal`의 `currentRound` 상한을 2로 변경
- 기존 `LessonRequest` 엔티티/레포: deprecated → 삭제

### 캘린더 위젯

- 기존 `ScheduleSlotPicker`를 `WeeklyCalendarPicker`로 교체
- 이전/다음 주 이동 + 날짜 인식 (기존은 요일만)
- 3안 선택 상태 관리: 위젯 내부 state로 `List<SelectedSlot>` (max 3)
- 4번째 클릭 시 전부 초기화 → 1부터 재시작

### 완료 페이지

- 새 화면 `RequestCompletionScreen` 생성
- `WillPopScope`로 뒤로가기 차단 (폼으로 돌아가기 방지)
- 5단계 `Stepper` 또는 커스텀 수직 리스트

### 정규레슨 날짜 처리

- 캘린더에서 날짜를 찍으면 내부적으로 `dayOfWeek` + `startTime`만 추출
- 시작일 정보는 UI에 표시하되 서버에는 요일+시간만 전송
- 선생님이 수강권 발급 시 시작일 결정

### Step 3 내부 분리

- 학생 화면: "시간 확정 후 입금" 하나로 표시
- 내부: timeConfirmed → proposalSent → proposalAccepted → paymentNotified

---

## 영향받는 모듈

### 프론트엔드

| 모듈 | 변경 | 내용 |
|------|------|------|
| `schedule/domain/entities/unified_lesson_request.dart` | MODIFY | `PreferredTimeSlot` 리스트, `perSession` 타입, 2라운드 |
| `schedule/domain/entities/lesson_request.dart` | DELETE | `UnifiedLessonRequest`로 통합 폐기 |
| `schedule/domain/repositories/` | MODIFY | 인터페이스/Mock/Remote 3안 지원 |
| `schedule/presentation/screens/unified_lesson_request_screen.dart` | MODIFY | 3타입 전환, 안내 메시지, 캘린더 교체, 완료 페이지 연결 |
| `schedule/presentation/screens/request_completion_screen.dart` | **NEW** | 5단계 가이드 + 요약 |
| `schedule/presentation/widgets/schedule_slot_picker.dart` | MODIFY→REPLACE | `WeeklyCalendarPicker` (이전/다음, 3안 선택) |
| `schedule/presentation/widgets/unified_request_card.dart` | MODIFY | 3안 표시 |
| `schedule/presentation/widgets/teacher_approval_card.dart` | MODIFY | 3안 중 선택 UI |
| `schedule/presentation/widgets/approval_bottom_sheet.dart` | MODIFY | 3안 수락/역제안 |
| `search/presentation/screens/teacher_detail_screen.dart` | MODIFY | 진입 파라미터 확장 |
| `settings/domain/entities/teacher_settings.dart` | MODIFY | `bookingGuidanceMessage` 필드 |
| `settings/presentation/screens/` | MODIFY | 안내 메시지 편집 UI |
| `core/router/routes/schedule_routes.dart` | MODIFY | 완료 페이지 라우트 추가 |

### 백엔드

| 모듈 | 변경 | 내용 |
|------|------|------|
| `models/schedule.py` | MODIFY | `preferred_slots` JSON 필드, `per_session` 타입 |
| `models/settings.py` | MODIFY | `booking_guidance_message` 필드 |
| `schemas/schedule.py` | MODIFY | `PreferredTimeSlot` 스키마 |
| `schemas/settings.py` | MODIFY | 안내 메시지 스키마 |
| `services/schedule_service.py` | MODIFY | 3안 처리 로직 |
| `api/v1/schedule.py` | MODIFY | 엔드포인트 파라미터 확장 |
| `api/v1/settings_api.py` | MODIFY | 안내 메시지 GET/PUT |
| `alembic/versions/` | **NEW** | 마이그레이션 (nullable 필드 추가) |

### 문서

| 파일 | 변경 | 내용 |
|------|------|------|
| `docs/specs/booking/unified_lesson_request_spec.md` | DONE | v2.0 완료 |
| `docs/specs/booking/unified_lesson_request_checklist.md` | DONE | 100+ 항목 |
| `docs/specs/booking/unified_lesson_request_v2_pad.md` | DONE | 본 문서 |
