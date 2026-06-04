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
| AC-M3 | 정산 (일괄 수금 → 강사 배분) + 미수금 리마인더 + 한 달 마감 워크플로우 + 세무사 export + 현금영수증 Year 1 보조 | 7-10일 | 3-4 라운드 (배분 정책 + 청구 시점 + 리마인더 SLA + 강사별 모드 혼합 + 마감 흐름) |
| AC-M4 | 베타 6개 학원 검증 | 외부 의존 (학원 모집·운영) | 학원 피드백 사이클 |
| AC-M5 | **운영 안전망** — 학원장 임시 권한 위임 + 학생 이탈 조기 신호 (출석/플래그) + 강사 휴가 신청·승인 + 공간 등록 + UTM 추적 MVP + 영업시간 자동 응답 + 강사 퇴직 신청 | 6-9일 | 3-4 라운드 (위임 권한 매트릭스 + 이탈 신호 임계치 + 휴가 정책 + 영업시간 정책) |
| AC-M6 | **운영 효율** — 무통장입금 fuzzy 매칭 (CSV/수기/OCR) + 강사 정산 모드 혼합 + trusted_substitute 매니저 영구 패턴 + 청구·정산 CSV 임포트 + 신규 학생 자동 슬롯 제안 | 5-7일 | 2-3 라운드 (매칭 알고리즘 신호 가중치 + 매니저 정책) |
| AC-M7 | **Insight** — 발표회 4단계 워크플로우 (기획→준비→진행→사후) + 코호트 분석 + 공간 활용도 heatmap + 강사 ROI + 학생 LTV + 학원 강사 대강 매칭 + 학생 인수인계 + 강사 평판 DB | 10-14일 | 4-6 라운드 (발표회 정책 + 코호트 분석 정의 + 활용도 KPI + 인수인계 흐름) |
| AC-M8 | **Growth** — 학부모 추천 시스템 + fraud 신호 + 보상 정책 + 채널별 LTV/CAC + 광고비 ROI + 카톡 채널 통합 | 6-8일 | 3-4 라운드 (보상 정책 + 부정 방지 정책 + 채널 분석 KPI) |
| AC-M9 | **외부 통합** — OCR 통장 캡처 + 카카오 BizMessage API + 자동 광고비 추적 (네이버/카카오 광고 API) + NTS 현금영수증 API | 8-12일 | 4-6 라운드 (외부 API 결정 + 비용 + 보안) |

각 라운드 = 사용자 검토 + 결정 1회. 마일스톤 간 의존성으로 직렬 진행 (AC-M1 모델 확정 후 AC-M2 시작 가능). AC-M5~M8 은 AC-M3 완료 후 우선순위에 따라 선택적 진행 (병렬 가능 — 학원장 결정 사이클 분리).

## 스펙

