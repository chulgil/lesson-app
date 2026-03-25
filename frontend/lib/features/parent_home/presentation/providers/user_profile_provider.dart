import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/child_profile.dart';
import '../../../../features/parent_home/domain/entities/user_profile.dart';
import './child_profile_provider.dart';

part 'user_profile_provider.g.dart';

/// Provider for the current user's profile with active role context
///
/// This provider manages:
/// - Active profile type (parent, student, child)
/// - Profile switching between roles
/// - Access to child profiles
@riverpod
class CurrentUserProfile extends _$CurrentUserProfile {
  @override
  UserProfile build() {
    // TODO: Load from auth/storage service
    // For now, return a default parent profile
    return const UserProfile(
      userId: 'current-user-id',
      userName: '사용자',
      activeProfile: ProfileType.parent,
      hasStudentProfile: false,
      children: [],
    );
  }

  /// Initialize user profile from auth data
  void initialize({
    required String userId,
    required String userName,
    required bool hasStudentProfile,
    String? studentTeacherId,
    String? studentTeacherName,
    List<ChildProfile>? children,
  }) {
    state = UserProfile(
      userId: userId,
      userName: userName,
      activeProfile: ProfileType.parent,
      hasStudentProfile: hasStudentProfile,
      studentTeacherId: studentTeacherId,
      studentTeacherName: studentTeacherName,
      children: children ?? [],
    );
  }

  /// Switch to parent profile
  void switchToParent() {
    state = state.switchToParent();
  }

  /// Switch to student profile (if user is also a student)
  void switchToStudent() {
    if (!state.hasStudentProfile) return;
    state = state.switchToStudent();
  }

  /// Switch to child profile
  void switchToChild(String childId) {
    state = state.switchToChild(childId);
  }

  /// Update children list
  void updateChildren(List<ChildProfile> children) {
    state = state.copyWith(children: children);

    // If currently viewing a child that no longer exists, switch to parent
    if (state.activeProfile == ProfileType.child) {
      final activeChild = state.activeChild;
      if (activeChild == null) {
        switchToParent();
      }
    }
  }

  /// Add a child to the list
  void addChild(ChildProfile child) {
    final updated = [...state.children, child];
    state = state.copyWith(children: updated);
  }

  /// Remove a child from the list
  void removeChild(String childId) {
    final updated = state.children.where((c) => c.id != childId).toList();
    state = state.copyWith(children: updated);

    // If currently viewing the removed child, switch to parent
    if (state.activeProfile == ProfileType.child &&
        state.activeChildId == childId) {
      switchToParent();
    }
  }

  /// Update student profile status
  void setHasStudentProfile(bool hasProfile, {String? teacherId, String? teacherName}) {
    state = state.copyWith(
      hasStudentProfile: hasProfile,
      studentTeacherId: teacherId,
      studentTeacherName: teacherName,
    );

    // If currently in student mode but no longer has student profile, switch to parent
    if (!hasProfile && state.activeProfile == ProfileType.student) {
      switchToParent();
    }
  }
}

/// Provider for available profile types the current user can switch to
@riverpod
List<ProfileType> availableProfileTypes(Ref ref) {
  final userProfile = ref.watch(currentUserProfileProvider);
  return userProfile.availableProfiles;
}

/// Provider for checking if profile switching is available
@riverpod
bool canSwitchProfiles(Ref ref) {
  final available = ref.watch(availableProfileTypesProvider);
  return available.length > 1;
}

/// Provider for the active profile type
@riverpod
ProfileType activeProfileType(Ref ref) {
  final userProfile = ref.watch(currentUserProfileProvider);
  return userProfile.activeProfile;
}

/// Provider for the active child profile (when in child mode)
@riverpod
ChildProfile? activeChildProfile(Ref ref) {
  final userProfile = ref.watch(currentUserProfileProvider);
  return userProfile.activeChild;
}

/// Provider that indicates if the current view should show unconnected child features
///
/// Returns true when:
/// - User is in child mode AND
/// - Active child is unconnected
@riverpod
bool isUnconnectedChildMode(Ref ref) {
  final userProfile = ref.watch(currentUserProfileProvider);
  if (userProfile.activeProfile != ProfileType.child) return false;

  final activeChild = userProfile.activeChild;
  return activeChild?.isUnconnected ?? false;
}

/// Provider for syncing user profile with child profiles from repository
@riverpod
Future<void> syncUserProfileChildren(
  Ref ref,
  String parentId,
) async {
  final children = await ref.watch(childProfilesProvider(parentId).future);
  ref.read(currentUserProfileProvider.notifier).updateChildren(children);
}
