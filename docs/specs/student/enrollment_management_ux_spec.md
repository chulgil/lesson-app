# 수강 관리 탭 UX 재설계 스펙 (Status Triage 모델)

> 작성일: 2026-04-24
> 상태: Phase 1~5 (서비스/프로바이더/테스트) + Phase 6 완료 · 설정 UI 토글은 후속 세션
> 담당 화면: `features/students/presentation/screens/students_tab.dart`
> 관련 스펙:
> - [student_class_system.md](./student_class_system.md)
> - [subscription_master.md](../subscription/subscription_master.md)
> - [subscription_renewal_spec.md](../subscription/subscription_renewal_spec.md)

**⚠️ 이 문서는 수강 관리 탭 UX 변경의 Single Source of Truth입니다.**

---

## 1. 문제 정의

### 1.1 배경
홈 네비게이션 **"수강관리"** 진입 시 탭 제목이 **"학생 관리"** 여서 용어 불일치 → 1차 라벨 통일 완료 (커밋 `93b0dc7a`).

그러나 라벨 통일만으로는 근본 UX 문제 해결 안 됨. 실제 선생님이 이 탭에 오는 3가지 이유가 현재 UI에 제대로 반영되지 않음.

### 1.2 선생님의 3가지 근본 질문

| # | 질문 | 현재 해결 방법 | 문제 |
|---|-----|---------------|------|
| Q1 | 특정 학생을 빠르게 찾기 | 검색창 | ✅ 동작 |
| Q2 | 곧 끊길 학생 파악 (돈 놓침) | 학생 상세 일일이 열기 | ❌ 한눈에 안 보임 |
| Q3 | 수강료 미납 파악 (현금흐름) | 없음 | ❌ 별도 화면 필요 |
| Q4 | 만료된 학생 재등록 | 검색 불가 (목록에서 사라짐) | ❌ 고립 |

### 1.3 해결 원칙
- **학생 = primary entity** (identity 보존, 검색/식별 편의)
- **수강권 상태 = visual layer** (배너·chip·카드 뱃지)
- **만료 학생 영구 보관** (archive, 삭제 없음)

---

## 2. 설계 방향: Status Triage

### 2.1 화면 계층 구조

```
┌─ 수강 관리 탭 ──────────────────────────────────┐
│ [A] Masthead (기존 유지)                         │
│     ENROLLMENTS · Programme of Enrollments       │
│     수강 관리                                    │
├─────────────────────────────────────────────────┤
│ [B] Triage Banner (신규)                         │
│     ┌──────┬──────┬──────┐                      │
│     │만료임박│입금대기│체험중│ ← 탭 → 해당 필터 적용 │
│     │ 3명  │ 2명  │ 1명  │                      │
│     └──────┴──────┴──────┘                      │
├─────────────────────────────────────────────────┤
│ [C] Search + Filter Chips (확장)                 │
│     🔍 검색바                                    │
│     [전체][활성][임박][입금대기][체험][보관]       │
├─────────────────────────────────────────────────┤
│ [D] Student List (카드 재설계)                   │
│     ┌─────────────────────────────┐             │
│     │ 김민지 · 바이올린             │             │
│     │ ━━━━━━━━━━━ 4/8회           │             │
│     │ D-10 만료 🔴                │             │
│     │ [갱신 제안] [레슨 추가]      │             │
│     └─────────────────────────────┘             │
└─────────────────────────────────────────────────┘
```

### 2.2 Tab-based Active/Archive 뷰 (방향 B 통합)

필터 chip 의 "보관" 이 선택된 경우에만 리스트가 archive 모드로 전환:
- 카드 스타일: grey-out + "재등록 제안" CTA 노출
- 만료일 역순 정렬 (최근 만료 먼저)
- 영구 보관 (삭제 없음)

---

## 3. 컴포넌트 스펙

### 3.1 Triage Banner (신규)

**위치**: Masthead 바로 아래, Search bar 위

**구성**: 3-칸 horizontal card row

