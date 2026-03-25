// Piece domain entities
// Moved from lib/features/practice/domain/entities/piece.dart for Clean Architecture

/// Progress status for a piece
enum PieceProgress {
  notStarted,
  inProgress,
  polishing,
  completed;

  String get label {
    switch (this) {
      case PieceProgress.notStarted:
        return '시작 전';
      case PieceProgress.inProgress:
        return '진행중';
      case PieceProgress.polishing:
        return '마무리';
      case PieceProgress.completed:
        return '완료';
    }
  }

  double get progressValue {
    switch (this) {
      case PieceProgress.notStarted:
        return 0.0;
      case PieceProgress.inProgress:
        return 0.4;
      case PieceProgress.polishing:
        return 0.8;
      case PieceProgress.completed:
        return 1.0;
    }
  }
}

/// Piece (repertoire) model
class Piece {
  final String id;
  final String title;
  final String? composer;
  final String? opus;
  final String? movement;
  final String? difficulty;
  final PieceProgress progress;
  final double progressPercentage; // 0.0 to 1.0
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Piece({
    required this.id,
    required this.title,
    this.composer,
    this.opus,
    this.movement,
    this.difficulty,
    this.progress = PieceProgress.notStarted,
    this.progressPercentage = 0.0,
    this.notes,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get full title with composer
  String get fullTitle {
    if (composer != null) {
      return '$title - $composer';
    }
    return title;
  }

  /// Get display name with movement
  String get displayName {
    final parts = <String>[title];
    if (opus != null) parts.add(opus!);
    if (movement != null) parts.add(movement!);
    return parts.join(' ');
  }

  Piece copyWith({
    String? id,
    String? title,
    String? composer,
    String? opus,
    String? movement,
    String? difficulty,
    PieceProgress? progress,
    double? progressPercentage,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Piece(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      opus: opus ?? this.opus,
      movement: movement ?? this.movement,
      difficulty: difficulty ?? this.difficulty,
      progress: progress ?? this.progress,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Student's repertoire (collection of pieces)
class Repertoire {
  final String studentId;
  final List<Piece> currentPieces;
  final List<Piece> completedPieces;

  const Repertoire({
    required this.studentId,
    this.currentPieces = const [],
    this.completedPieces = const [],
  });

  /// Get total piece count
  int get totalPieces => currentPieces.length + completedPieces.length;

  /// Get pieces in progress
  List<Piece> get inProgressPieces => currentPieces
      .where((p) => p.progress == PieceProgress.inProgress)
      .toList();

  Repertoire copyWith({
    String? studentId,
    List<Piece>? currentPieces,
    List<Piece>? completedPieces,
  }) {
    return Repertoire(
      studentId: studentId ?? this.studentId,
      currentPieces: currentPieces ?? this.currentPieces,
      completedPieces: completedPieces ?? this.completedPieces,
    );
  }
}
