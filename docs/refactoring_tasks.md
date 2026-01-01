# 레슨 앱 리팩토링 태스크

> 마지막 업데이트: 2026-01-01
> 분석 기준: 최신 Flutter 개발 트렌드 및 Clean Architecture 원칙

---

## 프로젝트 현황 요약

| 항목 | 현재 상태 |
|------|----------|
| 파일 수 | 216개 Dart 파일 |
| 코드량 | ~76,691줄 |
| 대형 파일 (800줄+) | 15개 이상 |
| 최대 파일 | 1,510줄 |
| 아키텍처 | Feature-based (presentation only) |
| 상태관리 | Riverpod (@riverpod 코드생성) |
| 라우팅 | go_router (14.2.0) |
| 로컬 저장소 | Hive (2.2.3) |

---

## 아키텍처 분석 결과

### 현재 구조의 장점 ✅

1. **Feature-based 폴더 구조**: 도메인별 분리 시도
2. **Riverpod 코드생성**: 타입 안전한 상태관리
3. **Repository 패턴**: 인터페이스 + Mock 분리
4. **일관된 네이밍**: 파일/클래스 네이밍 규칙 준수

### 개선이 필요한 영역 ⚠️

1. **대형 파일 다수**: 유지보수 어려움
2. **레이어 불완전**: presentation만 존재, domain/data 레이어 부재
3. **중앙집중 모델**: models/ 폴더에 모든 모델 집중
4. **Provider 구조**: 일부 legacy 패턴 혼재
5. **테스트 커버리지**: 테스트 코드 부족

---

## 리팩토링 태스크 목록

### Phase 1: 대형 파일 분할 (우선순위: 높음) ✅ 완료

> 800줄 이상 파일을 300~500줄 수준으로 분할

#### 1.1 라우터 파일 분할 ✅ 완료
- **파일**: `lib/core/router/app_router.dart` (653줄 → 53줄)
- **작업**:
  - [x] 도메인별 라우트 파일 분리 (12개 파일 생성)
    - `app_routes.dart` - 라우트 경로 상수
    - `routes/auth_routes.dart`
    - `routes/home_routes.dart`
    - `routes/student_routes.dart`
    - `routes/lesson_routes.dart`
    - `routes/practice_routes.dart`
    - `routes/schedule_routes.dart`
    - `routes/profile_routes.dart`
    - `routes/invite_routes.dart`
    - `routes/search_routes.dart`
    - `routes/onboarding_routes.dart`
  - [x] 중앙 라우터는 import만 담당
- **결과**: 라우트 추가/수정 시 충돌 감소
- **커밋**: `dd83198`

#### 1.2 대형 스크린 파일 분할 ✅ 완료

| 파일 | 이전 | 이후 | 분할 내용 |
|------|------|------|----------|
| `section_detail_screen.dart` | 1,319줄 | 634줄 | 5개 위젯 분리 |
| `lesson_detail_screen.dart` | 1,225줄 | 828줄 | 4개 위젯 분리 |
| `student_detail_screen.dart` | 1,148줄 | 614줄 | 5개 위젯 분리 |
| **합계** | **3,692줄** | **2,076줄** | **-1,616줄 (-44%)** |

**생성된 위젯 파일:**
- `widgets/section_detail/` (5개): SectionInfoCard, PracticeStatsCard, RecordingControl, SectionRecordingListItem, CompletionToggle
- `widgets/lesson_detail/` (4개): AddTipBottomSheet, LessonHeaderCard, LessonRecordingCard, AISummaryCard
- `widgets/student_detail/` (5개): StudentStatsCards, StudentPracticeSection, StudentUpcomingLessonsSection, StudentRecentLessonsSection, StudentLessonCard

- [x] 각 스크린의 하위 위젯을 `widgets/[screen_name]/` 폴더로 분리
- [x] Barrel 파일 생성 (`*_widgets.dart`)
- **커밋**: `c401632`, `30ce970`, `edeafed`

---

### Phase 2: Clean Architecture 레이어 정립 (우선순위: 중간)

> 현재: features/[domain]/presentation/
> 목표: features/[domain]/{data, domain, presentation}/

#### 2.1 Domain 레이어 도입 ✅ 완료 (practice, lesson, student 도메인)

**적용된 도메인 구조:**
```
features/[domain]/
├── domain/
│   ├── entities/         # 도메인 엔티티
│   └── repositories/     # Repository 인터페이스
├── data/
│   └── repositories/     # Mock 구현체
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/        # (기존 lib/providers/ 유지)
```

**practice 도메인** ✅
- Domain: PracticeTask, PracticeLog, PracticeStreak, PracticeStats
- Data: MockPracticeRepository
- **커밋**: `c32e2e9`

**lesson 도메인** ✅
- Domain: Lesson, LessonPiece, LessonRecording, LessonStatus
- Data: MockLessonRepository
- 하위 호환성: lib/models/lesson.dart, lib/repositories/lesson_repository.dart re-export

**student 도메인** ✅
- Domain: Student, StudentStatus, StudentLevel, PracticeStatus
- Data: MockStudentRepository
- 하위 호환성: lib/models/student.dart, lib/repositories/student_repository.dart re-export
- 공유 타입: ConnectionStatus, PracticeLevel (invite.dart), AgeGroup (practice_item.dart) 참조

