import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/domain/value_objects/discipline.dart';
import '../../../../core/domain/value_objects/discipline_registry.dart';
import 'user_role_provider.dart';

part 'active_discipline_provider.g.dart';

const _boxName = 'selected_discipline';

/// Persists the coaching discipline the user chose at sign-up (#979-A, Phase 4).
///
/// User-scoped (mirrors `OnboardingProgressStorage`): the Hive key carries the
/// current user id, so choices never cross-contaminate between accounts. With
/// music as the only registered discipline the selection screen auto-skips, so
/// nothing is persisted yet and [build] returns null — [activeDiscipline] then
/// falls back to music (byte-identical). Phase 4 (#979-B) registers a 2nd
/// discipline, the selection screen goes live, and this stores the choice.
@Riverpod(keepAlive: true)
class SelectedDisciplineStorage extends _$SelectedDisciplineStorage {
  @override
  Future<String?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    final box = await Hive.openBox<String>(_boxName);
    return box.get(_key(userId));
  }

  String _key(String userId) => 'user:$userId:selectedDisciplineId';

  /// Persist [disciplineId] as the current user's chosen discipline.
  Future<void> select(String disciplineId) async {
    final userId = ref.read(currentUserIdProvider);
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key(userId), disciplineId);
    state = AsyncData(disciplineId);
  }
}

/// The active coaching discipline for the logged-in user (#979-A).
///
/// Resolves the persisted [SelectedDisciplineStorage] id through
/// [DisciplineRegistry], falling back to music for null / legacy / unknown ids
/// (including while the async storage is still loading). Music-only today, so
/// this always resolves to music = byte-identical; it is the seam the practice
/// tools modal reads to pick a discipline's tool set.
@riverpod
Discipline activeDiscipline(ActiveDisciplineRef ref) {
  final id = ref.watch(selectedDisciplineStorageProvider).valueOrNull;
  return (id != null ? DisciplineRegistry.byId(id) : null) ??
      DisciplineRegistry.fallback;
}
