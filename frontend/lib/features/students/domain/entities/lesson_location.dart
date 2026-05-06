import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_location.g.dart';

/// Lesson location type.
@HiveType(typeId: 58)
enum LocationType {
  @HiveField(0)
  academyRoom, // Academy lesson room

  @HiveField(1)
  teacherStudio, // Teacher's studio

  @HiveField(2)
  studentHome, // Student's home (visiting)

  @HiveField(3)
  externalPlace, // External place (rental studio, etc.)

  @HiveField(4)
  online, // Online
}

/// Lesson location entity.
@HiveType(typeId: 59)
@JsonSerializable()
class LessonLocation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // "Lesson Room 1", "Home Studio"

  @HiveField(2)
  final LocationType type;

  @HiveField(3)
  final String? lessonClassId; // Class ID (for academy rooms)

  @HiveField(4)
  final String? ownerId; // Owner (teacher ID)

  // Address info
  @HiveField(5)
  final String? address; // Full address

  @HiveField(6)
  final String? addressDetail; // Detail address (floor/room)

  // Coordinates (for map integration)
  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  // Online info
  @HiveField(9)
  final String? onlinePlatform; // "zoom", "google_meet", "facetime"

  @HiveField(10)
  final String? onlineLink; // Meeting link (optional)

  // Meta
  @HiveField(11)
  final String? notes; // Directions, parking info, etc.

  @HiveField(12)
  final bool isDefault; // Default location flag

  @HiveField(13)
  final bool isActive; // Active status

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
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
