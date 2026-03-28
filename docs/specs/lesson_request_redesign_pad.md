# 레슨요청 시스템 전면 개편 PAD

> 작성일: 2026-03-29
> 상태: Draft

## 문제 정의

선생님 홈화면의 "즉시확인필요" 섹션과 레슨요청 관리 흐름에 6가지 핵심 문제가 있다:

1. **정보 과부하** — 즉시확인필요 섹션에 너무 많은 정보가 한꺼번에 노출되어 선생님이 진입 시 복잡하게 느낌
2. **건수 불일치** — 홈에서 "레슨요청 4건 대기"인데 요청 화면 진입 시 "대기중 2건"으로 표기 (레거시/통합 이중 시스템)
3. **과거/현재 UI 혼재** — 과거 요청과 현재 요청의 UI 구분이 불명확
4. **버튼 비일관성** — 상태에 따라 "다음에/수락", "대안시간제안" 등 버튼 체계가 통일되지 않음
5. **기능 중복** — "수락 후 역제안" 버튼과 "다음에 > 다른 스케줄 제안" 기능이 동일
6. **시간순 혼란** — 학생별이 아닌 시간순 정렬로 라운드 시간협상 시 맥락 추적 어려움

근본 원인: 레거시 `LessonRequest`와 `UnifiedLessonRequest` 이중 시스템이 공존하고, 협상 히스토리를 추적하는 전용 데이터 모델이 부재하며, 지라 티켓처럼 요청 단위로 상태를 추적하는 화면이 없음.

## 솔루션 개요

레슨요청을 **지라 티켓**처럼 개별 티켓 단위로 관리하는 시스템으로 전면 개편한다.

- 레거시 `LessonRequest` 완전 제거, `UnifiedLessonRequest` 단일 시스템으로 통합
- 협상 히스토리를 추적하는 `RequestEvent` 엔티티 신규 도입 (카카오톡 스타일 채팅 UI)
- 홈화면에 "오늘의 레슨"과 동일한 디자인의 "레슨요청" 섹션 배치
- 리스트 클릭 시 지라 상세와 같은 티켓 상세 화면으로 진입
- 전체 레슨요청 화면 (달력 + 기간/상태 필터 + 페이지네이션)
- 선생님/학생 양방향 대칭 UI (무제한 핑퐁 협상)

## 유저 스토리

### 선생님 (1차)

- 선생님으로서 홈화면에서 레슨요청 현황을 한눈에 파악하여 즉시 대응할 수 있다
- 선생님으로서 요청 리스트에서 타입(체험/정규/회차권/재수강), 학원/개인, 학생정보, 상태를 한 줄로 확인할 수 있다
- 선생님으로서 요청을 클릭하면 해당 티켓의 전체 협상 히스토리를 카톡처럼 시간순으로 볼 수 있다
- 선생님으로서 학생의 희망시간 중 하나를 선택해 수락하거나 다른 시간을 제안할 수 있다
- 선생님으로서 거절 시 사유를 메시지로 전달할 수 있다
- 선생님으로서 이미 보낸 제안을 수정하거나 요청을 취소할 수 있다
- 선생님으로서 전체 레슨요청 화면에서 달력 또는 필터로 과거 요청을 검색할 수 있다
- 선생님으로서 프로필 > 레슨 운영에서 전체 레슨요청 화면에 진입할 수 있다

### 학생 (2차)

- 학생으로서 홈화면에서 내가 보낸 레슨요청 현황을 확인할 수 있다
- 학생으로서 선생님의 제안을 수락하거나 다른 시간을 역제안할 수 있다
- 학생으로서 선생님의 스케줄(다른 학생 이름 비공개)을 보고 빈 시간을 찾아 제안할 수 있다
- 학생으로서 진행 중인 요청을 취소할 수 있다

## 수용 기준

### 데이터 모델
- [ ] 레거시 `LessonRequest` 엔티티, 프로바이더, 리포지토리, 위젯 완전 제거
- [ ] `UnifiedLessonRequest`에 `package` 타입 추가 (trial/regular/package)
- [ ] `UnifiedLessonRequest`에 `academyId` 필드 추가
- [ ] `UnifiedLessonRequest`에서 `proposals` 리스트 제거
- [ ] `RequestEvent` 엔티티 신규 생성 (actorType, eventType, suggestedSlots, selectedSlotIndex, message, createdAt)
- [ ] 무제한 핑퐁 — `currentRound` 상한 제거, 단순 카운터로 변경
- [ ] 7일 만료 — 생성일 기준 7일 경과 시 expired 처리

