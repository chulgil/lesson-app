import 'package:json_annotation/json_annotation.dart';

part 'guardian_seal.g.dart';

@JsonSerializable()
class GuardianSeal {
  final DateTime weekStart;
  final String guardianUserId;
  final String? cheerNote;

  const GuardianSeal({
    required this.weekStart,
    required this.guardianUserId,
    this.cheerNote,
  });

  GuardianSeal copyWith({
    DateTime? weekStart,
    String? guardianUserId,
    String? cheerNote,
  }) => GuardianSeal(
    weekStart: weekStart ?? this.weekStart,
    guardianUserId: guardianUserId ?? this.guardianUserId,
    cheerNote: cheerNote ?? this.cheerNote,
  );

  factory GuardianSeal.fromJson(Map<String, dynamic> json) =>
      _$GuardianSealFromJson(json);
  Map<String, dynamic> toJson() => _$GuardianSealToJson(this);
}
