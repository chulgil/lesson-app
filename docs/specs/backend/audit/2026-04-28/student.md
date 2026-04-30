# Student 도메인 백엔드 점검 (Phase 1C)

> 점검일: 2026-04-28
> 점검자: Claude (Phase 1C)
> 대상: `backend/app/api/v1/students.py` (10 endpoints), `backend/app/models/student.py`, `backend/app/schemas/student.py`, `backend/app/services/student_service.py`
> 비교 SSOT: `docs/specs/student/enrollment_management_ux_spec.md`

## 1. SSOT 위치

| 영역 | SSOT |
|------|------|
| Status Triage UX (배너·필터·archive) | `docs/specs/student/enrollment_management_ux_spec.md` (2026-04-24, Phase 1~6 완료) |
| RosterSummary 데이터 모델 | 위 스펙 §4.1 — **현재 프론트 전용** (`features/students/domain/entities/roster_summary.dart`) |
| §7.119 휴강 의미론 | 위 스펙 §10.8 — `LessonStatus.cancelledByTeacher` 사용 강제 |
| §10 Bulk Teacher Actions | 위 스펙 §10 — **신규 설계, 백엔드 미구현 자연스러움** |
| Student status 4-enum | 백엔드 `models/student.py` `StudentStatus` (trial/active/paused/inactive) |

**결론**: Status Triage 의 SSOT 는 spec + Flutter 프론트. 백엔드 `students.py` 는 기본 CRUD 만 보유, triage·bulk 신호 없음.

---

## 2. 점검 매트릭스

| # | 요구사항 (스펙 §) | 프론트 코드 | 백엔드 endpoint | 백엔드 model | 판정 |
|---|------------------|------------|-----------------|--------------|------|
| 1 | §4.1 RosterSummary — 학생 status 별 카운트(expiring/unpaid/trial) + ID set 단일 API 노출 | `features/students/presentation/providers/student_roster_summary_provider.dart` (Phase 1, 커밋 `24c631f3`) | **부재** (예: `GET /students/summary`) | — | **MISSING** |
| 2 | §3.2 4축 필터 (expiring/unpaid/trial/archive) — 백엔드 `?status=` 쿼리에 추가 의미 필터 지원 | `features/students/presentation/providers/grouped_students_provider.dart` | `GET /students?status=` 만 — Student.status enum (trial/active/paused/inactive) 한정 | `Student.status` (4값) | **FAIL** (필터 축 mismatch — expiring/unpaid 는 Subscription 결합 필요) |
| 3 | §1.3 만료 학생 영구 보관 (archive — soft 보존) | 프론트 archive chip 필터 | `DELETE /students/{id}` 가 `student.status = "inactive"` 로 soft-delete (`student_service.py:123`) | `Student.status = inactive` | **PASS** (soft 보존은 동작, archive 필터링은 §2 의 백엔드 의미론 부재로 분리 처리 필요) |
| 4 | §7.119 휴강 의미론 — student status 별도 paused 케이스 (active/paused/quit 분리) | 프론트 `StudentStatus.paused` 사용 | `PATCH /students/{id}/status` 에서 `paused` 허용 (`student_service.py:100` `valid_statuses`) | `StudentStatus.paused` 존재 | **PASS** (휴강 학생 상태) |
| 5 | §10.8 휴강 레슨 상태 — `LessonStatus.cancelledByTeacher` 분리 (수강권 차감 X, reschedule O) | 프론트 `BulkTeacherActionService` (설계 단계) | Student 도메인 외 — `models/lesson.py` LessonStatus 에 `cancelledByTeacher` 정의됨 | `Lesson.status` enum 보유 | **PASS** (모델 enum 만, bulk endpoint 부재는 §6 항목) |
| 6 | §10.3 B1 휴강 공지 — `POST /students/bulk/cancel-lessons-on-date` (studentIds + targetDate + reason → cancelledByTeacher 일괄 전환 + 알림 fan-out) | 신규 설계 (미구현) | **부재** | — | **MISSING** (스펙상 신규 설계, 백엔드 부재 자연스러움) |
| 7 | §10.3 B2 일괄 메시지 — `POST /students/bulk/broadcast-message` (studentIds + title + body → generalAnnouncement 알림 fan-out) | 신규 설계 (미구현) | **부재** | — | **MISSING** |
| 8 | §10.3 B1 프리뷰 — `POST /students/bulk/preview-lessons` (studentIds + targetDate → 영향 레슨 목록) | 신규 설계 (미구현) | **부재** | — | **MISSING** |
| 9 | §3.4 수강권 만료 알림 (D-14/D-7/D-1/D-0 스케줄 등록) | 프론트 `SubscriptionExpiryNotificationService` (Phase 5a) | scheduler 라우터 4 endpoints 보유, 단 student_id × subscription expiry 트리거 endpoint 명시 부재 | `Notification` 모델 보유 | **STALE** (Subscription 도메인 audit 에서 재확인 — 본 audit 는 student 도메인 영향 한정) |
| 10 | §3.3 학생 카드 inline `practiceLevel` (good/normal/poor/onBreak) — list response 포함 | 프론트 카드 표시 | `GET /students` Response 에 `practice_level` 포함됨 (`schemas/student.py:38`) | `Student.practice_level` (PracticeLevel enum) | **PASS** |

