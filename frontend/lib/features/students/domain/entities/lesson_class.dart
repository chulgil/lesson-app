import 'package:json_annotation/json_annotation.dart';

part 'lesson_class.g.dart';

/// Class type - academy or private lessons.
enum LessonClassType {
  academy, // Academy (institutional affiliation)

  private, // Private lessons
}

/// Payment type - who handles payment.
enum PaymentType {
  organization, // Institution (academy) handles payment, teacher receives salary

  parent, // Parent pays teacher directly
}

/// Class/group entity representing academy or private lesson groups.
@JsonSerializable()
class LessonClass {
  final String id;

  final String teacherId; // Owning teacher ID

  // Basic info
  final String name; // "ABC Music Academy", "Private Lessons", etc.

  final LessonClassType type; // academy | private

  final PaymentType paymentType; // organization | parent

  // Academy info (only when type == academy)
  final String? contactPerson; // Academy contact person name

  final String? contactPhone; // Academy contact phone

  final String? address; // Academy address

  // Settings
  final int sortOrder; // Display order

  final bool isArchived; // Archive status

  // Meta
  final DateTime createdAt;

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
