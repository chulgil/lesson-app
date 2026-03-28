# 레슨요청 개편 — 전체 진행 상황

> 마지막 업데이트: 2026-03-29
> PAD: docs/specs/lesson_request_redesign_pad.md
> API 스펙: docs/specs/schedule/lesson_request_api_spec.md

## 이슈 상태

| 이슈 | 제목 | 상태 | 커밋 |
|------|------|------|------|
| #215 | 엔티티 & 상세화면 코어 | ✅ Closed | 7 |
| #216 | 홈 리스트 & 바텀시트 & 레거시 제거 | ✅ Closed | 4 |
| #217 | 전체 화면 (달력+필터) & API 스펙 | 🔧 In Progress | 3 |
| #218 | 학생 측 전체 (2차) | 🔧 In Progress | 2 |

## 완료 항목

### #215 (✅ Closed)
- [x] RequestEvent 엔티티 (HiveType 130-131)
- [x] UnifiedLessonRequest 수정 (package, academyId, isExpiredByDate)
- [x] Mock 10개 경계값 시나리오
- [x] Provider 리팩토링 (requestEventsProvider, todayRequestsProvider, cancel, modify)
- [x] 상세 화면 (CurrentRequestBox + RequestHistoryChat + RequestDetailScreen)
- [x] 라우팅 (/schedule/request/:id)

### #216 (✅ Closed)
- [x] LessonRequestSection (UrgentActionsSection 대체)
- [x] RequestListItem (타입 배지 + 상태 칩)
- [x] 프로필 "레슨 요청 관리" 메뉴
- [x] 바텀시트 디폴트 메시지 분기 (거절/제안)
- [x] AppStrings 다국어 대비 30+ 상수
- [x] 레거시 10개 파일 완전 삭제 (-3,775줄)

### #217 (🔧 진행 중)
- [x] RequestFilter 엔티티 (상태/기간/정렬/페이지네이션)
- [x] AllLessonRequestsScreen (달력+필터+정렬)
- [x] API 스펙 6개 엔드포인트 정의
- [ ] 무한 스크롤 페이지네이션 (서버 API 필요)
- [ ] 푸시 알림 + 만료 타이머 (서버 필요)

### #218 (🔧 진행 중)
- [x] studentTodayRequestsProvider
- [x] LessonRequestSection 학생용 (viewerRole 분기)
- [x] 학생 대시보드 통합
- [x] 시간 그리드 이름 마스킹 (hideStudentNames)
- [x] 레거시 배너/프로그레스 카드 삭제
- [x] my_lesson_requests_screen 통합 전용 전환
- [ ] 학생 전체 화면 라우팅 (AllLessonRequestsScreen 학생용)

## 세션 통계

- 총 커밋: 19개
- 신규 코드: ~3,500줄
- 삭제 코드: ~3,800줄 (순 -300줄)
- 테스트: 48개 신규 (186개 전체 통과)
- 신규 파일: 12개
- 삭제 파일: 11개