| 파일 | 범위 | 마일스톤 |
|---|---|---|
| [console_overview_spec.md](console_overview_spec.md) | 학원장 콘솔 전체 구조 (IA, 네비, 권한 격리, 컨텍스트 토글 요약) | AC-M1 |
| [context_toggle_spec.md](context_toggle_spec.md) | 학원장 ↔ 강사 컨텍스트 토글 (UX·JWT·권한 매트릭스·세션 격리·감사·엣지 케이스) | AC-M2 |
| [dashboard_spec.md](dashboard_spec.md) | 대시보드 KPI (월 매출, 학생 수, 출석률, 정산 진행) — 개별 노트 비공개 | AC-M1 |
| [teacher_management_spec.md](teacher_management_spec.md) | 강사 초대·수락·역할·퇴사·학생 이관 | AC-M2 / AC-M5 |
| [student_management_spec.md](student_management_spec.md) | 학생 등록·강사 매칭·대기 큐·이탈·노트 일시 접근 (2인 동의 + 90일) | AC-M2 / AC-M5 |
| [public_page_spec.md](public_page_spec.md) | `academy.lessonaza.app/{slug}` 공개 페이지 (강사 리스트·SEO·schema.org) | AC-M2 / AC-M5 |
| [billing_settlement_spec.md](billing_settlement_spec.md) | 청구·수금·강사 배분 정산 + 미수금 리마인더 + CSV 임포트 + 현금영수증 Year 1 보조 + 한 달 마감 워크플로우 + 세무사 export | AC-M3 / AC-M6 |
| [payment_matching_spec.md](payment_matching_spec.md) | 무통장입금 ↔ 학생 fuzzy 매칭 (수기 보조, 한국 가족 호칭/메모 코드 패턴) | AC-M3 / AC-M6 / AC-M9 |
| [announcements_spec.md](announcements_spec.md) | 학원 공지사항 (전체/강사/학부모 일괄 발송, 인앱+카톡) | AC-M3 / AC-M5 |
| [inbox_spec.md](inbox_spec.md) | 학부모 문의 인박스 (공개 페이지·lesson-app 수신 + 답변 SLA + 영업시간/야간 silent + 긴급 키워드) | AC-M3 / AC-M5 |
| [student_retention_signals_spec.md](student_retention_signals_spec.md) | 학생 이탈 조기 신호 6종 + 위험 점수 + 강사→학원장 플래그 채널 + 코호트 retrospective | AC-M5 / AC-M7 |
| [temporary_delegation_spec.md](temporary_delegation_spec.md) | 학원장 임시 권한 위임 (출장/병가) + 부분 권한 + 학원장 자동 복귀 감지 + audit | AC-M5 / AC-M6 |
| [parent_referral_spec.md](parent_referral_spec.md) | 학부모 추천 시스템 + 보상 정책 + fraud 7신호 + 학부모 랭킹 + ROI | AC-M8 (Growth 신규) |
| [acquisition_tracking_spec.md](acquisition_tracking_spec.md) | UTM 유입 채널 추적 + funnel + 채널별 LTV/CAC + 수기 광고비 ROI | AC-M5 / AC-M8 |
| [recital_workflow_spec.md](recital_workflow_spec.md) | 발표회 4단계 워크플로우 (기획→준비→진행→사후) + 학원장 모바일 진행 모드 + 영상 배포 | AC-M7 (Insight) |
| [teacher_absence_and_substitute_spec.md](teacher_absence_and_substitute_spec.md) | 학원 강사 휴가/대강 — 학원장 승인 + 내부 대강 매칭 + 페이 분배 + 무단 결근 페널티 | AC-M5 / AC-M7 |
| [teacher_offboarding_spec.md](teacher_offboarding_spec.md) | 강사 퇴직 + 학생 인수인계 — 퇴직 5유형 + NFR-A-5 권한 이양 + 인수인계 메모 + 최종 정산 + 평판 DB | AC-M5 / AC-M7 |
| [studio_utilization_spec.md](studio_utilization_spec.md) | 학원 공간 활용도 — 방 등록 + heatmap + 방별 ROI + 강사별 효율 + 빈 슬롯 모객 우선순위 + 자동 슬롯 제안 | AC-M5 / AC-M7 |
| [academy_schedule_authority_spec.md](academy_schedule_authority_spec.md) | 수강권 귀속(academy/teacher) + 강사 무조건 위임 + `AcademyActivityLog` 사후 가시성 + 수습 강사 onboarding + Privacy + 충돌 감지 + 마스터 스케줄 | AC-M2 / AC-M3 / AC-M5 |
| [teacher_cancellation_policy_spec.md](teacher_cancellation_policy_spec.md) | 강사 사유 변경/취소 정책 (12h 기준, 학생 변경권 자동 적립, 다음 레슨 추가 시간 안내, 페이 차감 없음) | AC-M3 / AC-M5 |
| [owner_bulk_closure_spec.md](owner_bulk_closure_spec.md) | 학원장 일괄 휴강 (C2 1h 유예 + 강사 의견 + Override + 보강 강사 위임) | AC-M3 / AC-M5 |

## 관련

- 가입 / 인증: [../auth/api_contract.md](../auth/api_contract.md)
- 선생님 프로필 (강사 본인 공개페이지): [../teacher/profile_spec.md](../teacher/profile_spec.md)
- 백엔드 모델 (예정): `Academy`, `AcademyMember`, `AcademyStudent`, `AcademyInvoice`, `AcademyPayment`, `AcademySubscription`, `AcademyActivityLog`, `AcademyCancellationPolicy`, `TeacherCancellationDefaults`, `TeacherLateCancelEvent`, `StudentCancellationCredit`, `AcademyClosure`, `AcademyClosureTeacherComment`, `AcademyClosureAffectedLesson`
- 옵시디언: `mybrain/10 Projects/레슨앱/22-academy-커뮤니케이션-스펙.md`, `23-academy-수강권귀속-강사변경권한-설계.md`
