# 학생 중심 아키텍처 설계

> 작성일: 2024-12-22
> 최종 수정: 2026-01-24
> 상태: 설계 완료 + 스트릭 기능 구현 완료
> 엔티티 스키마: [practice_space.md](../../schema/entities/practice_space.md)

> **관련 문서**: [3자 관계 설계](three_party_relationship_spec.md) - 학원-선생님-학생 관계 확장

---

## 개요

### 설계 철학

**"학생이 연습 공간의 주인, 선생님은 초대된 코치"**

기존의 선생님 중심 모델에서 학생 중심 모델로 전환하되, 선생님도 학생 관리 도구로 활용할 수 있도록 **양방향 초대 시스템**을 구현합니다.

> **Note**: 학원 소속 선생님의 경우, `organizationId`를 통해 학원 컨텍스트가 추가됩니다.
> 학원 학생은 학원과 선생님 양쪽에 연결되며, 데이터 소유권은 학원에 있습니다.
> 자세한 내용은 [3자 관계 설계](three_party_relationship_spec.md) 참조.

### 핵심 변경점

| 구분 | 기존 모델 | 신규 모델 |
|------|----------|----------|
| 데이터 소유권 | 선생님 중심 | 학생 중심 |
| 관계 생성 | 선생님이 학생 추가 | 양방향 초대 (QR/URL) |
| 연습 기록 | 선생님 관리 | 학생 소유, 선생님 읽기 |
| 과제 관리 | 선생님 생성 | 선생님 제안 → 학생 수락 |

---

## 데이터 모델

### 핵심 엔티티

