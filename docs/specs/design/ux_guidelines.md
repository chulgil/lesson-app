# UX Guidelines

> 최종 수정: 2026-03-07
> 목적: Claude가 UI 구현 시 참고하는 디자인 시스템 + UX 원칙

---

## 1. 디자인 토큰 (Design Tokens)

> **절대 규칙**: 모든 색상/타이포/간격은 공통 클래스만 사용. 하드코딩 금지.

### 1.1 색상 시스템 (AppColors)

> 파일: `lib/core/theme/app_colors.dart`

**브랜드 색상** — 앱 아이덴티티

| 토큰 | HEX | 용도 |
|------|-----|------|
| `primary` | #6B5B95 | CTA, 선택 상태, 링크, 아이콘 |
| `primaryLight` | #9A8BC4 | 아바타 배경, 연한 강조 |
| `primaryDark` | #4A3D6E | 그라디언트 끝, 진한 강조 |
| `secondary` | #F4A460 | 보조 강조, 추천(⭐), 그룹레슨 |
| `secondaryLight` | #F7C490 | 보조 연한 배경 |

**시맨틱 색상** — 의미 기반 (상태 표현용)

| 토큰 | HEX | 의미 | 사용 예 |
|------|-----|------|---------|
| `success` | #2E8B57 | 완료/정상 | 체크 아이콘, 완료 상태 |
| `successLight` | #E8F5E9 | 완료 배경 | 성공 토스트 배경 |
| `warning` | #F4A460 | 경고/주의 | 잔여 횟수 적음, 임박 |
| `warningLight` | #FFF3E0 | 경고 배경 | 경고 카드 배경 |
| `error` | #DC143C | 오류/삭제/긴급 | 미수금, 삭제 버튼, 결석 |
| `errorLight` | #FFEBEE | 오류 배경 | 에러 카드 배경 |
| `info` | #4A90D9 | 정보/안내 | 내 예약, 안내 텍스트 |
| `infoLight` | #E3F2FD | 정보 배경 | 정보 카드 배경 |

**서피스 색상** — 라이트 모드

| 토큰 | HEX | 용도 |
|------|-----|------|
| `backgroundLight` | #FFFAF5 | 전체 배경 (웜톤) |
| `surfaceLight` | #FFFFFF | 카드/시트 배경 |
| `surfaceSecondaryLight` | #F5F0EB | 비활성 배경, 칩 배경 |
| `borderLight` | #E5E0DB | 테두리, 구분선 |

**텍스트 색상** — 라이트 모드

| 토큰 | HEX | 용도 |
|------|-----|------|
| `textPrimaryLight` | #1A1A1A | 제목, 본문 |
| `textSecondaryLight` | #666666 | 부제목, 아이콘 |
| `textTertiaryLight` | #999999 | 힌트, 비활성 라벨 |
| `textDisabledLight` | #CCCCCC | 비활성 텍스트 |

**허용되는 직접 색상**: `Colors.white`, `Colors.black`, `Colors.transparent`만 허용.
**금지**: `Colors.grey`, `Colors.red`, `Colors.green`, `Color(0xFF...)` 등 직접 사용 금지.

#### 색상 사용 결정 기준

```
Q: 이 색상은 무엇을 의미하나?
├─ 브랜드/앱 아이덴티티 → primary / secondary
├─ 성공/완료 → success
├─ 경고/주의 → warning
├─ 오류/삭제/긴급 → error
├─ 정보/안내 → info
├─ 배경/서피스 → backgroundLight / surfaceLight
├─ 텍스트 → textPrimary/Secondary/TertiaryLight
└─ 테두리/구분선 → borderLight
```

#### 새 색상이 필요한 경우

1. 기존 토큰으로 대체 가능한지 먼저 확인
2. 불가능하면 `AppColors`에 새 상수 추가 후 사용
3. **절대** 위젯 내부에 하드코딩하지 않음

### 1.2 타이포그래피 (AppTypography)

> 파일: `lib/core/theme/app_typography.dart`
> 폰트: Pretendard

| 토큰 | 크기 | 무게 | 용도 |
|------|------|------|------|
| `displayLarge` | 32 | Bold | 히어로 숫자 |
| `displayMedium` | 28 | Bold | 대형 제목 |
| `headingLarge` | 24 | SemiBold | 화면 제목 |
| `headingMedium` | 20 | SemiBold | 섹션 제목 |
| `headingSmall` | 18 | SemiBold | 카드 제목 |
| `bodyLarge` | 16 | Regular | 본문 (기본) |
| `bodyMedium` | 14 | Regular | 부제목, 설명 |
| `bodySmall` | 12 | Regular | 캡션, 메타 |
| `caption` | 11 | Regular | 작은 라벨 |
| `button` | 16 | SemiBold | 버튼 텍스트 |
| `buttonSmall` | 14 | Medium | 작은 버튼 |

