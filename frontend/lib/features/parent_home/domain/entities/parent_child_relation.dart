// Parent-Child relation domain entity
// Moved from lib/features/parent_home/domain/entities/parent_child_relation.dart for Clean Architecture

/// Parent-Child relation status enum
/// Renamed to avoid conflict with RelationStatus in teacher_student_relation.dart
enum ParentChildRelationStatus {
  pending, // Awaiting confirmation
  active, // Active relationship
  inactive; // Deactivated

  String get label {
    switch (this) {
      case ParentChildRelationStatus.pending:
        return '대기';
      case ParentChildRelationStatus.active:
        return '활성';
      case ParentChildRelationStatus.inactive:
        return '해제';
    }
  }
}

/// Backward compatibility alias
typedef RelationStatus = ParentChildRelationStatus;

/// Parent-Child relation model
/// Represents the 1:N relationship between parent and children
/// Designed for future N:N expansion
class ParentChildRelation {
  final String id;
  final String parentId;
  final String studentId;
  final bool isPrimaryGuardian; // Main guardian for this child
  final bool isBillingTarget; // Receives payment requests
  final ParentChildRelationStatus status;
  final DateTime linkedAt;
  final DateTime? unlinkedAt;

  const ParentChildRelation({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.isPrimaryGuardian = true,
    this.isBillingTarget = true,
    this.status = ParentChildRelationStatus.pending,
    required this.linkedAt,
    this.unlinkedAt,
  });

  /// Check if relation is currently active
  bool get isActive => status == ParentChildRelationStatus.active;

  /// Copy with new values
  ParentChildRelation copyWith({
    String? id,
    String? parentId,
    String? studentId,
    bool? isPrimaryGuardian,
    bool? isBillingTarget,
    ParentChildRelationStatus? status,
    DateTime? linkedAt,
    DateTime? unlinkedAt,
  }) {
    return ParentChildRelation(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      studentId: studentId ?? this.studentId,
      isPrimaryGuardian: isPrimaryGuardian ?? this.isPrimaryGuardian,
      isBillingTarget: isBillingTarget ?? this.isBillingTarget,
      status: status ?? this.status,
      linkedAt: linkedAt ?? this.linkedAt,
      unlinkedAt: unlinkedAt ?? this.unlinkedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentChildRelation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Extended relation with parent and student info for UI display
class ParentChildRelationWithDetails {
  final ParentChildRelation relation;
  final String parentName;
  final String studentName;
  final String? parentPhone;
  final String? studentInstrument;

  const ParentChildRelationWithDetails({
    required this.relation,
    required this.parentName,
    required this.studentName,
    this.parentPhone,
    this.studentInstrument,
  });

  String get parentId => relation.parentId;
  String get studentId => relation.studentId;
  bool get isPrimaryGuardian => relation.isPrimaryGuardian;
  bool get isBillingTarget => relation.isBillingTarget;
}
