# group-lesson — 주요 시나리오 플로우 (Phase 3)

> spec: `.harness/spec/2026-07-31-group-lesson.md` §3 시나리오 1~4 대응

## 1. 코호트 반 운영 (시나리오 1·4)

```mermaid
sequenceDiagram
    actor T as 교사
    participant F as FE (내 클래스)
    participant A as BE /group-classes
    participant S as schedule_ext_service
    participant U as add_usage (구독 SSOT)
    actor P as 학생·학부모

    T->>F: 반 생성 (이름·정원·요일시간·노쇼정책 4값)
    F->>A: POST /group-classes (type=regular)
    A->>S: 매주 GroupClassSchedule 자동 생성
    T->>F: 학생 배정 (또는 학생 신청→챗형 승인)
    F->>A: POST /group-classes/:id/members (정원 검증)
    A-->>P: 알림: 반 배정 확정 (P2-2)
    Note over T,P: 매주 수업일
    T->>F: 출석 체크 (출석/노쇼 토글 → 저장)
    F->>S: 출석 확정
    S->>U: add_usage(appliesTo 검증: group|universal)
    U-->>S: 차감 완료 (중복 멱등)
    S-->>P: 알림: 노쇼 경고 (노쇼 시, 정책 4값 적용)
    Note over S,U: 1:1 전용권만 있으면 4xx — 차감 거부
```

## 2. 드롭인 즉시예약 + 대기열 (시나리오 3)

```mermaid
sequenceDiagram
    actor St as 성인 학생
    participant F as FE (교사 상세 → 클래스)
    participant A as BE booking (기존)
    participant W as 대기열·자동승격 (기존)

    St->>F: 특강 발견 → 예약 탭
    F->>St: 확인 다이얼로그 (P2-6)<br/>차감 수강권 + 마감·노쇼 정책 명시
    St->>F: 확정
    F->>A: 예약 요청
    alt 정원 여유
        A-->>St: confirmed + 예약확정 알림 (P2-2)
    else 정원 초과
        A->>W: 대기열 등록
        Note over W: 취소 발생
        W->>A: 1순위 자동승격
        A-->>St: 즉시 알림 (승격 = 출석 의무 발생)
    end
    Note over St,A: 마감 후 취소 시도
    St->>F: 취소
    F->>A: 취소 요청
    A-->>F: 4xx + 정책 안내 (P2-1 마감 집행)
```

## 3. 그룹 수강권 발급·표시 (시나리오 2)

```mermaid
sequenceDiagram
    actor T as 교사
    participant A as BE subscription
    actor P as 학부모
    participant F as FE 결제 탭·수강권 목록

    T->>A: 그룹 전용 템플릿으로 발급<br/>(appliesTo=group, 가격 앵커 1:1의 60~70%)
    A-->>P: 수강권 제안 → 입금 확인 (기존 플로우)
    P->>F: 결제 탭 조회
    F-->>P: 클래스명 + 그룹 배지 표시<br/>("개인레슨" 폴백 금지 — P1-5 회귀)
    Note over F: 잔여 횟수 1:1 과 구분 표시,<br/>만료 임박 알림에 수강권 종류 명시
```

## 4. 반 공지 (P2-5)

```mermaid
sequenceDiagram
    actor T as 교사
    participant A as BE TeacherAnnouncement
    actor M as 반 멤버 (학생·학부모)

    T->>A: 공지 작성 (scope=class, classId)
    A-->>M: 반 멤버에게만 발행 알림 (P2-2)
    Note over T,M: 개인 피드백은 기존 1:1 노트 경로 (별도 트랙)
```

## 릴리스 순서 제약 (spec §8)

```mermaid
graph LR
    P10["P1-0 배선 정합"] --> P11["P1-1 CRUD"] --> P12["P1-2 진입점"]
    P14["P1-4 appliesTo"] --> P13["P1-3 실차감"]
    P22["P2-2 알림 6종"] --> P13
    style P13 fill:#ffe5e5
    P16["P1-6 이모지 정리 (선행)"] --> P12
```

> **P1-3 실차감은 P2-2 알림과 같은 릴리스 이전 배포 금지** — 알림 없는 자동승격 차감 방지.