---

## 3. 갭 상세

### 갭 1 — RosterSummary endpoint 부재 (#1, P1)

- **현황**: 프론트 `studentRosterSummaryProvider` 가 `studentsNotifierProvider` 를 watch 한 뒤 클라이언트에서 N 학생 × M 수강권 순회로 카운트 + ID set 계산.
- **영향 범위**: 학생 수가 늘어날수록 (예: 500명+) 클라이언트 계산 비용 누적. 수강관리 탭 진입 지연. Triage Banner 의 카운트는 페이지네이션 없는 전체 학생 풀이 필요해 `GET /students` 의 size limit 와 충돌.
- **우선순위**: **P1** (기능은 동작하나 확장성·UX 지연 리스크)
- **권장 조치**:
  ```
  GET /students/summary
  Query: ?teacher_id=auto (current user)
  Response:
  {
    "expiring_count": int,
    "unpaid_count": int,
    "trial_count": int,
    "archived_student_ids": [str],
    "expiring_student_ids": [str],
    "unpaid_student_ids": [str],
    "trial_student_ids": [str]
  }
  ```
  - 서버 측에서 `Student JOIN Subscription` 으로 단일 쿼리 집계.
  - 응답 캐싱 (60s TTL) 검토.

### 갭 2 — `?status=` 쿼리 의미 mismatch (#2, P1)

- **현황**: `GET /students?status=` 가 `StudentStatus` enum (trial/active/paused/inactive) 만 인식. 프론트의 4축 필터(expiring/unpaid/trial/archive)는 Subscription 결합 의미론을 가지므로 직접 매핑 불가.
- **영향 범위**: 프론트가 전체 학생 리스트를 받아 클라이언트에서 필터링 — 페이지네이션 비효율.
- **우선순위**: **P1**
- **권장 조치**: 갭 1 의 `/students/summary` 가 ID set 을 반환하므로 `GET /students?ids=a,b,c` 보조 쿼리로 ID 기반 조회 또는 `?triage_filter=expiring|unpaid|trial|archive` 신규 enum 추가. 후자는 백엔드가 Subscription 의미론을 알아야 하므로 갭 1 이후 후속 작업.

### 갭 3 — Bulk Teacher Actions endpoints 부재 (#6, #7, #8, P2)

