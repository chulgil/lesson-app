import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../domain/repositories/parent_repository.dart';
import '../../data/repositories/remote_parent_repository.dart';

/// Parent repository provider - switches between Mock and Remote.
final parentRepositoryProvider = Provider<ParentRepository>((ref) =>
    createRepository<ParentRepository>(
      ref: ref,
      mock: () => MockParentRepository(),
      remote: (api) => RemoteParentRepository(api),
    ));
