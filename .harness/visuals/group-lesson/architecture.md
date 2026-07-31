# group-lesson — 아키텍처 (Phase 3)

> spec: `.harness/spec/2026-07-31-group-lesson.md` (locked 2026-07-31)

## 1. 컴포넌트 아키텍처

```mermaid
graph TD
    subgraph FE["FE Flutter — features/schedule + subscription"]
        T1["교사 홈 → 내 클래스<br/>group_classes_screen (신규)"]
        T2["클래스 생성·수정 폼<br/>group_class_form_screen (신규)<br/>반 기본 + 드롭인 폼 옵션"]
        T3["클래스 상세<br/>group_class_detail_screen (기존·이모지 정리)"]
        T4["출석 체크<br/>group_class_attendance_screen (기존·이모지 정리)"]
        S1["학생 레슨탭 아젠다<br/>등록 반 행 (student_lessons_tab 확장)"]
        S2["교사 상세 — 개설 클래스 섹션<br/>(탐색 표면, 신규)"]
        W1["수강권 화면<br/>그룹 배지 + 클래스명<br/>(subscription_membership_card 확장)"]
    end

    subgraph BE["BE FastAPI — schedule_ext + subscription"]
        A1["/group-classes CRUD (신규)"]
        A2["/group-classes/:id/members (신규)<br/>코호트 배정·정원 검증"]
        A3["booking / attendance / waitlist<br/>(기존 — schedule_ext_service:228-354)"]
        SV1["차감: add_usage<br/>(row lock·idempotent — 기존 SSOT)"]
        SV2["마감 집행 (P2-1, 신규 검증)"]
        SV3["알림 6종 emit (P2-2, 신규)"]
    end

    subgraph DB["PostgreSQL"]
        D1["group_classes<br/>(정원·노쇼정책 — P1-0 실참조 정합)"]
        D2["group_class_schedules"]
        D3["group_class_bookings"]
        D4["subscriptions + applies_to<br/>(null=universal 비파괴)"]
        D5["teacher_announcements + scope"]
    end

    T1 --> A1
    T2 --> A1
    T3 --> A3
    T4 --> A3
    S1 --> A3
    S2 --> A1
    A2 --> D1
    A1 --> D1
    A3 --> D2
    A3 --> D3
    A3 --> SV1
    SV1 --> D4
    A3 --> SV2
    A3 --> SV3
    SV3 --> D5
    W1 --> D4
```

## 2. 데이터 모델 (P1-0 배선 정합 후)

```mermaid
erDiagram
    GROUP_CLASS ||--o{ GROUP_CLASS_SCHEDULE : "1:N (P1-0: LessonClass 오참조 -> GroupClass 실참조)"
    GROUP_CLASS ||--o{ COHORT_MEMBER : "고정 로스터 (P2-4)"
    GROUP_CLASS_SCHEDULE ||--o{ GROUP_CLASS_BOOKING : "드롭인 예약·대기열"
    SUBSCRIPTION ||--o{ USAGE : "add_usage 차감 (P1-3)"
    STUDENT ||--o{ COHORT_MEMBER : ""
    STUDENT ||--o{ GROUP_CLASS_BOOKING : ""
    STUDENT ||--o{ SUBSCRIPTION : ""
    TEACHER_ANNOUNCEMENT }o--|| GROUP_CLASS : "scope=class (P2-5)"

    GROUP_CLASS {
        string type "regular(반) | dropin"
        int capacity
        enum no_show_policy "4값 SSOT (P2-3)"
        int booking_deadline_minutes "P2-1 집행"
        int cancel_deadline_minutes "P2-1 집행"
    }
    SUBSCRIPTION {
        enum applies_to "oneToOne | group | universal(null)"
        string membership_id "기존 필수 FK — 그룹은 표시계층서 클래스명 해석"
    }
```

## 3. 핵심 불변식 (다이어그램이 강제하는 것)

- 차감 경로는 **`add_usage` 단 하나** — 그림에 두 번째 차감 화살표를 그리지 말 것
- `GroupClassSchedule` 의 부모는 **`GroupClass` 뿐** — `LessonClass` 화살표는 P1-0 에서 제거되는 대상
- 알림은 **BE emit 만** (FE 로컬 발화 화살표 금지 — #1191)
- 공지 엔티티는 `teacher_announcements` **1개** (ClassNote 박스 추가 금지)
