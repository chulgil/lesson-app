# Returning Student Lesson Request Review

> 2026-05-04 | Status: review note

## Problem

기존에 레슨을 받았던 선생님에게 다시 신청할 때 현재 UI는 `다시 시작하기`에서 `UnifiedLessonRequestScreen`으로 바로 진입한다. 이 경로는 `isReturningStudent=true`와 이전 악기 프리필만 보장한다.

오래 전 수강 이력이 있는 경우 선생님의 가능 요일, 가능 시간, 수업 방식, 수강료, 수강권 정책이 바뀌었을 수 있다. 따라서 재수강 신청은 이전 스케줄을 그대로 복원하는 플로우가 아니라 최신 선생님 설정을 기준으로 다시 확인하는 플로우여야 한다.

## Current Behavior

- 검색/상세 화면에서 기존 선생님이면 `다시 시작하기` 버튼을 표시한다.
- 진입 파라미터는 `isReturningStudent=true`, `previousInstrument` 중심이다.
- 신청 화면은 정규 레슨 타입을 기본값으로 선택하고 악기를 프리필한다.
- 선호 시간은 `WeeklyCalendarPicker`에서 현재 선생님 가능 시간 기준으로 새로 선택한다.
- 별도 정책 문구나 “이전 스케줄과 다를 수 있음” 고지는 약하다.

## Required Product Rules

1. 재수강 신청에서도 학생은 최신 가능 시간 중 1-3순위를 반드시 새로 선택한다.
2. 이전 스케줄은 자동 선택하지 않는다. 추천이 필요하면 “이전 수업 시간” 배지만 표시하고, 선택 가능 여부 검증 후 학생이 직접 선택하게 한다.
3. 선생님 가능 시간이 변경되어 이전 시간이 불가능하면 해당 시간은 비활성/안내 상태로 보여야 한다.
4. 수강료, 수강권 템플릿, 결제 계좌는 이전 이력 값이 아니라 선생님 최신 설정을 기준으로 한다.
5. 신청 완료 후 선생님 승인/대안 제안/수강권 제안 과정은 신규 신청과 동일한 라이프사이클을 탄다.

## Implementation Notes

- `UnifiedLessonRequestParams.previousDay` / `previousTime`은 현재 경로에서 실질적으로 활용되지 않는다.
- 이전 스케줄 추천 UI를 추가하려면 `WeeklyCalendarPicker`가 “suggested previous slot” 입력을 받고, 최신 availability와 비교해 selectable/disabled 상태를 분리해야 한다.
- 이번 수정에서는 재수강 배너 문구를 최신 가능 시간 재선택 기준으로 맞춘다. 자동 복원 UX는 별도 설계 후 진행한다.
