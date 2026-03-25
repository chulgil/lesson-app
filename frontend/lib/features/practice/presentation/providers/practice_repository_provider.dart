import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_practice_repository.dart';
import '../../data/repositories/remote_practice_repository.dart';
import '../../domain/repositories/practice_repository.dart';

/// Practice repository provider - switches between Mock and Remote.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) =>
    createRepository<PracticeRepository>(
      ref: ref,
      mock: () => MockPracticeRepository(),
      remote: (api) => RemotePracticeRepository(api),
    ));