| 칸 | 라벨 | 카운트 정의 | 색상 | 탭 동작 |
|---|-----|-----------|------|--------|
| 1 | 만료임박 | 활성 수강권(`SubscriptionStatus.active/expiringSoon`) 중 `endDate - today ≤ 14일` 학생 수 | `AppColors.paperAccent` (Vermillion) | 필터 `expiring` 적용 |
| 2 | 입금대기 | `Subscription.paymentConfirmed == false` 학생 수 | `AppColors.paperWarn` | 필터 `unpaid` 적용 |
| 3 | 체험중 | `ClassMembership.status == MembershipStatus.trial` 학생 수 | `AppColors.paperOk` | 필터 `trial` 적용 |

**디자인 토큰**:
- 각 칸: `BorderRadius.zero` (§7.113 각진 원칙)
- Border: `Border.all(color: 해당색, strokeAlignInside)`
- 숫자 타이포: `AppTypography.headingMedium`
- 라벨 타이포: `AppTypography.caption`

**0명 처리**: 카운트 0이면 카드를 회색 + non-clickable 로 disabled 표시 (공간 유지).

### 3.2 Filter Chips (확장)

기존 `StudentFilter` enum 에 수강권 상태 필터 추가:

| 기존 | 신규 추가 | 의미 |
|-----|---------|------|
| all / good / normal / poor / paused | **expiring** | 만료임박 (D-14 이내) |
| | **unpaid** | 입금대기 (pendingPayment) |
| | **trial** | 체험 중 |
| | **archive** | 만료 수강권만 있는 학생 |

연습 상태 필터(good/normal/poor)와 수강권 상태 필터(expiring/unpaid/trial/archive)는 **상호 배타** — chip 하나만 선택 가능 (기존 단일 선택 UX 유지).

### 3.3 Student Card (재설계)

**기존 카드에 추가되는 요소**:

```
┌─────────────────────────────────────┐
│ [아바타] 김민지 · 바이올린           │  ← 기존 헤더
│         ━━━━━━━━━━━━━━━ 4/8회      │  ← 신규: 진행 bar
│         D-10 만료 🔴                │  ← 신규: D-day chip
│         [갱신 제안] [레슨 추가]      │  ← 신규: 인라인 CTA
└─────────────────────────────────────┘
```

**진행 bar**:
- 횟수제: `usedLessons / totalLessons` 비율
- 월간제: 당월 사용률 `usedThisMonth / lessonsPerMonth`
- 색상: 기본 ink, 80%+ 사용 시 paperAccent

**D-day chip**:
- 월간제: 다음 입금 예정일 기준 `billingDay` 까지 남은 일수
- 횟수제: 예상 소진일 (최근 사용 속도 기반 — MVP 에서는 `endDate` 사용)
- 표시 규칙: D-14 이상이면 숨김, D-14~D-8 중성(ink), D-7~D-1 경고(paperAccent), D-0 이하 만료(paperError)

**인라인 CTA**:
- `[갱신 제안]` — `unified_subscription_sheet` 오픈 (기존 플로우 재사용)
- `[레슨 추가]` — `add_lesson_screen` 네비게이션 (기존)
- 버튼: `AppSpacing.buttonHeightSmall`, `§7.113` 각진

**Archive 모드 카드**:
- 헤더 grey-out (`AppColors.inkTertiary`)
- 진행 bar 숨김
- CTA: `[재등록 제안]` 만 노출
- 카드 하단 회색 메타: "2026-02-15 만료"

### 3.4 자동 갱신 알림 (신규)

**트리거**: 활성 수강권 기준

| 시점 | 알림 유형 | 메시지 예시 |
|-----|---------|-----------|
| D-14 | in-app 뱃지 | "김민지 학생 수강권이 14일 후 만료됩니다" |
| D-7 | in-app + push (선택) | "김민지 학생 수강권이 1주 후 만료 — 갱신 제안 보내기" |
| D-1 | in-app 강조 + push | "내일 김민지 학생 수강권 만료" |
| D-0 (만료일) | in-app + push | "김민지 학생 수강권이 오늘 만료되었습니다" |

