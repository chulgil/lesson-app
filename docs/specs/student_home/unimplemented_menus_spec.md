# 미구현 메뉴 통합 스펙

> 마지막 업데이트: 2026-03-10
> 관련 이슈: #90, #91, #92, #93, #94

학생 프로필 탭(`StudentProfileTab`)에서 현재 `onTap: () {}` 또는 "준비 중" SnackBar로 처리된 5개 메뉴 항목의 구현 스펙.
마치 스마트폰 설정 앱의 하위 메뉴처럼, 각 항목을 탭하면 해당 기능 화면으로 진입한다.

**대상 메뉴:**

| # | 이슈 | 메뉴 | 현재 상태 | 복잡도 |
|---|------|------|----------|:------:|
| 1 | #90 | 프로필 수정 | `onTap: () {}` (무동작) | M |
| 2 | #91 | 연습 기록 내역 | `onTap: () {}` (무동작) | S |
| 3 | #92 | 연습 리마인더 | `onTap: () {}` (무동작) | M |
| 4 | #93 | 언어 설정 | SnackBar ("준비 중") | S |
| 5 | #94 | 이용약관/개인정보처리방침 | SnackBar ("준비 중") | S |

---

## 1. 프로필 수정 (Issue #90)

### 1.1 개요

학생이 자신의 기본 정보(이름, 악기, 연락처)를 직접 수정할 수 있는 편집 화면. 현재 프로필 헤더에 하드코딩된 "홍길동", "student@example.com", "바이올린" 등의 값을 실제 데이터로 교체하고, 편집 기능을 제공한다.

### 1.2 상세 동작

**진입 플로우:**
1. 프로필 탭 > 메뉴 섹션 > "프로필 수정" 탭
2. `StudentProfileEditScreen`으로 push 이동

**편집 가능 필드:**

| 필드 | 타입 | 필수 | 검증 규칙 |
|------|------|:----:|----------|
| 이름 | TextFormField | O | 1~20자, 공백만 불가 |
| 악기 | Dropdown / BottomSheet | O | 기존 악기 목록에서 선택 |
| 이메일 | TextFormField | X | 이메일 형식 검증 (입력 시) |
| 전화번호 | TextFormField | X | 숫자만, 10~11자리 |
| 학부모 연락처 | TextFormField | X | 숫자만, 10~11자리 |

**저장 플로우:**
1. "저장" 버튼 탭
2. 폼 검증 실행 (필수 필드 + 형식 검증)
3. 검증 실패 시: 해당 필드 아래 에러 메시지 표시
4. 검증 성공 시: 로딩 표시 -> Mock Repository 업데이트 -> "저장되었습니다" SnackBar -> pop

**예외 처리:**
- 변경 사항 없이 뒤로가기: 즉시 pop (확인 없음)
- 변경 사항 있는 상태에서 뒤로가기: "변경사항을 저장하지 않고 나가시겠습니까?" 확인 다이얼로그
- 저장 실패: "저장에 실패했습니다. 다시 시도해주세요." SnackBar

**데이터 연동:**
- 현재 `StudentProfileTab`의 프로필 헤더가 하드코딩("홍길동" 등)이므로, `currentUserIdProvider`로 학생 정보를 가져와 실제 데이터로 교체 필요
- 저장 후 프로필 탭 헤더에 즉시 반영 (`ref.invalidateSelf()`)

### 1.3 UI 구조

