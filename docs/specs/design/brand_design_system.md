# Lessonaza 브랜드 디자인 시스템

> v1.0 | 2026-03-26

## 1. 브랜드 아이덴티티

### 1.1 브랜드 가치

| 가치 | 설명 | UX 반영 |
|------|------|---------|
| **따뜻함** | 선생님과 학생의 따뜻한 관계 | Warm cream 배경 (#FFFAF5), 부드러운 radius |
| **신뢰** | 레슨 일정·결제의 정확성 | 명확한 상태 색상, 일관된 패턴 |
| **성장** | 음악 실력 향상의 기록 | 스트릭, 완성도 바, 게이미피케이션 |
| **품격** | 음악의 고전적 우아함 | 클래식 퍼플 primary, Pretendard 폰트 |

### 1.2 브랜드 키워드
`클래식` `따뜻함` `전문성` `성장` `심플`

---

## 2. 색상 시스템

### 2.1 Primary Palette

| 이름 | 코드 | 용도 |
|------|------|------|
| **Primary** | `#6B5B95` | 브랜드 컬러, CTA 버튼, 선택 상태, 액센트 |
| **Primary Light** | `#9A8BC4` | 비활성 강조, 아바타 배경, 칩 배경 |
| **Primary Dark** | `#4A3D6E` | 그래디언트 끝점, 강조 텍스트 |

### 2.2 Secondary Palette

| 이름 | 코드 | 용도 |
|------|------|------|
| **Secondary** | `#F4A460` | 악기 목재 느낌, 경고, 진행 중 |
| **Secondary Light** | `#F7C490` | 배너 배경, 하이라이트 |

### 2.3 Semantic Colors

| 이름 | 코드 | 용도 | 금지 사항 |
|------|------|------|----------|
| **Success** | `#2E8B57` | 완료, 성공, 좋음 | 브랜드 장식용 금지 |
| **Warning** | `#F4A460` | 주의, 임박, 진행 중 | 에러 대용 금지 |
| **Error** | `#DC143C` | 에러, 삭제, 경고 | 일반 강조용 금지 |
| **Info** | `#4A90D9` | 정보, 알림, 링크 | primary 대체 금지 |

### 2.4 Surface Colors

| 이름 | 코드 | 용도 |
|------|------|------|
| **Background** | `#FFFAF5` | 앱 전체 배경 (warm cream) |
| **Surface** | `#FFFFFF` | 카드, 바텀시트, 다이얼로그 |
| **Surface Secondary** | `#F5F0EB` | 섹션 배경, 비활성 영역 |
| **Border** | `#E5E0DB` | 카드 테두리, 구분선 |

### 2.5 Text Colors

| 이름 | 코드 | 용도 |
|------|------|------|
| **Text Primary** | `#1A1A1A` | 제목, 중요 텍스트 |
| **Text Secondary** | `#666666` | 부제목, 설명 |
| **Text Tertiary** | `#999999` | 힌트, 날짜, 메타 정보 |
| **Text Disabled** | `#CCCCCC` | 비활성 텍스트 |

---

## 3. 타이포그래피

### 3.1 폰트
- **기본 폰트**: Pretendard
- **대안**: SF Pro (iOS), Roboto (Android)

### 3.2 스케일

| 스타일 | 크기 | 무게 | 용도 |
|--------|------|------|------|
| Display Large | 32px / w700 | Bold | 온보딩 타이틀 |
| Display Medium | 28px / w700 | Bold | 섹션 대제목 |
| Heading Large | 24px / w600 | Semi | 페이지 제목 |
| Heading Medium | 20px / w600 | Semi | 카드 제목 |
| Heading Small | 18px / w600 | Semi | 섹션 소제목 |
| Body Large | 16px / w400 | Regular | 본문 (기본) |
| Body Medium | 14px / w400 | Regular | 설명, 리스트 |
| Body Small | 12px / w400 | Regular | 보조 텍스트 |
| Caption | 11px / w400 | Regular | 메타, 타임스탬프 |

---

## 4. 스페이싱

- **그리드**: 4pt 기반 (4, 8, 12, 16, 20, 24, 32, 40, 48)
- **화면 패딩**: 16px
- **카드 패딩**: 16px
- **섹션 간격**: 24px
- **Border Radius**: Small 4 / Medium 8 / Large 12 / XLarge 16

---

## 5. UX 점검 체크리스트 (자동 검증용)

### 5.1 색상 규칙 (CRITICAL)

- [ ] `Color(0x...)` 하드코딩 없음 → 반드시 `AppColors.xxx` 사용
- [ ] Primary 색상은 `#6B5B95` 계열만 사용
- [ ] 배경색은 `#FFFAF5` (backgroundLight) 사용
- [ ] Semantic 색상 오용 없음 (success를 장식용으로 사용 금지)
- [ ] 텍스트 색상 4단계 중 적절한 단계 사용

### 5.2 타이포그래피 규칙

- [ ] `TextStyle(fontSize: ...)` 직접 정의 없음 → `AppTypography.xxx` 사용
- [ ] 제목에 Body 스타일 사용 금지
- [ ] 본문에 Heading 스타일 사용 금지

### 5.3 스페이싱 규칙

- [ ] 매직 넘버 없음 → `AppSpacing.xxx` 사용
- [ ] 화면 패딩 `AppSpacing.screenPadding` (16px) 통일
- [ ] 카드 패딩 `AppSpacing.cardPadding` (16px) 통일

### 5.4 컴포넌트 규칙

- [ ] 공통 위젯 (`core/widgets/`) 우선 사용
- [ ] 중복 위젯 생성 금지 (기존 확인 후 재사용)
- [ ] 이름 표시: `NameUtils.givenName()` 사용
- [ ] 날짜 포맷: `formatDateYMD()` 등 유틸 사용

### 5.5 레이아웃 규칙

- [ ] 500줄 초과 위젯 → 파일 분리
- [ ] 4단계 이상 중첩 금지
- [ ] Row 안 Expanded/Flexible 사용 확인
- [ ] BoxDecoration border → 별도 Container 분리 (0.5px overflow 방지)

---

## 6. 상태별 색상 매핑

### 6.1 스케줄

| 상태 | 배경 | 액센트 |
|------|------|--------|
| 과거 레슨 | `scheduleMutedBackground` | `scheduleMutedAccent` |
| 오늘 레슨 | `primary` | `primary` |
| 미래 레슨 | `primaryLight` (10% opacity) | `primary` |
| 이동 시간 | `scheduleTravelBackground` | `scheduleTravelAccent` |

### 6.2 연습 상태

| 상태 | 색상 |
|------|------|
| 좋음 (80%+) | `practiceGood` (#2E8B57) |
| 보통 (50-79%) | `practiceNormal` (#F4A460) |
| 부족 (<50%) | `practicePoor` (#DC143C) |
| 일시정지 | `practicePaused` (#9E9E9E) |

### 6.3 수강권

| 상태 | 색상 |
|------|------|
| 활성 | `success` |
| 만료 임박 | `warning` |
| 만료 | `error` |
| 일시정지 | `textTertiaryLight` |
