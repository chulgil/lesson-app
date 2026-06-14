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
| `NotebookBanner` foundation | `80123d3b` | 공통 위젯 + smoke 4/4 + 스펙 + `time_context_banner` 마이그레이션 (① 마지널리아 스트립 원형 증명). 잔여: `availability_vacation_banner` 등 ① 후보 + ③ refit |
| **circular 게이트 + inbox sweep** | `7ad4622e` | 계약 테스트에 `BorderRadius.zero` 게이트 추가 (자기 축소 baseline 41 + 영구예외 4, Red-Green 검증) + inbox 3파일 7건 → 각진. 게이트 28/28 green |
| **billing sweep** | `fc4a428a` | billing 4파일 10건 → 각진 (배지 borderRadius 제거 + 버튼 `const RoundedRectangleBorder()`). baseline 41→37. billing 위젯 테스트 19/19 |
| **profile sweep** | `34643ccb` | profile 7파일 10건 → 각진 (BoxDecoration borderRadius 제거 + 인라인 드래그 핸들 → 공유 `BottomSheetHandle` + 시트 top 각진). baseline 37→30. profile 테스트 163/163 |
| **schedule sweep** | `a0a03dcb` | schedule 4파일 9건 → 각진 (BoxDecoration/InkWell borderRadius 제거 + 인라인 드래그 핸들 → 공유 `BottomSheetHandle`). baseline 30→26. 게이트 28/28, schedule 테스트 362/362 |
| **practice sweep** | `707e2dad` | practice 6파일 6건 → 각진 (버튼 `const RoundedRectangleBorder()` 2 + BoxDecoration borderRadius 제거 3 + 진행바 ClipRRect `BorderRadius.zero` 1). baseline 26→20. 게이트 28/28, practice 테스트 336/336 |
| **subscription sweep** | `70d61682` | subscription 4파일 5건 → 각진 (BoxDecoration borderRadius 제거 4 + InkWell borderRadius 제거 1). baseline 20→16. 게이트 28/28, subscription 테스트 165/165 |
| **lessons sweep** | `cf9458f5` | lessons 3파일 4건 → 각진 (시트 top BoxDecoration borderRadius 제거 2 + InkWell borderRadius 제거 1 + 진행바 ClipRRect `BorderRadius.zero` 1). baseline 16→14. 게이트 28/28, lessons 테스트 57/57 |
| **onboarding sweep** | `c638d12f` | onboarding 3파일 3건 → 각진 (버튼 shape `const RoundedRectangleBorder()` 2 + BoxDecoration borderRadius 제거 1). baseline 14→11. 게이트 28/28, onboarding 테스트 34/34 |
| **gamification sweep** | `7466f6ac` | gamification 3파일 3건 → 각진 (BoxDecoration borderRadius 제거 3). baseline 11→8. 게이트 28/28, gamification 테스트 316/316 |
| **auth sweep** | `d2b28643` | auth 2파일 3건 → 각진 (BoxDecoration borderRadius 제거 3: `academy_invite_accept` 2 + `academy_invite_expired` 1). baseline 8→6. 게이트 28/28, auth 테스트 49/49 |
| **academy·core·home·notifications sweep (circular 완결)** | (본 커밋) | 5파일 각진 + nav FAB 1 영구예외 → **baseline 6→0 (circular sweep 전 도메인 완료)**. academy 3(외곽 카드 var+배지 2) + `address_search_field` 인라인 핸들→`BottomSheetHandle` + `like_stamp` ON 도장 각진 + `quest_board_card` 진행바 `BorderRadius.zero` + `context_switch_toast` 토스트 각진. `practice_center_button`(nav FAB)은 permanentExceptionMarkers 로 이동(원형 유지). 게이트 28/28, 위젯 테스트 63/63 |

## 4. BorderRadius.circular 인벤토리 (baseline 0 — circular sweep 전 도메인 완료, inbox·billing·profile·schedule·practice·subscription·lessons·onboarding·gamification·auth·academy·core·home·notifications)

> **게이트 활성 (2026-06-13, baseline 0 도달)**: `notebook_design_contract_test.dart` 의 "BorderRadius.zero — 각진 원칙" 테스트의 baseline 이 **빈 set** 이 됨 → **신규 circular 도입은 어디서든 즉시 FAIL**. 영구예외(permanentExceptionMarkers)만 허용.
>
> 잔여 ③ refit: `lifetime_promo_banner` 는 각진 처리됐으나 `color: paperAccent` fill 배경은 유지 — ① 마지널리아 스트립/② NotebookCard 로 refit 은 별도 슬라이스.

정당 예외 6건 (정비 대상 아님): `tuner_cat_widgets.dart`(캐릭터), `youtube_player_widget.dart`·`practice/.../youtube/`(미디어), `bottom_sheet_handle.dart`(드래그 pill), `coach_mark_overlay.dart`(오버레이 cue), `practice_center_button.dart`(바텀 nav 중앙 FAB — 시스템 affordance, 원형 유지).

