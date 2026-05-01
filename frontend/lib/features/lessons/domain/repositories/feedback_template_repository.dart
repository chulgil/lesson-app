import 'package:uuid/uuid.dart';

import '../constants/feedback_constants.dart';
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

/// In-memory mock implementation. Seeds 9 templates derived from
/// the legacy chip preset list (`feedbackPresets`) so first-time teachers
/// have something usable.
class MockFeedbackTemplateRepository implements FeedbackTemplateRepository {
  final _uuid = const Uuid();
  final List<FeedbackTemplate> _templates = [];

  MockFeedbackTemplateRepository() {
    _initSeeds();
  }

  void _initSeeds() {
    final now = DateTime.now();
    const teacherId = 'teacher_1';

    // Map each legacy chip preset to a starter template.
    // Body = a one-line phrase teachers can edit; tag = the original chip text;
    // category = best-fit semantic.
    final seedSpecs = <_SeedSpec>[
      _SeedSpec(
        '음정 주의',
        '오늘 레슨에서 음정에 더 신경 써 주세요. 특히 어려운 구간은 천천히 음을 맞춰가며 연습합니다.',
        FeedbackCategory.technique,
      ),
      _SeedSpec(
        '리듬 좋음',
        '리듬감이 매우 좋아졌습니다. 다음 시간에는 같은 안정감으로 더 빠른 템포에 도전해 봅시다.',
        FeedbackCategory.musicality,
      ),
      _SeedSpec(
        '활 주법 연습',
        '활 주법(보잉)을 집중 연습할 시간입니다. 활의 무게와 속도를 일정하게 유지해 주세요.',
        FeedbackCategory.technique,
      ),
      _SeedSpec(
        '자세 교정',
        '연주 자세를 점검해 봅시다. 어깨와 손목의 긴장을 풀고 자연스러운 자세를 유지합니다.',
        FeedbackCategory.technique,
      ),
      _SeedSpec(
        '진도 우수',
        '진도가 매우 잘 나가고 있습니다. 이번 곡을 완성도 있게 마무리하고 다음 단계로 넘어갑시다.',
        FeedbackCategory.general,
      ),
      _SeedSpec(
        '많이 향상됨',
        '지난 시간보다 눈에 띄게 향상되었습니다. 꾸준한 연습의 결과가 나타나고 있어요.',
        FeedbackCategory.general,
      ),
      _SeedSpec(
        '복습 필요',
        '이번 레슨 내용은 다음 시간 전에 한 번 더 복습해 주세요. 핵심 구간을 반복 연습합니다.',
        FeedbackCategory.practice,
      ),
      _SeedSpec(
        '천천히 연습',
        '메트로놈 템포를 절반으로 낮춰 천천히 정확하게 연습한 뒤 점진적으로 올려 주세요.',
        FeedbackCategory.practice,
      ),
      _SeedSpec(
        '메트로놈 사용',
        '메트로놈을 사용해 박자를 정확하게 맞추는 연습이 필요합니다. 60bpm부터 시작합니다.',
        FeedbackCategory.practice,
      ),
    ];

    // Sanity check: seed list mirrors legacy presets so we don't drift.
    assert(
      seedSpecs.length == feedbackPresets.length,
      'Seed count must match legacy feedbackPresets length',
    );

    for (var i = 0; i < seedSpecs.length; i++) {
      final spec = seedSpecs[i];
      _templates.add(
        FeedbackTemplate(
          id: _uuid.v4(),
          teacherId: teacherId,
          title: spec.title,
          body: spec.body,
          tags: [spec.title],
          category: spec.category,
          usageCount: 0,
          createdAt: now.subtract(Duration(days: seedSpecs.length - i)),
        ),
      );
    }
  }

  List<FeedbackTemplate> _ownedBy(String teacherId) =>
      _templates.where((t) => t.teacherId == teacherId).toList();

  void _sortByUsage(List<FeedbackTemplate> list) {
    list.sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  @override
  Future<List<FeedbackTemplate>> getTemplates(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final list = _ownedBy(teacherId);
    _sortByUsage(list);
    return list;
  }

  @override
  Future<List<FeedbackTemplate>> getTemplatesByCategory(
    String teacherId,
    FeedbackCategory category,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list =
        _ownedBy(teacherId).where((t) => t.category == category).toList();
    _sortByUsage(list);
    return list;
  }

  @override
  Future<List<FeedbackTemplate>> getTemplatesByTag(
    String teacherId,
    String tag,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list =
        _ownedBy(teacherId).where((t) => t.tags.contains(tag)).toList();
    _sortByUsage(list);
    return list;
  }

  @override
  Future<List<FeedbackTemplate>> searchTemplates(
    String teacherId,
    String query,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final lower = query.toLowerCase();
    return _ownedBy(teacherId).where((t) {
      if (t.title.toLowerCase().contains(lower)) return true;
      if (t.body.toLowerCase().contains(lower)) return true;
      if (t.tags.any((tag) => tag.toLowerCase().contains(lower))) return true;
      return false;
    }).toList();
  }

  @override
  Future<List<FeedbackTemplate>> getFrequentlyUsed(
    String teacherId, {
    int limit = 3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _ownedBy(teacherId).where((t) => t.usageCount > 0).toList();
    _sortByUsage(list);
    return list.take(limit).toList();
  }

  @override
  Future<FeedbackTemplate> createTemplate(FeedbackTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final created = template.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _templates.add(created);
    return created;
  }

  @override
  Future<FeedbackTemplate> updateTemplate(FeedbackTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      throw Exception('FeedbackTemplate not found: ${template.id}');
    }
    _templates[index] = template;
    return template;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _templates.removeWhere((t) => t.id == id);
  }

  @override
  Future<FeedbackTemplate> incrementUsage(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('FeedbackTemplate not found: $id');
    }
    final updated = _templates[index].incrementUsage();
    _templates[index] = updated;
    return updated;
  }
}

class _SeedSpec {
  final String title;
  final String body;
  final FeedbackCategory category;
  const _SeedSpec(this.title, this.body, this.category);
}
