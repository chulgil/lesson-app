# 문서 레지스트리

> 버전: 1.3
> 최종 업데이트: 2026-03-07

이 문서는 모든 스펙 문서와 공통 모듈 간의 의존성을 추적합니다.

---

## 1. 디자인 토큰 (`_tokens/`)

### 정의

| 토큰 ID | 파일 | 설명 |
|---------|------|------|
| `tokens/colors` | [_tokens/colors.md](_tokens/colors.md) | 색상 토큰 |
| `tokens/typography` | [_tokens/typography.md](_tokens/typography.md) | 타이포그래피 토큰 |
| `tokens/spacing` | [_tokens/spacing.md](_tokens/spacing.md) | 스페이싱 토큰 |
| `tokens/icons` | [_tokens/icons.md](_tokens/icons.md) | 아이콘 토큰 |
| `tokens/status` | [_tokens/status.md](_tokens/status.md) | 상태 토큰 |

### 사용처

| 토큰 | 사용 스펙 |
|------|----------|
| `tokens/colors` | 모든 UI 스펙 |
| `tokens/typography` | 모든 UI 스펙 |
| `tokens/spacing` | 모든 UI 스펙 |
| `tokens/icons` | 대부분의 UI 스펙 |
| `tokens/status` | 상태 표시가 있는 스펙 |

---

## 2. 공통 컴포넌트 (`_components/`)

### 정의

| 컴포넌트 ID | 파일 | 설명 |
|-------------|------|------|
| `components/form_field` | [_components/form_field.md](_components/form_field.md) | 폼 입력 필드 |
| `components/measure_picker` | [_components/measure_picker.md](_components/measure_picker.md) | 마디 선택기 |
| `components/date_range_picker` | [_components/date_range_picker.md](_components/date_range_picker.md) | 날짜 범위 선택기 |
| `components/repeat_toggle` | [_components/repeat_toggle.md](_components/repeat_toggle.md) | 반복 토글 |
| `components/submit_button` | [_components/submit_button.md](_components/submit_button.md) | 제출 버튼 |
| `components/bottom_sheet` | [_components/bottom_sheet.md](_components/bottom_sheet.md) | 바텀 시트 |
| `components/list_card` | [_components/list_card.md](_components/list_card.md) | 리스트 카드 |
| `components/confirm_dialog` | [_components/confirm_dialog.md](_components/confirm_dialog.md) | 확인 다이얼로그 |
| `components/empty_state` | [_components/empty_state.md](_components/empty_state.md) | 빈 상태 |

### 사용처

| 컴포넌트 | 사용 스펙 |
|----------|----------|
| `components/form_field` | CRUD 폼이 있는 모든 스펙 |
| `components/measure_picker` | 연습 섹션 관련 스펙 |
| `components/date_range_picker` | 기간 설정이 있는 스펙 |
| `components/repeat_toggle` | 연습 반복 관련 스펙 |
| `components/submit_button` | 모든 폼 스펙 |
| `components/bottom_sheet` | 추가/편집 스펙 |
| `components/list_card` | 리스트가 있는 스펙 |
| `components/confirm_dialog` | 삭제가 있는 스펙 |
| `components/empty_state` | 리스트가 있는 스펙 |

---

## 3. 공통 패턴 (`_patterns/`)

### 정의

| 패턴 ID | 파일 | 설명 |
|---------|------|------|
| `patterns/crud_form` | [_patterns/crud_form.md](_patterns/crud_form.md) | CRUD 폼 패턴 |
| `patterns/list_detail` | [_patterns/list_detail.md](_patterns/list_detail.md) | 리스트-상세 패턴 |
| `patterns/date_constraint` | [_patterns/date_constraint.md](_patterns/date_constraint.md) | 날짜 제약 패턴 |

### 사용처

| 패턴 | 사용 스펙 |
|------|----------|
| `patterns/crud_form` | CRUD 기능이 있는 모든 스펙 |
| `patterns/list_detail` | 리스트 기반 스펙 |
| `patterns/date_constraint` | 날짜 기반 활성/비활성 스펙 |

---

## 4. 스펙 문서

> 전체 문서 인덱스는 [DOCUMENT_INDEX.md](DOCUMENT_INDEX.md) 참조

### 마스터 문서 (도메인별 SSOT)

