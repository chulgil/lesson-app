import '../entities/tip_template.dart';

/// Repository interface for tip templates
abstract class TipTemplateRepository {
  Future<List<TipTemplate>> getTemplates(String teacherId);
  Future<List<TipTemplate>> getTemplatesByCategory(
    String teacherId,
    TipCategory category,
  );
  Future<List<TipTemplate>> getTemplatesByInstrument(
    String teacherId,
    String? instrument,
  );
  Future<List<TipTemplate>> searchTemplates(String teacherId, String query);
  Future<List<TipTemplate>> getFrequentlyUsed(
    String teacherId, {
    int limit = 5,
  });
  Future<TipTemplate> createTemplate(TipTemplate template);
  Future<TipTemplate> updateTemplate(TipTemplate template);
  Future<void> deleteTemplate(String id);
  Future<TipTemplate> incrementUsage(String id);
}
