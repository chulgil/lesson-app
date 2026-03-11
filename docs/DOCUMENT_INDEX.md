# Document Index

> 최종 업데이트: 2026-03-11
> 목적: Claude가 작업 시작 시 이 파일을 읽고 필요한 문서를 빠르게 찾기 위한 인덱스

---

## 마스터 문서 (SSOT)

각 도메인의 마스터 문서는 해당 도메인의 **모든 하위 스펙을 통합**한 단일 진실 소스입니다.

| 도메인 | 마스터 문서 | 핵심 내용 |
|--------|-----------|----------|
| 디자인 시스템 | [design_master.md](specs/design/design_master.md) | 색상, 타이포, 컴포넌트, 경쟁사 분석 |
| 레슨 | [lesson_master.md](specs/lesson/lesson_master.md) | 레슨 CRUD, 예약, 취소, 노트, 3자 관계 |
| 수강권 | [subscription_master.md](specs/subscription/subscription_master.md) | 수강권 발급, 결제 확인, 정책 |
| 스케줄 | [schedule_master.md](specs/schedule/schedule_master.md) | 캘린더, 가용시간, 스케줄 확인 카드 |
| 캘린더 | [calendar_master.md](specs/calendar/calendar_master.md) | 주간/월간 캘린더 UI |
| 연습 | [practice_master.md](specs/practice/practice_master.md) | 레퍼토리, 녹음, 리포트, 연습 목표 |
| 사용자 | [user_master.md](specs/user/user_master.md) | 회원가입, 역할, 학부모 시스템 |
| 알림 | [notification_master.md](specs/notification/notification_master.md) | 알림 유형, 푸시 설정 |
| 온보딩 | [onboarding_master.md](specs/onboarding/onboarding_master.md) | 온보딩 플로우 |
| 메트로놈 | [metronome_master.md](specs/metronome/metronome_master.md) | 메트로놈 기능, 쉼표 패턴 |
| 팔로우/초대 | [follow_master.md](specs/follow/follow_master.md) | 선생님-학생 연결, 초대 시스템 |
| 설정 | [settings_master.md](specs/settings/settings_master.md) | 앱 설정, 녹음 관리 |
| 학생 홈 | [student_home_master.md](specs/student_home/student_home_master.md) | 학생 앱 홈 화면 |

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
| [teacher_app_screens.md](specs/design/teacher_app_screens.md) | 선생님 앱 4탭 화면 와이어프레임 | 선생님 화면 UI 구현 시 |
| [role_based_screens.md](specs/design/role_based_screens.md) | 역할별(선생님/학생/학부모) 화면 개요 | 역할별 차이 확인 시 |
| [ux_guidelines.md](specs/design/ux_guidelines.md) | UX 원칙, 상호작용 패턴 | UI 구현 판단 시 |
| [teacher_ux_review.md](specs/design/teacher_ux_review.md) | 선생님 앱 UX 검토 결과 + 개선 이슈 | UX 개선 작업 시 |
| [student_ux_review.md](specs/design/student_ux_review.md) | 학생 앱 UX 검토 결과 | 학생 UX 개선 작업 시 |
| [competitor_ux_analysis.md](specs/design/competitor_ux_analysis.md) | 경쟁사 UX 분석 | 기능 비교 시 |
| [booking_system_comparison.md](specs/design/booking_system_comparison.md) | 예약 시스템 비교 분석 | 예약 UX 설계 시 |
| [design_system.md](specs/design/figma/design_system.md) | Figma 디자인 시스템 | 디자인 토큰 확인 시 |

---

## 요구사항 & 로드맵

| 문서 | 역할 |
|------|------|
| [requirement.md](requirement/requirement.md) | 전체 요구사항 정의 |
| [requirement2.md](requirement/requirement2.md) | 추가 요구사항 |
| [implementation_status.md](requirement/implementation_status.md) | 구현 상태 (Phase별) |
| [implementation_roadmap_v2.md](specs/dev/implementation_roadmap_v2.md) | 6단계 구현 로드맵 (최신) |
| [implementation_roadmap.md](specs/dev/implementation_roadmap.md) | 구현 로드맵 v1 (이전 버전) |
| [beta_readiness.md](specs/dev/beta_readiness.md) | 베타 준비 상태 |
| [launch_roadmap.md](launch_roadmap.md) | 런칭 로드맵 |
| [test_scenarios.md](specs/dev/test_scenarios.md) | 테스트 시나리오 |
| [test_data.md](specs/dev/test_data.md) | 테스트 데이터 |

---

## 도메인별 개별 스펙

### 레슨 (specs/lesson/)

