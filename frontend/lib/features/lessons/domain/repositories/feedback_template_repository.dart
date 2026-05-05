import '../entities/feedback_template.dart';

/// Repository interface for feedback templates.
abstract class FeedbackTemplateRepository {
  Future<List<FeedbackTemplate>> getTemplates(String teacherId);
  Future<List<FeedbackTemplate>> getTemplatesByCategory(
    String teacherId,
    FeedbackCategory category,
  );
  Future<List<FeedbackTemplate>> getTemplatesByTag(
    String teacherId,
    String tag,
  );
  Future<List<FeedbackTemplate>> searchTemplates(
    String teacherId,
    String query,
  );
  Future<List<FeedbackTemplate>> getFrequentlyUsed(
    String teacherId, {
    int limit = 3,
  });
  Future<FeedbackTemplate> createTemplate(FeedbackTemplate template);
  Future<FeedbackTemplate> updateTemplate(FeedbackTemplate template);
  Future<void> deleteTemplate(String id);
  Future<FeedbackTemplate> incrementUsage(String id);
}
