# 프론트엔드 ↔ 백엔드 필드 대조 검증

> 검증일: 2026-05-04
> 프론트: Flutter entities (features/*/domain/entities/)
> 백엔드: SQLAlchemy models (backend/app/models/)

---

## 검증 결과 요약

| 도메인 | 일치 | 프론트에만 있음 | 백엔드에만 있음 | 판정 |
|--------|------|---------------|---------------|------|
| UnifiedLessonRequest | 23/26 | 3 | 8 | ⚠️ |
| RequestEvent | 14/14 | 0 | 0 | ✅ |
| ScheduleConfirmationCard | 8/8 | 8 | 2 | ⚠️ |
| Subscription | 27/28 | 1 | 1 | ✅ |
| SubscriptionProposal | 20/20 | 6 | 0 | ⚠️ |
| SubscriptionTemplate | 6/6 | 10 | 4 | ❌ |
| SubscriptionUsage | 4/4 | 4 | 0 | ⚠️ |
| Student | 25/27 | 2 | 2 | ✅ |
| ClassMembership | 8/8 | 3 | 3 | ✅ |
| Lesson | 14/14 | 4 | 2 | ⚠️ |
| TeacherStudentRelation | 18/18 | 3 | 5 | ⚠️ |
| LessonBooking | 9/9 | 0 | 2 | ✅ |

---

## 상세 검증

### 1. SubscriptionTemplate — ❌ 불일치 심각

프론트엔드에만 있는 필드 (백엔드 DB에 없음):
| 프론트 필드 | 타입 | 필요 여부 |
|------------|------|----------|
| `ownerId` | String | ⚠️ teacher_id와 동일 개념이나 이름 불일치 |
| `ownerType` | SubscriptionTemplateOwnerType | ❌ 백엔드에 enum 없음 |
| `totalLessons` | int | ⚠️ 백엔드는 `lessons_count` |
| `lessonDurationMinutes` | int | ❌ 백엔드에 없음 |
| `validityDays` | int | ❌ 백엔드에 없음 (duration_months만 있음) |
| `price` | int | ⚠️ 백엔드는 `amount` |
| `displayOrder` | int | ❌ 백엔드에 없음 |
| `rescheduleAllowance` | int | ❌ 백엔드에 없음 |
| `isAutoProposalEnabled` | bool | ❌ 백엔드에 없음 (ProposalSettings에 분리) |
| `updatedAt` | DateTime | ✅ 있음 |

백엔드에만 있는 필드 (프론트에 없음):
| 백엔드 필드 | 타입 |
|------------|------|
| `lessons_per_month` | Integer |
| `duration_months` | Integer |

**필요 작업**: 백엔드 SubscriptionTemplate에 `lesson_duration_minutes`, `validity_days`, `display_order`, `reschedule_allowance` 컬럼 추가 필요. `owner_type` 지원 여부 결정 (학원 vs 개인).

### 2. SubscriptionProposal — ⚠️ 프론트에만 있는 필드 6개

| 프론트 필드 | 타입 | 백엔드 상태 |
|------------|------|-----------|
| `proposalType` | ProposalType (proposal/directIssue) | ❌ 없음 |
| `isRenewal` | bool | ❌ 없음 |
| `previousSubscriptionId` | String? | ❌ 없음 |
| `renewalInitiator` | RenewalInitiator? | ❌ 없음 |
| `rejectedAt` | DateTime? | ✅ 있음 |
| `isAppTransition` | bool | ✅ 있음 |

**필요 작업**: 갱신(renewal) 기능을 구현하려면 `is_renewal`, `previous_subscription_id`, `renewal_initiator` 컬럼 추가 필요. `proposal_type` 도 필요.

### 3. ScheduleConfirmationCard — ⚠️ 프론트에만 있는 필드 8개

| 프론트 필드 | 타입 | 백엔드 상태 |
|------------|------|-----------|
| `teacherName` | String | ❌ 없음 (join으로 해결 가능) |
| `instrument` | String? | ❌ 없음 |
| `cardType` | ScheduleCardType | ❌ 없음 (afterTrial/reEnrollment/additionalInstrument) |
| `totalLessons` | int? | ❌ 없음 (subscription join으로 해결 가능) |
| `lessonRequestId` | String? | ❌ 없음 |
| `suggestedDay2/Time2` | int?/String? | ❌ 없음 (다수 시간 제안) |
| `suggestedDay3/Time3` | int?/String? | ❌ 없음 |

**필요 작업**: `card_type`, `instrument`, `lesson_request_id` 컬럼 추가. 다수 시간 제안은 JSON 필드로 통합 가능. `teacherName`, `totalLessons`는 API 응답에서 join으로 해결.

### 4. SubscriptionUsage — ⚠️ 프론트에만 있는 필드 4개

| 프론트 필드 | 타입 | 백엔드 상태 |
|------------|------|-----------|
| `note` | String? | ❌ 없음 |
| `deducted` | bool | ❌ 없음 |
| `usageType` | UsageType | ⚠️ 백엔드 `type` (이름 불일치, 값은 동일) |
| `createdAt` | DateTime | ⚠️ 백엔드는 `used_at` (이름 불일치) |

**필요 작업**: `note`, `deducted` 컬럼 추가. API 응답에서 필드명 매핑 (type→usageType, used_at→createdAt).

### 5. Lesson — ⚠️ 프론트에만 있는 필드

| 프론트 필드 | 타입 | 백엔드 상태 |
|------------|------|-----------|
| `studentNote` | String? | ❌ 없음 |
| `travelTimeMinutes` | int | ❌ 없음 (ClassMembership에 있음) |
| `subscriptionId` | String? | ❌ 없음 |
| `isPreview` | bool | ❌ 클라이언트 전용 (DB 불필요) |

**필요 작업**: `student_note`, `subscription_id` 컬럼 추가 고려. `travelTimeMinutes`는 membership join으로 해결. `isPreview`는 클라이언트 전용이므로 DB 불필요.

### 6. TeacherStudentRelation — ⚠️ 프론트에만 있는 필드

| 프론트 필드 | 타입 | 백엔드 상태 |
|------------|------|-----------|
| `lastScheduleRecordedAt` | DateTime? | ⚠️ 백엔드는 `schedule_recorded_at` (이름 약간 다름) |

백엔드에만 있는 필드:
| 백엔드 필드 | 타입 |
|------------|------|
| `invite_code` | String(10) |
| `can_view_practice` | Boolean |
| `can_comment` | Boolean |
| `can_suggest_assignments` | Boolean |
| `disconnected_at` | DateTime |

→ 이들은 프론트에서 별도 설정 화면에서 사용될 가능성. 현재 엔티티에 미포함이지만 API 응답으로 내려줄 수 있음.

### 7. UnifiedLessonRequest — ⚠️ 프론트에만 있는 필드

| 프론트 필드 | 타입 | 백엔드 상태 |
|------------|------|-----------|
| `academyId` | String? | ✅ 있음 |
| `proposals` | List\<TimeProposal\> | ⚠️ 백엔드는 `time_proposals` (JSON) |

백엔드에만 있는 필드 (프론트 엔티티에 없음):
| 백엔드 필드 | 용도 |
|------------|------|
| `preferred_timing` | afterConsultation 등 |
| `keep_previous_schedule` | 재등록 시 이전 스케줄 유지 |
| `previous_lesson_day/time/duration` | 재등록 학생 이전 스케줄 |

→ 프론트에서 재등록 플로우 구현 시 필요할 수 있으나 현재 미사용.

---

## Enum 불일치

| 엔티티 | 프론트 Enum | 백엔드 Enum | 차이 |
|--------|-----------|-----------|------|
| ScheduleConfirmationCard | `ScheduleCardStatus` (pending, confirmed, **changedTime**, dismissed) | `ConfirmationCardStatus` (pending, confirmed, **rejected**, expired) | `changedTime` vs `rejected`, `dismissed` vs `expired` |
| TeacherStudentRelation | `RelationshipStatus` (trialBooked, active, expired, past) | `RelationStatus` (+pending, +inactive, +disconnected) | 프론트에 pending/inactive/disconnected 없음 |
| SubscriptionTemplate | 프론트에 `SubscriptionTemplateOwnerType` | 백엔드에 없음 | 학원 소유 구분 미지원 |

---

## 우선순위별 필요 작업

### P0 — Mock→Remote 전환 시 즉시 필요

| # | 작업 | 영향 |
|---|------|------|
| 1 | SubscriptionTemplate에 `validity_days`, `lesson_duration_minutes`, `display_order` 컬럼 추가 | 템플릿 카드 UI에서 사용 |
| 2 | ScheduleConfirmationCard에 `card_type`, `instrument`, `lesson_request_id` 컬럼 추가 | 확인 카드 UI에서 사용 |
| 3 | SubscriptionTemplate 필드명 매핑 정리 (ownerId↔teacher_id, totalLessons↔lessons_count, price↔amount) | API 직렬화에서 alias 처리 |
| 4 | ScheduleCardStatus enum 통일 (changedTime vs rejected, dismissed vs expired) | 상태 표시 불일치 |

### P1 — 기능 완성도

| # | 작업 |
|---|------|
| 5 | SubscriptionProposal에 renewal 관련 4개 컬럼 추가 |
| 6 | SubscriptionUsage에 `note`, `deducted` 컬럼 추가 |
| 7 | Lesson에 `student_note`, `subscription_id` 컬럼 추가 |

### P2 — 나중에

| # | 작업 |
|---|------|
| 8 | 학원(academy) owner_type 지원 |
| 9 | RelationshipStatus 프론트/백 통일 |
