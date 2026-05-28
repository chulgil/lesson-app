# academy/console_overview_spec — 학원장 콘솔 전체 구조

> 기준일: 2026-05-19
> 도메인: `console.lessonaza.app` (또는 `academy.lessonaza.app/admin` — AC-M2 결정 보류)
> 마일스톤: AC-M1 (도메인 모델) → AC-M2 (컨텍스트 토글) → AC-M3 (콘솔 MVP)
> 선행: [README.md](README.md), [../../web/auth/api_contract.md](../auth/api_contract.md), 옵시디언 `21-academy-요구사항.md`

## 1. 범위

학원장(R-AO) 콘솔의 **IA · 네비게이션 · 권한 격리 · 컨텍스트 토글** 전체 구조. 화면별 상세는 도메인별 스펙 (dashboard, teacher_management, student_management, billing_settlement, public_page) 참조.

## 2. 사용자

| 역할 | ID | 콘솔 접근 |
|---|---|---|
| 학원장 (운영전담) | R-AO | 전체 메뉴 |
| 학원장 (강사 겸직) | R-AO + R-AT | 학원장 모드 → 콘솔 / 내 강사 모드 → lesson-app |
| 강사 | R-AT | 콘솔 접근 불가 (lesson-app 만) |
| 학생/학부모 | R-AS | 콘솔 접근 불가 |

## 3. 정보 아키텍처 (IA)

```
console.lessonaza.app
├─ /                    대시보드 (오늘 신규/미수금/결근)
├─ /teachers            강사 관리
│  ├─ /invite           강사 초대
│  └─ /{id}             강사 상세 (학생, 출근율, 매출 기여)
├─ /students            학생 관리
│  ├─ /new              신규 등록 (강사 매칭 포함)
│  ├─ /waiting          매칭 대기 큐
│  └─ /{id}             학생 상세 (강사 변경, 이탈, 노트 일시 접근 요청)
├─ /billing             수강료 청구 / 수금 / 강사 배분
│  ├─ /invoices         월별 청구서 (PDF 일괄 발송)
│  ├─ /payments         수금 확인 (1클릭 + CSV 임포트)
│  └─ /settlement       강사 배분 명세 확정
├─ /stats               통계 (매출 + 강사 + 학생 집계)
├─ /announcements       공지사항 (전체/강사/학부모)
├─ /inbox               학부모 문의 인박스
├─ /page                학원 공개 페이지 편집
├─ /settings            학원 설정 (계좌·결제·정산 규칙·세금)
└─ /switch              모드 토글 → lesson-app
```

## 4. 네비게이션 / 레이아웃

- **데스크탑 우선** (1280px+), 태블릿 768px+ 지원, 모바일 360px+ 긴급 확인용
- 좌측 사이드바 (고정 폭 240px) + 상단 헤더 (학원 이름 + 컨텍스트 토글 + 알림 + 로그아웃)
- 사이드바 메뉴: 대시보드 / 강사 / 학생 / 청구·정산 / 통계 / 공지 / 인박스 / 학원 페이지 / 설정
- 컨텍스트 토글 위치: 상단 헤더 우측 — "학원장 모드 ▼" 클릭 시 "내 강사 모드로 전환" 옵션 (강사 겸직만 표시)

## 5. 권한 격리 (NFR-A-4 / NFR-A-5)

### 5.1 학원장 모드에서 차단되는 엔드포인트

| 엔드포인트 | 차단 사유 |
|---|---|
| `GET /api/v1/students/{id}/notes` | 학생 노트 비공개 |
| `GET /api/v1/students/{id}/recordings` | 녹음 비공개 |
| `GET /api/v1/lessons/{id}/notes` | 레슨 노트 비공개 |
| `GET /api/v1/practice-logs/{user_id}` | 연습 기록 비공개 |

호출 시 응답:
```json
{
  "error": "FORBIDDEN_ACADEMY_OWNER_SCOPE",
  "message": "학원장은 학생 개별 진도/노트에 접근할 수 없습니다.",
  "audit_id": "..."
}
```

모든 차단 호출은 `AuditLog` 기록 (user_id, target_student_id, endpoint, timestamp).

### 5.2 일시 접근 토큰 (R-AO-23)

분쟁/민원 시 학생 노트 일시 접근 가능. 2인 동의 + 90일 자동 회수. 상세: [student_management_spec.md §일시 접근](student_management_spec.md).

### 5.3 학원장 모드에서 허용되는 엔드포인트

- `/api/v1/academies/{id}/*` (학원 전체)
- `/api/v1/academies/{id}/teachers/*`
- `/api/v1/academies/{id}/students/*` (집계만)
- `/api/v1/academies/{id}/billing/*`
- `/api/v1/academies/{id}/stats/*`

## 6. 컨텍스트 토글 (R-AO-1, R-AO-3, FR-ACAPP-6)

### 6.1 모델

```python
class User(Base):
    role = Column(Enum("teacher", "student", "parent", "academy_owner"), nullable=False)

class AcademyMember(Base):
    academy_id = Column(FK)
    user_id = Column(FK)
    role = Column(Enum("owner", "teacher", "alumni"), nullable=False)
    # 학원장 겸직 강사: 같은 User 가 (role=owner) + (role=teacher) 2 행 보유
```

### 6.2 JWT scope

JWT 페이로드에 `active_context` 필드:

```json
{
  "user_id": 1,
  "active_context": "academy_owner",  // or "teacher"
  "academy_id": 42,
  "teacher_id": 7
}
```

`active_context` 가 `academy_owner` 일 때만 콘솔 메뉴 접근. 토글 시 새 JWT 발급 (POST `/api/v1/auth/context/switch`).

### 6.3 토글 UX

- lesson-app 상단: "학원장 모드로 전환" 버튼 → 콘솔 redirect (JWT 재발급)
- 콘솔 상단: "내 강사 모드로 전환" 버튼 → lesson-app deep link (JWT 재발급)
- **명시적 클릭 필수** — 자동 권한 승격 금지 (실수 방지)

## 7. 인증 / 세션

- SSO 로그인은 [api_contract.md §2](../auth/api_contract.md)
- 학원장 가입은 [signup_spec.md](../auth/signup_spec.md) §역할별 분기 `academy_owner`
- 콘솔 세션 만료: 4시간 무활동 시 자동 로그아웃 (재로그인 시 active_context 유지)

## 8. 디자인

- "Notebook × Score" 시그니처 영역 정책 준수 — [`docs/specs/design/notebook/README.md`](../../design/notebook/README.md)
- 일반 UI: Material 아이콘 허용
- 폰트: Pretendard (본문), Gaegu (헤더/시그니처 영역)

## 9. 기술 선택 (보류)

옵시디언 §11 미정 항목 — AC-M3 착수 전 결정:

| 옵션 | 장점 | 단점 |
|---|---|---|
| (a) React/Vue SPA | 풍부한 컴포넌트, 모바일 대응 쉬움 | 빌드 파이프라인 + 호스팅 추가 |
| (b) Jinja2 + HTMX | profile-renderer 와 동거, 운영 단순 | 복잡한 인터랙션 한계 |
| (c) Flutter Web | lesson-app 코드 재활용 | 데스크탑 폼/표 UX 약함 |

AC-M3 착수 전 학원장 5명 인터뷰 후 결정.

## 10. 변경 이력

- 2026-05-19: 초안 (AC-M1 ~ AC-M3 범위)
