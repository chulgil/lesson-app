# PracticeNote 엔티티

> 작성일: 2026-01-24
> 관련 스펙: [practice_note_spec.md](../../specs/practice/practice_note_spec.md)

---

## Hive TypeId 할당

| TypeId | 엔티티 |
|:------:|--------|
| 31 | PracticeNote |

---

## PracticeNote (연습노트)

학생이 연습 중 기록하는 노트 엔티티.

### Dart 엔티티

```dart
/// 연습노트 모델
@HiveType(typeId: 31)
class PracticeNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sectionId;  // 연결된 섹션 ID

  @HiveField(2)
  final String content;    // 노트 내용 (텍스트)

  @HiveField(3)
  final DateTime createdAt;  // 작성 시간 (시간별 구분용)

  @HiveField(4)
  final DateTime? updatedAt;  // 수정 시간

  PracticeNote({
    required this.id,
    required this.sectionId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  /// 작성 시간 포맷 (예: "10:30")
  String get timeText {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// 날짜 포맷 (예: "2026-01-03")
  String get dateText {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// 수정 여부
  bool get isEdited => updatedAt != null;

  PracticeNote copyWith({
    String? id,
    String? sectionId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeNote(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 필드 설명

| 필드 | 타입 | 설명 | 필수 |
|------|------|------|:----:|
| id | String | 고유 식별자 | ⭕ |
| sectionId | String | 연결된 섹션 ID | ⭕ |
| content | String | 노트 내용 (텍스트) | ⭕ |
| createdAt | DateTime | 작성 시간 | ⭕ |
| updatedAt | DateTime? | 수정 시간 | ❌ |

---

## PracticeSection 확장

기존 PracticeSection에 notes 필드를 추가하여 연습노트를 연결합니다.

```dart
// 기존 PracticeSection에 notes 필드 추가
class PracticeSection {
  // ... 기존 필드들
  final List<PracticeNote> notes;  // 연습노트 목록

  /// 최근 노트 가져오기
  PracticeNote? get latestNote {
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  /// 날짜별 노트 그룹화
  Map<String, List<PracticeNote>> get notesByDate {
    final grouped = <String, List<PracticeNote>>{};
    for (final note in notes) {
      final dateKey = note.dateText;
      grouped.putIfAbsent(dateKey, () => []).add(note);
    }
    // 각 그룹 내에서 시간순 정렬
    for (final list in grouped.values) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return grouped;
  }
}
```

---

## 파일 위치

```
lib/features/practice/domain/entities/practice_note.dart
```

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [practice_note_spec.md](../../specs/practice/practice_note_spec.md) | 연습노트 시스템 스펙 |
| [practice_space.md](./practice_space.md) | PracticeSection 관련 |
