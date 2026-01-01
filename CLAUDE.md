# CLAUDE.md - Lesson App

> 마지막 업데이트: 2026-01-01

음악 레슨/연습 관리 앱 (Flutter)

## 빠른 참조

| 항목 | 값 |
|------|-----|
| 기술 스택 | Flutter, Riverpod (@riverpod 코드생성), Go Router, Hive |
| 플랫폼 | iOS, Android |
| 아키텍처 | Clean Architecture + Feature-based |
| 상태 | Phase 1 완료 (100%) |

## 명령어

```bash
flutter pub get                    # 의존성
flutter run                        # 실행
dart run build_runner build --delete-conflicting-outputs  # 코드 생성
flutter analyze                    # 분석
```

---

## 프로젝트 구조 (Clean Architecture)

```
lib/
├── core/                    # 공통 유틸리티
│   ├── audio/               # 오디오 엔진 (메트로놈, 녹음)
│   ├── models/              # 공유 enum
│   ├── router/              # GoRouter (도메인별 분할)
│   └── theme/               # AppColors, AppTypography
│
├── features/                # 🔑 기능별 모듈 (Clean Architecture)
│   ├── [domain]/
│   │   ├── domain/          # 엔티티, Repository 인터페이스
│   │   │   └── entities/
│   │   ├── data/            # Repository 구현체 (Mock)
│   │   │   └── repositories/
│   │   └── presentation/    # UI 레이어
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── providers/   # 🔑 Feature별 Provider
│   │
│   ├── lessons/             # 레슨 관리
│   ├── practice/            # 연습 관리
│   ├── students/            # 학생 관리
│   ├── parent_home/         # 학부모 홈
│   ├── profile/             # 프로필
│   ├── notifications/       # 알림
│   ├── onboarding/          # 온보딩
│   └── search/              # 선생님 검색
│
├── models/                  # ⚠️ 레거시 (re-export only)
├── providers/               # ⚠️ 레거시 (re-export only)
└── repositories/            # ⚠️ 레거시 (re-export only)

docs/                        # 모든 프로젝트 문서
├── architecture.md          # 🔑 상세 아키텍처 가이드
├── refactoring_tasks.md     # 리팩토링 현황
├── requirement/             # 요구사항
├── proposal/                # 기획 제안서
└── specs/                   # 기능 명세 (도메인별)
```

> **⚠️ 중요**: `lib/models/`, `lib/providers/`, `lib/repositories/`는 레거시 위치입니다.
> 새 코드는 반드시 `features/[domain]/` 아래에 작성하세요.

→ [상세 아키텍처 가이드](docs/architecture.md)

---

## Claude 작업 지침

### 📋 작업 시작 전 체크리스트

1. **문서 확인** (순서대로):
   ```
   docs/architecture.md      → 폴더 구조 파악
   docs/requirement/         → 요구사항 확인
   docs/specs/[domain]/      → 관련 스펙 확인
   docs/refactoring_tasks.md → 리팩토링 현황 (진행중 작업 확인)
   ```

2. **Serena 메모리 확인**:
   - `lesson_app_architecture` - 아키텍처 빠른 참조
   - `code_style_conventions` - 코딩 컨벤션

### 📁 새 코드 작성 위치

| 항목 | 위치 | 예시 |
|------|------|------|
| 모델/엔티티 | `features/[domain]/domain/entities/` | `student.dart` |
| Provider | `features/[domain]/presentation/providers/` | `student_providers.dart` |
| 화면 | `features/[domain]/presentation/screens/` | `student_detail_screen.dart` |
| 위젯 | `features/[domain]/presentation/widgets/` | `student_card.dart` |
| 라우트 | `core/router/routes/` | `student_routes.dart` |
| 공유 타입 | `core/models/` | `shared_enums.dart` |

### 🔧 작업 유형별 가이드

#### Provider 추가
```dart
// 1. 파일 위치: features/[domain]/presentation/providers/
// 2. @riverpod 어노테이션 사용
@riverpod
Future<List<Lesson>> allLessons(Ref ref) async {
  final repository = ref.watch(lessonRepositoryProvider);
  return repository.getAllLessons();
}

// 3. build_runner 실행
// dart run build_runner build --delete-conflicting-outputs
```

#### 모델 추가
```dart
// 1. 파일 위치: features/[domain]/domain/entities/
// 2. JSON 직렬화 필요시
@JsonSerializable()
class NewModel { ... }

// 3. 하위 호환성 필요시 lib/models/에 re-export 추가
// export '../features/[domain]/domain/entities/new_model.dart';
```

#### 화면 추가
```dart
// 1. 파일 위치: features/[domain]/presentation/screens/
// 2. 라우트 추가: core/router/routes/[domain]_routes.dart
// 3. 라우트 상수 추가: core/router/app_routes.dart
```

### ✅ 작업 완료 체크리스트

