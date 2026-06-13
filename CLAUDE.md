# CLAUDE.md - Lessonaza

> 마지막 업데이트: 2026-05-04

음악 레슨/연습 관리 앱 — Flutter 3.29.0, Riverpod, Go Router, Hive | Clean Architecture + Feature-based

## 프로젝트 구조

```
lesson-app/
├── docs/                    # 요구사항, 스펙(영구 마스터), 스키마, 아키텍처
├── .harness/                # cg-harness 7-Phase 워크플로우 (.harness/README.md 참조)
├── backend/                 # FastAPI
├── frontend/lib/
│   ├── core/                # 공통 (audio/, router/, widgets/, theme/, utils/)
│   └── features/[domain]/   # 기능별 모듈
└── frontend/ios/Runner/     # iOS 네이티브 (MetronomePlugin 등)
```

### cg-harness (`.harness/`)

새 feature는 7-Phase 워크플로우로 진행: `/new-feature` 또는 `/phase N`

```
Phase 0: brownfield-scan → Phase 1: interview → Phase 2: spec
→ Phase 3: visuals → Phase 4: decomposition → Phase 5: execution → Phase 6: evaluation
```

- 스펙 체계: `docs/specs/` (영구 마스터) ↔ `.harness/spec/` (feature 작업 스펙 → Phase 6 후 마스터에 머지)
- 유비쿼터스 언어: `.harness/knowledge/glossary.md` (SSOT)

> **⚠️ 새 코드는 반드시 `features/[domain]/` 아래에 작성** → [상세 아키텍처](docs/architecture.md)

## 명령어

```bash
cd frontend
flutter pub get                                              # 의존성
flutter run                                                  # 실행
dart run build_runner build --delete-conflicting-outputs      # 코드 생성
flutter analyze                                              # 분석
```

## 핵심 규칙

| 항목 | 규칙 |
|------|------|
| 응답 언어 | 한글 (코드 주석은 영어) |
| 커밋 메시지 | 한글, Conventional Commits |
| 색상 | `AppColors`만 사용 (하드코딩 금지) |
| Provider | `@riverpod` 어노테이션, `features/[domain]/` 아래만 |
| 위젯 크기 | 500줄 이상 → 별도 파일 분리 |
| UI 텍스트 | `AppStrings` 상수 사용 (하드코딩 금지, 다국어 대비) |
| 스와이프 액션 (4원칙) | 1) 우→좌 관리 맥락별 1개 (삭제 `destructive` / 편집 `normal`) / 2) 양방향 최대 2개, 초과 시 BottomSheet / 3) 모든 destructive=확인 다이얼로그 / 4) 좌→우=편의 (`convenience` 녹색). 스펙: `docs/_components/swipe_action.md`, 룰: `.claude/rules/ux-rules.md` |

**Ask First**: 아키텍처 변경, 새 패키지 추가, 데이터 스키마 변경
**Never**: `Color(0x...)`, 레거시 위치에 새 코드, 사용자 확인 전 이슈 닫기

## 규칙 파일 (`.claude/rules/`)

| 파일 | 내용 |
|------|------|
| **워크플로우** | |
| `workflow.md` | 7-Phase 작업 순서, 스펙 우선 개발, 완료 체크리스트 |
| `worktree-parallel-workflow.md` | **tmux + git worktree 병렬 개발 강제** (main 직접 작업 금지, 검증 통과 후만 merge) |
| `doc-sync.md` | 코드 변경 시 스펙 문서 동기화 매핑 (훅 + 규칙 이중 안전장치) |
| `glossary-sync.md` | 유비쿼터스 언어 강제 (glossary SSOT + FE-BE 명칭 일치) |
| `issue-workflow.md` | 이슈 생성·라벨·브랜치·커밋 워크플로우 |
| `git-workflow-v2.md` | PR/커밋/브랜치 규칙 |
| **코딩 원칙** | |
| `golden-principles.md` | 12가지 핵심 원칙 (TDD/Immutability/Surgical/증거기반 등) |
| `coding-style.md` | Immutability, 파일 크기, 에러 처리 |
| `design-principles.md` | 아키텍처 설계 원칙 (SSOT/완전성/데이터모델) |
| `domain-linter.md` | 도메인 린�� — 파일명/클래스명/임포트/폴더 규칙 |
| `interaction.md` | 가정 명시, 결론 우선, 불확실성 표현 |
| **검증** | |
| `verification.md` | 증거 기반 완료 (Iron Law + Red-Green 검증) |
| `rubric-evaluation.md` | 4기준 자가평�� (완성도/견고성/일관성/간결성) |
| `adaptive-quality.md` | 작업 난이도별 검증 강도 (ultra/balanced/fast) |
| **UI/UX** | |
| `ux-rules.md` | UX 위반 방지 + HARD-GATE + grep 패턴 |
| `frontend-verify.md` | Playwright 스크린샷 기반 회귀 검증 |

