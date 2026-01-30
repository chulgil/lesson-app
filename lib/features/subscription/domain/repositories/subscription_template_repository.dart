import '../entities/subscription_template.dart';

/// Repository interface for subscription templates.
abstract class SubscriptionTemplateRepository {
  /// Get all templates for a teacher
  Future<List<SubscriptionTemplate>> getByTeacher(String teacherId);

  /// Get all templates for an academy
  Future<List<SubscriptionTemplate>> getByAcademy(String academyId);

  /// Get a template by ID
  Future<SubscriptionTemplate?> getById(String id);

  /// Get active templates for a teacher (for student display)
  Future<List<SubscriptionTemplate>> getActiveByTeacher(String teacherId);

  /// Get active templates for an academy (for student display)
  Future<List<SubscriptionTemplate>> getActiveByAcademy(String academyId);

  /// 🆕 Get auto-proposal enabled templates for a teacher
  /// Returns active templates that have isAutoProposalEnabled = true
  /// Used for automatic proposal generation (trial completion / subscription renewal)
  Future<List<SubscriptionTemplate>> getAutoProposalTemplates(String teacherId);

  /// Create a new template
  Future<SubscriptionTemplate> create(SubscriptionTemplate template);

  /// Update an existing template
  Future<SubscriptionTemplate> update(SubscriptionTemplate template);

  /// Delete a template
  Future<void> delete(String id);

  /// Toggle template active status
  Future<SubscriptionTemplate> toggleActive(String id);

  /// Reorder templates (update displayOrder)
  Future<void> reorder(List<String> orderedIds);
}
