# CLAUDE.md - Lesson App {#overview}

> 마지막 업데이트: 2026-01-03

음악 레슨/연습 관리 앱 (Flutter)

## 빠른 참조 {#quick-reference}

| 항목 | 값 |
|------|-----|
| 기술 스택 | Flutter, Riverpod (@riverpod 코드생성), Go Router, Hive |
| 플랫폼 | iOS, Android |
| 아키텍처 | Clean Architecture + Feature-based |
| 상태 | Phase 1 완료 (100%) |

## 명령어 {#commands}

```bash
flutter pub get                    # 의존성
flutter run                        # 실행
dart run build_runner build --delete-conflicting-outputs  # 코드 생성
flutter analyze                    # 분석
```

### 기기 배포 {#device-deploy}

#### 연결된 기기 확인

```bash
flutter devices                    # 모든 기기 목록
adb devices                        # Android 기기만 확인
```

#### iPhone 배포

```bash
# 데이터 유지하며 배포 (권장)
flutter run -d <device_id> --release

# 완전 재설치 (앱 데이터 삭제됨 - 녹음 파일 포함)
flutter install -d <device_id>
```

> ⚠️ `flutter install`은 앱을 삭제 후 재설치하므로 녹음 파일이 삭제됩니다.
> 개발 중에는 `flutter run --release`를 사용하세요.

**iPhone 무선 디버깅 설정:**
1. Mac과 iPhone을 USB로 연결
2. Xcode → Window → Devices and Simulators
3. 기기 선택 → "Connect via network" 체크
4. USB 분리 후에도 무선으로 배포 가능

#### Android 배포

```bash
# 데이터 유지하며 배포 (권장)
flutter run -d <device_id> --release

# APK 빌드만 (기기 없이)
flutter build apk --release

# 완전 재설치
flutter install -d <device_id>
```

**Android USB 디버깅 설정:**
1. 설정 → 휴대전화 정보 → 소프트웨어 정보 → "빌드 번호" 7번 탭
2. 설정 → 개발자 옵션 → "USB 디버깅" ON
3. USB 연결 시 "USB 디버깅 허용" 팝업에서 허용
4. USB 모드를 "파일 전송(MTP)" 또는 "PTP"로 설정

**Android 무선 디버깅 설정 (Android 11+):**
1. 설정 → 개발자 옵션 → "무선 디버깅" ON
2. "페어링 코드로 기기 페어링" 클릭
3. Mac 터미널에서:
   ```bash
   adb pair <IP>:<PORT>     # 페어링 코드 입력
   adb connect <IP>:<PORT>  # 연결
   ```

> 💡 Android 최소 요구사항: API 21+ (Android 5.0 Lollipop)

---

## 프로젝트 구조 (Clean Architecture) {#project-structure}

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

## Issue 기반 작업 {#issue-workflow}

작업은 GitHub Issue 단위로 진행하여 이력을 관리합니다.

### Issue 생성 시 Claude 행동 지침

사용자가 간단히 요청해도 Claude는 다음을 수행합니다:

1. **관련 코드 파악**: 이슈와 관련된 파일/코드를 먼저 검색
2. **상세 본문 작성**: 문제 설명, 관련 파일, 예상 원인 등 포함
3. **적절한 라벨 자동 선택**: 도메인, 우선순위, 타입 라벨 부착
4. **이슈 생성 후 확인**: 생성된 이슈 URL 제공

#### 예시: 간단한 요청 → 상세한 이슈

```
사용자: "메트로놈 타이밍 버그 이슈 만들어줘"

Claude 행동:
1. lib/core/audio/metronome_engine.dart 등 관련 파일 검색
2. 기존 메트로놈 관련 이슈/스펙 확인
3. 상세 이슈 생성:

gh issue create \
  --title "[BUG] 메트로놈 타이밍 문제" \
  --label "bug,domain: practice,priority: medium" \
  --body "## 문제 설명
메트로놈 타이밍 관련 문제 발생

## 관련 파일
- lib/core/audio/metronome_engine.dart
- lib/features/practice/presentation/providers/metronome_provider.dart

## 관련 스펙
- docs/specs/metronome/

## 예상 원인
[코드 분석 후 작성]
"
```

