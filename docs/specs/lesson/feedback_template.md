# 레슨 피드백 템플릿 (Feedback Template)

> 마지막 업데이트: 2026-05-01 (§7.136 마지널리아 패턴 + §7.137 다중 누적 반영)

선생님이 레슨 피드백을 빠르게 작성할 수 있도록 본문 템플릿을 미리 등록하고 1탭으로 적용하는 기능.

## 배경

이전 구조: `QuickFeedbackScreen` / `LessonNoteEditor`(레슨 상세) 양쪽에 chip line(`feedback_preset` — "음정 주의", "리듬 좋음", "활 주법 연습")으로 본문에 단어를 누적 삽입. 단어 단위 누적은 자연스러운 피드백 문장이 되지 못하고, 선생님은 결국 직접 타이핑하게 되어 chip 사용률이 낮았음.

새 구조: 본문 전체를 갈음하는 **템플릿** 단위로 전환. 템플릿은 프로필에서 사전 등록하고, 피드백 작성 시 시트로 선택. 두 진입점(`QuickFeedbackScreen`, `LessonNoteEditor`)에서 동일 패턴.

## 도메인 모델

`features/lessons/domain/entities/feedback_template.dart`

- `id` `String` — UUID
- `title` `String` — 템플릿 제목 (예: "박자 늘어짐 지적")
- `body` `String` — 피드백 본문 전체 (수십~수백자)
- `tags` `List<String>` — 검색·필터용 태그 (예: ["박자", "기초"])
- `category` `FeedbackCategory` — `technique` / `musicality` / `practice` / `attitude` / `general`
- `usageCount` `int` — 사용 시마다 +1, "자주 사용" 정렬 키
- `createdAt` / `updatedAt` `DateTime`

`FeedbackCategory.label` — 한국어 라벨(`기교`, `음악성`, `연습 방법`, `태도`, `일반`)

## 레이어

| 레이어 | 파일 |
|---|---|
| Entity | `features/lessons/domain/entities/feedback_template.dart` |
| Repository (interface) | `features/lessons/domain/repositories/feedback_template_repository.dart` |
| Repository (Mock) | 같은 파일의 `MockFeedbackTemplateRepository` (9개 시드) |
| Provider | `features/lessons/presentation/providers/feedback_template_providers.dart` |
| 관리 화면 | `features/profile/presentation/screens/feedback_template_management_screen.dart` |
| 추가/편집 시트 | `features/profile/presentation/widgets/feedback_template_form_sheet.dart` |
| 선택 시트 | `features/lessons/presentation/widgets/feedback_template_picker_sheet.dart` |
| 교체 확인 | `features/lessons/presentation/widgets/replace_feedback_confirm_dialog.dart` |

## Provider 구성

- `feedbackTemplatesProvider` — 전체 목록
- `feedbackTemplatesByCategoryProvider(FeedbackCategory)` — 카테고리 필터
- `frequentFeedbackTemplatesProvider` — 사용량 Top 3
- `feedbackTemplateSearchProvider(String)` — 제목·본문·태그 검색
- `feedbackTemplatesNotifierProvider` — `addTemplate / updateTemplate / deleteTemplate / useTemplate(id)` 변경 작업

CRUD는 변경 후 위 Future*Providers를 invalidate해 화면이 자동 리프레시.

## 작성자(선생님) 흐름

진입점은 두 곳, 같은 패턴:

| 진입점 | 위치 | 트리거 |
|---|---|---|
| `QuickFeedbackScreen` | 학생 리스트에서 "빠른 피드백" 진입 | 본문 영역 위 단일 버튼 |
| `LessonNoteEditor` | 레슨 상세 화면 (선생님 시점) `lessonFeedbackHeader` 섹션 | 본문 영역 위 단일 버튼 |

```
[진입점]
  └─ 마지널리아 행 — `※ 템플릿으로 피드백 추가` (NotebookGlyph.referenceMark
     + NotebookTypography.handEmphasis / paperAccent / InkWell)
       └─ FeedbackTemplatePickerSheet (DraggableScrollableSheet 0.75 / max 0.95)
            ├─ 검색 (제목·본문·태그)
            ├─ 카테고리 필터 칩 (전체 + 5개)
            ├─ 자주 사용 섹션 (검색·필터 없을 때만, Top 3)
            └─ 전체 템플릿 섹션
       └─ 선택 시 (다중 누적 §7.137):
            ├─ 본문이 비어 있으면 그대로 삽입 → SnackBar "적용했습니다"
            └─ 본문이 있으면 `trimRight() + '\n\n' + 신규 body` 끝에 append
                → SnackBar "추가되었습니다"
       └─ 적용 후:
            ├─ Undo snapshot push (적용 직전 본문)
            ├─ TextEditingController에 합쳐진 본문 대입 (커서 끝)
            ├─ TextField scrollController.maxScrollExtent 로 200ms easeOut 스크롤
            │   (append된 새 본문 끝이 시야에 들어오도록)
            └─ usageCount +1 (unawaited, 비차단)
```

