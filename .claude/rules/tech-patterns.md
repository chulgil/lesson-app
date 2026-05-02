# Tech Patterns

> 언어 중립적 구현 원칙. 언어별 구체 가이드는 해당 feature 스펙에 기술.

## 1. Immutability (필수)

- 기존 객체를 수정하지 마세요. 새 객체를 생성하세요.
- Flutter: `copyWith` 사용. Python: `dataclasses.replace` 또는 `frozen=True`. Java: record. Go: new struct.

## 2. 작은 파일, 작은 함수

| 대상 | 최대 |
|------|------|
| 파일 | 800 라인 (일반적으로 200-400) |
| 함수 | 50 라인 |
| 중첩 | 4 레벨 |

초과 시 분해.

## 3. 시스템 경계 검증

외부 입력(사용자, API, 파일)은 **반드시** 검증:
- Flutter: `freezed` + `json_serializable` 의 custom validator
- Python: `pydantic` 또는 `zod` 스타일 스키마
- Java: Bean Validation (`@NotNull`, `@Size`)
- Go: struct tag 기반 검증 (`go-playground/validator`)

내부 함수는 신뢰. 이중 검증은 오히려 안티패턴.

## 4. Secret 은 환경변수

하드코딩 금지. `.env` 파일은 git ignore.

## 5. Feature 기반 디렉토리

레이어별이 아닌 **도메인별** 폴더:
```
features/
├── {feature-a}/
│   ├── domain/       # 엔티티, 리포지토리 인터페이스
│   ├── data/         # 리포지토리 구현
│   └── presentation/ # UI, 프로바이더
```

## 6. Surgical Changes

요청된 라인만 변경. 주변 리팩토링 금지.
- "while I'm here" 금지
- 단일 커밋 = 단일 논리 변경
- 의도치 않은 포매팅 변경이 diff 를 오염시키면 별도 커밋으로 분리

## 7. 테스트 배치

- 단위 테스트: 소스 근처 또는 `tests/unit/`
- 통합 테스트: `tests/integration/`
- E2E 테스트: `tests/e2e/` 또는 `integration_test/` (Flutter)

## 8. 에러 처리

모든 외부 호출은 `try/catch` 또는 `Result<T, E>`. 조용히 삼키지 마세요.
사용자에게 보이는 에러 메시지는 기술적 용어 금지.