### Issue 생성 요청 예시

```
# 간단한 요청 (Claude가 알아서 상세 작성)
"메트로놈 타이밍 버그 이슈 만들어줘"
"녹음 파형 안 보이는 버그 이슈 생성해줘"
"학부모 대시보드 기능 이슈 만들어줘"

# 상세 요청 (사용자가 정보 제공)
"버그 이슈 만들어줘: BPM 120 이상에서 타이밍 밀림. 1분 이상 실행 시 발생"
```

### Issue 해결 요청

```
"#42 이슈 해결해줘"
"#42 분석하고 수정 방안 알려줘"
```

### 라벨 체계

| 카테고리 | 라벨 |
|----------|------|
| 타입 | `bug`, `feature`, `enhancement`, `refactor`, `claude` |
| 우선순위 | `priority: critical/high/medium/low` |
| 도메인 | `domain: lesson/student/parent/practice/payment/schedule/notification/auth` |
| 상태 | `status: todo/in-progress/blocked/review/done` |

### 브랜치 네이밍

```bash
fix/42-metronome-timing      # 버그 수정
feat/15-parent-dashboard     # 새 기능
refactor/28-booking-service  # 리팩토링
```

### 커밋에 이슈 연결

```bash
git commit -m "fix(메트로놈): BPM 120 이상 타이밍 밀림 수정

Refs #42"
```

### Issue 해결 워크플로우

1. **이슈 확인**: `gh issue view 42` 또는 `#42 이슈 보여줘`
2. **분석 및 수정**: 관련 코드 파악 → 수정 → 테스트
3. **커밋**: `Refs #42` 또는 `Closes #42` 포함
4. **완료 처리**: 이슈에 해결 내용 코멘트 → 닫기

### 빠른 참조

| 요청 | 예시 |
|------|------|
| 이슈 생성 | "메트로놈 버그 이슈 만들어줘" |
| 이슈 해결 | "#42 해결해줘" |
| 이슈 조회 | "#42 보여줘" |
| 이슈 검색 | "practice 관련 열린 이슈 찾아줘" |
| 이슈 닫기 | "#42 닫아줘" |

---

## Claude 작업 지침 {#claude-guidelines}

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

## 핵심 규칙 {#core-rules}

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

## Feature별 Provider 매핑 {#provider-mapping}

| Feature | Providers | 설명 |
|---------|-----------|------|
| **lessons** | lesson, payment, booking, piece, tip_template | 레슨 관련 전체 |
| **practice** | practice, practice_item, practice_repertoire, metronome, tuner, tuner_combo, recording, smart_recording | 연습 관련 전체 |
| **students** | student | 학생 관리 |
| **parent_home** | parent, child_profile, user_profile | 학부모 관련 |
| **profile** | invite, teacher_extended_profile | 프로필/초대 |
| **auth** | user_role | 인증/역할 |
| **notifications** | notification | 알림 |
| **onboarding** | onboarding, teacher_profile_repository | 온보딩 |
| **search** | teacher_search, teacher | 검색 |

---

## 문서 구조 {#docs-structure}

| 폴더 | 내용 | Claude 확인 시점 |
|------|------|----------------|
| `docs/architecture.md` | 아키텍처 가이드 | 🔴 작업 시작 전 필수 |
| `docs/refactoring_tasks.md` | 리팩토링 현황 | 구조 변경 작업 시 |
| `docs/requirement/` | 요구사항 | 새 기능 구현 시 |
| `docs/proposal/` | 기획 Q&A | 기획 논의 시 |
| `docs/specs/[domain]/` | 기능 명세 | 해당 도메인 작업 시 |

→ [전체 문서 인덱스](docs/README.md)

---

## 주요 모델 {#models}

