# 연습장 P2 — 제본(Binding) 실행 계획

> 작성: 2026-06-16 (instrument/마이그레이션 게이트 세션에서 사전 조사·계획)
> 마스터 스펙: `docs/specs/practice_journal/practice_journal_master.md` §12 Phase 2, §9.2, §13
> 실행: **새 세션에서** 7-Phase + worktree 로 진행 (이번 세션 컨텍스트 50% 룰 초과로 분리)
> 순서: **P2(제본) → 그다음 swipe Phase 2b** (사용자 지시 "위 순차적으로")

## 목표 (AC — 마스터 §12)

- [ ] 곡(레퍼토리) 완성 시 완성본(`BoundVolume`) 1권 생성, `volumeNo` 자녀 프로필별 1부터 증가(로마 렌더)
- [ ] 책장 화면에서 완성본 / 연습중(점선) 구분
- [ ] 곡 완성 시 "완성본으로 제본" 축하

비목표(P3): 발표회(출판) 연계, 연령 톤 정교화 — 하지 말 것 (YAGNI).

## 이번 세션에서 확정한 사실 (재조사 불필요)

| 항목 | 확정값 |
|---|---|
| **곡 완성 트리거 진원지** | `frontend/lib/features/practice/presentation/providers/repertoire_archive_provider.dart` → `archiveRepertoire(id)` (구현 mixin: `features/practice/data/repositories/impl/mixins/practice_archive_mixin.dart`, 인터페이스: `practice_repertoire_repository.dart`). **여기에 제본을 와이어링**한다 (별도 `features/repertoire/` 없음). |
| 로마숫자 렌더 | `core/theme/notebook_typography.dart:239` `romanOf(int index)` 재사용 |
| 자녀 프로필 | `Student.parentConsentAt`(null=자가연습) + `profileColorKey` (마스터 §13) |
| P1 코드 위치 | `frontend/lib/features/practice_journal/` (entities/repos/providers/screens/widgets 이미 존재) |
| 시그니처 아이콘 | notebook 글리프 정책 적용 영역 — `NotebookGlyph`/`romanOf` (Icons.* 금지, ux-rules HARD-GATE) |

## 파일 계획 (feature: practice_journal)

- `domain/entities/bound_volume.dart` — `BoundVolume{ childProfileId, repertoireId(또는 pieceId), volumeNo:int, boundDate }` (@JsonSerializable, 마스터 §8.1 `BoundVolume`)
- `domain/repositories/practice_journal_repository.dart` — `getBoundVolumes(childProfileId)`, `bindVolume(...)` 추가 (volumeNo = 기존 수 + 1, 멱등: 같은 repertoire 중복 제본 방지)
- `data/repositories/mock_practice_journal_repository.dart` — 위 구현 + 시드
- `presentation/providers/practice_journal_provider.dart` — boundVolumes provider + 제본 service(곡완성→BoundVolume). cross-feature 와이어링은 **facade 경유**(practice_journal_facade ↔ practice repertoire). domain service 는 repository interface 주입(presentation 에서 조립) — flutter-architecture.md 준수.
- `presentation/screens/bound_shelf_screen.dart` — `BoundShelfScreen` (책장, 완성본/연습중 점선 구분)
- `presentation/widgets/bound_volume_spine.dart` — `BoundVolumeSpine` (로마숫자 책등, `romanOf()` + `NotebookTypography.roman`)
- 진입점 wiring: 책장 진입 affordance (학생/부모 홈 연습장 카드 → 책장). "덩그러니" 금지(feedback_entry_point_wiring).
- 트리거 wiring: `repertoire_archive_provider.archiveRepertoire()` 성공 후 제본 service 호출 + 축하 (read provider invalidate 필수 — feedback_provider_read_write_split).

## 테스트 계획

- 도메인 유닛: volumeNo 증가(자녀별 1부터), 중복 제본 방지, 2자 fallback(이름).
- **widget smoke (HARD-GATE)**: `bound_shelf_screen_test.dart`, `bound_volume_spine_test.dart` — pumpWidget + pumpAndSettle + `expect(tester.takeException(), isNull)`.
- 트리거 회귀: archiveRepertoire → BoundVolume 생성 + 책장 갱신 (실제 write→read, read override 금지 — Oracle Problem).

## 주의 (이전 세션 학습)

- glossary: `BoundVolume`/`완성본`/`제본` 용어 일치 (`.harness/knowledge/glossary.md` 확인·필요시 추가).
- AppStrings/core/l10n — 하드코딩 한글 금지. domain/data 에서 l10n import 금지(presentation 변환).
- MarkIntensity 임계값 신설 금지 — practice 도메인 SSOT 재사용(P2는 BoundVolume 중심이라 대개 무관).
- 패키지명 `lessonaza`.
- worktree 에서 작업, 검증(flutter analyze 0 + 테스트) 통과 후만 main merge.

## 다음 (P2 완료 후)

swipe Phase 2b: `schedule_tab` Dismissible → SwipeActionTile 일원화 + popup 흡수 2곳 (고트래픽 — 신중). 메모리 `project_swipe_bidirectional` 참조.
