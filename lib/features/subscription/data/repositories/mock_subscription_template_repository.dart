import '../../domain/entities/subscription_template.dart';
import '../../domain/repositories/subscription_template_repository.dart';

/// Mock implementation of SubscriptionTemplateRepository.
class MockSubscriptionTemplateRepository
    implements SubscriptionTemplateRepository {
  final Map<String, SubscriptionTemplate> _templates = {};

  MockSubscriptionTemplateRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Teacher templates (김지수 선생님 - teacher_1)
    // isAutoProposalEnabled: 체험레슨 후 자동 제안에 포함될 수강권
    final teacherTemplates = [
      SubscriptionTemplate(
        id: 'template_t1_1',
        ownerId: 'teacher_1',
        ownerType: SubscriptionTemplateOwnerType.teacher,
        name: '4회권',
        totalLessons: 4,
        lessonDurationMinutes: 50,
        validityDays: 60,
        price: 200000,
        isActive: true,
        displayOrder: 0,
        description: '입문자 추천',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isAutoProposalEnabled: true, // ✅ 자동 제안 대상
      ),
      SubscriptionTemplate(
        id: 'template_t1_2',
        ownerId: 'teacher_1',
        ownerType: SubscriptionTemplateOwnerType.teacher,
        name: '8회권',
        totalLessons: 8,
        lessonDurationMinutes: 50,
        validityDays: 90,
        price: 380000,
        isActive: true,
        displayOrder: 1,
        description: '가장 인기 있는 패키지',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isAutoProposalEnabled: true, // ✅ 자동 제안 대상
      ),
      SubscriptionTemplate(
        id: 'template_t1_3',
        ownerId: 'teacher_1',
        ownerType: SubscriptionTemplateOwnerType.teacher,
        name: '16회권',
        totalLessons: 16,
        lessonDurationMinutes: 50,
        validityDays: 150,
        price: 720000,
        isActive: true,
        displayOrder: 2,
        description: '장기 수강 할인',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isAutoProposalEnabled: false, // ❌ 선생님 직접 제안 전용
      ),
    ];

    // Academy templates (ABC 음악학원 - academy_1)
    final academyTemplates = [
      SubscriptionTemplate(
        id: 'template_a1_1',
        ownerId: 'academy_1',
        ownerType: SubscriptionTemplateOwnerType.academy,
        name: '4회권',
        totalLessons: 4,
        lessonDurationMinutes: 45,
        validityDays: 45,
        price: 180000,
        isActive: true,
        displayOrder: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      SubscriptionTemplate(
        id: 'template_a1_2',
        ownerId: 'academy_1',
        ownerType: SubscriptionTemplateOwnerType.academy,
        name: '8회권',
        totalLessons: 8,
        lessonDurationMinutes: 45,
        validityDays: 75,
        price: 340000,
        isActive: true,
        displayOrder: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      SubscriptionTemplate(
        id: 'template_a1_3',
        ownerId: 'academy_1',
        ownerType: SubscriptionTemplateOwnerType.academy,
        name: '12회권',
        totalLessons: 12,
        lessonDurationMinutes: 45,
        validityDays: 120,
        price: 480000,
        isActive: true,
        displayOrder: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];

    for (final template in [...teacherTemplates, ...academyTemplates]) {
      _templates[template.id] = template;
    }
  }

  @override
  Future<List<SubscriptionTemplate>> getByTeacher(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _templates.values
        .where((t) =>
            t.ownerId == teacherId &&
            t.ownerType == SubscriptionTemplateOwnerType.teacher)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  Future<List<SubscriptionTemplate>> getByAcademy(String academyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _templates.values
        .where((t) =>
            t.ownerId == academyId &&
            t.ownerType == SubscriptionTemplateOwnerType.academy)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  Future<SubscriptionTemplate?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _templates[id];
  }

  @override
  Future<List<SubscriptionTemplate>> getActiveByTeacher(
      String teacherId) async {
    final templates = await getByTeacher(teacherId);
    return templates.where((t) => t.isActive).toList();
  }

  @override
  Future<List<SubscriptionTemplate>> getActiveByAcademy(
      String academyId) async {
    final templates = await getByAcademy(academyId);
    return templates.where((t) => t.isActive).toList();
  }

  @override
  Future<List<SubscriptionTemplate>> getAutoProposalTemplates(
      String teacherId) async {
    final templates = await getActiveByTeacher(teacherId);
    // 활성화되어 있고 자동 제안 대상인 템플릿만 반환
    return templates.where((t) => t.isAutoProposalEnabled).toList();
  }

  @override
  Future<SubscriptionTemplate> create(SubscriptionTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Generate ID if not provided
    final newTemplate = template.id.isEmpty
        ? template.copyWith(
            id: 'template_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
          )
        : template;

    _templates[newTemplate.id] = newTemplate;
    return newTemplate;
  }

  @override
  Future<SubscriptionTemplate> update(SubscriptionTemplate template) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_templates.containsKey(template.id)) {
      throw Exception('Template not found: ${template.id}');
    }

    final updated = template.copyWith(updatedAt: DateTime.now());
    _templates[template.id] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _templates.remove(id);
  }

  @override
  Future<SubscriptionTemplate> toggleActive(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final template = _templates[id];
    if (template == null) {
      throw Exception('Template not found: $id');
    }

    final updated = template.copyWith(
      isActive: !template.isActive,
      updatedAt: DateTime.now(),
    );
    _templates[id] = updated;
    return updated;
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (var i = 0; i < orderedIds.length; i++) {
      final template = _templates[orderedIds[i]];
      if (template != null) {
        _templates[orderedIds[i]] = template.copyWith(
          displayOrder: i,
          updatedAt: DateTime.now(),
        );
      }
    }
  }
}
