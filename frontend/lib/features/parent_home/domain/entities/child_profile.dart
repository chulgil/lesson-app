// Child profile domain entity
// Moved from lib/features/parent_home/domain/entities/child_profile.dart for Clean Architecture

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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

/// Child connection status with teacher
///
/// Determines what features are available for the child:
/// - connected: Full features with teacher
/// - pending: Waiting for teacher connection
/// - unconnected: Practice/metronome only (no lessons, no repertoire)
///
/// ChildProfile.connectionStatus 필드 + isConnected/isPending/isUnconnected getter에 배선.
/// 선생님 초대 → 연결 플로우 UI 구현 시 외부 세팅 활성화.
// ignore: unused-enum
enum ChildConnectionStatus {
  connected,
  pending,
  unconnected;

  String get label {
    switch (this) {
      case ChildConnectionStatus.connected:
        return '연결됨';
      case ChildConnectionStatus.pending:
        return '대기 중';
      case ChildConnectionStatus.unconnected:
        return '미연결';
    }
  }

  Color get color {
    switch (this) {
      case ChildConnectionStatus.connected:
        return AppColors.success;
      case ChildConnectionStatus.pending:
        return AppColors.warning;
      case ChildConnectionStatus.unconnected:
        return AppColors.textTertiaryLight;
    }
  }

  IconData get icon {
    switch (this) {
      case ChildConnectionStatus.connected:
        return Icons.link;
      case ChildConnectionStatus.pending:
        return Icons.hourglass_empty;
      case ChildConnectionStatus.unconnected:
        return Icons.link_off;
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
  final String?
  linkedStudentId; // Maps to Student.id for subscription/lesson queries
  final Color profileColor;
  final ChildProfileStatus status;
  final ChildConnectionStatus connectionStatus;
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
    this.linkedStudentId,
    required this.profileColor,
    this.status = ChildProfileStatus.active,
    this.connectionStatus = ChildConnectionStatus.unconnected,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get first character of name for avatar
  String get initial => name.isNotEmpty ? name[0] : '?';

  /// Check if child is active
  bool get isActive => status == ChildProfileStatus.active;

  /// Check if child is connected to a teacher
  bool get isConnected => connectionStatus == ChildConnectionStatus.connected;

  /// Check if connection is pending
  bool get isPending => connectionStatus == ChildConnectionStatus.pending;

  /// Check if child is unconnected (practice/metronome only)
  bool get isUnconnected =>
      connectionStatus == ChildConnectionStatus.unconnected;

  /// Check if child has a teacher assigned
  bool get hasTeacher => teacherId != null;

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
    String? linkedStudentId,
    Color? profileColor,
    ChildProfileStatus? status,
    ChildConnectionStatus? connectionStatus,
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
      linkedStudentId: linkedStudentId ?? this.linkedStudentId,
      profileColor: profileColor ?? this.profileColor,
      status: status ?? this.status,
      connectionStatus: connectionStatus ?? this.connectionStatus,
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
