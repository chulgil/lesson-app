import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/piece.dart';
import '../../domain/repositories/piece_repository.dart';
import 'piece_repository_provider.dart';

part 'piece_crud_provider.g.dart';

/// All pieces provider (library)
@Riverpod(keepAlive: true)
Future<List<Piece>> pieces(PiecesRef ref) async {
  final repository = ref.watch(pieceRepositoryProvider);
  return repository.getAllPieces();
}

/// Single piece provider
@Riverpod(keepAlive: true)
Future<Piece?> piece(PieceRef ref, String id) async {
  final repository = ref.watch(pieceRepositoryProvider);
  return repository.getPiece(id);
}

/// Search pieces provider
@Riverpod(keepAlive: true)
class PieceSearchQuery extends _$PieceSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@Riverpod(keepAlive: true)
Future<List<Piece>> filteredPieces(FilteredPiecesRef ref) async {
  final query = ref.watch(pieceSearchQueryProvider);
  final repository = ref.watch(pieceRepositoryProvider);

  if (query.isEmpty) {
    return repository.getAllPieces();
  }
  return repository.searchPieces(query);
}

/// Student repertoire provider
@Riverpod(keepAlive: true)
Future<Repertoire> studentRepertoire(
  StudentRepertoireRef ref,
  String studentId,
) async {
  final repository = ref.watch(pieceRepositoryProvider);
  return repository.getStudentRepertoire(studentId);
}

/// Piece library notifier for CRUD operations
@Riverpod(keepAlive: true)
class PiecesNotifier extends _$PiecesNotifier {
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

/// Student repertoire notifier
@Riverpod(keepAlive: true)
class StudentRepertoireNotifier extends _$StudentRepertoireNotifier {
  PieceRepository get _repository => ref.read(pieceRepositoryProvider);

  @override
  Future<Repertoire> build(String studentId) async {
    return _repository.getStudentRepertoire(studentId);
  }

  Future<void> assignPiece(String pieceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignPieceToStudent(pieceId, studentId);
      state = await AsyncValue.guard(
        () => _repository.getStudentRepertoire(studentId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removePiece(String pieceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removePieceFromStudent(pieceId, studentId);
      state = await AsyncValue.guard(
        () => _repository.getStudentRepertoire(studentId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProgress(String pieceId, PieceProgress progress) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePieceProgress(pieceId, studentId, progress);
      state = await AsyncValue.guard(
        () => _repository.getStudentRepertoire(studentId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getStudentRepertoire(studentId),
    );
  }
}
