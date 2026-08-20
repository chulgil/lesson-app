// Cohort roster row of a group class (spec §2 P2-4)

import 'package:json_annotation/json_annotation.dart';

part 'group_class_member.g.dart';

/// One student on a regular class's fixed roster.
///
/// Drop-in classes have no roster — they are booked per session, so a member
/// row only ever points at a [GroupClassType.regular] class.
@JsonSerializable()
class GroupClassMember {
  final String id;

  final String groupClassId;

  final String studentId;

  /// Display name the backend joins in from the student row. Null on responses
  /// that skip the join, so screens keep a local fallback.
  final String? studentName;

  final DateTime createdAt;

  const GroupClassMember({
    required this.id,
    required this.groupClassId,
    required this.studentId,
    this.studentName,
    required this.createdAt,
  });

  factory GroupClassMember.fromJson(Map<String, dynamic> json) =>
      _$GroupClassMemberFromJson(json);

  Map<String, dynamic> toJson() => _$GroupClassMemberToJson(this);
}
