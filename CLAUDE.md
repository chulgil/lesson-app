# CLAUDE.md - Lessonaza

> 마지막 업데이트: 2026-03-27

음악 레슨/연습 관리 앱 (Monorepo: docs + backend + frontend)

## 빠른 참조

| 항목 | 값 |
|------|-----|
| 구조 | Monorepo (docs / backend / frontend) |
| Frontend | Flutter 3.29.0, Riverpod, Go Router, Hive |
| Backend | FastAPI (개발 예정) |
| 플랫폼 | iOS, Android, macOS |
| 아키텍처 | Clean Architecture + Feature-based |

## 프로젝트 구조

```
lesson-app/
├── docs/                    # 요구사항, 스펙, 스키마, 아키텍처
├── backend/                 # FastAPI (개발 예정)
├── frontend/lib/
│   ├── core/                # 공통 (audio/, router/, widgets/, theme/, utils/)
│   └── features/[domain]/   # 🔑 기능별 모듈
│       ├── domain/entities/
│       ├── data/repositories/
│       └── presentation/    # screens/, widgets/, providers/
└── frontend/ios/Runner/     # iOS 네이티브 (MetronomePlugin 등)
```

> **⚠️ 새 코드는 반드시 `features/[domain]/` 아래에 작성** (레거시 `lib/models/`, `lib/providers/` 금지)

→ [상세 아키텍처](docs/architecture.md)

## 명령어

```bash
cd frontend
flutter pub get                                              # 의존성
flutter run                                                  # 실행
dart run build_runner build --delete-conflicting-outputs      # 코드 생성
flutter analyze                                              # 분석
flutter run -d <device_id> --release                         # 기기 배포
```

---

## 작업 지침

### 작업 시작 전

```
1. docs/architecture.md  → 구조 파악
2. docs/specs/[domain]/  → 관련 스펙 확인
3. docs/requirement/     → 요구사항 확인
```

### 스펙 우선 개발

> ⚠️ **필수**: 요구사항 → 스펙 문서 → 사용자 승인 → 코드 구현

| 상황 | Claude 행동 |
|------|------------|
| 새 기능 | `docs/specs/[domain]/`에 스펙 작성 → 사용자 확인 → 구현 |
| 기존 수정 | 기존 스펙 확인 → 변경 반영 → 사용자 확인 → 구현 |
| 버그 수정 | 스펙과 동작 비교 → 코드 수정 |

### 새 코드 작성 위치

| 항목 | 위치 |
|------|------|
| 엔티티 | `features/[domain]/domain/entities/` |
| Provider | `features/[domain]/presentation/providers/` (@riverpod) |
| 화면/위젯 | `features/[domain]/presentation/screens/`, `widgets/` |
| 라우트 | `core/router/routes/` + `app_routes.dart` 상수 |

### 작업 완료 체크리스트

1. [ ] `flutter analyze` 경고 없음
2. [ ] `build_runner build` 코드 생성
3. [ ] Mock Repository 테스트 데이터 확인
4. [ ] `docs/specs/` 문서 업데이트
5. [ ] 커밋 메시지 한글 (Conventional Commits)

---

## UI 필수 규칙

**⚠️ 코딩 전 필수 조회 (HARD-GATE):**
1. `AppColors` 클래스 → 색상 확인 (없으면 상수 추가)
2. `core/utils/` → 기존 유틸 사용 (NameUtils, date_format_utils 등)
3. `core/widgets/` → 기존 공통 위젯 확인

**공통 유틸 필수 사용:**
- 이름: `NameUtils.givenName()` | 날짜: `formatDateYMD()` | 악기색상: `InstrumentColors.getColor()`
- 스케줄 뮤트: `AppColors.scheduleMutedBackground`, `AppColors.scheduleMutedAccent`

**원샷 UX**: 한 번 탭으로 모든 연관 작업 완료 → [UX 가이드라인](docs/specs/design/ux_guidelines.md)

---

## 핵심 규칙

| 항목 | 규칙 |
|------|------|
| 응답 언어 | 한글 (코드 주석은 영어) |
| 커밋 메시지 | 한글, Conventional Commits |
| 색상 | `AppColors`만 사용 (Primary: #6B5B95, BG: #FFFAF5) |
| 위젯 크기 | 500줄 이상 → 별도 파일 분리 |
| Repository | 인터페이스 + Mock 분리, @riverpod 사용 |

### Always
- `@riverpod` 어노테이션 사용
- 새 코드는 `features/[domain]/` 아래만 작성
- `AppColors` 클래스만 사용 (하드코딩 금지)
- 기존 공통 위젯 (`core/widgets/`) 우선 사용

### Ask First
- 아키텍처 변경, 새 패키지 추가, 데이터 스키마 변경, 기존 UI 패턴과 다른 구현

### Never
- `Color(0x...)` 하드코딩, `lesson.studentName` 직접 표시, 인라인 날짜 포맷
- 레거시 위치에 새 코드 작성, 외부 메트로놈 패키지, 사용자 확인 전 이슈 닫기

---

## 자주 틀리는 것

| 오류 | 원인 | 해결 |
|------|------|------|
| 빈 화면 | Repository AutoDispose | `@Riverpod(keepAlive: true)` |
| mouse_tracker | Dropdown 내 Row+Expanded | `Flexible` + `isExpanded: true` |
| Provider not found | 코드 생성 미완료 | `build_runner build` 실행 |
| go_router extra 누락 | ShellRoute에서 extra 미전달 | `GoRouterState.of(context)` |
| Mock 변경 후 크래시 | Hive 캐시 충돌 | 앱 삭제 후 재설치 |
| 0.5px OVERFLOW | BoxDecoration border 침범 | border를 별도 Container로 분리 |

---

## 분리된 규칙 파일 (`.claude/rules/`)

| 파일 | 내용 |
|------|------|
| `ux-rules.md` | UX 위반 방지 규칙 + grep 패턴 |
| `tech-patterns.md` | 기술 에러 패턴 (Provider/Mock/iOS/CRUD) |
| `design-principles.md` | 아키텍처 설계 원칙 (SSOT/완전성/데이터모델) |
| `data-privacy.md` | 개인정보 접근 규칙 (보안 격리) |
| `issue-workflow.md` | 이슈 생성·라벨·브랜치·커밋 워크플로우 |
| `metronome-guide.md` | 메트로놈 커스텀 플러그인 개발 지침 |
| `troubleshooting.md` | iOS/Android/Provider 빌드 에러 해결 |
