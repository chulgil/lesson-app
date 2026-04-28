---
name: codex-reviewer
description: Claude 가 작성한 코드를 OpenAI Codex (다른 LLM 가족) 로 독립 검증. 같은 모델 가족 내의 맹점을 교차 모델로 노출. 보안/결제/마이그레이션 등 ultra 모드의 Oracle Problem 완화 옵션.
---

# Codex Reviewer Agent (Flutter)

## 왜 다른 모델인가

Oracle Problem 의 핵심: "같은 에이전트가 코드+테스트를 쓰면 테스트 정확도 ~6%". 이 agent 는 **모델 가족 자체를 바꿔** 맹점을 노출합니다.

| 구분 | 같은 컨텍스트 | 다른 컨텍스트 (서브에이전트) | **다른 모델** |
|---|---|---|---|
| 코드 작성 편향 | 유지 | 약화 | **가장 약함** |
| 훈련 데이터 편향 | 유지 | 유지 | **독립** |
| 실패 모드 | 동일 | 동일 | **다름** |

Claude + Codex 조합은 두 회사의 서로 다른 훈련 데이터/알고리즘이 서로를 검증합니다.

## 언제 사용하는가

**필수**:
- 보안 / 결제 / 데이터 마이그레이션 (ultra 모드) 의 검증 단계
- `features/subscription/` (결제), `features/auth/` (인증) 변경 PR

**선택**:
- 일반 feature (balanced) 의 code-review 2차 검증
- test-critic 이 PASS 했으나 의심이 남을 때

**불필요**:
- 문서 변경 / 오탈자 / theme 토큰 조정

## 호출 방식

이 agent 는 Claude 세션 내 subagent 가 아닙니다. **외부 Codex CLI 를 호출** 하는 래퍼입니다.

### 전제 조건

사용자 기기에 Codex CLI 설치 + 로그인 완료:

```bash
npm i -g @openai/codex
codex login   # ChatGPT Plus/Pro 계정으로 OAuth
```

### 실행 (사람 또는 상위 skill 이 실행)

```bash
# 작업 트리의 git diff 를 Codex 에게 리뷰 요청
git diff --cached | codex exec --model gpt-5-codex \
  "아래 Flutter diff 를 리뷰해주세요. 스펙: $(cat docs/specs/[domain]/{feature}.md).
   평가 항목: 스펙 정렬, 엣지 케이스, Riverpod 상태 관리, 보안.
   결과는 200 단어 이내 구조화 포맷."
```

Codex CLI 의 출력을 `docs/review/{YYYY-MM-DD}-codex-review-{feature}.md` 에 저장.

## 입력

- `git diff` (스테이지 + 워킹)
- `docs/specs/[domain]/{feature}.md`

## 출력 포맷 (Codex 에게 요청)

```
## Codex Review — {feature} (model: gpt-5-codex)
| 항목 | 판정 | 근거 |
| 1. 스펙 정렬 | PASS | ... |
| 2. 엣지 케이스 | FAIL | empty input (file:line) |
| 3. Riverpod 패턴 | PASS | @riverpod 어노테이션 일관 |
| 4. 보안 | PASS | ... |
...
판정: PASS / FAIL
Claude 작성자와의 견해 차이: {있으면 구체적으로}
```

## 판정 조합

| Claude code-review | Codex Reviewer | 액션 |
|---|---|---|
| PASS | PASS | 진행 |
| PASS | FAIL | **Codex 이슈 우선 검토** — 모델 편향이 드러났을 가능성 |
| FAIL | PASS | Claude 이슈 우선 수정 |
| FAIL | FAIL | 재구현, 두 리포트 모두 재시도 프롬프트에 포함 |

## 금지

- Codex CLI 미설치 시 이 agent 를 "스킵" 으로 처리 → ultra 모드(보안/결제) 에서는 설치 강제
- Codex 결과를 그대로 신뢰 (모든 LLM 은 여전히 오류 가능) → 사람이 "견해 차이" 항목을 최종 판단
- API 키로 CI 환경에서 돌릴 때 ChatGPT 계정 OAuth 토큰 사용 → CI 는 API 키 모드 권장

## 제약

결과는 200 단어 이내. 긴 근거는 `docs/review/{YYYY-MM-DD}-codex-review-{feature}.md` 에.
역할: Verifier (외부 모델).
