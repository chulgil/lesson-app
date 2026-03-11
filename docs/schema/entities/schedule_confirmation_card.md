# ScheduleConfirmationCard 엔티티

> 마지막 업데이트: 2026-03-11

## 개요

수강권 발급 후 학생에게 레슨 스케줄 확인을 요청하는 카드입니다.
시나리오(체험 후 등록, 재등록, 추가 악기)에 따라 이전 스케줄이나 체험 레슨 시간을 제안합니다.

---

## Dart 엔티티

```dart
// lib/features/schedule/domain/entities/schedule_confirmation_card.dart

@HiveType(typeId: 102)
@JsonSerializable()
class ScheduleConfirmationCard extends HiveObject {
  @HiveField(0)  final String id;
  @HiveField(1)  final String studentId;
  @HiveField(2)  final String teacherId;
  @HiveField(3)  final String teacherName;
  @HiveField(4)  final String? instrument;
  @HiveField(5)  final String subscriptionId;
  @HiveField(6)  final int? suggestedDay;
  @HiveField(7)  final String? suggestedTime;
  @HiveField(8)  final int? lessonDuration;
  @HiveField(9)  final ScheduleCardType cardType;
  @HiveField(10) final ScheduleCardStatus status;
  @HiveField(11) final DateTime createdAt;
  @HiveField(12) final DateTime? respondedAt;
  @HiveField(13) final int? totalLessons;
  @HiveField(14) final String? lessonRequestId;
}
```

---

## 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | 고유 ID |
| `studentId` | String | ✅ | 학생 ID |
| `teacherId` | String | ✅ | 선생님 ID |
| `teacherName` | String | ✅ | 선생님 이름 |
| `instrument` | String? | - | 악기명 |
| `subscriptionId` | String | ✅ | 연결된 수강권 ID |
| `suggestedDay` | int? | - | 제안 레슨 요일 (1=월 ~ 7=일) |
| `suggestedTime` | String? | - | 제안 레슨 시간 (예: "15:00") |
| `lessonDuration` | int? | - | 레슨 시간 (분) |
| `cardType` | ScheduleCardType | ✅ | 카드 유형 |
| `status` | ScheduleCardStatus | - | 상태 (기본: pending) |
| `createdAt` | DateTime | ✅ | 생성일 |
| `respondedAt` | DateTime? | - | 학생 응답 일시 |
| `totalLessons` | int? | - | 수강권 총 레슨 수 (표시용) |
| `lessonRequestId` | String? | - | 관련 레슨 요청 ID (재등록용) |

### 계산 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `hasSuggestedSchedule` | bool | 제안 스케줄 존재 여부 |
| `isActionable` | bool | 액션 가능 여부 (pending 상태) |
| `formattedSuggestedSchedule` | String? | 포맷된 제안 스케줄 (예: "매주 수요일 15:00 (50분)") |

---

## Enum

### ScheduleCardType (HiveType: 100)

카드 유형 (시나리오별).

| 값 | 라벨 | 제안 텍스트 | 시간 제안 |
|-----|------|-----------|----------|
| `afterTrial` | 체험 후 등록 | 체험 레슨 시간으로 예약할까요? | ✅ |
| `reEnrollment` | 재등록 | 이전 스케줄로 예약할까요? | ✅ |
| `additionalInstrument` | 추가 악기 | 레슨 시간을 선택해주세요 | - |

### ScheduleCardStatus (HiveType: 101)

카드 상태.

| 값 | 라벨 | 설명 |
|-----|------|------|
| `pending` | 확인 대기 | 학생 응답 대기 중 |
| `confirmed` | 확정됨 | 제안 시간 수락 |
| `changedTime` | 시간 변경됨 | 다른 시간 선택 |
| `dismissed` | 닫힘 | 카드 닫힘/만료 |

---

## Hive TypeId

| 타입 | TypeId |
|------|--------|
| ScheduleCardType | 100 |
| ScheduleCardStatus | 101 |
| ScheduleConfirmationCard | 102 |

---

## JSON 예시

```json
{
  "id": "card_001",
  "studentId": "student_001",
  "teacherId": "teacher_001",
  "teacherName": "박선생",
  "instrument": "바이올린",
  "subscriptionId": "sub_001",
  "suggestedDay": 3,
  "suggestedTime": "15:00",
  "lessonDuration": 50,
  "cardType": "afterTrial",
  "status": "pending",
  "createdAt": "2026-03-11T00:00:00.000Z",
  "respondedAt": null,
  "totalLessons": 4,
  "lessonRequestId": null
}
```

---

## 관련 파일

- Entity: `features/schedule/domain/entities/schedule_confirmation_card.dart`
- Provider: `features/schedule/presentation/providers/`

## 관련 엔티티

- [Subscription](subscription.md) - 수강권
- [LessonSchedule](lesson_schedule.md) - 레슨 스케줄

## 변경 이력

- 2026-03-11: 초기 스키마 문서 생성