**금지**: `fontSize: N` 직접 사용. 반드시 `AppTypography.xxx` 사용.

#### 1.2.1 NotebookTypography — 자필·악보 시그니처 (Notebook × Score)

> 파일: `lib/core/theme/notebook_typography.dart`
> 폰트: Gaegu (자필) / Playfair Display (악보 헤더) / IBM Plex Mono (시간·템포)

| 토큰 | 폰트 | 용도 |
|------|------|------|
| `hand` | Gaegu 16 | **사용자 자필 본문**: 선생님 피드백 입력/표시, 학생 메모 입력/표시, 연습노트 본문, 곡 메모 — TextField input style 도 포함 (§7.129) |
| `handOk` | Gaegu 13 / paperOk | 자필 완료 마크 ("✓ 보잉 좋음") |
| `indicatorLabel` | Pretendard 11 italic | 시스템 자동 인디케이터 ("오늘", "D-N", "미결제") |
| `pieceTitle` | Playfair w700 | 곡 제목, 카드 헤더 |
| `sectionTitle` | Playfair italic | 섹션 헤더 |
| `roman` / `romanActive` | Playfair italic | 로마숫자 인덱스 |

**4계층 결정 트리**: "이 텍스트의 작성 주체는 누구인가?" → 사람=자필(Tier 1·2), 시스템=인쇄체(Tier 3·4).

상세 가이드 + 회피 신호 + Tier 3 안내문 매트릭스 → `docs/specs/design/notebook/README.md` §1.1.1.

### 1.3 간격 (AppSpacing)

> 파일: `lib/core/theme/app_spacing.dart`
> 체계: 4pt 기반

| 토큰 | 값 | 용도 |
|------|-----|------|
| `space1` | 4 | 최소 간격 |
| `space2` | 8 | 요소 내부 |
| `space3` | 12 | 요소 간 |
| `space4` | 16 | 섹션 내부 (= `screenPadding`, `cardPadding`) |
| `space5` | 20 | |
| `space6` | 24 | 섹션 간 (= `sectionSpacing`) |
| `space8` | 32 | 큰 섹션 간 |

| 레이아웃 | 토큰 | 값 |
|----------|------|-----|
| 화면 좌우 패딩 | `screenPadding` | 16 |
| 카드 내부 패딩 | `cardPadding` | 16 |
| 섹션 간 간격 | `sectionSpacing` | 24 |
| 버튼 높이 | `buttonHeight` | 48 |
| 입력 높이 | `inputHeight` | 48 |
| 라운딩 | `radiusSmall/Medium/Large/XLarge` | 4/8/12/16 |

**금지**: `EdgeInsets.all(16)` 대신 `EdgeInsets.all(AppSpacing.space4)` 사용.

---

## 2. 핵심 UX 원칙

### 2.1 3가지 황금 규칙

| 원칙 | 설명 |
|------|------|
| **원클릭** | 핵심 작업은 한 번 탭으로 완료. 불필요한 확인 다이얼로그 제거 |
| **얕은 뎁스** | 모든 기능 2탭 이내 도달 (홈 → 상세 끝) |
| **재사용** | 동일 컴포넌트를 역할별로 다르게 표시 |

### 2.2 타겟 사용자

```
"음악인은 IT에 관심이 적으므로 최대한 심플하면서 효율적으로"
```

- 직관적 UI (설명 없이 이해)
- 충분한 터치 영역
- 3초 내 원하는 화면 도달
- 기술 용어 금지 (동기화 → 새로고침, NULL → 없음)

### 2.3 정보 우선순위

```
1순위: 긴급 (error 색상) — 미수금 D+, 승인 대기
2순위: 오늘 — 당일 레슨/과제
3순위: 트렌드 — 스트릭, 주간 연습, 월간 레슨
4순위: 도구 — 메트로놈, 튜너, 녹음
```

### 2.4 긴급도 색상 규칙

| 긴급도 | 색상 토큰 | 표시 |
|--------|----------|------|
| 긴급 (기한 초과) | `error` | D+3 (빨강) |
| 경고 (7일 이내) | `warning` | D-5 (주황) |
| 주의 (임박) | `secondary` | 2회 남음 |
| 정상 | `textSecondaryLight` | 기본 표시 |

### 2.5 긴급 알림 Top 1 정책 (2026-04-16)

