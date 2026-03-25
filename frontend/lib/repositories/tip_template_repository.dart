import 'package:uuid/uuid.dart';

import '../features/lessons/domain/entities/tip_template.dart';

/// Repository interface for tip templates
abstract class TipTemplateRepository {
  Future<List<TipTemplate>> getTemplates(String teacherId);
  Future<List<TipTemplate>> getTemplatesByCategory(
      String teacherId, TipCategory category);
  Future<List<TipTemplate>> getTemplatesByInstrument(
      String teacherId, String? instrument);
  Future<List<TipTemplate>> searchTemplates(String teacherId, String query);
  Future<List<TipTemplate>> getFrequentlyUsed(String teacherId, {int limit = 5});
  Future<TipTemplate> createTemplate(TipTemplate template);
  Future<TipTemplate> updateTemplate(TipTemplate template);
  Future<void> deleteTemplate(String id);
  Future<TipTemplate> incrementUsage(String id);
}

/// Mock implementation for development
class MockTipTemplateRepository implements TipTemplateRepository {
  final _uuid = const Uuid();
  final List<TipTemplate> _templates = [];

  MockTipTemplateRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final teacherId = 'teacher_1';

    // Violin technique tips
    _templates.addAll([
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '활 압력을 줄이고 속도를 높여서 가볍게 연주해보세요',
        category: TipCategory.technique,
        instrument: '바이올린',
        usageCount: 15,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUsedAt: now.subtract(const Duration(days: 1)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '왼손 엄지 긴장을 풀고 목 부분을 가볍게 잡아주세요',
        category: TipCategory.technique,
        instrument: '바이올린',
        usageCount: 12,
        createdAt: now.subtract(const Duration(days: 25)),
        lastUsedAt: now.subtract(const Duration(days: 2)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '비브라토는 손목이 아닌 팔 전체의 움직임으로 만들어주세요',
        category: TipCategory.technique,
        instrument: '바이올린',
        usageCount: 8,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '현을 바꿀 때 팔꿈치 높이를 미리 준비해주세요',
        category: TipCategory.technique,
        instrument: '바이올린',
        usageCount: 10,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ]);

    // Musicality tips
    _templates.addAll([
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '프레이즈의 방향을 생각하며 자연스럽게 크레센도/디크레센도 해주세요',
        category: TipCategory.musicality,
        usageCount: 9,
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '쉼표는 단순히 멈추는 것이 아니라 음악의 일부입니다',
        category: TipCategory.musicality,
        usageCount: 6,
        createdAt: now.subtract(const Duration(days: 22)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '노래 부르듯이 연주해보세요 - 숨 쉬는 곳을 찾아보세요',
        category: TipCategory.musicality,
        usageCount: 11,
        createdAt: now.subtract(const Duration(days: 18)),
        lastUsedAt: now.subtract(const Duration(hours: 12)),
      ),
    ]);

    // Practice tips
    _templates.addAll([
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '어려운 부분은 메트로놈 템포를 절반으로 낮추고 시작하세요',
        category: TipCategory.practice,
        usageCount: 20,
        createdAt: now.subtract(const Duration(days: 35)),
        lastUsedAt: now,
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '연습 전 5분 스케일/아르페지오로 워밍업 하세요',
        category: TipCategory.practice,
        usageCount: 18,
        createdAt: now.subtract(const Duration(days: 32)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '같은 패시지를 3번 연속 완벽하게 연주할 때까지 반복하세요',
        category: TipCategory.practice,
        usageCount: 14,
        createdAt: now.subtract(const Duration(days: 27)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '녹음해서 들어보세요 - 자신의 연주를 객관적으로 평가할 수 있습니다',
        category: TipCategory.practice,
        usageCount: 7,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ]);

    // Mindset tips
    _templates.addAll([
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '실수해도 괜찮습니다. 실수는 배움의 과정입니다',
        category: TipCategory.mindset,
        usageCount: 5,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '연주 전 깊은 호흡으로 긴장을 풀어주세요',
        category: TipCategory.mindset,
        usageCount: 8,
        createdAt: now.subtract(const Duration(days: 33)),
      ),
    ]);

    // Piano tips
    _templates.addAll([
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '손목을 유연하게 유지하고 팔의 무게를 사용하세요',
        category: TipCategory.technique,
        instrument: '피아노',
        usageCount: 13,
        createdAt: now.subtract(const Duration(days: 29)),
      ),
      TipTemplate(
        id: _uuid.v4(),
        teacherId: teacherId,
        content: '페달은 귀로 듣고 발로 조절하세요',
        category: TipCategory.technique,
        instrument: '피아노',
        usageCount: 9,
        createdAt: now.subtract(const Duration(days: 24)),
      ),
    ]);
  }

  @override
  Future<List<TipTemplate>> getTemplates(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _templates
        .where((t) => t.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  @override
  Future<List<TipTemplate>> getTemplatesByCategory(
      String teacherId, TipCategory category) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _templates
        .where((t) => t.teacherId == teacherId && t.category == category)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  @override
  Future<List<TipTemplate>> getTemplatesByInstrument(
      String teacherId, String? instrument) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _templates
        .where((t) =>
            t.teacherId == teacherId &&
            (t.instrument == instrument || t.instrument == null))
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  }

  @override
  Future<List<TipTemplate>> searchTemplates(
      String teacherId, String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final lowerQuery = query.toLowerCase();
    return _templates
        .where((t) =>
            t.teacherId == teacherId &&
            t.content.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<List<TipTemplate>> getFrequentlyUsed(String teacherId,
      {int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final templates = _templates
        .where((t) => t.teacherId == teacherId && t.usageCount > 0)
        .toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return templates.take(limit).toList();
  }

  @override
  Future<TipTemplate> createTemplate(TipTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newTemplate = template.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _templates.add(newTemplate);
    return newTemplate;
  }

  @override
  Future<TipTemplate> updateTemplate(TipTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      throw Exception('Template not found');
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
  Future<TipTemplate> incrementUsage(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Template not found');
    }
    final updated = _templates[index].incrementUsage();
    _templates[index] = updated;
    return updated;
  }
}
