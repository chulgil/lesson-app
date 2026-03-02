# 레슨 장소 선택 및 관리

> 마지막 업데이트: 2026-03-03
> 관련 엔티티: [lesson_location.md](../../schema/entities/lesson_location.md)
> 관련 스펙: [lesson_schedule.md](lesson_schedule.md), [quick_add_lesson.md](quick_add_lesson.md)

---

## 1. 개요

### 1.1 문제

- DB와 엔티티에 `LessonLocation`(5가지 유형, 16개 필드)이 완전히 설계되어 있으나, **레슨 생성/수정 화면 어디에도 장소 선택 UI가 없음**
- 선생님이 레슨 장소를 지정할 방법이 없고, 학생이 레슨 장소를 확인할 수 없음
- 학원 레슨실, 자택 스튜디오, 학생 방문, 온라인 등 다양한 장소를 오가는 음악 레슨 특성이 반영되지 않음

### 1.2 목표

> **핵심 원칙: "한 번 설정, 자동 적용, 필요 시 변경"**

| 목표 | 설명 |
|------|------|
| 빠른 레슨 생성 유지 | 학생 선택 → 장소 자동 프리필. 기존 3탭 플로우 유지 |
| 직관적 장소 관리 | 프로필에서 장소 사전 등록 + 레슨 폼에서 즉석 추가 |
| 학생별 기본 장소 | 학생마다 고정 장소를 지정하면 매번 선택할 필요 없음 |
| 장소 변경 알림 | 기존 레슨의 장소 변경 시 학생/학부모 자동 알림 |

### 1.3 벤치마크

| 서비스 | 핵심 패턴 | 차용 |
|--------|----------|------|
| **Teachworks** | 학생 프로필에 기본 장소 설정 → 레슨 폼 자동 프리필 | ✅ 학생별 기본 장소 |
| **Fons** | Settings에서 장소 사전 등록, 타이핑 시 자동완성 드롭다운 | ✅ 프로필 장소 관리 + 인라인 추가 |
| **Calendly** | 유형 칩(대면/온라인) → 상세 입력 | ✅ 유형 칩 필터 |
| **My Music Staff** | Zoom/FaceTime 링크를 Location에 저장, 원클릭 접속 | ✅ 온라인 링크 통합 |
| **Google Calendar** | 장소 변경 시 "Send update?" 다이얼로그 | ✅ 변경 알림 |

---

## 2. 장소 자동 프리필 로직

### 2.1 우선순위 체인

학생이 선택되면 다음 우선순위로 장소를 자동 선택한다:

```
1. Student.defaultLocationId  (학생별 기본 장소)
         ↓ null이면
2. LessonClass.defaultLocation (반별 기본 장소 — isDefault=true인 LessonLocation)
         ↓ null이면
3. 선생님의 기본 장소           (ownerId=teacherId, isDefault=true인 LessonLocation)
         ↓ null이면
4. 빈 상태 (선택 안 됨)
```

### 2.2 동작 예시

| 시나리오 | 학생 기본 | 반 기본 | 결과 |
|----------|---------|---------|------|
| 학원 학생 (기본 설정됨) | 레슨실 1 | 레슨실 1 | ⭐ 레슨실 1 |
| 학원 학생 (기본 미설정) | null | 레슨실 1 | ⭐ 레슨실 1 (반 기본) |
| 개인 학생 (자택 방문) | 학생집 | null | ⭐ 학생집 |
| 온라인 학생 | Zoom | null | ⭐ Zoom |
| 신규 학생 (설정 없음) | null | null | 빈 상태 → 선택 필요 |

### 2.3 "이번만" vs "기본으로 저장"

자동 프리필된 장소를 변경할 때:

```
┌──────────────────────────────────────────┐
│  장소를 변경하시겠습니까?                    │
│                                           │
│  🏫 레슨실 1  →  🏠 홈 스튜디오             │
│                                           │
│  ○ 이번 레슨만 변경                        │
│  ○ 앞으로 이 학생의 기본 장소로 저장        │
│                                           │
│         [취소]        [변경]               │
└──────────────────────────────────────────┘
```

- **이번만**: `Lesson.location`만 변경
- **기본으로 저장**: `Student.defaultLocationId`도 업데이트

---

## 3. 레슨 추가 화면 — 장소 선택 UI

