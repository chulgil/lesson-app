import '../entities/child_profile.dart';

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
    String childId,
    String teacherId,
    String teacherName,
  );

  /// Disconnect teacher from a child profile
  Future<ChildProfile> disconnectTeacher(String childId);
}
