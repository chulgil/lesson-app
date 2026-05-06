import 'package:json_annotation/json_annotation.dart';

part 'manual_teacher.g.dart';

/// Profile color palette for manual teachers (Notebook × Score — ink-led).
const _profileColors = [
  0xff14161c,
  0xff9b1b12,
  0xff3f5d2f,
  0xfff7d755,
  0xffe74c3c,
  0xff1abc9c,
  0xff9b59b6,
  0xffe67e22,
];

/// Generate a profile color from the teacher's name.
int _profileColorValueFromName(String name) {
  if (name.isEmpty) return _profileColors[0];
  final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
  return _profileColors[hash % _profileColors.length];
}

/// Manually registered teacher (offline teacher not on the app).
@JsonSerializable()
class ManualTeacher {
  final String id;

  final String name;

  final String? instrument;

  final String? phone;

  final String? notes;

  final DateTime createdAt;

  final int profileColorValue;

  ManualTeacher({
    required this.id,
    required this.name,
    this.instrument,
    this.phone,
    this.notes,
    required this.createdAt,
    int? profileColorValue,
  }) : profileColorValue =
           profileColorValue ?? _profileColorValueFromName(name);

  /// First character of name for avatar display.
  String get initial => name.isNotEmpty ? name[0] : '?';

  factory ManualTeacher.fromJson(Map<String, dynamic> json) =>
      _$ManualTeacherFromJson(json);

  Map<String, dynamic> toJson() => _$ManualTeacherToJson(this);

  ManualTeacher copyWith({
    String? id,
    String? name,
    String? instrument,
    String? phone,
    String? notes,
    DateTime? createdAt,
    int? profileColorValue,
  }) {
    return ManualTeacher(
      id: id ?? this.id,
      name: name ?? this.name,
      instrument: instrument ?? this.instrument,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      profileColorValue: profileColorValue ?? this.profileColorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualTeacher &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
