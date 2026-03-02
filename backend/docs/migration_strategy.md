# Hive → MySQL Migration Strategy

> 마지막 업데이트: 2026-03-02

## 개요

현재 Flutter 앱은 Hive(로컬 DB)와 Mock Repository로 동작한다.
이를 MySQL(서버 DB) + REST API 기반으로 전환하되, 기존 데이터를 보존하고 무중단으로 마이그레이션한다.

---

## 현재 아키텍처 (Before)

```
┌──────────────────────────┐
│      Flutter App         │
├──────────────────────────┤
│  Presentation (Screens)  │
│  Providers (Riverpod)    │
├──────────────────────────┤
│  Repository Interface    │  ← 추상 인터페이스
├──────────────────────────┤
│  Mock Repository (Hive)  │  ← 로컬 DB 구현
├──────────────────────────┤
│  Hive Boxes (Local)      │  ← 기기 저장
└──────────────────────────┘
```

## 목표 아키텍처 (After)

```
┌──────────────────────────┐     ┌──────────────────────┐
│      Flutter App         │     │   FastAPI Backend     │
├──────────────────────────┤     ├──────────────────────┤
│  Presentation (Screens)  │     │  API Routes          │
│  Providers (Riverpod)    │     │  Services            │
├──────────────────────────┤     │  SQLAlchemy Models   │
│  Repository Interface    │     ├──────────────────────┤
├──────────────────────────┤     │  MySQL 8.0           │
│  API Repository          │────→│                      │
│  (+ Local Cache)         │     └──────────────────────┘
└──────────────────────────┘
```

---

## 마이그레이션 페이즈

### Phase 1: 백엔드 API 구축 (2-3주)

**목표:** 서버 측 API를 완성하고, 프론트엔드는 기존 Hive 그대로 유지.

```
[프론트엔드]               [백엔드]
Mock Repository ────→    API 구축 중 (독립 개발)
Hive Boxes                MySQL 테이블 생성
                          Alembic 마이그레이션
                          CRUD API 테스트
```

**작업 목록:**
1. MySQL DB + 테이블 생성 (Alembic)
2. SQLAlchemy ORM 모델 작성
3. FastAPI CRUD 엔드포인트 구현
4. OAuth + JWT 인증 구현
5. Postman/pytest로 API 테스트

**완료 조건:**
- 모든 엔드포인트가 curl/Postman으로 동작
- DB에 테스트 데이터 입력/조회 가능

---

### Phase 2: API Repository 이중화 (1-2주)

**목표:** `ApiRepository implements Repository` 패턴으로 API 우선, Hive 폴백 구조를 만든다.

```
[프론트엔드]
Repository Interface
├── ApiRepository (NEW)   ←── API 호출 우선
│   ├── 성공 → 캐시에 저장
│   └── 실패 → HiveRepository 폴백
└── HiveRepository (기존)  ←── 폴백용
```

**핵심 패턴:**

```dart
class ApiLessonRepository implements LessonRepository {
  final Dio _dio;
  final HiveLessonRepository _hiveRepo;  // Fallback

  @override
  Future<List<Lesson>> getLessons() async {
    try {
      final response = await _dio.get('/api/v1/lessons');
      final lessons = (response.data['items'] as List)
          .map((e) => Lesson.fromJson(e))
          .toList();
      // Cache locally
      await _hiveRepo.cacheAll(lessons);
      return lessons;
    } catch (e) {
      // Offline fallback
      return _hiveRepo.getLessons();
    }
  }

  @override
  Future<Lesson> createLesson(Lesson lesson) async {
    try {
      final response = await _dio.post('/api/v1/lessons', data: lesson.toJson());
      final created = Lesson.fromJson(response.data);
      await _hiveRepo.cache(created);
      return created;
    } catch (e) {
      // Queue for sync later
      await _hiveRepo.queueForSync(lesson);
      return lesson;
    }
  }
}
```

**Repository Provider 전환:**

