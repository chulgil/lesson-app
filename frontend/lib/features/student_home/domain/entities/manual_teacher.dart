import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/theme/app_colors.dart';

part 'manual_teacher.g.dart';

/// Profile color palette for manual teachers (Notebook × Score — ink-led).
const _profileColors = [
  AppColors.ink,
  AppColors.paperAccent,
  AppColors.paperOk,
  AppColors.paperHighlight,
  AppColors.profileRed,
  AppColors.profileTeal,
  AppColors.profilePurple,
  AppColors.profileOrange,
];

/// Generate a profile color from the teacher's name.
Color _profileColorFromName(String name) {
  if (name.isEmpty) return _profileColors[0];
  final hash = name.codeUnits.fold(0, (sum, c) => sum + c);
  return _profileColors[hash % _profileColors.length];
}

/// Manually registered teacher (offline teacher not on the app).
@HiveType(typeId: 110)
@JsonSerializable()
class ManualTeacher extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? instrument;

  @HiveField(3)
  final String? phone;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
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
           profileColorValue ?? _profileColorFromName(name).toARGB32();

  /// Profile color derived from stored int value.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Color get profileColor => Color(profileColorValue);

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
