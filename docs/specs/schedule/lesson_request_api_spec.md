# 레슨요청 API 스펙

> 작성일: 2026-03-29
> Issue: #217

## 엔드포인트 목록

### 1. 레슨요청 목록 (페이지네이션)

```
GET /api/lesson-requests
```

**Query Parameters:**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| teacherId | string | O* | 선생님 ID (*teacherId 또는 studentId 중 하나 필수) |
| studentId | string | O* | 학생 ID |
| status | string | - | 상태 필터 (pending, negotiating, completed, ...) |
| startDate | ISO 8601 | - | 기간 시작일 |
| endDate | ISO 8601 | - | 기간 종료일 |
| sortBy | string | - | 정렬 (createdAt_desc, studentName_asc) |
| page | int | - | 페이지 번호 (0부터, default: 0) |
| pageSize | int | - | 페이지 크기 (default: 20, max: 50) |

**Response:**

```json
{
  "data": [UnifiedLessonRequest],
  "meta": {
    "page": 0,
    "pageSize": 20,
    "totalCount": 45,
    "totalPages": 3
  }
}
```

### 2. 레슨요청 상세 (이벤트 포함)

```
GET /api/lesson-requests/:id
```

**Response:**

```json
{
  "data": {
    ...UnifiedLessonRequest,
    "events": [RequestEvent],
    "student": { "id", "name", "profileUrl" },
    "teacher": { "id", "name", "profileUrl" }
  }
}
```

### 3. 레슨요청 생성

```
POST /api/lesson-requests
```

**Body:**

```json
{
  "teacherId": "string",
  "type": "trial | regular | package",
  "instrument": "string",
  "goal": "hobby | exam | major | other",
  "experience": "beginner | intermediate | advanced",
  "preferredSlots": [
    { "priority": 1, "dayOfWeek": 2, "startTime": "14:00", "endTime": "15:00" }
  ],
  "preferredDuration": 60,
  "message": "string?",
  "academyId": "string?",
  "isReturningStudent": false
}
```

### 4. 레슨요청 액션

```
POST /api/lesson-requests/:id/actions
```

**Body:**

```json
{
  "action": "approve | reject | proposeAlternative | acceptAlternative | counterPropose | cancel",
  "message": "string?",
  "suggestedSlots": [TimeSlotOption]?,
  "selectedSlotIndex": 0?
}
```

**Action별 필수 필드:**

| Action | message | suggestedSlots | selectedSlotIndex |
|--------|---------|----------------|-------------------|
| approve | - | - | - |
| reject | O | - | - |
| proposeAlternative | - | O (1~3개) | - |
| acceptAlternative | - | - | O |
| counterPropose | - | O (1개) | - |
| cancel | - | - | - |

### 5. 달력 날짜별 요청 건수

```
GET /api/lesson-requests/calendar
```

**Query Parameters:**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| teacherId | string | O* | 선생님 ID |
| studentId | string | O* | 학생 ID |
| year | int | O | 연도 |
| month | int | O | 월 |

**Response:**

```json
{
  "data": {
    "2026-03-25": 2,
    "2026-03-26": 1,
    "2026-03-28": 3
  }
}
```

### 6. 만료 배치

```
POST /api/lesson-requests/expire (internal/cron)
```

- 7일 경과 + pending/negotiating 상태 → expired 전환
- 만료 24시간 전 푸시 알림 발송
- 매일 00:00 UTC 실행

## 인증/권한

- 모든 엔드포인트: Bearer JWT 필수
- teacherId/studentId는 토큰에서 추출 (query param은 검증용)
- 학생은 자신의 요청만 조회/액션 가능
- 선생님은 자신에게 온 요청만 조회/액션 가능

## 에러 코드

| HTTP | 코드 | 설명 |
|------|------|------|
| 400 | INVALID_TRANSITION | 상태 전이 불가 (e.g. completed → cancel) |
| 400 | MAX_SLOTS_EXCEEDED | suggestedSlots > 3개 |
| 404 | REQUEST_NOT_FOUND | 요청 ID 없음 |
| 403 | UNAUTHORIZED_ACTION | 권한 없는 액션 |
