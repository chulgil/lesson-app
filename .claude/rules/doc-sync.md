# 문서 동기화 규칙 — 코드 변경 = 문서 변경

> 출처: CH03 "문서화 자동화 & 팀 단위 AI 코딩 에이전트 운영 규칙"
> 이중 안전장치: **프롬프트(이 규칙) + 훅(check-doc-sync.sh)** 으로 문서 동기화율 강제.
> 원칙: 코드를 바꿀 때 반드시 관련 스펙 문서를 같은 커밋에서 함께 업데이트.

## 매핑 (CRITICAL)

| 코드 변경 경로 | 업데이트할 문서 |
|----------------|-----------------|
| `frontend/lib/features/lessons/**` | `docs/specs/lesson/` |
| `frontend/lib/features/students/**` | `docs/specs/student/` |
| `frontend/lib/features/notifications/**` | `docs/specs/notification/` |
| `frontend/lib/features/<domain>/**` (나머지 1:1) | `docs/specs/<domain>/` |
| `frontend/lib/core/audio/*metronome*` | `docs/specs/metronome/` |
| `frontend/lib/core/audio/*recording*` | `docs/specs/recording/` |
| `frontend/lib/core/audio/*tuner*` | `docs/specs/tuner/` |
| `frontend/lib/core/router/**` | `docs/architecture.md` |
| `frontend/ios/Runner/Metronome*` | `docs/specs/metronome/` |
| `backend/**/routes|routers|endpoints|api/**` | `docs/specs/backend/` (API 섹션) |
| `backend/**/models|schemas|migration*` | `docs/specs/backend/` (데이터 섹션) |

복수→단수 변환 (`lessons`→`lesson`, `students`→`student`, `notifications`→`notification`)에 주의.

## 동작 흐름

```
1. 코드 파일 편집
2. PostToolUse 훅(check-doc-sync.sh)이 경로 매칭 검사
3. 매칭되는 스펙 폴더가 실제 존재하면 stderr로 알림 출력
4. Claude는 이 알림을 보고 관련 스펙 문서도 함께 편집
5. 코드 + 문서 하나의 커밋으로 동시 반영
```

## Claude 행동 지침

| 상황 | 행동 |
|------|------|
| 훅이 경로를 알려줌 | 해당 스펙 폴더의 관련 .md 파일을 읽고, 변경이 필요한 부분 업데이트 |
| 스펙 폴더는 있지만 관련 .md가 없음 | 새 스펙 파일을 추가하거나, 기존 index 문서에 섹션 추가 |
| 스펙 폴더 자체가 없음 | 신규 도메인이므로 `docs/specs/<domain>/overview.md` 생성 검토 |
| 간단한 버그 수정이라 스펙 영향 없음 | 커밋 본문에 `docs: 스펙 변경 없음 (동작 유지)` 명시 |

## 절대 하지 말 것

- 훅 경고를 무시하고 코드만 커밋
- 스펙과 다른 동작을 구현하면서 스펙을 고치지 않음
- "나중에 문서 업데이트" 라고 남기기 — CH03에서 지적한 팀의 가장 오래된 거짓말

## 커밋 메시지 예시

```
feat(lesson): 레슨 취소 시 수강권 복원 로직 추가

- frontend/lib/features/lessons/ 비즈니스 로직 변경
- docs/specs/lesson/cancel_policy.md 정책 업데이트
```

## 매핑 확장

새 도메인/모듈이 추가되면 두 곳을 모두 업데이트한다.

1. 이 파일의 매핑 테이블
2. `.claude/hooks/check-doc-sync.sh` 의 경로 매칭 블록
