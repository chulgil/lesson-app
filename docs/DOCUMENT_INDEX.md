# Document Index

> 최종 업데이트: 2026-05-02
> 목적: 사람이 전체 문서 구조를 파악하기 위한 인덱스
> AI 작업 지시용: **[SPEC_ROUTING.md](SPEC_ROUTING.md)** 참조
> 정리: 2026-05-02 — old/ + 대용량 히스토리 → _archive/ 이동 (177→88개, 87K→40K줄)

---

## 마스터 문서 (SSOT)

각 도메인의 마스터 문서는 해당 도메인의 **모든 하위 스펙을 통합**한 단일 진실 소스입니다.

| 도메인 | 마스터 문서 | 핵심 내용 |
|--------|-----------|----------|
| 디자인 시스템 | [notebook/README.md](specs/design/notebook/README.md) | Notebook × Score 디자인 시스템 (**SSOT**) |
| 레슨 | [lesson_master.md](specs/lesson/lesson_master.md) | 레슨 CRUD, 예약, 취소, 노트, 3자 관계 |
| 수강권 | [subscription_master.md](specs/subscription/subscription_master.md) | 수강권 발급, 결제 확인, 정책 |
| 스케줄 | [schedule_master.md](specs/schedule/schedule_master.md) | 캘린더, 가용시간, 스케줄 확인 카드 |
| 캘린더 | [calendar_master.md](specs/calendar/calendar_master.md) | 주간/월간 캘린더 UI |
| 연습 | [practice_master.md](specs/practice/practice_master.md) | 레퍼토리, 녹음, 리포트, 연습 목표 |
| 사용자 | [user_master.md](specs/user/user_master.md) | 회원가입, 역할, 학부모 시스템 |
| 알림 | [notification_master.md](specs/notification/notification_master.md) | 알림 유형, 푸시 설정 |
| 온보딩 | [onboarding_master.md](specs/onboarding/onboarding_master.md) | 온보딩 플로우 |
| 메트로놈 | [metronome_master.md](specs/metronome/metronome_master.md) | 메트로놈 기능, 쉼표 패턴 |
| 팔로우 | [follow_master.md](specs/follow/follow_master.md) | 소식 구독 (초대는 `lesson/invite/` 참조) |
| 설정 | [settings_master.md](specs/settings/settings_master.md) | 앱 설정, 녹음 관리 |
| 학생 홈 | [student_home_master.md](specs/student_home/student_home_master.md) | 학생 앱 홈 화면 |

### 스펙 ↔ 코드 도메인 매핑

> 스펙 디렉토리 이름(단수)과 코드 도메인 이름(복수)이 다른 경우가 있음

| 스펙 디렉토리 | 코드 도메인 (`features/`) | 비고 |
|:------------|:------------------------|:-----|
| `specs/lesson/` | `features/lessons/` | 단수↔복수 |
| `specs/student/` | `features/students/` | 단수↔복수 |
| `specs/notification/` | `features/notifications/` | 단수↔복수 |
| `specs/metronome/`, `specs/practice/` (tuner) | `features/practice/` | 메트로놈/튜너는 연습 도메인 하위 |
| `specs/user/` (auth+invite+review+trial 통합) | `features/auth/`, `features/invite/`, `features/profile/` | 1 스펙 → 다수 도메인 |
| `specs/gamification/` | `features/gamification/` | gamification_master.md |
| `specs/home/` | `features/home/` | home_master.md |
| `specs/relationship/` | `features/relationship/` | relationship_master.md |
| `specs/profile/` | `features/profile/` | profile_master.md |
| (마스터 스펙 없음) | `features/analytics/` | lesson_master에서 언급 |

---

## 크로스 도메인 문서

| 문서 | 역할 | 언제 참조? |
|------|------|----------|
| [glossary.md](specs/glossary.md) | 용어 사전 (프로젝트 전체 용어 정의) | 용어 혼동 시, 새 기능 스펙 작성 시 |
| [feature_hub.md](specs/feature_hub.md) | 기능 허브 (기능 간 연결 맵) | 기능 의존성 파악, 영향 범위 분석 시 |
| [tech_decision.md](specs/tech_decision.md) | 기술 결정 사항 | 기술 스택 선택 근거 확인 시 |