| 모델 | 위치 | 용도 |
|------|------|------|
| Student | `students/domain/entities/` | 학생 정보, 레벨 |
| Lesson | `lessons/domain/entities/` | 레슨 기록, 노트 |
| Payment | `lessons/domain/entities/` | 결제, 입금확인 |
| PracticeTask | `practice/domain/entities/` | 연습 과제 |
| Recording | `practice/domain/entities/` | 녹음 파일 |
| TunerSettings | `practice/domain/entities/` | 튜너 설정 |
| TunerNote | `practice/domain/entities/` | 튜너 음표 감지 |
| Parent | `parent_home/domain/entities/` | 학부모 정보 |
| Invite | `profile/domain/entities/` | 초대 시스템 |
| Notification | `notifications/domain/entities/` | 알림 |

---

## 구현 현황 {#implementation-status}

### 완료
- 로그인 UI, 선생님/학생/학부모 대시보드
- 학생 관리 (CRUD, 레벨)
- 레슨 캘린더 (월/주 뷰), 레슨 노트/녹음
- 수강료 관리 (2단계 입금확인)
- 연습 시스템 (레퍼토리 연동, 다중 구간)
- 메트로놈 시스템 (엔진, UI, 고양이 인디케이터, 템포 마킹)
- 튜너 시스템 (피치 감지, 원형 12음계, 고양이 피드백, 콤보, 설정 저장)
- 녹음 재생 시스템 (웨이브폼, A-B 루프, 속도 조절, 핀치 줌)
- 스마트 녹음 (앞뒤 무음 자동 트리밍)
- 녹음 초기화 버튼 (전체 녹음 삭제)
- 녹음 날짜별 필터링/정렬
- 대표녹음 시스템 (첫 녹음 자동 지정, 삭제 시 최신순 재지정)
- 메트로놈 미사용 시 BPM null 표시
- 연습완료 시 대표녹음 공유 안내
- 전체 녹음 파일 관리 화면 (섹션 연결 변경, 삭제)
- 녹음 가져오기 기능 (외부 오디오 파일 import)
- 외부 선생님 등록 (온보딩 3단계)
- 양방향 초대 시스템 (QR/URL/코드)
- 학부모 시스템 (이중 역할, 프로필 스위처)
- 레퍼토리 정렬 옵션 (최신순, 오래된순, 이름순)
- 섹션 범위 타입 (전체/줄/마디) 올바른 표시
- 홈/레슨 화면에서 메트로놈/튜너 접근 버튼

