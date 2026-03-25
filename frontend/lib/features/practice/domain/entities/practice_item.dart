// Practice item domain entities
// Moved from lib/features/practice/domain/entities/practice_item.dart for Clean Architecture

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

import 'package:json_annotation/json_annotation.dart';

// Re-export shared enum for backward compatibility
export '../../../../core/models/shared_enums.dart' show AgeGroup;

part 'practice_item.g.dart';

/// Quick Reaction from teacher (1-tap feedback)
enum QuickReaction {
  good, // 👍 잘했어요
  excellent, // ⭐ 훌륭해요
  tryHarder; // 💪 힘내자

  String get emoji {
    switch (this) {
      case QuickReaction.good:
        return '👍';
      case QuickReaction.excellent:
        return '⭐';
      case QuickReaction.tryHarder:
        return '💪';
    }
  }

  String get label {
    switch (this) {
      case QuickReaction.good:
        return '잘했어요';
      case QuickReaction.excellent:
        return '훌륭해요';
      case QuickReaction.tryHarder:
        return '힘내자';
    }
  }
}

/// Student response to teacher's feedback
enum StudentResponse {
  thanks, // 🙏 감사합니다
  question; // ❓ 질문있어요

  String get emoji {
    switch (this) {
      case StudentResponse.thanks:
        return '🙏';
      case StudentResponse.question:
        return '❓';
    }
  }

  String get label {
    switch (this) {
      case StudentResponse.thanks:
        return '감사합니다';
      case StudentResponse.question:
        return '질문있어요';
    }
  }
}

/// Practice priority levels for "이번 주 연습"
enum PracticePriority {
  must, // 🔴 필수 - 꼭 해오기
  should, // 🟡 추천 - 해오면 좋아요
  could; // 🟢 도전 - 도전해볼까?

  /// Display label for teacher UI
  String get label {
    switch (this) {
      case PracticePriority.must:
        return '필수';
      case PracticePriority.should:
        return '추천';
      case PracticePriority.could:
        return '도전';
    }
  }

  /// Friendly label for child UI
  String get childLabel {
    switch (this) {
      case PracticePriority.must:
        return '꼭 해와요!';
      case PracticePriority.should:
        return '해보면 좋아요~';
      case PracticePriority.could:
        return '도전해볼까?';
    }
  }

  /// Short label for adult UI
  String get shortLabel {
    switch (this) {
      case PracticePriority.must:
        return '필수';
      case PracticePriority.should:
        return '권장';
      case PracticePriority.could:
        return '선택';
    }
  }

  /// Priority color
  Color get color {
    switch (this) {
      case PracticePriority.must:
        return AppColors.error; // 🔴
      case PracticePriority.should:
        return AppColors.practiceNormal; // 🟡
      case PracticePriority.could:
        return AppColors.practiceGood; // 🟢
    }
  }

  /// Priority emoji (for child UI)
  String get emoji {
    switch (this) {
      case PracticePriority.must:
        return '⭐⭐⭐';
      case PracticePriority.should:
        return '⭐⭐';
      case PracticePriority.could:
        return '⭐';
    }
  }

  /// Priority dot (for student/adult UI)
  String get dot {
    switch (this) {
      case PracticePriority.must:
        return '🔴';
      case PracticePriority.should:
        return '🟡';
      case PracticePriority.could:
        return '🟢';
    }
  }

  /// Sort order (must first, could last)
  int get sortOrder {
    switch (this) {
      case PracticePriority.must:
        return 0;
      case PracticePriority.should:
        return 1;
      case PracticePriority.could:
        return 2;
    }
  }
}

/// Practice item source types
enum PracticeType {
  repertoire, // 레퍼토리에서 선택
  technique, // 테크닉/스케일
  theory, // 이론
  custom; // 직접 입력

  String get label {
    switch (this) {
      case PracticeType.repertoire:
        return '레퍼토리';
      case PracticeType.technique:
        return '테크닉';
      case PracticeType.theory:
        return '이론';
      case PracticeType.custom:
        return '직접입력';
    }
  }

  IconData get icon {
    switch (this) {
      case PracticeType.repertoire:
        return Icons.music_note;
      case PracticeType.technique:
        return Icons.piano;
      case PracticeType.theory:
        return Icons.menu_book;
      case PracticeType.custom:
        return Icons.edit_note;
    }
  }
}

/// Practice item model - 선생님이 레슨에서 할당하는 "이번 주 연습" 항목
@JsonSerializable()
class PracticeItem {
  final String id;
  final String lessonId; // 연결된 레슨 ID
  final String studentId; // 학생 ID
  final String teacherId; // 선생님 ID

  // Content
  final PracticeType type;
  final String title; // "Canon in D - A섹션"
  final String? description; // "메트로놈 60으로 정확하게"
  final String? repertoireId; // 레퍼토리 연결 (선택)
  final String? sectionId; // 섹션 연결 (선택)

  // Priority
  final PracticePriority priority;

  // Teaching resources attached to this practice item
  final List<String> resourceIds;

  // Completion status
  final bool isCompleted;
  final int practiceCount; // 연습 횟수 (기본: 0, 완료 시 최소: 1)
  final DateTime? completedAt;

  // Teacher feedback
  final bool hasLike; // 좋아요 여부 (deprecated: use teacherReaction)
  final DateTime? likedAt;