```
/student/profile/edit
┌──────────────────────────────────┐
│  <- 프로필 수정            [저장] │
├──────────────────────────────────┤
│                                  │
│         [프로필 이미지]            │
│         (카메라 아이콘)            │
│         * 이미지 변경은 향후 구현   │
│                                  │
│  ──────────────────────────────  │
│                                  │
│  기본 정보                        │
│  ┌──────────────────────────────┐│
│  │ 이름 *                       ││
│  │ [홍길동                    ] ││
│  ├──────────────────────────────┤│
│  │ 악기 *                       ││
│  │ [바이올린                ▼ ] ││
│  └──────────────────────────────┘│
│                                  │
│  연락처                           │
│  ┌──────────────────────────────┐│
│  │ 이메일                       ││
│  │ [student@example.com       ] ││
│  ├──────────────────────────────┤│
│  │ 전화번호                     ││
│  │ [010-1234-5678             ] ││
│  ├──────────────────────────────┤│
│  │ 학부모 연락처                 ││
│  │ [010-9876-5432             ] ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

### 1.4 관련 파일

| 구분 | 파일 경로 | 비고 |
|------|----------|------|
| **신규** | `features/student_home/presentation/screens/student_profile_edit_screen.dart` | 프로필 편집 화면 |
| **수정** | `features/student_home/presentation/screens/student_profile_tab.dart` | 프로필 수정 `onTap` 연결 + 헤더 하드코딩 제거 |
| **수정** | `core/router/app_routes.dart` | 라우트 상수 추가 |
| **수정** | `core/router/routes/` | GoRoute 등록 |
| **참조** | `features/students/domain/entities/student.dart` | Student 엔티티 (name, instrument, phone, email 등) |
| **참조** | `features/students/presentation/widgets/student_form/` | 기존 학생 폼 위젯 재사용 가능 (instrument_selector 등) |

---

## 2. 연습 기록 내역 (Issue #91)

### 2.1 개요

프로필 탭의 "연습 기록 내역" 메뉴를 탭하면 기존에 구현된 `RepertoireHistoryScreen`으로 이동한다. 라우트 `/practice/history`와 화면이 이미 존재하므로, `onTap` 콜백만 연결하면 된다.

### 2.2 상세 동작

**진입 플로우:**
1. 프로필 탭 > 메뉴 섹션 > "연습 기록 내역" 탭
2. `context.push('${AppRoutes.repertoireHistory}?studentId=$studentId')`
3. `RepertoireHistoryScreen`으로 이동

**기존 화면 기능 (이미 구현):**
- 레퍼토리 타임라인을 월별 그룹으로 표시
- 상단 요약 카드: 전체 레퍼토리 수, 완료 수, 진행 중 수
- 월별 섹션 헤더 + `RepertoireTimelineCard`
- 빈 상태: "아직 레퍼토리가 없습니다" 메시지
- 에러 상태: "다시 시도" 버튼

**조건:**
- `studentId`는 `currentUserIdProvider`에서 가져옴
- `studentId`가 비어있으면 빈 문자열 전달 (기존 화면에서 빈 상태 표시)

**예외 처리:**
- 데이터 로딩 실패: 기존 `RepertoireHistoryScreen`의 에러 UI 사용

### 2.3 UI 구조

별도 UI 신규 작성 불필요. 기존 `RepertoireHistoryScreen` 그대로 사용.

```
/practice/history?studentId=xxx
┌──────────────────────────────────┐
│  <- 레퍼토리 히스토리              │
├──────────────────────────────────┤
│                                  │
│  ┌ 요약 카드 ──────────────────┐ │
│  │ 전체 N곡  완료 N곡  진행 N곡 │ │
│  └──────────────────────────────┘│
│                                  │
│  2026년 3월 (N곡)                │
│  ┌ RepertoireTimelineCard ─────┐ │
│  │ 곡명 / 기간 / 상태           │ │
│  └──────────────────────────────┘│
│  ...                             │
└──────────────────────────────────┘
```

### 2.4 관련 파일

| 구분 | 파일 경로 | 비고 |
|------|----------|------|
| **수정** | `features/student_home/presentation/screens/student_profile_tab.dart` | "연습 기록 내역" `onTap` 연결 |
| **참조** | `features/practice/presentation/screens/repertoire_history_screen.dart` | 기존 히스토리 화면 (수정 불필요) |
| **참조** | `features/practice/presentation/providers/repertoire_history_provider.dart` | 기존 Provider (수정 불필요) |
| **참조** | `core/router/app_routes.dart` | `AppRoutes.repertoireHistory` 이미 존재 (`/practice/history`) |
| **참조** | `core/router/routes/practice_routes.dart` | GoRoute 이미 등록됨 |

---

## 3. 연습 리마인더 (Issue #92)

### 3.1 개요

매일 특정 시간에 "연습할 시간이에요!" 같은 로컬 알림을 보내기 위한 설정 화면. BottomSheet 형태로 시간/요일을 설정하고, ON/OFF 토글로 활성화한다. MVP 단계에서는 설정 UI만 구현하고, 실제 로컬 알림 발송은 향후 구현한다.

### 3.2 상세 동작

**진입 플로우:**
1. 프로필 탭 > 설정 섹션 > "연습 리마인더" 탭
2. `PracticeReminderBottomSheet` 표시 (모달)

**BottomSheet 기능:**

| 항목 | 동작 |
|------|------|
| ON/OFF 토글 | 리마인더 전체 활성화/비활성화 |
| 시간 선택 | TimePicker로 알림 시간 설정 (기본값: 17:00) |
| 요일 선택 | 7개 요일 칩 (월~일), 복수 선택 가능 (기본값: 월~금) |
| 메시지 미리보기 | 설정된 시간/요일 기반 안내 문구 표시 |

**데이터 저장:**
- Hive에 `PracticeReminderSettings` 저장
- 변경 즉시 자동 저장 (별도 저장 버튼 없음)
- 프로필 탭 subtitle에 현재 설정 요약 표시 (예: "매일 오후 5시" / "월수금 오후 7시" / "꺼짐")

**ON/OFF 동작:**
- OFF 전환 시: 시간/요일 선택 UI 비활성화 (greyed out), 설정값은 유지
- ON 전환 시: 이전 설정값 복원, 시간/요일 선택 활성화

**예외 처리:**
- 요일을 하나도 선택하지 않으면: "최소 1일을 선택해주세요" 안내 표시, OFF로 자동 전환
- 실제 알림 발송은 향후 `flutter_local_notifications` 연동 시 구현

**데이터 모델:**

```dart
// Hive에 저장할 연습 리마인더 설정
class PracticeReminderSettings {
  bool isEnabled;         // ON/OFF
  int hour;               // 시 (0~23, 기본값: 17)
  int minute;             // 분 (0~59, 기본값: 0)
  List<int> selectedDays; // 요일 (1=월 ~ 7=일, 기본값: [1,2,3,4,5])
}
```

### 3.3 UI 구조

```
BottomSheet (PracticeReminderBottomSheet)
┌──────────────────────────────────┐
│          ── (drag handle) ──     │
│                                  │
│  연습 리마인더            [ON/OFF]│
│                                  │
│  ──────────────────────────────  │
│                                  │
│  알림 시간                        │
│  ┌──────────────────────────────┐│
│  │        오후 5:00          ▼  ││
│  └──────────────────────────────┘│
│                                  │
│  반복 요일                        │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐│
│  │월│ │화│ │수│ │목│ │금│ │토│ │일││
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘│
│  (선택된 요일: primary 색상 fill)   │
│                                  │
│  ──────────────────────────────  │
│                                  │
│  ⓘ 설정한 시간에 연습 알림을       │
│    보내드립니다.                   │
│    * 알림 기능은 준비 중입니다.     │
│                                  │
└──────────────────────────────────┘
```

### 3.4 관련 파일

| 구분 | 파일 경로 | 비고 |
|------|----------|------|
| **신규** | `features/student_home/presentation/widgets/practice_reminder_bottom_sheet.dart` | 리마인더 설정 BottomSheet |
| **신규** | `features/student_home/domain/entities/practice_reminder_settings.dart` | 설정 엔티티 |
| **신규** | `features/student_home/presentation/providers/practice_reminder_provider.dart` | 설정 상태 관리 (@riverpod, Hive 저장) |
| **수정** | `features/student_home/presentation/screens/student_profile_tab.dart` | "연습 리마인더" `onTap` 연결 + subtitle 동적 표시 |
| **참조** | `features/student_home/presentation/providers/notification_settings_provider.dart` | 유사 패턴 참조 (Hive 저장 + @riverpod) |

---

## 4. 언어 설정 (Issue #93)

### 4.1 개요

현재 "한국어만 지원됩니다" SnackBar를 BottomSheet로 교체하여, 언어 목록에서 선택할 수 있는 UI를 제공한다. MVP 단계에서는 한국어만 실제 선택 가능하고, English는 "준비 중" 표시로 비활성화한다.

### 4.2 상세 동작

**진입 플로우:**
1. 프로필 탭 > 설정 섹션 > "언어" 탭
2. `LanguageBottomSheet` 표시 (모달)

**BottomSheet 기능:**

| 언어 | 상태 | 동작 |
|------|------|------|
| 한국어 | 선택됨 (체크 아이콘) | 탭 시: BottomSheet 닫힘 (변경 없음) |
| English | 비활성 | 탭 시: "English는 준비 중입니다" SnackBar |

**동작 상세:**
- 진입 시 현재 선택된 언어(한국어)에 체크 표시
- 한국어 탭: 이미 선택 상태이므로 BottomSheet 닫힘
- English 탭: SnackBar 표시, 선택 상태 변경 없음
- BottomSheet 외부 탭: 변경 없이 닫힘

**향후 확장 (Phase 4+):**
- `flutter_localizations` + `intl` 패키지 활용
- English 활성화
- 추가 언어 (일본어 등)
- Hive에 `locale` 저장
- 앱 전체 리빌드

### 4.3 UI 구조

```
BottomSheet (LanguageBottomSheet)
┌──────────────────────────────────┐
│          ── (drag handle) ──     │
│                                  │
│  언어 설정                        │
│                                  │
│  ──────────────────────────────  │
│                                  │
│  ┌──────────────────────────────┐│
│  │ 🇰🇷  한국어                ✓ ││
│  └──────────────────────────────┘│
│  ┌──────────────────────────────┐│
│  │ 🇺🇸  English      (준비 중)  ││
│  │      (텍스트 회색 처리)       ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

