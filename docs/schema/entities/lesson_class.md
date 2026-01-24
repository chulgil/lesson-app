# LessonClass 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [student_class_system.md](../../specs/student/student_class_system.md)

## 개요

학원 또는 개인레슨 그룹을 나타내는 엔티티입니다.
선생님은 여러 LessonClass를 소유할 수 있습니다.

---

## Dart 엔티티

```dart
// lib/features/students/domain/entities/lesson_class.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_class.g.dart';

/// 클래스 유형
@HiveType(typeId: 50)
enum LessonClassType {
  @HiveField(0)
  academy,   // 학원 (기관 소속)

  @HiveField(1)
  private,   // 개인레슨
}

/// 결제 유형
@HiveType(typeId: 51)
enum PaymentType {
  @HiveField(0)
  organization,  // 기관(학원)에서 일괄 결제 → 선생님은 급여

  @HiveField(1)
  parent,        // 학부모가 선생님에게 직접 결제
}

/// 클래스/소속 그룹
@HiveType(typeId: 52)
@JsonSerializable()
class LessonClass {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String teacherId;        // 소유 선생님 ID

  // 기본 정보
  @HiveField(2)
  final String name;             // "○○음악학원", "개인레슨" 등

  @HiveField(3)
  final LessonClassType type;    // academy | private

  @HiveField(4)
  final PaymentType paymentType; // organization | parent

  // 학원 정보 (type == academy인 경우)
  @HiveField(5)
  final String? contactPerson;   // 학원 담당자 이름

  @HiveField(6)
  final String? contactPhone;    // 학원 연락처

  @HiveField(7)
  final String? address;         // 학원 주소

  // 설정
  @HiveField(8)
  final int sortOrder;           // 표시 순서

  @HiveField(9)
  final bool isArchived;         // 보관 여부

  // 메타
  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? updatedAt;

  const LessonClass({
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
}
```

---

## 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `teacherId` | String | ✅ | 소유 선생님 ID |
| `name` | String | ✅ | 클래스명 ("○○음악학원", "개인레슨" 등) |
| `type` | LessonClassType | ✅ | academy, private |
| `paymentType` | PaymentType | ✅ | organization, parent |
| `contactPerson` | String? | - | 학원 담당자명 (academy만) |
| `contactPhone` | String? | - | 학원 연락처 (academy만) |
| `address` | String? | - | 학원 주소 (academy만) |
| `sortOrder` | int | ✅ | 정렬 순서 (기본값: 0) |
| `isArchived` | bool | ✅ | 보관 여부 (기본값: false) |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

---

## JSON 예시

```json
{
  "id": "lc_001",
  "teacherId": "teacher_001",
  "name": "○○음악학원",
  "type": "academy",
  "paymentType": "organization",
  "contactPerson": "홍길동",
  "contactPhone": "02-1234-5678",
  "address": "서울시 강남구 테헤란로 123",
  "sortOrder": 0,
  "isArchived": false,
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

---

## Repository 인터페이스

```dart
// lib/features/students/domain/repositories/lesson_class_repository.dart

abstract class LessonClassRepository {
  /// 선생님의 모든 클래스 조회
  Future<List<LessonClass>> getByTeacherId(String teacherId);

  /// 클래스 생성
  Future<LessonClass> create(LessonClass lessonClass);

  /// 클래스 수정
  Future<LessonClass> update(LessonClass lessonClass);

  /// 클래스 보관 (소프트 삭제)
  Future<void> archive(String id);

  /// 정렬 순서 변경
  Future<void> reorder(List<String> orderedIds);
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| LessonClassType | 50 |
| PaymentType | 51 |
| LessonClass | 52 |

---

## 관련 엔티티

- [ClassMembership](class_membership.md) - 학생-클래스 소속 관계
- [LessonLocation](lesson_location.md) - 클래스에 연결된 레슨 장소