도메인별 실위반 (정비 우선순위 = 사용자 노출 빈도 순):

| 도메인 | 건수 | 대표 위반 패턴 |
|--------|------|---------------|
| ~~profile~~ | ~~10~~ | **정비 완료** (본 커밋) — 7파일 BoxDecoration borderRadius 제거 + 인라인 드래그 핸들 → 공유 `BottomSheetHandle` + `feedback_template_form_sheet` 시트 top 각진 |
| ~~billing~~ | ~~10~~ | **정비 완료** (본 커밋) — 배지 borderRadius 제거 + 버튼 `const RoundedRectangleBorder()`. lifetime_promo fill 배경 refit 만 잔여(③) |
| ~~schedule~~ | ~~9~~ | **정비 완료** (본 커밋) — 4파일 BoxDecoration/InkWell borderRadius 제거 + `request_detail` 인라인 드래그 핸들 → 공유 `BottomSheetHandle`. `request_history_chat` 채팅버블 `Radius.circular` 4건은 별도 메타포 — 스코프 외 |
| ~~practice~~ | ~~6~~ | **정비 완료** (본 커밋) — 버튼 shape `const RoundedRectangleBorder()` 2 + BoxDecoration borderRadius 제거 3 + 진행바 ClipRRect `BorderRadius.zero` 1. `tuner_cat_widgets` 캐릭터 곡률은 영구예외 |
| ~~inbox~~ | ~~7~~ | **정비 완료** (본 커밋) — 배지 borderRadius 제거 + 입력 border `BorderRadius.zero` |
| ~~subscription~~ | ~~5~~ | **정비 완료** (본 커밋) — 4파일 BoxDecoration borderRadius 제거 4 + `makeup_credit_use_selector` InkWell borderRadius 제거 1 |
| ~~lessons~~ | ~~4~~ | **정비 완료** (본 커밋) — 3파일: 시트 top BoxDecoration borderRadius 제거 2 + `add_recording` InkWell borderRadius 제거 1 + 진행바 ClipRRect `BorderRadius.zero` 1. `feedback_template_picker` 는 `Radius.circular`(게이트 비대상)였으나 동일 각진 정비 |
| ~~onboarding~~ | ~~3~~ | **정비 완료** (본 커밋) — 3파일: 버튼 shape `const RoundedRectangleBorder()` 2 (`first_availability`·`quest_unlock` celebration) + `recording_step` BoxDecoration borderRadius 제거 1 (raw `8.0` 매직넘버였음) |
| ~~gamification~~ | ~~3~~ | **정비 완료** (본 커밋) — 3파일 BoxDecoration borderRadius 제거 (`spotlight_slot`·`trophy_collection_card`·`year_heatmap_grid`, year_heatmap 은 raw `2` 히트맵 셀). L3+ 색맹 마커 `BoxShape.circle` 은 접근성 cue — 스코프 외 |
| ~~auth~~ | ~~3~~ | **정비 완료** — 2파일 BoxDecoration borderRadius 제거 3 (`academy_invite_accept_screen` 2 + `academy_invite_expired_screen` 1) |
| ~~academy~~ | ~~3~~ | **정비 완료** (본 커밋) — `academy_activity_timeline_screen` 외곽 카드 `cardBorderRadius` var 삭제 + 배지 2 borderRadius 제거 |
| ~~core~~ | ~~3~~ | **정비 완료** (본 커밋) — `address_search_field` 인라인 핸들 → 공유 `BottomSheetHandle` · `like_stamp` ON 도장 각진(사각 stamp) · `practice_center_button`(nav FAB)은 영구예외(원형 유지) |
| ~~home~~ | ~~1~~ | **정비 완료** (본 커밋) — `quest_board_card` 진행바 ClipRRect `BorderRadius.zero` |
| ~~notifications~~ | ~~1~~ | **정비 완료** (본 커밋) — `context_switch_toast` 토스트 컨테이너 borderRadius 제거 |

정비 규칙: `BorderRadius.circular(...)` → `BorderRadius.zero`(=각진) 또는 decoration 에서 borderRadius 제거. §1.3.1.

## 5. BoxShadow 인벤토리 (drift 0 — 정비 완료, 예외 4)

> **게이트 활성 (2026-06-14, baseline 0)**: `notebook_design_contract_test.dart` "flat ink — no BoxShadow" 테스트가 BoxShadow 를 금지하고 4 예외(permanentExceptionMarkers: `youtube`·`coach_mark_overlay`·`practice_center_button`)만 허용. **신규 BoxShadow 도입은 어디서든 즉시 FAIL**.