| 도메인 | 마스터 문서 |
|--------|-----------|
| 디자인 | [design_master.md](specs/design/design_master.md) |
| 레슨 | [lesson_master.md](specs/lesson/lesson_master.md) |
| 수강권 | [subscription_master.md](specs/subscription/subscription_master.md) |
| 스케줄 | [schedule_master.md](specs/schedule/schedule_master.md) |
| 캘린더 | [calendar_master.md](specs/calendar/calendar_master.md) |
| 연습 | [practice_master.md](specs/practice/practice_master.md) |
| 사용자 | [user_master.md](specs/user/user_master.md) |
| 알림 | [notification_master.md](specs/notification/notification_master.md) |
| 온보딩 | [onboarding_master.md](specs/onboarding/onboarding_master.md) |
| 메트로놈 | [metronome_master.md](specs/metronome/metronome_master.md) |
| 팔로우/초대 | [follow_master.md](specs/follow/follow_master.md) |
| 설정 | [settings_master.md](specs/settings/settings_master.md) |
| 학생 홈 | [student_home_master.md](specs/student_home/student_home_master.md) |

### 연습 도메인 (`specs/practice/`)

| 스펙 | 파일 | 사용 토큰/컴포넌트/패턴 |
|------|------|------------------------|
| 레퍼토리/섹션 CRUD | [repertoire_section_crud_spec.md](specs/practice/repertoire_section_crud_spec.md) | `tokens/*`, `components/*`, `patterns/*` |

---

## 5. 의존성 마커 사용법

### 정의 마커

해당 문서가 특정 토큰/컴포넌트/패턴을 **정의**할 때:

```markdown
<!-- @defines: tokens/colors -->
<!-- @defines: components/form_field -->
<!-- @defines: patterns/crud_form -->
```

### 사용 마커

해당 문서가 다른 모듈을 **사용**할 때:

```markdown
<!-- @uses: tokens/colors, tokens/typography -->
<!-- @uses: components/form_field, components/submit_button -->
<!-- @uses: patterns/crud_form -->
```

### 역참조 마커

해당 모듈을 사용하는 다른 문서를 **기록**할 때:

```markdown
<!-- @used-by: specs/practice/repertoire_section_crud_spec -->
```

---

## 6. 코드 패턴 (`_patterns/code/`)

### 정의

| 패턴 ID | 파일 | 설명 |
|---------|------|------|
| `patterns/barrel_file` | - | 여러 파일을 하나로 re-export |
| `patterns/mixin_split` | - | 대형 클래스를 mixin으로 분리 |

### 사용처

| 패턴 | 사용 위치 |
|------|----------|
| `patterns/barrel_file` | `lib/features/lessons/presentation/widgets/lesson_form_widgets.dart` |
| `patterns/barrel_file` | `lib/features/students/presentation/widgets/student_form_widgets.dart` |
| `patterns/mixin_split` | `lib/repositories/impl/` (PracticeRepertoireRepository) |

### 예시: Barrel File 패턴

```dart
/// lib/features/.../widgets/lesson_form_widgets.dart
export 'lesson_form/lesson_student_info.dart';
export 'lesson_form/lesson_student_selector.dart';
// ... 모든 하위 파일 re-export
```

### 예시: Mixin Split 패턴

```dart
/// Base class with shared state
abstract class PracticeRepositoryBase { ... }

/// Mixins for each responsibility
mixin PracticeRepertoireCrudMixin on PracticeRepositoryBase { ... }
mixin PracticeSectionMixin on PracticeRepositoryBase { ... }

/// Final class combining all mixins
class MockPracticeRepertoireRepository extends PracticeRepositoryBase
    with PracticeRepertoireCrudMixin, PracticeSectionMixin, ... { }
```

---

## 7. 변경 영향 분석

토큰/컴포넌트/패턴 변경 시 영향받는 문서:

### 예시: `tokens/colors` 변경 시

영향받는 문서:
- `_components/*.md` (모든 컴포넌트)
- `specs/practice/repertoire_section_crud_spec.md`
- (기타 `@uses: tokens/colors`를 선언한 모든 문서)

### 변경 절차

1. 토큰/컴포넌트/패턴 문서 수정
2. 해당 모듈을 `@uses`하는 모든 문서 확인
3. 필요시 스펙 문서 업데이트
4. 레지스트리 업데이트

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.3 | 2026-03-07 | 마스터 문서 13개 등록, DOCUMENT_INDEX.md 연결 |
| 1.2 | 2026-01-24 | student_form_widgets barrel_file 사용처 추가 |
| 1.1 | 2026-01-24 | 코드 패턴 섹션 추가 (barrel_file, mixin_split) |
| 1.0 | 2026-01-04 | 초기 레지스트리 생성 |
