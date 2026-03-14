# 수기 관리 vs 연동 관리 수강료 분리 스펙

> 작성일: 2026-03-14
> 상태: 구현 완료
> 관련: subscription_master.md, edit_student_screen.dart

---

## 1. 문제 정의

### 1.1 현재 상태

수강료가 두 곳에서 독립적으로 관리되고 있음:

| 위치 | 필드 | 용도 | 편집 |
|------|------|------|------|
| 학생 수정 화면 | `Student.monthlyFee` | 수기 참고 수강료 | 자유 편집 |
| 수강권 발급 화면 | `Subscription.amount` | 실제 결제 금액 | 발급 시 입력 |

### 1.2 문제점

1. **두 값이 불일치해도 경고 없음** — 학생 수정에서 20만원, 수강권은 24만원
2. **역할이 불명확** — "수강료"가 어디서 관리되는지 사용자가 혼란
3. **수기 관리 선생님에게 수강권 시스템이 과도** — 개인 레슨 선생님은 티켓 발급 불필요
4. **연동 관리 시 수기 수강료 편집이 오해 유발** — 수정해도 수강권에 반영 안 됨

---

## 2. 설계: 하이브리드 모드 (C안 + 연동 상태 기반 접근 제어)

### 2.1 핵심 원칙

> **연동된 학생 = 수강료 읽기 전용, 수기 학생 = 수강료 편집 가능**

| 학생 유형 | 판별 기준 | 수강료 관리 | 학생 수정 화면 |
|----------|----------|------------|--------------|
| **연동 학생** | `hasActiveSubscription == true` 또는 `hasClassMembership == true` | 수강권 시스템 (Subscription) | `monthlyFee` **읽기 전용** + "수강권에서 관리" 안내 |
| **수기 학생** | 수강권/멤버십 없음 | 학생 프로필 (Student.monthlyFee) | `monthlyFee` **편집 가능** |

### 2.2 연동 판별 로직

```dart
/// 학생이 수강권 시스템과 연동되어 있는지 판별
bool isLinkedStudent(Student student, List<ClassMembership> memberships) {
  return memberships.isNotEmpty;
}
```

- `ClassMembership`이 1개 이상 존재 → 연동 학생
- `ClassMembership`이 없음 → 수기 관리 학생

### 2.3 학생 수정 화면 변경

#### 수기 학생 (멤버십 없음)

```
레벨 및 수강료
├── 레벨 선택: [초급 ▼]
├── 수강료: [200,000] 원  ← 편집 가능
├── 주 N회 레슨: [1회 ▼]
└── (수강권 미사용 안내 없음)
```

#### 연동 학생 (멤버십 있음)

```
레벨 및 수강료
├── 레벨 선택: [중급 ▼]
├── 수강료: 240,000원  ← 읽기 전용 (회색 배경)
│   └── "수강권으로 관리 중"  ← 안내 텍스트
├── 주 N회 레슨: [2회 ▼]
└── [수강권 관리 →]  ← 수강권 화면 바로가기
```

---

## 3. 변경 범위

### 3.1 코드 변경

| 파일 | 변경 내용 |
|------|----------|
| `edit_student_screen.dart` | 멤버십 존재 여부 확인 → monthlyFee 필드 읽기 전용 전환 |
| `student_form/basic_info_fields.dart` 또는 level_tuition 섹션 | 연동 상태에 따른 UI 분기 |

### 3.2 엔티티 변경

- **없음** — 기존 `Student.monthlyFee`와 `Subscription.amount` 그대로 유지
- `ClassMembership` 존재 여부로 판별하므로 스키마 변경 불필요

### 3.3 Provider 변경

- `edit_student_screen.dart`에서 `studentMembershipsProvider(studentId)` 참조 추가
- 읽기 전용 판별용으로만 사용

---

## 4. UX 상세

### 4.1 수기 학생 → 연동 학생 전환 시

1. 선생님이 학생에게 수강권 발급
2. `ClassMembership` 생성됨
3. 다음 학생 수정 화면 진입 시 `monthlyFee`가 자동으로 읽기 전용
4. 스낵바: "수강권이 발급되어 수강료는 수강권에서 관리됩니다"

### 4.2 연동 학생의 수강권 모두 만료 시

- `ClassMembership`은 유지 → 여전히 읽기 전용
- 이유: 수강 이력이 있는 학생은 수기 관리로 돌아가지 않음
- 재발급 시 기존 금액 참조 가능

### 4.3 수기 학생에서 수강료 변경 시

- 변경 이력 없음 (현재 구조 유지)
- 향후 백엔드 도입 시 `monthlyFee` 변경 로그 추가 가능

---

## 5. 구현 단계

### Step 1: 학생 수정 화면에 연동 판별 추가
- `studentMembershipsProvider` 참조
- `monthlyFee` 필드에 `enabled: !isLinked` 적용
- 연동 시 "수강권으로 관리 중" 안내 + 바로가기 버튼

### Step 2: 수강권 발급 시 monthlyFee 기본값 제안
- `issueSubscription` 화면에서 `student.monthlyFee`를 금액 기본값으로 설정
- 이미 `Subscription.amount`에 값이 있으면 해당 값 우선

---

## 6. 리스크

| 리스크 | 심각도 | 대응 |
|--------|:------:|------|
| 멤버십 있지만 수강권 미발급 상태 | LOW | 멤버십 존재 = 연동으로 간주, 수강권 발급 유도 |
| 수기→연동 전환 시 기존 monthlyFee 값 | LOW | 값은 유지, 읽기 전용으로만 전환 |
| 학생이 여러 멤버십에 속한 경우 | LOW | 수강권별 금액이 다를 수 있으므로 "수강권에서 관리" 안내만 |

---

## 관련 문서

| 문서 | 역할 |
|------|------|
| [subscription_master.md](subscription_master.md) | 수강권 시스템 전체 스펙 |
| [teacher_ux_review.md](../design/teacher_ux_review.md) | 선생님 UX 검토 보고서 |