| 엔티티 | 설명 | 상세 |
|--------|------|------|
| **PracticeSpace** | 학생이 소유하는 개인 연습 공간 | [practice_space.md](../../schema/entities/practice_space.md#practicespace-연습-공간) |
| **CoachConnection** | 학생-선생님 연결 관계 | [practice_space.md](../../schema/entities/practice_space.md#coachconnection-코치-연결) |
| **ExternalTeacher** | 앱 미사용 외부 선생님 정보 | [practice_space.md](../../schema/entities/practice_space.md#외부-선생님-앱-미사용) |
| **Assignment** | 선생님 제안 → 학생 수락 과제 | [practice_space.md](../../schema/entities/practice_space.md#assignment-과제) |
| **InviteCode** | 양방향 초대 코드 | [practice_space.md](../../schema/entities/practice_space.md#invitecode-초대-코드) |

### ConnectionStatus

| 값 | 설명 |
|----|------|
| `pending` | 대기중 |
| `active` | 활성 |
| `paused` | 일시중지 |
| `ended` | 종료 |

### ConnectionSource

| 값 | 설명 |
|----|------|
| `studentInvite` | 학생이 초대 |
| `teacherInvite` | 선생님이 초대 |
| `appSearch` | 앱 검색 |

### AssignmentStatus

| 값 | 설명 |
|----|------|
| `suggested` | 제안됨 (선생님 → 학생) |
| `accepted` | 수락됨 |
| `declined` | 거절됨 |
| `completed` | 완료됨 |

### 멀티 코치 연습 기록 정책 ✅ 결정됨

> **결정**: 통합 관리 (모든 선생님이 모든 연습 기록 조회)

| 정책 | 설명 |
|------|------|
| **통합 관리** | 연결된 모든 선생님이 학생의 전체 연습 기록 조회 가능 |
| 악기별 분리 | ❌ (선택되지 않음) |

**이유**:
- 학생의 전반적인 연습 현황을 파악하는 것이 지도에 도움
- 다른 선생님의 과제와 중복/충돌 방지 가능
- 악기별 분리는 UX 복잡성 증가 대비 이점이 적음

---

## 양방향 초대 시스템

### 초대 플로우

#### 학생 → 선생님 초대

```
1. 학생이 "선생님 초대" 버튼 클릭
2. QR 코드 또는 URL 생성
3. 선생님이 스캔/클릭
4. 선생님 앱에서 연결 수락
5. CoachConnection 생성 (status: active)
```

#### 선생님 → 학생 초대

```
1. 선생님이 "학생 초대" 버튼 클릭
2. QR 코드 또는 URL 생성
3. 학생이 스캔/클릭
4. 학생 앱에서 연결 수락
5. CoachConnection 생성 (status: active)
```

### InviteType

| 값 | 설명 |
|----|------|
| `studentToTeacher` | 학생 → 선생님 |
| `teacherToStudent` | 선생님 → 학생 |

### URL 형식

```
학생 → 선생님: lessonapp://invite/coach/{code}
선생님 → 학생: lessonapp://invite/student/{code}
웹 딥링크:     https://lessonapp.kr/invite/{type}/{code}
```

### 비등록 사용자 초대 ✅ 결정됨

> **결정**: SMS/카카오톡 딥링크 방식

| 상황 | 처리 방식 |
|------|----------|
| 선생님 앱 사용 | 앱 내 QR 스캔/URL 클릭 |
| 선생님 앱 미설치 | SMS/카카오톡으로 초대 링크 전송 → 앱스토어 연결 |

---

## 권한 모델

### 데이터 접근 권한

| 데이터 | 학생 | 앱 사용 선생님 | 외부 선생님 |
|--------|:----:|:--------------:|:-----------:|
| 연습 기록 | 읽기/쓰기 | 읽기 | - |
| 연습 통계 | 읽기/쓰기 | 읽기 | - |
| 과제 | 읽기/쓰기/삭제 | 제안/읽기 | - |
| 코치 피드백 | 읽기 | 읽기/쓰기 | - |
| 레슨 노트 | 읽기 | 읽기/쓰기 | - |
| 연결 관리 | 추가/해제 | 해제만 | - |

### CoachConnection 권한 필드

| 필드 | 기본값 | 설명 |
|------|:------:|------|
| `canViewPractice` | true | 연습 기록 조회 |
| `canComment` | true | 댓글 작성 |
| `canSuggestAssignments` | true | 과제 제안 |

---

## 사용 시나리오

### 시나리오 A: 선생님 앱 사용

```
[학생]                          [선생님]
연습 기록 작성 ─────────────────→ 연습 기록 조회
                              ↓
                          피드백 작성
                              ↓
    피드백 확인 ←─────────────────
    과제 수락
```

### 시나리오 B: 외부 선생님 (앱 미사용)

```
[학생]
외부 선생님 등록 (이름, 악기, 요일만)
    ↓
연습 기록 작성 (선생님 연결)
    ↓
레슨 후 직접 레슨 노트 작성
```

### 시나리오 C: 독학

```
[학생]
연습 공간 생성 (선생님 연결 없이)
    ↓
연습 기록 작성
    ↓
스트릭 추적 & 자기 분석
```

---

## 마이그레이션 전략

### 기존 데이터 처리

| 기존 데이터 | 마이그레이션 방안 |
|-------------|------------------|
| 선생님이 등록한 학생 | 학생에게 PracticeSpace 자동 생성, 기존 선생님을 Coach로 연결 |
| 기존 레슨 기록 | LessonNote로 유지 (선생님 소유) |
| 연습 기록 | 해당 학생의 PracticeSpace로 이동 |

### 단계별 전환

```
Phase 1: 신규 가입자 - 새 모델 적용
Phase 2: 기존 사용자 - 마이그레이션 안내 후 전환
Phase 3: 레거시 모델 지원 종료
```

---

## UI 변경점

### 학생 앱

| 화면 | 변경 내용 |
|------|----------|
| 홈 | "내 연습 공간" 중심 UI |
| 선생님 탭 | "내 코치" 목록 + 초대 버튼 |
| 연습 기록 | 스트릭 표시 + 코치 피드백 영역 |
| 설정 | 코치별 권한 설정 |

### 선생님 앱

| 화면 | 변경 내용 |
|------|----------|
| 홈 | "연결된 학생" 목록 |
| 학생 상세 | 학생 연습 기록 조회 (읽기 전용) |
| 초대 | QR/URL 생성 기능 |
| 피드백 | 학생 연습 기록에 코멘트 |

---

## 구현된 기능: 연습 스트릭 ✅

> 구현일: 2024-12-22

### 스트릭 레벨

| 레벨 | 조건 | 이모지 | 그라데이션 색상 |
|:----:|------|:------:|----------------|
| 0 | 스트릭 없음 | - | 회색 (#9E9E9E → #757575) |
| 1 | 1-6일 | ✨ | 보라색 (Primary) |
| 2 | 7-29일 | 🔥 | 주황/빨강 (#FF6B6B → #FF8E53) |
| 3 | 30일+ | 🔥🔥 | 골드 (#FFB800 → #FF8C00) |

### 주말 제외 정책

토/일에 연습 안 해도 스트릭 유지

### 구현된 위젯

| 위젯 | 용도 | 위치 |
|------|------|------|
| `PracticeStreakCard` | 대시보드용 대형 카드 | 학생 홈 화면 상단 |
| `PracticeStreakBadge` | 소형 배지 | 프로필, 리스트 등 |
| `RecordPracticeButton` | 오늘 연습 기록 버튼 | 대시보드 |

→ 스트릭 상세 명세: [practice_streak_spec.md](../practice/practice_streak_spec.md)

---

## 결정된 정책 요약

### 의사결정 기록 (2024-12-22)

| 항목 | 결정 | 이유 |
|------|------|------|
| **멀티 코치 연습 기록** | 통합 관리 | 모든 선생님이 전체 연습 기록 조회 가능 |
| **비등록 사용자 초대** | SMS/카카오톡 딥링크 | 앱 미설치 선생님도 초대 가능 |
| **스트릭 리셋 정책** | 주말 제외 | 토/일에 연습 안 해도 스트릭 유지 |

---

## 관련 문서

| 문서 | 설명 |
|------|------|
| [practice_space.md](../../schema/entities/practice_space.md) | PracticeSpace, CoachConnection, Assignment 엔티티 |
| [three_party_relationship_spec.md](three_party_relationship_spec.md) | 학원-선생님-학생 3자 관계 확장 |
| [practice_streak_spec.md](../practice/practice_streak_spec.md) | 스트릭 기능 상세 명세 |
| [invite_system_v2.md](../invite/invite_system_v2.md) | 초대 시스템 (수강권 기반) |
