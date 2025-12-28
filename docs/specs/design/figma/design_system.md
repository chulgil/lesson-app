# Lesson App 디자인 시스템

> **버전**: 1.0
>
> **참조 템플릿**: [Music App UI Kit](https://www.figma.com/design/xydMYjbMvpS1o89KMXtNKZ/)
>
> **목적**: Flutter 구현 및 Figma 디자인 일관성 유지

---

## 목차

1. [색상 시스템](#1-색상-시스템)
2. [타이포그래피](#2-타이포그래피)
3. [아이콘](#3-아이콘)
4. [스페이싱 & 그리드](#4-스페이싱--그리드)
5. [컴포넌트](#5-컴포넌트)
6. [상태 & 피드백](#6-상태--피드백)
7. [모션 & 애니메이션](#7-모션--애니메이션)

---

## 1. 색상 시스템

### 1.1 브랜드 컬러

> 음악/클래식 느낌의 따뜻하고 우아한 색상 팔레트

| 이름 | Light Mode | Dark Mode | 용도 |
|------|------------|-----------|------|
| **Primary** | `#6B5B95` | `#8B7BB5` | 주요 액션, 브랜드 아이덴티티 |
| **Primary Light** | `#9A8BC4` | `#A99BD4` | 호버, 선택된 상태 |
| **Primary Dark** | `#4A3D6E` | `#6B5B95` | 텍스트, 강조 |
| **Secondary** | `#F4A460` | `#F4A460` | 보조 액션, 악기 느낌 |
| **Secondary Light** | `#F7C490` | `#F7C490` | 배경 강조 |

### 1.2 시맨틱 컬러

| 이름 | Light Mode | Dark Mode | 용도 |
|------|------------|-----------|------|
| **Success** | `#2E8B57` | `#3DA86B` | 완료, 성공 |
| **Warning** | `#F4A460` | `#F4A460` | 주의, 경고 |
| **Error** | `#DC143C` | `#E84057` | 에러, 삭제 |
| **Info** | `#4A90D9` | `#5BA3EC` | 정보 |

### 1.3 연습 상태 컬러

| 상태 | 색상 | HEX | 설명 |
|------|------|-----|------|
| 🟢 좋음 | Green | `#2E8B57` | 연습률 70% 이상 |
| 🟡 보통 | Orange | `#F4A460` | 연습률 40-70% |
| 🔴 부족 | Red | `#DC143C` | 연습률 40% 미만 |
| ⚪ 휴강 | Gray | `#9E9E9E` | 휴강 상태 |
| 🔵 진행중 | Primary | `#6B5B95` | 현재 진행 중 |

### 1.4 중립 컬러 (Neutral)

#### Light Mode

| 이름 | HEX | 용도 |
|------|-----|------|
| **Background** | `#FFFAF5` | 메인 배경 (아이보리) |
| **Surface** | `#FFFFFF` | 카드, 시트 배경 |
| **Surface Secondary** | `#F5F0EB` | 구분선, 보조 배경 |
| **Border** | `#E5E0DB` | 테두리 |
| **Text Primary** | `#1A1A1A` | 제목, 본문 |
| **Text Secondary** | `#666666` | 부가 설명 |
| **Text Tertiary** | `#999999` | 플레이스홀더 |
| **Text Disabled** | `#CCCCCC` | 비활성 텍스트 |

#### Dark Mode

| 이름 | HEX | 용도 |
|------|-----|------|
| **Background** | `#1A1A2E` | 메인 배경 |
| **Surface** | `#252540` | 카드, 시트 배경 |
| **Surface Secondary** | `#303050` | 구분선, 보조 배경 |
| **Border** | `#404060` | 테두리 |
| **Text Primary** | `#FFFFFF` | 제목, 본문 |
| **Text Secondary** | `#B0B0B0` | 부가 설명 |
| **Text Tertiary** | `#808080` | 플레이스홀더 |
| **Text Disabled** | `#505050` | 비활성 텍스트 |

### 1.5 Flutter 코드

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Primary
  static const primary = Color(0xFF6B5B95);
  static const primaryLight = Color(0xFF9A8BC4);
  static const primaryDark = Color(0xFF4A3D6E);

  // Secondary
  static const secondary = Color(0xFFF4A460);
  static const secondaryLight = Color(0xFFF7C490);

  // Semantic
  static const success = Color(0xFF2E8B57);
  static const warning = Color(0xFFF4A460);
  static const error = Color(0xFFDC143C);
  static const info = Color(0xFF4A90D9);

  // Practice Status
  static const practiceGood = Color(0xFF2E8B57);
  static const practiceNormal = Color(0xFFF4A460);
  static const practicePoor = Color(0xFFDC143C);
  static const practicePaused = Color(0xFF9E9E9E);

  // Light Mode
  static const backgroundLight = Color(0xFFFFFAF5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF1A1A1A);
  static const textSecondaryLight = Color(0xFF666666);

  // Dark Mode
  static const backgroundDark = Color(0xFF1A1A2E);
  static const surfaceDark = Color(0xFF252540);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFFB0B0B0);
}
```

### 1.6 Figma 색상 변수

```
Colors/
├── Primary/
│   ├── primary-500     #6B5B95
│   ├── primary-400     #9A8BC4
│   └── primary-600     #4A3D6E
├── Secondary/
│   ├── secondary-500   #F4A460
│   └── secondary-400   #F7C490
├── Semantic/
│   ├── success         #2E8B57
│   ├── warning         #F4A460
│   ├── error           #DC143C
│   └── info            #4A90D9
├── Neutral-Light/
│   ├── background      #FFFAF5
│   ├── surface         #FFFFFF
│   ├── text-primary    #1A1A1A
│   └── text-secondary  #666666
└── Neutral-Dark/
    ├── background      #1A1A2E
    ├── surface         #252540
    ├── text-primary    #FFFFFF
    └── text-secondary  #B0B0B0
```

---

## 2. 타이포그래피

### 2.1 폰트 패밀리

| 용도 | 폰트 | 비고 |
|------|------|------|
| **기본** | Pretendard | 한글/영문 모두 지원 |
| **음악 기호** | Noto Music | 음표, 음자리표 등 |
| **숫자 강조** | SF Pro Display | 통계, 시간 표시 |

### 2.2 폰트 스케일

| 스타일 | 크기 | 줄높이 | 굵기 | 용도 |
|--------|------|--------|------|------|
| **Display Large** | 32px | 40px | Bold (700) | 스플래시, 온보딩 제목 |
| **Display Medium** | 28px | 36px | Bold (700) | 페이지 대제목 |
| **Heading Large** | 24px | 32px | SemiBold (600) | 섹션 제목 |
| **Heading Medium** | 20px | 28px | SemiBold (600) | 카드 제목 |
| **Heading Small** | 18px | 24px | SemiBold (600) | 서브 제목 |
| **Body Large** | 16px | 24px | Regular (400) | 본문 텍스트 |
| **Body Medium** | 14px | 20px | Regular (400) | 일반 설명 |
| **Body Small** | 12px | 16px | Regular (400) | 보조 정보 |
| **Caption** | 11px | 14px | Regular (400) | 타임스탬프, 라벨 |
| **Button** | 16px | 24px | SemiBold (600) | 버튼 텍스트 |
| **Button Small** | 14px | 20px | Medium (500) | 작은 버튼 |

### 2.3 Flutter 코드

```dart
// lib/core/theme/app_typography.dart

class AppTypography {
  static const String fontFamily = 'Pretendard';

  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.29,
    fontWeight: FontWeight.w700,
  );

  static const headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  static const headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  static const headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.33,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.33,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.27,
    fontWeight: FontWeight.w400,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
}
```

### 2.4 텍스트 스타일 가이드

```
제목 계층:
Display Large   → 앱 타이틀, 온보딩
Display Medium  → 페이지 제목
Heading Large   → 섹션 제목 ("오늘의 레슨")
Heading Medium  → 카드 제목 (학생 이름, 곡명)
Heading Small   → 리스트 항목 제목

본문 계층:
Body Large      → 주요 설명, 메모 내용
Body Medium     → 일반 설명, 리스트 항목
Body Small      → 보조 정보, 태그

보조 정보:
Caption         → 날짜, 시간, 상태 라벨
```

---

## 3. 아이콘

### 3.1 아이콘 시스템

| 라이브러리 | 용도 |
|-----------|------|
| **Material Icons** | 기본 UI 아이콘 |
| **Custom Icons** | 악기, 음악 관련 |

### 3.2 아이콘 크기

| 크기 | 픽셀 | 용도 |
|------|------|------|
| **XS** | 16px | 인라인, 배지 내부 |
| **SM** | 20px | 버튼 내부, 리스트 |
| **MD** | 24px | 기본 아이콘 |
| **LG** | 32px | 탭바, 카드 강조 |
| **XL** | 48px | 빈 상태, 온보딩 |
| **2XL** | 64px | 스플래시, 히어로 |

### 3.3 주요 아이콘 목록

#### 네비게이션

| 이름 | 아이콘 | Material Icon |
|------|--------|---------------|
| 홈 | 🏠 | `home` / `home_outlined` |
| 캘린더 | 📅 | `calendar_today` / `calendar_today_outlined` |
| 학생 | 👥 | `people` / `people_outlined` |
| 연습 | 📝 | `assignment` / `assignment_outlined` |
| 프로필 | 👤 | `person` / `person_outlined` |

#### 레슨/연습

| 이름 | 아이콘 | Material Icon |
|------|--------|---------------|
| 녹음 | 🎤 | `mic` |
| 녹음 중 | 🔴 | `fiber_manual_record` (red) |
| 재생 | ▶️ | `play_arrow` |
| 일시정지 | ⏸️ | `pause` |
| 정지 | ⏹️ | `stop` |
| 체크 | ✓ | `check` |
| 체크박스 | ☐/☑ | `check_box_outline_blank` / `check_box` |

#### 악기 (커스텀)

| 이름 | 이모지 | 파일명 |
|------|--------|--------|
| 바이올린 | 🎻 | `ic_violin.svg` |
| 피아노 | 🎹 | `ic_piano.svg` |
| 첼로 | 🎻 | `ic_cello.svg` |
| 플루트 | 🎵 | `ic_flute.svg` |
| 기타 | 🎸 | `ic_guitar.svg` |

#### 액션

| 이름 | Material Icon |
|------|---------------|
| 뒤로 | `arrow_back` |
| 닫기 | `close` |
| 추가 | `add` |
| 더보기 | `more_vert` |
| 편집 | `edit` |
| 삭제 | `delete` |
| 검색 | `search` |
| 필터 | `filter_list` |
| 알림 | `notifications` / `notifications_outlined` |
| 설정 | `settings` |

### 3.4 아이콘 컬러

| 상태 | Light Mode | Dark Mode |
|------|------------|-----------|
| 기본 | `#666666` | `#B0B0B0` |
| 활성 | `#6B5B95` (Primary) | `#8B7BB5` |
| 비활성 | `#CCCCCC` | `#505050` |
| 흰색 | `#FFFFFF` | `#FFFFFF` |

---

## 4. 스페이싱 & 그리드

### 4.1 스페이싱 스케일 (8pt Grid)

| 토큰 | 크기 | 용도 |
|------|------|------|
| `space-0` | 0px | - |
| `space-1` | 4px | 아이콘 내부, 미세 간격 |
| `space-2` | 8px | 요소 내부 패딩 |
| `space-3` | 12px | 컴팩트 패딩 |
| `space-4` | 16px | 기본 패딩/마진 |
| `space-5` | 20px | 섹션 내부 간격 |
| `space-6` | 24px | 카드 패딩 |
| `space-8` | 32px | 섹션 간격 |
| `space-10` | 40px | 큰 섹션 간격 |
| `space-12` | 48px | 페이지 상단 여백 |
| `space-16` | 64px | 대형 간격 |

### 4.2 화면 레이아웃

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
│                                 │
├─────────────────────────────────┤
│  [🏠]   [📅]   [👥]   [👤]    │  Tab Bar: 56px + Safe Area
│         Safe Area Bottom        │
└─────────────────────────────────┘
```

### 4.3 그리드 시스템

| 속성 | 값 |
|------|-----|
| **Columns** | 4 |
| **Gutter** | 16px |
| **Margin** | 16px (좌우) |
| **Screen Width** | 393px (iPhone 14 Pro 기준) |

### 4.4 Flutter 코드

```dart
// lib/core/theme/app_spacing.dart

class AppSpacing {
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // Common
  static const double screenPadding = 16;
  static const double cardPadding = 16;
  static const double sectionSpacing = 24;

  // Heights
  static const double headerHeight = 56;
  static const double tabBarHeight = 56;
  static const double buttonHeight = 48;
  static const double inputHeight = 48;
}
```

---

## 5. 컴포넌트

### 5.1 버튼 (Buttons)

#### Primary Button

```
┌─────────────────────────────────┐
│           버튼 텍스트             │
└─────────────────────────────────┘

- Height: 48px
- Border Radius: 12px
- Background: Primary (#6B5B95)
- Text: White, Button (16px SemiBold)
- Padding: 16px 24px
```

| 상태 | Background | Text |
|------|------------|------|
| Default | `#6B5B95` | White |
| Pressed | `#4A3D6E` | White |
| Disabled | `#E5E0DB` | `#999999` |
| Loading | `#6B5B95` + Spinner | - |

#### Secondary Button

```
┌─────────────────────────────────┐
│           버튼 텍스트             │
└─────────────────────────────────┘

- Height: 48px
- Border Radius: 12px
- Background: Transparent
- Border: 1px Primary (#6B5B95)
- Text: Primary, Button (16px SemiBold)
```

#### Text Button

```
           버튼 텍스트

- Height: 40px
- Background: Transparent
- Text: Primary, Body Medium (14px)
```

#### Icon Button

```
  ┌────┐
  │ 🔔 │
  └────┘

- Size: 40x40px (터치 영역: 48x48)
- Border Radius: 20px (원형)
- Icon Size: 24px
```

#### Social Login Buttons

```
┌─────────────────────────────────┐
│  [G]  Google로 계속하기          │
└─────────────────────────────────┘
- Background: #FFFFFF
- Border: 1px #E5E0DB
- Icon: Google Logo 20px
- Text: #1A1A1A

┌─────────────────────────────────┐
│  [K]  카카오로 계속하기           │
└─────────────────────────────────┘
- Background: #FEE500
- Icon: Kakao Logo 20px
- Text: #1A1A1A

┌─────────────────────────────────┐
│  []  Apple로 계속하기           │
└─────────────────────────────────┘
- Background: #000000
- Icon: Apple Logo 20px
- Text: #FFFFFF
```

### 5.2 입력 필드 (Inputs)

#### Text Input

```
  레이블
  ┌─────────────────────────────┐
  │ 플레이스홀더 텍스트...        │
  └─────────────────────────────┘
  도움말 텍스트

- Height: 48px
- Border Radius: 8px
- Border: 1px #E5E0DB (Default), #6B5B95 (Focus)
- Background: #FFFFFF
- Padding: 12px 16px
- Label: Body Small, Text Secondary
- Placeholder: Body Medium, Text Tertiary
- Helper: Caption, Text Secondary
```

| 상태 | Border | Background |
|------|--------|------------|
| Default | `#E5E0DB` | White |
| Focus | `#6B5B95` | White |
| Error | `#DC143C` | `#FFF5F5` |
| Disabled | `#E5E0DB` | `#F5F0EB` |

#### Search Input

```
  ┌─────────────────────────────┐
  │ 🔍 검색어를 입력하세요...      │
  └─────────────────────────────┘

- Height: 44px
- Border Radius: 22px (pill shape)
- Background: #F5F0EB (Light), #303050 (Dark)
- Icon: 20px, Text Secondary
```

### 5.3 카드 (Cards)

#### 기본 카드

```
┌─────────────────────────────────┐
│  [아이콘]  제목            [→]  │
│           부제목                │
│           추가 정보             │
└─────────────────────────────────┘

- Border Radius: 12px
- Background: Surface (White / #252540)
- Shadow: 0 2px 8px rgba(0,0,0,0.08)
- Padding: 16px
```

#### 레슨 카드

```
┌─────────────────────────────────┐
│  🎻 14:00                       │
│  홍길동 | 바이올린               │
│  바흐 파르티타 2번               │
│                           [→]  │
└─────────────────────────────────┘

- Left accent: 4px Primary bar
- Status badge (optional)
```

#### 학생 카드

```
┌─────────────────────────────────┐
│  [👤]  홍길동           🟢      │
│        바이올린 | 매주 월 14시   │
│        연습 5/7 | 다음 12/23    │
└─────────────────────────────────┘

- Avatar: 48px circle
- Status dot: 12px
```

#### 연습 카드

```
┌─────────────────────────────────┐
│  ☐ 스케일 연습                  │
│     G장조 3옥타브 | 15분         │
│     [🎤 녹음]                   │
└─────────────────────────────────┘

- Checkbox: 24px
- 완료 시 strikethrough + ☑
```

### 5.4 리스트 아이템 (List Items)

#### Simple List Item

```
┌─────────────────────────────────┐
│  [아이콘]  텍스트          [→]  │
└─────────────────────────────────┘

- Height: 56px
- Divider: 1px #E5E0DB (optional)
```

#### Two-line List Item

```
┌─────────────────────────────────┐
│  [아이콘]  제목                  │
│           부제목           [→]  │
└─────────────────────────────────┘

- Height: 72px
```

### 5.5 탭 바 (Tab Bar)

```
┌─────────────────────────────────┐
│  [🏠]   [📅]   [👥]   [👤]    │
│   홈    캘린더  학생   프로필     │
└─────────────────────────────────┘

- Height: 56px + Safe Area Bottom
- Background: Surface
- Border Top: 1px #E5E0DB
- Icon: 24px
- Label: Caption (11px)
- Active: Primary color
- Inactive: Text Secondary
```

### 5.6 헤더 (Header/App Bar)

```
┌─────────────────────────────────┐
│  ←     페이지 제목        [액션] │
└─────────────────────────────────┘

- Height: 56px
- Background: Transparent or Surface
- Back button: 40x40px
- Title: Heading Medium (20px SemiBold)
- Action: Icon Button 40x40px
```

### 5.7 배지 (Badges)

#### Status Badge

```
  ● 완료    ● 진행중    ● 예정

- Height: 24px
- Border Radius: 12px
- Padding: 4px 12px
- Text: Caption (11px)
```

| 상태 | Background | Text |
|------|------------|------|
| 완료 | `#E8F5E9` | `#2E8B57` |
| 진행중 | `#EDE7F6` | `#6B5B95` |
| 예정 | `#FFF3E0` | `#F4A460` |
| 휴강 | `#F5F5F5` | `#9E9E9E` |

#### Count Badge

```
  🔔 [3]

- Size: 18px (min)
- Border Radius: 9px
- Background: Error (#DC143C)
- Text: 11px White
```

### 5.8 진행률 바 (Progress Bar)

```
  ████████████░░░░ 75%

- Height: 8px
- Border Radius: 4px
- Background: #E5E0DB
- Fill: Primary (#6B5B95) or Status color
```

### 5.9 체크박스 (Checkbox)

```
  ☐ 미완료          ☑ 완료

- Size: 24px
- Border Radius: 4px
- Unchecked: Border 2px #E5E0DB
- Checked: Background Primary, Check icon White
```

### 5.10 토글 (Toggle/Switch)

```
  OFF: ○────      ON: ────●

- Size: 48x28px
- Track: 48x28px, Border Radius 14px
- Thumb: 24px circle
- OFF: Background #E5E0DB, Thumb White
- ON: Background Primary, Thumb White
```

---

## 6. 상태 & 피드백

### 6.1 로딩 상태

#### Spinner

```
    ◠
   ◜ ◝

- Size: 24px (default), 48px (large)
- Color: Primary
- Animation: Rotate 360deg, 1s linear infinite
```

#### Skeleton

```
┌─────────────────────────────────┐
│  [░░░]  ░░░░░░░░░               │
│         ░░░░░░░░░░░░░           │
└─────────────────────────────────┘

- Background: #F5F0EB (Light), #303050 (Dark)
- Animation: Shimmer effect
```

### 6.2 빈 상태 (Empty State)

```
         ┌─────┐
         │ 📭  │
         └─────┘

      아직 레슨이 없어요

   새 레슨을 추가해보세요

   [+ 레슨 추가하기]
```

- Icon: 64px
- Title: Heading Medium
- Description: Body Medium, Text Secondary
- Action: Secondary Button

### 6.3 에러 상태

```
         ┌─────┐
         │ ⚠️  │
         └─────┘

     문제가 발생했어요

   잠시 후 다시 시도해주세요

     [다시 시도]
```

### 6.4 토스트 메시지

```
┌─────────────────────────────────┐
│  ✓  저장되었습니다               │
└─────────────────────────────────┘

- Position: Bottom, 16px margin
- Height: 48px
- Border Radius: 8px
- Background: #1A1A1A (Light), #FFFFFF (Dark)
- Text: White (Light), #1A1A1A (Dark)
- Duration: 3 seconds
- Animation: Slide up + Fade
```

| 타입 | Icon | Color |
|------|------|-------|
| Success | ✓ | `#2E8B57` |
| Error | ✕ | `#DC143C` |
| Warning | ⚠ | `#F4A460` |
| Info | ℹ | `#4A90D9` |

### 6.5 다이얼로그

```
┌─────────────────────────────────┐
│                            [✕] │
│                                 │
│         레슨을 삭제할까요?         │
│                                 │
│   이 작업은 되돌릴 수 없습니다.    │
│                                 │
│   [취소]           [삭제]       │
│                                 │
└─────────────────────────────────┘

- Width: Screen - 48px (max 320px)
- Border Radius: 16px
- Background: Surface
- Padding: 24px
- Title: Heading Medium
- Description: Body Medium, Text Secondary
- Actions: Right-aligned
```

---

## 7. 모션 & 애니메이션

### 7.1 기본 원칙

| 원칙 | 설명 |
|------|------|
| **자연스러움** | 실제 물리 법칙을 따르는 느낌 |
| **신속함** | 사용자를 기다리게 하지 않음 |
| **의미있음** | 애니메이션은 목적이 있어야 함 |

### 7.2 Duration

| 토큰 | 시간 | 용도 |
|------|------|------|
| `duration-instant` | 100ms | 호버, 버튼 프레스 |
| `duration-fast` | 200ms | 작은 요소 전환 |
| `duration-normal` | 300ms | 페이지 전환, 모달 |
| `duration-slow` | 400ms | 복잡한 애니메이션 |

### 7.3 Easing

| 토큰 | Curve | 용도 |
|------|-------|------|
| `ease-out` | cubic-bezier(0, 0, 0.2, 1) | 요소 등장 |
| `ease-in` | cubic-bezier(0.4, 0, 1, 1) | 요소 퇴장 |
| `ease-in-out` | cubic-bezier(0.4, 0, 0.2, 1) | 상태 변화 |

### 7.4 전환 애니메이션

#### 페이지 전환

```
Forward: 새 페이지가 오른쪽에서 슬라이드 + 페이드 인
Back: 현재 페이지가 오른쪽으로 슬라이드 + 페이드 아웃
Duration: 300ms
Curve: ease-in-out
```

#### 모달/시트

```
Bottom Sheet: 아래에서 슬라이드 업
Dialog: 중앙에서 스케일 업 (0.95 → 1.0) + 페이드 인
Duration: 300ms
Curve: ease-out
```

#### 탭 전환

```
Content: 페이드 (현재 → 0% → 새로운 100%)
Duration: 200ms
Curve: ease-in-out
```

### 7.5 마이크로 인터랙션

#### 버튼 프레스

```
Press: scale(0.98)
Release: scale(1.0)
Duration: 100ms
Curve: ease-out
```

#### 체크박스

```
Check: 체크 아이콘 스케일 업 (0 → 1) + 배경 색상
Duration: 200ms
Curve: ease-out (bounce 효과)
```

#### Pull to Refresh

```
Pull: 스피너 등장 + 콘텐츠 아래로 이동
Release: 스피너 회전, 콘텐츠 원위치
Duration: 300ms
```

### 7.6 Flutter 코드

```dart
// lib/core/theme/app_motion.dart

class AppMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  // Curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceOut = Curves.bounceOut;

  // Page Transitions
  static PageRouteBuilder slideTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: easeInOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}
```

---

## 부록: Figma 설정 가이드

### A. Design System 페이지 구성

```
💎 Design System
├── 📁 Colors
│   ├── Primary Palette
│   ├── Semantic Colors
│   ├── Neutral (Light)
│   └── Neutral (Dark)
├── 📁 Typography
│   ├── Type Scale
│   └── Text Styles
├── 📁 Icons
│   ├── Navigation
│   ├── Actions
│   └── Instruments (Custom)
├── 📁 Components
│   ├── Buttons
│   ├── Inputs
│   ├── Cards
│   ├── List Items
│   ├── Navigation
│   └── Feedback
└── 📁 Layouts
    ├── Grid
    └── Spacing
```

### B. 컴포넌트 네이밍 규칙

```
[Category]/[Component]/[Variant]=[Value], [State]=[Value]

예시:
Buttons/Primary/Size=Large, State=Default
Buttons/Primary/Size=Large, State=Pressed
Cards/Lesson/Mode=Light
Cards/Lesson/Mode=Dark
Inputs/Text/State=Default
Inputs/Text/State=Focus
Inputs/Text/State=Error
```

### C. Auto Layout 설정

| 컴포넌트 | Direction | Gap | Padding |
|----------|-----------|-----|---------|
| Card | Vertical | 8px | 16px |
| Button | Horizontal | 8px | 16px 24px |
| List Item | Horizontal | 12px | 16px |
| Input | Vertical | 4px | 0 |

---

## 참고 문서

- [템플릿 분석](./template_analysis.md)
- [화면별 상세 명세서](./screen_specs.md)
- [요구사항 정의](../requirement.md)
- [기술 의사결정](../tech_decision.md)
