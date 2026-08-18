# AC Tree — group-lesson (P1+P2)

> 최종 갱신: 2026-07-31 (Phase 4 작성 — 전체 pending)
> Spec: `2026-07-31-group-lesson.md` | DAG: `decomposition-2026-07-31-group-lesson.md`

## AC-0 [group-lesson] 그룹레슨 P1+P2 전체 (pending)
- **설명**: 코호트 우선 그룹 클래스 운영 + 통합 수강권 실차감 + 운영 완성(마감·알림·노쇼·멤버)
- **만족 조건**: 모든 자식 AC passed
- **담당 job**: —

  ### AC-1 [BE 코어] GroupClass 배선 정합 (passed)
  - **만족 조건**: GroupClassSchedule→GroupClass 실참조 + alembic 실PG + 기존 회귀 0
  - **담당 job**: J1
  - **관련 테스트**: `backend/tests/test_group_class_wiring.py`

  ### AC-2 [구독] appliesTo + groupClassId (in_progress — J2 passed, 자식 AC-2.1 은 J5a 대기)
  - **만족 조건**: 필드 추가(null=universal 비파괴) + 그룹 템플릿 발급 가능
  - **담당 job**: J2
  - **관련 테스트**: `backend/tests/test_group_lesson_deduction.py::test_applies_to_migration_nondestructive` + `backend/tests/test_group_class_crud.py::test_issue_group_template`

    #### AC-2.1 [차감 검증] 범위 불일치 거부 (pending)
    - **만족 조건**: 1:1 전용권만 보유 시 그룹 차감 4xx
    - **담당 job**: J5a
    - **관련 테스트**: `test_group_lesson_deduction.py::test_one_to_one_only_rejected`

  ### AC-3 [클래스 CRUD] 생성·수정·비활성 + 반복 스케줄 (passed — BE 15/15 + FE 폼·목록 12/12)
  - **만족 조건**: API + ownership(타 교사 403) + 폼 화면(반 기본·드롭인 옵션) + **반 생성 시 N주 스케줄 자동 생성·수정 시 미래 회차 갱신**
  - **담당 job**: J3, J9a, J9b
  - **관련 테스트**: `backend/tests/test_group_class_crud.py` (`::test_regular_creates_recurring_schedules` 포함) + `frontend/test/features/schedule/group_class_form_screen_test.dart` (smoke)

  ### AC-4 [진입점] 고아 0 (pending)
  - **만족 조건**: 교사 홈→내 클래스 / 학생 아젠다 반 행 / 교사 상세 섹션 / 상세·출석 push 연결 + route_integrity 3곳
  - **담당 job**: J12
  - **관련 테스트**: `frontend/test/routing/all_routes_render_test.dart` (기존 게이트 확장)

  ### AC-5 [실차감] add_usage 단일 경로 + 노쇼 정책 집행 (passed — J5a PR #1281 + J5b)
  - **만족 조건**: 출석 확정→잔여 감소 + 멱등 + 선택 규칙(group→universal·만료임박 우선) + flag-only 제거 + **노쇼 집행 2축 정렬(2026-08-18 개정, 옵시디언 54): deductCredit=차감 / reschedule=차감+MakeupCredit 적립(쌍 회계) / noDeduction=무차감 / halfCredit=폐기(신규 400, 레거시 무차감)** + 결과 문구 알림(배치 경로 포함)
  - **담당 job**: J5a(차감 코어), J5b(노쇼 4분기)
  - **관련 테스트**: `backend/tests/test_group_lesson_deduction.py` (노쇼 4분기 케이스 포함)

  ### AC-6 [표시 정합] 개인레슨 폴백 0 (passed — branch ① 클래스명 실주입 한 줄은 J12 에서)
  - **만족 조건**: `groupClassId` 有→클래스명+그룹 배지 / 無+group→"그룹 수강권" 라벨. "개인레슨" 폴백 0건. **만료 임박 알림·카드에 수강권 종류 명시** (rev2 잔여이슈 1 해소)
  - **담당 job**: J13
  - **관련 테스트**: `frontend/test/features/subscription/group_subscription_display_test.dart` (두 표시 규칙 + 폴백 부재 + 만료 임박 종류 명시 케이스)

  ### AC-7 [DS 정리] 이모지 0건 (passed)
  - **만족 조건**: 그룹 화면 2종 이모지 0 (C8 raw alpha 는 범위 외 — 별도 백로그)
  - **담당 job**: J8
  - **관련 테스트**: eval `p1-6-no-emoji-in-group-screens` (rg 게이트)

  ### AC-8 [마감 집행] deadline 4xx (pending)
  - **만족 조건**: booking/cancel 마감 경과 시 4xx + 정책 메시지
  - **담당 job**: J6
  - **관련 테스트**: `backend/tests/test_group_deadline_enforcement.py`

  ### AC-9 [알림] 그룹 6종 BE emit (in_progress — 5종(J10) passed, 반 공지(J11a)·FE 타입 매핑(J12 편입) 대기)
  - **만족 조건**: 예약확정·리마인더(전일/당일)·오픈·노쇼경고(J10) + 반 공지 발행(J11a)
  - **담당 job**: J10, J11a
  - **관련 테스트**: `backend/tests/test_group_notifications.py`

    #### AC-9.1 [FE 오발화 금지] 로컬 알림 0 (pending)
    - **만족 조건**: 그룹 feature 코드에 FE 로컬 알림 스케줄링 0건 (#1191 패턴)
    - **담당 job**: J10, J12
    - **관련 테스트**: eval `p2-2-no-fe-local-notification` (rg 게이트)

  ### AC-10 [노쇼 정합] 4값 SSOT (passed — BE 실집행 증명은 AC-5/J5b 에서)
  - **만족 조건**: FE NoShowPolicy = BE 4값, 출석 화면서 정책별 동작
  - **담당 job**: J7
  - **관련 테스트**: `frontend/test/features/schedule/no_show_policy_test.dart`

  ### AC-11 [코호트 멤버] 배정·승인·정원 (pending)
  - **만족 조건**: 교사 배정 + 챗형 신청·승인 + 정원 초과 차단
  - **담당 job**: J4, J15
  - **관련 테스트**: `backend/tests/test_cohort_members.py` + `frontend/test/features/schedule/cohort_member_management_test.dart` (smoke + 배정 플로우)

  ### AC-12 [반 공지] TeacherAnnouncement scope (pending)
  - **만족 조건**: scope=class 발행 → 멤버만 수신. ClassNote 신설 0
  - **담당 job**: J11a, J11b
  - **관련 테스트**: `backend/tests/test_group_notifications.py::test_class_announcement_scope`

  ### AC-13 [예약 확인] 다이얼로그 (pending)
  - **만족 조건**: 드롭인 예약 전 확인(차감 수강권+마감·노쇼 명시) + 정책 박스 버튼 위
  - **담당 job**: J14
  - **관련 테스트**: `frontend/test/features/schedule/group_booking_confirm_test.dart`

  ### AC-14 [통합 게이트] 전체 스위트 (pending)
  - **만족 조건**: evals 9/9 + flutter analyze 0 + FE/BE 전체 스위트 green + architecture 테스트
  - **담당 job**: J16
  - **관련 테스트**: `python3 .harness/evals/run.py`