### 3.1 위치

AddLessonScreen의 기존 섹션 사이에 장소 선택을 추가한다:

```
1. 학생 선택         ← 기존
2. 날짜/시간         ← 기존
3. 레슨 시간         ← 기존
4. ★ 레슨 장소 ★     ← 신규
5. 반복 설정         ← 기존
6. 곡명/노트         ← 기존
7. 알림 설정         ← 기존
```

### 3.2 UI 스펙 — 장소 선택 섹션

#### 상태 A: 학생 미선택 (비활성)

```
┌──────────────────────────────────────┐
│  레슨 장소                            │
│  ┌────────────────────────────────┐  │
│  │  학생을 먼저 선택하세요          │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

- 학생 선택 전에는 비활성 상태 (회색 텍스트)
- 학생 선택 후 자동 프리필되며 활성화

#### 상태 B: 장소 자동 프리필됨 (기본)

```
┌──────────────────────────────────────┐
│  레슨 장소                            │
│  ┌────────────────────────────────┐  │
│  │  🏫  레슨실 1                   │  │
│  │      서울시 강남구 테헤란로 123  │  │
│  │      ○○빌딩 3층                 │  │
│  │                          [변경] │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

- 자동 프리필된 장소를 카드 형태로 표시
- 아이콘 + 장소명 + 주소 (온라인이면 플랫폼명 + 링크)
- [변경] 탭 → 장소 선택 BottomSheet 열림

#### 상태 C: 장소 선택 BottomSheet

```
┌──────────────────────────────────────┐
│  레슨 장소 선택                 [✕]   │
├──────────────────────────────────────┤
│                                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐  │
│  │ 🏫   │ │ 🏠   │ │ 🚗   │ │ 💻 │  │
│  │ 학원 │ │스튜  │ │ 방문 │ │온라│  │
│  │      │ │디오  │ │      │ │인  │  │
│  └──────┘ └──────┘ └──────┘ └────┘  │
│  유형 필터 (ChoiceChip)              │
│                                      │
│ ─────────────────────────────────── │
│                                      │
│  ⭐ 레슨실 1 (기본)                   │
│     서울시 강남구 테헤란로 123         │
│                                      │
│  레슨실 2                             │
│     서울시 강남구 테헤란로 123 4층     │
│                                      │
│  레슨실 3                             │
│     서울시 서초구 반포대로 45          │
│                                      │
│ ─────────────────────────────────── │
│                                      │
│  [+ 새 장소 추가]                     │
│                                      │
└──────────────────────────────────────┘
```

**동작:**
1. 유형 칩 탭 → 해당 유형의 장소만 필터링
2. 장소 탭 → 선택 후 BottomSheet 닫힘
3. `+ 새 장소 추가` → 장소 추가 BottomSheet로 전환
4. 기본 장소는 ⭐ 표시, 목록 최상단

#### 상태 D: 온라인 장소 선택 시

온라인 유형 칩 탭 시 추가 필드 표시:

```
┌──────────────────────────────────────┐
│  💻 온라인 레슨                       │
│                                      │
│  ⭐ Zoom 레슨 (기본)                  │
│     https://zoom.us/j/123...         │
│                                      │
│  Google Meet                          │
│     https://meet.google.com/abc...   │
│                                      │
│  FaceTime                             │
│     (링크 없음)                       │
│                                      │
│ ─────────────────────────────────── │
│  [+ 새 온라인 장소 추가]              │
└──────────────────────────────────────┘
```

#### 상태 E: 장소 미설정 (신규 학생)

