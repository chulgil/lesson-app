# CLAUDE.md - Lessonaza

> 마지막 업데이트: 2026-04-28

음악 레슨/연습 관리 앱 — Flutter 3.29.0, Riverpod, Go Router, Hive | Clean Architecture + Feature-based

## 프로젝트 구조

```
lesson-app/
├── docs/                    # 요구사항, 스펙, 스키마, 아키텍처
├── backend/                 # FastAPI (개발 예정)
├── frontend/lib/
│   ├── core/                # 공통 (audio/, router/, widgets/, theme/, utils/)
│   └── features/[domain]/   # 기능별 모듈
└── frontend/ios/Runner/     # iOS 네이티브 (MetronomePlugin 등)
```

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

**Ask First**: 아키텍처 변경, 새 패키지 추가, 데이터 스키마 변경
**Never**: `Color(0x...)`, 레거시 위치에 새 코드, 사용자 확인 전 이슈 닫기

## 규칙 파일 (`.claude/rules/`)

| 파일 | 내용 |
|------|------|
| `workflow.md` | 작업 순서, 스펙 우선 개발, 완료 체크리스트 |
| `doc-sync.md` | 코드 변경 시 스펙 문서 동기화 매핑 (훅 + 규칙 이중 안전장치) |
| `ux-rules.md` | UX 위반 방지 + HARD-GATE + grep 패턴 |
| `tech-patterns.md` | 기술 에러 패턴 (Provider/Mock/iOS/CRUD/레이아웃) |
| `design-principles.md` | 아키텍처 설계 원칙 (SSOT/완전성/데이터모델) |
| `data-privacy.md` | 개인정보 접근 규칙 (보안 격리) |
| `issue-workflow.md` | 이슈 생성·라벨·브랜치·커밋 워크플로우 |
| `metronome-guide.md` | 메트로놈 커스텀 플러그인 개발 지침 |
| `troubleshooting.md` | iOS/Android/Provider 빌드 에러 해결 |
| `scenario-testing.md` | 백엔드 시나리오 테스트 규칙 |
| `seed-data.md` | 백엔드 시드 데이터 자동 감지/실행 규칙 |

## 검증 에이전트 (`.claude/agents/`)

Oracle Problem (같은 AI 가 코드+테스트 작성 시 정확도 ~6%) 완화를 위해 별개 컨텍스트로 격리 호출.

| 에이전트 | 역할 | 사용 시점 |
|------|------|----------|
| `architect.md` | 아키텍처 설계 검토 | 새 기능 / 구조 변경 |
| `market-researcher.md` | 시장 조사 | 신규 기능 기획 |
| `test-critic.md` | 테스트가 spec 을 검증하는지 vs 구현 복사인지 판별 | 테스트 작성 후 |
| `security-reviewer.md` | Flutter 보안 12-항목 (시크릿/Hive/딥링크/플랫폼 채널) | 보안/결제/인증 변경 |
| `codex-reviewer.md` | OpenAI Codex 외부 모델 교차 검증 | ultra 모드 (보안/결제/마이그레이션) |