**원칙**: 홈 화면 긴급 알림은 최상위 1건만 표시. 나머지는 Expandable.

| 알림 수 | 표시 방식 |
|:---:|------|
| 0건 | 섹션 숨김 |
| 1건 | 단일 카드 |
| 2+건 | Top 1 + "외 N건 ▼" |

**근거**: 토스 홈 패턴 — 사용자 인지 부하 감소. 5가지 알림 동시 표시는 과부하.

**Top 1 결정 우선순위**: 미수금 > 만료 > 갱신 예정 > 확인 필요 > 예약 대기

### 2.6 Progressive Disclosure (점진적 공개)

**원칙**: 초기에는 요약 N개만 노출. "전체보기"로 확장.

| 섹션 | 기본 노출 | 확장 |
|------|:---:|------|
| 오늘 레슨 | 5건 | "전체보기 (N건 더)" |
| 레슨 요청 | 3건 | "전체보기" |
| 스케줄 변경 | 3건 | "전체보기" |
| 과제 미완료 | 3명 | "전체보기" |

**근거**: 네이버 예약 "다가오는 예약" 패턴. 하루 10+ 레슨 선생님의 홈 압박 방지.

### 2.7 스파크라인 가이드라인

**용도**: 7일 연습 추이를 미니 막대 그래프로 시각화 (수강관리 화면)

| 규칙 | 값 |
|------|-----|
| 기본 기간 | 최근 7일 |
| 막대 수 | 7개 고정 |
| 색상 | 평균 수준별 🟢🟡🔴 (2.4 긴급도 색상 규칙 참조) |
| 클릭 | 해당 학생 연습 상세로 이동 |

**구현**: `PracticeSparkline` 위젯 — 높이 16px, 너비 60-80px

---

## 3. 공통 컴포넌트 패턴

### 3.1 공통 위젯 (`core/widgets/`)

> **원칙**: 새 위젯 작성 전 반드시 기존 위젯 확인. 있으면 재사용.

| 위젯 | 용도 |
|------|------|
| `WeekCalendarWidget` | 주간 캘린더 (연습/레슨/예약) |
| `StatCard` | 통계 카드 |
| `QuickToolButton` | 빠른 도구 버튼 |
| `PracticeCenterButton` | 연습 센터 버튼 |
| `EmptyStateWidget` | 빈 상태 UI |
| `selectors/LessonCountSelector` | 레슨 횟수 선택 |
| `selectors/LessonDurationSelector` | 수업 시간 선택 |
| `selectors/ValidityPeriodSelector` | 유효기간 선택 |
| `selectors/DiscountPercentSelector` | 할인율 선택 |
| `selectors/BonusCountSelector` | 보너스 횟수 선택 |

### 3.2 카드 레이아웃

**이벤트 카드** (시간 기반):
```
┌─────────────────────────────────────────────┐
│ ┃  14:00     김지수 · 피아노       예정   > │
│ ┃  50분      모차르트 소나타...            │
└─────────────────────────────────────────────┘
  ↑   ↑(48px)     ↑(Flexible)    ↑(72px)  ↑
  바   시간        정보            상태   화살표
```

**엔티티 카드** (사람/객체):
```
┌─────────────────────────────────────────────┐
│ (아바타) 김지수 [학원]                       │
│          피아노 · 8회 남음                   │
│          매주 토 14:00       ●●●●○○       > │
└─────────────────────────────────────────────┘
```