```
┌──────────────────────────────────────┐
│  레슨 장소 (선택)                     │
│  ┌────────────────────────────────┐  │
│  │  📍 장소를 선택하세요            │  │
│  │                     [선택하기]  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

- 장소는 **선택 사항** (필수 아님)
- 탭 → BottomSheet 열림

---

## 4. 장소 관리 화면 (프로필 > 레슨 장소)

### 4.1 진입 경로

```
프로필 탭 → 레슨 장소 관리 (리스트 아이템)
```

### 4.2 장소 목록 화면

```
┌──────────────────────────────────────┐
│  ← 레슨 장소 관리               [+]  │
├──────────────────────────────────────┤
│                                      │
│  🏫 학원 레슨실                       │
│  ────────────────────────────────── │
│  ⭐ 레슨실 1                         │
│     서울시 강남구 테헤란로 123 3층     │
│     메모: 주차 1시간 무료             │
│                                      │
│  레슨실 2                             │
│     서울시 강남구 테헤란로 123 4층     │
│                                      │
│  🏠 선생님 스튜디오                    │
│  ────────────────────────────────── │
│  ⭐ 홈 스튜디오                       │
│     서울시 서초구 반포대로 45 2층      │
│                                      │
│  💻 온라인                            │
│  ────────────────────────────────── │
│  ⭐ Zoom 레슨                        │
│     https://zoom.us/j/1234567890     │
│                                      │
│  Google Meet                          │
│     https://meet.google.com/abc-def  │
│                                      │
└──────────────────────────────────────┘
```

**인터랙션:**
- 유형별 그룹핑 (접기/펼치기 없이 전체 표시)
- ⭐ 기본 장소는 유형별 첫 번째
- 장소 탭 → 장소 상세/수정 화면
- 장소 길게 누르기 → 기본 설정, 비활성화, 삭제 메뉴
- [+] → 장소 추가 화면

### 4.3 장소 추가/수정 화면

```
┌──────────────────────────────────────┐
│  ← 장소 추가                  [저장]  │
├──────────────────────────────────────┤
│                                      │
│  장소 유형                            │
│  ┌──────┐ ┌──────┐ ┌──────┐         │
│  │ 🏫   │ │ 🏠   │ │ 🚗   │ ...     │
│  │ 학원 │ │스튜  │ │ 방문 │         │
│  └──────┘ └──────┘ └──────┘         │
│                                      │
│  장소 이름 *                          │
│  ┌────────────────────────────────┐  │
│  │  레슨실 1                      │  │
│  └────────────────────────────────┘  │
│                                      │
│  ── 대면 레슨 (학원/스튜디오/방문/외부) ── │
│                                      │
│  주소                                 │
│  ┌────────────────────────────────┐  │
│  │  서울시 강남구 테헤란로 123     │  │
│  └────────────────────────────────┘  │
│                                      │
│  상세 주소                            │
│  ┌────────────────────────────────┐  │
│  │  ○○빌딩 3층 301호              │  │
│  └────────────────────────────────┘  │
│                                      │
│  ── 또는 온라인 레슨 ──               │
│                                      │
│  플랫폼                               │
│  ┌──────┐ ┌──────┐ ┌──────────┐    │
│  │ Zoom │ │ Meet │ │ FaceTime │    │
│  └──────┘ └──────┘ └──────────┘    │
│                                      │
│  미팅 링크 (선택)                     │
│  ┌────────────────────────────────┐  │
│  │  https://zoom.us/j/123...      │  │
│  └────────────────────────────────┘  │
│                                      │
│  ── 공통 ──                          │
│                                      │
│  메모 (찾아오는 길, 주차 정보 등)      │
│  ┌────────────────────────────────┐  │
│  │  주차 1시간 무료. 엘리베이터    │  │
│  │  이용. 레슨 10분 전 도착 권장   │  │
│  └────────────────────────────────┘  │
│                                      │
│  ☑ 기본 장소로 설정                   │
│                                      │
└──────────────────────────────────────┘
```

**유형별 필드 노출:**

| 유형 | 주소 | 상세주소 | 플랫폼 | 미팅 링크 | 메모 |
|------|:---:|:------:|:-----:|:-------:|:---:|
| academyRoom | ✅ | ✅ | - | - | ✅ |
| teacherStudio | ✅ | ✅ | - | - | ✅ |
| studentHome | ✅ | ✅ | - | - | ✅ |
| externalPlace | ✅ | ✅ | - | - | ✅ |
| online | - | - | ✅ | ✅ | ✅ |

---

## 5. 학생 프로필의 기본 장소

### 5.1 학생 상세 화면에 기본 장소 표시

```
┌──────────────────────────────────────┐
│  김민서                               │
│  바이올린 · 화요일 15:00 · 60분       │
│                                      │
│  📍 기본 레슨 장소                     │
│  ┌────────────────────────────────┐  │
│  │  🏫 레슨실 1                    │  │
│  │  서울시 강남구 테헤란로 123 3층  │  │
│  │                        [변경]  │  │
│  └────────────────────────────────┘  │
│                                      │
│  ...                                 │
└──────────────────────────────────────┘
```

### 5.2 학생 등록/수정 시 기본 장소 설정

AddStudentScreen / EditStudentScreen에 기본 장소 선택 필드 추가:

```
┌──────────────────────────────────────┐
│  기본 레슨 장소 (선택)                 │
│  ┌────────────────────────────────┐  │
│  │  🏫 레슨실 1                    │  │
│  │                        [변경]  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

