# 색상 토큰

> ID: `tokens/colors`
> 버전: 1.0
> 소스: `lib/core/theme/app_colors.dart`

<!-- @defines: tokens/colors -->
<!-- @claude-note: 색상 변경 시 모든 스펙 문서의 색상 참조 확인 필요 -->

---

## 1. 브랜드 컬러

### Primary (음악/클래식 느낌의 보라색)

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `color.primary` | `#6B5B95` | 주요 액션, 브랜드 아이덴티티 |
| `color.primary.light` | `#9A8BC4` | 호버, 선택된 상태 |
| `color.primary.dark` | `#4A3D6E` | 텍스트 강조, 진한 배경 |

### Secondary (악기 나무 느낌의 샌디 브라운)

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `color.secondary` | `#F4A460` | 보조 액션, 악기 느낌 |
| `color.secondary.light` | `#F7C490` | 배경 강조 |

---

## 2. 시맨틱 컬러

| 토큰 ID | 값 | 배경색 | 용도 |
|---------|-----|--------|------|
| `color.success` | `#2E8B57` | `#E8F5E9` | 완료, 성공 |
| `color.warning` | `#F4A460` | `#FFF3E0` | 주의, 경고 |
| `color.error` | `#DC143C` | `#FFEBEE` | 에러, 삭제 |
| `color.info` | `#4A90D9` | `#E3F2FD` | 정보 |

---

## 3. 연습 상태 컬러

| 토큰 ID | 값 | 이모지 | 설명 |
|---------|-----|--------|------|
| `color.practice.good` | `#2E8B57` | 🟢 | 연습률 70% 이상 |
| `color.practice.normal` | `#F4A460` | 🟡 | 연습률 40-70% |
| `color.practice.poor` | `#DC143C` | 🔴 | 연습률 40% 미만 |
| `color.practice.paused` | `#9E9E9E` | ⚪ | 휴강 상태 |

---

## 4. 특수 컬러

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `color.cat.accent` | `#B8A9C9` | 메트로놈 고양이 발바닥 |

---

## 5. 중립 컬러

### Light Mode

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `color.background` | `#FFFAF5` | 메인 배경 (아이보리) |
| `color.surface` | `#FFFFFF` | 카드, 시트 배경 |
| `color.surface.secondary` | `#F5F0EB` | 구분선, 보조 배경 |
| `color.border` | `#E5E0DB` | 테두리 |
| `color.text.primary` | `#1A1A1A` | 제목, 본문 |
| `color.text.secondary` | `#666666` | 부가 설명 |
| `color.text.tertiary` | `#999999` | 플레이스홀더 |
| `color.text.disabled` | `#CCCCCC` | 비활성 텍스트 |

### Dark Mode

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `color.background.dark` | `#1A1A2E` | 메인 배경 |
| `color.surface.dark` | `#252540` | 카드, 시트 배경 |
| `color.surface.secondary.dark` | `#303050` | 구분선, 보조 배경 |
| `color.border.dark` | `#404060` | 테두리 |
| `color.text.primary.dark` | `#FFFFFF` | 제목, 본문 |
| `color.text.secondary.dark` | `#B0B0B0` | 부가 설명 |

---

## 6. 소셜 로그인

| 토큰 ID | 값 | 용도 |
|---------|-----|------|
| `color.social.google` | `#FFFFFF` | Google 버튼 배경 |
| `color.social.kakao` | `#FEE500` | Kakao 버튼 배경 |
| `color.social.apple` | `#000000` | Apple 버튼 배경 |

---

## 사용처

<!-- @used-by: 모든 스펙 문서 -->

모든 UI 스펙 문서에서 색상 참조 시 이 토큰 사용

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 토큰 정의 (AppColors에서 추출) |
