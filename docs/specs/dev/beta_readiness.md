# 베타 서버 연동 현황

> 작성일: 2026-03-03
> 최종 수정: 2026-06-01
> 상태: 진행 중

---

## 개요

프론트엔드(Flutter)와 베타 서버(FastAPI) 간 API 연동 현황을 정리한 문서.
`USE_MOCK=false` 모드에서 각 도메인의 Remote Repository 구현 상태를 추적합니다.

---

## Repository 연동 현황

### Remote Repository 구현 완료

| 도메인 | Repository | Provider 파일 |
|--------|-----------|--------------|
| 인증 | `RemoteAuthRepository` | `auth_provider.dart` |
| 레슨 | `RemoteLessonRepository` | `lesson_repository_provider.dart` |
| 학생 | `RemoteStudentRepository` | `student_repository_provider.dart` |
| 수강권 | `RemoteSubscriptionRepository` | `subscription_providers.dart` |
| 수강권 제안 | `RemoteSubscriptionProposalRepository` | `subscription_proposal_providers.dart` |
| 수강권 템플릿 | `RemoteSubscriptionTemplateRepository` | `subscription_template_providers.dart` |
| 레슨 요청 | `RemoteLessonRequestRepository` | `lesson_request_providers.dart` |
| 가용시간 | `RemoteTeacherAvailabilityRepository` | `teacher_availability_providers.dart` |
| 예약 | `RemoteBookingRepository` | `booking_providers.dart` |
| 그룹클래스 예약 | `RemoteGroupClassBookingRepository` | `group_class_booking_providers.dart` |
| 스케줄 확인 카드 | `RemoteScheduleConfirmationCardRepository` | `schedule_confirmation_card_providers.dart` |
| 연습 | `RemotePracticeRepository` | `practice_repository_provider.dart` |
| 연습 항목 | `RemotePracticeItemRepository` | `practice_item_providers.dart` |
| 연습 노트 | `RemotePracticeNoteRepository` | `practice_note_provider.dart` |
| 알림 | `RemoteNotificationRepository` | `notification_providers.dart` |
| 관계 | `RemoteTeacherStudentRelationRepository` | `relation_providers.dart` |
| 학부모 | `RemoteParentRepository` | `parent_providers.dart` |
| 녹음 피드백 | `RemoteRecordingFeedbackRepository` | `recording_feedback_provider.dart` |
| 자녀 프로필 | `RemoteChildProfileRepository` | `child_profile_provider.dart` |
| 선생님 공지 | `RemoteTeacherAnnouncementRepository` | `teacher_announcement_providers.dart` |
| 팁 템플릿 | `RemoteTipTemplateRepository` | `tip_template_providers.dart` |
| 피드백 템플릿 | `RemoteFeedbackTemplateRepository` | `feedback_template_providers.dart` |

### Mock-only 또는 정책상 Remote 보류

| 도메인 | Provider 파일 | 비고 |
|--------|--------------|------|
| 레슨 정책 | `lesson_policy_providers.dart` | 백엔드 API 필요 |
| 제안 설정 | `proposal_settings_providers.dart` | 백엔드 API 필요 |
| 레슨 클래스 | `lesson_class_providers.dart` | 백엔드 API 필요 |
| 멤버십 | `membership_providers.dart` | 백엔드 API 필요 |
| 장소 | `location_providers.dart` | 백엔드 API 필요 |
| 선생님 검색 | `teacher_providers.dart` | 백엔드 API 필요 |
| 결제 | `payment_repository_provider.dart` | 빈 Mock (empty: true) |
| 악보 | `piece_repository_provider.dart` | 빈 Mock (empty: true) |
| 연습 레퍼토리 | `practice_repertoire_repository_provider.dart` | Mock 반환 |
| 선생님 프로필 | `teacher_profile_repository_provider.dart` | 빈 Mock (empty: true) |

---

## 베타 접속 빌드 조건 (2026-05-29)

베타 서버를 기존 프론트 앱에서 검증할 때는 mock repository 기본값을 끄고 베타 API base URL을 명시한다.

```bash
--dart-define=USE_MOCK=false
--dart-define=API_BASE_URL=https://api-beta.lessonaza.app/api/v1
```

`USE_MOCK` 기본값은 `true`이고 `API_BASE_URL` 기본값은 local 서버이므로, 위 값이 없으면 베타 백엔드를 테스트하지 않는다.

## 백엔드 API Gap 검증 결과 (2026-06-01)

