# §7.127 Gaegu 손글씨 4계층 SSOT 정착 — 시스템 자동 뱃지 hand 해제

> 작성일: 2026-04-28
> 모드: `/plan` → `/auto` 10x Vision 모드 (사용자: "3번으로 진행 병렬처리 가능하면 병렬로 진행")
> 사용자 결정: Phase 1~5 완전 적용 + 신규 advisory 훅 + Phase 6 별건 분리

## 배경

사용자 점검: "현재 디자인컨셉 notebook x score 가 되어있는데 일부만 폰트 필기체가 적용되어있는데 클래식 전공 선생님의 노트필기에 익숙해져있어 해당 디자인 컨셉의 폰트의 경우 필기체 적용 범위를 다시 검증해주세요. UX전문가 관점과 선생님관점에서".

§7.107~§7.108 에서 시스템 자동 뱃지("오늘", "D-N", "미결제", "필수", "진행 중") 에 `handEmphasis` 적용. 그러나 클래식 노트북 메타포에서 자필은 **사람의 인격적 메시지** — 시스템 자동 데이터에 자필을 입히면 "가짜 자필" → 메타포 신뢰 훼손.

## UX 분석 — 4계층 작성 주체

| Tier | 주체 | 종류 | 스타일 |
|------|-----|------|--------|
| Tier 1 | 사람 | 자필 본문 (≥1 줄) | `hand` |
| Tier 2 | 사람 | 짧은 자필 강조 / 완료 체크 | `hand` / `handOk` |
| Tier 3 | 시스템 | 안내문·온보딩 톤 (논쟁) | `hand` 또는 Pretendard |
| Tier 4 | 시스템 | 자동 인디케이터·메타 라벨 | `indicatorLabel` (Pretendard italic) |

**의사결정 트리**: "이 텍스트의 작성 주체는 누구인가?" → 사람이면 자필, 시스템이면 인쇄체.

## Phase 1: README §1.1.1 4계층 SSOT 명시 ✅

`docs/specs/design/notebook/README.md` 에 §1.1.1 절 신설:
- 작성 주체별 4 Tier 표
- Tier 4 회피 신호 (5종 키워드 패턴)
- Tier 3 결정 가이드
- 구현 토큰 매핑

## Phase 2: 신규 토큰 `indicatorLabel` 도입 + Tier 4 위반 7지점 정정 ✅

`NotebookTypography.indicatorLabel` 신규 (Pretendard italic 11/700 paperAccent letterSpacing 0.8).

7개 화면 `handEmphasis` → `indicatorLabel`:
- `schedule_tab.dart` "오늘"
- `student_lessons_tab.dart` "오늘"
- `student_practice_tab.dart` "오늘"
- `month_group_header.dart` "진행 중"
- `parent_dashboard_tab.dart` "D-N" (`copyWith(color: paperOk)`) + "미결제"
- `assignment_item.dart` "필수"

## Phase 3: 레퍼토리 곡 메모 Tier 1 보완 ✅

`repertoire_management_widgets.dart` `piece.notes` → `NotebookTypography.hand` (선생님 자필 곡 메모 의도).

## Phase 4: handOk 활성화 — 검토 후 보류

handOk 토큰은 보존. 진정한 Tier 2 (선생님 자필 ✓) 사용처 현재 없음. "저장됨" 등은 시스템 자동 상태 → Tier 4. 자필 ✓ 마킹 UI 도입 시점에 활성화.

## Phase 5: Advisory 훅 신설 ✅

`.claude/hooks/check-handwriting-tier.sh`:
- Tier 4 키워드 (오늘/내일/D-N/미결제/필수/진행 중/대기/완료) 와 자필 스타일 (`hand*`/`Gaegu`) 동일 윈도우 ±10 라인 동시 출현 감지
- stderr 경고 (exit 0 advisory)
- `// ignore: handwriting-tier` 옵트아웃
- `settings.json` 등록 + 자가 검증 (1 위반 케이스 감지, 7 정정 파일 false-positive 0)

## Phase 6: Tier 3 안내문 톤 통일 — 별건 분리

§1.1.1 Tier 3 결정 가이드를 SSOT 로 두고, 시간대 인사·온보딩·빈 상태 안내문 전수 점검은 §7.128 별건 후보로 보존. 일괄 인쇄체 전환은 "선생님 톤" 인격적 메시지 의도 손상 → Lore-rejected.

## 평가 결과

| 기준 | 점수 | 근거 |
|------|------|------|
| 완성도 | 10/10 | Phase 1·2·3·5 완전 적용, Phase 4·6 의식적 보류·분리 |
| 견고성 | 9/10 | flutter analyze 0, 신규 훅 자가 검증 (violation 1, false-positive 0) |
| 일관성 | 9/10 | indicatorLabel 7지점 모두 동일 스타일 + copyWith 의미별 색만 변형 |
| 간결성 | 9/10 | 신규 토큰 1, 신규 훅 1, README 1절 신설, 라인 변경 최소 |
| **가중 평균** | **9.5** | **PASS** |

## 다음 단계

| 작업 | 커맨드 |
|------|--------|
| 커밋·푸시·문서 동기화 | `/commit-push-pr` (이 작업의 마지막 단계) |
| §7.128 Tier 3 안내문 별건 점검 | 향후 별 phase 로 분리 |
