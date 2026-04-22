// User profile domain entity
// Moved from lib/features/parent_home/domain/entities/user_profile.dart for Clean Architecture

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'child_profile.dart';

/// Profile type for dual-role support
///
/// Users can switch between different profiles:
/// - parent: Managing children's lessons
/// - student: Own practice and lessons (if user is also a student)
/// - child: Acting as a specific child (for practice on child's behalf)
enum ProfileType {
  parent,
  student,
  child;

  String get label {
    switch (this) {
      case ProfileType.parent:
        return '학부모';
      case ProfileType.student:
        return '학생';
      case ProfileType.child:
        return '자녀';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileType.parent:
        return Icons.family_restroom;
      case ProfileType.student:
        return Icons.school;
      case ProfileType.child:
        return Icons.child_care;
    }
  }

  Color get color {
    switch (this) {
      case ProfileType.parent:
        return AppColors.primary;
      case ProfileType.student:
        return AppColors.paperOk;
      case ProfileType.child:
        return AppColors.secondary;
    }
  }
}

/// User profile model for managing active profile context
///
/// Supports dual-role users (e.g., parent who is also a student)
/// and profile switching between parent, student, and child modes.
class UserProfile {
  final String userId;
  final String userName;
  final ProfileType activeProfile;
  final String? activeChildId; // Only used when activeProfile == child
  final bool hasStudentProfile; // Whether user is also a student
  final String? studentTeacherId; // Teacher for user's own student profile
  final String? studentTeacherName;
  final List<ChildProfile> children;

  const UserProfile({
    required this.userId,
    required this.userName,
    this.activeProfile = ProfileType.parent,
    this.activeChildId,
    this.hasStudentProfile = false,
    this.studentTeacherId,
    this.studentTeacherName,
    this.children = const [],
  });

  /// Get active child profile (when in child mode)
  ChildProfile? get activeChild {
    if (activeProfile != ProfileType.child || activeChildId == null) {
      return null;
    }
    return children.where((c) => c.id == activeChildId).firstOrNull;
  }

  /// Check if user can switch to student mode
  bool get canSwitchToStudent => hasStudentProfile;

  /// Check if user has any children
  bool get hasChildren => children.isNotEmpty;

  /// Get connected children (with teacher)
  List<ChildProfile> get connectedChildren =>
      children.where((c) => c.isConnected).toList();

  /// Get unconnected children (practice/metronome only)
  List<ChildProfile> get unconnectedChildren =>
      children.where((c) => c.isUnconnected).toList();

  /// Get pending children (waiting for connection)
  List<ChildProfile> get pendingChildren =>
      children.where((c) => c.isPending).toList();

  /// Get available profile types for switching
  List<ProfileType> get availableProfiles {
    final profiles = <ProfileType>[ProfileType.parent];
    if (hasStudentProfile) {
      profiles.add(ProfileType.student);
    }
    if (hasChildren) {
      profiles.add(ProfileType.child);
    }
    return profiles;
  }

  /// Get display name for current profile
  String get activeProfileDisplayName {
    switch (activeProfile) {
      case ProfileType.parent:
        return userName;
      case ProfileType.student:
        return '$userName (학생)';
      case ProfileType.child:
        return activeChild?.name ?? '자녀';
    }
  }

  /// Copy with new values
  UserProfile copyWith({
    String? userId,
    String? userName,
    ProfileType? activeProfile,
    String? activeChildId,
    bool? hasStudentProfile,
    String? studentTeacherId,
    String? studentTeacherName,
    List<ChildProfile>? children,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      activeProfile: activeProfile ?? this.activeProfile,
      activeChildId: activeChildId ?? this.activeChildId,
      hasStudentProfile: hasStudentProfile ?? this.hasStudentProfile,
      studentTeacherId: studentTeacherId ?? this.studentTeacherId,
      studentTeacherName: studentTeacherName ?? this.studentTeacherName,
      children: children ?? this.children,
    );
  }

  /// Switch to parent profile
  UserProfile switchToParent() {
    return copyWith(
      activeProfile: ProfileType.parent,
      activeChildId: null,
    );
  }

  /// Switch to student profile (if available)
  UserProfile switchToStudent() {
    if (!hasStudentProfile) return this;
    return copyWith(
      activeProfile: ProfileType.student,
      activeChildId: null,
    );
  }

  /// Switch to child profile
  UserProfile switchToChild(String childId) {
    if (!children.any((c) => c.id == childId)) return this;
    return copyWith(
      activeProfile: ProfileType.child,
      activeChildId: childId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          activeProfile == other.activeProfile &&
          activeChildId == other.activeChildId;

  @override
  int get hashCode =>
      userId.hashCode ^ activeProfile.hashCode ^ activeChildId.hashCode;
}