### 홈화면 레슨요청 섹션
- [ ] 기존 `UrgentActionsSection` 제거, "레슨요청 (N)" 섹션으로 교체
- [ ] "오늘의 레슨" 위에 배치
- [ ] 오늘일자 기준 상태 종료 변경일의 완료(취소/거절/만료 포함) + 진행중 표시
- [ ] 대기 중 우선, 그 다음 최신 요청순 정렬
- [ ] 최대 3개 표시, 3개 초과 시 "N개 요청 더보기" 버튼
- [ ] 0건일 때 섹션 자체 숨김
- [ ] 괄호 안 숫자는 전체 건수

### 리스트 아이템
- [ ] 왼쪽: 타입 표기 (체험레슨/정규레슨/회차권, 재수강은 정규 대신 "재수강" 표시)
- [ ] 가운데 1라인: 학원명 또는 "개인" (academyId 유무로 판단)
- [ ] 가운데 2라인: 학생이름 + 악기 + 목표 + 레벨
- [ ] 가운데 3라인: 최근 메시지 (없으면 빈 공간, 최대 3줄 truncate)
- [ ] 오른쪽: 상태 칩 — 기본 검정, error(입금완료), success(완료), warning(취소/보류/만료)

### 상세 화면 (지라 like)
- [ ] 상단: 학생 프로필(클릭 시 학생 상세 이동) + 이름 + 악기 + 목표 + 레벨
- [ ] 상단: 재수강인 경우 이전 스케줄 표기
- [ ] 현재 레슨요청 박스: 상대방의 최근 미응답 제안만 표시
- [ ] 현재 박스 — 희망시간 선택(1개면 선택상태) + 메시지 + "다른 제안" / "수락" 버튼
- [ ] 현재 박스 — 내가 응답 완료 시 "상대방 응답 대기 중" 메시지 + 수정/취소 액션
- [ ] 취소 시 바텀시트 안내 메시지, 동시 종료 시 서버 상태 우선 갱신
- [ ] 히스토리 박스: 카카오톡 스타일 말풍선 (내가 항상 오른쪽)
- [ ] 말풍선 내용: 상태 메시지 + 제안 시간(최대 3개) + 메시지
- [ ] 학생 최초 요청도 첫 번째 말풍선으로 표시
- [ ] 타임스탬프: 말풍선 아래 시간 + 날짜 구분선 (카카오톡 패턴)

### "다른 제안" 바텀시트
- [ ] 메시지 입력창으로 변경 (고정 메시지 제거)
- [ ] 거절 경로: 디폴트 "현재 가능한 시간이 없어 이번에는 어렵습니다." → 전송
- [ ] 대안 시간 경로: 디폴트 "다른 시간을 제안드립니다" → 시간 그리드 이동
- [ ] 시간 그리드: 선생님/학생 공유 (학생에게는 다른 학생 이름 숨김)

### 전체 레슨요청 화면
- [ ] 스케줄 화면과 동일한 달력 UI (요청 있는 날 점 표시)
- [ ] 달력 날짜 클릭 → 해당일 생성 요청만 표시 (과거 완료 포함)
- [ ] 필터 영역: 기간(일주일/한달/세달/직접입력) + 상태 + 검색 버튼
- [ ] 달력 클릭과 필터 검색은 배타적
- [ ] 기간 직접 수정 시 셀렉트박스 "직접입력" 상태로 변경
- [ ] 정렬: 시간순(요청 생성시간) / 이름순(학생 가나다) 셀렉트박스
- [ ] 20개 단위 스크롤 페이지네이션
- [ ] "N개 요청" 동적 건수 표시

### 프로필 메뉴
- [ ] "레슨 운영" 그룹, "정책 관리" 위에 "레슨 요청 관리" 메뉴 추가
- [ ] 클릭 시 전체 레슨요청 화면(오늘 날짜 선택 상태)으로 이동

### 진입 경로
- [ ] 홈 "N개 요청 더보기" → 전체 화면 (오늘)
- [ ] 프로필 "레슨 요청 관리" → 전체 화면 (오늘)
- [ ] 기존 urgent_actions 경로 → 전체 화면 (오늘)

### 알림 & 만료
- [ ] 상대방 액션 시 푸시 알림 발송
- [ ] 만료 24시간 전 알림
- [ ] 화면 진입 시 또는 푸시 수신 시 데이터 갱신 (WebSocket 미사용)
- [ ] 프론트: 타이머 기반 만료 표시, 서버: 배치 만료 처리

### API 스펙
- [ ] 레슨요청 목록 API (페이지네이션 20개, 정렬, 필터)
- [ ] 레슨요청 상세 API (RequestEvent 포함)
- [ ] 레슨요청 액션 API (수락/다른제안/거절/취소/수정)
- [ ] 달력 날짜별 요청 건수 API
- [ ] 만료 배치 API

## 구현 결정 사항

