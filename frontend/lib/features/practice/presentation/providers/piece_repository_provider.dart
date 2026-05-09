import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../data/repositories/mock_piece_repository.dart';
import '../../domain/repositories/piece_repository.dart';

part 'piece_repository_provider.g.dart';

/// Piece repository provider - switches between Mock and Remote.
@Riverpod(keepAlive: true)
PieceRepository pieceRepository(PieceRepositoryRef ref) {
  return createLocalFallbackRepository<PieceRepository>(
    ref: ref,
    mock: MockPieceRepository.new,
    // No remote API yet — use empty mock to avoid dummy data
    fallback: () => MockPieceRepository(empty: true),
  );
}