- [x] practice 도메인 시범 적용
- [x] lesson, student 도메인 확장 적용

#### 2.2 Models 분산 배치 (진행 중)
- **현재**: `lib/models/` (중앙집중)
- **목표**: 각 feature의 `data/models/`로 이동

**Step 1: 공유 enum 추출** ✅ 완료
- `lib/core/models/shared_enums.dart` 생성
  - AgeGroup (from practice_item.dart)
  - ConnectionStatus, PracticeLevel, ConnectionStatusHelper (from invite.dart)
- `lib/core/models/models.dart` barrel file 생성
- 기존 파일에서 re-export 설정 (하위 호환성 유지)

**Step 2: Feature 전용 모델 이동** (대기)
- [ ] feature 전용 모델은 해당 feature로 이동
- **난이도**: 중

---

### Phase 3: Provider 구조 개선 (우선순위: 중간)

#### 3.1 Ref 타입 현대화 ✅ 완료
- [x] deprecated Ref 타입을 `Ref`로 변경 (26건)
- [x] flutter_riverpod import 추가

#### 3.2 Provider 위치 정리
- **현재**: `lib/providers/` (중앙집중)
- **목표**: 각 feature의 `presentation/providers/`로 이동
- [ ] UI 상태 Provider는 feature 내부로 이동
- [ ] 공유 Provider는 `lib/core/providers/`에 유지
- **난이도**: 중

#### 3.3 AsyncValue 패턴 일관화
- [ ] 모든 비동기 Provider에 AsyncValue 적용
- [ ] 에러 핸들링 표준화
- [ ] 로딩 상태 UI 컴포넌트 표준화
- **난이도**: 낮음

---

### Phase 4: 코드 품질 개선 (우선순위: 낮음)

#### 4.1 테스트 커버리지 확대
- **현재 상태**: 테스트 코드 부족
- [ ] Repository 단위 테스트 추가
- [ ] Provider 테스트 추가
- [ ] Widget 테스트 (주요 화면)
- [ ] Integration 테스트 (핵심 플로우)
- **목표**: 60% 이상 커버리지
- **난이도**: 중

#### 4.2 문서화 강화
- [ ] 주요 클래스 dartdoc 추가
- [ ] 아키텍처 문서 작성 (`docs/architecture.md`)
- [ ] API 문서 자동 생성 설정
- **난이도**: 낮음

#### 4.3 의존성 업데이트
- [ ] 주요 패키지 최신 버전 확인
- [ ] Breaking changes 대응
- [ ] deprecated API 제거
- **난이도**: 중

---

## 실행 우선순위

```
1단계: Phase 1.1 라우터 분할 ✅ 완료
    ↓
2단계: Phase 1.2 대형 스크린 분할 ✅ 완료
    ↓
3단계: Phase 2.1 practice 도메인 Clean Architecture ✅ 완료
    ↓
4단계: Phase 2.1 확장 (lesson, student 도메인) ✅ 완료
    ↓
5단계: Phase 2.2 Step 1 공유 enum 추출 ✅ 완료
    ↓
6단계 (다음): Phase 2.2 Step 2 feature 전용 모델 이동
    ↓
7단계 (지속): Phase 3.2, 4 Provider 분산/테스트/문서화
```

---

## 리팩토링 원칙

### DO ✅
- 한 번에 하나의 리팩토링만 진행
- 각 단계 후 `flutter analyze` 확인 (0 issues 유지)
- 기능 동작 확인 후 커밋
- 작은 단위로 PR 생성

### DON'T ❌
- 여러 리팩토링 동시 진행
- 테스트 없이 대규모 변경
- 기존 기능 동작 미확인 상태로 커밋

---

## 태스크 체크리스트

### 완료됨 ✅
- [x] `app_router.dart` 도메인별 분할
- [x] 대형 스크린 파일 분할 (section_detail, lesson_detail, student_detail)
- [x] deprecated Ref 타입 수정 (26건)
- [x] deprecated 경고 수정 (PaymentStatus 등)
- [x] practice 도메인 Clean Architecture 적용 (domain/data 레이어)
- [x] lesson 도메인 Clean Architecture 적용
- [x] student 도메인 Clean Architecture 적용
- [x] 공유 enum lib/core/models/로 추출 (AgeGroup, ConnectionStatus, PracticeLevel)

### 즉시 실행 가능
- [ ] 미사용 import 정리 (선택사항)

### 기획 필요
- [ ] Clean Architecture 전환 범위 결정
- [ ] 테스트 전략 수립
- [ ] 마이그레이션 일정 계획

---

## 참고 자료

- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/best_practices)
- [Effective Dart](https://dart.dev/effective-dart)

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-01-01 | 초기 분석 및 태스크 작성 |
| 2025-01-01 | Phase 1.1 라우터 분할 완료 (653줄 → 53줄) |
| 2025-01-01 | Phase 1.2 대형 스크린 분할 완료 (3,692줄 → 2,076줄, -44%) |
| 2025-01-01 | Phase 3.1 Ref 타입 현대화 완료 (26건) |
| 2026-01-01 | Phase 2.1 practice 도메인 Clean Architecture 적용 완료 |
| 2026-01-01 | Phase 2.1 lesson, student 도메인 Clean Architecture 확장 완료 |
| 2026-01-01 | Phase 2.2 Step 1 공유 enum lib/core/models/로 추출 완료 |