| 문서 | 내용 |
|------|------|
| [lesson_note_spec.md](specs/lesson/lesson_note_spec.md) | 레슨 노트 스펙 |
| [lesson_note_history_spec.md](specs/lesson/lesson_note_history_spec.md) | 레슨 노트 히스토리 |
| [quick_add_lesson.md](specs/lesson/quick_add_lesson.md) | 빠른 레슨 추가 |
| [quick_feedback_spec.md](specs/lesson/quick_feedback_spec.md) | 빠른 피드백 |
| [feedback_presets_spec.md](specs/lesson/feedback_presets_spec.md) | 피드백 프리셋 |
| [attendance_spec.md](specs/lesson/attendance_spec.md) | 출석 관리 |
| [assignment_dashboard_spec.md](specs/lesson/assignment_dashboard_spec.md) | 과제 대시보드 |
| [assignment_ui_simplification.md](specs/lesson/assignment_ui_simplification.md) | 과제 UI 간소화 |
| [ai_lesson_notes_spec.md](specs/lesson/ai_lesson_notes_spec.md) | AI 레슨 노트 |
| [teaching_resources_spec.md](specs/lesson/teaching_resources_spec.md) | 교육 자료 |
| [group_lesson_spec.md](specs/lesson/group_lesson_spec.md) | 그룹 레슨 |
| [three_party_relationship_spec.md](specs/lesson/three_party_relationship_spec.md) | 3자 관계 |
| [Unified_Lesson_Booking_Spec.md](specs/lesson/Unified_Lesson_Booking_Spec.md) | 통합 레슨 예약 |
| [lesson_schedule.md](specs/lesson/lesson_schedule.md) | 레슨 스케줄 |
| [lesson_location_selection.md](specs/lesson/lesson_location_selection.md) | 레슨 장소 선택 |
| [practice_type_unification.md](specs/lesson/practice_type_unification.md) | 연습 유형 통합 |
| [flow_*.md](specs/lesson/) | 레슨 플로우 (connection, trial, regular, package, cancel, payment, with_app, without_app) |
| [flow_test_checklist.md](specs/lesson/flow_test_checklist.md) | 플로우 테스트 체크리스트 |

### 연습 (specs/practice/)

| 문서 | 내용 |
|------|------|
| [Practice_System_Spec.md](specs/practice/Practice_System_Spec.md) | 연습 시스템 전체 스펙 |
| [practice_screen_spec.md](specs/practice/practice_screen_spec.md) | 연습 화면 스펙 |
| [practice_goal_spec.md](specs/practice/practice_goal_spec.md) | 연습 목표 |
| [practice_note_spec.md](specs/practice/practice_note_spec.md) | 연습 노트 |
| [practice_streak_spec.md](specs/practice/practice_streak_spec.md) | 연습 스트릭 |
| [practice_report_spec.md](specs/practice/practice_report_spec.md) | 연습 리포트 |
| [practice_sharing_spec.md](specs/practice/practice_sharing_spec.md) | 연습 공유 |
| [gamification_spec.md](specs/practice/gamification_spec.md) | 게이미피케이션 시스템 (포인트/레벨/뱃지) |
| [central_practice_button.md](specs/practice/central_practice_button.md) | 중앙 연습 버튼 |
| [section_detail_spec.md](specs/practice/section_detail_spec.md) | 섹션 상세 |
| [repertoire_detail_spec.md](specs/practice/repertoire_detail_spec.md) | 레퍼토리 상세 |
| [repertoire_quick_edit_spec.md](specs/practice/repertoire_quick_edit_spec.md) | 레퍼토리 빠른 편집 |
| [repertoire_history_spec.md](specs/practice/repertoire_history_spec.md) | 레퍼토리 히스토리 |
| [smart_recording_spec.md](specs/practice/smart_recording_spec.md) | 스마트 녹음 |
| [quick_recording_spec.md](specs/practice/quick_recording_spec.md) | 빠른 녹음 |
| [recording_comparison_spec.md](specs/practice/recording_comparison_spec.md) | 녹음 비교 |
| [recording_player_ui.md](specs/practice/recording_player_ui.md) | 녹음 플레이어 UI |
| [recording_requirement.md](specs/practice/recording_requirement.md) | 녹음 요구사항 |
| [backup_implementation_spec.md](specs/practice/backup_implementation_spec.md) | 백업 구현 |

### 분석 (specs/analytics/)

| 문서 | 내용 |
|------|------|
| [analytics_dashboard_spec.md](specs/analytics/analytics_dashboard_spec.md) | 선생님 분석 대시보드 스펙 |

### 수강권 (specs/subscription/)