### 4.4 관련 파일

| 구분 | 파일 경로 | 비고 |
|------|----------|------|
| **신규** | `features/student_home/presentation/widgets/language_bottom_sheet.dart` | 언어 선택 BottomSheet |
| **수정** | `features/student_home/presentation/screens/student_profile_tab.dart` | "언어" `onTap` → BottomSheet 호출로 변경 |

---

## 5. 이용약관/개인정보처리방침 (Issue #94)

### 5.1 개요

앱 정보 화면(`AppInfoScreen`)의 "이용약관"과 "개인정보처리방침" 메뉴에서 현재 "준비 중" SnackBar를 표시하고 있다. 이를 스크롤 가능한 전문 뷰어 화면으로 교체한다. 두 문서 모두 동일한 뷰어 화면(`LegalDocumentScreen`)을 공유하며, 문서 종류를 파라미터로 구분한다.

### 5.2 상세 동작

**진입 플로우:**
1. 프로필 탭 > 설정 > 앱 정보 > "이용약관" 또는 "개인정보처리방침" 탭
2. `LegalDocumentScreen(type: LegalDocumentType.termsOfService)` 또는 `LegalDocumentScreen(type: LegalDocumentType.privacyPolicy)` 로 push 이동

**화면 기능:**
- AppBar에 문서 제목 표시 ("이용약관" 또는 "개인정보처리방침")
- 스크롤 가능한 본문 영역에 전문 텍스트 표시
- 하단에 최종 수정일 표시

