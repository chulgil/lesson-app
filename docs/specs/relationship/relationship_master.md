# 선생님-학생 관계 마스터 스펙

> 마지막 업데이트: 2026-03-12
> 구현 상태: ✅ 구현 완료
> 관련 코드: `features/relationship/`

---

## 1. 개요

선생님-학생 간 연결(relationship) 상태 관리. 수강권 기반 관계 모델(V2)로 전환 완료.

## 2. 주요 기능

### 2.1 관계 생성
- 초대 시스템을 통한 연결 (QR/URL/코드)
- 수강권 발급 시 자동 연결

### 2.2 관계 상태 관리
- 연결 상태: pending, active, inactive, blocked
- 관계 해제/차단

### 2.3 데이터 구조
- Mock + Remote Repository 이중 구현

## 3. 코드 위치

| 레이어 | 파일 |
|--------|------|
| 엔티티 | `features/relationship/domain/entities/` |
| Repository | `features/relationship/data/repositories/` (mock + remote) |
| Provider | `features/relationship/presentation/providers/` |

## 4. 관련 마스터 스펙

- 초대: [follow_master.md](../follow/follow_master.md)
- 수강권 기반 관계: [subscription_master.md](../subscription/subscription_master.md) §관계 모델
- 사용자 관리: [user_master.md](../user/user_master.md) §4

---

## 코드 반영 추가 (2026-06-03)

> 본 섹션은 코드 구현이 기존 본문(§2.2의 pending/active/inactive/blocked 등)보다 앞서간 부분을 단방향으로 반영한 것이다. 실제 구현은 수강권 기반 4-상태 모델이며, §2.2의 일반 설명은 역사적 기술로 유지한다.

### RelationshipStatus enum (수강권 기반 4-상태)

코드: `features/relationship/domain/entities/relationship_status.dart`

| 값 | 정의 | 한글 표시(displayName) |
|----|------|----------------------|
| `trialBooked` | 체험 레슨 예약됨 (수강권 발급 전) | 체험 예정 |
| `active` | 수강권 유효 (정기 레슨 진행 중) | 수강 중 |
| `expired` | 수강권 만료 후 30일 이내 (유예 기간) | 수강권 만료 |
| `past` | 수강권 만료 30일 초과 | 이전 레슨 |

`RelationshipStatusExtension`: `canBookLesson`(active만), `canRequestLesson`(expired·past), `canSharePractice`(active만), `isActiveRelationship`(past 아님). (← `relationship_status.dart`)

### TeacherStudentRelation 엔티티 필드

코드: `features/relationship/domain/entities/teacher_student_relation.dart`

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` / `teacherId` / `studentId` | String | 식별자 |
| `status` | RelationshipStatus | 관계 상태 |
| `activeSubscriptionId` | String? | 활성 수강권 ID |
| `lastSubscriptionExpiredAt` | DateTime? | 마지막 수강권 만료일 |
| `expiredUntil` | DateTime? | 유예 종료일 (만료일 + 30일) |
| `createdAt` / `updatedAt` | DateTime | 최초 연결 / 마지막 상태 변경 시각 |
| `trialBookingId` | String? | 체험 예약 ID (trialBooked 상태) |
| `totalLessonCount` | int | 누적 레슨 횟수 (기본 0) |
| `lastLessonAt` | DateTime? | 마지막 레슨 시각 |
| `terminatedBy` / `terminationReason` | String? | 관계 종료자 / 사유 |
| `isManuallyRegistered` | bool | 수동 등록(오프라인) 학생 여부 (true면 상태 전이 미적용, 항상 active) |
| `isAppConnected` | bool | 앱 연결 여부 (기본 true) |
| `appConnectedAt` | DateTime? | 앱 연결 시각 (FE 연결 시점 SSOT) |
| `lastLessonDay` / `lastLessonTime` / `lastLessonDuration` | int?/String?/int? | 재등록 복원용 직전 정기 레슨 요일/시각/분 |
| `lastScheduleRecordedAt` | DateTime? | 직전 스케줄 기록 시각 |

> connection_status 컬럼/enum drop(2026-06) 이후 FE 관계의 연결 시점은 `appConnectedAt` + `isAppConnected` 가 SSOT 이다. 별도 connectionStatus 필드는 존재하지 않는다.

#### appConnectedAt 이원 SSOT 정책 (2026-06-04 명시)

`Student.connectedAt` 과 `TeacherStudentRelation.appConnectedAt` 가 동일 의미를 다른 위치에서 갖는다. 다음 규칙을 적용한다.

| 사용처 | 권위 소스 |
|--------|----------|
| 학생 카드/리스트 UI (선생님 시점 학생 목록) | `Student.connectedAt` — `students_tab.dart` 의 `isAppConnected` 매핑이 이 필드를 우선 사용 |
| 관계 도메인 비즈니스 로직 (체험/정기/회차권 발급 권한 검사) | `TeacherStudentRelation.appConnectedAt` — `effectiveStatus` 계산에 사용 |
| 신규 연결 이벤트 (초대 수락, 학원 매칭) | 양쪽 모두 동일 시각으로 업데이트 — Repository 가 동기 보장 |
| BE 응답 매핑 | BE 가 두 필드를 같은 값으로 반환 (`appConnectedAt` 단일 컬럼 → 양쪽 entity 에 매핑) |

**불일치 시 처리:** Repository 레이어에서 BE 응답 매핑 시 두 필드가 다르면 `appConnectedAt` 우선 — `Student.connectedAt` 를 덮어쓴다. 별도 sync 로직은 두지 않는다 (단일 BE 컬럼이 진실).

**Migration history (2026-06):**
1. Phase A: `ConnectionStatus` enum + `connection_status` 컬럼 deprecation 시작
2. Phase B-2a: connection_status writer 제거, `appConnectedAt` 단독 SSOT
3. Phase B-2b: `connection_status` 컬럼/엔티티/enum drop (#459)
4. **Phase B-3 (예정)**: `Student.connectedAt` 또는 `TeacherStudentRelation.appConnectedAt` 중 하나만 남기는 단일화 — `students_tab.dart` 사용처 마이그레이션 선행

엔티티 파생 getter/메서드: `effectiveStatus`(수동등록·미연결 시 active), `canSharePractice({practiceShareEnabled})`, `isExpired`, `isPast`, `hasValidSubscription`, `daysUntilPast`, `daysSinceExpired`, `hasPreviousSchedule`, `previousScheduleLabel`. (← `teacher_student_relation.dart`)

### NotificationSetting 엔티티 (관계 단위 알림 설정)

코드: `features/relationship/domain/entities/notification_setting.dart`

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` / `userId` / `targetUserId` | String | 식별자 / 설정 소유자 / 상대방 |
| `pushEnabled` | bool | 푸시 알림 (기본 true) |
| `practiceShareEnabled` | bool | 연습 현황 공유 (학생 전용, active일 때만 실제 공유) |
| `lessonReminderEnabled` | bool | 레슨 리마인더 (기본 true) |
| `paymentReminderEnabled` | bool | 입금 안내 (기본 true) |
| `createdAt` / `updatedAt` | DateTime | 생성 / 수정 시각 |

