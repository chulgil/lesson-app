/// Activity log entry for academy operations (teacher's view).
///
/// Spec: docs/specs/web/academy/academy_schedule_authority_spec.md §2.4.
///
/// 학원장이 사후 가시성으로 강사 액션을 확인 (3차 무조건 위임 모델).
/// actor_name 직접 저장 — 강사 이름 변경/퇴직 후에도 audit 보존.
class AcademyActivityLog {
  const AcademyActivityLog({
    required this.id,
    required this.academyId,
    required this.actorMemberId,
    required this.actorName,
    required this.actionType,
    required this.description,
    required this.createdAt,
    this.targetResourceType,
    this.targetResourceId,
    this.metadata,
  });

  final String id;
  final String academyId;
  final String actorMemberId;
  final String actorName;
  final String actionType;
  final String description;
  final DateTime createdAt;

  /// 타깃 리소스 종류 (예: "lesson", "subscription", "student"). nullable.
  final String? targetResourceType;

  /// 타깃 리소스 id (예: lesson_id, subscription_id). nullable.
  final String? targetResourceId;

  /// 추가 메타데이터 (변경 전/후 값 등 추가 컨텍스트). nullable.
  /// BE 의 metadata_json (DB 컬럼명 "metadata") 와 1:1.
  final Map<String, dynamic>? metadata;

  AcademyActivityLog copyWith({
    String? id,
    String? academyId,
    String? actorMemberId,
    String? actorName,
    String? actionType,
    String? description,
    DateTime? createdAt,
    String? targetResourceType,
    String? targetResourceId,
    Map<String, dynamic>? metadata,
  }) {
    return AcademyActivityLog(
      id: id ?? this.id,
      academyId: academyId ?? this.academyId,
      actorMemberId: actorMemberId ?? this.actorMemberId,
      actorName: actorName ?? this.actorName,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      targetResourceType: targetResourceType ?? this.targetResourceType,
      targetResourceId: targetResourceId ?? this.targetResourceId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AcademyActivityLog) return false;
    if (!_mapEquals(metadata, other.metadata)) return false;
    return id == other.id &&
        academyId == other.academyId &&
        actorMemberId == other.actorMemberId &&
        actorName == other.actorName &&
        actionType == other.actionType &&
        description == other.description &&
        createdAt == other.createdAt &&
        targetResourceType == other.targetResourceType &&
        targetResourceId == other.targetResourceId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    academyId,
    actorMemberId,
    actorName,
    actionType,
    description,
    createdAt,
    targetResourceType,
    targetResourceId,
    // metadata 는 Map identity 가 hash 에 들어가면 안 됨 — key 개수만.
    metadata?.length ?? 0,
  );

  static bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