**문서 데이터:**
- MVP 단계: 앱 내 하드코딩 (정적 문자열)
- 향후: 서버에서 가져오거나 웹뷰로 표시

**문서 타입 enum:**

```dart
enum LegalDocumentType {
  termsOfService,    // 이용약관
  privacyPolicy;     // 개인정보처리방침

  String get title {
    switch (this) {
      case LegalDocumentType.termsOfService:
        return '이용약관';
      case LegalDocumentType.privacyPolicy:
        return '개인정보처리방침';
    }
  }
}
```

**예외 처리:**
- 문서 내용이 비어있는 경우: "문서를 불러올 수 없습니다" 메시지 표시
- 향후 서버 연동 시: 로딩 / 에러 상태 추가

### 5.3 UI 구조

```
/settings/legal/:type
┌──────────────────────────────────┐
│  <- 이용약관 (또는 개인정보처리방침) │
├──────────────────────────────────┤
│                                  │
│  제1조 (목적)                     │
│  이 약관은 Lessonaza(이하 "앱")   │
│  이 제공하는 서비스의 이용 조건 및  │
│  절차에 관한 사항을 규정함을        │
│  목적으로 합니다.                  │
│                                  │
│  제2조 (정의)                     │
│  ① "서비스"란 앱이 제공하는 모든   │
│  음악 레슨 관리, 연습 기록,        │
│  스케줄 관리 기능을 말합니다.       │
│  ...                             │
│                                  │
│  (스크롤 가능)                    │
│                                  │
│  ──────────────────────────────  │
│  최종 수정일: 2026년 3월 10일      │
│                                  │
└──────────────────────────────────┘
```