- 장소 선택 BottomSheet 재사용 (§3.2 상태 C와 동일)
- 선택 사항 (null 허용)

---

## 6. 레슨 카드에 장소 표시

### 6.1 선생님 앱 — 레슨 카드

```
┌──────────────────────────────────────┐
│  15:00 - 16:00                       │
│  김민서  바이올린                      │
│  📍 레슨실 1                          │
│  🎵 가보트 - Gossec                   │
└──────────────────────────────────────┘
```

### 6.2 학생 앱 — 레슨 카드

```
┌──────────────────────────────────────┐
│  15:00  박선생님  [바이올린]           │
│  📍 레슨실 1 · 서울시 강남구...        │
│  🎵 가보트 - Gossec                   │
└──────────────────────────────────────┘
```

- 장소 표시: 아이콘 + 장소명 + 주소 (1줄 truncate)
- 온라인: `💻 Zoom 레슨` + 탭하면 링크 열기
- 장소가 null이면 해당 줄 미표시

### 6.3 학생 앱 — 온라인 레슨 카드

```
┌──────────────────────────────────────┐
│  15:00  박선생님  [바이올린]           │
│  💻 Zoom 레슨                         │
│  ┌────────────────────────────────┐  │
│  │  🔗 수업 참여하기               │  │
│  └────────────────────────────────┘  │
│  🎵 가보트 - Gossec                   │
└──────────────────────────────────────┘
```

- 레슨 시작 30분 전~레슨 중에만 [수업 참여하기] 버튼 표시
- 탭 시 미팅 링크 열기

---

## 7. 장소 변경 알림

### 7.1 트리거

기존 레슨(예약 확정 상태)의 장소가 변경되면 자동 알림 발송.

### 7.2 알림 내용

```
📍 레슨 장소가 변경되었습니다

3월 5일(화) 15:00 바이올린 레슨
변경 전: 🏫 레슨실 1
변경 후: 🏠 홈 스튜디오 (서울시 서초구 반포대로 45)
```

### 7.3 알림 대상

| 대상 | 조건 |
|------|------|
| 학생 | 항상 |
| 학부모 | 학생이 미성년인 경우 |

### 7.4 알림 채널

- 인앱 알림 (Notification 엔티티)
- 푸시 알림 (FCM — 추후 구현)

---

## 8. 데이터 모델 변경

### 8.1 Student 엔티티 — `defaultLocationId` 추가

```dart
// frontend/lib/features/students/domain/entities/student.dart
class Student {
  // ... 기존 필드 ...
  final String? defaultLocationId;  // 기본 레슨 장소 ID
}
```

### 8.2 백엔드 Student 모델

```python
# backend/app/models/student.py
class Student(UUIDMixin, TimestampMixin, Base):
    # ... 기존 필드 ...
    default_location_id: Mapped[str | None] = mapped_column(
        String(36), nullable=True
    )
```

### 8.3 Lesson 엔티티 — `locationId` 추가

현재 `Lesson`에는 `LessonLocationInfo`(name+address만)가 있지만, `LessonLocation` 전체 참조가 필요:

```dart
// frontend/lib/features/lessons/domain/entities/lesson.dart
class Lesson {
  // ... 기존 필드 ...
  final String? locationId;           // LessonLocation ID (신규)
  final LessonLocationInfo? location; // 표시용 간략 정보 (기존 유지)
}
```

### 8.4 백엔드 Lesson 모델

```python
# backend/app/models/lesson.py
class Lesson(UUIDMixin, TimestampMixin, Base):
    # ... 기존 필드 ...
    location_id: Mapped[str | None] = mapped_column(
        String(36), ForeignKey("lesson_locations.id"), nullable=True
    )
    # location_name, location_address는 기존 유지 (비정규화 표시용)
```

---

## 9. 위젯/Provider 구현

### 9.1 신규 위젯

