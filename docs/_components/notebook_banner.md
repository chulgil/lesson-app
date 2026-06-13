<!-- @defines: components/notebook_banner -->
<!-- @uses: tokens/colors, tokens/typography, tokens/spacing -->

# NotebookBanner (마지널리아 스트립 배너)

> 버전: 1.0 (2026-06-13)
> 구현: `frontend/lib/core/widgets/notebook/notebook_banner.dart`
> 스펙 SSOT: `docs/specs/design/notebook/README.md` §1.1(시그니처)·§1.3.1(각진)

크림 종이 위에 적은 **손글씨 주석** 메타포의 인라인 배너 공통 셸. 시간대 인사,
다음 레슨 안내, 휴무 안내 등 "종이 가장자리 메모" 성격의 알림에 사용한다.

## 구조

```
| 메시지 영역 .......................... [trailing] |
^ 좌측 3px accent 세로선 (Vermillion 기본)
  [icon] Gaegu 손글씨 메시지
```

- 배경: 투명 (paper 직접 노출) — fill 금지
- 좌측: 3px `accent` 세로선 (4대 시그니처 Vermillion)
- 본문: Gaegu 손글씨 (`NotebookTypography.hand` 기본)
- 각진 (BorderRadius 없음, §1.3.1)

## Props

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `message` | `String` | O | — | 본문 문구 (손글씨 주석) |
| `messageStyle` | `TextStyle?` | X | `NotebookTypography.hand` | 본문 스타일 override |
| `leadingIcon` | `IconData?` | X | null | 좌측 리딩 아이콘 (size 20, ink) |
| `accent` | `Color` | X | `AppColors.paperAccent` | 좌측 3px 세로선 색 |
| `trailing` | `Widget?` | X | null | 우측 인라인 액션/닫기 |
| `margin` | `EdgeInsetsGeometry` | X | `bottom: space4` | 외곽 margin |
| `padding` | `EdgeInsetsGeometry` | X | `all(space3)` | 내부 padding |

## 사용 원칙 (HARD-GATE)

- **시각 셸만 제공.** 메시지 텍스트·표시 조건 같은 도메인 로직은 호출부가 소유하고
  이 위젯을 조립한다 (예: `TimeContextBanner` 가 시간대 로직 + NotebookBanner 셸).
- **accent 색**: 일반 Vermillion. 체험레슨 맥락은 `AppColors.paperTrial`, 완료/안정은
  `AppColors.paperOk` (§2.1 3색 잉크 체계).

## 이 원형이 아닌 것 (refit 대상)

배너 12종 중 3개 원형이 혼재. NotebookBanner 는 ① 만 담당:

| 원형 | 예 | 처리 |
|------|----|------|
| ① 마지널리아 스트립 | `time_context_banner` | **NotebookBanner 사용** |
| ② NotebookCard 행 | `app_update_banner` | `NotebookCard` 유지 |
| ③ 채워진 프로모 카드 | `lifetime_promo_banner` | drift — ①/② 로 refit |

> 채워진 `color: paperAccent` 배경 + eyebrow + 대형 CTA 형태는 이 원형이 아니다.
> 정비 추적: `docs/specs/design/notebook/token_drift_remediation.md`.

## @used-by

- `features/home/.../time_context_banner.dart` (시간대 인사 — SSOT 레퍼런스)