### 진행중
- 스마트 녹음 트림 후 실제 재생 시간 표시 (Issue #7)
- 연습완료 날짜별 완료 상태 동기화 (Issue #8)

### 예정
- 푸시 알림 (FCM)
- 뱃지 시스템
- 백엔드 API (FastAPI)
- OAuth 연동

---

## 작업 우선순위 {#priorities}

| 순위 | 작업 | 상태 | 긴급도 |
|:----:|------|:----:|:------:|
| 1 | 푸시 알림 | 대기 | 높음 |
| 2 | 뱃지 시스템 | 대기 | 높음 |
| 3 | 백엔드 API (FastAPI) | 대기 | 중간 |
| 4 | OAuth 연동 | 대기 | 중간 |

---

## GitHub 이슈 관리 {#github-issues}

이 프로젝트는 GitHub Issues를 태스크 관리 도구로 사용합니다.

### 이슈 명령어

```bash
# 이슈 생성
gh issue create --title "제목" --body "내용" --label "라벨"

# 이슈 보기
gh issue view [이슈번호] --json title,body,labels

# 이슈 목록
gh issue list

# 이슈 닫기
gh issue close [이슈번호] --comment "완료 내용"

# 라벨 추가
gh issue edit [이슈번호] --add-label "라벨1,라벨2"
```

### 라벨 구조

| 카테고리 | 라벨 | 설명 |
|----------|------|------|
| **타입** | `bug` | 버그 수정 |
| | `feature` | 새 기능 |
| | `enhancement` | 기능 개선 |
| | `refactor` | 리팩토링 |
| | `docs` | 문서 작업 |
| | `test` | 테스트 |
| **우선순위** | `priority: critical` | 긴급 - 즉시 해결 |
| | `priority: high` | 높음 |
| | `priority: medium` | 보통 |
| | `priority: low` | 낮음 |
| **상태** | `status: todo` | 시작 전 |
| | `status: in-progress` | 진행 중 |
| | `status: review` | 검토 중 |
| | `status: blocked` | 차단됨 |
| | `status: done` | 완료 |
| **도메인** | `domain: lesson` | 레슨 관리 |
| | `domain: practice` | 연습 기록 |
| | `domain: recording` | 녹음 기능 |
| | `domain: student` | 학생 관리 |
| | `domain: payment` | 결제/정산 |
| | `domain: parent` | 학부모 연동 |
| | `domain: schedule` | 스케줄/캘린더 |
| | `domain: notification` | 알림 |
| | `domain: metronome` | 메트로놈 |
| | `domain: auth` | 인증/로그인 |
| | `domain: profile` | 프로필 관리 |
| **기타** | `claude` | Claude 작업 |

### 이슈 워크플로우

1. **이슈 생성**: 기능/버그 발견 시 이슈 생성
2. **라벨 지정**: 타입 + 도메인 + 우선순위 라벨 추가
3. **작업 시작**: `status: in-progress` 라벨로 변경
4. **구현 완료**: `status: review` 라벨로 변경 (사용자 확인 대기)
5. **사용자 확인 후**: `status: done` 라벨 + 이슈 닫기

> ⚠️ **중요**: 기능 구현 후 사용자가 테스트/확인하기 전까지 이슈를 닫지 않습니다.

---

## TODO.md 작업 관리 {#todo-management}

복잡한 작업(3시간+, 여러 세션)은 TODO.md로 Phase 기반 관리합니다.

### 도구 선택 기준

| 작업 시간 | 도구 | 이유 |
|----------|------|------|
| < 1시간 | Issue + TodoWrite | 자동 추적으로 충분 |
| 1-3시간 | Issue + TodoWrite | `/sc:spawn` 자동 분해 |
| > 3시간 | Issue + TODO.md | 세션 간 Phase 유지 필요 |

### TODO.md 형식

```markdown
## [작업명] (#이슈번호)

**Goal**: 목표
**Issue**: https://github.com/user/repo/issues/번호

---

### Phase 1: 분석 (예상 시간) ✅ COMPLETE

- [x] 작업 항목
  - **Result**: 결과 기록
  - **Commit**: abc1234

### Phase 2: 구현 (예상 시간) → IN PROGRESS

- [x] 완료된 항목
- [ ] 진행중 항목
- [ ] 예정 항목

---

## Summary
**Progress**: Phase 2 (40%)
**Next**: 다음 작업
**Blockers**: 없음
```

### 워크플로우

```
1. Issue 생성 → 전체 목표 정의
2. TODO.md에 Phase 계획 작성
3. 세션별로 해당 Phase 작업
4. 세션 종료 시 /sc:save로 저장
5. 완료 시 Issue에 요약 코멘트 → 닫기
```

### Issue ↔ TODO.md 연동

```markdown
# TODO.md에서 Issue 참조
## BookingService 리팩토링 (#55)
**Issue**: https://github.com/chulgil/lesson-app/issues/55

# 완료 후 Issue에 코멘트
gh issue comment 55 --body "Phase 2 완료: BookingCreator, BookingNotifier 분리"
```

---

## 문제 해결 {#troubleshooting}

```bash
# iOS 빌드 에러
cd ios && pod install && cd .. && flutter clean && flutter pub get

# Android 빌드 에러
cd android && ./gradlew clean && cd .. && flutter clean && flutter pub get

# Provider 코드 생성 에러
dart run build_runner build --delete-conflicting-outputs
```
