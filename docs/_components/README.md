# 공통 컴포넌트 라이브러리

> 버전: 1.0
> 최종 업데이트: 2026-01-04

이 폴더는 앱 전체에서 재사용되는 UI 컴포넌트의 스펙을 정의합니다.

---

## 컴포넌트 목록

### 입력/선택

| 컴포넌트 | ID | 설명 |
|----------|-----|------|
| [폼 필드](form_field.md) | `components/form_field` | 텍스트 입력 필드 |
| [마디 선택기](measure_picker.md) | `components/measure_picker` | 마디/줄 번호 선택 |
| [날짜 범위 선택기](date_range_picker.md) | `components/date_range_picker` | 시작일~종료일 선택 |
| [반복 토글](repeat_toggle.md) | `components/repeat_toggle` | 반복 설정 토글+횟수 |

### 버튼/액션

| 컴포넌트 | ID | 설명 |
|----------|-----|------|
| [제출 버튼](submit_button.md) | `components/submit_button` | 로딩 상태 지원 버튼 |
| [스와이프 액션](swipe_action.md) | `components/swipe_action` | 리스트 행의 편집/삭제 액션 |

### 레이아웃/컨테이너

| 컴포넌트 | ID | 설명 |
|----------|-----|------|
| [바텀 시트](bottom_sheet.md) | `components/bottom_sheet` | 하단 모달 시트 |
| [리스트 카드](list_card.md) | `components/list_card` | 리스트 아이템 카드 |
| [빈 상태](empty_state.md) | `components/empty_state` | 데이터 없음 안내 |

### 피드백/오버레이

| 컴포넌트 | ID | 설명 |
|----------|-----|------|
| [확인 다이얼로그](confirm_dialog.md) | `components/confirm_dialog` | 삭제/확인 다이얼로그 |

---

## 사용 방법

### 스펙에서 컴포넌트 참조

```markdown
<!-- @uses: components/form_field, components/submit_button -->
```

### 컴포넌트 정의

```markdown
<!-- @defines: components/[component_name] -->
<!-- @uses: tokens/colors, tokens/typography -->
```

---

## 컴포넌트 작성 가이드

1. **구조**: ASCII 와이어프레임으로 시각적 구조 표현
2. **Props**: 모든 속성을 테이블로 정리 (타입, 필수, 기본값)
3. **상태**: 상태별 스타일 변화 정의
4. **토큰 참조**: 색상, 타이포그래피, 스페이싱은 `_tokens/` 참조
5. **사용처**: `@used-by` 마커로 역참조 표시

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 컴포넌트 라이브러리 생성 |
| 1.1 | 2026-05-31 | 스와이프 액션 공통 컴포넌트 추가 |