**저장 위치**: `features/notifications/` 도메인 기존 구조 재사용
**스케줄러**: 앱 실행 시 `NotificationScheduleService` 가 다음 D-day 계산하여 등록

**설정 화면**: `settings` 도메인에 "수강권 만료 알림" 토글 추가
- 기본 ON
- D-14 / D-7 / D-1 / D-0 개별 토글

---

## 4. 데이터 구조

### 4.1 신규 Provider: `StudentRosterSummary`

```dart
// features/students/domain/entities/roster_summary.dart
class RosterSummary {
  final int expiringCount;
  final int unpaidCount;
  final int trialCount;
  final Set<String> archivedStudentIds;
  final Set<String> expiringStudentIds;
  final Set<String> unpaidStudentIds;
  final Set<String> trialStudentIds;
}

// features/students/presentation/providers/student_roster_summary_provider.dart
@riverpod
Future<RosterSummary> studentRosterSummary(
  StudentRosterSummaryRef ref,
  String teacherId,
) async {
  final students = await ref.watch(studentsNotifierProvider.future);
  // For each student, collect subscriptions + membership status
  // Compute counts + ID sets used by filter logic
  ...
}
```

**설계 근거**: 카운트와 ID set 을 함께 반환 — 배너 탭 시 필터에 전달할 ID 목록이 즉시 준비됨.

### 4.2 Archive 정의

**조건**: 학생이 과거 수강권을 보유했으나 현재 모든 수강권이 다음 상태:
- `SubscriptionStatus.expired` OR `SubscriptionStatus.paused` OR `endDate < today`
- **또한** active 수강권이 0개

**제외**: 수강권이 아예 없는 학생 (체험도 안 한 신규 초대 학생) — archive 에 포함 X

**영구 보관**: 삭제 없음. archive 학생도 `studentsProvider` 에는 계속 포함.

### 4.3 만료 임박 정의

- **기본 윈도우**: D-14 이내
- **계산**: `endDate.difference(today).inDays <= 14 && status == active`
- **월간제 (endDate null)**: 다음 `billingDay` 까지 남은 일수로 계산

---

## 5. 필터 로직 확장

```dart
// grouped_students_provider.dart 확장 지점
List<StudentWithMembership> _applyFilter(
  List<StudentWithMembership> students,
  StudentFilter filter,
  List<Subscription> subscriptions,
) {
  switch (filter) {
    case StudentFilter.expiring:
      return students.where((s) => _isExpiring(s, subscriptions, days: 14)).toList();
    case StudentFilter.unpaid:
      return students.where((s) => _hasStatus(s, subscriptions, SubscriptionStatus.pendingPayment)).toList();
    case StudentFilter.trial:
      return students.where((s) => _hasStatus(s, subscriptions, SubscriptionStatus.trial)).toList();
    case StudentFilter.archive:
      return students.where((s) => _isArchived(s, subscriptions)).toList();
    // 기존 필터 유지
    ...
  }
}
```

---

## 6. Phase 분해

| Phase | 내용 | 커밋 | 상태 |
|------|------|------|------|
| **1. Foundation** | `RosterSummary` 엔티티 + `studentRosterSummaryProvider` + `StudentFilter` enum 4축 확장 | `24c631f3` | ✅ 완료 |
| **2. Triage Banner** | `RosterTriageBanner` 위젯 + students_tab 통합 + 탭→필터 연결 | `a744d891` | ✅ 완료 |
| **3. Filter Chip 확장** | expiring/unpaid/trial/archive chip + ID set 기반 필터 로직 | `3f0800d2` | ✅ 완료 |
| **4. Card 재설계** | 진행 bar + D-day chip + 인라인 CTA + archive 모드 | `13e95096` | ✅ 완료 |
| **5a. 자동 갱신 알림 (서비스 계층)** | `SubscriptionExpiryNotificationService` + `SubscriptionExpiryReminderSettings` + Riverpod 프로바이더 + 단위 테스트 13건 | `11fb106e` | ✅ 완료 |
| **5b. 설정 UI 토글** | `NotificationSettingsScreen` 선생님 전용 섹션 + Hive `settings` 박스 영속 + master + D14/D7/D1/D0 개별 토글 | 본 커밋 | ✅ 완료 |
| **6. 문서 동기화** | enrollment_management_ux_spec 완료 처리 + notebook §7.117 기록 | `d45c8c6d` | ✅ 완료 |

