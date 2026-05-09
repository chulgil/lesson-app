import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_practice_repository.dart';
import '../../data/repositories/remote_practice_repository.dart';
import '../../data/repositories/sync_aware_practice_repository.dart';
import '../../domain/repositories/practice_repository.dart';

part 'practice_repository_provider.g.dart';

/// Practice repository provider - switches between Mock and SyncAware (Remote + Queue).
@Riverpod(keepAlive: true)
PracticeRepository practiceRepository(PracticeRepositoryRef ref) {
  return createSyncAwareRepository<PracticeRepository>(
    ref: ref,
    mock: () => MockPracticeRepository(),
    syncAware: (api, queue) => SyncAwarePracticeRepository(
      remote: RemotePracticeRepository(api),
      queue: queue,
    ),
  );
}
