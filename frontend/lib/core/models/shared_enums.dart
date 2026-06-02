import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ============================================================================
// Shared Enums - Used across multiple domains
// ============================================================================

/// Age groups for UI differentiation
/// Used by: Student, PracticeItem
enum AgeGroup {
  child, // 어린이 (12세 이하)
  student, // 학생 (13-18세)
  adult; // 성인 (19세 이상)

  String get label {
    switch (this) {
      case AgeGroup.child:
        return '어린이';
      case AgeGroup.student:
        return '학생';
      case AgeGroup.adult:
        return '성인';
    }
  }

  String get description {
    switch (this) {
      case AgeGroup.child:
        return '초등학생 이하';
      case AgeGroup.student:
        return '중고등학생';
      case AgeGroup.adult:
        return '대학생 이상';
    }
  }

  /// Calculate age group from birth date
  static AgeGroup fromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    if (age <= 12) return AgeGroup.child;
    if (age <= 18) return AgeGroup.student;
    return AgeGroup.adult;
  }

  /// Age threshold
  int get maxAge {
    switch (this) {
      case AgeGroup.child:
        return 12;
      case AgeGroup.student:
        return 18;
      case AgeGroup.adult:
        return 999;
    }
  }
}

/// Connection status for mutual follow system
/// Used by: Student, Invite
///
/// **DEPRECATED — RelationshipStatus is the SSOT (G3 Phase B).**
///
/// spec: docs/specs/review/2026-06-01-teacher-e2e/30-gap-catalog.md
/// #5 D-G3 `이중 상태 충돌`. New surface logic must read from
/// `features/relationship/.../RelationshipStatus` (FE) and
/// `app.models.relationship.RelationStatus` (BE).
///
/// This enum is retained while `Student.connectionStatus` (FE entity field
/// and BE column) is still in use; data migration + column drop will land
/// in Phase B-2.
@Deprecated('Use RelationshipStatus — G3 Phase B (gap-catalog #5)')
enum ConnectionStatus {
  offline, // Manual registration only (no app)
  inviteSent, // I followed, waiting for follow back
  inviteReceived, // They followed me, I haven't followed back
  connected, // Mutual follow established
  disconnected; // Was connected, but one side unfollowed

  String get label {
    switch (this) {
      case ConnectionStatus.offline:
        return '오프라인';
      case ConnectionStatus.inviteSent:
        return '초대 보냄';
      case ConnectionStatus.inviteReceived:
        return '초대 받음';
      case ConnectionStatus.connected:
        return '연결됨';
      case ConnectionStatus.disconnected:
        return '연결 끊김';
    }
  }

  Color get color {
    switch (this) {
      case ConnectionStatus.offline:
        return AppColors.inkTertiary;
      case ConnectionStatus.inviteSent:
        return AppColors.paperAccent;
      case ConnectionStatus.inviteReceived:
        return AppColors.ink;
      case ConnectionStatus.connected:
        return AppColors.paperOk;
      case ConnectionStatus.disconnected:
        return AppColors.inkTertiary;
    }
  }

  /// Whether this status represents an app-connected user
  bool get isAppConnected => this == ConnectionStatus.connected;

  /// Whether action button should show "Re-connect" instead of "Invite"
  bool get showReconnectButton => this == ConnectionStatus.disconnected;
}

/// Practice level for integrated indicator
/// Used by: Student, Invite
enum PracticeLevel {
  newStudent, // Just connected (no practice data yet)
  excellent, // 5+ days in last 7 days
  average, // 3-4 days in last 7 days
  poor, // 1-2 days in last 7 days
  onBreak; // On break status

  String get label {
    switch (this) {
      case PracticeLevel.newStudent:
        return '신규';
      case PracticeLevel.excellent:
        return '우수';
      case PracticeLevel.average:
        return '보통';
      case PracticeLevel.poor:
        return '부족';
      case PracticeLevel.onBreak:
        return '휴강';
    }
  }

  Color get color {
    switch (this) {
      case PracticeLevel.newStudent:
        return AppColors.paperAccent;
      case PracticeLevel.excellent:
        return AppColors.paperOk;
      case PracticeLevel.average:
        return AppColors.paperAccent;
      case PracticeLevel.poor:
        return AppColors.paperAccent;
      case PracticeLevel.onBreak:
        return AppColors.inkTertiary;
    }
  }

  /// Minimum practice days required for this level
  int get minDays {
    switch (this) {
      case PracticeLevel.excellent:
        return 5;
      case PracticeLevel.average:
        return 3;
      case PracticeLevel.poor:
        return 1;
      case PracticeLevel.newStudent:
      case PracticeLevel.onBreak:
        return 0;
    }
  }
}

/// Helper class to calculate connection status from follow relationships
class ConnectionStatusHelper {
  /// Calculate ConnectionStatus from follow relationships
  static ConnectionStatus calculateStatus({
    required bool iFollowThem,
    required bool theyFollowMe,
    required bool hasAppAccount,
  }) {
    if (!hasAppAccount) return ConnectionStatus.offline;
    if (iFollowThem && theyFollowMe) return ConnectionStatus.connected;
    if (iFollowThem && !theyFollowMe) return ConnectionStatus.inviteSent;
    if (!iFollowThem && theyFollowMe) return ConnectionStatus.inviteReceived;
    return ConnectionStatus.disconnected;
  }

  /// Calculate PracticeLevel from practice days in last 7 days
  static PracticeLevel calculatePracticeLevel({
    required int practiceDaysInLast7Days,
    required bool isOnBreak,
    required bool isNewStudent,
  }) {
    if (isOnBreak) return PracticeLevel.onBreak;
    if (isNewStudent) return PracticeLevel.newStudent;
    if (practiceDaysInLast7Days >= 5) return PracticeLevel.excellent;
    if (practiceDaysInLast7Days >= 3) return PracticeLevel.average;
    return PracticeLevel.poor;
  }
}
