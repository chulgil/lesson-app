# 선생님 홈 마스터 스펙

> 마지막 업데이트: 2026-03-12
> 구현 상태: ✅ 구현 완료
> 관련 코드: `features/home/`

---

## 1. 개요

선생님 메인 대시보드. 오늘 레슨, 긴급 액션, 시작 가이드, 과제 현황 요약 표시.
탭 기반 네비게이션(홈/캘린더/학생/프로필)의 진입점.

## 2. 주요 화면

### 2.1 DashboardTab
- 오늘 레슨 카드 (시간순 정렬)
- 긴급 액션 섹션 (미확인 레슨, 승인 대기 등)
- 시작 가이드 카드 (신규 선생님용)
- 과제 요약 섹션

### 2.2 과제 대시보드 (#101)
- 전체 학생 주간 과제 현황
- 학생별 완료율 표시

## 3. 코드 위치

| 레이어 | 파일 |
|--------|------|
| Provider | `features/home/presentation/providers/assignment_summary_provider.dart` |
| 화면 | `features/home/presentation/screens/home_screen.dart`, `assignment_dashboard_screen.dart` |
| 위젯 | `features/home/presentation/widgets/` (dashboard_tab, lesson_card, getting_started_card 등) |

## 4. 관련 마스터 스펙

- 레슨 카드: [lesson_master.md](../lesson/lesson_master.md)
- 디자인: [design_master.md](../design/design_master.md) §선생님 화면
