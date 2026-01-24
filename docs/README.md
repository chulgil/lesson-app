# lesson-app 문서

> 마지막 업데이트: 2026-01-24

음악 레슨 예약 및 연습 관리 앱 문서입니다.

---

## 🔥 핵심 문서 (Claude 필독)

| 문서 | 설명 | 용도 |
|------|------|------|
| [architecture.md](architecture.md) | **앱 아키텍처 가이드** | 폴더 구조, Provider 패턴, 코드 위치 |
| [../CLAUDE.md](../CLAUDE.md) | **프로젝트 가이드** | 명령어, 규칙, 작업 우선순위 |
| [registry.md](registry.md) | **문서 레지스트리** | 토큰/컴포넌트/패턴 의존성 추적 |
| [refactoring_tasks.md](refactoring_tasks.md) | 리팩토링 진행 현황 | Clean Architecture 마이그레이션 |

> **Claude 작업 시작 시**: `architecture.md` → `CLAUDE.md` → 관련 specs 순으로 확인

---

## 문서 구조

```
docs/
├── _tokens/              # 🔑 디자인 토큰 (Single Source of Truth)
│   ├── colors.md         # 색상 토큰
│   ├── typography.md     # 타이포그래피 토큰
│   ├── spacing.md        # 스페이싱 토큰
│   ├── icons.md          # 아이콘 토큰
│   └── status.md         # 상태 토큰
├── _components/          # 🔑 공통 컴포넌트 스펙
│   ├── form_field.md     # 폼 입력 필드
│   ├── measure_picker.md # 마디 선택기
│   ├── date_range_picker.md # 날짜 범위 선택기
│   ├── repeat_toggle.md  # 반복 토글
│   ├── submit_button.md  # 제출 버튼
│   ├── bottom_sheet.md   # 바텀 시트
│   ├── list_card.md      # 리스트 카드
│   ├── confirm_dialog.md # 확인 다이얼로그
│   └── empty_state.md    # 빈 상태
├── _patterns/            # 🔑 공통 패턴
│   ├── crud_form.md      # CRUD 폼 패턴
│   ├── list_detail.md    # 리스트-상세 패턴
│   └── date_constraint.md # 날짜 제약 패턴
├── registry.md           # 📋 문서 의존성 레지스트리
├── requirement/          # 요구사항 및 현황
├── proposal/             # 기획 제안서
├── specs/                # 기능 명세서
│   ├── lesson/           # 레슨 시스템
│   ├── practice/         # 연습 시스템
│   ├── metronome/        # 메트로놈
│   ├── payment/          # 결제 시스템
│   ├── subscription/     # 구독/수강권 시스템 (개인/학원)
│   ├── student/          # 학생 시스템 (클래스/소속)
│   ├── user/             # 사용자 (선생님/학부모)
│   ├── notification/     # 알림 시스템
│   ├── review/           # 리뷰 시스템
│   ├── trial/            # 체험 레슨
│   ├── invite/           # 초대 시스템
│   ├── design/           # UX/UI 설계
│   └── dev/              # 개발 가이드
└── session/              # 작업 세션 기록
```

---

## 모듈러 문서 시스템

### 원칙
- **Single Source of Truth**: 토큰/컴포넌트/패턴은 한 곳에서만 정의
- **의존성 추적**: 스펙 문서는 사용하는 모듈을 헤더에 선언
- **변경 전파**: 모듈 변경 시 registry.md로 영향 범위 파악

### 사용 방법

스펙 문서 상단에 의존성 선언:
```markdown
<!-- @uses: tokens/colors, tokens/typography -->
<!-- @uses: components/form_field, components/submit_button -->
<!-- @uses: patterns/crud_form -->
```

### 공통 모듈

| 폴더 | 설명 | 예시 |
|------|------|------|
| `_tokens/` | 디자인 토큰 (색상, 폰트, 간격) | `tokens/colors` |
| `_components/` | 재사용 UI 컴포넌트 | `components/form_field` |
| `_patterns/` | 공통 UX 패턴 | `patterns/crud_form` |

