# 피드백 템플릿 관리 (프로필)

> 마지막 업데이트: 2026-05-01

선생님이 레슨 피드백 본문 템플릿을 등록·편집·삭제하는 프로필 하위 화면.

## 진입

| 경로 | 메뉴 |
|---|---|
| `/profile/feedback-templates` | 프로필 탭 > **피드백 템플릿** (`description_outlined` 아이콘) |

같은 프로필 탭에 **연습 팁 템플릿**(`/profile/tip-templates`)이 별도 메뉴로 존재. 피드백 템플릿은 **레슨 피드백 본문**용, 팁 템플릿은 **학생에게 보내는 짧은 연습 팁**용으로 사용처 분리.

## 화면 구조

```
AppBar: "피드백 템플릿"
TabBar: 전체 / 기교 / 음악성 / 연습 방법 / 태도 / 일반
ListView (또는 EmptyState):
  └─ Dismissible Card (좌→우 스와이프 = 삭제)
       ├─ Title (bodyLarge.w600)
       ├─ Body (NotebookTypography.hand, 2줄 ellipsis)
       └─ Tags (#tag chips, paperAccentSoft 배경)
FAB: 추가 (FeedbackTemplateFormSheet)
```

## CRUD

| 작업 | UI | Provider |
|---|---|---|
| 추가 | FAB → FormSheet | `feedbackTemplatesNotifierProvider.addTemplate` |
| 편집 | 카드 탭 → FormSheet(`existing`) | `... .updateTemplate` |
| 삭제 | 좌→우 스와이프 → 확인 | `... .deleteTemplate` |

## FormSheet

`features/profile/presentation/widgets/feedback_template_form_sheet.dart`

DraggableScrollableSheet (initial 0.85 / max 0.95) — 키보드 인셋 자동 패딩.

| 필드 | 검증 |
|---|---|
| 제목 (TextField) | 공백만이면 실패 — `feedbackTemplateValidateTitle` |
| 본문 (TextField, maxLines: 8) | 공백만이면 실패 — `feedbackTemplateValidateBody` |
| 카테고리 (ChoiceChip Wrap) | 5개 중 1개 선택 (기본: `general`) |
| 태그 (TextField) | 콤마 구분, `split(',').map(trim).where(isNotEmpty)` |

저장 → SnackBar(`feedbackTemplateAddedSnack` 또는 `Updated`) → `Navigator.pop(true)`.

## 카드 디자인 메모

본문은 `NotebookTypography.hand`(Gaegu 손글씨체)로 노출 — Notebook 디자인 시그니처와 일치. 제목·태그는 `AppTypography.bodyLarge` / `captionSmall` 시스템 폰트로 구분.

## 검증

`test/features/profile/feedback_template_management_screen_test.dart`:
- 화면이 RenderBox/BoxConstraints 크래시 없이 렌더
- 시드 템플릿("음정 주의")이 카드로 표시
