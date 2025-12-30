# lesson-app 문서

> 마지막 업데이트: 2025-12-31

음악 레슨 예약 및 연습 관리 앱 문서입니다.

---

## 📁 문서 구조

```
docs/
├── requirement/          # 요구사항 및 현황
├── proposal/             # 기획 제안서
├── specs/                # 기능 명세서
│   ├── lesson/           # 레슨 시스템
│   ├── practice/         # 연습 시스템
│   ├── metronome/        # 메트로놈
│   ├── payment/          # 결제 시스템
│   ├── user/             # 사용자 (선생님/학부모)
│   ├── notification/     # 알림 시스템
│   ├── review/           # 리뷰 시스템
│   ├── trial/            # 체험 레슨
│   ├── invite/           # 초대 시스템
│   ├── design/           # UX/UI 설계
│   └── dev/              # 개발 가이드
└── task.md               # 개발 태스크
```

---

## 📋 요구사항 (requirement/)

| 문서 | 설명 |
|------|------|
| [requirement.md](requirement/requirement.md) | 프로젝트 요구사항 정리 |
| [implementation_status.md](requirement/implementation_status.md) | 구현 현황 |

---

## 💡 제안서 (proposal/)

| 문서 | 설명 |
|------|------|
| [existing_relationship_onboarding.md](proposal/existing_relationship_onboarding.md) | 기존 관계 온보딩 |
| [minor_registration_policy.md](proposal/minor_registration_policy.md) | 미성년자 등록 정책 |
| [parent_system.md](proposal/parent_system.md) | 학부모 시스템 Q&A |

---

## 📐 기능 명세 (specs/)

### 레슨 시스템 (lesson/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [lesson_schedule.md](specs/lesson/lesson_schedule.md) | ✅ 확정 | 레슨 스케줄 시스템 |
| [Lesson_Types_Analysis.md](specs/lesson/Lesson_Types_Analysis.md) | ✅ 확정 | 레슨 유형 분석 |
| [Lesson_Schedule_Design.md](specs/lesson/Lesson_Schedule_Design.md) | ✅ 확정 | 레슨 스케줄 설계 |
| [student_centered_architecture.md](specs/lesson/student_centered_architecture.md) | ✅ 확정 | 학생 중심 아키텍처 |
| [Unified_Lesson_Booking_Spec.md](specs/lesson/Unified_Lesson_Booking_Spec.md) | ✅ 확정 | 통합 레슨 예약 스펙 |

### 연습 시스템 (practice/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [practice_system.md](specs/practice/practice_system.md) | ✅ 확정 | 연습 시스템 스펙 |
| [Practice_System_Spec.md](specs/practice/Practice_System_Spec.md) | ✅ 확정 | 연습 시스템 상세 스펙 |
| [practice_streak_spec.md](specs/practice/practice_streak_spec.md) | ✅ 확정 | 연습 스트릭 스펙 |
| [recording_requirement.md](specs/practice/recording_requirement.md) | ✅ 확정 | 녹음 기능 요구사항 |
| [recording_player_ui.md](specs/practice/recording_player_ui.md) | ✅ 확정 | 녹음 재생 UI 스펙 |
| [waveform_improvements.md](specs/practice/waveform_improvements.md) | ✅ 확정 | 파형 UI 개선 (모듈화, 핀치줌) |

### 메트로놈 (metronome/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [metronome_system.md](specs/metronome/metronome_system.md) | ✅ 확정 | 메트로놈 시스템 |
| [metronome_sound.md](specs/metronome/metronome_sound.md) | ✅ 확정 | 사운드 이펙트 |
| [metronome_indicator.md](specs/metronome/metronome_indicator.md) | ✅ 확정 | UI 인디케이터 |

### 결제 시스템 (payment/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [payment_system.md](specs/payment/payment_system.md) | ✅ 확정 | 결제 시스템 스펙 |
| [payment_flow.md](specs/payment/payment_flow.md) | ✅ 확정 | 결제 플로우 |
| [payment_requirement.md](specs/payment/payment_requirement.md) | ✅ 확정 | 결제 요구사항 |

### 사용자 시스템 (user/)

| 문서 | 상태 | 설명 |
|------|------|------|
| [parent_system.md](specs/user/parent_system.md) | ✅ 확정 | 학부모 시스템 |
| [parent_login_flow.md](specs/user/parent_login_flow.md) | ✅ 확정 | 학부모 로그인 플로우 |
| [teacher_registration.md](specs/user/teacher_registration.md) | ✅ 확정 | 외부 선생님 등록 |

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
| [invite_system_v2.md](specs/invite/invite_system_v2.md) | ✅ 확정 | 양방향 초대 시스템 (QR/URL/코드) |

### UX/UI 설계 (design/)

| 문서 | 상태 | 설명 |
|------|------|------|
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
| [test_scenarios.md](specs/dev/test_scenarios.md) | ✅ 확정 | 로그인 테스트 시나리오 |

---

## 🔗 관련 문서

- [프로젝트 CLAUDE.md](../CLAUDE.md) - 프로젝트 개발 가이드
