---
name: todo-manage
description: 복잡한 작업을 Phase 기반 TODO.md로 관리합니다.
allowed-tools: Read, Edit, Write
---

# TODO Manage Skill - Lesson App

복잡한 작업(3시간+, 여러 세션)을 **Phase 기반 TODO.md**로 관리합니다.

## 사용 시점

- 3시간 이상 걸리는 작업
- 여러 세션에 걸쳐 진행되는 작업
- 복잡한 리팩토링/마이그레이션
- 여러 파일에 걸친 대규모 변경

## 도구 선택 기준

| 작업 시간 | 도구 | 이유 |
|----------|------|------|
| < 1시간 | Issue + TodoWrite | 자동 추적으로 충분 |
| 1-3시간 | Issue + TodoWrite | `/sc:spawn` 자동 분해 |
| > 3시간 | Issue + TODO.md | 세션 간 Phase 유지 필요 |

## TODO.md 위치

```
프로젝트 루트/TODO.md
```

## Phase 기반 형식

```markdown
## [작업명] (#이슈번호)

**Goal**: 달성하려는 목표
**Issue**: https://github.com/chulgil/lesson-app/issues/번호
**Started**: YYYY-MM-DD

---

### Phase 1: 분석 (예상 시간) ✅ COMPLETE

- [x] 작업 항목 1
  - **Result**: 실제 결과 기록
  - **Commit**: abc1234
- [x] 작업 항목 2
  - **Result**: 결과
  - **Risk**: 발견된 리스크 (있다면)

### Phase 2: 구현 (예상 시간) → IN PROGRESS

- [x] 완료된 항목
  - **Result**: 결과
  - **Commit**: def5678
- [ ] 진행중 항목
- [ ] 예정 항목

### Phase 3: 테스트 (예상 시간)

- [ ] 유닛 테스트
- [ ] 통합 테스트
- [ ] 사용자 테스트

---

## Summary
**Progress**: Phase 2 진행중 (40%)
**Next**: 다음에 해야 할 작업
**Blockers**: 없음 (또는 차단 요소)
**Last Updated**: YYYY-MM-DD HH:MM
```

## 상태 표시

| 상태 | 표시 |
|------|------|
| 완료 | `✅ COMPLETE` |
| 진행중 | `→ IN PROGRESS` |
| 대기 | (표시 없음) |
| 차단됨 | `⛔ BLOCKED` |

## 작업 항목 속성

| 속성 | 설명 | 필수 |
|------|------|:----:|
| `Result` | 작업 결과 | ✅ |
| `Commit` | 관련 커밋 해시 | ⭕ |
| `Risk` | 발견된 리스크 | ⭕ |
| `Effort` | 실제 소요 시간 | ⭕ |

## 사용법

```
"이 작업 TODO.md로 관리하자"
"TODO.md Phase 2 진행상황 업데이트해줘"
"다음 세션에서 이어서 할 수 있게 TODO.md 정리해줘"
```

## 워크플로우

### 1. 작업 시작
```
1. Issue 생성 → 전체 목표 정의
2. TODO.md에 Phase 계획 작성
3. Phase 1부터 순차 진행
```

### 2. 세션 중
```
1. 현재 Phase의 작업 항목 진행
2. 완료된 항목에 Result 기록
3. 커밋 시 Commit 해시 기록
```

### 3. 세션 종료
```
1. Summary 섹션 업데이트
2. /sc:save로 컨텍스트 저장
3. 다음 작업 명시
```

### 4. 작업 완료
```
1. 모든 Phase 완료 확인
2. Issue에 요약 코멘트
3. Issue 닫기
4. TODO.md 삭제 또는 아카이브
```

## Issue ↔ TODO.md 연동

```markdown
# TODO.md에서 Issue 참조
## BookingService 리팩토링 (#55)
**Issue**: https://github.com/chulgil/lesson-app/issues/55

# 완료 후 Issue에 코멘트
gh issue comment 55 --body "Phase 2 완료: BookingCreator, BookingNotifier 분리

결과:
- BookingService 1200줄 → 3개 클래스로 분리
- 테스트 커버리지 60% → 85%

Commits: abc1234, def5678"
```

## 예시: 실제 TODO.md

```markdown
## BookingService 리팩토링 (#55)

**Goal**: 1200줄 BookingService를 Clean Architecture로 분리
**Issue**: https://github.com/chulgil/lesson-app/issues/55
**Started**: 2026-01-03

---

### Phase 1: 분석 (1시간) ✅ COMPLETE

- [x] 현재 BookingService 구조 분석
  - **Result**: Creator, Validator, Notifier 역할 혼재
  - **Effort**: 45분
- [x] 의존성 그래프 작성
  - **Result**: 12개 파일에서 참조 중
  - **Risk**: LessonScreen과 강한 결합

### Phase 2: 분리 (3시간) → IN PROGRESS

- [x] BookingCreator 분리
  - **Result**: 350줄 → 독립 클래스
  - **Commit**: abc1234
- [ ] BookingValidator 분리
- [ ] BookingNotifier 분리

### Phase 3: 테스트 (1시간)

- [ ] BookingCreator 유닛 테스트
- [ ] 통합 테스트 수정

---

## Summary
**Progress**: Phase 2 (33%)
**Next**: BookingValidator 분리
**Blockers**: 없음
**Last Updated**: 2026-01-03 14:30
```

## 체크리스트

- [ ] Issue가 먼저 생성되었는가?
- [ ] Phase가 논리적 단위로 분리되었는가?
- [ ] 각 작업 항목이 구체적인가?
- [ ] Summary가 최신 상태인가?