기존 chip line(`_buildPresetChips`, `_insertPreset` 외 4개 메서드 / `feedbackPresets` 상수)은 두 진입점 모두에서 삭제. 본문 작성 영역 위에 단일 "템플릿으로 피드백 추가" 마지널리아 행만 노출.

`feedbackPresets` 상수 자체는 `MockFeedbackTemplateRepository` 시드 정합 검증(`feedback_template_repository.dart`)에서 길이 비교에 사용되므로 보존. UI 진입점에서만 제거.

## 되돌리기 (Undo)

선생님이 본문을 잘못 교체하거나 타이핑 실수를 즉시 회복할 수 있도록, 작성 필드 우하단에 단일 Undo 아이콘을 노출.

| 항목 | 결정 |
|---|---|
| 위치 | 본문 위 **마지널리아 행** 우측 (`Icons.undo`, 18px). Stack overlay 폐기 — 템플릿 추가 액션과 한 쌍이므로 같은 행에 정렬 (LessonNoteEditor §7.136). QuickFeedbackScreen 은 Undo 미적용 (신규 작성). |
| 색상 | 비활성: `inkTertiary` / 활성: `paperAccent` |
| Tooltip | "되돌리기" |
| Snapshot 단위 | 타이핑 정지 1.5초 debounce + 템플릿 적용 시 즉시 push |
| Snapshot stack 최대 | 20개 (FIFO drop) |
| Undo 후 동작 | 직전 snapshot 복원 → `_onChanged` 경유로 자동 저장 동기화 → SnackBar "되돌렸습니다" |
| 비활성 조건 | snapshot stack이 비었을 때 (초기 진입 baseline 포함) |

**Undo 비포함 (의도)**:
- Redo (한 번 되돌리면 끝) — v1 단순화
- 글자 단위 undo — 사용자 의도가 "묶음 단위" 회복이므로 debounce 묶음으로 충분
- 다른 위젯(KeyPoints, PracticeTips)으로 확장 — 본 스펙은 피드백 본문 한정

**시그니처 영역 외 Material 아이콘 허용** — `lesson_notes_widgets.dart`는 Notebook×Score §9 일반 영역(navigation/utility)에 해당. 단, 템플릿 트리거는 §7.136 에서 손맛 메타포가 더 적합하다고 판단하여 NotebookGlyph + Gaegu 마지널리아로 채택. Undo 는 시스템 affordance 컨벤션(되돌리기 = `↶`)을 따라 Material 유지.

## 관리자(선생님) 흐름

`프로필 탭 > 피드백 템플릿`(`/profile/feedback-templates`)에서:

- TabBar: 전체 + 5개 카테고리
- 카드: 제목(`bodyLarge.w600`) + 본문(`NotebookTypography.hand`, 2줄 ellipsis) + 태그(`#tag`)
- 좌→우 스와이프: 삭제 확인
- FAB: `FeedbackTemplateFormSheet`(추가)
- 카드 탭: `FeedbackTemplateFormSheet`(편집)

기존 "연습 팁 템플릿"(`tipTemplateManagement`)은 별도 메뉴(`tips_and_updates_outlined`)로 분리해 그대로 유지.

## UX 의사결정

