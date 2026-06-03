# 백엔드 잔여 작업 우선순위 (2026-06-03)

> 작성: 2026-06-03 (드리프트 동기화 후속 Item 3 — BE 잔여 우선순위 결정)
> 상태: 활성 백로그. 프론트엔드 작업은 사실상 완료(드리프트 동기화 후 FE-scope 열린 이슈 0), 잔여는 백엔드 중심.
> 기준: 데이터 정합성/보안 > FE 완료분 unblock > 인프라/품질 순. effort는 상대 규모(S/M/L).

## 우선순위 시퀀스

### P0 — 데이터 정합성 · 보안 (먼저 수정)

| 순 | 이슈 | 내용 | effort | 비고 |
|----|------|------|:------:|------|
| 1 | **#469** | 출석 스케줄러 자동완료 시 **수강권 차감 누락 + UTC 날짜/시간 오류** | M | 진행 중 데이터 손상 위험. FE 사전안내 UI는 #473로 분리됨 |
| 2 | **#468** | 수강권 **우회/이중발급/만료복구** 보안 | M | 수강권 무결성 |
| 3 | **#467** | 초대(invite) 노출 + 중복 수락 | S | ⚠️ 다른 세션 진행 중(`fix/467` worktree) — 중복 착수 금지 |

> 참고: 백엔드 접근제어 IDOR(#460~#466)은 PR #472로 이미 머지됨.

### P1 — FE 완료분 end-to-end unblock (critical 기능)

| 순 | 이슈 | 내용 | effort | 의존 |
|----|------|------|:------:|------|
| 4 | **#431** | 휴가 모드 BE — `TeacherAvailability.vacationPeriods`, `Subscription.autoExtendedDays` 필드+마이그레이션, 영향 레슨 조회 API, 3 disposition API, 만료 자동연장 | L | FE 완료(PR #471). #432와 연동(보강 자동등록) |
| 5 | **#432** | Make-up Bank BE — `MakeupCredit` 모델/repo/service, `Subscription.scheduledLessons`/`bonusCount`, 적립 트리거 4종, 사용 정책, **30일 만료 cron**, 일괄변경 재계산 | L | FE 완료(PR #471). #431 휴가 보강과 연동 |
| 6 | **#423** | 카카오 알림톡 `LNZ_INVOICE`/`LNZ_PAYMENT_CONFIRM` | M | 입금/결제 알림. #431 `LNZ_TEACHER_VACATION`도 같은 알림톡 인프라 |

### P2 — 인프라 · 품질

| 순 | 이슈 | 내용 | effort |
|----|------|------|:------:|
| 7 | **#418** | beta 통합 테스트 스캐폴딩 (api-beta 종단 시나리오) | M |
| 8 | **#470** | 백엔드 감사 중간/낮은 위험 수집 | S |
| 9 | **#417** | #318 R2 20개 도메인 선생님 단독 모드 감사 | S |

### 신규 트래킹 (본 작업에서 이슈 신설 완료)

| 항목 | 이슈 | 내용 | effort | 우선순위 |
|------|------|------|:------:|:--------:|
| FCM Firebase 설정 | **#475** | 알림 코드는 완료, Firebase 프로젝트/인증서/APNs 키 설정 + 토큰 등록 BE 대기 (로드맵 Phase 3-4) | M | P1~P2 (푸시 활성화 필요 시) |
| academy BE (mock→remote) | **#476** | `features/academy/` 8 repository 전부 Mock. Academy 모델/API/수강권 귀속(SubscriptionOwnership) BE. academy_master.md 참조 | XL | 학원 기능 출시 시점에 결정 (현재 P3) |

## 권고 착수 순서

```
#469 → #468 → (#467은 타 세션) → #431 → #432 → #423 → FCM 설정 → #418
```

- P0 버그/보안을 먼저: 데이터 손상·무결성은 복구 불가 리스크.
- #431·#432는 FE가 이미 머지되어 BE만 채우면 즉시 end-to-end 동작. 둘은 보강 크레딧으로 강결합 → 묶어서 진행 권장.
- academy BE는 규모(XL)가 커 별도 마일스톤. 출시 로드맵 확정 후 분해.

## 정책 제약 (불변)

- 수강료(흐름 A/A')는 **무통장입금만**, PG 영구 비채택. 앱 사용료(흐름 B)만 스토어 IAP. → [payment_architecture.md](../subscription/payment_architecture.md)

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-06-03 | BE 잔여 백로그 우선순위 최초 작성 (Item 3) |
