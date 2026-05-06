import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_parent_repository.dart';
import '../../data/repositories/remote_parent_repository.dart';
import '../../domain/repositories/parent_repository.dart';

part 'parent_repository_provider.g.dart';

/// Parent repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
ParentRepository parentRepository(ParentRepositoryRef ref) =>
    createRepository<ParentRepository>(
      ref: ref,
      mock: () => MockParentRepository(),
      remote: (api) => RemoteParentRepository(api),
    );
