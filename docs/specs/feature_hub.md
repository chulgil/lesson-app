# Feature Hub — 기능 × 역할 × 스펙 매트릭스

> 작성일: 2026-03-02
> 상태: 관리 중
> 목적: 전체 기능의 스펙/코드/상태를 한눈에 파악하는 중앙 허브
> 관련 문서: [flow_with_app.md](lesson/flow_with_app.md) (Pain Point 원본)

---

## 1. Pain Point A~H ↔ 기능 매핑

> 출처: [flow_with_app.md §장기 수강생 Pain Point](lesson/flow_with_app.md)
> "오래된 수강생에게 앱의 가치는 편리함이 아니라 **성장 증명**이다."

| # | Pain Point | 해결 기능 | 스펙 문서 | 해결율 |
|---|------------|----------|----------|:------:|
| A | 2년간 뭘 배웠는지 기록 없음 | 레슨 노트 타임라인, 레퍼토리 히스토리 | [lesson_note_spec](lesson/lesson_note_spec.md), [repertoire_history_spec](practice/repertoire_history_spec.md) | 🔥 100% |
| B | 연습 진도 블랙박스 | 연습 기록 실시간 공유 | [practice_sharing_spec](practice/practice_sharing_spec.md) | 🔥 90% |
| C | 실력 성장 체감 불가 | 녹음 A/B 비교 재생 | [recording_comparison_spec](practice/recording_comparison_spec.md) | 🔥 90% |
| D | 학부모에게 보여줄 근거 없음 | 학부모 대시보드 실데이터 | [parent_dashboard_spec](user/parent_dashboard_spec.md), [practice_sharing_spec](practice/practice_sharing_spec.md) | 🔥 95% |
| E | 레슨 시간 최적화 근거 없음 | 레슨별 진도 데이터 | (Phase 2 — 백엔드 필요) | 🟡 60% |
| F | 발표회/콩쿠르 준비 관리 | 섹션별 완성도 추적 | [practice_goal_spec](practice/practice_goal_spec.md) | 🔥 85% |
| G | 선생님 부재 시 대체 레슨 | 레슨 노트 + 레퍼토리 공유 | [lesson_note_spec](lesson/lesson_note_spec.md) | 🔥 90% |
| H | 수강료 인상 근거 | 성장 데이터 기반 협의 | [practice_report_spec](practice/practice_report_spec.md) | 🟡 70% |

---

## 2. 기능 × 역할(T/S/P) × 스펙 × 코드 매트릭스

> T = 선생님, S = 학생, P = 학부모
> 상태: ✅ 구현 완료 | 📋 스펙 완료 | 🆕 스펙 작성 중 | ❌ 미착수

### 2.1 레슨 도메인

| 기능 | T | S | P | 스펙 문서 | 코드 위치 | 상태 |
|------|:-:|:-:|:-:|----------|----------|:----:|
| 레슨 캘린더 (월/주) | ✅ | ✅ | 읽기 | [lesson_schedule](lesson/lesson_schedule.md) | `features/lessons/` | ✅ |
| 레슨 노트 (피드백/포인트/팁) | 편집 | 읽기 | 읽기 | [lesson_note_spec](lesson/lesson_note_spec.md) | `features/lessons/presentation/widgets/lesson_detail/` | 🆕 |
| 레슨 예약 (다중 옵션) | ✅ | ✅ | — | [Multi_Option_Schedule_Spec](lesson/Multi_Option_Schedule_Spec.md) | `features/lessons/` | ✅ |
| 체험 레슨 | ✅ | ✅ | — | [trial_lesson_system](../specs/../trial/trial_lesson_system.md) | `features/lessons/` | ✅ |
| 레슨 추가 (빠른) | ✅ | — | — | [quick_add_lesson](lesson/quick_add_lesson.md) | `features/lessons/` | 📋 |

### 2.2 연습 도메인

