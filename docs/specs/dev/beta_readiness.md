# 베타 서버 연동 현황

> 작성일: 2026-03-03
> 상태: 진행 중

---

## 개요

프론트엔드(Flutter)와 베타 서버(FastAPI) 간 API 연동 현황을 정리한 문서.
`USE_MOCK=false` 모드에서 각 도메인의 Remote Repository 구현 상태를 추적합니다.

---

## Repository 연동 현황

### Remote Repository 구현 완료 (14개)

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
| 연습 | `RemotePracticeRepository` | `practice_repository_provider.dart` |
| 알림 | `RemoteNotificationRepository` | `notification_providers.dart` |
| 관계 | `RemoteTeacherStudentRelationRepository` | `relation_providers.dart` |
| 학부모 | `RemoteParentRepository` | `parent_providers.dart` |

### Mock-only (Remote 미구현, 7개)

| 도메인 | Provider 파일 | 비고 |
|--------|--------------|------|
| 스케줄 확인 카드 | `schedule_confirmation_card_providers.dart` | 백엔드 API 필요 |
| 레슨 정책 | `lesson_policy_providers.dart` | 백엔드 API 필요 |
| 제안 설정 | `proposal_settings_providers.dart` | 백엔드 API 필요 |
| 레슨 클래스 | `lesson_class_providers.dart` | 백엔드 API 필요 |
| 멤버십 | `membership_providers.dart` | 백엔드 API 필요 |
| 장소 | `location_providers.dart` | 백엔드 API 필요 |
| 선생님 검색 | `teacher_providers.dart` | 백엔드 API 필요 |

### Mock + Empty (Remote API 미구현, 5개)

| 도메인 | Provider 파일 | remote mode 동작 |
|--------|--------------|-----------------|
| 결제 | `payment_repository_provider.dart` | 빈 Mock (empty: true) |
| 악보 | `piece_repository_provider.dart` | 빈 Mock (empty: true) |
| 연습 레퍼토리 | `practice_repertoire_repository_provider.dart` | Mock 반환 |
| 선생님 프로필 | `teacher_profile_repository_provider.dart` | 빈 Mock (empty: true) |
| 설정 | `settings_repository_provider.dart` | Mock 반환 |

---

## 백엔드 API Gap (미구현 엔드포인트)

| 프론트엔드 호출 경로 | 백엔드 상태 | 심각도 |
|--------------------|-----------|--------|
| `/practice/logs/*` (CRUD, 토글, 주간, 스트릭) | 미구현 | CRITICAL |
| `/schedule/lesson-requests/*` (CRUD, 상태변경) | 미구현 | HIGH |
| `/subscriptions/{id}/usage` | 미구현 | HIGH |
| URL 패턴: `/subscriptions-templates` vs `/subscriptions/-templates` | 불일치 | HIGH |
| URL 패턴: `/subscriptions-proposals` vs `/subscriptions/-proposals` | 불일치 | HIGH |
| `POST /auth/logout` body 형식 | 불일치 가능 | MEDIUM |

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

## 홈 화면 미수금 표시 (2026-03-03)

- 미수금이 0원이면 StatCard 2개 (오늘 레슨, 이번 달)만 표시
- 미수금이 0원 초과일 때만 3개 (오늘 레슨, 미수금, 이번 달) 표시
