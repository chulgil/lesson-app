import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../data/repositories/mock_child_profile_repository.dart';
import '../../domain/entities/child_profile.dart';
import '../../domain/repositories/child_profile_repository.dart';

part 'child_profile_provider.g.dart';

/// Provider for the child profile repository - switches between Mock and Remote.
@riverpod
ChildProfileRepository childProfileRepository(Ref ref) {
  if (EnvironmentConfig.useMockData) {
    return MockChildProfileRepository();
  }
  // No remote API yet — use empty mock to avoid dummy data
  return MockChildProfileRepository(empty: true);
}

/// Provider for child profiles of a specific parent
@riverpod
Future<List<ChildProfile>> childProfiles(Ref ref, String parentId) async {
  final repository = ref.watch(childProfileRepositoryProvider);
  return repository.getChildProfilesByParent(parentId);
}

/// Provider for a single child profile
@riverpod
Future<ChildProfile?> childProfile(Ref ref, String childId) async {
  final repository = ref.watch(childProfileRepositoryProvider);
  return repository.getChildProfile(childId);
}

/// Currently selected child profile for parent view
@riverpod
class SelectedChildProfile extends _$SelectedChildProfile {
  @override
  ChildProfile? build() => null;

  void select(ChildProfile? profile) {
    state = profile;
  }

  void clear() {
    state = null;
  }
}

/// Notifier for managing child profiles (add, update, delete)
@riverpod
class ChildProfileManager extends _$ChildProfileManager {
  @override
  FutureOr<void> build() {}

  Future<ChildProfile> addChildProfile({
    required String parentId,
    required String name,
    required int birthYear,
    required String instrument,
    required String level,
    required Color profileColor,
  }) async {
    state = const AsyncLoading();

    final repository = ref.read(childProfileRepositoryProvider);

    try {
      final newProfile = ChildProfile(
        id: '', // Will be assigned by repository
        parentId: parentId,
        name: name,
        birthYear: birthYear,
        instrument: instrument,
        level: level,
        profileColor: profileColor,
        createdAt: DateTime.now(),
      );

      final result = await repository.addChildProfile(newProfile);

      // Invalidate the profiles list to refresh
      ref.invalidate(childProfilesProvider(parentId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<ChildProfile> updateChildProfile(ChildProfile profile) async {
    state = const AsyncLoading();

    final repository = ref.read(childProfileRepositoryProvider);

    try {
      final result = await repository.updateChildProfile(profile);

      // Invalidate related providers
      ref.invalidate(childProfilesProvider(profile.parentId));
      ref.invalidate(childProfileProvider(profile.id));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteChildProfile(String childId, String parentId) async {
    state = const AsyncLoading();

    final repository = ref.read(childProfileRepositoryProvider);

    try {
      await repository.deleteChildProfile(childId);

      // Invalidate the profiles list
      ref.invalidate(childProfilesProvider(parentId));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<ChildProfile> connectTeacher(
    String childId,
    String parentId,
    String teacherId,
    String teacherName,
  ) async {
    state = const AsyncLoading();

    final repository = ref.read(childProfileRepositoryProvider);

    try {
      final result = await repository.connectTeacher(
        childId,
        teacherId,
        teacherName,
      );

      // Invalidate related providers
      ref.invalidate(childProfilesProvider(parentId));
      ref.invalidate(childProfileProvider(childId));

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