| 문서 | 내용 |
|------|------|
| [subscription_system_spec.md](specs/subscription/subscription_system_spec.md) | 수강권 시스템 스펙 |
| [subscription_proposal_spec.md](specs/subscription/subscription_proposal_spec.md) | 수강권 제안 스펙 |
| [subscription_status_colors.md](specs/subscription/subscription_status_colors.md) | 수강권 상태 색상 |
| [lesson_cancellation_policy.md](specs/subscription/lesson_cancellation_policy.md) | 레슨 취소 정책 |
| [lesson_policy_settings.md](specs/subscription/lesson_policy_settings.md) | 레슨 정책 설정 |
| [lesson_request_system.md](specs/subscription/lesson_request_system.md) | 레슨 요청 시스템 |
| [terms_of_service.md](specs/subscription/terms_of_service.md) | 이용약관 |
| [privacy_policy.md](specs/subscription/privacy_policy.md) | 개인정보처리방침 |

### 스케줄 (specs/schedule/)

| 문서 | 내용 |
|------|------|
| [teacher_availability_spec.md](specs/schedule/teacher_availability_spec.md) | 선생님 가용시간 스펙 |
| [schedule_confirmation_card_spec.md](specs/schedule/schedule_confirmation_card_spec.md) | 스케줄 확인 카드 스펙 |

### 사용자 (specs/user/)

| 문서 | 내용 |
|------|------|
| [parent_system.md](specs/user/parent_system.md) | 학부모 시스템 |
| [parent_login_flow.md](specs/user/parent_login_flow.md) | 학부모 로그인 플로우 |
| [parent_dashboard_spec.md](specs/user/parent_dashboard_spec.md) | 학부모 대시보드 스펙 |
| [teacher_registration.md](specs/user/teacher_registration.md) | 선생님 등록 |

### 학생 홈 (specs/student_home/)

| 문서 | 내용 |
|------|------|
| [student_profile_settings.md](specs/student_home/student_profile_settings.md) | 학생 프로필 설정 |
| [unimplemented_menus_spec.md](specs/student_home/unimplemented_menus_spec.md) | 미구현 메뉴 스펙 |

### 알림 (specs/notification/)

| 문서 | 내용 |
|------|------|
| [notification_system.md](specs/notification/notification_system.md) | 알림 시스템 스펙 |

### 초대 (specs/invite/)

| 문서 | 내용 |
|------|------|
| [invite_system_v2.md](specs/invite/invite_system_v2.md) | 초대 시스템 v2 |
| [subscription_based_relationship.md](specs/invite/subscription_based_relationship.md) | 수강권 기반 관계 |

### 메트로놈 (specs/metronome/)

| 문서 | 내용 |
|------|------|
| [metronome_system.md](specs/metronome/metronome_system.md) | 메트로놈 시스템 |
| [metronome_sound.md](specs/metronome/metronome_sound.md) | 메트로놈 사운드 |
| [avaudioengine_guide.md](specs/metronome/avaudioengine_guide.md) | AVAudioEngine 가이드 |
| [subdivision_ui_design.md](specs/metronome/subdivision_ui_design.md) | 서브디비전 UI 디자인 |

### 튜너 (specs/tuner/)

| 문서 | 내용 |
|------|------|
| [README.md](specs/tuner/README.md) | 튜너 스펙 개요 |

### 인증 (specs/auth/)

| 문서 | 내용 |
|------|------|
| [google_sso_setup_guide.md](specs/auth/google_sso_setup_guide.md) | Google SSO 설정 가이드 |

### 결제 (specs/payment/)

| 문서 | 내용 |
|------|------|
| [payment_unified_spec.md](specs/payment/payment_unified_spec.md) | 통합 결제 스펙 |

### 리뷰 (specs/review/)

| 문서 | 내용 |
|------|------|
| [review_system.md](specs/review/review_system.md) | 리뷰 시스템 |

### 학생 (specs/student/)

| 문서 | 내용 |
|------|------|
| [student_class_system.md](specs/student/student_class_system.md) | 학생 클래스 시스템 |

### 체험 (specs/trial/)

| 문서 | 내용 |
|------|------|
| [trial_lesson_system.md](specs/trial/trial_lesson_system.md) | 체험 레슨 시스템 |

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

> **specs/old/ -- 사용 금지 (deprecated). 최신 스펙은 각 도메인 디렉토리 참조.**
>
> `specs/old/` 디렉토리의 문서들은 더 이상 유효하지 않습니다. 절대 참조하지 마세요.
> 최신 스펙은 `specs/[domain]/` 또는 해당 도메인의 마스터 문서를 확인하세요.

---

## 문서 규칙

1. **마스터 문서가 SSOT**: 개별 스펙과 마스터 문서가 충돌 시, 마스터 문서가 우선
2. **새 기능 스펙**: `specs/[domain]/` 아래 작성 후, 해당 마스터 문서에 참조 추가
3. **기획 제안**: `proposal/`에 작성 (확정 후 specs/에 스펙 문서 생성)
4. **참고 자료**: `reference/`에 보관 (과거 분석, 가이드 등)
5. **리서치**: `research/`에 보관 (경쟁사 분석, 시장 조사 등)
