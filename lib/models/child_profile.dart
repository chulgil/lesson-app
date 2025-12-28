import 'package:flutter/material.dart';

/// Child profile status enum
enum ChildProfileStatus {
  active,
  inactive;

  String get label {
    switch (this) {
      case ChildProfileStatus.active:
        return '활성';
      case ChildProfileStatus.inactive:
        return '비활성';
    }
  }
}

/// Child profile model for under-14 students (no account registration)
///
/// This is NOT a user account - it's a profile under parent's account.
/// Used for children under 14 years old who cannot register their own account
/// due to personal information protection laws (requires parental consent).
class ChildProfile {
  final String id;
  final String parentId; // Parent account FK
  final String name; // Name or nickname
  final int birthYear; // Year only (for age verification)
  final String instrument; // e.g., 'violin', 'piano'
  final String level; // e.g., 'beginner', 'intermediate'
  final String? teacherId; // Connected teacher
  final String? teacherName; // For display
  final Color profileColor;
  final ChildProfileStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChildProfile({
    required this.id,
    required this.parentId,
    required this.name,
    required this.birthYear,
    required this.instrument,
    required this.level,
    this.teacherId,
    this.teacherName,
    required this.profileColor,
    this.status = ChildProfileStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get first character of name for avatar
  String get initial => name.isNotEmpty ? name[0] : '?';

  /// Check if child is active
  bool get isActive => status == ChildProfileStatus.active;

  /// Calculate current age from birth year
  int get age => DateTime.now().year - birthYear;

  /// Check if child is under 14 (requires child profile)
  bool get isUnder14 => age < 14;

  /// Check if child can convert to own account (14 or older)
  bool get canConvertToAccount => age >= 14;

  /// Get instrument display name
  String get instrumentLabel {
    switch (instrument.toLowerCase()) {
      case 'violin':
        return '바이올린';
      case 'piano':
        return '피아노';
      case 'cello':
        return '첼로';
      case 'viola':
        return '비올라';
      case 'flute':
        return '플루트';
      default:
        return instrument;
    }
  }

  /// Get level display name
  String get levelLabel {
    switch (level.toLowerCase()) {
      case 'beginner':
        return '입문';
      case 'elementary':
        return '초급';
      case 'intermediate':
        return '중급';
      case 'advanced':
        return '고급';
      default:
        return level;
    }
  }

  /// Get instrument icon
  IconData get instrumentIcon {
    switch (instrument.toLowerCase()) {
      case 'violin':
        return Icons.music_note;
      case 'piano':
        return Icons.piano;
      case 'cello':
        return Icons.music_note;
      case 'viola':
        return Icons.music_note;
      case 'flute':
        return Icons.music_note;
      default:
        return Icons.music_note;
    }
  }

  /// Copy with new values
  ChildProfile copyWith({
    String? id,
    String? parentId,
    String? name,
    int? birthYear,
    String? instrument,
    String? level,
    String? teacherId,
    String? teacherName,
    Color? profileColor,
    ChildProfileStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      birthYear: birthYear ?? this.birthYear,
      instrument: instrument ?? this.instrument,
      level: level ?? this.level,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      profileColor: profileColor ?? this.profileColor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
