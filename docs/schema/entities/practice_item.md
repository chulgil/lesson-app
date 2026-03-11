# PracticeItem 엔티티

> 마지막 업데이트: 2026-03-11

## 개요

선생님이 레슨에서 할당하는 "이번 주 연습" 항목입니다.
우선순위(필수/추천/도전)별로 분류되며, 학생의 완료 상태와 선생님 좋아요를 추적합니다.

---

## 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|:----:|------|
| `id` | String | ✅ | 고유 ID |
| `lessonId` | String | ✅ | 연결된 레슨 ID |
| `studentId` | String | ✅ | 학생 ID |
| `teacherId` | String | ✅ | 선생님 ID |
| `type` | PracticeType | ✅ | 연습 유형 |
| `title` | String | ✅ | 제목 (예: "Canon in D - A섹션") |
| `description` | String? | - | 설명 (예: "메트로놈 60으로 정확하게") |
| `repertoireId` | String? | - | 레퍼토리 연결 ID |
| `sectionId` | String? | - | 섹션 연결 ID |
| `resourceIds` | List\<String\> | - | 교육 자료 ID 목록 (기본: []) |
| `priority` | PracticePriority | - | 우선순위 (기본: should) |
| `isCompleted` | bool | - | 완료 여부 (기본: false) |
| `practiceCount` | int | - | 연습 횟수 (기본: 0) |
| `completedAt` | DateTime? | - | 완료 일시 |
| `hasLike` | bool | - | 선생님 좋아요 여부 (기본: false) |
| `likedAt` | DateTime? | - | 좋아요 일시 |
| `createdAt` | DateTime | ✅ | 생성일 |
| `updatedAt` | DateTime? | - | 수정일 |

### 계산 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `isFromRepertoire` | bool | 레퍼토리에서 가져온 항목 여부 |
| `completionInfo` | String | 완료 정보 문자열 (예: "2회 완료") |
| `completionDateText` | String? | 완료 날짜 문자열 (예: "3월 11일 완료") |

---

## Enum

### PracticePriority

연습 우선순위 레벨.

| 값 | 라벨 | 아동 라벨 | 색상 |
|-----|------|----------|------|
| `must` | 필수 | 꼭 해와요! | 🔴 error |
| `should` | 추천 | 해보면 좋아요~ | 🟡 practiceNormal |
| `could` | 도전 | 도전해볼까? | 🟢 practiceGood |

### PracticeType

연습 항목 유형.

| 값 | 라벨 | 아이콘 |
|-----|------|--------|
| `repertoire` | 레퍼토리 | music_note |
| `technique` | 테크닉 | piano |
| `theory` | 이론 | menu_book |
| `custom` | 직접입력 | edit_note |

---

## List Extension

`List<PracticeItem>`에 대한 편의 확장.

| 메서드/필드 | 반환 타입 | 설명 |
|------------|----------|------|
| `groupByPriority()` | Map | 우선순위별 그룹핑 (must → should → could) |
| `incomplete` | List | 미완료 항목만 |
| `completed` | List | 완료 항목만 |
| `completionRate` | double | 완료율 (0.0 ~ 1.0) |
| `completionPercentage` | String | 완료율 문자열 (예: "60%") |
| `completionSummary` | String | 완료 요약 (예: "2/5 완료") |
| `sortedByPriority()` | List | 우선순위 정렬 (must 먼저) |

---

## 관련 파일

- Entity: `features/practice/domain/entities/practice_item.dart`
- Provider: `features/practice/presentation/providers/`

## 변경 이력

- 2026-03-11: 초기 스키마 문서 생성
