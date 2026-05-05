import '../entities/piece.dart';

/// Repository interface for piece/repertoire management
abstract class PieceRepository {
  // Library management
  Future<List<Piece>> getAllPieces();
  Future<Piece?> getPiece(String id);
  Future<Piece> createPiece(Piece piece);
  Future<Piece> updatePiece(Piece piece);
  Future<void> deletePiece(String id);
  Future<List<Piece>> searchPieces(String query);

  // Student repertoire
  Future<Repertoire> getStudentRepertoire(String studentId);
  Future<void> assignPieceToStudent(String pieceId, String studentId);
  Future<void> removePieceFromStudent(String pieceId, String studentId);
  Future<void> updatePieceProgress(
    String pieceId,
    String studentId,
    PieceProgress progress,
  );
}
