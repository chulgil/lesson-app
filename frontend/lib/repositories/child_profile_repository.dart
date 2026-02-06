import 'package:flutter/material.dart';

import '../models/child_profile.dart';

/// Repository interface for child profile operations
abstract class ChildProfileRepository {
  /// Get all child profiles for a parent
  Future<List<ChildProfile>> getChildProfilesByParent(String parentId);

  /// Get a specific child profile by ID
  Future<ChildProfile?> getChildProfile(String childId);

  /// Add a new child profile
  Future<ChildProfile> addChildProfile(ChildProfile profile);

  /// Update an existing child profile
  Future<ChildProfile> updateChildProfile(ChildProfile profile);

  /// Delete a child profile (soft delete - sets status to inactive)
  Future<void> deleteChildProfile(String childId);

  /// Connect a teacher to a child profile
  Future<ChildProfile> connectTeacher(
      String childId, String teacherId, String teacherName);

  /// Disconnect teacher from a child profile
  Future<ChildProfile> disconnectTeacher(String childId);
}

/// Mock implementation of ChildProfileRepository
class MockChildProfileRepository implements ChildProfileRepository {
  final List<ChildProfile> _profiles = [
    ChildProfile(
      id: 'child_1',
      parentId: 'parent_1',
      name: '민준이',
      birthYear: 2015,
      instrument: 'violin',
      level: 'elementary',
      teacherId: 'teacher_1',
      teacherName: '김선생님',
      profileColor: Colors.blue,
      status: ChildProfileStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    ChildProfile(
      id: 'child_2',
      parentId: 'parent_1',
      name: '서연이',
      birthYear: 2017,
      instrument: 'piano',
      level: 'beginner',
      teacherId: 'teacher_2',
      teacherName: '박선생님',
      profileColor: Colors.pink,
      status: ChildProfileStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    ChildProfile(
      id: 'child_3',
      parentId: 'parent_2',
      name: '지우',
      birthYear: 2014,
      instrument: 'cello',
      level: 'intermediate',
      teacherId: 'teacher_1',
      teacherName: '김선생님',
      profileColor: Colors.green,
      status: ChildProfileStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
  ];

  @override
  Future<List<ChildProfile>> getChildProfilesByParent(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _profiles
        .where((p) =>
            p.parentId == parentId && p.status == ChildProfileStatus.active)
        .toList();
  }

  @override
  Future<ChildProfile?> getChildProfile(String childId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _profiles.firstWhere((p) => p.id == childId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ChildProfile> addChildProfile(ChildProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newProfile = profile.copyWith(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _profiles.add(newProfile);
    return newProfile;
  }

  @override
  Future<ChildProfile> updateChildProfile(ChildProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index == -1) {
      throw Exception('Child profile not found: ${profile.id}');
    }
    final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
    _profiles[index] = updatedProfile;
    return updatedProfile;
  }

  @override
  Future<void> deleteChildProfile(String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _profiles.indexWhere((p) => p.id == childId);
    if (index == -1) {
      throw Exception('Child profile not found: $childId');
    }
    _profiles[index] =
        _profiles[index].copyWith(status: ChildProfileStatus.inactive);
  }

  @override
  Future<ChildProfile> connectTeacher(
      String childId, String teacherId, String teacherName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _profiles.indexWhere((p) => p.id == childId);
    if (index == -1) {
      throw Exception('Child profile not found: $childId');
    }
    final updatedProfile = _profiles[index].copyWith(
      teacherId: teacherId,
      teacherName: teacherName,
      updatedAt: DateTime.now(),
    );
    _profiles[index] = updatedProfile;
    return updatedProfile;
  }

  @override
  Future<ChildProfile> disconnectTeacher(String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _profiles.indexWhere((p) => p.id == childId);
    if (index == -1) {
      throw Exception('Child profile not found: $childId');
    }
    // Create new profile without teacherId/teacherName
    final current = _profiles[index];
    final updatedProfile = ChildProfile(
      id: current.id,
      parentId: current.parentId,
      name: current.name,
      birthYear: current.birthYear,
      instrument: current.instrument,
      level: current.level,
      teacherId: null,
      teacherName: null,
      profileColor: current.profileColor,
      status: current.status,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    _profiles[index] = updatedProfile;
    return updatedProfile;
  }
}
