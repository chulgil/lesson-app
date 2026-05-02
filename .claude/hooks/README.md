# Hooks

> 이 폴더의 훅은 **선택적** 입니다. 프로젝트에 맞춰 수정/삭제하세요.

## 훅 타입

- `pre-commit`: 커밋 전 검증 (lint, format, secret scan)
- `pre-push`: 푸시 전 테스트
- `commit-msg`: 커밋 메시지 Conventional Commits 준수 확인

## 설치

```bash
# Git core.hooksPath 사용
git config core.hooksPath .claude/hooks
chmod +x .claude/hooks/*
```

또는 `pre-commit` 프레임워크 사용 시:
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: check-spec-sync
        entry: .claude/hooks/check-spec-sync.sh
        language: system
```

## 언어별 권장 훅

### Flutter
- `dart format --set-exit-if-changed`
- `flutter analyze`
- `flutter test --coverage`

### Python
- `ruff check --fix`
- `ruff format`
- `pytest`

### Java
- `./gradlew spotlessCheck`
- `./gradlew test`

### Go
- `gofmt -l . | grep . && exit 1 || exit 0`
- `go vet ./...`
- `go test ./...`

## 필수 훅 (모든 프로젝트 공통)

- **Secret scan**: `.env` 나 API 키가 커밋에 포함되지 않도록
- **Spec-code sync**: 코드 변경 시 대응하는 spec 파일도 스테이지되었는지

## 예시 훅은 추후 추가됩니다

현재는 README 만 제공. 프로젝트 시작 시 위 템플릿을 참조해 작성하세요.
