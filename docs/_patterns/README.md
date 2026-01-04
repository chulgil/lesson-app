# 공통 패턴 라이브러리

> 버전: 1.0
> 최종 업데이트: 2026-01-04

이 폴더는 앱 전체에서 반복적으로 사용되는 UI/UX 패턴을 정의합니다.

---

## 패턴 목록

### 데이터 관리

| 패턴 | ID | 설명 |
|------|-----|------|
| [CRUD 폼](crud_form.md) | `patterns/crud_form` | 생성/조회/수정/삭제 폼 |
| [리스트-상세](list_detail.md) | `patterns/list_detail` | 마스터-디테일 네비게이션 |

### 제약/규칙

| 패턴 | ID | 설명 |
|------|-----|------|
| [날짜 제약](date_constraint.md) | `patterns/date_constraint` | 날짜 기반 활성/비활성 |

---

## 사용 방법

### 스펙에서 패턴 참조

```markdown
<!-- @uses: patterns/crud_form, patterns/list_detail -->
```

### 패턴 정의

```markdown
<!-- @defines: patterns/[pattern_name] -->
<!-- @uses: components/form_field, components/submit_button -->
```

---

## 패턴 vs 컴포넌트

| 구분 | 패턴 | 컴포넌트 |
|------|------|----------|
| 범위 | 여러 화면/기능에 걸친 동작 | 단일 UI 요소 |
| 내용 | 흐름, 규칙, 상호작용 | 구조, 스타일, Props |
| 예시 | CRUD 폼 패턴, 리스트-상세 패턴 | 버튼, 입력 필드, 카드 |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0 | 2026-01-04 | 초기 패턴 라이브러리 생성 |