`NotificationSetting.defaultSetting({userId, targetUserId})` 팩토리 제공. (← `notification_setting.dart`)

### TeacherStudentRelationRepository 메서드

코드: `features/relationship/domain/repositories/teacher_student_relation_repository.dart` (Mock + Remote 이중 구현)

- 조회: `getById`, `getRelation`, `getByTeacher`, `getByStudent`, `getByTeacherAndStatus`, `getActiveByTeacher`, `getExpiredByTeacher`, `getPastByTeacher`, `getManuallyRegisteredByTeacher`, `getTrialBookedByTeacher`
- 명령: `create`, `update`, `delete`(취소된 체험만)
- 상태 전이: `onSubscriptionIssued`, `onSubscriptionExpired`, `onTrialBooked`, `onTrialCancelled`, `onRelationshipTerminated`, `processExpiredToPast`(일일 배치, expired 30일+ → past)
- 스케줄 기록(재등록 복원): `recordSchedule`, `getPreviousSchedule`
- 알림 설정: `getNotificationSetting`, `saveNotificationSetting`, `deleteNotificationSetting`

### Provider 구성

코드: `features/relationship/presentation/providers/relationship_providers.dart`

| Provider | 용도 |
|----------|------|
| `teacherStudentRelationRepositoryProvider` | Repository (keepAlive, Mock/Remote 전환) |
| `relationshipByIdProvider(id)` | ID로 관계 조회 |
| `teacherStudentRelationProvider({teacherId, studentId})` | 선생님-학생 관계 조회 |
| `teacherRelationshipsProvider(teacherId)` / `studentRelationshipsProvider(studentId)` | 측별 전체 관계 |
| `teacherRelationshipsByStatusProvider({teacherId, status})` | 상태별 관계 |
| `activeStudentsProvider` / `expiredStudentsProvider` / `pastStudentsProvider` / `trialBookedStudentsProvider` / `manuallyRegisteredStudentsProvider` | 상태별 학생 목록(teacherId) |
| `relationshipNotificationSettingProvider({userId, targetUserId})` | 관계 단위 알림 설정 |
| `previousScheduleProvider({teacherId, studentId})` | 재등록 복원용 직전 스케줄 |
| `ScheduleRecorder` (Notifier) | 정기 레슨 확정/변경 시 스케줄 기록 |

### 코드 위치 보강

| 레이어 | 파일 |
|--------|------|
| 엔티티 | `relationship/domain/entities/{teacher_student_relation,relationship_status,notification_setting}.dart` |
| Repository 인터페이스 | `relationship/domain/repositories/teacher_student_relation_repository.dart` |
| Repository 구현 | `relationship/data/repositories/{mock,remote}_teacher_student_relation_repository.dart` |
| Provider | `relationship/presentation/providers/relationship_providers.dart` |
| Facade | `relationship/relationship_facade.dart` |
