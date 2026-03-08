import '../entities/teaching_resource.dart';

/// Repository interface for teaching resources
abstract class TeachingResourceRepository {
  /// Get all resources for a teacher
  Future<List<TeachingResource>> getByTeacherId(String teacherId);

  /// Get resources by IDs (for displaying attached resources)
  Future<List<TeachingResource>> getByIds(List<String> ids);

  /// Get a single resource by ID
  Future<TeachingResource?> getById(String id);

  /// Create a new resource
  Future<TeachingResource> create(TeachingResource resource);

  /// Update a resource
  Future<TeachingResource> update(TeachingResource resource);

  /// Delete a resource
  Future<void> delete(String id);
}