| 기능 | T | S | P | 스펙 문서 | 코드 위치 | 상태 |
|------|:-:|:-:|:-:|----------|----------|:----:|
| 연습 화면 (주간 캘린더) | 조회 | ✅ | — | [practice_screen_spec](practice/practice_screen_spec.md) | `features/practice/presentation/screens/` | ✅ |
| 연습 스트릭 | — | ✅ | 읽기 | [practice_streak_spec](practice/practice_streak_spec.md) | `features/practice/` | ✅ |
| 연습 목표 | 설정 | ✅ | — | [practice_goal_spec](practice/practice_goal_spec.md) | `features/practice/` | 📋 |
| 레퍼토리 관리 | ✅ | ✅ | — | [repertoire_detail_spec](practice/repertoire_detail_spec.md) | `features/practice/` | ✅ |
| 섹션 상세 | ✅ | ✅ | — | [section_detail_spec](practice/section_detail_spec.md) | `features/practice/` | ✅ |
| 녹음 기본 (시작/정지/저장) | ✅ | ✅ | — | [recording_requirement](practice/recording_requirement.md) | `features/practice/` | ✅ |
| 녹음 재생 (A-B루프/속도) | ✅ | ✅ | — | [recording_player_ui](practice/recording_player_ui.md) | `features/practice/presentation/widgets/` | ✅ |
| 파형 시각화 (핀치줌) | — | ✅ | — | [waveform_improvements](practice/waveform_improvements.md) | `features/practice/presentation/widgets/waveform/` | ✅ |
| 스마트 녹음 (무음 트리밍) | — | ✅ | — | [smart_recording_spec](practice/smart_recording_spec.md) | `features/practice/` | ✅ |
| **녹음 비교 재생** | — | ✅ | — | [recording_comparison_spec](practice/recording_comparison_spec.md) | (미구현) | 🆕 |
| **연습 공유** | 수신 | 전송 | 읽기 | [practice_sharing_spec](practice/practice_sharing_spec.md) | (미구현) | 🆕 |
| **레퍼토리 히스토리** | 조회 | ✅ | — | [repertoire_history_spec](practice/repertoire_history_spec.md) | (미구현) | 🆕 |
| 연습 통계 리포트 | 조회 | ✅ | 읽기 | [practice_report_spec](practice/practice_report_spec.md) | (미구현) | 📋 |
| 바로 녹음 | — | ✅ | — | [quick_recording_spec](practice/quick_recording_spec.md) | (미구현) | 📋 |

### 2.3 메트로놈/튜너 도메인

| 기능 | T | S | P | 스펙 문서 | 코드 위치 | 상태 |
|------|:-:|:-:|:-:|----------|----------|:----:|
| 메트로놈 시스템 | ✅ | ✅ | — | [metronome_system](metronome/metronome_system.md) | `core/audio/`, `ios/Runner/Audio/` | ✅ |
| 메트로놈 사운드 | — | ✅ | — | [metronome_sound](metronome/metronome_sound.md) | `core/audio/` | ✅ |
| 메트로놈 인디케이터 | — | ✅ | — | [metronome_indicator](metronome/metronome_indicator.md) | `features/practice/presentation/widgets/` | ✅ |
| 중앙 연습 버튼 | — | ✅ | — | [central_practice_button](practice/central_practice_button.md) | `core/widgets/` | ✅ |

### 2.4 결제/수강권 도메인

| 기능 | T | S | P | 스펙 문서 | 코드 위치 | 상태 |
|------|:-:|:-:|:-:|----------|----------|:----:|
| 통합 결제 시스템 | ✅ | ✅ | — | [payment_unified_spec](payment/payment_unified_spec.md) | `features/payment/` | ✅ |
| 수강권 시스템 | ✅ | ✅ | — | [subscription_system_spec](subscription/subscription_system_spec.md) | `features/subscription/` | 📋 |

### 2.5 사용자/초대 도메인

| 기능 | T | S | P | 스펙 문서 | 코드 위치 | 상태 |
|------|:-:|:-:|:-:|----------|----------|:----:|
| 학부모 시스템 (프로필 전환) | — | — | ✅ | [parent_system](user/parent_system.md) | `features/parent_home/` | ✅ |
| **학부모 대시보드 (4탭)** | — | — | ✅ | [parent_dashboard_spec](user/parent_dashboard_spec.md) | `features/parent_home/presentation/screens/` | 🆕 |
| 학부모 로그인 플로우 | — | — | ✅ | [parent_login_flow](user/parent_login_flow.md) | `features/onboarding/` | ✅ |
| 양방향 초대 (QR/코드) | ✅ | ✅ | ✅ | [invite_system_v2](invite/invite_system_v2.md) | `features/invite/` | ✅ |
| 수강권 기반 관계 | ✅ | ✅ | — | [subscription_based_relationship](invite/subscription_based_relationship.md) | `features/invite/` | ✅ |
| 외부 선생님 등록 | ✅ | — | — | [teacher_registration](user/teacher_registration.md) | `features/profile/` | ✅ |

