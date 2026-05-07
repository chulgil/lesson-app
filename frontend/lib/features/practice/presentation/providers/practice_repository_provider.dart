import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_practice_repository.dart';
import '../../data/repositories/remote_practice_repository.dart';
import '../../domain/repositories/practice_repository.dart';

part 'practice_repository_provider.g.dart';

/// Practice repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
PracticeRepository practiceRepository(PracticeRepositoryRef ref) {
  return createRepository<PracticeRepository>(
    ref: ref,
    mock: () => MockPracticeRepository(),
    remote: (api) => RemotePracticeRepository(api),
  );
}
