# Notebook × Score 토큰 Drift 잔여 인벤토리 & 정비 계획

> 작성: 2026-06-13
> 상태: 진행 중 (P0 + 포크 통합 완료, 토큰 sweep 대기)
> SSOT 관계: [README.md](./README.md) 가 정의, 본 문서가 **잔여 drift 추적**. 정비 완료 시 README 수치 갱신.

## 1. 한 줄 결론

README 가 "BorderRadius.circular 2건 포화 / BoxShadow 0건 / 전 도메인 완료"(2026-05-04)라 단언했으나, 그 이후 추가된 도메인에서 **토큰 drift 가 누적**됐다. 근본 원인은 `notebook_design_contract_test.dart` 가 표면 래퍼(Scaffold/Card/Dialog/Sheet)만 검사하고 **토큰(각진·평면·타이포)을 검사하지 않아** 멱등성 게이트가 비어 있었기 때문이다.

## 2. 발견 경위 (2026-06-13)

| 항목 | README 주장 | 실측 | 비고 |
|------|------------|------|------|
| 디자인 계약 테스트 | (CI 게이트 가정) | **red 22pass/5fail** | main 에 red 방치 → P0 에서 green 전환 |
| `BorderRadius.circular` | 2건만 (포화) | **72건** (정당 예외 5 제외 = **67 실위반**) | §1.3.1 거짓 |
| `BoxShadow` | 0건 (전수 제거) | **5건** | §7 milestone 거짓 |
| raw `fontSize:` (copyWith·theme 제외) | 토큰 전수 치환 완료 | **73건** | §5.3 과장 |
| 직접 `Scaffold`/`AlertDialog`/`showModalBottomSheet` | 래퍼만 | **2 파일** | 계약 테스트가 정확히 포착 → P0 해소 |

핵심: **표면 구조는 잘 강제됨(2파일만 drift)**, **토큰은 게이트 부재로 67+건 drift**.

## 3. 완료 (2026-06-13)

| 작업 | 커밋 | 결과 |
|------|------|------|
| P0 — 계약 red 2건 → green | `51da3df9` | gamification Scaffold/sheet + proposal_draft_banner AlertDialog. 27/27 green |
| stat_card 포크 통합 | `8396cf44` | parent_home 독자 StatCard 삭제 → core 통합 |
| `NotebookBanner` foundation | (본 커밋) | 공통 위젯 + smoke 4/4 + 스펙 + `time_context_banner` 마이그레이션 (① 마지널리아 스트립 원형 증명). 잔여: `availability_vacation_banner` 등 ① 후보 + ③ refit |

## 4. 잔여 BorderRadius.circular 인벤토리 (67 실위반)

정당 예외 5건 (정비 대상 아님): `tuner_cat_widgets.dart`(캐릭터), `youtube_player_widget.dart`·`practice/.../youtube/`(미디어), `bottom_sheet_handle.dart`(드래그 pill), `coach_mark_overlay.dart`(오버레이 cue).

도메인별 실위반 (정비 우선순위 = 사용자 노출 빈도 순):

| 도메인 | 건수 | 대표 위반 패턴 |
|--------|------|---------------|
| profile | 10 | `category_card.dart`, `context_toggle_dialog.dart` |
| billing | 10 | `BorderRadius.circular(AppSpacing.radiusMedium)` — §1.3.1 명시 금지 (subscription_status_card·lifetime_promo·free_limit_sheet) |
| schedule | 9 | `teacher_vacation_mode_screen.dart`, `cancel_lesson_bottom_sheet.dart` |
| practice | 7 | (youtube 미디어 제외 후 잔여) |
| inbox | 7 | `BorderRadius.circular(8/4)` 생 매직넘버 (academy_inquiry_*) |
| subscription | 5 | makeup_credit / payment_pending |
| lessons | 4 | (youtube 제외 후 잔여) |
| onboarding/gamification/auth/academy | 3 each | — |
| notifications/home | 1 each | — |