**실제 파일**: Phase 1~4 (신규 3 + 수정 2 = 5) + Phase 5a (신규 3 + 테스트 1 = 4) + Phase 5b (수정 2 = 2) = 11 파일
**게이트**: Status Triage 모델 전 Phase 완료.

---

## 7. 비가역 결정 (Lore)

- **Lore-directive**: 학생 = primary entity. 수강권은 visual layer. 리스트 행 단위는 절대 수강권으로 전환하지 않는다.
- **Lore-constraint**: 만료 학생 영구 보관 — 자동 삭제 없음. 재등록 유도를 최우선.
- **Lore-rejected**: Two-tab (Active/Archive) 완전 분리 — 학생 탭 구조 복잡도 증가. 필터 chip 으로 충분.
- **Lore-rejected**: AI 이탈 예측 — 데이터 부족, 현 시점 검증 불가.

---

## 8. 리스크

| 리스크 | 등급 | 완화 |
|-------|------|------|
| Triage banner 카운트 계산 성능 (N 학생 × M 수강권) | MED | 기존 Provider 의 데이터 재사용, 앱당 로컬 계산 |
| 카드 높이 증가로 스크롤 길이 늘어남 | MED | 진행 bar 는 2px, D-day 는 inline chip — 카드 +12px 이내 |
| 영구 보관으로 리스트가 너무 커짐 (5년차 선생님) | LOW | archive 필터 기본 숨김, 전체 필터에서도 포함은 하되 하단 정렬 |
| 알림 권한 미부여 시 자동 갱신 알림 무용지물 | MED | in-app 뱃지로 fallback, 설정에서 권한 재요청 안내 |

---

## 9. UX 감정 기대치

| 시점 | 기존 | 재설계 후 |
|-----|------|---------|
| 화면 진입 | 혼란 | **안심** (배너가 우선순위 노출) |
| 만료 임박 파악 | 불안 | **통제감** (빨간 배너 1탭 접근) |
| 만료 학생 재등록 | 좌절 | **기회감** (보관 chip + CTA) |
| 현금흐름 파악 | 불가시 | **명료** (입금대기 배너) |

---

## 10. 선생님 일괄 작업 (Bulk Teacher Actions, §7.119)

> **도입 배경**: 수강 관리 탭의 "선택 모드" 는 기존 "수강권 일괄 발급" 경로였으나 실시나리오에서 거의 사용되지 않음 — 수강권은 학생별 조건이 다르고, 인라인 "갱신 제안"/"재등록 제안" CTA 로 1:1 발급이 자연스러움. 다중 선택이 실제로 가치 있는 업무 2종으로 **재설계** (2026-04-24).

### 10.1 유스케이스 (B1·B2)

| 기능 | 빈도 | 트리거 |
|------|------|--------|
| **B1. 휴강 공지** | 주 1회+ | "이번 금요일 개인사정으로 휴강" — 특정 날짜에 레슨이 있는 학생들에게 자동 공지 + 레슨 상태 `cancelledByTeacher` 전환 |
| **B2. 일괄 메시지** | 월 1~2회 | "발표회 7월 12일 참가 여부" — 선택 학생들에게 자유 메시지 발송 |

**삭제**: 기존 "수강권 일괄 발급" 경로 (`UnifiedSubscriptionSheet.show(studentIds: [a, b, c])` → `studentIds.first` silent drop 버그 포함).

### 10.2 UX 플로우

