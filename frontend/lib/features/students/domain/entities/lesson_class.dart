import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_class.g.dart';

/// Class type - academy or private lessons.
@HiveType(typeId: 50)
enum LessonClassType {
  @HiveField(0)
  academy, // Academy (institutional affiliation)

  @HiveField(1)
  private, // Private lessons
}

/// Payment type - who handles payment.
@HiveType(typeId: 51)
enum PaymentType {
  @HiveField(0)
  organization, // Institution (academy) handles payment, teacher receives salary

  @HiveField(1)
  parent, // Parent pays teacher directly
}

/// Class/group entity representing academy or private lesson groups.
@HiveType(typeId: 52)
@JsonSerializable()
class LessonClass extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId; // Owning teacher ID

  // Basic info
  @HiveField(2)
  final String name; // "ABC Music Academy", "Private Lessons", etc.

  @HiveField(3)
  final LessonClassType type; // academy | private

  @HiveField(4)
  final PaymentType paymentType; // organization | parent

  // Academy info (only when type == academy)
  @HiveField(5)
  final String? contactPerson; // Academy contact person name

  @HiveField(6)
  final String? contactPhone; // Academy contact phone

  @HiveField(7)
  final String? address; // Academy address

  // Settings
  @HiveField(8)
  final int sortOrder; // Display order

  @HiveField(9)
  final bool isArchived; // Archive status

  // Meta
  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  LessonClass({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.type,
    required this.paymentType,
    this.contactPerson,
    this.contactPhone,
    this.address,
    this.sortOrder = 0,
    this.isArchived = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory LessonClass.fromJson(Map<String, dynamic> json) =>
      _$LessonClassFromJson(json);

  Map<String, dynamic> toJson() => _$LessonClassToJson(this);

  /// Display icon based on class type — Notebook × Score: ASCII only, no emoji.
  String get icon => type == LessonClassType.academy ? '■' : '●';

  /// Display label for the class.
  String get displayLabel =>
      type == LessonClassType.academy ? name : '개인레슨';

  LessonClass copyWith({
    String? id,
    String? teacherId,
    String? name,
    LessonClassType? type,
    PaymentType? paymentType,
    String? contactPerson,
    String? contactPhone,
    String? address,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LessonClass(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      type: type ?? this.type,
      paymentType: paymentType ?? this.paymentType,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'LessonClass(id: $id, name: $name, type: $type)';
}
