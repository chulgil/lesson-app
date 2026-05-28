# academy/ — 학원 도구

> 도메인: `academy.lessonaza.app/{academy_slug}` (공개), `console.lessonaza.app` (콘솔)
> 요구사항 SSOT: 옵시디언 `mybrain/10 Projects/레슨앱/21-academy-요구사항.md`

## 컨테이너 분담

학원 데이터의 SoR(Source of Record) 는 백엔드. 두 컨테이너 + 모바일 앱은 같은 데이터를 다른 렌더링으로 표시한다.

| 컨테이너 | 경로 | 사용자 | 목적 | 시점 |
|---|---|---|---|---|
| `academy-renderer` (web) | `academy.lessonaza.app/{slug}` | 앱 미설치 외부 방문자 | SEO·schema.org 공개 학원 페이지 | AC-M2 (신설) |
| `academy-console` (web) | `console.lessonaza.app` | 학원장·강사 (인증 사용자) | 운영 콘솔 (대시보드/강사·학생 명단/정산) | AC-M1 (신설) |
| `lesson-app` 학원 뷰 | `/academies/:id` ([app_routes.dart:145](../../../../frontend/lib/core/router/app_routes.dart)) | 앱 기설치 학생/학부모 | 검색 결과의 학원 정보·강사 리스트 | **현재 존재** (mock 단계) |

> `lesson-app` 의 `AcademyDetailScreen` 은 선생님 검색 결과에서 `organizationId != null` 인 학원 소속 선생님의 학원 정보를 보기 위한 진입점이다. 학원이 콘솔에서 입력한 정보를 backend API 로 받아 표시한다 (선생님 검색 상세와 동일 패턴). AC-M2 작업 시 mock → remote 전환만 필요.

## 마일스톤 (Claude 기반 재산정)

> 기존 인간 풀타임 1인 기준 (~7주, ~6주) 폐기. Claude 코딩 기간 + 사용자 결정 사이클 라운드 수로 재산정.
> 핵심 병목: 코드 작성이 아니라 **사용자 요구사항 결정·검토 사이클 N라운드**.

| 마일스톤 | 산출물 | Claude 코딩 일수 | 사용자 결정 사이클 |
|---|---|---|---|
| AC-M1 | 도메인 모델 + 콘솔 MVP (대시보드, 강사/학생 명단) | 3-5일 | 2-3 라운드 (모델 확정 + IA 확정 + UX 점검) |
| AC-M2 | 공개페이지 + 컨텍스트 토글 + 강사 초대 흐름 | 4-6일 | 2-3 라운드 (분담·노출 정책 + 토글 UX + 초대 흐름) |
| AC-M3 | 정산 (일괄 수금 → 강사 배분) + 미수금 리마인더 + CSV 임포트 | 5-7일 | 3-4 라운드 (배분 정책 + 청구 시점 + 리마인더 SLA + CSV 포맷) |
| AC-M4 | 베타 6개 학원 검증 | 외부 의존 (학원 모집·운영) | 학원 피드백 사이클 |

각 라운드 = 사용자 검토 + 결정 1회. 마일스톤 간 의존성으로 직렬 진행 (AC-M1 모델 확정 후 AC-M2 시작 가능).

## 스펙

| 파일 | 범위 | 마일스톤 |
|---|---|---|
| [console_overview_spec.md](console_overview_spec.md) | 학원장 콘솔 전체 구조 (IA, 네비, 권한 격리, 컨텍스트 토글 요약) | AC-M1 |
| [context_toggle_spec.md](context_toggle_spec.md) | 학원장 ↔ 강사 컨텍스트 토글 (UX·JWT·권한 매트릭스·세션 격리·감사·엣지 케이스) | AC-M2 |
| [dashboard_spec.md](dashboard_spec.md) | 대시보드 KPI (월 매출, 학생 수, 출석률, 정산 진행) — 개별 노트 비공개 | AC-M1 |
| [teacher_management_spec.md](teacher_management_spec.md) | 강사 초대·수락·역할·퇴사·학생 이관 | AC-M2 / AC-M5 |
| [student_management_spec.md](student_management_spec.md) | 학생 등록·강사 매칭·대기 큐·이탈·노트 일시 접근 (2인 동의 + 90일) | AC-M2 / AC-M5 |
| [public_page_spec.md](public_page_spec.md) | `academy.lessonaza.app/{slug}` 공개 페이지 (강사 리스트·SEO·schema.org) | AC-M2 / AC-M5 |
| [billing_settlement_spec.md](billing_settlement_spec.md) | 청구·수금·강사 배분 정산 + 미수금 리마인더 + CSV 임포트 | AC-M3 / AC-M6 |
| [announcements_spec.md](announcements_spec.md) | 학원 공지사항 (전체/강사/학부모 일괄 발송, 인앱+카톡) | AC-M3 / AC-M5 |
| [inbox_spec.md](inbox_spec.md) | 학부모 문의 인박스 (공개 페이지·lesson-app 수신 + 답변 SLA) | AC-M3 / AC-M5 |
| [academy_schedule_authority_spec.md](academy_schedule_authority_spec.md) | 수강권 귀속(academy/teacher) + 강사 무조건 위임 + `AcademyActivityLog` 사후 가시성 + 수습 강사 onboarding + Privacy + 충돌 감지 + 마스터 스케줄 | AC-M2 / AC-M3 / AC-M5 |
| [teacher_cancellation_policy_spec.md](teacher_cancellation_policy_spec.md) | 강사 사유 변경/취소 정책 (12h 기준, 학생 변경권 자동 적립, 다음 레슨 추가 시간 안내, 페이 차감 없음) | AC-M3 / AC-M5 |
| [owner_bulk_closure_spec.md](owner_bulk_closure_spec.md) | 학원장 일괄 휴강 (C2 1h 유예 + 강사 의견 + Override + 보강 강사 위임) | AC-M3 / AC-M5 |

## 관련

- 가입 / 인증: [../auth/api_contract.md](../auth/api_contract.md)
- 선생님 프로필 (강사 본인 공개페이지): [../teacher/profile_spec.md](../teacher/profile_spec.md)
- 백엔드 모델 (예정): `Academy`, `AcademyMember`, `AcademyStudent`, `AcademyInvoice`, `AcademyPayment`, `AcademySubscription`, `AcademyActivityLog`, `AcademyCancellationPolicy`, `TeacherCancellationDefaults`, `TeacherLateCancelEvent`, `StudentCancellationCredit`, `AcademyClosure`, `AcademyClosureTeacherComment`, `AcademyClosureAffectedLesson`
- 옵시디언: `mybrain/10 Projects/레슨앱/22-academy-커뮤니케이션-스펙.md`, `23-academy-수강권귀속-강사변경권한-설계.md`
