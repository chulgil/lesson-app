# 커스텀 피드백 프리셋 관리 스펙

> 작성일: 2026-03-12
> 상태: 미구현

---

## 1. 개요

현재 피드백 프리셋은 9개가 하드코딩되어 있어 선생님이 자신만의 표현을 추가/편집/삭제할 수 없다. 선생님마다 전공 악기·교수법·학생 수준이 다르므로, 개인화된 프리셋 관리가 필수다.

**핵심 가치**: 선생님이 가장 자주 쓰는 피드백 문구를 3초 안에 입력할 수 있게 한다.

---

## 2. 현재 상태 (AS-IS)

| 항목 | 상태 |
|------|------|
| 프리셋 데이터 | `feedback_constants.dart`에 9개 하드코딩 |
| 사용 위치 | `LessonNoteEditor` (칩 행), `QuickFeedbackScreen` (칩 행) |
| 커스텀 | 불가능 — 추가/편집/삭제/순서변경 없음 |
| 저장소 | 없음 (상수) |

---

## 3. 목표 상태 (TO-BE)

### 3.1 UX 원칙

- **제로 설정 시작**: 기본 9개 프리셋으로 즉시 사용 가능 (첫 실행 UX 유지)
- **점진적 커스텀**: 사용하면서 자연스럽게 자기 것을 만들어가는 플로우
- **컨텍스트 내 편집**: 별도 설정 화면 대신, 프리셋 사용 화면에서 바로 편집

### 3.2 기능 범위

| 기능 | 우선순위 | 설명 |
|------|----------|------|
| 프리셋 추가 | HIGH | 새 문구 직접 입력 |
| 프리셋 삭제 | HIGH | 불필요한 프리셋 제거 |
| 프리셋 편집 | MEDIUM | 기존 문구 수정 |
| 순서 변경 | MEDIUM | 드래그&드롭으로 자주 쓰는 것을 앞으로 |
| 카테고리 분류 | LOW | 테크닉/평가/과제 등 그룹핑 |
| 사용 빈도 자동 정렬 | LOW | 많이 쓰는 프리셋이 자동으로 앞으로 |

---

## 4. 상세 설계

### 4.1 데이터 모델

```dart
@HiveType(typeId: XX)
class FeedbackPreset {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;        // 프리셋 문구

  @HiveField(2)
  final String? category;   // 카테고리 (optional)

  @HiveField(3)
  final int sortOrder;      // 정렬 순서

  @HiveField(4)
  final bool isDefault;     // 기본 프리셋 여부 (삭제 시 숨김 처리)

  @HiveField(5)
  final int usageCount;     // 사용 횟수 (자동 정렬용)
}
```

### 4.2 UI 플로우

#### 프리셋 칩 행 (기존 UI 확장)

```
[+ 추가] [음정 주의] [리듬 좋음] [활 주법 ×] [자세 교정] ... →
         ↑ 탭: 텍스트 삽입    ↑ 롱프레스: 편집/삭제 메뉴
```

- **탭**: 기존과 동일 (텍스트 필드에 삽입)
- **롱프레스**: 바텀시트 — `편집` / `삭제` / `취소`
- **[+ 추가] 칩**: 인라인 텍스트 입력 → 즉시 프리셋 등록

#### [+ 추가] 터치 시 플로우

```
1. [+ 추가] 칩 터치
2. 칩이 텍스트 입력 필드로 변환 (인라인)
3. 문구 입력 → Enter 또는 확인 버튼
4. 새 프리셋 등록 + 칩 행에 즉시 반영
5. 포커스 텍스트 필드로 복귀
```

#### 프리셋 관리 전체 화면 (설정에서 접근)

```
프로필 > 피드백 프리셋 관리

┌─────────────────────────────────┐
│ 나의 피드백 프리셋               │
│                                 │
│ ≡ 음정 주의           [편집] [×] │
│ ≡ 리듬 좋음           [편집] [×] │
│ ≡ 활 주법 연습         [편집] [×] │
│ ≡ (사용자 추가 항목)   [편집] [×] │
│                                 │
│ [+ 새 프리셋 추가]               │
│                                 │
│ ─── 숨긴 기본 프리셋 ───         │
│ ○ 자세 교정            [복원]    │
└─────────────────────────────────┘
```

- `≡` 아이콘: 드래그&드롭 순서 변경
- 기본 프리셋은 삭제 대신 "숨김" 처리 (복원 가능)
- 사용자 추가 프리셋은 완전 삭제

### 4.3 저장소

| 항목 | 구현 |
|------|------|
| 로컬 | Hive Box (`feedbackPresetsBox`) |
| 초기 데이터 | 앱 첫 실행 시 기본 9개 프리셋 생성 |
| 백엔드 (향후) | 사용자별 프리셋 동기화 |

---

## 5. 관련 파일

| 파일 | 변경 |
|------|------|
| `features/lessons/domain/entities/feedback_preset.dart` | 신규 — 엔티티 |
| `features/lessons/domain/constants/feedback_constants.dart` | 기본 프리셋 상수로 유지 (마이그레이션 소스) |
| `features/lessons/data/repositories/feedback_preset_repository.dart` | 신규 — Hive CRUD |
| `features/lessons/presentation/providers/feedback_preset_provider.dart` | 신규 — @riverpod |
| `features/lessons/presentation/widgets/lesson_detail/lesson_notes_widgets.dart` | 수정 — Provider 연동 |
| `features/lessons/presentation/screens/quick_feedback_screen.dart` | 수정 — Provider 연동 |
| `features/lessons/presentation/screens/feedback_preset_manage_screen.dart` | 신규 — 관리 화면 |

---

## 6. 예외 처리

| 상황 | 처리 |
|------|------|
| 빈 문구 입력 | 등록 불가 + 안내 |
| 중복 문구 | "이미 존재하는 프리셋입니다" 토스트 |
| 기본 프리셋 삭제 | 숨김 처리 (isDefault=true → hidden) |
| Hive 초기화 실패 | 하드코딩 상수 폴백 |

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-03-12 | 초안 작성 |