- **현황**: 스펙 §10 은 2026-04-24 작성된 신규 설계. `BulkTeacherActionService` 는 프론트 도메인 서비스 인터페이스만 정의되고 구현/엔드포인트 모두 미구현.
- **영향 범위**: §7.119 의 휴강 공지 / 일괄 메시지 UX 자체가 아직 미배포. 백엔드 부재가 현 시점 사용자 영향 없음.
- **우선순위**: **P2** (스펙대로 신규 설계 단계)
- **권장 endpoint 시그니처**:

  ```
  POST /students/bulk/preview-affected-lessons
  Body: { "student_ids": [str], "target_date": "YYYY-MM-DD" }
  Response: { "lessons": [LessonResponse] }

  POST /students/bulk/cancel-lessons-on-date
  Body: { "student_ids": [str], "target_date": "YYYY-MM-DD", "reason": str | null }
  Response: {
    "cancelled_lesson_count": int,
    "notified_student_count": int,
    "skipped_student_ids": [str]
  }
  Side-effect: 각 매칭 Lesson.status = "cancelledByTeacher" (NOT generic "cancelled" — §10.8 차감/reschedule 의미론 보존),
              학생별 Notification(type=lessonCancelled) fan-out.

  POST /students/bulk/broadcast-message
  Body: { "student_ids": [str], "title": str, "body": str }
  Response: { "notified_count": int }
  Side-effect: Notification(type=generalAnnouncement) fan-out.
              `generalAnnouncement` enum 이 backend `models/notification.py` 에 없으면 추가 필요 (사전 점검 후속).
  ```
  - 권한: 모두 `get_current_teacher` 강제. teacher_id 자동 resolve.
  - 트랜잭션: B1 은 원자성 보장 (개별 lesson update 실패 시 skip 카운트로 부분 성공 허용 — 스펙 §10.7).

### 갭 4 — `STALE` 항목 — 만료 알림 스케줄러 (#9, P2 — Subscription audit 위임)

- **현황**: `scheduler.py` 라우터에 4 endpoints 가 있으나 student/subscription 만료 트리거의 백엔드-주도 스케줄링 여부 불명.
- **위임**: Phase 1D Subscription 도메인 점검에서 재확인.

---

## 4. 결론

- **총 점검 항목**: 10
- **PASS**: 4 (#3 archive soft-delete, #4 paused enum, #5 cancelledByTeacher enum, #10 practice_level 응답 포함)
- **FAIL**: 1 (#2 `?status=` 의미 mismatch)
- **MISSING**: 4 (#1 RosterSummary, #6/#7/#8 Bulk Actions 3종)
- **STALE**: 1 (#9 만료 알림 스케줄러 — Subscription audit 위임)

**Patch Plan 권장 여부**: **YES**

| 우선순위 | 작업 | 근거 |
|---------|------|------|
| P1 | `GET /students/summary` 신설 + `Student JOIN Subscription` 집계 쿼리 | Status Triage UX 의 핵심 데이터 흐름. 학생 수 확장성. |
| P1 | `?status=` 의미 확장 (`?triage_filter=` 신규 enum) | summary 의 ID set 으로 우회 가능하나 페이지네이션 효율 위해 권장. |
| P2 | `POST /students/bulk/{preview-affected-lessons,cancel-lessons-on-date,broadcast-message}` 3종 신설 | §10 Bulk Teacher Actions UX 미배포 상태. 프론트 구현과 동기 진행. |
| P2 | `Notification.type` 에 `generalAnnouncement` enum 추가 (사전 확인) | B2 broadcast 의존성. |

**Lore 후보** (patch plan 커밋 시):
- `Lore-directive`: `/students/summary` 는 Status Triage UX 의 SSOT. 카운트 계산을 클라이언트가 중복 수행 금지.
- `Lore-constraint`: B1 휴강 공지는 반드시 `cancelledByTeacher` 로만 전환 — generic `cancelled` 는 reschedule 막힘으로 §10.8 위반.
- `Lore-rejected`: `Student.status` enum 에 expiring/unpaid 추가 — 의미론적으로 Subscription 결합 결과이지 Student 본질 상태가 아님.
