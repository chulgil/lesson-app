import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../auth/auth_facade.dart';
import '../../data/repositories/mock_tip_template_repository.dart';
import '../../domain/entities/tip_template.dart';
import '../../domain/repositories/tip_template_repository.dart';

part 'tip_template_providers.g.dart';

/// Repository provider
@Riverpod(keepAlive: true)
TipTemplateRepository tipTemplateRepository(TipTemplateRepositoryRef ref) {
  return createLocalFallbackRepository<TipTemplateRepository>(
    ref: ref,
    mock: () => MockTipTemplateRepository(),
    fallback: () => MockTipTemplateRepository(),
  );
}

/// Current teacher ID provider - uses currentUserIdProvider from auth
@Riverpod(keepAlive: true)
String currentTeacherId(CurrentTeacherIdRef ref) {
  return ref.watch(currentUserIdProvider);
}

/// All templates for current teacher
@Riverpod(keepAlive: true)
Future<List<TipTemplate>> tipTemplates(TipTemplatesRef ref) async {
  final repository = ref.watch(tipTemplateRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.getTemplates(teacherId);
}

/// Templates by category
@Riverpod(keepAlive: true)
Future<List<TipTemplate>> tipTemplatesByCategory(
  TipTemplatesByCategoryRef ref,
  TipCategory category,
) async {
  final repository = ref.watch(tipTemplateRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.getTemplatesByCategory(teacherId, category);
}

/// Templates for specific instrument (includes general tips)
@Riverpod(keepAlive: true)
Future<List<TipTemplate>> tipTemplatesByInstrument(
  TipTemplatesByInstrumentRef ref,
  String? instrument,
) async {
  final repository = ref.watch(tipTemplateRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.getTemplatesByInstrument(teacherId, instrument);
}

/// Frequently used templates
@Riverpod(keepAlive: true)
Future<List<TipTemplate>> frequentTipTemplates(
  FrequentTipTemplatesRef ref,
) async {
  final repository = ref.watch(tipTemplateRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.getFrequentlyUsed(teacherId, limit: 5);
}

/// Search templates
@Riverpod(keepAlive: true)
Future<List<TipTemplate>> tipTemplateSearch(
  TipTemplateSearchRef ref,
  String query,
) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(tipTemplateRepositoryProvider);
  final teacherId = ref.watch(currentTeacherIdProvider);
  return repository.searchTemplates(teacherId, query);
}

/// Notifier for CRUD operations
@Riverpod(keepAlive: true)
class TipTemplatesNotifier extends _$TipTemplatesNotifier {
  TipTemplateRepository get _repository =>
      ref.read(tipTemplateRepositoryProvider);
  String get _teacherId => ref.read(currentTeacherIdProvider);

  @override
  Future<List<TipTemplate>> build() async {
    return _repository.getTemplates(_teacherId);
  }

  Future<TipTemplate> addTemplate({
    required String content,
    TipCategory category = TipCategory.general,
    String? instrument,
  }) async {
    final template = TipTemplate(
      id: '',
      teacherId: _teacherId,
      content: content,
      category: category,
      instrument: instrument,
      createdAt: DateTime.now(),
    );

    state = const AsyncValue.loading();
    try {
      final newTemplate = await _repository.createTemplate(template);
      state = await AsyncValue.guard(
        () => _repository.getTemplates(_teacherId),
      );
      return newTemplate;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TipTemplate> updateTemplate(TipTemplate template) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateTemplate(template);
      state = await AsyncValue.guard(
        () => _repository.getTemplates(_teacherId),
      );
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTemplate(id);
      state = await AsyncValue.guard(
        () => _repository.getTemplates(_teacherId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<TipTemplate> useTemplate(String id) async {
    try {
      final updated = await _repository.incrementUsage(id);
      // Don't reload full list, just update in background
      ref.invalidate(frequentTipTemplatesProvider);
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}