정비 규칙: `BorderRadius.circular(...)` → `BorderRadius.zero`(=각진) 또는 decoration 에서 borderRadius 제거. §1.3.1.

## 5. 잔여 BoxShadow 인벤토리 (5건)

| 파일 | 판정 |
|------|------|
| `lessons/.../youtube_player_widget.dart` | 미디어 — 예외 후보 |
| `practice/.../youtube/loop_timeline.dart` | 미디어 — 예외 후보 |
| `practice/.../rest_recommendation_toast.dart` | **drift** — 종이 평면 잉크 위반 |
| `core/widgets/practice_center_button.dart` | **drift** — core 위젯, 우선 정비 |
| `core/widgets/coach_mark/coach_mark_overlay.dart` | 오버레이 elevation cue — 예외 후보 |

## 6. 멱등성 게이트 확장 (근본 원인 차단)

`notebook_design_contract_test.dart` 에 **토큰 게이트 3종 추가** (baseline allowlist 패턴 — 현재 위반을 고정하고 신규 위반만 차단, allowlist 를 점진 축소):

1. `BorderRadius.circular` 금지 (정당 예외 5 + 정비 대기 allowlist)
2. `BoxShadow` 금지 (미디어/오버레이 예외 allowlist)
3. (선택) signature 영역 raw `fontSize:` 금지

> 패턴: 기존 `allowedFiles`/`allowedPrefixes` 와 동일. 정비 1건마다 allowlist 1줄 삭제 → 테스트가 회귀 방지.

## 7. 공통 UI 추출 — NotebookBanner (중복 12종)

배너 12개(1,698 LOC)가 3개 원형으로 분산:

| 원형 | 대표 | 패턴 | 정비 |
|------|------|------|------|
| ① 마지널리아 스트립 | `time_context_banner`(SSOT 레퍼런스) | 좌측 3px accent bar + leading icon + Gaegu 메시지 | **공통 `NotebookBanner` 추출 대상** |
| ② NotebookCard 행 | `app_update_banner` | NotebookCard + 아이콘 뱃지 + 제목/부제 + action | 이미 모범 — 유지 |
| ③ 채워진 프로모 카드 | `lifetime_promo_banner` | `color: paperAccent` fill + eyebrow + CTA + dismiss | **drift** — ①/② 로 refit |

`NotebookBanner` 설계 (① 원형, 시각 셸만 — 메시지 로직은 도메인 잔류):

```dart
NotebookBanner({
  required Widget message,        // 또는 String + Gaegu 기본
  IconData? leadingIcon,          // size 20, ink
  Color accent = AppColors.paperAccent,  // 좌측 3px 세로선 색
  Widget? trailing,               // 인라인 action/dismiss (옵션)
  EdgeInsets margin = ...space4 bottom,
})
```

대상(① 원형): `time_context_banner`, `availability_vacation_banner` + ③ refit 후보. `*_test.dart` smoke 동반 필수(HARD-GATE).

## 8. 실행 순서 (후속 세션)

1. 토큰 게이트 3종 추가 (§6) — baseline 으로 red 회피, 신규 drift 차단
2. `NotebookBanner` 추출 + 스펙(`docs/_components/notebook_banner.md`) + smoke (§7)
3. 도메인별 circular sweep — billing·inbox(생 매직넘버) 우선, allowlist 동시 축소 (§4)
4. BoxShadow 2건(core 우선) 정비 (§5)
5. subscription badge 2종 통합 (`subscription_badge` + `student_subscription_badge`)
6. 완료 시 README §1.3.1·§5.3·§7 수치 갱신 + 본 문서 archived

## 9. 참조

- 정의 SSOT: [README.md](./README.md) §1.3.1(각진)·§1.2(시그니처)
- 이력 SSOT: [phase-log.md](./phase-log.md)
- 계약 테스트: `frontend/test/architecture/notebook_design_contract_test.dart`