---

## 요구사항 (requirement/)

| 문서 | 설명 |
|------|------|
| [requirement.md](requirement/requirement.md) | 프로젝트 요구사항 정리 |
| [implementation_status.md](requirement/implementation_status.md) | 구현 현황 |

---

## 제안서 (proposal/)

| 문서 | 설명 |
|------|------|
| [existing_relationship_onboarding.md](proposal/existing_relationship_onboarding.md) | 기존 관계 온보딩 |
| [minor_registration_policy.md](proposal/minor_registration_policy.md) | 미성년자 등록 정책 |
| [parent_system.md](proposal/parent_system.md) | 학부모 시스템 Q&A |
| [invite_ux_improvement.md](proposal/invite_ux_improvement.md) | 초대 UX 개선 |

---

## 기능 명세 (specs/)

### 레슨 시스템 (lesson/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [three_party_relationship_spec.md](specs/lesson/three_party_relationship_spec.md) | 📋 설계 중 | **3자 관계 UI/UX 설계** (→ 엔티티는 student_class_system.md 참조) |
| [lesson_schedule.md](specs/lesson/lesson_schedule.md) | ✅ 확정 | 레슨 스케줄 시스템 |
| [Lesson_Types_Analysis.md](specs/lesson/Lesson_Types_Analysis.md) | ✅ 확정 | 레슨 유형 분석 |
| [Lesson_Schedule_Design.md](specs/lesson/Lesson_Schedule_Design.md) | ✅ 확정 | 레슨 스케줄 설계 |
| [student_centered_architecture.md](specs/lesson/student_centered_architecture.md) | ✅ 확정 | 학생 중심 아키텍처 |
| [Unified_Lesson_Booking_Spec.md](specs/lesson/Unified_Lesson_Booking_Spec.md) | ✅ 확정 | 통합 레슨 예약 스펙 |
| [Multi_Option_Schedule_Spec.md](specs/lesson/Multi_Option_Schedule_Spec.md) | ✅ 확정 | 다중 옵션 스케줄 제안 |

### 연습 시스템 (practice/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [practice_system.md](specs/practice/practice_system.md) | ✅ 확정 | 연습 시스템 스펙 |
| [Practice_System_Spec.md](specs/practice/Practice_System_Spec.md) | ✅ 확정 | 연습 시스템 상세 스펙 |
| [practice_streak_spec.md](specs/practice/practice_streak_spec.md) | ✅ 확정 | 연습 스트릭 스펙 |
| [quick_recording_spec.md](specs/practice/quick_recording_spec.md) | 📋 설계 완료 | **바로 녹음** (디폴트 섹션, 연습도구 통합) |
| [recording_requirement.md](specs/practice/recording_requirement.md) | ✅ 확정 | 녹음 기능 요구사항 |
| [recording_player_ui.md](specs/practice/recording_player_ui.md) | ✅ 확정 | 녹음 재생 UI 스펙 |
| [waveform_improvements.md](specs/practice/waveform_improvements.md) | ✅ 확정 | 파형 UI 개선 (모듈화, 핀치줌) |

### 메트로놈 (metronome/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [metronome_system.md](specs/metronome/metronome_system.md) | ✅ 확정 | 메트로놈 시스템 |
| [metronome_sound.md](specs/metronome/metronome_sound.md) | ✅ 확정 | 사운드 이펙트 |
| [metronome_indicator.md](specs/metronome/metronome_indicator.md) | ✅ 확정 | UI 인디케이터 |
| [metronome_timing_analysis.md](specs/metronome/metronome_timing_analysis.md) | ✅ 확정 | 타이밍 분석 |
| [package_comparison.md](specs/metronome/package_comparison.md) | ✅ 확정 | 패키지 비교 |