| 위젯 | 경로 | 용도 |
|------|------|------|
| `LessonLocationSelector` | `core/widgets/selectors/location_selector.dart` | 레슨 폼에 임베드되는 장소 선택 위젯 |
| `LocationPickerBottomSheet` | `features/students/presentation/widgets/location_picker_bottom_sheet.dart` | 유형 칩 + 장소 목록 BottomSheet |
| `LocationFormBottomSheet` | `features/students/presentation/widgets/location_form_bottom_sheet.dart` | 새 장소 추가 인라인 폼 |
| `LocationManagementScreen` | `features/profile/presentation/screens/location_management_screen.dart` | 프로필 > 장소 관리 화면 |

### 9.2 기존 Provider 활용

이미 구현된 Provider를 활용한다:

```dart
// 이미 존재 — frontend/lib/features/students/presentation/providers/location_providers.dart
@riverpod locationRepository(...)         // Repository 주입
@riverpod classLocations(classId)         // 반별 장소 목록
@riverpod teacherLocations(teacherId)     // 선생님 장소 목록
@riverpod defaultClassLocation(classId)   // 반별 기본 장소
@riverpod LocationNotifier(classId)       // CRUD (반별)
@riverpod TeacherLocationNotifier(teacherId) // CRUD (선생님별)
```

### 9.3 신규 Provider

```dart
// 학생의 자동 프리필 장소를 계산하는 Provider
@riverpod
Future<LessonLocation?> studentDefaultLocation(ref, String studentId) {
  // 1. Student.defaultLocationId 확인
  // 2. null이면 → ClassMembership → LessonClass의 기본 장소
  // 3. null이면 → Teacher의 기본 장소
  // 4. null이면 → null 반환
}
```

### 9.4 LessonLocationSelector 위젯 API

```dart
class LessonLocationSelector extends ConsumerWidget {
  /// Currently selected location (auto-filled or manually picked).
  final LessonLocation? selectedLocation;

  /// Called when location changes.
  final ValueChanged<LessonLocation?> onLocationChanged;

  /// Called when user wants to save this as student's default.
  final ValueChanged<LessonLocation>? onSetAsDefault;

  /// Student ID for auto-fill lookup.
  final String? studentId;

  /// Whether the field is enabled.
  final bool enabled;
}
```

---

## 10. 구현 순서

### Phase 1: 장소 관리 (프로필)
1. `LocationManagementScreen` — 장소 목록 표시/그룹핑
2. `LocationFormBottomSheet` — 장소 추가/수정 폼
3. 프로필 화면에 "레슨 장소 관리" 메뉴 아이템 추가
4. 기존 Mock 데이터 활용하여 UI 확인

### Phase 2: 레슨 폼에 장소 선택 추가
1. `LessonLocationSelector` 위젯 구현
2. `LocationPickerBottomSheet` 구현
3. `AddLessonScreen`에 장소 섹션 추가
4. `EditLessonScreen`에 장소 섹션 추가
5. 레슨 저장 시 `locationId` + `LessonLocationInfo` 저장

### Phase 3: 자동 프리필
1. `Student` 엔티티에 `defaultLocationId` 추가
2. `studentDefaultLocation` Provider 구현
3. 학생 선택 시 장소 자동 프리필 연동
4. "이번만/기본으로 저장" 다이얼로그

### Phase 4: 학생 화면 + 알림
1. 레슨 카드에 장소 표시 (선생님/학생 앱)
2. 온라인 레슨 — "수업 참여하기" 버튼
3. 장소 변경 시 자동 알림 발송
4. 학생 프로필에 기본 장소 표시/변경

---

## 11. 관련 파일

### 엔티티
- `frontend/lib/features/students/domain/entities/lesson_location.dart`
- `frontend/lib/features/lessons/domain/entities/lesson.dart`
- `frontend/lib/features/students/domain/entities/student.dart`

### Repository
- `frontend/lib/features/students/domain/repositories/location_repository.dart`
- `frontend/lib/features/students/data/repositories/mock_location_repository.dart`

### Provider
- `frontend/lib/features/students/presentation/providers/location_providers.dart`

### 스키마 문서
- `docs/schema/entities/lesson_location.md`

### 백엔드
- `backend/app/models/lesson.py` — LessonLocation, Lesson 모델