### 데이터 모델
- `UnifiedLessonRequest` 단일 시스템 — `LessonRequest` 레거시 완전 제거
- `RequestEvent`로 모든 상태 변경 히스토리 추적 — 기존 `proposals` 리스트 대체
- 요청 타입: `trial` / `regular` / `package` + `isReturningStudent` 플래그
- 학원 구분: `academyId` 유무로 판단
- 학생 정보는 별도 조회 (비정규화 없음)

### 상태 머신
- 무제한 양방향 핑퐁 — 선생님/학생 모두 "수락/다른 제안/취소" 가능
- 7일 만료: 생성일 기준, 서버 배치 + 프론트 타이머 병행
- "다른 제안" 바텀시트 안에 거절(메시지만 전달) 경로 포함
- 대기 중에도 마지막 제안 수정/취소 가능
- 동시 수정 시 서버 상태 우선

### UI 패턴
- 홈 리스트: "오늘의 레슨" 섹션과 동일한 디자인 언어
- 상세 화면: 현재 박스(미응답 제안만) + 히스토리 박스(채팅형) 2단 구조
- 히스토리: 카카오톡 패턴 — 내가 항상 오른쪽, 타임스탬프+날짜 구분선
- 상태 칩: 3색(검정 기본 / error 입금완료 / success 완료 / warning 취소·보류·만료)
- 시간 그리드: 선생님/학생 공유, 학생에게 다른 학생 이름만 숨김

### 선생님/학생 화면 대칭
- 동일한 상세 화면 구조, 히스토리 좌우만 뷰어 기준 반전
- 시간 그리드 UI 공유 (데이터 필터링만 다름)
- 학생 측은 2차 구현

### 갱신 전략
- WebSocket 미사용, 게시판 댓글 알고리즘
- 화면 진입 시 + 푸시 알림 수신 시 갱신
- 전체 화면: 20개 단위 무한 스크롤

## 영향받는 모듈

### 제거
- `features/schedule/domain/entities/lesson_request.dart` — 레거시 엔티티
- `features/schedule/presentation/widgets/lesson_request_card.dart` — 레거시 카드
- `features/schedule/presentation/widgets/lesson_request_list.dart` — 레거시 리스트
- `features/schedule/presentation/providers/lesson_request_providers.dart` — 레거시 프로바이더
- `features/home/presentation/widgets/urgent_actions_section.dart` — 즉시확인 섹션

### 신규 생성
- `features/schedule/domain/entities/request_event.dart` — 히스토리 이벤트 엔티티
- `features/schedule/presentation/screens/request_detail_screen.dart` — 티켓 상세 (지라 like)
- `features/schedule/presentation/screens/all_requests_screen.dart` — 전체 요청 화면 (달력+필터)
- `features/schedule/presentation/widgets/request_list_item.dart` — 새 리스트 아이템
- `features/schedule/presentation/widgets/request_history_chat.dart` — 채팅형 히스토리
- `features/schedule/presentation/widgets/current_request_box.dart` — 현재 요청 박스
- `features/home/presentation/widgets/lesson_request_section.dart` — 홈 레슨요청 섹션

### 리팩토링
- `features/schedule/domain/entities/unified_lesson_request.dart` — 타입 추가, academyId, proposals 제거
- `features/schedule/presentation/providers/unified_lesson_request_providers.dart` — RequestEvent 연동
- `features/schedule/presentation/widgets/decline_bottom_sheet.dart` — 메시지 입력창 변경
- `features/schedule/presentation/screens/suggest_alternative_screen.dart` — 학생 공유, 이름 숨김
- `features/schedule/presentation/widgets/unified_request_card.dart` — 일부 재사용 리팩토링
- `features/home/presentation/widgets/dashboard_tab.dart` — 섹션 교체 + 순서 변경
- `features/profile/presentation/screens/profile_tab.dart` — 메뉴 추가
- `core/router/app_routes.dart` — 라우트 추가

### 구현 순서

**1차 (선생님)**
```
Phase 1: 엔티티 & Mock (RequestEvent, UnifiedLessonRequest 수정, Mock 10개 시나리오)
Phase 2: 홈 리스트 섹션 (lesson_request_section + request_list_item)
Phase 3: 상세 화면 (request_detail_screen + current_request_box + request_history_chat)
Phase 4: 바텀시트 개편 (decline_bottom_sheet + suggest_alternative_screen 메시지 입력창)
Phase 5: 전체 화면 (all_requests_screen — 달력 + 필터 + 페이지네이션)
Phase 6: 프로필 메뉴 + 라우팅 + 레거시 제거
Phase 7: API 스펙 정의
```

**2차 (학생)**
```
Phase 8: 학생 홈 레슨요청 섹션
Phase 9: 학생 상세 화면 (좌우 반전 + 취소 버튼)
Phase 10: 학생 전체 화면 (달력 + 필터)
Phase 11: 시간 그리드 학생 공유 (이름 숨김)
```
