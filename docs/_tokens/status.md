# 상태 토큰

> ID: `tokens/status`
> 버전: 1.0
> 소스: 앱 전반의 상태 정의

<!-- @defines: tokens/status -->

---

## 1. 연습 상태

| 토큰 ID | 값 | 색상 | 아이콘 | 설명 |
|---------|-----|------|--------|------|
| `status.practice.complete` | `complete` | `color.success` | ✓ | 연습 완료 |
| `status.practice.incomplete` | `incomplete` | `color.text.tertiary` | ○ | 미완료 |
| `status.practice.inProgress` | `in_progress` | `color.primary` | ◐ | 진행 중 |

---

## 2. 연습률 상태

| 토큰 ID | 조건 | 색상 | 이모지 |
|---------|------|------|--------|
| `status.practiceRate.good` | ≥70% | `color.practice.good` | 🟢 |
| `status.practiceRate.normal` | 40-70% | `color.practice.normal` | 🟡 |
| `status.practiceRate.poor` | <40% | `color.practice.poor` | 🔴 |
| `status.practiceRate.paused` | 휴강 | `color.practice.paused` | ⚪ |

---

## 3. 레퍼토리/섹션 상태

| 토큰 ID | 값 | 설명 |
|---------|-----|------|
| `status.repertoire.active` | `active` | 활성 (연습 기간 내) |
| `status.repertoire.inactive` | `inactive` | 비활성 (기간 외) |
| `status.repertoire.archived` | `archived` | 보관됨 |

---

## 4. 과제 유형

| 토큰 ID | 값 | 아이콘 | 설명 |
|---------|-----|--------|------|
| `status.assignment.teacher` | `assignment` | ⭐ | 선생님 과제 |
| `status.assignment.self` | `self` | ○ | 자기 연습 |

---

## 5. 반복 상태

| 토큰 ID | 값 | 표시 | 설명 |
|---------|-----|------|------|
| `status.repeat.none` | `none` | - | 반복 없음 |
| `status.repeat.daily` | `daily` | 🔁 | 매일 반복 |
| `status.repeat.count` | `count` | 2/4 | 횟수 기반 반복 |

---

## 6. 녹음 상태

| 토큰 ID | 값 | 설명 |
|---------|-----|------|
| `status.recording.idle` | `idle` | 대기 중 |
| `status.recording.recording` | `recording` | 녹음 중 |
| `status.recording.paused` | `paused` | 일시정지 |
| `status.recording.playing` | `playing` | 재생 중 |

---

## 7. 결제 상태

| 토큰 ID | 값 | 색상 | 설명 |
|---------|-----|------|------|
| `status.payment.pending` | `pending` | `color.warning` | 입금 대기 |
| `status.payment.partial` | `partial` | `color.info` | 부분 입금 |
| `status.payment.complete` | `complete` | `color.success` | 입금 완료 |
| `status.payment.overdue` | `overdue` | `color.error` | 연체 |

---

## 8. 레슨 상태

| 토큰 ID | 값 | 색상 | 설명 |
|---------|-----|------|------|
| `status.lesson.scheduled` | `scheduled` | `color.info` | 예정됨 |
| `status.lesson.completed` | `completed` | `color.success` | 완료 |
| `status.lesson.cancelled` | `cancelled` | `color.error` | 취소됨 |
| `status.lesson.rescheduled` | `rescheduled` | `color.warning` | 변경됨 |

---

## 9. 폼 유효성 상태

| 토큰 ID | 값 | 색상 | 설명 |
|---------|-----|------|------|
| `status.form.valid` | `valid` | `color.success` | 유효함 |
| `status.form.invalid` | `invalid` | `color.error` | 유효하지 않음 |
| `status.form.warning` | `warning` | `color.warning` | 경고 |

---

## 사용처

<!-- @used-by: 모든 스펙 문서 -->

상태 표시가 필요한 모든 UI 스펙 문서에서 참조

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 토큰 정의 |
