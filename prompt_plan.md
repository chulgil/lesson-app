# 현재 계획: 기획 갭 10건 스펙 단순화 (UX/기획 재검증 반영)

> 생성: 2026-05-18
> 모드: **기본 확장** (방향 A·B·C·D 모두 채택)
> 원본 갭 문서: `/Users/r00360/Dev/mybrain/10 Projects/레슨앱/15-기획방향-보완.md`

## 배경

10개 갭 스펙(G1–G10)을 작성 완료했으나 UX/기획 관점 재검증에서 빨간불 5개 발견:

1. 🔴 G4 자격 조건 4단계 — "왜 보상 안 와요?" 컴플레인
2. 🔴 G2 14세 미만 A/B/C 분기 — 가입 이탈
3. 🔴 G9 강제 복구 이메일 + 백업코드 — 가입 직후 이탈
4. 🟠 설정 화면 비대화 — 토글 13+개
5. 🟠 1인 운영 부담 누적 — Year 1 실행 불가능성

## 단순화 PR — 4건

### A. G4 추천 보상 단일화 ✅

**파일**: `docs/specs/lesson/invite/teacher_referral_spec.md`

- [x] 3단계 보상(가입/자격/전환) → **단일 보상**(가입 즉시 Pro 1주 양쪽)
- [x] 자격 판정 워커 §3.4 삭제
- [x] 어뷰징 방지는 device_id + IP throttle + 월 한도(20명) + 7일 회수 유지
- [x] §3.3 보상 단계 표 단순화
- [x] 의사결정 로그에 단순화 근거 추가

### B. G2 14세 미만 단일 경로 ✅

**파일**: `docs/specs/user/account_lifecycle_spec.md`

- [x] 경로 A/B/C → **A(자녀 프로필)만 유지**
- [x] 경로 B(부모 동의 + 자녀 계정) → Year 2 백로그로 명시 이동
- [x] 경로 C(가입 거절) 삭제 — A로 흡수
- [x] ParentalConsent 테이블은 유지 (Year 2 대비) but 가입 흐름에서 분리
- [x] §의사결정 로그 갱신

### C. G9 점진 보안 ✅

**파일**: `docs/specs/user/account_recovery_spec.md`

- [x] 복구 이메일 **선택**으로 변경 (skip 가능, 미설정 시 보안 뱃지 표시)
- [x] 백업 코드 → **Pro 전용 기능**
- [x] 첫 가입 가이드 §9.2 "skip 불가" 제거
- [x] 일반 잠금 케이스는 "이메일 매직 링크"로 90% 해결 (§2.1 점진 도입 표)
- [x] 의사결정 로그에 점진 도입 근거 추가

### D. 설정 IA 통합 (신규 스펙) ✅

**파일**: `docs/specs/design/settings_information_architecture_spec.md` (신규 생성)

- [x] "내 데이터 · 프라이버시" 단일 허브 정의
- [x] G3·G7 옵트아웃 → 단일 "데이터 수집 끄기" 토글로 통합 (내부적으로 둘 다 OFF)
- [x] G2 내보내기·삭제·동의 이력을 같은 허브에
- [x] "로그인 보안" 별도 그룹 (복구 이메일 + 활성 세션 + 백업 코드 Pro)
- [x] G3·G7 스펙은 본문 유지, "진입점은 IA 스펙 참조" 명시

### E. 부수 정리 ✅

- [x] `event_tracking_spec.md` §2.3, §7 옵트아웃 위치 → IA 스펙 참조로 변경
- [x] `crashlytics_spec.md` §7.1 옵트아웃 위치 → IA 스펙 참조로 변경
- [x] `customer_support_spec.md` Phase 2 항목(인앱 트래커) → 백로그 명시 강화
- [x] `last_active_at` 필드 SSOT 통일 (reengagement_spec이 정의, account_recovery Session.last_active_at은 별개임을 명시)

## 검증

| 항목 | 방법 |
|------|------|
| 설정 화면 깊이 | 1단계 감소 확인 (옵트아웃 13개 → 7개 가시) |
| 가입 흐름 단계 | 14세 미만 분기 1개로 감소 |
| 추천 룰 설명 | "추천 코드 공유 → 가입 즉시 Pro 1주" 한 문장 |
| 1인 운영 부담 | Phase 1만 출시 시점, Phase 2 백로그 명시 |

## 진행 순서

1. PR A·B·C 병렬 (스펙 본문 편집)
2. PR D 신규 작성
3. PR E 부수 정리 (A·B·C·D 머지 후)

승인 시 PR A부터 작업 개시.

---

## 이전 계획

### 선생님 공지 시스템 v3 (2026-05-07)

> 공지 중심 재설계 — 모든 Phase A–E 완료. `docs/specs/student/bulk_teacher_actions_spec.md` v3 기준 머지.