### 5.4 관련 파일

| 구분 | 파일 경로 | 비고 |
|------|----------|------|
| **신규** | `features/student_home/presentation/screens/legal_document_screen.dart` | 법적 문서 뷰어 화면 |
| **신규** | `features/student_home/domain/entities/legal_document.dart` | `LegalDocumentType` enum + 문서 내용 상수 |
| **수정** | `features/student_home/presentation/screens/app_info_screen.dart` | "이용약관" / "개인정보처리방침" `onTap` → 뷰어 화면으로 push |
| **수정** | `core/router/app_routes.dart` | 라우트 상수 추가 |
| **수정** | `core/router/routes/` | GoRoute 등록 |

---

## 공통 사항

### 라우트 추가

| 화면 | 라우트 경로 | 비고 |
|------|------------|------|
| 프로필 수정 | `/student/profile/edit` | 신규 |
| 연습 기록 내역 | `/practice/history` | 기존 (연결만) |
| 연습 리마인더 | - | BottomSheet (라우트 불필요) |
| 언어 설정 | - | BottomSheet (라우트 불필요) |
| 이용약관 | `/settings/legal/terms` | 신규 |
| 개인정보처리방침 | `/settings/legal/privacy` | 신규 |

### student_profile_tab.dart 변경 요약

| 메뉴 | 현재 | 변경 |
|------|------|------|
| 프로필 수정 | `onTap: () {}` | `onTap` → 프로필 편집 화면 push |
| 연습 기록 내역 | `onTap: () {}` | `onTap` → `/practice/history?studentId=` push |
| 연습 리마인더 | `onTap: () {}`, subtitle "매일 오후 5시" 하드코딩 | `onTap` → BottomSheet 표시, subtitle 동적 |
| 언어 | SnackBar | `onTap` → BottomSheet 표시 |

### app_info_screen.dart 변경 요약

| 메뉴 | 현재 | 변경 |
|------|------|------|
| 이용약관 | `_showComingSoon` SnackBar | `onTap` → 뷰어 화면 push |
| 개인정보처리방침 | `_showComingSoon` SnackBar | `onTap` → 뷰어 화면 push |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-10 | 미구현 메뉴 5개 통합 스펙 초기 작성 (#90~#94) |
