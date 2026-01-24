# Student 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [student_class_system.md](../../specs/student/student_class_system.md)

## 개요

학생(플랫폼 사용자)의 **기본 정보만** 포함합니다.
레슨 정보, 수강료 등은 [ClassMembership](class_membership.md)으로 분리되었습니다.

---

## Dart 엔티티

```dart
// lib/features/students/domain/entities/student.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

/// 앱 연결 상태
@HiveType(typeId: 60)
enum ConnectionStatus {
  @HiveField(0)
  offline,     // 미연결 (초대 전)

  @HiveField(1)
  inviteSent,  // 초대 발송됨

  @HiveField(2)
  connected,   // 연결됨
}

/// 연령 그룹
@HiveType(typeId: 61)
enum AgeGroup {
  @HiveField(0)
  child,       // 미취학/초등 (만 12세 이하)

  @HiveField(1)
  student,     // 중고등 (만 13-18세)

  @HiveField(2)
  adult,       // 성인 (만 19세 이상)

  /// 생년월일로 연령 그룹 계산
  static AgeGroup? fromBirthDate(DateTime? birthDate) {
    if (birthDate == null) return null;
    final age = DateTime.now().year - birthDate.year;
    if (age <= 12) return AgeGroup.child;
    if (age <= 18) return AgeGroup.student;
    return AgeGroup.adult;
  }
}

/// 학생 (플랫폼 사용자)
@HiveType(typeId: 62)
@JsonSerializable()
class Student {
  @HiveField(0)
  final String id;

  // 기본 정보
  @HiveField(1)
  final String name;

  @HiveField(2)
  final Color profileColor;

  @HiveField(3)
  final String? profileImageUrl;

  // 연락처 (개인레슨용, 학원 학생은 비워둘 수 있음)
  @HiveField(4)
  final String? phone;           // 학생 본인 연락처

  @HiveField(5)
  final String? parentPhone;     // 학부모 연락처

  @HiveField(6)
  final String? parentName;      // 학부모 이름

  @HiveField(7)
  final String? email;

  // 연령 정보
  @HiveField(8)
  final DateTime? birthDate;     // 생년월일 (연령 그룹 계산용)

  @HiveField(9)
  final AgeGroup? manualAgeGroup; // 수동 설정 연령 그룹

  // 앱 연결 상태
  @HiveField(10)
  final ConnectionStatus connectionStatus;

  @HiveField(11)
  final DateTime? connectedAt;

  // 메타
  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime? updatedAt;

  const Student({
    required this.id,
    required this.name,
    required this.profileColor,
    this.profileImageUrl,
    this.phone,
    this.parentPhone,
    this.parentName,
    this.email,
    this.birthDate,
    this.manualAgeGroup,
    this.connectionStatus = ConnectionStatus.offline,
    this.connectedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);

  Map<String, dynamic> toJson() => _$StudentToJson(this);

  // 계산 필드
  AgeGroup get effectiveAgeGroup =>
      AgeGroup.fromBirthDate(birthDate) ?? manualAgeGroup ?? AgeGroup.student;

  Student copyWith({
    String? id,
    String? name,
    Color? profileColor,
    String? profileImageUrl,
    String? phone,
    String? parentPhone,
    String? parentName,
    String? email,
    DateTime? birthDate,
    AgeGroup? manualAgeGroup,
    ConnectionStatus? connectionStatus,
    DateTime? connectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      profileColor: profileColor ?? this.profileColor,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      parentName: parentName ?? this.parentName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      manualAgeGroup: manualAgeGroup ?? this.manualAgeGroup,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectedAt: connectedAt ?? this.connectedAt,
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
| `name` | String | ✅ | 학생 이름 |
| `profileColor` | Color | ✅ | 프로필 색상 |
| `profileImageUrl` | String? | - | 프로필 이미지 URL |
| `phone` | String? | - | 학생 본인 연락처 |
| `parentPhone` | String? | - | 학부모 연락처 |
| `parentName` | String? | - | 학부모 이름 |
| `email` | String? | - | 이메일 |
| `birthDate` | DateTime? | - | 생년월일 |
| `manualAgeGroup` | AgeGroup? | - | 수동 설정 연령 그룹 |
| `connectionStatus` | ConnectionStatus | ✅ | offline, inviteSent, connected |
| `connectedAt` | DateTime? | - | 앱 연결 시점 |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

---

## JSON 예시

```json
{
  "id": "student_001",
  "name": "김민수",
  "profileColor": "#6B5B95",
  "profileImageUrl": null,
  "phone": null,
  "parentPhone": "010-1234-5678",
  "parentName": "김철수",
  "email": null,
  "birthDate": "2014-05-15T00:00:00.000Z",
  "manualAgeGroup": null,
  "connectionStatus": "connected",
  "connectedAt": "2026-01-01T00:00:00.000Z",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| ConnectionStatus | 60 |
| AgeGroup | 61 |
| Student | 62 |

---

## ⚠️ 마이그레이션 참고

기존 Student 엔티티에서 다음 필드가 ClassMembership으로 이동했습니다:

| 이전 (Student) | 이후 (ClassMembership) |
|---------------|----------------------|
| instrument | instrument |
| level | level |
| monthlyFee | monthlyFee |
| lessonsPerWeek | lessonsPerWeek |
| lessonDay | lessonDay |
| lessonTime | lessonTime |
| lessonDuration | lessonDuration |
| status | status |

---

## 관련 엔티티

- [ClassMembership](class_membership.md) - 학생의 클래스 소속 정보
- [Subscription](subscription.md) - 학생의 수강권
