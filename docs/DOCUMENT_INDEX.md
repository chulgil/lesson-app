# Document Index

> 최종 업데이트: 2026-03-07
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

## 화면 설계 문서

| 문서 | 역할 | 언제 참조? |
|------|------|----------|
| [teacher_app_screens.md](specs/design/teacher_app_screens.md) | 선생님 앱 4탭 화면 와이어프레임 | 선생님 화면 UI 구현 시 |
| [role_based_screens.md](specs/design/role_based_screens.md) | 역할별(선생님/학생/학부모) 화면 개요 | 역할별 차이 확인 시 |
| [ux_guidelines.md](specs/design/ux_guidelines.md) | UX 원칙, 상호작용 패턴 | UI 구현 판단 시 |
| [teacher_ux_review.md](specs/design/teacher_ux_review.md) | 선생님 앱 UX 검토 결과 + 개선 이슈 | UX 개선 작업 시 |
| [competitor_ux_analysis.md](specs/design/competitor_ux_analysis.md) | 경쟁사 UX 분석 | 기능 비교 시 |

---

## 요구사항 & 로드맵

| 문서 | 역할 |
|------|------|
| [requirement.md](requirement/requirement.md) | 전체 요구사항 정의 |
| [requirement2.md](requirement/requirement2.md) | 추가 요구사항 |
| [implementation_status.md](requirement/implementation_status.md) | 구현 상태 (Phase별) |
| [implementation_roadmap.md](specs/dev/implementation_roadmap.md) | 6단계 구현 로드맵 |
| [feature_hub.md](specs/feature_hub.md) | 기능 허브 (전체 기능 목록) |
| [beta_readiness.md](specs/dev/beta_readiness.md) | 베타 준비 상태 |

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

---

## 엔티티 스키마

위치: `schema/entities/`

주요 엔티티: User, Student, Teacher, Lesson, Subscription, SubscriptionProposal, LessonClass, LessonLocation, Payment, Recording, PracticeRepertoire, PracticeSection

---

## 공통 리소스

| 폴더 | 내용 |
|------|------|
| `_tokens/` | 디자인 토큰 (colors, typography, spacing, icons, status) |
| `_components/` | 공통 컴포넌트 스펙 (form_field, bottom_sheet, list_card 등) |
| `_patterns/` | 디자인 패턴 (crud_form, list_detail, date_constraint) |
| [registry.md](registry.md) | 토큰/컴포넌트/패턴 의존성 레지스트리 |

---

## 문서 규칙

1. **마스터 문서가 SSOT**: 개별 스펙과 마스터 문서가 충돌 시, 마스터 문서가 우선
2. **새 기능 스펙**: `specs/[domain]/` 아래 작성 후, 해당 마스터 문서에 참조 추가
3. **기획 제안**: `proposal/`에 작성 (확정 후 specs/에 스펙 문서 생성)
4. **old/**: `specs/old/`는 더 이상 사용하지 않는 구 스펙. 참조하지 말 것
