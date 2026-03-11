# CLAUDE.md - Lessonaza {#overview}

> 마지막 업데이트: 2026-03-11

음악 레슨/연습 관리 앱 (Monorepo: docs + backend + frontend)

## 빠른 참조 {#quick-reference}

| 항목 | 값 |
|------|-----|
| 구조 | Monorepo (docs / backend / frontend) |
| Frontend | Flutter, Riverpod, Go Router, Hive |
| Backend | FastAPI (개발 예정) |
| 플랫폼 | iOS, Android |
| 아키텍처 | Clean Architecture + Feature-based |

## 프로젝트 구조 {#project-structure}

```
lesson-app/
├── docs/                    # 📚 프로젝트 문서
│   ├── architecture.md      # 아키텍처 가이드
│   ├── requirement/         # 요구사항
│   ├── proposal/            # 기획 제안서
│   ├── specs/[domain]/      # 기능 명세
│   ├── schema/entities/     # 엔티티 스키마 (@HiveType, @JsonSerializable)
│   ├── _components/         # UI 컴포넌트 가이드
│   ├── _patterns/           # 디자인 패턴 가이드
│   └── _tokens/             # 디자인 토큰 (색상, 타이포 등)
│
├── backend/                 # 🐍 FastAPI (개발 예정)
│
├── frontend/lib/
│   ├── core/                # 공통 (audio/, router/, widgets/, theme/, models/)
│   ├── features/            # 🔑 기능별 모듈 (Clean Architecture)
│   │   ├── [domain]/
│   │   │   ├── domain/entities/          # 엔티티, Repository 인터페이스
│   │   │   ├── data/repositories/        # Repository 구현체 (Mock)
│   │   │   └── presentation/             # screens/, widgets/, providers/
│   │   ├── lessons/         # 레슨 관리
│   │   ├── practice/        # 연습 관리
│   │   ├── students/        # 학생 관리
│   │   ├── parent_home/     # 학부모 홈
│   │   ├── profile/         # 프로필
│   │   ├── notifications/   # 알림
│   │   ├── onboarding/      # 온보딩
│   │   └── search/          # 선생님 검색
│   ├── models/              # ⚠️ 레거시 (re-export only)
│   ├── providers/           # ⚠️ 레거시 (re-export only)
│   └── repositories/        # ⚠️ 레거시 (re-export only)
└── frontend/ios/Runner/     # iOS 네이티브 (MetronomePlugin 등)
```

> **⚠️ 새 코드는 반드시 `frontend/lib/features/[domain]/` 아래에 작성** (레거시 위치 X)

→ [상세 아키텍처 가이드](docs/architecture.md)

## 명령어 {#commands}

```bash
# Frontend
cd frontend
flutter pub get                                              # 의존성
flutter run                                                  # 실행
dart run build_runner build --delete-conflicting-outputs      # 코드 생성
flutter analyze                                              # 분석

# Backend
cd backend && uv sync && uv run uvicorn app.main:app --reload

# 기기 배포 (데이터 유지하며 배포 권장)
flutter run -d <device_id> --release
# ⚠️ flutter install은 앱 삭제 후 재설치 → 녹음 파일 삭제됨
```

---

## Claude 작업 지침 {#claude-guidelines}

### 📋 작업 시작 전 체크리스트

```
1. docs/architecture.md      → 폴더 구조 파악
2. docs/requirement/         → 요구사항 확인
3. docs/specs/[domain]/      → 관련 스펙 확인
4. docs/refactoring_tasks.md → 리팩토링 현황
```

### 📝 스펙 우선 개발 (Spec-First Development)

> ⚠️ **필수**: 요구사항 → 스펙 문서 → 사용자 승인 → 코드 구현

| 상황 | Claude 행동 |
|------|------------|
| 새 기능 요청 | `docs/specs/[domain]/`에 스펙 작성 → 사용자 확인 → 구현 |
| 기존 기능 수정 | 기존 스펙 확인 → 변경사항 반영 → 사용자 확인 → 구현 |
| 버그 수정 | 스펙과 실제 동작 비교 → 코드 수정 (스펙이 틀리면 함께 수정) |
| 간단한 UI 조정 | 스펙 업데이트 불필요 (사용자 판단) |

**스펙 문서 위치**:
- 도메인 기능: `docs/specs/[domain]/`
- 엔티티 스키마: `docs/schema/entities/` (@HiveType, @JsonSerializable 클래스)
- UI/UX 설계: `docs/specs/design/`

**스펙 필수 포함**: 개요, 상세 동작(플로우/조건/예외), UI 구조, 관련 엔티티/Provider, 변경 이력

### 📁 새 코드 작성 위치

| 항목 | 위치 |
|------|------|
| 모델/엔티티 | `features/[domain]/domain/entities/` |
| Provider | `features/[domain]/presentation/providers/` (@riverpod 어노테이션) |
| 화면 | `features/[domain]/presentation/screens/` |
| 위젯 | `features/[domain]/presentation/widgets/` |
| 라우트 | `core/router/routes/` + `core/router/app_routes.dart` 상수 추가 |