```dart
// Before (Hive)
@Riverpod(keepAlive: true)
LessonRepository lessonRepository(Ref ref) {
  return HiveLessonRepository();
}

// After (API + Hive fallback)
@Riverpod(keepAlive: true)
LessonRepository lessonRepository(Ref ref) {
  final dio = ref.read(dioProvider);
  final hiveRepo = HiveLessonRepository();
  return ApiLessonRepository(dio, hiveRepo);
}
```

**작업 목록:**
1. Dio HTTP 클라이언트 설정 (Auth 인터셉터 포함)
2. 각 도메인별 `ApiRepository` 구현
3. Repository Provider를 `ApiRepository`로 전환
4. 오프라인 시 Hive 폴백 동작 확인
5. 네트워크 에러 핸들링

**전환 순서 (리스크 낮은 것부터):**

| 순서 | Repository | 이유 |
|------|-----------|------|
| 1 | Auth (OAuth) | 인증 기반 → 다른 모든 것의 전제 |
| 2 | StudentRepository | 읽기 위주, 단순 CRUD |
| 3 | LessonRepository | 핵심 기능, 복잡도 중간 |
| 4 | SubscriptionRepository | 결제 연동, 상태 관리 복잡 |
| 5 | PracticeRepository | 데이터 양 많음, 날짜별 조회 |
| 6 | RecordingRepository | 파일 업로드/다운로드 |
| 7 | ScheduleRepository | 실시간성 필요 |
| 8 | NotificationRepository | 푸시 알림 연동 |

**완료 조건:**
- 온라인 시 API 호출이 정상 동작
- 오프라인 시 Hive 폴백이 정상 동작
- 기존 UI가 변경 없이 동작

---

### Phase 3: Hive 데이터 서버 업로드 (1주)

**목표:** 기존 Hive에 저장된 사용자 데이터를 서버로 일괄 업로드.

```
[앱 최초 실행 (업데이트 후)]
1. 로그인 (OAuth)
2. "기존 데이터 동기화" 프롬프트
3. Hive 데이터 읽기
4. POST /api/v1/migration/upload 일괄 업로드
5. 서버 확인 응답
6. Hive 데이터에 "synced" 마킹
```

**마이그레이션 API:**

```
POST /api/v1/migration/upload
```

```json
{
  "students": [...],
  "lessons": [...],
  "subscriptions": [...],
  "practice_repertoires": [...],
  "practice_sections": [...],
  "recordings": [...]  // 메타데이터만, 파일은 별도
}
```

**녹음 파일 마이그레이션:**

```
1. 녹음 메타데이터 먼저 업로드 (DB)
2. 백그라운드로 녹음 파일 업로드 (Object Storage)
   - 한 번에 하나씩 (대역폭 고려)
   - 진행률 표시
   - 실패 시 재시도
3. 업로드 완료된 파일은 로컬 삭제 가능
```

**데이터 충돌 해결:**

| 상황 | 전략 |
|------|------|
| 서버에 없는 데이터 | 서버에 생성 |
| 서버에 이미 존재 | 타임스탬프 비교 → 최신 우선 |
| ID 충돌 | 서버 ID 우선, 로컬 매핑 테이블 유지 |

**작업 목록:**
1. 마이그레이션 API 엔드포인트 구현
2. Hive → JSON 변환 유틸리티
3. ID 매핑 로직 (Hive UUID → Server UUID)
4. 녹음 파일 배치 업로드
5. 마이그레이션 상태 추적 UI

**완료 조건:**
- Hive 데이터가 서버 DB에 완전히 복제됨
- 녹음 파일이 Object Storage에 업로드됨
- 데이터 무결성 검증 통과

---

### Phase 4: Hive 제거 + 캐시 전환 (1주)

**목표:** Hive를 완전히 제거하고, 필요한 캐싱만 유지.

```
[최종 아키텍처]
Repository Interface
└── ApiRepository
    ├── API 호출 (Primary)
    └── 로컬 캐시 (Secondary)
        └── SQLite / SharedPreferences
```