---

## 화면 설계 문서

| 문서 | 역할 | 언제 참조? |
|------|------|----------|
| [notebook/README.md](specs/design/notebook/README.md) | **Notebook × Score 디자인 시스템 (최신 SSOT)** | UI 구현 시 |
| [ux_guidelines.md](specs/design/ux_guidelines.md) | UX 원칙, 상호작용 패턴 | UI 구현 판단 시 |
| [detail_screen_template.md](specs/design/detail_screen_template.md) | 상세 화면 공통 템플릿 | 새 상세 화면 추가 시 |
| [notebook/home_screens_audit.md](specs/design/notebook/home_screens_audit.md) | 홈화면 감사 결과 + 타이포 위계 규칙 | 홈화면 수정 시 |

---

## 요구사항 & 로드맵

| 문서 | 역할 |
|------|------|
| [implementation_roadmap_v2.md](specs/dev/implementation_roadmap_v2.md) | 6단계 구현 로드맵 (최신) |
| [beta_readiness.md](specs/dev/beta_readiness.md) | 베타 준비 상태 |
| [test_scenarios.md](specs/dev/test_scenarios.md) | 테스트 시나리오 |
| [test_data.md](specs/dev/test_data.md) | 테스트 데이터 |
| [requirement.md](requirement/requirement.md) | ⚠️ HISTORICAL — 2025-12 기준, SSOT는 각 도메인 마스터 |

---

## 도메인별 활성 스펙 (마스터 외)

> 마스터에 통합된 56개 개별 스펙은 old/로 이동됨 (2026-04-15)

### 레슨 (specs/lesson/) — 마스터 + 6개

| 문서 | 내용 | 비고 |
|------|------|------|
| [group_lesson_spec.md](specs/lesson/group_lesson_spec.md) | 그룹 레슨 | 마스터 미통합 (복잡) |
| [three_party_relationship_spec.md](specs/lesson/three_party_relationship_spec.md) | 3자 관계 (학원) | 마스터 미통합 (복잡) |
| [Unified_Lesson_Booking_Spec.md](specs/lesson/Unified_Lesson_Booking_Spec.md) | 통합 레슨 예약 | 활성 참조 |
| [assignment_dashboard_spec.md](specs/lesson/assignment_dashboard_spec.md) | 과제 대시보드 | 최근 구현 |
| [quick_add_lesson.md](specs/lesson/quick_add_lesson.md) | 빠른 레슨 추가 | 설계 중 |
| [flow_test_checklist.md](specs/lesson/flow_test_checklist.md) | 플로우 테스트 체크리스트 | 테스트용 |

### 연습 (specs/practice/) — 마스터 + 2개

| 문서 | 내용 |
|------|------|
| [practice_screen_spec.md](specs/practice/practice_screen_spec.md) | 연습 화면 스펙 |
| [backup_implementation_spec.md](specs/practice/backup_implementation_spec.md) | 백업 구현 |

### 수강권 (specs/subscription/) — 마스터 + 5개

| 문서 | 내용 | 비고 |
|------|------|------|
| [subscription_schedule_change_ux_spec.md](specs/subscription/subscription_schedule_change_ux_spec.md) | 스케줄 변경 UX | 2026-04 활성 |
| [subscription_schedule_management_spec.md](specs/subscription/subscription_schedule_management_spec.md) | 스케줄 관리 | 2026-04 활성 |
| [subscription_renewal_spec.md](specs/subscription/subscription_renewal_spec.md) | 수강권 갱신 | 설계 중 |
| [lesson_policy_settings.md](specs/subscription/lesson_policy_settings.md) | 레슨 정책 설정 | 설계 중 |
| [privacy_policy.md](specs/subscription/privacy_policy.md) + [terms_of_service.md](specs/subscription/terms_of_service.md) | 법적 문서 | 출시 필수 |

