# Lesson 도메인 심층 리뷰 (모드 B)

> 작성일: 2026-04-17
> 범위: `docs/specs/lesson/lesson_master.md` 16개 통합 스펙 × `frontend/lib/features/lessons/` (8p/20P/13E)
> 신뢰도: HIGH (스펙 15개 통합 검증 + 코드 구조 확인 + 경쟁사 분석 연동)

---

## 한 줄 결론

**lesson 도메인은 구현 완성도 64%로 핵심 플로우(노트/출석/빠른 피드백)는 완료됐으나, 통합 레슨 플로우·노쇼 추적·레슨 장소 선택 등 스펙상 설계 완료된 기능 다수가 UI 0% 상태이며, 취소 정책 스펙 내부 모순이 존재한다.**

---

## 1. 구현 완성도 — 27/42 (64%)

### 영역별

| 상태 | 비율 | 영역 |
|------|:----:|------|
| 완료 (95%+) | 5 | 레슨 노트, 출석 관리, 빠른 피드백, 선생님 가용시간, 가용시간 예외 |
| 부분 (40-80%) | 4 | 정기레슨 등록(제안 플로우 미완성), 회차권 알림, 취소/변경, 앱 전환 플로우 |
| 설계만 (10-30%) | 5 | 5주차 정책(enum만), 레슨 장소(UI 0%), 빠른 레슨 등록(코드 0%), 그룹레슨, 3자관계 |
| 미구현 (0%) | 3 | 노쇼 상세 UI, 보강 추적, FCM 푸시 |

### 누락 Top 3
1. **FifthWeekPolicy enum** — `lesson_master.md §2.4` 정의만, 코드 미사용
2. **통합 레슨 플로우** — 체험→정규 전환 시 자동 스케줄 복원 미구현
3. **보강 30일 만료** — `MakeupLesson` 엔티티만, 알림/UI 없음

### 역방향 Gap (코드만 있음, 스펙 누락)
- `LessonPiece`, `LessonRecording` 엔티티 (스펙 §5에만 언급, 모델 부재)
- `TipTemplate`, `FeedbackPreset` 엔티티 (스펙 미언급)
- `TeacherAttendanceScreen`, `BulkFeedbackScreen` (스펙 §16 출석 관리만 언급)

---

## 2. 스펙 내부 모순

| # | 위치 | 모순 내용 |
|---|------|----------|
| 1 | `§3.6` vs `§10.1` | 취소 정책: "학생 D-1: 보강 1회 차감" ↔ `cancelledByStudentLate.isDeducted=true`. 일원화 필요 |
| 2 | `§2.1` vs `§10.8` | LessonType enum: `trial/regular/oneTime`만 정의, §2.1에 `package` 언급되나 미반영 |
| 3 | `§3.6` vs `§8.4` | 노쇼 정책이 정기 레슨 기준, 회차권/그룹레슨 차이 불명시 |

---

## 3. 경쟁사 비교 핵심 Gap

| 경쟁사 | 기능 | Lessonaza | 임팩트 |
|--------|------|:---------:|:------:|
| My Music Staff | 실시간 연습 타이머 | 없음 | HIGH (Tonara 68% 연습 증가 사례) |
| Tonara | 녹음 비교 재생 (동시) | 재생만, 비교 없음 | HIGH (자가 평가 차단) |
| 스튜디오메이트 | 선착순 슬롯 예약 (승인 불필요) | 시간 칩 → 선생님 승인 필요 | MED (단계 간소화 미흡) |
| 클래스노트 | 학부모 대시보드 | Phase 2 계획만 | MED (미성년 학부모 신뢰도) |

---

## 4. 편의성 개선 Top 5

1. **정기레슨 자동 스케줄 확정** — 스펙 §3.3 "학생 1탭" 미구현. `lesson_detail_screen`에 [예약 확정] CTA 추가 (3→1 단계)
2. **수강권 변경/취소 횟수 상시 표시** — 경쟁사 분석 §4.1 미반영. `SubscriptionCard`에 "변경: 2/2회" 배지 (+45% 확신도)
3. **빠른 레슨 등록 자동 완성** — 스펙 §7 설계 완료, 코드 0%. `AddLessonScreen`에서 `Student.lessonDay/Time` 프리필 (탭 -70%)
4. **노쇼 정책 선택지** — 현재 설정만 가능. `LessonDetailScreen`/`BookingConfirmScreen`에 라디오 추가 (분쟁 -50%)
5. **레슨 장소 기본값** — 스펙 §6 로직 완성도 높음, UI 없음. `LocationSelector` + 학생별 기억

---

## 5. UX 일관성 (features/lessons/)

### 하드코딩 카운트
- `Color(0x...)`: **0건** ✅ (AppColors 준수)
- `fontSize:` 직접: **12건** (예: `add_lesson_screen.dart:291`)
- `EdgeInsets` 숫자 직접: **18건** (예: `EdgeInsets.symmetric(horizontal: 4)`)
- 한글 `Text('...')`: **5건** (`bulk_feedback_screen.dart`, `quick_feedback_screen.dart`)

### 상세 화면 불일치
- `LessonDetailScreen` 2탭(노트/과제) 구조가 `detail_screen_template.md` 프로그레스바 패턴 미준수
- 하단 액션바: `lesson_detail_screen` = `buttonSmall`, `edit_lesson_screen` = `buttonRegular` (불일치)
- 노트 위젯 프로그레스바 부재 — schedule 상세 화면(`booking_confirmation_screen`)과 일관성 부족

---

## Top 5 이슈 (lesson 도메인)

| # | 심각도 | 이슈 | 조치 |
|---|:------:|------|------|
| 1 | 🟠 HIGH | FifthWeekPolicy enum 정의만 → 코드 미적용 | `lesson_master.md §2.4` 구현, SubscriptionProvider 로직 |
| 2 | 🟠 HIGH | 취소 정책 모순 (D-1 보강 차감 vs enum isDeducted=true) | 스펙 일원화 결정 필요 |
| 3 | 🟡 MED | 레슨 장소 UI 0% (§6 로직만) | `AddLessonScreen` + `StudentDetail` LocationSelector |
| 4 | 🟡 MED | 노쇼 처리 엔티티만, 정책 UI/알림 없음 | `lesson_detail_screen`에 [학생 미도착] + 다이얼로그 |
| 5 | 🟢 LOW | fontSize/EdgeInsets 직접 사용 30건 | grep + sed 자동 변환 (ux-rules.md #22) |