**작업 목록:**
1. HiveRepository 코드 제거
2. Hive 의존성 제거 (`pubspec.yaml`)
3. `@HiveType`, `@HiveField` 어노테이션 제거
4. 캐시용 경량 로컬 DB 도입 (drift/SQLite 또는 SharedPreferences)
5. 오프라인 캐시 정책 구현
   - 읽기: 캐시 우선, 네트워크 동기화
   - 쓰기: 네트워크 우선, 실패 시 큐잉

**캐시 정책:**

| 데이터 | 캐시 전략 | TTL |
|--------|----------|-----|
| 학생 목록 | 캐시 우선 | 1시간 |
| 레슨 목록 | 네트워크 우선 | 5분 |
| 구독 상태 | 네트워크 우선 | 즉시 |
| 연습 기록 | 캐시 우선 | 30분 |
| 녹음 파일 | 로컬 + 클라우드 | 영구 |
| 알림 | 네트워크 전용 | 없음 |

**완료 조건:**
- Hive 관련 코드 완전 제거
- `flutter analyze` 에러 없음
- 온라인/오프라인 모두 정상 동작

---

## Hive → MySQL 필드 매핑

### 주요 변환 규칙

| Hive (Dart) | MySQL | 비고 |
|-------------|-------|------|
| `String` (UUID) | `CHAR(36)` | PK/FK |
| `String` | `VARCHAR(n)` / `TEXT` | 길이에 따라 |
| `int` | `INT` / `BIGINT` | 금액은 INT |
| `double` | `DECIMAL(10,2)` | 통화 |
| `bool` | `BOOLEAN` (TINYINT) | |
| `DateTime` | `DATETIME` | UTC 저장 |
| `List<String>` | `JSON` | MySQL JSON 타입 |
| `Map<String, dynamic>` | `JSON` | |
| `Enum` | `ENUM(...)` | MySQL ENUM |
| `Color` | `VARCHAR(7)` | `#RRGGBB` |
| 내장 객체 | 별도 테이블 | 1:N 정규화 |

### HiveType → 테이블 매핑

| HiveTypeId | Dart 클래스 | MySQL 테이블 |
|------------|------------|-------------|
| 52 | LessonClass | lesson_classes |
| 54 | ClassMembership | class_memberships |
| 55 | Subscription | subscriptions |
| 30 | PracticeRecording | practice_recordings |
| 31 | PracticeNote | practice_notes |
| 32 | PracticeGoal | practice_goals |
| 60-62 | Student | students |
| 70-76 | TeacherAvailability | teacher_availabilities + time_slots |
| 81 | GroupClass | group_classes |
| 82 | SubscriptionProposal | subscription_proposals |
| 90-93 | Booking | lesson_bookings |
| 93 | Follow | follows |
| 100 | LessonRequest | lesson_requests |

---

## 리스크 및 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| 데이터 유실 | 치명적 | Phase 3 전 Hive 백업, 검증 스크립트 |
| 오프라인 미지원 | 사용성 저하 | Phase 2에서 폴백 유지 |
| API 성능 | 느린 응답 | 페이지네이션, 캐싱, 인덱스 최적화 |
| 녹음 파일 대용량 | 업로드 시간 | 백그라운드 + 진행률 + 재시도 |
| 스키마 불일치 | 데이터 오류 | 매핑 테이블 + 검증 로직 |
| 중복 동기화 | 데이터 중복 | idempotency key + upsert |

---

## 타임라인 요약

```
Week 1-3  : [Phase 1] 백엔드 API 구축
Week 4-5  : [Phase 2] ApiRepository 이중화
Week 6    : [Phase 3] Hive 데이터 서버 업로드
Week 7    : [Phase 4] Hive 제거 + 캐시 전환
Week 8    : 안정화 + 버그 수정
```

총 예상 기간: **6-8주**
