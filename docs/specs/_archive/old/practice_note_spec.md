# 연습노트 시스템 스펙

> 작성일: 2026-01-03
> 상태: 설계 완료
> 엔티티 스키마: [practice_note.md](../../schema/entities/practice_note.md)
> 브레인스토밍: [practice_repertoire_enhancement.md](../../proposal/practice_repertoire_enhancement.md)

## 1. 개요

### 1.1 목적
학생이 연습 중 느낀 점, 주의할 사항 등을 섹션별로 기록할 수 있는 연습노트 기능

### 1.2 핵심 결정사항
| 항목 | 결정 |
|------|------|
| 공개 범위 | 학생 전용 (선생님 비공개) |
| 작성 빈도 | 하루에 여러 개 가능 (시간별 구분) |
| 권한 | 작성자만 수정/삭제 가능 |
| 첨부 | 텍스트만 (Phase 1) |

---

## 2. 데이터 모델

> 📦 **엔티티 정의**: [practice_note.md](../../schema/entities/practice_note.md)

### PracticeNote 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| id | String | 고유 식별자 |
| sectionId | String | 연결된 섹션 ID |
| content | String | 노트 내용 (텍스트) |
| createdAt | DateTime | 작성 시간 |
| updatedAt | DateTime? | 수정 시간 |

### PracticeSection 확장

기존 PracticeSection에 `notes` 필드를 추가하여 연습노트 목록을 연결합니다.

---

## 3. UI 설계

### 3.1 섹션 상세 화면 (SectionDetailScreen)
```
┌─────────────────────────────────────────┐
│ ← 바흐 파르티타 1~8 마디                 │
├─────────────────────────────────────────┤
│ 📝 최근 연습노트                    [>] │
│ ┌─────────────────────────────────────┐ │
│ │ 10:30 왼손 4번 손가락 음정 주의...  │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ 연습 통계                               │
│ ...                                     │
├─────────────────────────────────────────┤
│ 녹음 목록                               │
│ ...                                     │
└─────────────────────────────────────────┘
```

**동작:**
- 노트 미리보기 영역 터치 → 연습노트 리스트 화면으로 이동
- 노트가 없으면: "연습노트가 없습니다. 터치하여 추가하세요."

### 3.2 연습노트 리스트 화면 (PracticeNoteListScreen)
```
┌─────────────────────────────────────────┐
│ ← 연습노트                          [+] │
│   바흐 파르티타 1~8 마디                │
├─────────────────────────────────────────┤
│ 📅 2026-01-03 (오늘)                    │
│ ┌─────────────────────────────────────┐ │
│ │ 15:45                          [⋮] │ │
│ │ 오후 연습 - 템포 80까지 올림       │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 10:30                          [⋮] │ │
│ │ 오전 연습 - 느린 템포로 운지법 확인 │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│ 📅 2026-01-02 (어제)                    │
│ ┌─────────────────────────────────────┐ │
│ │ 20:00                          [⋮] │ │
│ │ 저녁 연습 완료                     │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**동작:**
- `[+]` 버튼 → 새 노트 추가 다이얼로그
- `[⋮]` 메뉴 → 수정 / 삭제
- 노트 카드 터치 → 수정 모드

### 3.3 노트 추가/수정 다이얼로그
```
┌─────────────────────────────────────────┐
│ 연습노트 추가                       [X] │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 연습하면서 느낀 점을 기록하세요... │ │
│ │                                     │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│             [취소]     [저장]           │
└─────────────────────────────────────────┘
```

---

## 4. Repository 인터페이스

```dart
abstract class PracticeNoteRepository {
  /// 섹션의 모든 노트 조회
  Future<List<PracticeNote>> getNotes(String sectionId);

  /// 노트 생성
  Future<PracticeNote> createNote({
    required String sectionId,
    required String content,
  });

  /// 노트 수정
  Future<PracticeNote> updateNote(PracticeNote note);

  /// 노트 삭제
  Future<void> deleteNote(String noteId);
}
```

---

## 5. Provider 설계

```dart
/// 섹션의 노트 목록 조회
final sectionNotesProvider = FutureProvider.family<List<PracticeNote>, String>(
  (ref, sectionId) async {
    final repository = ref.watch(practiceNoteRepositoryProvider);
    return repository.getNotes(sectionId);
  },
);

/// 노트 CRUD Notifier
class PracticeNoteCrudNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PracticeNote> createNote({
    required String sectionId,
    required String content,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(practiceNoteRepositoryProvider);
      final note = await repository.createNote(
        sectionId: sectionId,
        content: content,
      );

      // 관련 provider 무효화
      ref.invalidate(sectionNotesProvider(sectionId));
      ref.invalidate(sectionProvider(sectionId));

      state = const AsyncData(null);
      return note;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<PracticeNote> updateNote(PracticeNote note) async {
    // ... 구현
  }

  Future<void> deleteNote(String noteId, String sectionId) async {
    // ... 구현
  }
}

final practiceNoteCrudProvider =
    AsyncNotifierProvider<PracticeNoteCrudNotifier, void>(
  PracticeNoteCrudNotifier.new,
);
```

---

## 6. 라우팅

```dart
// Go Router 설정
GoRoute(
  path: 'section/:sectionId/notes',
  name: 'practiceNotes',
  builder: (context, state) {
    final sectionId = state.pathParameters['sectionId']!;
    final sectionName = state.uri.queryParameters['name'] ?? '';
    return PracticeNoteListScreen(
      sectionId: sectionId,
      sectionName: sectionName,
    );
  },
),
```

---

## 7. 파일 구조

```
lib/features/practice/
├── domain/
│   └── entities/
│       └── practice_note.dart          # PracticeNote 모델
├── data/
│   └── repositories/
│       └── practice_note_repository.dart
├── presentation/
│   ├── providers/
│   │   └── practice_note_provider.dart
│   ├── screens/
│   │   └── practice_note_list_screen.dart
│   └── widgets/
│       ├── note_preview_card.dart      # 섹션 상세용 미리보기
│       ├── note_list_item.dart         # 리스트 아이템
│       └── note_edit_dialog.dart       # 추가/수정 다이얼로그
```

---

## 8. 구현 체크리스트

- [ ] PracticeNote 모델 생성 (Hive 어댑터 포함)
- [ ] PracticeSection에 notes 필드 추가
- [ ] PracticeNoteRepository 인터페이스 및 Mock 구현
- [ ] Provider 구현
- [ ] SectionDetailScreen에 노트 미리보기 위젯 추가
- [ ] PracticeNoteListScreen 구현
- [ ] 노트 추가/수정 다이얼로그 구현
- [ ] 라우터 설정
- [ ] 테스트

---

## 9. 향후 확장 가능성

| 기능 | Phase | 설명 |
|------|:-----:|------|
| 이미지 첨부 | 2 | 악보 사진, 손 모양 등 |
| 음성 메모 | 2 | 녹음 대신 간단한 음성 메모 |
| 선생님 공유 | 2 | 특정 노트만 선생님에게 공유 |
| 태그/검색 | 2 | 노트 태그 및 검색 기능 |
