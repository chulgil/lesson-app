import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_subscription_template_repository.dart';
import '../../data/repositories/remote_subscription_template_repository.dart';
import '../../domain/entities/subscription_template.dart';
import '../../domain/repositories/subscription_template_repository.dart';

part 'subscription_template_providers.g.dart';

// ============================================================
// Repository Provider
// ============================================================

/// Template repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
SubscriptionTemplateRepository subscriptionTemplateRepository(Ref ref) {
  return createRepository<SubscriptionTemplateRepository>(
    ref: ref,
    mock: () => MockSubscriptionTemplateRepository(),
    remote: (api) => RemoteSubscriptionTemplateRepository(api),
  );
}

// ============================================================
// Teacher Templates
// ============================================================

@riverpod
Future<List<SubscriptionTemplate>> teacherTemplates(
  TeacherTemplatesRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionTemplateRepositoryProvider);
  return repository.getByTeacher(teacherId);
}

@riverpod
Future<List<SubscriptionTemplate>> activeTeacherTemplates(
  ActiveTeacherTemplatesRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionTemplateRepositoryProvider);
  return repository.getActiveByTeacher(teacherId);
}

/// 🆕 자동 제안 대상 템플릿만 가져오기
/// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
/// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
@riverpod
Future<List<SubscriptionTemplate>> autoProposalTemplates(
  AutoProposalTemplatesRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionTemplateRepositoryProvider);
  return repository.getAutoProposalTemplates(teacherId);
}

// ============================================================
// Academy Templates
// ============================================================

@riverpod
Future<List<SubscriptionTemplate>> academyTemplates(
  AcademyTemplatesRef ref,
  String academyId,
) async {
  final repository = ref.watch(subscriptionTemplateRepositoryProvider);
  return repository.getByAcademy(academyId);
}

@riverpod
Future<List<SubscriptionTemplate>> activeAcademyTemplates(
  ActiveAcademyTemplatesRef ref,
  String academyId,
) async {
  final repository = ref.watch(subscriptionTemplateRepositoryProvider);
  return repository.getActiveByAcademy(academyId);
}

// ============================================================
// Single Template
// ============================================================

@riverpod
Future<SubscriptionTemplate?> subscriptionTemplate(
  SubscriptionTemplateRef ref,
  String templateId,
) async {
  final repository = ref.watch(subscriptionTemplateRepositoryProvider);
  return repository.getById(templateId);
}

// ============================================================
// Template Notifier (for CRUD operations)
// ============================================================

@riverpod
class SubscriptionTemplateNotifier extends _$SubscriptionTemplateNotifier {
  @override
  AsyncValue<SubscriptionTemplate?> build() => const AsyncValue.data(null);

  Future<SubscriptionTemplate> createTemplate({
    required String ownerId,
    required SubscriptionTemplateOwnerType ownerType,
    required String name,
    required int totalLessons,
    required int lessonDurationMinutes,
    required int validityDays,
    required int price,
    int? regularPrice,
    String? description,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionTemplateRepositoryProvider);

      final template = SubscriptionTemplate(
        id: '',
        ownerId: ownerId,
        ownerType: ownerType,
        name: name,
        totalLessons: totalLessons,
        lessonDurationMinutes: lessonDurationMinutes,
        validityDays: validityDays,
        price: price,
        regularPrice: regularPrice,
        description: description,
        createdAt: DateTime.now(),
      );

      final created = await repository.create(template);
      state = AsyncValue.data(created);

      // Invalidate related providers
      if (ownerType == SubscriptionTemplateOwnerType.teacher) {
        ref.invalidate(teacherTemplatesProvider(ownerId));
        ref.invalidate(activeTeacherTemplatesProvider(ownerId));
      } else {
        ref.invalidate(academyTemplatesProvider(ownerId));
        ref.invalidate(activeAcademyTemplatesProvider(ownerId));
      }

      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<SubscriptionTemplate> updateTemplate(
    SubscriptionTemplate template,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionTemplateRepositoryProvider);
      final updated = await repository.update(template);
      state = AsyncValue.data(updated);

      // Invalidate related providers
      if (template.ownerType == SubscriptionTemplateOwnerType.teacher) {
        ref.invalidate(teacherTemplatesProvider(template.ownerId));
        ref.invalidate(activeTeacherTemplatesProvider(template.ownerId));
      } else {
        ref.invalidate(academyTemplatesProvider(template.ownerId));
        ref.invalidate(activeAcademyTemplatesProvider(template.ownerId));
      }
      ref.invalidate(subscriptionTemplateProvider(template.id));

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTemplate(SubscriptionTemplate template) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionTemplateRepositoryProvider);
      await repository.delete(template.id);
      state = const AsyncValue.data(null);

      // Invalidate related providers
      if (template.ownerType == SubscriptionTemplateOwnerType.teacher) {
        ref.invalidate(teacherTemplatesProvider(template.ownerId));
        ref.invalidate(activeTeacherTemplatesProvider(template.ownerId));
      } else {
        ref.invalidate(academyTemplatesProvider(template.ownerId));
        ref.invalidate(activeAcademyTemplatesProvider(template.ownerId));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<SubscriptionTemplate> toggleActive(
    SubscriptionTemplate template,
  ) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(subscriptionTemplateRepositoryProvider);
      final updated = await repository.toggleActive(template.id);
      state = AsyncValue.data(updated);

      // Invalidate related providers
      if (template.ownerType == SubscriptionTemplateOwnerType.teacher) {
        ref.invalidate(teacherTemplatesProvider(template.ownerId));
        ref.invalidate(activeTeacherTemplatesProvider(template.ownerId));
      } else {
        ref.invalidate(academyTemplatesProvider(template.ownerId));
        ref.invalidate(activeAcademyTemplatesProvider(template.ownerId));
      }

      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
