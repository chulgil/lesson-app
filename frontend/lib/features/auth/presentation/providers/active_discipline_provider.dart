import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/domain/value_objects/discipline.dart';
import '../../../../core/domain/value_objects/discipline_registry.dart';
import 'user_role_provider.dart';

part 'active_discipline_provider.g.dart';

const _boxName = 'selected_discipline';

/// Persists the coaching discipline the user chose at sign-up (#979-A, Phase 4).
///
/// User-scoped (mirrors `OnboardingProgressStorage`): the Hive key carries the
/// current user id, so choices never cross-contaminate between accounts.
/// Dormant since #1278 (음악 단일 포커스): with one registered discipline the
/// selection screen is skipped at sign-up, so nothing is normally stored.
/// Before a pick (or for legacy sessions) [build] returns null and
/// [activeDiscipline] falls back to music.
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
/// (including while the async storage is still loading). Resolves to music
/// today (#1278); it is the seam the practice tools modal reads to
/// pick a discipline's tool set.
@riverpod
Discipline activeDiscipline(ActiveDisciplineRef ref) {
  final id = ref.watch(selectedDisciplineStorageProvider).valueOrNull;
  return (id != null ? DisciplineRegistry.byId(id) : null) ??
      DisciplineRegistry.fallback;
}

/// Disciplines shown in the sign-up selection UI (#1196).
///
/// Remote/production builds expose only production-ready verticals (music
/// today) so users never land on an unfinished discipline's home. Mock/dev
/// builds — and widget tests, which default to mock — still see every
/// registered discipline so the multi-Discipline path (#979-B/#1102) stays
/// exercisable. [useMock] defaults to [EnvironmentConfig.useMockData]; pass
/// it explicitly in tests to exercise the gated (production) branch.
List<Discipline> selectableDisciplines({bool? useMock}) {
  final mock = useMock ?? EnvironmentConfig.useMockData;
  return mock ? DisciplineRegistry.all : DisciplineRegistry.productionReady;
}
