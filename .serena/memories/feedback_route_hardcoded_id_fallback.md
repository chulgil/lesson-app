# 라우트 식별자 하드코딩 폴백 금지 — mock 우연 일치 함정

**Why**: 2026-06-12 베타 버그 "시간대 추가해도 무반응". 라우트 빌더의 `queryParameters['teacherId'] ?? 'teacher_1'` 하드코딩 폴백이 remote(베타)에서 조회(가짜 teacher_1)/저장(토큰 본인 UUID) 대상 불일치를 만들었다. **mock 모드는 currentUserId 도 'teacher_1' 이라 우연히 일치 — 위젯테스트/시뮬레이터에서 절대 재현 불가**. E2E 위젯 테스트 2/2 PASS 인데 실기만 실패하면 이 패턴을 의심.

**How to apply**:
- 라우트 식별자 폴백은 `core/router/route_params.dart` 의 `teacherIdParamOrCurrent(context, state)` / `teacherIdExtraOrCurrent` 사용 (currentUserIdProvider 폴백, ProviderScope.containerOf 패턴)
- 신규 라우트에서 `?? 'teacher_1'` / `?? 'student_1'` 류 작성 금지 — grep: `grep -rn "?? 'teacher_1'\|?? 'student_1'" frontend/lib/core/router`
- 디버깅 시 "mock 재현 불가 + remote 만 실패" → mock ID 와 하드코딩 값의 우연 일치 가능성을 1순위 가설로
- 관련 PR: #701 (repo 결함 4개) + #703 (라우트 폴백 8곳 — 본체)
