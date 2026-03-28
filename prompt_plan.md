# #215 레슨요청 개편: 엔티티 & 상세화면 코어 — 구현 계획

> 확정일: (사용자 확인 대기)
> 범위: RequestEvent 신규 + UnifiedLessonRequest 수정 + 상세화면(지라 like) + Mock 10시나리오
> 복잡도: HIGH (~1200줄 신규 + ~300줄 수정, 8개 파일)
> PAD: docs/specs/lesson_request_redesign_pad.md
> Issue: #215 → blocks #216, #217, #218

## 요구사항 재정의

레슨요청을 지라 티켓처럼 관리하는 시스템의 **코어 레이어**를 구축한다:
1. `RequestEvent` 엔티티로 모든 협상 히스토리를 추적 (기존 `proposals` 대체)
2. `UnifiedLessonRequest` 수정 (package 타입, academyId, proposals 제거)
3. 상세 화면: 현재 요청 박스 + 카톡 스타일 히스토리 채팅
4. Mock 데이터 10개 경계값 시나리오

## 범위 챌린지

⚠️ **8개 파일 수정/생성 예상** — 범위 상한에 도달.

| 포함 (이번) | 제외 (Issue #216, #217) |
|------------|----------------------|
| ✅ RequestEvent 엔티티 | ❌ 홈 레슨요청 섹션 |
| ✅ UnifiedLessonRequest 수정 | ❌ 리스트 아이템 위젯 |
| ✅ Mock 데이터 10시나리오 | ❌ 전체 화면 (달력+필터) |
| ✅ Provider 리팩토링 | ❌ 프로필 메뉴 추가 |
| ✅ 상세 화면 (현재 박스+히스토리) | ❌ 레거시 제거 |
| ✅ 라우트 추가 (상세 화면만) | ❌ 바텀시트 개편 |

바텀시트 개편은 상세 화면에서 호출하지만, 기존 `DeclineBottomSheet`를 그대로 사용하고 #216에서 개편한다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                       request_detail_screen                     │
│  ┌───────────────────────────┐  ┌─────────────────────────────┐ │
│  │   current_request_box     │  │   request_history_chat      │ │
│  │  ┌─────────────────────┐  │  │  ┌───────────────────────┐  │ │
│  │  │ PreferredSlots 선택 │  │  │  │ 말풍선 (학생=왼쪽)    │  │ │
│  │  │ (재사용: approval   │  │  │  │ 말풍선 (선생님=오른쪽) │  │ │
│  │  │  bottom_sheet UI)   │  │  │  │ 날짜 구분선           │  │ │
│  │  ├─────────────────────┤  │  │  │ 타임스탬프            │  │ │
│  │  │ 메시지 표시         │  │  │  └───────────────────────┘  │ │
│  │  ├─────────────────────┤  │  └─────────────────────────────┘ │
│  │  │ [다른 제안] [수락]  │  │                                  │
│  │  └─────────────────────┘  │                                  │
│  └───────────────────────────┘                                  │
└───────────────────┬─────────────────────────────────────────────┘
                    │ reads
┌───────────────────▼─────────────────────────────────────────────┐
│              unified_lesson_request_providers                    │
│  requestEventsProvider(requestId) → List<RequestEvent>          │
│  unifiedRequestByIdProvider(requestId) → UnifiedLessonRequest   │
│  UnifiedLessonRequestActions (수락/거절/제안/수정/취소)           │
└───────────────────┬─────────────────────────────────────────────┘
                    │ reads/writes
┌───────────────────▼─────────────────────────────────────────────┐
│              domain entities                                     │
│  UnifiedLessonRequest (수정: +package, +academyId, -proposals)  │
│  RequestEvent (신규: actorType, eventType, slots, message)      │
│  TimeSlotOption (기존 유지)                                      │
│  PreferredTimeSlot (기존 유지)                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Phase 구성

### Phase 1: RequestEvent 엔티티 + UnifiedLessonRequest 수정 ✅
**파일 2개, ~250줄** (TDD 완료, 커밋 대기)

1-1. `request_event.dart` 신규 생성
```
features/schedule/domain/entities/request_event.dart
```
- `RequestEventType` enum (HiveType 130): initialRequest, approve, reject, proposeAlternative, counterPropose, acceptAlternative, cancel, expire, proposalSent, proposalAccepted, paymentNotified, completed
- `RequestEvent` class (HiveType 131): id, requestId, actorType(ProposerRole), actorId, eventType, suggestedSlots(List<TimeSlotOption>), selectedSlotIndex, message, createdAt
- fromJson/toJson/copyWith

1-2. `unified_lesson_request.dart` 수정
- `LessonRequestType` enum: `package` 추가 (HiveField 2)
- `UnifiedLessonRequest`: `academyId` 필드 추가 (HiveField 22)
- `UnifiedLessonRequest`: `proposals` 필드 deprecated → `events` 필드 추가 (HiveField 23, List<RequestEvent>)
- `currentRound` 상한 제거 (maxRounds 상수 삭제)
- `lastMessage` computed property 추가 (events에서 최신 메시지 추출)
- `isExpiredByDate` computed property (createdAt + 7일)

### Phase 2: Mock 데이터 10개 시나리오 ✅
**파일 1개, ~300줄** (TDD 완료, 커밋 대기)

2-1. `mock_unified_lesson_request_repository.dart` 전면 재작성
- 기존 8개 seed 삭제, 10개 경계값 시나리오 신규:

| # | 시나리오 | 타입 | 상태 | 이벤트 수 |
|---|---------|------|------|----------|
| 1 | 대기 중 (희망시간 3개) | regular | pending | 1 (초기요청) |
| 2 | 협상 중 라운드 3 | regular | negotiating | 6 (3왕복) |
| 3 | 오늘 완료 | regular | completed | 4 |
| 4 | 과거 완료 (어제) | trial | completed | 3 |
| 5 | 학생 취소 | regular | cancelled | 2 |
| 6 | 기간 만료 | regular | expired | 1 |
| 7 | 복수 악기 - 바이올린 | regular | pending | 1 |
| 8 | 복수 악기 - 피아노 | regular | negotiating | 4 |
| 9 | 회차권 + 정규 동시 | package | pending | 1 |
| 10 | 재수강 (학원) | regular(재수강) | negotiating | 3 |

- `RequestEvent` seed 데이터 포함 (각 시나리오별 히스토리)
- `getEventsByRequestId(String requestId)` 메서드 추가

### Phase 3: Provider 리팩토링 ✅
**파일 1개, ~150줄 수정** (TDD 완료 — 10/10 tests pass)

3-1. `unified_lesson_request_providers.dart` 수정
- `requestEventsProvider(requestId)` 신규 추가
- `todayRequestsProvider(teacherId)` 신규 (홈화면 리스트용 — 오늘 완료 포함, 대기 우선)
- `UnifiedLessonRequestActions` 수정:
  - 모든 액션에서 `RequestEvent` 생성 + 저장
  - `modifyLastAction(requestId)` 신규 (대기 중 수정)
  - `cancelRequest(requestId)` 신규
- `_invalidateProviders`에 `requestEventsProvider` 추가
- `build_runner` 재생성 필요

### Phase 4: 상세 화면 — current_request_box ✅
**파일 1개, ~200줄 신규** (구현 완료)

4-1. `current_request_box.dart` 신규 생성
```
features/schedule/presentation/widgets/current_request_box.dart
```
- Props: `UnifiedLessonRequest request`, `List<RequestEvent> events`, `String viewerRole`, callbacks
- 3가지 상태:
  - **내 차례**: 상대방 제안 표시 + 시간 선택 UI (approval_bottom_sheet에서 추출) + [다른 제안] [수락]
  - **상대 차례**: "김민준 학생의 응답을 기다리고 있습니다" + [수정] [취소]
  - **종료**: 최종 상태 메시지만 표시
- 시간 선택 UI: `_buildPreferredSlotsSection` 패턴 재사용 (unified_approval_bottom_sheet.dart:183-288)
- 1개 슬롯인 경우 자동 선택 상태

### Phase 5: 상세 화면 — request_history_chat ✅
**파일 1개, ~250줄 신규** (구현 완료)

5-1. `request_history_chat.dart` 신규 생성
```
features/schedule/presentation/widgets/request_history_chat.dart
```
- Props: `List<RequestEvent> events`, `String viewerId`, `String studentName`, `String? studentProfileUrl`
- `_buildChatBubble(RequestEvent event, bool isMyMessage)`:
  - 왼쪽(상대): 프로필 아바타 + 이름 + 말풍선
  - 오른쪽(나): 말풍선만 (프로필 없음)
- `_buildBubbleContent(RequestEvent event)`:
  - 상태 메시지 텍스트 (예: "다른 시간을 제안했습니다")
  - 시간 슬롯 카드 (최대 3개, 컴팩트)
  - 메시지 텍스트
- `_buildDateSeparator(DateTime date)`: "3월 25일 화요일"
- `_buildTimestamp(DateTime time)`: "오후 2:32"
- ListView.builder (역순 — 최신이 아래)

### Phase 6: 상세 화면 — request_detail_screen + 라우팅 ✅
**파일 2개, ~250줄 신규 + ~20줄 수정** (구현 완료)

6-1. `request_detail_screen.dart` 신규 생성
```
features/schedule/presentation/screens/request_detail_screen.dart
```
- Props: `String requestId`, `String viewerRole` (teacher/student)
- 상단: 학생/선생님 프로필 카드 (클릭 → 상세 이동)
  - 프로필 사진 + 이름 + 악기 + 목표 + 레벨
  - 재수강 시 이전 스케줄 표기
  - 타입 배지 (체험/정규/회차권/재수강)
  - 학원/개인 배지
- 본문: `CurrentRequestBox` + `RequestHistoryChat` (CustomScrollView)
- 액션 핸들러: 수락 → provider, 다른 제안 → 기존 DeclineBottomSheet(임시), 취소 → 확인 바텀시트

6-2. `app_routes.dart` 수정
- `static const requestDetail = '/schedule/request/:id'` 추가

6-3. `schedule_routes.dart` 수정
- `requestDetail` 라우트 등록 + GoRoute 설정

## 위험 요소

| 위험 | 수준 | 대응 |
|------|------|------|
| Hive TypeId 충돌 | MEDIUM | 130, 131 사용 — 기존 최대 129 확인 완료 |
| proposals → events 전환 시 기존 코드 깨짐 | HIGH | proposals를 deprecated로 유지, events와 병존 후 #216에서 레거시 제거 |
| 채팅 UI 스크롤 성능 | LOW | 이벤트 수가 무제한이지만, 7일 만료로 실질적 최대 ~20-30건 |
| build_runner 전체 빌드 필요 | LOW | 새 HiveType 추가 → `--delete-conflicting-outputs` 필수 |

## 검증 계획

```bash
# Phase 1 후
cd frontend && flutter analyze

# Phase 2 후
flutter run  # Mock 데이터 확인

# Phase 3 후
dart run build_runner build --delete-conflicting-outputs
flutter analyze

# Phase 6 후 (전체 검증)
flutter analyze
flutter run  # 상세 화면 진입 + 히스토리 표시 + 수락/제안 동작 확인
```

## 의존성

```
Phase 1 (엔티티) → Phase 2 (Mock) → Phase 3 (Provider)
                                           ↓
                            Phase 4 (현재 박스) ─→ Phase 6 (상세 화면)
                            Phase 5 (히스토리) ─→ Phase 6 (상세 화면)
Phase 4 & 5: 병렬 가능 ✓
```

## 완료 기준

- [ ] `flutter analyze` 경고 없음
- [ ] Mock 10개 시나리오 모두 상세 화면에서 정상 표시
- [ ] 히스토리 채팅: 말풍선 좌우 정렬 + 날짜 구분선 + 타임스탬프
- [ ] 현재 박스: 시간 선택 + 수락 동작
- [ ] 현재 박스: 대기 중 "응답 대기" 메시지 표시
- [ ] 라우팅: 상세 화면 진입/이탈 정상

---

## 이전 계획

### #211 과거 시간 선택 차단 (2026-03-28, ✅ 완료)

> 범위: 대안 시간 제안 + 메인 주간 스케줄에서 과거 셀 비활성화
> 복잡도: LOW (~23줄 수정, 2개 파일)

---

### 통합 레슨 신청 v2.0 (Cherry) — 2026-03-28, ✅ Phase 1-5 완료

> 범위: Cherry (3안 선택 엔진 + 완료 페이지 + 선생님 수락 UI)
> 복잡도: MEDIUM (~500줄 신규 + ~130줄 수정)

---

### Mock → Remote 전환 (2026-03-17, ✅ 완료)
