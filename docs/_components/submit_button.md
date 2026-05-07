# 제출 버튼 컴포넌트

> ID: `components/submit_button`
> 버전: 1.0
> 소스: `core/widgets/` (공통 버튼)

<!-- @defines: components/submit_button -->
<!-- @uses: tokens/colors, tokens/typography, tokens/spacing -->

---

## 1. 개요

폼 제출, 저장, 확인 등 주요 액션을 위한 버튼.
로딩 상태와 비활성 상태를 지원.

> 용어 규칙(UX): `닫기`는 오버레이 종료(시트/다이얼로그 닫기),  
> `취소`는 저장/요청/변경 등 진행 중인 흐름의 액션 취소 시 사용.

---

## 2. 구조

### 2.1 기본 상태

```
┌─────────────────────────────────────────────┐
│                   저장                       │
└─────────────────────────────────────────────┘
```

### 2.2 로딩 상태

```
┌─────────────────────────────────────────────┐
│               [◌ 로딩...]                   │
└─────────────────────────────────────────────┘
```

---

## 3. Props

| 속성 | 타입 | 필수 | 기본값 | 설명 |
|------|------|:----:|--------|------|
| `label` | `String` | ✓ | - | 버튼 텍스트 |
| `onPressed` | `VoidCallback?` | - | null | 탭 콜백 (null이면 비활성) |
| `isLoading` | `bool` | - | false | 로딩 상태 |
| `isEnabled` | `bool` | - | true | 활성화 상태 |
| `variant` | `ButtonVariant` | - | primary | 버튼 스타일 변형 |
| `size` | `ButtonSize` | - | large | 버튼 크기 |
| `icon` | `IconData?` | - | null | 좌측 아이콘 |
| `isFullWidth` | `bool` | - | true | 전체 너비 사용 |

---

## 4. ButtonVariant Enum

| 변형 | 배경 | 텍스트 | 용도 |
|------|------|--------|------|
| `primary` | `color.primary` | 흰색 | 주요 액션 |
| `secondary` | `color.surface` | `color.primary` | 보조 액션 |
| `danger` | `color.error` | 흰색 | 삭제/위험 액션 |
| `ghost` | 투명 | `color.primary` | 텍스트 버튼 |

---

## 5. ButtonSize Enum

| 크기 | 높이 | 폰트 | 패딩 |
|------|------|------|------|
| `small` | `height.button.small` (40px) | `type.button.small` | `space.3` |
| `large` | `height.button` (48px) | `type.button` | `space.4` |

---

## 6. 상태별 스타일

### Primary 버튼

| 상태 | 배경 | 텍스트 |
|------|------|--------|
| 기본 | `color.primary` | 흰색 |
| 눌림 | `color.primary.dark` | 흰색 |
| 비활성 | `color.primary` (50%) | 흰색 (50%) |
| 로딩 | `color.primary` | 스피너 + 텍스트 |

### Secondary 버튼

| 상태 | 배경 | 테두리 | 텍스트 |
|------|------|--------|--------|
| 기본 | `color.surface` | `color.primary` | `color.primary` |
| 눌림 | `color.primary.light` | `color.primary` | `color.primary` |
| 비활성 | `color.surface` | `color.border` | `color.text.disabled` |

---

## 7. 로딩 상태

```dart
// 로딩 중일 때
- 버튼 비활성화 (중복 탭 방지)
- 스피너 + 텍스트 표시
- 스피너: CircularProgressIndicator (작은 크기)
```

| 요소 | 스타일 |
|------|--------|
| 스피너 크기 | 20×20px |
| 스피너 색상 | 텍스트 색상과 동일 |
| 간격 | `space.2` (8px) |

---

## 8. 아이콘 버튼

```
┌─────────────────────────────────────────────┐
│              [+]  추가                       │
└─────────────────────────────────────────────┘
```

| 요소 | 스타일 |
|------|--------|
| 아이콘 크기 | `icon.sm` (20px) |
| 간격 | `space.2` (8px) |

---

## 9. 버튼 그룹

가로로 배치되는 버튼 쌍:

```
┌───────────────────┐  ┌───────────────────┐
│       취소        │  │       저장        │
└───────────────────┘  └───────────────────┘
   Secondary              Primary
```

| 요소 | 스타일 |
|------|--------|
| 간격 | `space.3` (12px) |
| 비율 | 동일 (1:1) |

---

## 10. 접근성

| 속성 | 값 |
|------|-----|
| 최소 터치 영역 | 48×48px |
| 포커스 표시 | `color.primary` 외곽선 (2px) |
| 비활성 시 | 터치 무시, 시각적 희미함 |

---

## 사용처

<!-- @used-by: 모든 폼 스펙 -->

- 모든 추가/편집 폼: 저장/취소 버튼
- 삭제 확인 다이얼로그: 삭제/취소 버튼
- 바텀시트 푸터: 확인/취소 버튼

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 컴포넌트 정의 |