### ✅ 작업 완료 체크리스트

1. [ ] `flutter analyze` 경고 없음
2. [ ] `dart run build_runner build --delete-conflicting-outputs` 코드 생성
3. [ ] Mock Repository에 테스트 데이터 존재 확인
4. [ ] 관련 `docs/specs/` 문서 업데이트
5. [ ] 커밋 메시지 한글 (Conventional Commits)

### 🎨 UI 필수 규칙

**UI 일관성**: 동일 기능은 동일 UI 패턴 사용 → 기존 패턴과 다르게 구현하려면 **반드시 사용자 동의**

**공통 위젯 우선 사용** (`core/widgets/`):
- `selectors/`: LessonCount, LessonDuration, ValidityPeriod, DiscountPercent, BonusCount
- `WeekCalendarWidget`, `StatCard`, `QuickToolButton`, `PracticeCenterButton`
- 새 위젯 작성 전 반드시 기존 공통 위젯 확인 → 있으면 사용 (직접 구현 금지)

**원샷 UX 원칙**: 한 번 탭으로 모든 연관 작업 완료 (알림, 상태, 스케줄 자동 처리)

→ [상세 UX 가이드라인](docs/specs/design/ux_guidelines.md)

---

## 핵심 규칙 {#core-rules}

| 항목 | 규칙 |
|------|------|
| 응답 언어 | 한글 (코드 주석은 영어) |
| 커밋 메시지 | 한글, Conventional Commits (`feat: 기능 추가`) |
| 색상 | `AppColors` 클래스만 사용 (Primary: #6B5B95, Secondary: #F4A460, BG: #FFFAF5) |
| 위젯 크기 | 500줄 이상 지양 → 별도 파일 분리 |
| Repository | 인터페이스 + Mock 분리, @riverpod 사용 |
| 하위 호환 | 레거시 위치에 re-export 패턴 유지 |

### 코드 스타일 예시 {#code-style}

```dart
// Provider pattern example
@riverpod
class LessonNotifier extends _$LessonNotifier {
  @override
  Future<List<Lesson>> build() async {
    return ref.read(lessonRepositoryProvider).getAll();
  }

  Future<void> add(Lesson lesson) async {
    await ref.read(lessonRepositoryProvider).add(lesson);
    ref.invalidateSelf();
  }
}
```

---

## 경계 규칙 {#boundaries}

### Always (항상)
- `@riverpod` 어노테이션 사용
- 새 코드는 `features/[domain]/` 아래만 작성
- `AppColors` 클래스만 사용 (하드코딩 금지)
- 기존 공통 위젯 (`core/widgets/`) 우선 사용
- 스펙 문서 → 사용자 승인 → 코드 구현 순서 준수

### Ask First (먼저 물어볼 것)
- 아키텍처 변경
- 새 패키지 의존성 추가
- 데이터 스키마 변경
- 기존 UI 패턴과 다른 구현

### Never (절대 금지)
- secrets 하드코딩
- 레거시 위치(`lib/models/`, `lib/providers/`)에 새 코드 작성
- 외부 메트로놈 패키지 사용
- 사용자 확인 전 이슈 닫기

---

## Claude가 자주 틀리는 것 {#common-mistakes}

| 오류 | 원인 | 해결 |
|------|------|------|
| 빈 화면 | Repository AutoDispose | `@Riverpod(keepAlive: true)` 추가 |
| mouse_tracker 에러 | Dropdown 내 Row + Expanded | `Flexible` + `isExpanded: true` |
| Dropdown assertion | value가 items에 없음 | 유효성 검증 후 null 처리 |
| Provider not found | 코드 생성 미완료 | `build_runner build` 실행 |
| go_router extra | ShellRoute에서 extra 전달 누락 | `GoRouterState.of(context)` 확인 |
| Mock 데이터 변경 후 크래시 | Hive 캐시된 이전 데이터와 새 enum/타입 충돌 | 앱 삭제 후 재설치 또는 Hive box 초기화 |
| 튜너 음 끊김 | stream + callback 이중 경로로 상태 충돌 | 단일 경로(stream)만 사용, callback 제거 |
| 튜너 불안정 감지 | StabilityFilter에서 낮은 확률 시 smoothedFrequency 미리셋 | probability 미달 시 `_smoothedFrequency = 0` 리셋 필수 |

---

## Issue 기반 작업 {#issue-workflow}

### Claude 행동 지침

사용자가 간단히 요청해도 다음을 수행:
1. 관련 코드/스펙 파악
2. 상세 본문 작성 (문제, 관련 파일, 예상 원인)
3. 라벨 자동 선택 후 이슈 생성

### 라벨 체계

| 카테고리 | 라벨 |
|----------|------|
| 타입 | `bug`, `feature`, `enhancement`, `refactor`, `docs`, `test`, `claude` |
| 우선순위 | `priority: critical/high/medium/low` |
| 도메인 | `domain: lesson/student/parent/practice/payment/schedule/notification/auth/recording/metronome/profile` |
| 상태 | `status: todo/in-progress/blocked/review/done` |

### 워크플로우

```
1. 이슈 생성 + 라벨 지정
2. 브랜치: fix/42-description, feat/15-description, refactor/28-description
3. 커밋: "fix(도메인): 설명\n\nRefs #42"
4. 구현 완료 → status: review (사용자 확인 대기)
5. 사용자 확인 후 → status: done + 이슈 닫기
```

> ⚠️ 기능 구현 후 사용자가 테스트/확인하기 전까지 이슈를 닫지 않습니다.

### 복잡한 작업 (3시간+)

TODO.md로 Phase 기반 관리 → Issue 참조, 세션별 Phase 진행, 완료 시 Issue에 코멘트

---

## 메트로놈 개발 지침 {#metronome-guidelines}

> ⚠️ 반드시 커스텀 `MetronomePlugin`만 사용 (외부 패키지 금지)

| 레이어 | 파일 |
|--------|------|
| Provider | `features/practice/presentation/providers/metronome_provider.dart` |
| Dart Engine | `core/audio/native_metronome_engine.dart` (macOS: `soloud_metronome_engine.dart`) |
| iOS Plugin | `ios/Runner/MetronomePlugin.swift` |
| iOS Engine | `ios/Runner/Audio/MetronomeAudioEngine.swift` |

핵심: `soundPattern: [Bool]` 배열로 쉼표(rest) 패턴 지원, `AppDelegate`에 플러그인 등록 필수

---

## 구현 현황 {#implementation-status}

### 진행중
- 스마트 녹음 트림 후 실제 재생 시간 표시 (Issue #7)
- 연습완료 날짜별 완료 상태 동기화 (Issue #8)

### 최근 완료
- 학생 UX 점검 3차 (#124~#127) — 시작 가이드, 레슨노트 UX, 스케줄 개선, 수기 선생님 관리
- 선생님 UX 점검 2차 (#118~#123) — EditStudent DB 연동, 시작 가이드, 요일별 시간, 피드백 프리셋, 학생 퀵셀렉트
- 선생님 UX 점검 1차 (#104~#112) — 빈 상태 CTA, 스와이프 액션, QuickFeedback 확장, 정렬, 색상 구분
- 과제 대시보드 (Issue #101) — 전체 학생 주간 과제 현황
- 게이미피케이션 Phase 1 (Issue #98) — 포인트/레벨/뱃지 시스템
- 선생님 분석 대시보드 (Issue #97) — 월별 통계/차트/연습률 랭킹

### 예정
- 푸시 알림 (FCM) → 백엔드 API (FastAPI) → OAuth 연동

---

## 문제 해결 {#troubleshooting}

```bash
# iOS 빌드 에러
cd frontend/ios && pod install && cd .. && flutter clean && flutter pub get

# Android 빌드 에러
cd frontend/android && ./gradlew clean && cd .. && flutter clean && flutter pub get

# Provider 코드 생성 에러
cd frontend && dart run build_runner build --delete-conflicting-outputs

# Mock 데이터 변경 후 앱 크래시 (Hive 캐시 충돌)
# 1) 앱 삭제 후 재설치 또는
# 2) flutter clean && flutter run (debug 모드로 먼저 확인)
```

---

# Lessons Learned

## 1. Mock 데이터 대규모 변경 시 반드시 실행 검증 - error-pattern
- **날짜**: 2026-03-06
- **분류**: error-pattern
- **교훈**: 병렬 에이전트로 4개 mock repository를 동시 변경(student 8→12, lesson 8→15, subscription 8→19, schedule card 1→5)한 후 앱이 즉시 크래시. `flutter analyze` 통과해도 런타임 크래시 가능. Hive에 캐시된 이전 데이터와 새 enum/타입 충돌이 원인일 수 있음.
- **조치**: Mock 데이터 변경 후 반드시 `flutter run`으로 실행 검증. 대규모 변경은 단계적으로 진행하고 각 단계마다 실행 확인.

## 2. 오디오 엔진 이벤트 경로는 반드시 단일화 - error-pattern
- **날짜**: 2026-03-06
- **분류**: error-pattern
- **교훈**: TunerEngine에서 `noteStream`(stream)과 `onPitchDetected`(callback) 두 경로로 동시에 노트를 전달하면, provider에서 같은 노트를 2번 처리하여 상태 충돌 발생 (음 감지 → 즉시 사라짐 → 다시 감지 반복).
- **조치**: stream만 사용하고 callback 제거. 오디오 파이프라인에서 데이터 흐름은 항상 단일 경로 유지.

## 3. iPhone 배포 시 provisioning profile 사전 확인 - error-pattern
- **날짜**: 2026-03-06
- **분류**: error-pattern
- **교훈**: `flutter run --release`로 iPhone 배포 시 provisioning profile 에러 빈번. CLI에서 `--allowProvisioningUpdates` 플래그가 flutter에서 지원되지 않음.
- **조치**: 배포 전 Xcode에서 Signing & Capabilities 확인. 문제 시 Xcode에서 직접 빌드하거나 `xcodebuild -allowProvisioningUpdates` 사용.
