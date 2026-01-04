# 스페이싱 토큰

> ID: `tokens/spacing`
> 버전: 1.0
> 소스: `lib/core/theme/app_spacing.dart`

<!-- @defines: tokens/spacing -->

---

## 1. 기본 스케일 (8pt Grid)

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `space.0` | 0px | - |
| `space.1` | 4px | 아이콘 내부, 미세 간격 |
| `space.2` | 8px | 요소 내부 패딩 |
| `space.3` | 12px | 컴팩트 패딩 |
| `space.4` | 16px | 기본 패딩/마진 |
| `space.5` | 20px | 섹션 내부 간격 |
| `space.6` | 24px | 카드 패딩 |
| `space.8` | 32px | 섹션 간격 |
| `space.10` | 40px | 큰 섹션 간격 |
| `space.12` | 48px | 페이지 상단 여백 |
| `space.16` | 64px | 대형 간격 |

---

## 2. 공통 레이아웃 값

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `space.screen` | 16px | 화면 좌우 패딩 |
| `space.card` | 16px | 카드 내부 패딩 |
| `space.section` | 24px | 섹션 간 간격 |

---

## 3. 컴포넌트 높이

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `height.header` | 56px | 앱바 높이 |
| `height.tabBar` | 56px | 탭바 높이 |
| `height.button` | 48px | 기본 버튼 높이 |
| `height.button.small` | 40px | 작은 버튼 높이 |
| `height.input` | 48px | 입력 필드 높이 |
| `height.listItem` | 56px | 기본 리스트 아이템 |
| `height.listItem.large` | 72px | 두 줄 리스트 아이템 |

---

## 4. 보더 라디우스

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `radius.small` | 4px | 체크박스, 미세 둥글기 |
| `radius.medium` | 8px | 입력 필드, 버튼 |
| `radius.large` | 12px | 카드 |
| `radius.xlarge` | 16px | 바텀시트 상단 |
| `radius.round` | 100px | 원형 버튼, 배지 |

---

## 5. 아이콘 크기

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `icon.xs` | 16px | 인라인, 배지 내부 |
| `icon.sm` | 20px | 버튼 내부, 리스트 |
| `icon.md` | 24px | 기본 아이콘 |
| `icon.lg` | 32px | 탭바, 카드 강조 |
| `icon.xl` | 48px | 빈 상태, 온보딩 |
| `icon.2xl` | 64px | 스플래시, 히어로 |

---

## 6. 아바타 크기

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `avatar.small` | 32px | 작은 프로필 |
| `avatar.medium` | 48px | 기본 프로필 |
| `avatar.large` | 64px | 상세 화면 프로필 |

---

## 7. 화면 레이아웃 가이드

```
┌─────────────────────────────────┐
│         Safe Area Top           │  (Dynamic)
├─────────────────────────────────┤
│  ←  페이지 제목            [액션] │  Header: 56px
├─────────────────────────────────┤
│◄─►                           ◄─►│
│16px                          16px│  Horizontal Padding
│                                 │
│         Content Area            │
│                                 │
├─────────────────────────────────┤
│  [🏠]   [📅]   [👥]   [👤]    │  Tab Bar: 56px + Safe Area
└─────────────────────────────────┘
```

---

## 사용처

<!-- @used-by: 모든 스펙 문서 -->

모든 UI 스펙 문서에서 간격/크기 참조 시 이 토큰 사용

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 토큰 정의 (AppSpacing에서 추출) |
