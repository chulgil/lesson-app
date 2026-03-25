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

/// Mock implementation of PieceRepository
class MockPieceRepository implements PieceRepository {
  MockPieceRepository({bool empty = false}) {
    if (empty) {
      _pieces.clear();
      _studentPieces.clear();
    }
  }

  final List<Piece> _pieces = [
    Piece(
      id: 'piece_1',
      title: 'Violin Concerto in E minor',
      composer: 'Mendelssohn',
      opus: 'Op. 64',
      difficulty: '상급',
      progress: PieceProgress.notStarted,
      progressPercentage: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Piece(
      id: 'piece_2',
      title: 'Violin Sonata No. 5',
      composer: 'Beethoven',
      opus: 'Op. 24',
      movement: '1악장',
      difficulty: '중급',
      progress: PieceProgress.inProgress,
      progressPercentage: 60,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    Piece(
      id: 'piece_3',
      title: 'Violin Concerto in D major',
      composer: 'Brahms',
      opus: 'Op. 77',
      difficulty: '상급',
      progress: PieceProgress.notStarted,
      progressPercentage: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Piece(
      id: 'piece_4',
      title: 'Czardas',
      composer: 'Monti',
      difficulty: '중급',
      progress: PieceProgress.completed,
      progressPercentage: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      completedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Piece(
      id: 'piece_5',
      title: 'Meditation from Thais',
      composer: 'Massenet',
      difficulty: '중급',
      progress: PieceProgress.polishing,
      progressPercentage: 85,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Piece(
      id: 'piece_6',
      title: 'Canon in D',
      composer: 'Pachelbel',
      difficulty: '초급',
      progress: PieceProgress.completed,
      progressPercentage: 100,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      completedAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
    Piece(
      id: 'piece_7',
      title: 'Introduction and Rondo Capriccioso',
      composer: 'Saint-Saëns',
      opus: 'Op. 28',
      difficulty: '상급',
      progress: PieceProgress.notStarted,
      progressPercentage: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Piece(
      id: 'piece_8',
      title: 'Zigeunerweisen',
      composer: 'Sarasate',
      opus: 'Op. 20',
      difficulty: '상급',
      progress: PieceProgress.inProgress,
      progressPercentage: 30,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  // Student-Piece assignments (studentId -> List<pieceId>)
  final Map<String, List<String>> _studentPieces = {
    'student_1': ['piece_1', 'piece_2', 'piece_5'],
    'student_2': ['piece_3', 'piece_4'],
    'student_3': ['piece_6', 'piece_7', 'piece_8'],
  };

  @override
  Future<List<Piece>> getAllPieces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_pieces);
  }

  @override
  Future<Piece?> getPiece(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _pieces.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Piece> createPiece(Piece piece) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newPiece = Piece(
      id: 'piece_${DateTime.now().millisecondsSinceEpoch}',
      title: piece.title,
      composer: piece.composer,
      opus: piece.opus,
      movement: piece.movement,
      difficulty: piece.difficulty,
      progress: piece.progress,
      progressPercentage: piece.progressPercentage,
      notes: piece.notes,
      createdAt: DateTime.now(),
    );
    _pieces.add(newPiece);
    return newPiece;
  }

  @override
  Future<Piece> updatePiece(Piece piece) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _pieces.indexWhere((p) => p.id == piece.id);
    if (index != -1) {
      final updated = Piece(
        id: piece.id,
        title: piece.title,
        composer: piece.composer,
        opus: piece.opus,
        movement: piece.movement,
        difficulty: piece.difficulty,
        progress: piece.progress,
        progressPercentage: piece.progressPercentage,
        notes: piece.notes,
        startedAt: piece.startedAt,
        completedAt: piece.completedAt,
        createdAt: piece.createdAt,
        updatedAt: DateTime.now(),
      );
      _pieces[index] = updated;
      return updated;
    }
    throw Exception('Piece not found');
  }

  @override
  Future<void> deletePiece(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _pieces.removeWhere((p) => p.id == id);
    // Remove from all student assignments
    for (final entry in _studentPieces.entries) {
      entry.value.remove(id);
    }
  }

  @override
  Future<List<Piece>> searchPieces(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final lowercaseQuery = query.toLowerCase();
    return _pieces.where((p) {
      return p.title.toLowerCase().contains(lowercaseQuery) ||
          (p.composer?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  @override
  Future<Repertoire> getStudentRepertoire(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final pieceIds = _studentPieces[studentId] ?? [];
    final studentPieces =
        _pieces.where((p) => pieceIds.contains(p.id)).toList();

    final currentPieces =
        studentPieces
            .where((p) => p.progress != PieceProgress.completed)
            .toList();
    final completedPieces =
        studentPieces
            .where((p) => p.progress == PieceProgress.completed)
            .toList();

    return Repertoire(
      studentId: studentId,
      currentPieces: currentPieces,
      completedPieces: completedPieces,
    );
  }

  @override
  Future<void> assignPieceToStudent(String pieceId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_studentPieces.containsKey(studentId)) {
      _studentPieces[studentId] = [];
    }
    if (!_studentPieces[studentId]!.contains(pieceId)) {
      _studentPieces[studentId]!.add(pieceId);
    }
  }

  @override
  Future<void> removePieceFromStudent(String pieceId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _studentPieces[studentId]?.remove(pieceId);
  }

  @override
  Future<void> updatePieceProgress(
    String pieceId,
    String studentId,
    PieceProgress progress,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _pieces.indexWhere((p) => p.id == pieceId);
    if (index != -1) {
      final piece = _pieces[index];
      double percentage;
      DateTime? completedAt;

      switch (progress) {
        case PieceProgress.notStarted:
          percentage = 0;
          break;
        case PieceProgress.inProgress:
          percentage =
              piece.progressPercentage > 0 ? piece.progressPercentage : 25;
          break;
        case PieceProgress.polishing:
          percentage =
              piece.progressPercentage > 75 ? piece.progressPercentage : 75;
          break;
        case PieceProgress.completed:
          percentage = 100;
          completedAt = DateTime.now();
          break;
      }

      _pieces[index] = Piece(
        id: piece.id,
        title: piece.title,
        composer: piece.composer,
        opus: piece.opus,
        movement: piece.movement,
        difficulty: piece.difficulty,
        progress: progress,
        progressPercentage: percentage,
        notes: piece.notes,
        startedAt: piece.startedAt ?? DateTime.now(),
        completedAt: completedAt,
        createdAt: piece.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }
}
