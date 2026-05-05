import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/auth_facade.dart';
import '../../data/repositories/mock_feedback_template_repository.dart';
import '../../domain/entities/feedback_template.dart';
import '../../domain/repositories/feedback_template_repository.dart';

/// Repository provider — singleton mock for now.
final feedbackTemplateRepositoryProvider = Provider<FeedbackTemplateRepository>(
  (ref) {
    return MockFeedbackTemplateRepository();
  },
);

final _currentTeacherIdProvider = Provider<String>((ref) {
  return ref.watch(currentUserIdProvider);
});

/// All templates owned by the current teacher.
final feedbackTemplatesProvider = FutureProvider<List<FeedbackTemplate>>((
  ref,
) async {
  final repo = ref.watch(feedbackTemplateRepositoryProvider);
  final teacherId = ref.watch(_currentTeacherIdProvider);
  return repo.getTemplates(teacherId);
});

/// Templates filtered by category.
final feedbackTemplatesByCategoryProvider =
    FutureProvider.family<List<FeedbackTemplate>, FeedbackCategory>((
      ref,
      category,
    ) async {
      final repo = ref.watch(feedbackTemplateRepositoryProvider);
      final teacherId = ref.watch(_currentTeacherIdProvider);
      return repo.getTemplatesByCategory(teacherId, category);
    });

/// Top-N most-used templates (for the picker's "자주 사용" section).
final frequentFeedbackTemplatesProvider =
    FutureProvider<List<FeedbackTemplate>>((ref) async {
      final repo = ref.watch(feedbackTemplateRepositoryProvider);
      final teacherId = ref.watch(_currentTeacherIdProvider);
      return repo.getFrequentlyUsed(teacherId, limit: 3);
    });

/// Search by title/body/tags.
final feedbackTemplateSearchProvider =
    FutureProvider.family<List<FeedbackTemplate>, String>((ref, query) async {
      if (query.isEmpty) return const [];
      final repo = ref.watch(feedbackTemplateRepositoryProvider);
      final teacherId = ref.watch(_currentTeacherIdProvider);
      return repo.searchTemplates(teacherId, query);
    });

/// CRUD notifier mirroring TipTemplatesNotifier conventions.
class FeedbackTemplatesNotifier extends AsyncNotifier<List<FeedbackTemplate>> {
  FeedbackTemplateRepository get _repo =>
      ref.read(feedbackTemplateRepositoryProvider);
  String get _teacherId => ref.read(_currentTeacherIdProvider);

  @override
  Future<List<FeedbackTemplate>> build() async {
    return _repo.getTemplates(_teacherId);
  }

  Future<FeedbackTemplate> addTemplate({
    required String title,
    required String body,
    List<String> tags = const [],
    FeedbackCategory category = FeedbackCategory.general,
  }) async {
    final draft = FeedbackTemplate(
      id: '',
      teacherId: _teacherId,
      title: title,
      body: body,
      tags: tags,
      category: category,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      final created = await _repo.createTemplate(draft);
      state = await AsyncValue.guard(() => _repo.getTemplates(_teacherId));
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<FeedbackTemplate> updateTemplate(FeedbackTemplate template) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateTemplate(template);
      state = await AsyncValue.guard(() => _repo.getTemplates(_teacherId));
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTemplate(id);
      state = await AsyncValue.guard(() => _repo.getTemplates(_teacherId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Bumps usage counter without reloading the full list.
  /// Frequent-templates view is invalidated so picker re-sorts on next open.
  Future<FeedbackTemplate> useTemplate(String id) async {
    final updated = await _repo.incrementUsage(id);
    ref.invalidate(frequentFeedbackTemplatesProvider);
    return updated;
  }
}

final feedbackTemplatesNotifierProvider =
    AsyncNotifierProvider<FeedbackTemplatesNotifier, List<FeedbackTemplate>>(
      FeedbackTemplatesNotifier.new,
    );