| 파일 | 판정 |
|------|------|
| ~~`practice/.../rest_recommendation_toast.dart`~~ | **정비 완료** (본 커밋) — boxShadow 제거 → 평면 + 잉크 테두리(`Border.all(ink)`) 로 변별성 유지 |
| `lessons/.../youtube_player_widget.dart` | 예외 — 외부 미디어(유튜브 루프 마커) |
| `practice/.../youtube/loop_timeline.dart` | 예외 — 외부 미디어(유튜브 루프 타임라인) |
| `core/widgets/practice_center_button.dart` | 예외 — 바텀 nav 중앙 FAB(시스템 affordance), `// ignore: notebook-boxshadow` 기보유 |
| `core/widgets/coach_mark/coach_mark_overlay.dart` | 예외 — 오버레이 elevation cue |

## 6. 멱등성 게이트 확장 (근본 원인 차단)

`notebook_design_contract_test.dart` 에 **토큰 게이트 3종 추가** (baseline allowlist 패턴 — 현재 위반을 고정하고 신규 위반만 차단, allowlist 를 점진 축소):

1. `BorderRadius.circular` 금지 (영구예외 6 + 정비 baseline 41→**0**) — **전 도메인 완료**. test: "BorderRadius.zero — 각진 원칙" (baseline 빈 set, 신규 circular 즉시 FAIL)
2. `BoxShadow` 금지 (영구예외 4: 미디어 2·오버레이 1·nav FAB 1) — **완료 (본 커밋)**. test: "flat ink — no BoxShadow" (baseline 빈 set, drift `rest_recommendation_toast` 정비 후 신규 BoxShadow 즉시 FAIL)
3. (선택) signature 영역 raw `fontSize:` 금지 — 대기

> 패턴: 기존 `allowedFiles`/`allowedPrefixes` 와 동일. 정비 1건마다 baseline set 에서 경로 1줄 삭제 → stale 검사가 누락 방지, unexpected 검사가 신규 도입 방지 (양방향 자기 축소).

## 7. 공통 UI 추출 — NotebookBanner

> **실측 상태 (2026-06-14)**: `NotebookBanner` 공통 위젯 추출 완료(`core/widgets/notebook/notebook_banner.dart`). 인라인 마지널리아 스트립(`Border(left: BorderSide)`) 패턴은 현재 **정본 위젯에만** 존재 — `time_context_banner` 가 채택해 이전 완료. 나머지 배너는 ② NotebookCard 행 또는 인라인 아이콘+accent 등 **별개 패턴**이라 "12종 일괄 마이그레이션" 은 과장이었음. 잔여는 선택적 refit(③ lifetime_promo, availability_vacation_banner)뿐.

배너 12개가 3개 원형으로 분산:

| 원형 | 대표 | 패턴 | 정비 |
|------|------|------|------|
| ① 마지널리아 스트립 | `time_context_banner`(SSOT 레퍼런스) | 좌측 3px accent bar + leading icon + Gaegu 메시지 | **추출 완료** — `NotebookBanner` 채택 |
| ② NotebookCard 행 | `app_update_banner` | NotebookCard + 아이콘 뱃지 + 제목/부제 + action | 이미 모범 — 유지 |
| ③ 채워진 프로모 카드 | `lifetime_promo_banner` | `color: paperAccent` fill + eyebrow + CTA + dismiss | 선택적 refit — ①/② 후보(설계 판단) |

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

refit 시 대상: `availability_vacation_banner`(인라인 아이콘+accent — ① 패턴 아님, 마이그레이션 시 시각 변경) + ③ `lifetime_promo`. `*_test.dart` smoke 동반 필수(HARD-GATE).

## 8. 실행 순서 — 진행 상태 (2026-06-14)

| # | 항목 | 상태 |
|---|------|------|
| 1 | 토큰 게이트 (§6): circular · BoxShadow | **완료** (2종). fontSize 게이트(③)는 선택, 미착수 |
| 2 | `NotebookBanner` 추출 + smoke (§7) | **완료** — `time_context_banner` 채택 |
| 3 | 도메인별 circular sweep (§4) | **완료** — 14도메인 baseline 0 |
| 4 | BoxShadow 정비 (§5) | **완료** — drift 0, 예외 4 |
| 5 | subscription badge 통합 | **잔여** — `subscription_badge`(subscription) ↔ `StudentClassBadge`/`StudentSubscriptionMiniBadge`(students) 는 **독립 위젯**(별개 surface). lesson_card·students_tab·provider 다중 호출처 → 설계 판단 + smoke 필요 |
| 6 | ③ lifetime_promo refit · availability_vacation_banner | **잔여 (선택)** — 시각 디자인 변경, 사용자 판단 필요 |
| 7 | 완료 시 README 수치 갱신 + 본 문서 archived | 5·6 완료 후 |

> 핵심: **근본 원인(토큰 게이트 부재)은 1~4 로 해소됨**. 잔여 5·6 은 token drift 가 아니라 위젯 dedup/시각 리팩토링이라 게이트 자기축소와 무관. fresh 세션 + 설계 입력 권장.

## 9. 참조

- 정의 SSOT: [README.md](./README.md) §1.3.1(각진)·§1.2(시그니처)
- 이력 SSOT: [phase-log.md](./phase-log.md)
- 계약 테스트: `frontend/test/architecture/notebook_design_contract_test.dart`