```
수강 관리 탭 헤더 [일괄 작업 아이콘 (tooltip: 일괄 작업)]
  ↓ 탭
선택 모드 ON (기존 Checkbox UI 재사용)
  ↓ N명 체크
하단 액션바: [휴강 공지] [메시지 보내기]
  ↓ 갈라짐
┌────────────────────┐    ┌────────────────────┐
│ 휴강 공지 화면     │    │ 메시지 바텀시트    │
│ 1. 날짜 선택       │    │ 1. multiline 입력  │
│ 2. 영향 레슨 프리뷰│    │ 2. [보내기]        │
│    (N명 · M건)     │    └────────────────────┘
│ 3. 사유 입력 (선택)│              ↓
│ 4. [휴강 확정]     │    AppNotification(generalAnnouncement)
└────────────────────┘    각 학생별로 fan-out
            ↓
  - 해당 주 target date 에 각 학생 레슨 탐색
  - status → cancelledByTeacher
  - lessonCancelled 알림 학생에게 전송
  - SnackBar "N명 · M건 레슨 휴강 완료"
```

### 10.3 도메인 서비스

```dart
abstract class BulkTeacherActionService {
  /// B1 — 특정 날짜에 `studentIds` 의 레슨이 있으면 `cancelledByTeacher` 로 전환하고 학생별 알림 발송.
  /// 반환: 실제로 취소된 레슨 수 (studentId 에 해당 날짜 레슨 없으면 스킵).
  Future<BulkCancelResult> cancelLessonsOnDate({
    required String teacherId,
    required List<String> studentIds,
    required DateTime targetDate,
    String? reason,
  });

  /// B2 — 선택 학생들에게 generalAnnouncement 알림 발송.
  /// 반환: 실제 발송된 알림 수 (= studentIds.length).
  Future<int> broadcastMessage({
    required String teacherId,
    required List<String> studentIds,
    required String title,
    required String body,
  });

  /// B1 프리뷰 — 실제 취소 전 영향 레슨 조회.
  Future<List<Lesson>> previewAffectedLessons({
    required List<String> studentIds,
    required DateTime targetDate,
  });
}

class BulkCancelResult {
  final int cancelledLessonCount;
  final int notifiedStudentCount;
  final List<String> skippedStudentIds;  // 해당 날짜 레슨 없음
}
```

### 10.4 알림 타입

기존 `NotificationType.lessonCancelled` 재사용 (B1). B2 는 `NotificationType.generalAnnouncement` — 없으면 새로 추가.

### 10.5 제거/수정 범위

| 변경 | 위치 |
|------|------|
| 제거 | `_buildBottomActionBar` 의 "수강권 발급" FilledButton (students_tab.dart) |
| 추가 | `_buildBottomActionBar` 의 [휴강 공지][메시지 보내기] 2 버튼 |
| 수정 | `Icons.check_box_outlined` tooltip "선택" → "일괄 작업" |
| 버그 픽스 | `_buildActiveFooter` line 1229: `teacherId: ''` → `ref.read(currentUserIdProvider)` |
| 신규 | `bulk_cancel_screen.dart`, `bulk_message_sheet.dart` |
| 신규 | `bulk_teacher_action_service.dart` + 테스트 |
| 신규 | `bulk_teacher_action_providers.dart` |

### 10.6 감정 설계

| 시점 | 감정 | 설계 응답 |
|------|------|----------|
| 헤더 아이콘 tooltip "일괄 작업" | **안심** (명확한 목적) | tooltip 재라벨 |
| 선택 모드 진입 | **집중** | 2 CTA 로 의사결정 축 단순화 |
| "휴강 공지" 탭 | **약간 불안** ("실수로 다 취소될까") | 확인 다이얼로그 + 영향 레슨 프리뷰 (N명 · M건) |
| 발송 완료 | **성취감** | SnackBar "N명 · M건 레슨 휴강 완료" |

### 10.7 리스크