### 공통 UI 패턴

- 행 단위 관리 액션은 `docs/_components/swipe_action.md`와 `frontend/lib/core/widgets/swipe_action_tile.dart`를 우선 사용한다.
- **swipe 4원칙 (2026-06-13 방향+tone — HARD-GATE)**:
  1. 우→좌 관리 액션은 맥락별 1개 — 삭제(`SwipeActionTone.destructive`) 또는 편집(`normal`). 한 방향 2개 이상 금지.
  2. 양방향 최대 2개(관리 1 + 편의 1). 3개 이상은 행 탭 → `showModalBottomSheet` 안에 `ListTile` 로 나열.
  3. 모든 destructive 는 `showDialog<AlertDialog>` 로 확인. 영향도 있으면 강화 메시지 (영향 카운트 포함). 편의·편집은 즉시 실행.
  4. 좌→우=편의(`convenience` 녹색 `paperOk`), 왼쪽 노출 — 없으면 단방향. 방향 의미는 전 화면 공통.
- 스와이프 액션을 도입한 행에는 동일 기능의 trailing 아이콘 버튼/PopupMenuButton 을 중복 배치하지 않는다.
- 자녀/관계처럼 destructive 메타포가 부적절한 카드는 swipe 적용하지 않고 BottomSheet 다중 액션만 사용.
- 삭제 후에도 요일/카테고리 같은 그룹 맥락은 유지하고 비어 있는 상태 라벨로 표시한다.
| **기술 가이드** | |
| `tech-patterns.md` | 기술 에러 패턴 (Provider/Mock/iOS/CRUD/레이아웃) |
| `metronome-guide.md` | 메트로놈 커스텀 플러그인 개발 지침 |
| `troubleshooting.md` | iOS/Android/Provider 빌드 에러 해결 |
| `date-calculation.md` | 날짜/시간 계산 (LLM 산�� 금지, 시스템 도구 사용) |
| **보안/프라이버시** | |
| `security.md` | 보안 체크리스트, 시크릿 관리 |
| `data-privacy.md` | 개인정보 접근 규칙 (보안 격리) |
| **백엔드** | |
| `scenario-testing.md` | 백엔드 시나리오 테스트 규칙 |
| `seed-data.md` | 백엔드 시드 데이터 자동 감지/실행 규칙 |
| **하네스 운영** | |
| `skill-loading.md` | 2단��� 스킬 로딩 (토큰 절약) |
| `subagent-output.md` | 서브에이전트 결과 포맷 (200단어 제한) |
| `lore-commit.md` | git trailer 의사결정 기록 (directive/constraint/rejected) |
| `hash-anchored-edit.md` | xxhash 기반 정밀 편집 (긴 파일 안전 수정) |

## Matt Pocock 기반 스킬

`mattpocock/skills`의 engineering 패턴을 Lessonaza 경로에 맞춰 적용한다.

| 스킬 | 사용 시점 |
|------|----------|
| `matt-grill-with-docs` | 기능 착수 전 요구사항·도메인 용어·결정사항 정리 |
| `matt-zoom-out` | 특정 파일/기능의 전체 시스템 맥락이 필요할 때 |
| `matt-to-issues` | spec/PRD를 독립 실행 가능한 vertical slice 이슈로 분해할 때 |

## 검증 에이전트 (`.claude/agents/`)

Oracle Problem (같은 AI 가 코드+테스트 작성 시 정확도 ~6%) 완화를 위해 별개 컨텍스트로 격리 호출.

| 에이전트 | 역할 | 사용 시점 |
|------|------|----------|
| `architect.md` | 아키텍처 설계 검토 | 새 기능 / 구조 변경 |
| `market-researcher.md` | 시장 조사 | 신규 기능 기획 |
| `test-critic.md` | 테스트가 spec 을 검증하는지 vs 구현 복사인지 판별 | 테스트 작성 후 |
| `security-reviewer.md` | Flutter 보안 12-항목 (시크릿/Hive/딥링크/플랫폼 채널) | 보안/결제/인증 변경 |
