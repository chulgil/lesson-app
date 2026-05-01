# 레슨 피드백 템플릿 (Feedback Template)

> 마지막 업데이트: 2026-05-01

선생님이 레슨 피드백을 빠르게 작성할 수 있도록 본문 템플릿을 미리 등록하고 1탭으로 적용하는 기능.

## 배경

이전 구조: `QuickFeedbackScreen`에 chip line(`feedback_preset` — "음정 주의", "리듬 좋음", "활 주법 연습")으로 본문에 단어를 누적 삽입. 단어 단위 누적은 자연스러운 피드백 문장이 되지 못하고, 선생님은 결국 직접 타이핑하게 되어 chip 사용률이 낮았음.

새 구조: 본문 전체를 갈음하는 **템플릿** 단위로 전환. 템플릿은 프로필에서 사전 등록하고, 피드백 작성 시 시트로 선택.

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

```
QuickFeedbackScreen
  └─ "템플릿 선택" 버튼 (description_outlined 아이콘 / paperAccent)
       └─ FeedbackTemplatePickerSheet (DraggableScrollableSheet 0.75 / max 0.95)
            ├─ 검색 (제목·본문·태그)
            ├─ 카테고리 필터 칩 (전체 + 5개)
            ├─ 자주 사용 섹션 (검색·필터 없을 때만, Top 3)
            └─ 전체 템플릿 섹션
       └─ 선택 시:
            ├─ 본문이 비어 있으면 즉시 교체
            └─ 본문이 있으면 ReplaceFeedbackConfirmDialog → 확인 시 교체
       └─ 교체 후:
            ├─ TextEditingController에 body 전체 대입 (커서 끝)
            ├─ usageCount +1 (unawaited, 비차단)
            └─ 적용 안내 SnackBar
```

기존 chip line(`_buildPresetChips`, `_insertPreset` 외 4개 메서드)은 삭제. 본문 작성 영역 위에 단일 "템플릿 선택" 버튼만 노출.

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
**Q3**: 기존 본문에 append vs 전체 교체 → **교체 + 확인 다이얼로그** (template = 완성된 문장, append는 의미 없음)
**Q4**: tags를 본문에 자동 prepend → **하지 않음** (메타데이터 전용; 검색·필터에만 사용)

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
