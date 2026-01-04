# 디자인 토큰 라이브러리

> 버전: 1.0
> 최종 업데이트: 2026-01-04

이 폴더는 앱 전체에서 사용되는 디자인 토큰(Single Source of Truth)을 정의합니다.

---

## 토큰 목록

| 토큰 | ID | 설명 | 소스 코드 |
|------|-----|------|-----------|
| [색상](colors.md) | `tokens/colors` | 브랜드, 시맨틱, 중립 색상 | `app_colors.dart` |
| [타이포그래피](typography.md) | `tokens/typography` | 폰트, 크기, 굵기 | `app_typography.dart` |
| [스페이싱](spacing.md) | `tokens/spacing` | 간격, 라디우스, 높이 | `app_spacing.dart` |
| [아이콘](icons.md) | `tokens/icons` | 시스템/도메인 아이콘 | Material Icons |
| [상태](status.md) | `tokens/status` | 연습, 결제, 폼 상태 | 앱 전반 |

---

## 사용 방법

### 스펙에서 토큰 참조

```markdown
<!-- @uses: tokens/colors, tokens/typography -->

배경색: `color.surface`
폰트: `type.body.medium`
```

### 토큰 정의

```markdown
<!-- @defines: tokens/[token_name] -->
```

---

## 토큰 ID 형식

```
{카테고리}.{그룹}.{변형}

예시:
- color.primary
- color.primary.light
- type.heading.medium
- space.4
- icon.nav.home
- status.practice.complete
```

---

## 코드 동기화

토큰 문서는 다음 코드 파일과 동기화되어야 합니다:

| 토큰 | 코드 파일 |
|------|----------|
| colors | `lib/core/theme/app_colors.dart` |
| typography | `lib/core/theme/app_typography.dart` |
| spacing | `lib/core/theme/app_spacing.dart` |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 토큰 라이브러리 생성 |
