import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/auth_facade.dart';
import '../../data/repositories/local_vocab_repository.dart';
import '../../domain/repositories/vocab_repository.dart';

part 'vocab_repository_provider.g.dart';

/// The vocabulary persistence layer for the logged-in user (#1124).
///
/// Local-first Hive (no backend yet). Watches [currentUserIdProvider] through the
/// auth facade (cross-feature = facade), so switching accounts rebuilds the repo
/// with a fresh user-scoped key and cascades every dependent provider.
@Riverpod(keepAlive: true)
VocabRepository vocabRepository(VocabRepositoryRef ref) =>
    LocalVocabRepository(ref.watch(currentUserIdProvider));
