# 타이포그래피 토큰

> ID: `tokens/typography`
> 버전: 1.0
> 소스: `lib/core/theme/app_typography.dart`

<!-- @defines: tokens/typography -->

---

## 1. 폰트 패밀리

| 용도 | 폰트 | 비고 |
|------|------|------|
| **기본** | Pretendard | 한글/영문 모두 지원 (TODO: 추가 예정) |
| **음악 기호** | Noto Music | 음표, 음자리표 등 |
| **숫자 강조** | SF Pro Display | 통계, 시간 표시 |

---

## 2. 폰트 스케일

### Display (큰 제목)

| 토큰 ID | 크기 | 줄높이 | 굵기 | 용도 |
|---------|------|--------|------|------|
| `type.display.large` | 32px | 1.25 | Bold (700) | 스플래시, 온보딩 제목 |
| `type.display.medium` | 28px | 1.29 | Bold (700) | 페이지 대제목 |

### Heading (섹션 제목)

| 토큰 ID | 크기 | 줄높이 | 굵기 | 용도 |
|---------|------|--------|------|------|
| `type.heading.large` | 24px | 1.33 | SemiBold (600) | 섹션 제목 |
| `type.heading.medium` | 20px | 1.4 | SemiBold (600) | 카드 제목 |
| `type.heading.small` | 18px | 1.33 | SemiBold (600) | 서브 제목 |

### Body (본문)

| 토큰 ID | 크기 | 줄높이 | 굵기 | 용도 |
|---------|------|--------|------|------|
| `type.body.large` | 16px | 1.5 | Regular (400) | 본문 텍스트 |
| `type.body.medium` | 14px | 1.43 | Regular (400) | 일반 설명 |
| `type.body.small` | 12px | 1.33 | Regular (400) | 보조 정보 |

### 기타

| 토큰 ID | 크기 | 줄높이 | 굵기 | 용도 |
|---------|------|--------|------|------|
| `type.caption` | 11px | 1.27 | Regular (400) | 타임스탬프, 라벨 |
| `type.button` | 16px | 1.5 | SemiBold (600) | 버튼 텍스트 |
| `type.button.small` | 14px | 1.43 | Medium (500) | 작은 버튼 |

---

## 3. 텍스트 스타일 가이드

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

## 사용처

<!-- @used-by: 모든 스펙 문서 -->

모든 UI 스펙 문서에서 폰트 스타일 참조 시 이 토큰 사용

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 토큰 정의 (AppTypography에서 추출) |