2026-06-01 기준 프론트 Remote Repository의 literal API 호출 275개와 FastAPI OpenAPI operation 400개를 대조했으며, 즉시 404/405로 이어지는 경로 불일치는 발견되지 않았다.

기존에 미구현으로 기록되어 있던 `/practice-logs/*`, `/schedule/lesson-requests/*`, `/subscriptions/{id}/usage`, 수강권 템플릿/제안 URL 패턴, `POST /auth/logout` 계약은 현재 백엔드 계약 테스트에서 통과한다.

남은 항목은 백엔드 미구현이 아니라 제품 정책 또는 프론트 연결 범위 문제다.

| 영역 | 현재 판단 |
|------|-----------|
| 결제 | 앱 내 PG가 아니라 선생님 수동 입금 상태 관리로 유지한다. 별도 payment API는 만들지 않고 `/subscriptions` 입금 상태와 사용 이력을 재사용한다. |
| 악보/곡 라이브러리 | `/practice/pieces` API는 있으나 기존 `PieceRepository`의 화면 계약과 전체 전환 범위가 다르다. 별도 전환 작업으로 다룬다. |
| 연습 레퍼토리 | `/practice/repertoires`, `/practice/sections`, `/practice/notes` API는 있으나 기존 Hive 녹음/섹션 동기화 경계가 남아 있다. |

## 베타 계약 보완 완료 (2026-05-29)

| 프론트엔드 호출 경로 | 백엔드 계약 | 상태 |
|--------------------|------------|------|
| `PATCH /lessons/{id}/archive` | 레슨을 `is_archived=true`, `archived_at=now`로 보관하고 기본 레슨 목록에서 숨김 | 완료 |
| `PATCH /lessons/{id}/unarchive` | 레슨 보관을 해제하고 `archived_at=null`로 복원 | 완료 |
| `PATCH /students/{id}/archive` | 기존 `inactive` 상태를 학생 보관 상태로 사용, `is_archived=true` 응답 | 완료 |
| `PATCH /students/{id}/unarchive` | 학생 상태를 `active`로 복원, `is_archived=false` 응답 | 완료 |
| `POST /bookings` with `slot_id` | `{teacher_id}-{yyyy-mm-dd}-{HH:mm}` 슬롯 ID를 예약 요청으로 변환하고 `AvailabilitySlot` 호환 응답 반환 | 완료 |
| `share_tokens` hash-only 스키마 | 기존 `add_share_token` revision을 보존하고 새 forward migration으로 베타 DB를 `token_hash` 기반 스키마로 전환 | 완료 |

베타 배포 전 서버에서 Alembic head까지 적용되어야 한다. 특히 `share_tokens`는 이미 적용된 베타 DB가 이전 컬럼(`token`, `scope`, `target_id`)을 가질 수 있으므로 새 migration 적용 여부를 확인한다.

---

## 회원가입 플로우 (2026-03-03 추가)

```
소셜 로그인 → 약관 동의 → 역할 선택 → (온보딩) → 홈 화면
```

### 약관 동의 화면
- 경로: `/terms-agreement`
- [필수] 서비스 이용약관 동의
- [필수] 개인정보 수집·이용 동의
- [선택] 마케팅 정보 수신 동의
- 상태 관리: `AuthNotifier.termsAgreed` (세션 내 메모리)

### 라우터 로직
- `AuthNeedsRole && !termsAgreed` → `/terms-agreement`
- `AuthNeedsRole && termsAgreed` → `/role-select`
- `AuthAuthenticated` → 역할별 홈

---

## 하드코딩 ID 제거 현황 (2026-03-03)

| 파일 | 이전 | 이후 | 상태 |
|------|------|------|------|
| `home_screen.dart` (urgent actions) | `'teacher_1'` | `teacherId` (provider) | 완료 |
| `students_tab.dart` (3곳) | `'teacher_1'` | `currentUserIdProvider` | 완료 |
| `profile_tab.dart` | `'김선생님'`, `'teacher@example.com'` | `authNotifierProvider` | 완료 |
| `profile_tab.dart` (레슨정책) | `teacher_1` | `currentUserIdProvider` | 완료 |

---

## 홈 화면 입금대기(후불) 표시 (2026-03-03)

- 입금대기(후불) 금액이 0원이면 StatCard 2개 (오늘 레슨, 이번 달)만 표시
- 입금대기(후불) 금액이 0원 초과일 때만 3개 (오늘 레슨, 입금대기(후불), 이번 달) 표시