**카드 스타일 코드**:
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceLight,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  // ...
)
```

### 3.3 버튼 패턴

| 용도 | 위젯 | 스타일 |
|------|------|--------|
| 주요 액션 (CTA) | `FilledButton` | `backgroundColor: AppColors.primary` |
| 보조 액션 | `OutlinedButton` | `side: BorderSide(color: AppColors.primary)` |
| 위험 액션 | `FilledButton` | `backgroundColor: AppColors.error` |
| 텍스트 액션 | `TextButton` | `foregroundColor: AppColors.primary` |

### 3.4 상태 뱃지 색상

| 상태 | 배경 | 텍스트 |
|------|------|--------|
| 활성/수강중 | `primary.withAlpha(25)` | `primary` |
| 완료 | `successLight` | `success` |
| 경고/만료임박 | `warningLight` | `warning` |
| 오류/미수금 | `errorLight` | `error` |
| 비활성 | `surfaceSecondaryLight` | `textTertiaryLight` |

### 3.5 선택자 칩 스타일

| 상태 | 배경 | 테두리 | 텍스트 |
|------|------|--------|--------|
| 비선택 | `surfaceLight` | `borderLight` | `textPrimaryLight` |
| 선택됨 | `primary(alpha:0.15)` | `primary` | `primary` (bold) |

### 3.6 피드백 패턴

| 액션 | 피드백 |
|------|--------|
| 저장 성공 | 하단 토스트 "저장되었습니다" (2초) |
| 삭제 성공 | 하단 토스트 + 되돌리기 |
| 에러 | 빨간 토스트 + 재시도 버튼 |
| 로딩 | `CircularProgressIndicator` |
| 빈 상태 | `EmptyStateWidget` (아이콘 + 안내 + CTA) |

---

## 4. 네비게이션

### 4.1 메인 탭

| 역할 | 탭 1 | 탭 2 | 탭 3 | 탭 4 |
|------|------|------|------|------|
| 선생님 | 홈 | 학생 | 일정 | 설정 |
| 학생 | 홈 | 연습 | 레슨 | 설정 |
| 학부모 | 홈 | 자녀 | 결제 | 설정 |

### 4.2 메뉴 배치

| 빈도 | 배치 |
|------|------|
| 매일 | 메인 탭, 홈 대시보드 |
| 주 1회 | 상세 화면 내부 |
| 월 1회 | 별도 탭 또는 설정 |
| 가끔 | 설정 메뉴 |

---

## 5. 역할별 화면 재사용

| 구분 | 선생님 | 학부모 | 학생 |
|------|--------|--------|------|
| 데이터 권한 | 읽기/쓰기 | 읽기 전용 | 본인만 읽기/쓰기 |
| 과제 | 생성/수정 | 열람 | 완료 체크 |
| 결제 | 청구서 발행 | 결제 | 열람 |

**읽기 전용 표시**: 눈 아이콘 + 체크박스 비활성화 (회색)

---

## 6. 도메인별 UI 규칙

### 6.1 수강권 카드

```
┌─────────────────────────────────────┐
│ 바이올린수강권                [활성] │
│ 5/8회 남음                          │
│ ██████░░░░                          │  ← 프로그레스바
│ 만료: 3/31   변경: 1/2회            │
└─────────────────────────────────────┘
```

**잔여 경고**: ≤25% `warning` | ≤2회 `warning` | =1회 `error`
**만료 경고**: ≤7일 `warning` | ≤3일 `error`

### 6.2 레슨 유형 구분

| 유형 | 아이콘 | 색상 |
|------|--------|------|
| 개인 레슨 | Icons.music_note | `primary` |
| 그룹 레슨 | Icons.groups | `secondary` |

### 6.3 예약 슬롯 색상

| 상태 | 색상 토큰 |
|------|----------|
| 예약 가능 | `success` |
| 내 예약 | `info` |
| 거의 만석 | `warning` |
| 만석 | `secondary` |
| 예약 불가 | `textTertiaryLight` |

### 6.4 레슨 상태 색상

| 상태 | 색상 토큰 |
|------|----------|
| 예정 | `primary` |
| 완료 | `success` |
| 취소 | `textTertiaryLight` |
| 결석 | `error` |

---

## 7. Claude 체크리스트

### UI 구현 전

```
- [ ] 기존에 유사한 화면/패턴이 있는가? → 있으면 동일 패턴 사용
- [ ] 공통 위젯(core/widgets/)으로 해결 가능한가?
- [ ] 다르게 구현하려면 사용자 동의 받았는가?
```

### UI 구현 중

```
- [ ] 색상: AppColors만 사용 (하드코딩 금지)
- [ ] 타이포: AppTypography만 사용 (fontSize 직접 금지)
- [ ] 간격: AppSpacing만 사용 (EdgeInsets 숫자 직접 금지)
- [ ] 빈 상태: EmptyStateWidget 사용
- [ ] 로딩: CircularProgressIndicator 사용
- [ ] 피드백: 토스트로 성공/실패 알림
```

### UI 구현 후

```
- [ ] flutter analyze 경고 없음
- [ ] 다른 화면과 레이아웃 일관적인가?
- [ ] 2탭 이내 도달 가능한가?
```

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-12-28 | 초안 작성 |
| 2026-01-27 | 수강권 UI, 슬롯 색상, 인터랙션 패턴 추가 |
| 2026-02-02 | 리스트 카드 디자인 패턴 추가 |
| 2026-03-07 | **v3 전면 개편** — 디자인 토큰 중심 재구성, AppColors/Typography/Spacing 통합 가이드, 불필요한 중복 제거, Claude 체크리스트 간소화 |
| 2026-04-16 | 긴급 알림 Top 1 정책, Progressive Disclosure 원칙, 스파크라인 가이드라인 추가 (§2.5~2.7) |
