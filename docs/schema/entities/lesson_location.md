# LessonLocation 엔티티

> 마지막 업데이트: 2026-01-24
> 관련 스펙: [student_class_system.md](../../specs/student/student_class_system.md)

## 개요

레슨 장소 정보입니다. LessonClass(학원/개인레슨)와 연결되거나 독립적으로 존재할 수 있습니다.
학원 레슨실, 선생님 스튜디오, 학생 집 방문, 온라인 등의 유형을 지원합니다.

---

## Dart 엔티티

```dart
// lib/features/students/domain/entities/lesson_location.dart

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lesson_location.g.dart';

/// 레슨 장소 유형
@HiveType(typeId: 58)
enum LocationType {
  @HiveField(0)
  academyRoom,     // 🏫 학원 레슨실

  @HiveField(1)
  teacherStudio,   // 🏠 선생님 스튜디오

  @HiveField(2)
  studentHome,     // 🚗 학생 집 방문

  @HiveField(3)
  externalPlace,   // 📍 외부 장소 (대여 연습실 등)

  @HiveField(4)
  online,          // 💻 온라인
}

/// 레슨 장소
@HiveType(typeId: 59)
@JsonSerializable()
class LessonLocation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;                    // "레슨실 1", "홈스튜디오"

  @HiveField(2)
  final LocationType type;

  @HiveField(3)
  final String? lessonClassId;          // 소속 클래스 (학원 레슨실인 경우)

  @HiveField(4)
  final String? ownerId;                // 소유자 (선생님 ID)

  // 주소 정보
  @HiveField(5)
  final String? address;                // 전체 주소

  @HiveField(6)
  final String? addressDetail;          // 상세 주소 (동/호수)

  // 좌표 (지도 연동용)
  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  // 온라인 정보
  @HiveField(9)
  final String? onlinePlatform;         // "zoom", "google_meet", "facetime"

  @HiveField(10)
  final String? onlineLink;             // 미팅 링크 (선택)

  // 메타
  @HiveField(11)
  final String? notes;                  // 찾아오는 길, 주차 정보 등

  @HiveField(12)
  final bool isDefault;                 // 기본 장소 여부

  @HiveField(13)
  final bool isActive;                  // 활성 상태

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime? updatedAt;

  const LessonLocation({
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

  /// 장소 유형별 아이콘
  String get icon {
    switch (type) {
      case LocationType.academyRoom:
        return '🏫';
      case LocationType.teacherStudio:
        return '🏠';
      case LocationType.studentHome:
        return '🚗';
      case LocationType.externalPlace:
        return '📍';
      case LocationType.online:
        return '💻';
    }
  }

  /// 표시용 전체 주소
  String get displayAddress {
    if (type == LocationType.online) {
      return onlinePlatform ?? '온라인';
    }
    if (address == null) return '';
    return addressDetail != null ? '$address $addressDetail' : address!;
  }

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
}
```

---

## 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | UUID |
| `name` | String | ✅ | 장소명 ("레슨실 1", "홈스튜디오") |
| `type` | LocationType | ✅ | academyRoom, teacherStudio, studentHome, externalPlace, online |
| `lessonClassId` | String? | - | 소속 클래스 ID (학원 레슨실만) |
| `ownerId` | String? | - | 소유자 (선생님 ID) |
| `address` | String? | - | 전체 주소 |
| `addressDetail` | String? | - | 상세 주소 (층/호) |
| `latitude` | double? | - | 위도 (지도 연동용) |
| `longitude` | double? | - | 경도 (지도 연동용) |
| `onlinePlatform` | String? | - | 온라인 플랫폼 (zoom, google_meet 등) |
| `onlineLink` | String? | - | 미팅 링크 |
| `notes` | String? | - | 찾아오는 길, 주차 정보 |
| `isDefault` | bool | ✅ | 기본 장소 여부 (기본값: false) |
| `isActive` | bool | ✅ | 활성 상태 (기본값: true) |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

---

## JSON 예시

### 학원 레슨실

```json
{
  "id": "loc_001",
  "name": "레슨실 1",
  "type": "academyRoom",
  "lessonClassId": "lc_001",
  "ownerId": null,
  "address": "서울시 강남구 테헤란로 123",
  "addressDetail": "○○빌딩 3층",
  "latitude": 37.5012,
  "longitude": 127.0396,
  "onlinePlatform": null,
  "onlineLink": null,
  "notes": "주차 1시간 무료, 엘리베이터 이용",
  "isDefault": true,
  "isActive": true,
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

### 온라인

```json
{
  "id": "loc_002",
  "name": "Zoom 레슨",
  "type": "online",
  "lessonClassId": "lc_002",
  "ownerId": "teacher_001",
  "address": null,
  "addressDetail": null,
  "latitude": null,
  "longitude": null,
  "onlinePlatform": "zoom",
  "onlineLink": "https://zoom.us/j/123456789",
  "notes": "레슨 시작 10분 전 접속",
  "isDefault": false,
  "isActive": true,
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": null
}
```

---

## Repository 인터페이스

```dart
// lib/features/students/domain/repositories/location_repository.dart

abstract class LocationRepository {
  /// 클래스의 모든 장소 조회
  Future<List<LessonLocation>> getByClassId(String classId);

  /// 선생님의 모든 장소 조회
  Future<List<LessonLocation>> getByOwnerId(String ownerId);

  /// 장소 생성
  Future<LessonLocation> create(LessonLocation location);

  /// 장소 수정
  Future<LessonLocation> update(LessonLocation location);

  /// 기본 장소 설정
  Future<void> setDefault(String id, String classId);

  /// 비활성화 (소프트 삭제)
  Future<void> deactivate(String id);
}
```

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| LocationType | 58 |
| LessonLocation | 59 |

---

## 장소 유형별 아이콘

| 유형 | 아이콘 | 설명 |
|------|:-----:|------|
| academyRoom | 🏫 | 학원 레슨실 |
| teacherStudio | 🏠 | 선생님 스튜디오 |
| studentHome | 🚗 | 학생 집 방문 |
| externalPlace | 📍 | 외부 장소 |
| online | 💻 | 온라인 |

---

## 관련 엔티티

- [LessonClass](lesson_class.md) - 소속 클래스
