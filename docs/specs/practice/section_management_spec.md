# 섹션 관리 시스템 스펙

> 작성일: 2026-01-03
> 상태: 설계 완료
> 브레인스토밍: [practice_repertoire_enhancement.md](../../proposal/practice_repertoire_enhancement.md)

## 1. 개요

### 1.1 목적
섹션 순서 관리 및 레퍼토리 아카이브 기능으로 연습 관리 효율성 향상

### 1.2 핵심 결정사항
| 항목 | 결정 |
|------|------|
| 섹션 순서 | 드래그앤드롭 + 정렬 옵션 |
| 기본 정렬 | 생성순 (최신이 위) |
| 정렬 옵션 | 이름순, 마디순, 최근 연습순 |
| 아카이브 | 수동 아카이브 + 최종 삭제 가능 |

---

## 2. 섹션 정렬 시스템

### 2.1 데이터 모델 확장

```dart
/// 섹션 정렬 방식
enum SectionSortType {
  /// 생성순 (기본) - 최신이 위
  createdDesc,
  /// 생성순 - 오래된 것이 위
  createdAsc,
  /// 이름순 (가나다순)
  nameAsc,
  /// 마디순 (시작 마디 기준)
  measureAsc,
  /// 최근 연습순
  lastPracticedDesc,
  /// 사용자 지정 순서
  custom,
}

/// PracticeSection에 순서 필드 추가
class PracticeSection {
  // ... 기존 필드들
  final int? sortOrder;        // 사용자 지정 순서 (드래그앤드롭용)
  final DateTime? lastPracticedAt;  // 마지막 연습 시간

  PracticeSection copyWith({
    // ... 기존 필드들
    int? sortOrder,
    DateTime? lastPracticedAt,
  });
}
```

### 2.2 정렬 로직

```dart
/// 섹션 정렬 유틸리티
extension SectionSorting on List<PracticeSection> {
  List<PracticeSection> sortBy(SectionSortType type) {
    final sorted = List<PracticeSection>.from(this);

    switch (type) {
      case SectionSortType.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SectionSortType.createdAsc:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SectionSortType.nameAsc:
        sorted.sort((a, b) => a.pieceName.compareTo(b.pieceName));
        break;
      case SectionSortType.measureAsc:
        sorted.sort((a, b) => a.startMeasure.compareTo(b.startMeasure));
        break;
      case SectionSortType.lastPracticedDesc:
        sorted.sort((a, b) {
          final aTime = a.lastPracticedAt ?? DateTime(1970);
          final bTime = b.lastPracticedAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
      case SectionSortType.custom:
        sorted.sort((a, b) {
          final aOrder = a.sortOrder ?? 999999;
          final bOrder = b.sortOrder ?? 999999;
          return aOrder.compareTo(bOrder);
        });
        break;
    }

    return sorted;
  }
}
```

### 2.3 UI - 정렬 옵션 드롭다운

```
┌─────────────────────────────────────────┐
│ 스즈키 6권                              │
│                                         │
│ 정렬: [최신순 ▼]                        │
│       ┌─────────────────┐               │
│       │ ✓ 최신순        │               │
│       │   오래된순      │               │
│       │   이름순        │               │
│       │   마디순        │               │
│       │   최근연습순    │               │
│       │   사용자지정    │               │
│       └─────────────────┘               │
├─────────────────────────────────────────┤
│ 섹션 목록                               │
│ ...                                     │
└─────────────────────────────────────────┘
```

### 2.4 UI - 드래그앤드롭 (사용자 지정 순서)

```
┌─────────────────────────────────────────┐
│ 정렬: [사용자지정 ▼]              [편집]│
├─────────────────────────────────────────┤
│ ☰ 1~8 마디 - 도입부                     │ ← 드래그 핸들
│ ☰ 9~16 마디 - 주제A                     │
│ ☰ 17~24 마디 - 주제B                    │
│ ☰ 25~32 마디 - 코다                     │
└─────────────────────────────────────────┘
```

**동작:**
- 정렬 타입이 `custom`일 때만 드래그 가능
- `[편집]` 버튼 터치 시 드래그 모드 활성화
- 드래그 완료 시 `sortOrder` 업데이트

