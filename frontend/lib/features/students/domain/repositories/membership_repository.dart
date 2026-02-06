import '../entities/class_membership.dart';

/// Repository interface for ClassMembership operations.
abstract class MembershipRepository {
  /// Get all memberships for a class.
  Future<List<ClassMembership>> getByClassId(String classId);

  /// Get all memberships for a student.
  Future<List<ClassMembership>> getByStudentId(String studentId);

  /// Get a single membership by ID.
  Future<ClassMembership?> getById(String id);

  /// Create a new membership.
  Future<ClassMembership> create(ClassMembership membership);

  /// Update an existing membership.
  Future<ClassMembership> update(ClassMembership membership);

  /// Update membership status.
  Future<void> updateStatus(String id, MembershipStatus status);

  /// Delete a membership.
  Future<void> delete(String id);

  /// Watch all memberships for a class (stream).
  Stream<List<ClassMembership>> watchByClassId(String classId);

  /// Watch all memberships for a student (stream).
  Stream<List<ClassMembership>> watchByStudentId(String studentId);
}
