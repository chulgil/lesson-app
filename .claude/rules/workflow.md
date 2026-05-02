# 작업 워크플로우 — 개발 순서와 체크리스트

## 작업 시작 전

```
1. docs/SPEC_ROUTING.md  → 작업 유형별 필수/보조/금지 문서 확인
2. docs/specs/[domain]/[domain]_master.md  → 해당 도메인 마스터 (SSOT)
3. docs/architecture.md  → 구조 파악 (필요 시)
```

> ⚠️ `docs/requirement/` 는 HISTORICAL (2025-12 기준). 현재 정책은 각 도메인 마스터 참조.
> ⚠️ `docs/specs/_archive/` 는 사용 금지 (폐기 문서).

## 스펙 우선 개발

> ⚠️ **필수**: 요구사항 → 스펙 문서 → 사용자 승인 → 코드 구현

| 상황 | Claude 행동 |
|------|------------|
| 새 기능 | `docs/specs/[domain]/`에 스펙 작성 → 사용자 확인 → 구현 |
| 기존 수정 | 기존 스펙 확인 → 변경 반영 → 사용자 확인 → 구현 |
| 버그 수정 | 스펙과 동작 비교 → 코드 수정 |

## 새 코드 작성 위치

| 항목 | 위치 |
|------|------|
| 엔티티 | `features/[domain]/domain/entities/` |
| Provider | `features/[domain]/presentation/providers/` (@riverpod) |
| 화면/위젯 | `features/[domain]/presentation/screens/`, `widgets/` |
| 라우트 | `core/router/routes/` + `app_routes.dart` 상수 |

## 작업 완료 체크리스트

1. [ ] `flutter analyze` 경고 없음
2. [ ] `build_runner build` 코드 생성
3. [ ] Mock Repository 테스트 데이터 확인
4. [ ] `docs/specs/` 문서 업데이트 — 매핑 규칙: [doc-sync.md](doc-sync.md)
5. [ ] 커밋 메시지 한글 (Conventional Commits)

## 문서 동기화 (이중 안전장치)

> CH03 패턴: 코드 변경 = 문서 변경. 프롬프트(규칙) + 훅(알림)으로 동기화율 강제.

- 코드 편집 시 `check-doc-sync.sh` 훅이 stderr로 관련 스펙 경로를 안내한다
- 경고가 뜨면 **같은 편집 세션에서** 해당 스펙 문서도 업데이트한다
- 매핑 테이블: [doc-sync.md](doc-sync.md)