| 리스크 | 완화 |
|-------|------|
| 휴강 공지 실수로 다수 레슨 상태 오염 | 프리뷰 다이얼로그 + 2단계 확인 ("정말 휴강 처리할까요?") |
| 알림 발송 부분 실패 | 개별 try/catch 로 부분 성공 허용 · SnackBar 로 실패 건 수 고지 |
| notification 권한 미부여 | in-app 뱃지 fallback (기존 §3.4 알림 인프라 재사용) |

### 10.8 수강권 차감 / Reschedule 의미론

**B1 휴강 공지 → 수강권 차감 없음 + 학생 reschedule 가능 보장**.

| 상태 | `isDeducted` | `allowsReschedule` | 결과 |
|------|--------------|--------------------|------|
| `LessonStatus.cancelled` (generic) | `false` | `false` | 차감 X · reschedule X (막힘) |
| `LessonStatus.cancelledByTeacher` | `false` | `true` | 차감 X · reschedule O (정상) |

`LessonRepository.cancelLesson(id)` 의 mock/remote 구현체는 둘 다 generic `LessonStatus.cancelled` 로 떨어뜨려 학생의 reschedule 경로를 끊는다. 따라서 `BulkTeacherActionService.cancelLessonsOnDate` 는 `cancelLesson()` 대신 **`updateLesson(lesson.copyWith(status: cancelledByTeacher))`** 로 명시 설정한다 — 어떤 repo 구현이 와도 동일한 의미론을 보장한다.

`useLesson()` 은 별도 호출이며 휴강에는 호출되지 않는다. → 수강권 잔여 횟수는 **변동 없음**(자동 환불도 아님, 차감도 아님). 학생이 reschedule 요청을 하면 새 레슨이 `scheduled` 로 생성되어 기존 수강권으로 진행.

### 10.9 Lore

- **Lore-directive**: 수강 관리 탭의 선택 모드는 "수강권 발급" 이 아닌 "일괄 공지/메시지" 를 위한 경로다. 수강권 발급은 1:1 인라인 CTA 로만 수행.
- **Lore-constraint**: 휴강 공지는 반드시 프리뷰 → 확인 2단계. 1탭 실행 금지.
- **Lore-rejected**: 수강권 일괄 발급 유지 — `studentIds.first` silent drop 버그가 있었고, 실제로 이 경로를 쓰는 선생님이 사실상 없음. 과감히 제거.
- **Lore-rejected**: B3 일괄 레슨 이동 / B4 일괄 결석 처리 — 기본 확장 범위에서 제외. 휴강+메시지 2종이 batch 수요의 90%+ 커버.

---

## 11. 변경 이력

| 날짜 | 변경 | 작성자 |
|-----|-----|-------|
| 2026-04-24 | 최초 작성 (v1 설계 확정) | Claude (CEO 리뷰) |
| 2026-04-24 | Phase 1~4 구현 완료 · Phase 5 대기로 상태 갱신 (커밋 `24c631f3` `a744d891` `3f0800d2` `13e95096`) | Claude |
| 2026-04-24 | Phase 6 문서 동기화 완료 (커밋 `d45c8c6d`) | Claude |
| 2026-04-24 | Phase 5a 자동 갱신 알림 서비스 계층 완료 (service + settings + providers + 13 tests GREEN) — 설정 UI 는 후속 세션 | Claude |
| 2026-04-24 | Phase 5b 설정 UI 토글 완료 (선생님 전용 섹션 + Hive 영속). Status Triage 전 Phase 종결 | Claude |
| 2026-04-24 | §10 선생님 일괄 작업 (§7.119) 설계 — 선택 모드 재설계: 수강권 일괄 발급 제거 → B1 휴강 공지 + B2 일괄 메시지 | Claude (CEO 리뷰) |
| 2026-04-27 | §10.8 차감/Reschedule 의미론 추가 — `cancelLesson()` 의 generic `cancelled` 폴백 회피 위해 `updateLesson(cancelledByTeacher)` 로 명시 (서비스 + 테스트 동기화) | Claude |
