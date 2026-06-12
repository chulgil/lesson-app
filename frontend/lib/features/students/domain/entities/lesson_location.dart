import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/json_converters.dart';

part 'lesson_location.g.dart';

/// Lesson location type.
enum LocationType {
  academyRoom, // Academy lesson room

  teacherStudio, // Teacher's studio

  studentHome, // Student's home (visiting)

  externalPlace, // External place (rental studio, etc.)

  online, // Online
}

/// Lesson location entity.
@JsonSerializable()
class LessonLocation {
  final String id;

  final String name; // "Lesson Room 1", "Home Studio"

  final LocationType type;

  final String? lessonClassId; // Class ID (for academy rooms)

  final String? ownerId; // Owner (teacher ID)

  // Address info
  final String? address; // Full address

  final String? addressDetail; // Detail address (floor/room)

  // Coordinates (for map integration)
  final double? latitude;

  final double? longitude;

  // Online info
  final String? onlinePlatform; // "zoom", "google_meet", "facetime"

  final String? onlineLink; // Meeting link (optional)

  // Meta
  final String? notes; // Directions, parking info, etc.

  final bool isDefault; // Default location flag

  final bool isActive; // Active status

  // #706 — BE created_at 이 None 가능 (strict DateTime.parse 방지).
  @JsonKey(fromJson: dateTimeFromJsonOrNow)
  final DateTime createdAt;

  final DateTime? updatedAt;

  LessonLocation({
    required this.id,
    required this.name,
    required this.type,
    this.lessonClassId,
    this.ownerId,
    this.address,
    this.addressDetail,
    this.latitude,
    this.longitude,
    this.onlinePlatform,
    this.onlineLink,
    this.notes,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory LessonLocation.fromJson(Map<String, dynamic> json) =>
      _$LessonLocationFromJson(json);

  Map<String, dynamic> toJson() => _$LessonLocationToJson(this);

  /// Check if location has coordinates for map.
  bool get hasCoordinates => latitude != null && longitude != null;

  LessonLocation copyWith({
    String? id,
    String? name,
    LocationType? type,
    String? lessonClassId,
    String? ownerId,
    String? address,
    String? addressDetail,
    double? latitude,
    double? longitude,
    String? onlinePlatform,
    String? onlineLink,
    String? notes,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lessonClassId: lessonClassId ?? this.lessonClassId,
      ownerId: ownerId ?? this.ownerId,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      onlinePlatform: onlinePlatform ?? this.onlinePlatform,
      onlineLink: onlineLink ?? this.onlineLink,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'LessonLocation(id: $id, name: $name, type: $type)';
}