1. [ ] `flutter analyze` - 경고 없음 확인
2. [ ] `dart run build_runner build` - 코드 생성 (Provider, JSON)
3. [ ] 관련 docs/specs/ 문서 업데이트
4. [ ] 커밋 메시지 한글로 작성 (Conventional Commits)

---

## 핵심 규칙

### 응답 언어
- **Claude 응답: 항상 한글로 작성**
- 코드 주석: 영어 유지
- 커밋 메시지: 한글 (Conventional Commits)

### 디자인
- 색상: 반드시 `AppColors` 클래스 사용 (하드코딩 금지)
- Primary: #6B5B95, Secondary: #F4A460, Background: #FFFAF5
- UX 가이드라인: [docs/specs/design/ux_guidelines.md](docs/specs/design/ux_guidelines.md)

### 코드
- Dart 스타일 가이드 준수
- `flutter analyze` 경고 없이 유지
- 대형 위젯: 별도 파일로 분리 (500줄 이상 지양)

### 아키텍처
- **새 코드는 features/ 아래에 작성** (레거시 위치 X)
- Repository 패턴: 인터페이스 + Mock 분리
- Provider: @riverpod 어노테이션 사용
- Re-export 패턴으로 하위 호환성 유지

---

## Feature별 Provider 매핑

| Feature | Providers | 설명 |
|---------|-----------|------|
| **lessons** | lesson, payment, booking, piece, tip_template | 레슨 관련 전체 |
| **practice** | practice, practice_item, practice_repertoire, metronome, recording, smart_recording | 연습 관련 전체 |
| **students** | student | 학생 관리 |
| **parent_home** | parent, child_profile, user_profile | 학부모 관련 |
| **profile** | invite, teacher_extended_profile | 프로필/초대 |
| **auth** | user_role | 인증/역할 |
| **notifications** | notification | 알림 |
| **onboarding** | onboarding, teacher_profile_repository | 온보딩 |
| **search** | teacher_search, teacher | 검색 |

---

## 문서 구조

| 폴더 | 내용 | Claude 확인 시점 |
|------|------|----------------|
| `docs/architecture.md` | 아키텍처 가이드 | 🔴 작업 시작 전 필수 |
| `docs/refactoring_tasks.md` | 리팩토링 현황 | 구조 변경 작업 시 |
| `docs/requirement/` | 요구사항 | 새 기능 구현 시 |
| `docs/proposal/` | 기획 Q&A | 기획 논의 시 |
| `docs/specs/[domain]/` | 기능 명세 | 해당 도메인 작업 시 |

→ [전체 문서 인덱스](docs/README.md)

---

## 주요 모델

| 모델 | 위치 | 용도 |
|------|------|------|
| Student | `students/domain/entities/` | 학생 정보, 레벨 |
| Lesson | `lessons/domain/entities/` | 레슨 기록, 노트 |
| Payment | `lessons/domain/entities/` | 결제, 입금확인 |
| PracticeTask | `practice/domain/entities/` | 연습 과제 |
| Recording | `practice/domain/entities/` | 녹음 파일 |
| Parent | `parent_home/domain/entities/` | 학부모 정보 |
| Invite | `profile/domain/entities/` | 초대 시스템 |
| Notification | `notifications/domain/entities/` | 알림 |

---

## 구현 현황

### 완료
- 로그인 UI, 선생님/학생/학부모 대시보드
- 학생 관리 (CRUD, 레벨)
- 레슨 캘린더 (월/주 뷰), 레슨 노트/녹음
- 수강료 관리 (2단계 입금확인)
- 연습 시스템 (레퍼토리 연동, 다중 구간)
- 메트로놈 시스템 (엔진, UI, 고양이 인디케이터)
- 녹음 재생 시스템 (웨이브폼, A-B 루프)
- 외부 선생님 등록 (온보딩 3단계)
- 양방향 초대 시스템 (QR/URL/코드)
- 학부모 시스템 (이중 역할, 프로필 스위처)

### 예정
- 푸시 알림 (FCM)
- 뱃지 시스템
- 백엔드 API (FastAPI)
- OAuth 연동

---

## 작업 우선순위

| 순위 | 작업 | 상태 | 긴급도 |
|:----:|------|:----:|:------:|
| 1 | 푸시 알림 | 대기 | 높음 |
| 2 | 뱃지 시스템 | 대기 | 높음 |
| 3 | 백엔드 API (FastAPI) | 대기 | 중간 |
| 4 | OAuth 연동 | 대기 | 중간 |

---

## 문제 해결

```bash
# iOS 빌드 에러
cd ios && pod install && cd .. && flutter clean && flutter pub get

# Android 빌드 에러
cd android && ./gradlew clean && cd .. && flutter clean && flutter pub get

# Provider 코드 생성 에러
dart run build_runner build --delete-conflicting-outputs
```
