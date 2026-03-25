import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../domain/repositories/piece_repository.dart';

/// Piece repository provider - switches between Mock and Remote.
final pieceRepositoryProvider = Provider<PieceRepository>((ref) {
  if (EnvironmentConfig.useMockData) {
    return MockPieceRepository();
  }
  // No remote API yet — use empty mock to avoid dummy data
  return MockPieceRepository(empty: true);
});