---

## 3. 레퍼토리 아카이브 시스템

### 3.1 데이터 모델 확장

```dart
/// PracticeRepertoire에 아카이브 필드 추가
class PracticeRepertoire {
  // ... 기존 필드들
  final bool isArchived;       // 아카이브 여부
  final DateTime? archivedAt;  // 아카이브 시점

  /// 아카이브되지 않은 활성 레퍼토리인지
  bool get isActive => !isArchived;

  PracticeRepertoire copyWith({
    // ... 기존 필드들
    bool? isArchived,
    DateTime? archivedAt,
  });
}
```

### 3.2 Repository 인터페이스 확장

```dart
abstract class PracticeRepertoireRepository {
  // ... 기존 메서드들

  /// 활성 레퍼토리만 조회
  Future<List<PracticeRepertoire>> getActiveRepertoires(String studentId);

  /// 아카이브된 레퍼토리만 조회
  Future<List<PracticeRepertoire>> getArchivedRepertoires(String studentId);

  /// 레퍼토리 아카이브
  Future<PracticeRepertoire> archiveRepertoire(String id);

  /// 아카이브 복원
  Future<PracticeRepertoire> restoreRepertoire(String id);

  /// 아카이브된 레퍼토리 영구 삭제
  Future<void> permanentlyDeleteRepertoire(String id);
}
```

### 3.3 UI - 레퍼토리 목록 (활성)

```
┌─────────────────────────────────────────┐
│ 레퍼토리                        [+] [⋮]│
│                                 ┌─────┐ │
│                                 │아카 │ │
│                                 │이브 │ │
│                                 │보기 │ │
│                                 └─────┘ │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 스즈키 6권                     [⋮] │ │
│ │ 진행률: 75% ████████░░░            │ │
│ │ 섹션: 4개 | 연습: 3시간 20분       │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 바흐 파르티타                  [⋮] │ │
│ │ 진행률: 30% ███░░░░░░░░            │ │
│ │ ┌─────────────────────┐            │ │
│ │ │ 수정                │            │ │
│ │ │ 아카이브            │ ← 아카이브 │ │
│ │ │ 삭제                │            │ │
│ │ └─────────────────────┘            │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 3.4 UI - 아카이브 목록

```
┌─────────────────────────────────────────┐
│ ← 아카이브                              │
├─────────────────────────────────────────┤
│ 아카이브된 레퍼토리를 복원하거나        │
│ 영구 삭제할 수 있습니다.                │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 🗄️ 스즈키 5권                 [⋮] │ │
│ │ 아카이브: 2025-12-15               │ │
│ │ ┌─────────────────────┐            │ │
│ │ │ 복원                │ ← 복원     │ │
│ │ │ 영구 삭제 🗑️        │ ← 최종삭제 │ │
│ │ └─────────────────────┘            │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 아카이브된 레퍼토리가 없습니다.         │
│ (빈 상태 시)                            │
└─────────────────────────────────────────┘
```

### 3.5 삭제 확인 다이얼로그

**아카이브 시:**
```
┌─────────────────────────────────────────┐
│ 레퍼토리 아카이브                       │
├─────────────────────────────────────────┤
│ "스즈키 6권"을 아카이브할까요?          │
│                                         │
│ 아카이브된 레퍼토리는 목록에서 숨겨지며 │
│ 나중에 복원할 수 있습니다.              │
├─────────────────────────────────────────┤
│             [취소]     [아카이브]       │
└─────────────────────────────────────────┘
```

**영구 삭제 시:**
```
┌─────────────────────────────────────────┐
│ ⚠️ 레퍼토리 영구 삭제                   │
├─────────────────────────────────────────┤
│ "스즈키 5권"을 영구 삭제할까요?         │
│                                         │
│ ⚠️ 이 작업은 되돌릴 수 없습니다.       │
│ 모든 섹션, 녹음, 연습 기록이            │
│ 함께 삭제됩니다.                        │
├─────────────────────────────────────────┤
│             [취소]     [영구 삭제]      │
└─────────────────────────────────────────┘
```

---

## 4. Provider 설계

```dart
/// 현재 정렬 타입 상태
final sectionSortTypeProvider = StateProvider<SectionSortType>(
  (ref) => SectionSortType.createdDesc,
);

