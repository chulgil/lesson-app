# New Feature

$ARGUMENTS 기능을 Feature-First Clean Architecture로 구현하기 위한 스펙을 작성해줘.

## 절차

### 1단계: 기존 코드 분석
- `frontend/lib/features/` 아래 기존 구조 확인
- 유사한 기능이 이미 있는지 확인
- 재사용 가능한 공통 위젯 (`core/widgets/`) 확인

### 2단계: 스펙 문서 작성 (코드 작성 금지)
`docs/specs/[domain]/` 에 스펙 문서를 작성:

```markdown
# [기능명] 스펙

## 개요
## 상세 동작 (플로우/조건/예외)
## UI 구조
## 관련 엔티티 / Provider
## 수락 기준
## 엣지 케이스
```

### 3단계: 사용자 승인 대기
스펙을 사용자에게 보여주고 승인을 받을 것.
**승인 없이 코드를 작성하지 마.**

### 4단계: 구현 (승인 후)
```
frontend/lib/features/[domain]/
├── domain/entities/        # 엔티티
├── data/repositories/      # Mock Repository
└── presentation/
    ├── screens/            # 화면
    ├── widgets/            # 위젯
    └── providers/          # @riverpod Provider
```

### 5단계: 검증
- `flutter analyze` 경고 없음
- `dart run build_runner build --delete-conflicting-outputs` 성공
- Mock Repository에 테스트 데이터 존재
- 관련 스펙 문서 업데이트 완료
