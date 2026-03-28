# 작업 워크플로우 — 개발 순서와 체크리스트

## 작업 시작 전

```
1. docs/architecture.md  → 구조 파악
2. docs/specs/[domain]/  → 관련 스펙 확인
3. docs/requirement/     → 요구사항 확인
```

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
4. [ ] `docs/specs/` 문서 업데이트
5. [ ] 커밋 메시지 한글 (Conventional Commits)
