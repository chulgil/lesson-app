/// Activity log entry for academy operations (teacher's view)
class AcademyActivityLog {
  const AcademyActivityLog({
    required this.id,
    required this.academyId,
    required this.actorMemberId,
    required this.actorName,
    required this.actionType,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String academyId;
  final String actorMemberId;
  final String actorName;
  final String actionType;
  final String description;
  final DateTime createdAt;

  AcademyActivityLog copyWith({
    String? id,
    String? academyId,
    String? actorMemberId,
    String? actorName,
    String? actionType,
    String? description,
    DateTime? createdAt,
  }) {
    return AcademyActivityLog(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      actorMemberId: actorMemberId ?? this.actorMemberId,
      actorName: actorName ?? this.actorName,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
