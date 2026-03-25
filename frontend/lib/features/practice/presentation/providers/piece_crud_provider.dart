import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/piece.dart';
import '../../../../repositories/piece_repository.dart';
import 'piece_repository_provider.dart';

/// All pieces provider (library)
final piecesProvider = FutureProvider<List<Piece>>((ref) async {
  final repository = ref.watch(pieceRepositoryProvider);
  return repository.getAllPieces();
});

/// Single piece provider
final pieceProvider =
    FutureProvider.family<Piece?, String>((ref, id) async {
  final repository = ref.watch(pieceRepositoryProvider);
  return repository.getPiece(id);
});

/// Search pieces provider
final pieceSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPiecesProvider = FutureProvider<List<Piece>>((ref) async {
  final query = ref.watch(pieceSearchQueryProvider);
  final repository = ref.watch(pieceRepositoryProvider);

  if (query.isEmpty) {
    return repository.getAllPieces();
  }
  return repository.searchPieces(query);
});

/// Student repertoire provider
final studentRepertoireProvider =
    FutureProvider.family<Repertoire, String>((ref, studentId) async {
  final repository = ref.watch(pieceRepositoryProvider);
  return repository.getStudentRepertoire(studentId);
});

/// Piece library notifier for CRUD operations
class PiecesNotifier extends AsyncNotifier<List<Piece>> {
  PieceRepository get _repository => ref.read(pieceRepositoryProvider);

  @override
  Future<List<Piece>> build() async {
    return _repository.getAllPieces();
  }

  Future<Piece> addPiece(Piece piece) async {
    state = const AsyncValue.loading();
    try {
      final newPiece = await _repository.createPiece(piece);
      state = await AsyncValue.guard(() => _repository.getAllPieces());
      return newPiece;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Piece> updatePiece(Piece piece) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updatePiece(piece);
      state = await AsyncValue.guard(() => _repository.getAllPieces());
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deletePiece(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePiece(id);
      state = await AsyncValue.guard(() => _repository.getAllPieces());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getAllPieces());
  }
}

final piecesNotifierProvider =
    AsyncNotifierProvider<PiecesNotifier, List<Piece>>(
  PiecesNotifier.new,
);

/// Student repertoire notifier
class StudentRepertoireNotifier
    extends FamilyAsyncNotifier<Repertoire, String> {
  PieceRepository get _repository => ref.read(pieceRepositoryProvider);

  @override
  Future<Repertoire> build(String studentId) async {
    return _repository.getStudentRepertoire(studentId);
  }

  Future<void> assignPiece(String pieceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignPieceToStudent(pieceId, arg);
      state = await AsyncValue.guard(
          () => _repository.getStudentRepertoire(arg));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removePiece(String pieceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removePieceFromStudent(pieceId, arg);
      state = await AsyncValue.guard(
          () => _repository.getStudentRepertoire(arg));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(String pieceId, PieceProgress progress) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePieceProgress(pieceId, arg, progress);
      state = await AsyncValue.guard(
          () => _repository.getStudentRepertoire(arg));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _repository.getStudentRepertoire(arg));
  }
}

final studentRepertoireNotifierProvider = AsyncNotifierProvider.family<
    StudentRepertoireNotifier, Repertoire, String>(
  StudentRepertoireNotifier.new,
);