### 스케줄 (specs/schedule/) — 마스터 + 10개

| 문서 | 내용 |
|------|------|
| [teacher_availability_spec.md](specs/schedule/teacher_availability_spec.md) | 선생님 가용시간 |
| [chat_guide_message_spec.md](specs/schedule/chat_guide_message_spec.md) | 챗 가이드 메시지 |
| [lesson_lifecycle_chapters.md](specs/schedule/lesson_lifecycle_chapters.md) | 레슨 라이프사이클 |
| [lesson_request_api_spec.md](specs/schedule/lesson_request_api_spec.md) | API 스펙 |
| 기타 6개 | 장소관리, 이동시간, 빠른선택, 확인카드, 가용시간 리디자인, 뷰 UX |

### 기타 활성 도메인

| 도메인 | 파일 수 | 주요 파일 |
|--------|:------:|----------|
| design/ | 11개 | 마스터 + UX 가이드 + 경쟁분석 + 화면설계 + 템플릿 |
| user/ | 5개 | 마스터 + 학부모(3) + 선생님 등록 |
| metronome/ | 2개 | 마스터 + AVAudioEngine 가이드 |
| notification/ | 3개 | 마스터 + 시스템 스펙 + Firebase 가이드 |
| profile/ | 4개 | 마스터 + 사진업로드 + 이미지 + 선생님 편집 |
| student/ | 2개 | 클래스 시스템 + 일일 레슨 시간 |
| booking/ | 2개 | 통합 예약 스펙 + 체크리스트 |
| analytics/ | 1개 | 분석 대시보드 |
| 기타 (6개 마스터만) | 6개 | calendar, onboarding, student_home, follow, settings, gamification, home, relationship, tuner |

---

## 기획 제안서 (proposal/)

| 문서 | 내용 |
|------|------|
| [teacher_feedback_session.md](proposal/teacher_feedback_session.md) | 선생님 피드백 세션 자료 + 시장 분석 + 수익 모델 |
| [payment_subscription_integration.md](proposal/payment_subscription_integration.md) | Payment -> Subscription 통합 설계 결정 |
| [offline_first_architecture.md](proposal/offline_first_architecture.md) | 오프라인 우선 아키텍처 제안 |
| [tuner_feature_proposal.md](proposal/tuner_feature_proposal.md) | 튜너 기능 제안 |
| [flow_simplification_analysis.md](proposal/flow_simplification_analysis.md) | 플로우 간소화 분석 |
| [invite_ux_improvement.md](proposal/invite_ux_improvement.md) | 초대 UX 개선 |
| [data_backup_proposal.md](proposal/data_backup_proposal.md) | 데이터 백업 제안 |
| [existing_relationship_onboarding.md](proposal/existing_relationship_onboarding.md) | 기존 관계 온보딩 |
| [minor_registration_policy.md](proposal/minor_registration_policy.md) | 미성년자 등록 정책 |
| [parent_system.md](proposal/parent_system.md) | 학부모 시스템 제안 |
| [practice_repertoire_enhancement.md](proposal/practice_repertoire_enhancement.md) | 연습 레퍼토리 개선 |
| [recording_persistence_qa.md](proposal/recording_persistence_qa.md) | 녹음 영속성 QA |
| [recording_sync_multidevice.md](proposal/recording_sync_multidevice.md) | 녹음 다중 기기 동기화 |
| [recording_session_2025-12-30.md](proposal/recording_session_2025-12-30.md) | 녹음 세션 기록 |
| [smart_recording_qa.md](proposal/smart_recording_qa.md) | 스마트 녹음 QA |
| [tuner_gamification_ux.md](proposal/tuner_gamification_ux.md) | 튜너 게이미피케이션 UX |
| [repertoire_date_management_analysis.md](proposal/repertoire_date_management_analysis.md) | 레퍼토리 날짜 관리 분석 |

---

## 참고 자료 (reference/)