### 결제 시스템 (payment/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [payment_unified_spec.md](specs/payment/payment_unified_spec.md) | ✅ 확정 | **통합 결제 스펙** (3자 관계 관점, 상태 enum 통일) |
| [payment_system.md](specs/payment/payment_system.md) | 📦 레거시 | 결제 시스템 스펙 (→ unified_spec으로 통합) |
| [payment_flow.md](specs/payment/payment_flow.md) | 📦 레거시 | 결제 플로우 (→ unified_spec으로 통합) |
| [payment_requirement.md](specs/payment/payment_requirement.md) | 📦 레거시 | 결제 요구사항 (→ unified_spec으로 통합) |

### 구독 시스템 (subscription/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [subscription_system_spec.md](specs/subscription/subscription_system_spec.md) | 📋 설계 완료 | 수강권 시스템 (개인/학원 모드, 데이터 소유권, 정산) |
| [terms_of_service.md](specs/subscription/terms_of_service.md) | 📋 초안 | 이용약관 (법률 검토 필요) |
| [privacy_policy.md](specs/subscription/privacy_policy.md) | 📋 초안 | 개인정보처리방침 (법률 검토 필요) |

### 사용자 시스템 (user/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [parent_system.md](specs/user/parent_system.md) | ✅ 확정 | 학부모 시스템 |
| [parent_login_flow.md](specs/user/parent_login_flow.md) | ✅ 확정 | 학부모 로그인 플로우 |
| [teacher_registration.md](specs/user/teacher_registration.md) | ✅ 확정 | 외부 선생님 등록 |

### 학생 시스템 (student/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [student_class_system.md](specs/student/student_class_system.md) | 📋 설계 완료 | **학생 클래스(소속) 시스템** - LessonClass, ClassMembership, LessonLocation 엔티티 설계 |

### 알림 시스템 (notification/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [notification_system.md](specs/notification/notification_system.md) | ✅ 확정 | 알림 시스템 스펙 |

### 리뷰 시스템 (review/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [review_system.md](specs/review/review_system.md) | ✅ 확정 | 피드백/리뷰 시스템 |

### 체험 레슨 (trial/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [trial_lesson_system.md](specs/trial/trial_lesson_system.md) | ✅ 확정 | 체험 레슨 시스템 |

### 초대 시스템 (invite/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [invite_system_v2.md](specs/invite/invite_system_v2.md) | ✅ 확정 | **양방향 초대 시스템** (맞팔, QR/URL/코드, 3자 관계) |
| [invite_system.md](specs/invite/invite_system.md) | ⚠️ DEPRECATED | v1 레거시 (→ v2로 완전 대체됨) |

### UX/UI 설계 (design/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [role_based_screens.md](specs/design/role_based_screens.md) | 📋 설계 완료 | **역할별 화면 통합 설계** (선생님/학생/학부모 앱) |
| [ux_guidelines.md](specs/design/ux_guidelines.md) | ✅ 확정 | UX 가이드라인 |
| [figma_templates.md](specs/design/figma_templates.md) | ✅ 확정 | Figma 템플릿 |
| [competitive_analysis.md](specs/design/competitive_analysis.md) | ✅ 확정 | 경쟁사 분석 |
| [figma/](specs/design/figma/) | - | Figma 상세 문서 |

### 기술 결정

| 문서 | 상태 | 설명 |
|------|------|------|
| [tech_decision.md](specs/tech_decision.md) | ✅ 확정 | 기술 스택 결정 |

### 개발 (dev/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [implementation_roadmap.md](specs/dev/implementation_roadmap.md) | 📋 계획 | **구현 로드맵** (학원/수강권/3자 관계) |
| [test_scenarios.md](specs/dev/test_scenarios.md) | ✅ 확정 | 로그인 테스트 시나리오 |

### 문서 검증 (review/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [document_verification_report.md](review/document_verification_report.md) | ✅ 완료 | 3자 관계 관점 문서 검증 보고서 |

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [architecture.md](architecture.md) | 앱 아키텍처 (Clean Architecture, Provider 패턴) |
| [refactoring_tasks.md](refactoring_tasks.md) | 리팩토링 진행 현황 |
| [../CLAUDE.md](../CLAUDE.md) | 프로젝트 가이드 (명령어, 규칙)
