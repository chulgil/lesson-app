import 'package:json_annotation/json_annotation.dart';

part 'endorsement.g.dart';

enum EndorsedBy { self, teacher }

@JsonSerializable()
class Endorsement {
  final EndorsedBy by;
  final DateTime date;
  final String authorUserId;

  /// teacher 검인은 반드시 과제 참조를 가진다(과제 한정). self 회고는 null.
  final String? assignmentRef;
  final String note;

  const Endorsement({
    required this.by,
    required this.date,
    required this.authorUserId,
    this.assignmentRef,
    required this.note,
  });

  /// teacher ⇒ assignmentRef 필수, self ⇒ assignmentRef 없음.
  bool get isValid =>
      by == EndorsedBy.teacher ? assignmentRef != null : assignmentRef == null;

  Endorsement copyWith({
    EndorsedBy? by,
    DateTime? date,
    String? authorUserId,
    String? assignmentRef,
    String? note,
    bool clearAssignment = false,
  }) => Endorsement(
    by: by ?? this.by,
    date: date ?? this.date,
    authorUserId: authorUserId ?? this.authorUserId,
    assignmentRef:
        clearAssignment ? null : (assignmentRef ?? this.assignmentRef),
    note: note ?? this.note,
  );

  factory Endorsement.fromJson(Map<String, dynamic> json) =>
      _$EndorsementFromJson(json);
  Map<String, dynamic> toJson() => _$EndorsementToJson(this);
}