| 문서 | 내용 |
|------|------|
| [flutter_deploy_guide.md](reference/flutter_deploy_guide.md) | Flutter 배포 가이드 |
| [student_centered_architecture.md](reference/student_centered_architecture.md) | 학생 중심 아키텍처 |
| [metronome_timing_analysis.md](reference/metronome_timing_analysis.md) | 메트로놈 타이밍 분석 |
| [data_backup_strategy.md](reference/data_backup_strategy.md) | 데이터 백업 전략 |
| [Lesson_Types_Analysis.md](reference/Lesson_Types_Analysis.md) | 레슨 유형 분석 |
| [package_comparison.md](reference/package_comparison.md) | 패키지 비교 |

---

## 리서치 (research/)

| 문서 | 내용 |
|------|------|
| [README.md](research/README.md) | 리서치 개요 |
| [tonara_app_analysis.md](research/tonara_app_analysis.md) | Tonara 앱 분석 |
| [practice_space_app_analysis.md](research/practice_space_app_analysis.md) | Practice Space 앱 분석 |
| [studiomate_app_analysis.md](research/studiomate_app_analysis.md) | StudioMate 앱 분석 |
| [pricing_model_analysis.md](research/pricing_model_analysis.md) | 요금 모델 분석 |
| [competitive_analysis.md](research/competitive_analysis.md) | 경쟁사 분석 |
| [template_analysis.md](research/template_analysis.md) | 템플릿 분석 |
| [figma_templates.md](research/figma_templates.md) | Figma 템플릿 |
| [ai_agent_development_workflow.md](research/ai_agent_development_workflow.md) | AI 에이전트 개발 워크플로우 |

---

## 엔티티 스키마

위치: `schema/entities/`

주요 엔티티: User, Student, Teacher, Lesson, Subscription, SubscriptionProposal, LessonClass, LessonLocation, Payment, Recording, PracticeRepertoire, PracticeSection, Booking, CancellationPolicy, ClassMembership, LessonSchedule, Notification, Parent, PracticeGoal, PracticeNote, PracticeSpace, Review, TeacherAvailability, AvailabilitySlot

---

## 공통 리소스

| 폴더 | 내용 |
|------|------|
| `_tokens/` | 디자인 토큰 (colors, typography, spacing, icons, status) |
| `_components/` | 공통 컴포넌트 스펙 (form_field, bottom_sheet, list_card, confirm_dialog, date_range_picker, empty_state, measure_picker, repeat_toggle, submit_button) |
| `_patterns/` | 디자인 패턴 (crud_form, list_detail, date_constraint) |
| [registry.md](registry.md) | 토큰/컴포넌트/패턴 의존성 레지스트리 |

---

## 기타 문서

| 문서 | 내용 |
|------|------|
| [architecture.md](architecture.md) | 아키텍처 가이드 |
| [refactoring_tasks.md](refactoring_tasks.md) | 리팩토링 태스크 목록 |
| [task.md](task.md) | 태스크 관리 |

---

## Deprecated

> **specs/_archive/ — 작업 근거로 읽지 말 것**
>
> `_archive/` 디렉토리에는 폐기된 스펙이 보관되어 있습니다.
> 활성 문서의 (아카이브됨) 링크는 통합 원본 출처 표시일 뿐, 작업 근거가 아닙니다.
> 최신 스펙은 `specs/[domain]/` 마스터 문서를 확인하세요.

---

## 문서 규칙

1. **마스터 문서가 SSOT**: 개별 스펙과 마스터 문서가 충돌 시, 마스터 문서가 우선
2. **새 기능 스펙**: `specs/[domain]/` 아래 작성 후, 해당 마스터 문서에 참조 추가
3. **기획 제안**: `proposal/`에 작성 (확정 후 specs/에 스펙 문서 생성)
4. **참고 자료**: `reference/`에 보관 (과거 분석, 가이드 등)
5. **리서치**: `research/`에 보관 (경쟁사 분석, 시장 조사 등)
