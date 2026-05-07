# 품질 계약 (Harness Contract)

> 이 프로젝트에 적용되는 품질 기준.
> 최종 업데이트: 2026-05-04 (brownfield-scan 수동 반영)

## 프로젝트 스택

| 레이어 | 기술 | 버전 |
|--------|------|------|
| Frontend | Flutter + Riverpod + Go Router + Hive | 3.29.0 |
| Backend | FastAPI + SQLAlchemy + Alembic + PostgreSQL | Python 3.12 |
| 패키지 관리 | pub (Flutter), uv (Python) | — |
| CI/CD | APScheduler (in-process cron) | — |

## 린팅

| 대상 | 명령 | 기준 |
|------|------|------|
| Frontend | `flutter analyze --no-pub` | 에러 0건 |
| Backend | `uv run ruff check .` | 에러 0건 |
| 허용 예외 | `// ignore:` 주석 + 사유 필수 | — |

## 테스팅

| 대상 | 프레임워크 | 명령 | 최소 커버리지 |
|------|-----------|------|-------------|
| Frontend 단위 | `flutter_test` | `flutter test --no-pub` | 80% |
| Backend 단위 | `pytest` | `uv run pytest -x -q` | 80% |
| E2E | Playwright MCP 또는 수동 | — | 핵심 플로우 커버 |

### Frontend 아키텍처 자동 점검 항목

- `flutter --no-version-check test frontend/test/architecture/layer_boundaries_test.dart`
- `flutter --no-version-check test frontend/test/architecture/feature_dependency_contract_test.dart`
- `flutter --no-version-check test frontend/test/architecture/notebook_design_contract_test.dart`
- `flutter --no-version-check test frontend/test/architecture/ux_overlay_label_contract_test.dart`

이 항목은 변경 전/후 `git status`에서 UI 라벨 문구가 변경되었는지 확인되면 반드시 재실행한다.

## 빌드

| 대상 | 명령 |
|------|------|
| Frontend | `flutter build apk --debug --target-platform android-arm64` |
| Backend | `uv run python -m compileall -q .` |
| 코드 생성 | `dart run build_runner build --delete-conflicting-outputs` |

## 아키텍처 규칙

- 모든 도메인 로직은 `features/{domain}/domain/` 이하에만 작성
- UI에서 repository 직접 호출 금지 — Provider 경유 필수
- `@riverpod` 어노테이션만 사용 (수동 Provider 금지)
- 새 코드는 반드시 `features/[domain]/` 아래에 작성 (`core/` 예외)
- 색상: `AppColors`만, UI 텍스트: `AppStrings`만, 타이포: `AppTypography`만

## 유비쿼터스 언어

- SSOT: `.harness/knowledge/glossary.md`
- 신규 엔티티는 FE-BE 동일 클래스명 필수
- Phase 1(interview)에서 용어 수집 → Phase 2(spec)에서 강제 사용

## 스펙 체계

| 위치 | 역할 |
|------|------|
| `docs/specs/{domain}/` | 도메인 마스터 스펙 (영구 SSOT) |
| `.harness/spec/{feature}.md` | feature 작업 스펙 (Phase 6 PASS 후 마스터에 머지) |
| `.harness/knowledge/glossary.md` | 유비쿼터스 언어 SSOT |

## 스펙 독립 승격 규칙 (2026-05-07)

> 마스터 스펙의 특정 섹션이 독립 기능으로 성장하면 별도 스펙으로 분리한다.

| 기준 | 행동 |
|------|------|
| 섹션이 100줄+ OR 백엔드 API 계약 포함 | 독립 스펙 파일로 분리 |
| 분리 시 원본 | 레거시 표시 + 독립 스펙 링크 추가 |
| 관련 스펙 | 이벤트 렌더링 등 교차 영향 스펙도 동시 업데이트 |
| 백엔드 | `backend_spec.md` API 계약에도 반영 |

예시: `enrollment_management_ux_spec.md` §10 → `bulk_teacher_actions_spec.md` 독립 승격

## 기획 완전성 체크리스트 (CRUD+L 패턴) (2026-05-07)

> **모든 기능은 CRUD+L(Create/Read/Update/Delete/List)을 기본으로 갖춘다.**
> 하나라도 누락되면 기획 미완성. 스펙 작성 시 아래 체크리스트를 반드시 통과해야 한다.

| # | 질문 | 예시 (공지 기능) |
|---|------|----------------|
| **C** | 생성할 수 있는가? | 공지 작성 시트 ✅ |
| **R** | 상세를 확인할 수 있는가? | 공지 카드 내용 + 영향 학생 ✅ |
| **U** | 수정할 수 있는가? | 공지 메시지 수정 ⚠️ |
| **D** | 삭제할 수 있는가? | 공지 삭제 ⚠️ |
| **L** | 목록을 확인할 수 있는가? | 공지 이력 화면 ✅ |

### 추가 체크 항목

| # | 질문 | 누락 시 영향 |
|---|------|-----------|
| 6 | 생성 후 **다시 찾을 수** 있는가? | 사용자가 "내가 뭘 했지?" 혼란 |
| 7 | **빈 상태**(0건)에서 안내가 있는가? | 사용자가 기능 미인지 |
| 8 | **에러 상태**에서 복구 가능한가? | 데이터 유실 |
| 9 | 관련 **다른 화면에서 참조** 가능한가? | 고립된 기능 |
| 10 | **상태 변경 이력**이 추적되는가? | 분쟁 시 증거 없음 |

### 유사 서비스 벤치마크 체크

| # | 질문 |
|---|------|
| 11 | 카카오톡/Slack/업계 1위 앱에서 이 기능을 어떻게 제공하는가? |
| 12 | 경쟁사가 제공하는데 우리가 누락한 것은 없는가? |
| 13 | "이 기능을 10번 사용한 사용자"의 관점에서 불편한 점은 없는가? |

> **이 체크리스트는 Phase 2 (spec) 작성 시 필수 통과 항목이다.**
> 하나라도 "아니요"이면 스펙을 보완한 후 Phase 5 (구현)에 진입한다.

## 검증 순서 (mechanical.toml 기준)

> 빠른 게이트 우선: lint → test → build (실패 가능성 큰 것부터)

## Evaluation Pipeline (3-Critic)

| Critic | 역할 | 독립성 |
|--------|------|--------|
| Code Critic | spec 정렬, 보안, 엣지 케이스 | 작성자와 다른 세션 |
| Test Critic | Oracle Problem 점검 (의도 vs 구현 검증) | 코드 작성자와 다른 세션 — **필수** |
| E2E Eval | 스크립트 + 에이전트 탐색 E2E | Playwright MCP 또는 수동 |

Oracle Problem: 같은 AI가 코드+테스트를 쓰면 실제 의도가 아닌 구현 그대로를 테스트하게 되어 정확도가 낮아집니다. Test critic은 반드시 코드 세션과 분리하세요.