### 2.6 알림/설계 도메인

| 기능 | T | S | P | 스펙 문서 | 코드 위치 | 상태 |
|------|:-:|:-:|:-:|----------|----------|:----:|
| 알림 시스템 | ✅ | ✅ | ✅ | [notification_system](notification/notification_system.md) | `features/notifications/` | ✅ |
| 역할별 화면 개요 | T | S | P | [role_based_screens](design/role_based_screens.md) | — | 📋 |
| UX 가이드라인 | — | — | — | [ux_guidelines](design/ux_guidelines.md) | — | ✅ |

---

## 3. 스펙 작성 현황 대시보드

### 3.1 이번 라운드 신규/보완 문서

| # | 문서 | 유형 | Pain Point | 상태 |
|---|------|------|-----------|:----:|
| 1 | [feature_hub.md](feature_hub.md) | 허브 | — | ✅ 완료 |
| 2 | [lesson_note_spec.md](lesson/lesson_note_spec.md) | 코드 기반 | A, G | ✅ 완료 |
| 3 | [parent_dashboard_spec.md](user/parent_dashboard_spec.md) | 코드 기반 | D | ✅ 완료 |
| 4 | [recording_comparison_spec.md](practice/recording_comparison_spec.md) | 신규 설계 | C | ✅ 완료 |
| 5 | [practice_sharing_spec.md](practice/practice_sharing_spec.md) | 신규 설계 | B, D | ✅ 완료 |
| 6 | [repertoire_history_spec.md](practice/repertoire_history_spec.md) | 신규 설계 | A | ✅ 완료 |
| 7 | [practice_report_spec.md](practice/practice_report_spec.md) | 보완 | H | ✅ 완료 |

### 3.2 전체 스펙 커버리지

| 도메인 | 총 기능 | 스펙 있음 | 스펙 없음 | 커버율 |
|--------|:-------:|:--------:|:--------:|:------:|
| 레슨 | 5 | 5 | 0 | 100% |
| 연습 | 14 | 14 | 0 | 100% |
| 메트로놈 | 4 | 4 | 0 | 100% |
| 결제/수강권 | 2 | 2 | 0 | 100% |
| 사용자/초대 | 6 | 6 | 0 | 100% |
| 알림/설계 | 3 | 3 | 0 | 100% |

---

## 4. 문서 의존성 그래프

```
                    ┌──────────────┐
                    │ feature_hub  │ (이 문서)
                    └──────┬───────┘
                           │ 참조
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌─────────────┐  ┌───────────┐  ┌──────────────┐
   │ lesson_note │  │ recording │  │ practice     │
   │ _spec       │  │ comparison│  │ _sharing_spec│
   └──────┬──────┘  │ _spec     │  └───────┬──────┘
          │         └───────────┘          │
          │                                ▼
          │                        ┌───────────────┐
          ▼                        │ practice      │
   ┌─────────────┐                │ _report_spec  │
   │ repertoire  │                │ (공유 섹션)    │
   │ _history    │                └───────────────┘
   │ _spec       │
   └─────────────┘
          │
          ▼
   ┌─────────────┐
   │ parent      │
   │ _dashboard  │◄── practice_sharing_spec
   │ _spec       │
   └─────────────┘
```

### 핵심 의존성

| 문서 | 참조하는 엔티티 | 참조하는 스펙 |
|------|---------------|-------------|
| lesson_note_spec | `Lesson` (feedback/keyPoints/practiceTips) | recording_requirement, practice_sharing_spec |
| parent_dashboard_spec | `ChildProfile`, `UserProfile` | practice_sharing_spec, practice_report_spec |
| recording_comparison_spec | `PracticeRecording` (sectionId/bpm/createdAt) | recording_player_ui, waveform_improvements |
| practice_sharing_spec | `Recording` (sharedAt), `PracticeRecording` | practice_report_spec, parent_dashboard_spec |
| repertoire_history_spec | `PracticeRepertoire` (startDate/endDate/isArchived) | repertoire_detail_spec |
| practice_report_spec | `WeeklyReport`, `MonthlyReport` | practice_sharing_spec |

---

## 5. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-03-02 | 초안 작성 — 전체 매트릭스 + Pain Point 매핑 + 의존성 그래프 |
