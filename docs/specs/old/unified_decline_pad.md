# 통합 거절/일정조율 바텀시트 PAD

## 문제 정의

선생님이 레슨 요청을 거절할 때 사용하는 UI가 4곳에 흩어져 있다:
- 레슨 요청 카드: "다음에" → AlertDialog (텍스트 입력)
- 통합 레슨 신청: "거절" → AlertDialog (텍스트 입력)
- 체험레슨 승인시트: "거절하기" → 3개 사유 리스트 → 대안 시간 선택
- 통합 승인시트 역제안: 주간 캘린더 → 대안 시간 선택

각각 다른 제목, 라벨, 플로우를 사용하여 UX 일관성이 떨어진다.
실제 사용의 95%가 "완전 거절"이 아닌 "일정 조율"임에도 불구하고, UI는 "거절"을 메인 프레이밍으로 사용한다.

## 솔루션 개요

모든 거절/일정조율 진입점에서 동일한 2단계 플로우를 사용하는 공통 컴포넌트를 만든다.
"거절" 대신 "이 시간에 레슨이 어렵습니다"로 프레이밍하여 95%인 일정 조율에 최적화한다.
바텀시트는 결과만 반환하고(콜백 패턴), 호출자가 상황에 맞는 API를 호출한다.

## 유저 스토리

- 선생님으로서 레슨 요청에 대해 **메시지만 전달**(거절)하면, 학생에게 거절 사유가 전달된다
- 선생님으로서 레슨 요청에 대해 **다른 시간을 제안**하면, 주간 스케줄에서 빈 시간을 탭하여 최대 3개 대안을 제안할 수 있다
- 선생님으로서 대안 시간 제안 시 **기존 수업이 보이는 주간 그리드**에서 빈 칸을 탭하면, 레슨 길이가 자동 적용된 시간이 제안 목록에 추가된다
- 선생님으로서 제안된 시간을 **수정**(날짜피커 + 시간피커)하거나 **삭제**할 수 있다
- 선생님으로서 이미 수업이 있는 시간에 제안하려 하면, **중복 경고**가 표시된다
- 학생으로서 선생님의 대안 시간 제안을 받으면, 하나를 **수락**하거나 **2라운드 조율**을 요청할 수 있다
- 선생님/학생으로서 어떤 화면에서든 거절 플로우의 **제목, 라벨, 동작이 동일**하다

## 수용 기준

- [ ] 1단계 바텀시트: 제목 "이 시간에 레슨이 어렵습니다" + 디폴트 메시지 텍스트필드 + 2 CTA
- [ ] "메시지만 전달" 탭 시 메시지와 빈 시간 목록 반환
- [ ] "다른 시간 제안" 탭 시 2단계 화면으로 이동 (메시지 전달)
- [ ] 2단계 주간 그리드에 기존 수업이 악기색상으로 표시됨
- [ ] 빈 칸 탭 시 학생 예약 기준 레슨 길이로 TimeSlot 자동 생성
- [ ] 최대 3개 시간 제안 가능, 3개 도달 시 그리드 탭 비활성
- [ ] 각 제안 시간 수정(DatePicker + TimePicker) 및 삭제 가능
- [ ] 기존 수업과 시간 겹침 시 SnackBar 경고
- [ ] 4곳 호출자 모두 동일 바텀시트 사용
- [ ] 체험레슨/통합 신청/레거시 요청 모두 동일 라벨
- [ ] UnavailableReason enum 삭제, 자유 텍스트로 대체
- [ ] unavailable_bottom_sheet.dart 삭제
- [ ] counter_propose_bottom_sheet.dart 삭제
- [ ] flutter analyze 에러 0건

## 구현 결정 사항

| 결정 | 값 | 근거 |
|------|-----|------|
| 프레이밍 | "이 시간에 레슨이 어렵습니다" | 95%가 일정 조율이므로 "거절" 워딩 부적절 |
| 사유 입력 | 자유 텍스트 + 디폴트 메시지 | 카테고리 분류 불필요 (숨고/크몽 참고) |
| API 연동 패턴 | 콜백 (바텀시트는 결과만 반환) | 호출자마다 다른 API 호출 필요 |
| 시간 선택 UI | 주간 스케줄 그리드 (빈 칸 탭) | 기존 수업 맥락 파악 + 직관적 |
| 레슨 길이 | 학생 예약 시 확정된 durationMinutes | 예약 단계에서 30/45/60분 결정됨 |
| 최대 제안 수 | 3개 | 기존 3안 선택 패턴과 일관 |
| 중복 체크 | 클라이언트: 기존 수업. 이중 제안: 향후 서버 | 먼저 수락한 쪽이 가져가는 방식 |
| 수기 수정 | DatePicker + TimePicker 기존 UI 재활용 | 새 UI 불필요 |
| 조율 라운드 | 최대 2라운드 | 현행 유지 |
| 라벨 | 모든 상황 동일 | 상황별 분기 불필요 (인터뷰 확인) |
| "직접 시간 추가" | 삭제 | 그리드 탭 + 수기 수정으로 대체 |

## 영향받는 모듈

- **decline_bottom_sheet.dart** (신규): 1단계 바텀시트 — 메시지 입력 + 2 CTA
- **suggest_alternative_screen.dart** (신규): 2단계 전체 화면 — 주간 그리드 + 시간 제안 목록
- **lesson_booking.dart**: UnavailableReason enum 삭제 → `unavailableMessage: String?`
- **booking_repository.dart** + Mock: `markUnavailable` 시그니처 변경 (enum → String)
- **booking_facade.dart**: 같은 시그니처 변경
- **booking_providers.dart**: 같은 시그니처 변경
- **remote_booking_repository.dart**: JSON 파싱 변경
- **approval_bottom_sheet.dart**: `_handleReject` → `showDeclineBottomSheet()` 호출
- **lesson_request_card.dart**: `_showDeclineDialog` → `showDeclineBottomSheet()` 호출
- **lesson_requests_screen.dart**: `_handleReject` + `onProposeAlternatives` → `showDeclineBottomSheet()` 호출
- **unavailable_bottom_sheet.dart** (삭제): 통합 바텀시트로 대체
- **counter_propose_bottom_sheet.dart** (삭제): 통합 바텀시트로 대체