/// 정렬된 섹션 목록
final sortedSectionsProvider = Provider.family<List<PracticeSection>, String>(
  (ref, repertoireId) {
    final repertoire = ref.watch(repertoireProvider(repertoireId)).valueOrNull;
    final sortType = ref.watch(sectionSortTypeProvider);

    if (repertoire == null) return [];
    return repertoire.sections.sortBy(sortType);
  },
);

/// 활성 레퍼토리 목록 (아카이브 제외)
final activeRepertoiresProvider =
    FutureProvider.family<List<PracticeRepertoire>, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceRepertoireRepositoryProvider);
    return repository.getActiveRepertoires(studentId);
  },
);

/// 아카이브된 레퍼토리 목록
final archivedRepertoiresProvider =
    FutureProvider.family<List<PracticeRepertoire>, String>(
  (ref, studentId) async {
    final repository = ref.watch(practiceRepertoireRepositoryProvider);
    return repository.getArchivedRepertoires(studentId);
  },
);

/// 섹션 순서 업데이트 Notifier
class SectionOrderNotifier extends AsyncNotifier<void> {
  /// 드래그앤드롭으로 순서 변경
  Future<void> reorderSections(
    String repertoireId,
    int oldIndex,
    int newIndex,
  ) async {
    // ... 구현
  }

  /// 정렬 타입 변경 시 sortOrder 초기화
  Future<void> applySortOrder(
    String repertoireId,
    SectionSortType type,
  ) async {
    // ... 구현
  }
}

/// 아카이브 Notifier
class RepertoireArchiveNotifier extends AsyncNotifier<void> {
  Future<void> archive(String id, String studentId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceRepertoireRepositoryProvider);
      await repository.archiveRepertoire(id);

      ref.invalidate(activeRepertoiresProvider(studentId));
      ref.invalidate(archivedRepertoiresProvider(studentId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> restore(String id, String studentId) async {
    // ... 구현
  }

  Future<void> permanentlyDelete(String id, String studentId) async {
    // ... 구현
  }
}
```

---

## 5. 라우팅

```dart
// 아카이브 화면 라우트 추가
GoRoute(
  path: 'practice/archive',
  name: 'practiceArchive',
  builder: (context, state) {
    final studentId = state.uri.queryParameters['studentId']!;
    return RepertoireArchiveScreen(studentId: studentId);
  },
),
```

---

## 6. 파일 구조

```
lib/features/practice/
├── domain/
│   └── entities/
│       └── section_sort_type.dart      # 정렬 타입 enum
├── presentation/
│   ├── providers/
│   │   ├── section_sort_provider.dart
│   │   └── repertoire_archive_provider.dart
│   ├── screens/
│   │   └── repertoire_archive_screen.dart
│   └── widgets/
│       ├── section_sort_dropdown.dart  # 정렬 드롭다운
│       ├── reorderable_section_list.dart  # 드래그 리스트
│       └── archive_repertoire_tile.dart   # 아카이브 아이템
```

---

## 7. 구현 체크리스트

### Phase 1: 정렬 옵션
- [ ] SectionSortType enum 추가
- [ ] PracticeSection에 sortOrder, lastPracticedAt 필드 추가
- [ ] 정렬 로직 구현
- [ ] 정렬 드롭다운 UI 구현
- [ ] Provider 구현

### Phase 5: 드래그앤드롭
- [ ] ReorderableListView 구현
- [ ] 순서 변경 시 sortOrder 업데이트 로직
- [ ] 편집 모드 UI

### Phase 1: 아카이브
- [ ] PracticeRepertoire에 isArchived, archivedAt 필드 추가
- [ ] Repository 메서드 추가
- [ ] 아카이브 화면 구현
- [ ] 복원/영구삭제 기능
- [ ] Provider 구현

---

## 8. 마이그레이션

기존 데이터에 새 필드 추가 시 기본값:
```dart
// PracticeSection
sortOrder: null  // null이면 정렬 로직에서 맨 뒤로
lastPracticedAt: null  // 연습 기록 없음

// PracticeRepertoire
isArchived: false  // 기본적으로 활성
archivedAt: null
```