  // Quick Reaction feedback
  final QuickReaction? teacherReaction;
  final DateTime? teacherReactionAt;
  final StudentResponse? studentResponse;
  final DateTime? studentResponseAt;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PracticeItem({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.teacherId,
    required this.type,
    required this.title,
    this.description,
    this.repertoireId,
    this.sectionId,
    this.resourceIds = const [],
    this.priority = PracticePriority.should,
    this.isCompleted = false,
    this.practiceCount = 0,
    this.completedAt,
    this.hasLike = false,
    this.likedAt,
    this.teacherReaction,
    this.teacherReactionAt,
    this.studentResponse,
    this.studentResponseAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory PracticeItem.fromJson(Map<String, dynamic> json) =>
      _$PracticeItemFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeItemToJson(this);

  /// Check if this is from repertoire
  bool get isFromRepertoire =>
      type == PracticeType.repertoire && repertoireId != null;

  /// Get formatted completion info
  String get completionInfo {
    if (!isCompleted) return '미완료';
    if (practiceCount == 1) return '완료';
    return '$practiceCount회 완료';
  }

  /// Get formatted date string for completion
  String? get completionDateText {
    if (completedAt == null) return null;
    return '${completedAt!.month}월 ${completedAt!.day}일 완료';
  }

  /// Copy with new values
  PracticeItem copyWith({
    String? id,
    String? lessonId,
    String? studentId,
    String? teacherId,
    PracticeType? type,
    String? title,
    String? description,
    String? repertoireId,
    String? sectionId,
    List<String>? resourceIds,
    PracticePriority? priority,
    bool? isCompleted,
    int? practiceCount,
    DateTime? completedAt,
    bool? hasLike,
    DateTime? likedAt,
    QuickReaction? teacherReaction,
    DateTime? teacherReactionAt,
    StudentResponse? studentResponse,
    DateTime? studentResponseAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PracticeItem(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      studentId: studentId ?? this.studentId,
      teacherId: teacherId ?? this.teacherId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      repertoireId: repertoireId ?? this.repertoireId,
      sectionId: sectionId ?? this.sectionId,
      resourceIds: resourceIds ?? this.resourceIds,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      practiceCount: practiceCount ?? this.practiceCount,
      completedAt: completedAt ?? this.completedAt,
      hasLike: hasLike ?? this.hasLike,
      likedAt: likedAt ?? this.likedAt,
      teacherReaction: teacherReaction ?? this.teacherReaction,
      teacherReactionAt: teacherReactionAt ?? this.teacherReactionAt,
      studentResponse: studentResponse ?? this.studentResponse,
      studentResponseAt: studentResponseAt ?? this.studentResponseAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Complete this practice item
  PracticeItem complete() {
    return copyWith(
      isCompleted: true,
      practiceCount: practiceCount == 0 ? 1 : practiceCount,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Uncomplete this practice item
  PracticeItem uncomplete() {
    return copyWith(
      isCompleted: false,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Whether teacher has reacted (Quick Reaction or legacy hasLike)
  bool get hasReaction => teacherReaction != null || hasLike;

  /// Toggle like status (legacy — prefer setReaction)
  PracticeItem toggleLike() {
    return copyWith(
      hasLike: !hasLike,
      likedAt: !hasLike ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  /// Set teacher Quick Reaction (replaces toggleLike)
  PracticeItem setReaction(QuickReaction? reaction) {
    return copyWith(
      teacherReaction: reaction,
      teacherReactionAt: reaction != null ? DateTime.now() : null,
      hasLike: reaction != null,
      likedAt: reaction != null ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  /// Set student response to teacher's feedback
  PracticeItem setStudentResponse(StudentResponse? response) {
    return copyWith(
      studentResponse: response,
      studentResponseAt: response != null ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  /// Increment practice count
  PracticeItem incrementCount() {
    return copyWith(
      practiceCount: practiceCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  /// Decrement practice count (minimum 0)
  PracticeItem decrementCount() {
    return copyWith(
      practiceCount: practiceCount > 0 ? practiceCount - 1 : 0,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PracticeItem(id: $id, title: $title, priority: $priority)';
}

/// Extension to group practice items by priority
extension PracticeItemListExtension on List<PracticeItem> {
  /// Group items by priority (sorted: must -> should -> could)
  Map<PracticePriority, List<PracticeItem>> groupByPriority() {
    final grouped = <PracticePriority, List<PracticeItem>>{};
    for (final priority in PracticePriority.values) {
      grouped[priority] = where((item) => item.priority == priority).toList();
    }
    return grouped;
  }

  /// Get only incomplete items
  List<PracticeItem> get incomplete => where((item) => !item.isCompleted).toList();

  /// Get only completed items
  List<PracticeItem> get completed => where((item) => item.isCompleted).toList();

  /// Get completion rate (0.0 to 1.0)
  double get completionRate {
    if (isEmpty) return 0.0;
    return completed.length / length;
  }

  /// Get completion percentage string
  String get completionPercentage => '${(completionRate * 100).round()}%';

  /// Get completion summary (e.g., "2/5 완료")
  String get completionSummary => '${completed.length}/$length 완료';

  /// Sort by priority (must first)
  List<PracticeItem> sortedByPriority() {
    return [...this]..sort((a, b) => a.priority.sortOrder.compareTo(b.priority.sortOrder));
  }
}
