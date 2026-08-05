# Hyen UX 표준 — 디자이너 피드백 기반 전역 UI/UX 개편

> 출처: Figma `Lessonaza-Design-System` — `홈 · 교사 홈_Hyen 수정중` (node 355:1106) 프레임 내 디자이너(Hyen) 주석 8건.
> 사용자 결정 (2026-08-05): 아이콘 네비 전 역할 전환 / paper 전역 토큰 변경 / FAB 44px.
> 악보X노트 컨셉은 유지한다 (디자이너 명시: "악보X노트 컨셉으로 진행하겠습니다").

## 1. 표준 원칙 (디자이너 주석 → 일반화)

| # | 원칙 | 디자이너 주석 (원문) | 적용 |
|---|------|---------------------|------|
| H1 | 배경 밝게 | "배경은 밝게 깔았어요. 어두우니까 텍스트가 잘 보이지 않았는데, 종이질감을 내고 싶다면 패턴을 은은하게" | `AppColors.paper` `#F2ECDD` → `#FFFDF8` (전역). 하단 네비 배경 `#FFFAEE` 토큰 신설 |
| H2 | 로고/장식 은은하게 | "로고는 배경에서 은은하게. 너무 텍스트가 잘 보이면 중요한 글자는 안 보이게 되거든요" | 워드마크 `#867F6F` @ opacity 0.20 (Montserrat 15) |
| H3 | 중복 텍스트 제거 | "중복되는 글자는 잠시 빼뒀어요" | 마스트헤드 날짜 1회만: `7월 27일` / `오늘의 레슨`(Playfair 38 masthead 유지) / `네 편의 수업`(Playfair Italic 13) |
| H4 | 일시적 알림 최상단 | "학생 연결 요청 같은 경우는 일시적으로 보였다가 수락하면 사라지는 거니까 상단으로 가죠" | 행동 필요·일시성 배너를 콘텐츠 최상단 배치. 스타일: `paperAccentSoft` bg + `paperMargin` border |
| H5 | 시간 민감 정보 강조 | "다음 레슨 알림이 더 눈에 잘 보였으면 했어요" | 다음 레슨 배너: `amberLight` bg + `paperTrial` border + IBM Plex Mono 15 |
| H6 | 텍스트 액션 밑줄 | "버튼으로 사용되는 걸까 생각해서 밑줄을 넣었답니다" | 탭 가능한 텍스트 액션(일괄 피드백, 전체 보기 등)에 underline |
| H7 | 완료 항목 뮤트 | "완료한건 게이지 바처럼 색상이 채워지도록… 악보X노트 컨셉으로 진행" | 완료 레슨 행: 이름/시간/상태/chevron `inkQuaternary`(25%), 좌측 상태 바는 `paperOk` 유지 |
| H8 | 터치 타깃 | "버튼 터치 이슈로 최소 사이즈 44px 맞춰드렸습니다" | FAB 44px (사용자 결정) |
| H9 | 하단 네비 아이콘 | (시안 드로잉) 로마숫자 탭 → 아이콘 24px + 라벨 10px | 전 역할(교사/학생/학부모). active=`paperAccent`, inactive=`inkTertiary`. Material Icons 사용 (프로젝트 규칙: 네비=일반 영역) |

## 2. 유지 항목 (변경 금지)

- 마스트헤드 Playfair Display Bold 38 (`NotebookTypography.masthead`)
- 레슨 리스트 로마숫자 회차 (I. II. III. — Playfair SemiBold Italic 15)
- 시간 표기 IBM Plex Mono
- ink 팔레트 (`ink`/`inkTertiary`/`inkQuaternary`), `paperAccent` #9B1B12
- D-day/잔여 칩 스타일 (border + mono)

## 3. 색 토큰 변경

| 토큰 | 이전 | 이후 |
|------|------|------|
| `AppColors.paper` | `#F2ECDD` | `#FFFDF8` |
| `AppColors.paperNav` (신설) | — | `#FFFAEE` (하단 네비 배경) |
| 나머지 paper 계열 soft 톤 | — | 새 배경 대비 시각 검증 후 필요 시만 조정 (surgical) |

## 4. 하단 네비 아이콘 매핑 (Material)

| 탭 | inactive | active |
|----|----------|--------|
| 홈 | `Icons.home_outlined` | `Icons.home` |
| 스케줄 | `Icons.calendar_month_outlined` | `Icons.calendar_month` |
| 수강관리 | `Icons.album_outlined` (레코드판 — 음악 메타포) | `Icons.album` |
| 프로필 | `Icons.person_outline` | `Icons.person` |

학생/학부모 홈 탭도 동일 규칙 (기존 라벨 유지, 로마숫자만 아이콘으로 대체).

## 5. 검증 기준

- `flutter analyze` 0 errors
- `flutter test` 신규 실패 0 (main baseline: 휴가 날짜의존 BE 2 + per_student_disposition FE 2 기존 실패 제외)
- `flutter test test/architecture` 통과
- web 375px 스크린샷 QA: 교사 홈 / 학생 홈 / 스케줄 최소 3화면
- 완료 후 Figma 미러 동기화 (변수 + 프레임)
