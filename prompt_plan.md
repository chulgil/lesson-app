# #216 레슨요청 개편: 홈 리스트 & 바텀시트 & 레거시 제거 — 구현 계획

> 확정일: 2026-03-29
> 범위: 홈 섹션 교체 + 리스트 아이템 + 바텀시트 개편 + 프로필 메뉴 + 레거시 삭제
> 복잡도: HIGH (~600줄 신규 + ~200줄 수정 + ~1500줄 삭제, 12개 파일)
> PAD: docs/specs/lesson_request_redesign_pad.md
> Issue: #216 (blocked by #215 ✅)

## Phase 구성

### Phase 1: 리스트 아이템 위젯 + 홈 섹션
**파일 3개 (신규 2 + 수정 1)**

1-1. `request_list_item.dart` 신규
```
features/schedule/presentation/widgets/request_list_item.dart
```
- 왼쪽: 타입 배지 (체험/정규/회차권/재수강)
- 가운데: 학원/개인 + 학생이름·악기·목표·레벨 + 최근 메시지 (3줄 truncate)
- 오른쪽: 상태 칩 (검정/error/success/warning)
- onTap → requestDetail 라우트

1-2. `lesson_request_section.dart` 신규
```
features/home/presentation/widgets/lesson_request_section.dart
```
- "레슨요청 (N)" 헤더 (_buildTodayLessonsHeader 패턴 참조)
- todayRequestsProvider 사용 (Phase 3에서 만든 것)
- 최대 3개 + "N개 요청 더보기" 버튼
- 0건 → 섹션 숨김

1-3. `dashboard_tab.dart` 수정
- UrgentActionsSection → LessonRequestSection 교체
- import 변경: lesson_request_providers → unified 프로바이더
- pendingRequestsAsync 제거 (더 이상 사용 안 함)

### Phase 2: 프로필 메뉴 + 바텀시트 개편
**파일 2개 수정**

2-1. `profile_tab.dart` 수정
- "레슨 운영" 그룹 첫 번째에 "레슨 요청 관리" 메뉴 추가
- icon: Icons.assignment, route: AppRoutes.lessonRequests

2-2. `decline_bottom_sheet.dart` 수정
- 고정 메시지 → 자유 입력 TextField (디폴트 텍스트 유지)
- 거절: 디폴트 "현재 가능한 시간이 없어 이번에는 어렵습니다."
- 대안 제안: 디폴트 "다른 시간을 제안드립니다"

### Phase 3: 레거시 제거
**파일 5개 삭제 + 참조 정리**

3-1. 삭제 대상:
- `domain/entities/lesson_request.dart`
- `presentation/widgets/lesson_request_card.dart`
- `presentation/widgets/lesson_request_list.dart`
- `presentation/providers/lesson_request_providers.dart` + `.g.dart`
- `home/presentation/widgets/urgent_actions_section.dart`

3-2. 참조 정리:
- `lesson_requests_screen.dart` — 레거시 섹션 제거, 통합 요청만 표시
- `my_lesson_requests_screen.dart` — 레거시 import 제거
- `schedule_routes.dart` — 레거시 import 정리

## 의존성

```
Phase 1 (위젯+홈) → Phase 2 (메뉴+바텀시트) → Phase 3 (레거시 삭제)
모두 순차 (삭제 전 대체 먼저)
```

## 검증 계획

```bash
flutter analyze           # 에러 0
flutter test test/features/schedule/  # 기존 테스트 통과
flutter run               # 홈화면 레슨요청 섹션 표시 확인
```

---

## 이전 계획

### #215 레슨요청 개편: 엔티티 & 상세화면 코어 (2026-03-29, ✅ 완료)

> Phase 1-6 모두 완료, 7개 커밋 push
