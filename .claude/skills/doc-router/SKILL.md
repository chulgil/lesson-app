---
name: doc-router
description: lesson-app 프로젝트의 문서를 앵커 기반으로 빠르게 조회합니다. 전체 파일 대신 특정 섹션만 로드하여 토큰을 80-90% 절약합니다.
allowed-tools: Read, Grep, Glob
---

# Doc Router Skill - Lesson App

lesson-app 프로젝트의 **문서 앵커 인덱스**를 제공하고 특정 섹션을 빠르게 조회합니다.

## 사용 시점

- 특정 문서 섹션만 필요할 때
- 전체 파일 로드 없이 가이드 확인할 때
- 토큰 효율적인 문서 조회가 필요할 때

## CLAUDE.md 앵커 인덱스

### 기본 정보

| 앵커 | 설명 |
|------|------|
| `#overview` | 프로젝트 개요 |
| `#quick-reference` | 빠른 참조 (기술 스택, 상태) |
| `#commands` | Flutter 명령어 |
| `#iphone-deploy` | iPhone 배포 방법 |

### 아키텍처

| 앵커 | 설명 |
|------|------|
| `#project-structure` | Clean Architecture 폴더 구조 |
| `#provider-mapping` | Feature별 Provider 매핑 |
| `#models` | 주요 모델 위치 |
| `#docs-structure` | 문서 구조 |

### 작업 가이드

| 앵커 | 설명 |
|------|------|
| `#issue-workflow` | Issue 기반 작업 방법 |
| `#claude-guidelines` | Claude 작업 지침 |
| `#core-rules` | 핵심 규칙 (언어, 디자인, 코드) |
| `#todo-management` | TODO.md 작업 관리 |

### 현황 및 문제 해결

| 앵커 | 설명 |
|------|------|
| `#implementation-status` | 구현 현황 (완료/진행중/예정) |
| `#priorities` | 작업 우선순위 |
| `#github-issues` | GitHub 이슈 관리 |
| `#troubleshooting` | 문제 해결 (빌드 에러 등) |

## docs/ 문서 구조

```
docs/
├── architecture.md          # 상세 아키텍처 가이드
├── refactoring_tasks.md     # 리팩토링 현황
├── README.md                # 문서 인덱스
├── requirement/             # 요구사항
├── proposal/                # 기획 제안서
└── specs/                   # 기능 명세 (도메인별)
    ├── design/              # UX 가이드라인
    ├── practice/            # 연습 기능 스펙
    ├── metronome/           # 메트로놈 스펙
    ├── recording/           # 녹음 기능 스펙
    └── invite/              # 초대 시스템 스펙
```

## 사용법

### 특정 섹션 조회

```
"CLAUDE.md의 #commands 섹션 보여줘"
"#project-structure 확인해줘"
"#troubleshooting 읽어줘"
```

### 앵커 목록 확인

```
"CLAUDE.md에서 사용 가능한 앵커 알려줘"
```

### 스펙 문서 조회

```
"docs/specs/practice/ 폴더 구조 보여줘"
"녹음 관련 스펙 찾아줘"
```

## 조회 패턴

### Pattern 1: 앵커로 직접 조회 (권장)

```bash
"CLAUDE.md의 #claude-guidelines 섹션만 읽어줘"
```

### Pattern 2: 헤딩 구조 확인 후 조회

```bash
# 1단계: 목차 확인
"CLAUDE.md 헤딩 구조 보여줘"

# 2단계: 필요한 섹션 조회
"#provider-mapping 섹션 보여줘"
```

### Pattern 3: 스펙 문서 검색

```bash
"docs/specs/에서 recording 관련 파일 찾아줘"
```

## 토큰 효율성

| 조회 방식 | 토큰 | 절약률 |
|----------|------|--------|
| 전체 CLAUDE.md 읽기 | ~5,000 | - |
| 목차만 조회 | ~200 | 96% |
| 앵커로 섹션 조회 | ~500 | 90% |

## 자주 사용하는 조회

| 상황 | 요청 |
|------|------|
| 새 기능 구현 시작 | "#claude-guidelines 보여줘" |
| Provider 추가할 때 | "#provider-mapping 확인해줘" |
| 빌드 에러 발생 | "#troubleshooting 읽어줘" |
| Issue 작업 시작 | "#issue-workflow 보여줘" |
| 복잡한 작업 계획 | "#todo-management 확인해줘" |