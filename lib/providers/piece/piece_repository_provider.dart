import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/piece_repository.dart';

/// Piece repository provider
final pieceRepositoryProvider = Provider<PieceRepository>((ref) {
  return MockPieceRepository();
});