**Q1**: TipTemplate 재사용 vs 신규 entity → **신규** (피드백/팁은 본문 길이·사용 빈도가 다르고 카테고리 체계도 다름)
**Q2**: chip line 잔존 vs 제거 → **제거** (사용률 낮음, 짧은 단어 누적은 결국 본문이 되지 못함)
**Q3** (§7.137 갱신): 기존 본문에 append vs 전체 교체 → **append 누적 채택**. 처음 결정은 "교체 + 확인 다이얼로그"였으나 실사용에서 선생님은 한 레슨에 **여러 측면**(예: "박자" + "활 주법" + "표현")을 한 번에 피드백하는 패턴이 자연스러움. 교체는 두 번째 템플릿 선택 시 첫 번째 내용을 잃어 누적 작성을 막는 마찰. → 빈 본문은 그대로 삽입, 기존 본문이 있으면 `trimRight() + '\n\n' + 신규` 로 끝에 append. 확인 다이얼로그(`ReplaceFeedbackConfirmDialog` 호출처) 제거. 위젯 자체는 보존(추후 "교체" 옵션 도입 시 재사용 가능).
**Q4**: tags를 본문에 자동 prepend → **하지 않음** (메타데이터 전용; 검색·필터에만 사용)
**Q5** (§7.137 갱신): 두 진입점 라벨 통일 → 변천 "템플릿 선택"(모호) → "템플릿 가져오기"(1회성 import 뉘앙스) → **"템플릿으로 피드백 추가"** 채택. §7.137 누적 추가가 본질이 된 후 "가져오기"는 1회성 import 뉘앙스로 누적 의도가 약함. 메모 톤 명사화로 Gaegu 손글씨 영역과 정렬, "피드백" 명시로 진입점 컨텍스트 강화.
**Q6**: Undo snapshot 단위 — 글자 vs 묶음 → **debounce 1.5s 묶음 + 템플릿 적용 즉시** (글자 단위는 무용지물)
**Q7**: Undo 활성 시 색상 강조 — 회색 고정 vs `paperAccent` → **활성 시 `paperAccent`** (행동 가능 시그널)
**Q8** (§7.136): 템플릿 트리거 형태 — OutlinedButton + Material `description_outlined` vs **마지널리아 행** (`※` + Gaegu) → **마지널리아 행 채택**. 본문이 Gaegu 손글씨 영역인데 OutlinedButton paperAccent 테두리는 "교과서 위 디지털 툴바" 느낌으로 시각적 무게가 본문 컨테이너와 경합. `※`(NotebookGlyph.referenceMark) + Gaegu handEmphasis 라벨은 **여백 주석** 메타포로 본문 위 28px 한 행에 가볍게 얹혀, 액션-본문 시선 단절을 제거. LessonNoteEditor 는 Undo 와 한 쌍으로 같은 행 좌우 배치 (Stack overlay 폐기). `description_outlined` Material 아이콘은 §9 일반 영역이라 허용되긴 하나, 본 화면에서는 손맛 메타포가 우세.

## 검증

| 검증 | 위치 |
|---|---|
| 관리 화면 smoke test | `test/features/profile/feedback_template_management_screen_test.dart` |
| 선택 시트 smoke test | `test/features/lessons/presentation/widgets/feedback_template_picker_sheet_test.dart` |
| `flutter analyze` | clean (전체 프로젝트) |

## 향후 (Phase B 후보)

- 사용 통계 대시보드 (`usageCount` 시각화)
- 백엔드 영속화 (현재 Mock in-memory)
- 템플릿 공유 (선생님 간)
- 학생별 가중치 (특정 학생에게 자주 쓰는 템플릿 상단 노출)

## 코드 반영 추가 (2026-06-03)

> "배경"에서 `feedback_preset` chip line은 UI 진입점에서 제거됐다고 명시하나, **`FeedbackPreset` 엔티티/레포지토리/프로바이더는 코드에 그대로 활성 상태**다. 시드 정합 검증용으로만 남은 것이 아니라, 별도 CRUD 스택과 실제 백엔드 API가 동작한다.

### FeedbackPreset 엔티티 (활성)

`features/lessons/domain/entities/feedback_preset.dart`

| 필드 | 타입 | 설명 |
|---|---|---|
| `id` | `String` | UUID |
| `text` | `String` | 프리셋 짧은 문구 (예: "음정 주의") |
| `teacherId` | `String?` | 소유 선생님 (null = 기본 프리셋) |
| `sortOrder` | `int` | 노출 정렬 순서 |
| `isDefault` | `bool` | 시스템 기본 제공 프리셋 여부 |
| `isHidden` | `bool` | 선생님이 숨김 처리 (soft delete) |
| `createdAt` | `DateTime` | 생성 시각 |

### 레이어

| 레이어 | 파일 |
|---|---|
| Repository (interface) | `features/lessons/domain/repositories/feedback_preset_repository.dart` — `getPresets / addPreset / updatePreset / deletePreset / restorePreset` |
| Repository (Mock) | `features/lessons/data/repositories/mock_feedback_preset_repository.dart` |
| Repository (Remote) | `features/lessons/data/repositories/remote_feedback_preset_repository.dart` — 백엔드 `/settings/feedback-presets` (GET/POST/PATCH/DELETE) |
| Provider | `features/lessons/presentation/providers/feedback_preset_providers.dart` — `FeedbackPresetNotifier` (`addPreset / updatePreset / deletePreset`) |
| 사용 화면 | `features/lessons/presentation/screens/bulk_feedback_screen.dart` (일괄 피드백 작성 시 프리셋 칩 사용) |

> 결론: 프리셋은 레슨 상세/빠른 피드백의 **본문 누적 chip line**에서만 제거됐고, 일괄 피드백(BulkFeedbackScreen) 경로에서는 계속 사용된다. `isHidden`/`restorePreset`은 숨김-복원 soft delete 패턴을 지원한다.
