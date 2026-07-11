# 오프라인/동기화 마스터 스펙 (SSOT)

> 상태: 활성 · 작성 2026-07-03 · 소유 범위 `frontend/lib/core/sync`, `frontend/lib/core/network/cache`
> 정본(SSOT). 요구사항 원안 = 옵시디언 `14-RA-동기화-상세스펙`(2026-05-07, 일부 대체됨). 채택 계획/롤아웃 이력 = `docs/specs/architecture/offline_first_migration_plan.md`(D1~D6). 이 문서는 **현재 구현된 계약(as-built)** 과 **미국 등 느린 네트워크 대응 계약**, **검증된 갭 레지스터**를 정의한다.

## 1. 결론 먼저

앱은 "서버 미연결 시 로컬 데이터 표시 + 나중 동기화"를 지향한다. 현재 구현은 **읽기 = HTTP 응답 캐시 인터셉터**(전송 실패 시 last-known-good 서빙), **쓰기 = 뮤테이션 큐**(오프라인/전송실패 시 큐잉 + 낙관적 결과, 재접속 시 재생)로 되어 있다. 뼈대는 동작하나, **완전 오프라인(무선 차단)** 은 부분 처리되고 **느린-연결(무선 살아있고 타임아웃, 미국 셀룰러 전형)** 은 처리 공백이 크다. 또한 **schedule 도메인 쓰기가 어댑터 미등록으로 영구 손실**되는 P0 데이터 유실 버그가 있다.

- 가장 시급 3건 해소: [G-01](#g-01)(#1113), [G-02](#g-02)·[G-03](#g-03)은 PR #1159(2026-07-10)로 해소 — 유실 시 사용자 통지만 잔여(#1188).
- 느린 네트워크 핵심: [G-04 SWR 부재(풀 타임아웃 대기)](#g-04), [G-05 읽기 캐시 5개 도메인만](#g-05), [G-06 느린망 stale 표시 없음](#g-06), [G-07 타임아웃 중복 생성](#g-07).

## 2. 용어

| 용어 | 정의 |
|------|------|
| 완전 오프라인 | `connectivity_plus`가 무선 없음(none) 보고 — 비행기모드/무신호 |
| 느린-연결(degraded) | 무선은 살아있으나 고RTT/패킷손실/타임아웃 — 미국 셀룰러 전형. 본 스펙의 1급 대상 |
| 뮤테이션 큐 | 쓰기 재생 큐 (`SyncQueueStore`, Hive box `sync_queue`) |
| 응답 캐시 | GET 응답 캐시 (`ResponseCacheStore`, Hive box `response_cache_v1`) |
| 낙관적 결과 | 쓰기를 큐에 넣고 UI에 즉시 성공으로 보이는 임시 결과 |
| LWW | Last-Write-Wins 충돌 해결 (clientUpdatedAt vs serverUpdatedAt 비교) |

## 3. 아키텍처 (as-built)

```
쓰기: UI -> SyncAware{Domain}Repository -> MutationQueueHelper
        온라인 성공 -> 서버 반영
        오프라인/전송실패 -> SyncQueueStore(enqueue) + 낙관적 결과
        재접속/30s 폴 -> SyncService.syncPending -> SyncAdapterRegistry.resolve(domain) -> RestSyncAdapter.replay(HTTP 재생)

읽기: UI -> Remote{Domain}Repository -> ApiClient(Dio)
        인터셉터 체인: Logging -> Auth -> Error -> Refresh -> ResponseCacheInterceptor(말미)
        성공 GET(allowlist) -> onResponse: 캐시 저장
        전송실패 GET(allowlist, 캐시히트) -> onError: 캐시 서빙(fromCache)
```

핵심 파일: `core/sync/application/{sync_service,mutation_queue_helper,sync_adapter,sync_adapter_registry,connectivity_service,initial_pull_service}.dart` · `core/sync/data/sync_queue_store.dart` · `core/network/cache/{response_cache_store,response_cache_policy}.dart` · `core/network/interceptors/response_cache_interceptor.dart`.

## 4. 쓰기 큐 계약

### 4.1 큐 엔트리 (`SyncQueueEntry`)

`id`(uuid) · `domain` · `method`+`path`+`payload`(HTTP 재생용) · `status`(pending/syncing/synced/failed) · `retryCount` · `createdAt` · `lastSyncedAt` · `clientUpdatedAt`(LWW 기준 버전 — 재생 시 `If-Unmodified-Since` 헤더로 전송, [§7](#7-충돌-해결-계약-d4), 선택) · `idempotencyKey`(#1117, 선택 — 클라이언트 생성, 초기 요청·재생에 동일 키 전송해 서버 dedupe. 이전 버전 엔트리는 null → [§4.3](#43-재시도만료) 고아 복구가 legacy 로 취급).

### 4.2 불변식 (HARD-GATE)

- **INV-1 (도메인-어댑터 정합)**: `queueMutation(domain: X)` 로 큐잉하는 모든 도메인 X는 반드시 `SyncAdapterRegistry`에 등록되어야 한다. 미등록 시 재생이 `NO_ADAPTER`로 영구 실패하고 쓰기가 유실된다. 레지스트리는 실제 큐잉 호출처에서 파생·검증되어야 한다(현재 하드코딩 → [G-01](#g-01) 원인). 큐잉 도메인 전수: `lesson`·`student`·`subscription`·`practice`·`schedule`.
- **INV-2 (재생 멱등성)**: 재생은 서버가 이미 커밋한 요청을 중복 생성하지 않아야 한다(멱등 키). **충족(#1117)** — 클라이언트가 초기 요청·재생에 동일 `Idempotency-Key`(user_id 스코프)를 보내고, 서버(`idempotency_keys` 테이블 + `IdempotencyMiddleware`)가 reserve-first 로 POST 를 dedupe. → [G-07 해소](#g-07).
- **INV-3 (무손실 정리)**: 큐 정리(cleanup)는 **미전송(pending) 쓰기를 무통보로 삭제하지 않는다**. 해소(PR #1159): 용량 트리밍은 synced/failed 만 제거, pending/syncing 보존 (`sync_queue_store_cleanup_test.dart`) → [G-03](#g-03).
- **INV-4 (사용자 격리)**: 큐는 사용자 경계에서 격리되어야 한다. 로그아웃 시 이전 사용자 pending 쓰기가 다음 사용자 토큰으로 재생되면 안 된다. 해소(PR #1159): `logout()` 이 `sync_queue` 를 비움 (`auth_logout_sync_queue_test.dart`). 클리어 시 미전송 통지는 잔여 → #1188 → [G-02](#g-02).

### 4.3 재시도/만료

- 재시도: 최대 5회, 지수 백오프 1→16s(상한 30s 폴). 소진 시 status=failed.
- 만료: failed 엔트리 7일 초과 시 삭제. **삭제 시 사용자 알림 필요**(요구안 §8) — 알림은 미구현, #1188 에서 추적 → [G-03](#g-03).
- 재생 에러 분류: 비즈니스 4xx(409/422 등)는 재시도 대상이 아니어야 한다(현재 catch-all 재시도 → [G-14](#기타-확인된-갭)).
- **고아 복구(#1162)**: 재생 중 앱이 강제 종료되면 엔트리가 `syncing` 으로 남는다. 시작 시(`SyncService.initialize`) `syncing` 엔트리를 재분류하며, 이후 플러시는 `syncing` 을 후보에서 제외한다(`_isPending`/`_isProcessable`). 규칙: `idempotencyKey` 있으면 → `pending`(재생이 서버에서 dedupe) · 키 없고 PUT/PATCH/DELETE → `pending`(자연 멱등) · **키 없고 POST(legacy) → `failed`+`ORPHANED_UNSAFE_REPLAY`**(자동 재생 시 중복 위험 → 사용자 판단으로 넘김, 무통보 삭제 금지). 상태 UI 노출은 [G-10](#g-10)/#1120.

## 5. 읽기 캐시 계약

- **저장**: allowlist 경로의 2xx GET 응답을 저장(`ResponseCacheInterceptor.onResponse`).
- **서빙**: allowlist GET이 **전송 실패**(connectionError / connect·receive·send Timeout)하고 캐시 히트 시 last-known-good 서빙(`onError`, `fromCache:true`). 비즈니스 4xx/5xx·캐시미스·비-GET·비-allowlist는 그대로 전파.
- **무효화(N7)**: 비-GET 2xx 성공 시 해당 prefix 캐시 제거. 교차 도메인 효과(예: 레슨 완료가 구독 사용량 차감)는 범위 밖 → [G-13](#기타-확인된-갭).
- **TTL(D3)**: 민감 경로(`/subscriptions/payment-pending`)는 15분 TTL, 그 외 표시 도메인은 무TTL(재접속까지 stale).
- **allowlist(현재)**: 배치1 `/lessons` · `/students` · `/subscriptions` · `/schedule/availability` · `/schedule/slots` + 배치2(#1116) `/parents` · `/manual-teachers` · `/practice` · `/practice-logs` · `/recordings` · `/teachers` · `/gamification` (12개). segment-aware(형제 경로 `/lessons-classes` 등 미포함). `/parents/billing-target` 는 민감 15분 TTL. 배치 3~4(profile·settings·search·academy·analytics 등)·알림 미배포, auth·billing 은 fresh 필수로 제외 → [G-05](#g-05).

## 6. 느린 네트워크 대응 계약 (미국 시장 1급 요건)

> 완전 오프라인이 아니라 **무선 살아있고 타임아웃**이 미국 셀룰러의 지배적 실패다. 아래는 이 조건의 목표 계약이며 현재 대부분 미충족이다.

| # | 계약 | 현재 | 갭 |
|---|------|------|-----|
| SN-1 | 읽기는 캐시가 있으면 **즉시** last-known-good을 보이고 백그라운드 갱신(stale-while-revalidate) | 구현(#1116) — onRequest 소프트타임아웃 레이스: 빠른망 최신 직행, 느린망 캐시 즉시 서빙 후 백그라운드 갱신 | [G-04](#g-04) |
| SN-2 | 핵심 사용자 화면 읽기는 전부 캐시 보호(연습·홈·게이미피케이션·알림 포함) | 배치2 확장(#1116) — parents·manual-teachers·practice·gamification 캐시 보호. 배치3~4·알림 미배포 | [G-05](#g-05) |
| SN-3 | 캐시(stale) 서빙 중이면 무선 상태와 무관하게 "지난 동기화 시각" 표시 | 구현(#1116) — 배너가 캐시-서빙 신호로 게이팅(connectivity 무관), fresh 시 소거, 느린망 문구 분리 | [G-06](#g-06) |
| SN-4 | 응답 유실된 POST 재생이 서버 중복 생성 금지(멱등 키) | 구현(#1117) — 클라이언트 생성 키 + 서버 (user_id,key) 유니크 dedupe | [G-07 해소](#g-07) |
| SN-5 | 전송 타임아웃 값이 느린망에 합리적(과단축=허위실패, 과장=UI 프리즈) + 업로드 sendTimeout 설정 | connect/receive 30s, sendTimeout 미설정, refresh Dio 무타임아웃 | [G-08](#g-08) |
| SN-6 | 일시적 읽기 실패(단발 패킷손실)에 요청 단위 재시도(백오프) | 읽기 재시도 없음 | [G-11](#기타-확인된-갭) |
| SN-7 | 쓰기 탭이 풀 타임아웃 동안 UI를 막지 않음(빠른 큐 폴백) | 온라인 판정 통과 시 remoteCall 완료까지 대기(~30s 프리즈) | [G-12](#기타-확인된-갭) |

## 7. 충돌 해결 계약 (D4)

- 전략 맵: `serverWins`(기본: lesson·subscription·student·schedule) / `lastWriteWins`(practice·settings·notification-settings) / `clientWins`(recording).
- **LWW = 전송 전 조건부 요청(#1119)**: `lastWriteWins` 도메인 쓰기는 `If-Unmodified-Since` 헤더에 **클라이언트가 편집한 기준 버전**(practice = `PracticeLog.updatedAt`, 큐 엔트리의 `clientUpdatedAt`)을 실어 보낸다. 서버는 리소스 `updated_at`이 그 기준보다 **엄격히 이후**면 `412 CONFLICT_LWW_REJECTED`로 거절한다(그 사이 다른 쓰기가 서버를 갱신 = 서버가 더 최신). 헤더 없으면(기준 버전 미상) 무조건 적용. as-built 였던 "전송 **후** 응답 비교"는 거절이 구조적으로 불가능해 폐기됨 — 어댑터는 이제 모든 전략에서 요청만 보내고, LWW 여부는 헤더 부착으로만 갈린다. 서버 `LastWriteWinsConflictException`(412) ↔ 클라이언트 `conflictLwwRejectedCode`.
- **거절 = 즉시 terminal + SnackBar(#1119)**: 재생이 `CONFLICT_LWW_REJECTED`로 거절되면 재시도해도 같은 낡은 쓰기라 결정적이다 — `SyncService`가 엔트리를 즉시 `failed`(retryCount 소진, 재시도 없음)로 표시하고 `errorCode`를 보존하며 `rejectionStream`으로 이벤트를 발행한다. 앱 루트가 이를 구독해 전 역할 공통 SnackBar를 띄운다. → [G-09 해소](#g-09).
- 첫 전송(온라인 직접 호출)도 같은 헤더를 부착하나, 사용자가 화면에서 지켜보는 동기 요청이므로 첫-전송 412는 호출 프로바이더의 일반 에러 경로로 표면화한다(비동기 재생 거절만 SnackBar 스트림 경유).

## 8. 상태 UI 계약 (요구안 §7)

구현(#1120): 쓰기 큐 백로그는 앱 루트 `OfflineBannerWrapper`(전 역할 공통, MaterialApp.builder)가 렌더하는 **`SyncStatusBanner`** 한 줄로 노출한다. 읽기 신선도(오프라인/stale) 배너와 하나의 top `SafeArea`를 공유하며(두 번째 스트립이 상태바 인셋을 이중 적용하지 않도록), 우선순위는 실패 > 동기화중 > 대기.

| 상태 | 표시 | 구현 |
|------|------|------|
| 대기 | 온라인 "N건 전송 대기 중" / 오프라인 "오프라인 · N건 대기" | `SyncServiceStats.pending` + `.online` |
| 동기화 중 | "N건 동기화 중" + 스피너 | `SyncServiceStats.syncing` (이전 소비처 0) |
| 실패 | "N건 전송 실패" (탭 → 인라인 패널: 항목별 재시도/삭제) | `SyncService.failedEntries/retryEntry/deleteEntry` |

- 실패 패널의 항목별 문구는 `errorCode`로 분기: `ORPHANED_UNSAFE_REPLAY`(재시도 = 재전송 동의)·`CONFLICT_LWW_REJECTED`(서버 최신과 충돌)·일반. 재시도는 retryCount를 0으로 리셋해 terminal 엔트리도 사용자 명시 동의로 재전송한다.
- 교사 대시보드 전용 실패 배너는 전 역할 공통 `SyncStatusBanner`로 대체(중복 제거). → [G-10 해소](#g-10).

## 9. 갭 레지스터 (2026-07-03 검증)

> 워크플로우 7영역 병렬 실측 + 코드 직접 재검증(origin/main `ae5f7377`). severity: P0=데이터유실/무결성, P1=느린망 핵심 사용자 실패, P2=피드백/일관성, P3=폴리시.

### G-01
**[P0] schedule 도메인 어댑터 미등록 → 큐된 availability 쓰기 영구 유실.** availability 리포 12곳이 `domain: 'schedule'`로 큐잉하나 `SyncAdapterRegistry`는 `'schedule'` 미등록(대신 미사용 `'booking'`). 느린망 타임아웃→큐잉→낙관적 성공 표시 후, 재생이 `NO_ADAPTER`로 즉시 failed → 교사 근무가능시간 저장이 조용히 사라짐. 근거: `sync_adapter_registry.dart:19-41`, `sync_aware_teacher_availability_repository.dart:114-312`(12x), `sync_service.dart:199-208`. **수정: 레지스트리 `'booking'`→`'schedule'` + 도메인별 재생 e2e 테스트.** 즉시 반영 대상.

### G-02
**[P0→해소] 로그아웃이 쓰기 큐를 비우지 않아 교차 사용자 재생.** `logout()`은 토큰·`notification_settings`·응답 읽기캐시는 비우나 `sync_queue`는 미삭제였음. 사용자 A의 pending 쓰기가 계정 전환 후 B 토큰으로 재생. **해소(PR #1159, 2026-07-10)**: `logout()` 에 큐 클리어 배선 + `auth_logout_sync_queue_test.dart`. 클리어 시 미전송 쓰기 사용자 통지는 #1188.

### G-03
**[P0→해소(통지 잔여)] 큐 정리 시 미전송 쓰기 무통보 삭제.** `cleanup()`이 500 초과 시 status 무관 최오래 삭제(pending 포함)였음. **해소(PR #1159, 2026-07-10)**: 트리밍은 synced/failed 만, pending/syncing 보존 (`sync_queue_store_cleanup_test.dart`). failed 7일 만료 삭제의 사용자 알림은 미구현 — #1188.

### G-04
**[P1] SWR 부재 — 모든 읽기가 풀 타임아웃 대기 후에야 캐시.** 캐시는 `onError`에서만 서빙, `onRequest` cache-first 없음. 고RTT/패킷손실 미국망에서 화면마다 최대 30s 스피너 후 last-known-good. 근거: `response_cache_interceptor.dart:37-93`(onRequest 없음), `api_client.dart:146-151`(30s), `environment.dart:24-27`. **해소(#1116): `onRequest` 캐시-우선 + 단일 백그라운드 재검증을 `swrSoftTimeout`(~2.5s)과 레이스 — 빠른망은 창 안에 최신 직행(무 stale-flash), 느린망은 캐시 즉시 서빙 후 백그라운드가 store 갱신. 서빙 stale 와 다르면 재검증 버스(`RevalidationEvents`/`ref.autoRevalidate`)가 구독 read 프로바이더를 자동 갱신(변경 시에만 emit → 루프 방지).**

### G-05
**[P1] 읽기 캐시 allowlist 5개 도메인만 — 배치 2~4 미배포.** practice·parent_home·student_home·gamification·notifications·settings·profile·search 등은 fail-closed(타임아웃→에러/무한스피너). 학생측 최고빈도 화면(연습 허브)이 느린망에서 raw 에러. 근거: `response_cache_policy.dart:26-36`(5 prefix), 계획 §5 배치 2~4. **부분 해소(#1116): 배치2(`/parents`·`/manual-teachers`·`/practice`·`/practice-logs`·`/recordings`·`/teachers`·`/gamification`) 추가 — 전부 bespoke 캐시 없는 plain remote(double-cache 실측 0). `/parents/billing-target` 15분 TTL. 배치3~4·알림은 후속, auth·billing 은 fresh 필수로 영구 제외.**

### G-06
**[P1] 느린망 stale 표시 없음(D2 위반).** stale 배너가 무선-오프라인(`isOffline`)일 때만 렌더. 캐시는 무선 살아있는 타임아웃에도 서빙되므로, 느린망 사용자는 몇 시간 지난 레슨/일정을 최신처럼 무표시로 봄. `onCacheServed`/`lastServedFromCacheAtProvider`는 배선됐으나 offline 분기 안에서만 소비. 근거: `offline_banner.dart:28,41-46`. **해소(#1116): 배너 게이팅을 `isOffline || staleMarker≠null` 로 확장(connectivity 무관 캐시-서빙 신호 기반). 라이브 읽기 도달 시 `onFreshServed`→marker 소거로 배너 자동 사라짐. 문구·아이콘 분리(오프라인/느린망).**

### G-07
**[P1] 타임아웃 시 멱등 키 없어 중복 생성.** POST가 전달됐으나 응답이 receiveTimeout → 큐잉 후 멱등 키 없이 재생 → 서버가 중복 레슨/구독 생성. 느린망의 대표 실패. 근거: `mutation_queue_helper.dart:37-45`, `error_interceptor.dart:23-31`, `sync_queue_entry.dart`(멱등 필드 없음). **해소(#1117): FE `IdempotencyInterceptor` 가 초기 mutation 요청에 `Idempotency-Key`(uuid v4)를 부착·`extra` 에 stash → 실패 시 `ErrorInterceptor` 가 예외로 그 키를 실어 큐 엔트리에 동일 키 저장(`SyncQueueEntry.idempotencyKey`) → 재생이 같은 헤더 재부착. BE `idempotency_keys` 테이블 + `IdempotencyMiddleware` 가 reserve-first(유니크 위반 시 저장된 응답 replay / 처리 중이면 409 `CONFLICT_IN_FLIGHT`)로 POST dedupe. PUT/DELETE 는 자연 멱등이라 서버 dedupe 대상 외.**

### G-08
**[P1] sendTimeout 미설정 + refresh Dio 무타임아웃.** 본 Dio는 connect/receive만, sendTimeout 없음 → 본문 업로드 정지 시 OS TCP까지 행. `RefreshInterceptor`의 Dio는 타임아웃 전무 + QueuedInterceptor라 정지된 refresh가 전 파이프라인을 분 단위로 동결. 근거: `api_client.dart:143-151`, `refresh_interceptor.dart:29-31`.

### G-09
**[P1→해소 #1119] D4 LWW/거절 SnackBar.** 이전: `CONFLICT_LWW_REJECTED` 미소비, `_buildReplayError`가 errorCode를 null로 버림, LWW 비교가 전송 후라 거절 불가, practice가 `clientUpdatedAt` 미전달로 LWW 무력. **해소: LWW를 전송 전 `If-Unmodified-Since` 조건부 요청으로 전환(서버 412 `CONFLICT_LWW_REJECTED`), `_buildReplayError`가 errorCode 보존, practice가 기준 버전(`updatedAt`)을 헤더·`clientUpdatedAt`으로 전달, 거절은 즉시 terminal failed + `rejectionStream` → 앱 루트 SnackBar(전 역할).** 상세: [§7](#7-충돌-해결-계약-d4).

### G-10
**[P1→해소 #1120] 상태 UI — 대기 카운트/동기화중/역할 커버리지.** 이전: pending·syncing 카운트 미표시, 실패 표면이 교사 대시보드 탭 전용. **해소: 앱 루트 `OfflineBannerWrapper`가 전 역할 공통 `SyncStatusBanner`(대기/동기화중/실패 카운트 + 실패 항목별 재시도/삭제) 렌더, 교사 전용 배너 제거.** 상세: [§8](#8-상태-ui-계약-요구안-7).

### 기타 확인된 갭 (P2/P3)

| id | sev | 요약 | 근거 |
|----|-----|------|------|
| G-11 no-read-retry-backoff | P2 | 읽기 요청 단위 재시도/백오프 없음(단발 실패 즉시 에러→stale) | pubspec 재시도 패키지 없음 |
| G-12 write-blocks-full-timeout | P2 | 온라인 판정 통과 시 쓰기 탭이 풀 타임아웃 프리즈 후 큐 폴백 | `mutation_queue_helper.dart:30-45` |
| G-13 cross-domain-invalidation | P2 | 무효화가 prefix-local — 레슨 완료가 구독 사용량 캐시 미무효화 | `response_cache_interceptor.dart:58-59` |
| G-14 replay-retries-4xx | P2 | 재생이 비즈니스 4xx도 백오프 재시도(무의미 5회) | `sync_service.dart:224-239` |
| G-15 warmup-misses-subscriptions | P2 | InitialPull이 lessons/students/availability만 워밍, /subscriptions·/schedule/slots 누락 | `initial_pull_service.dart:69-73` |
| G-16 tmp-id-not-reconciled | P2 | 오프라인 생성 tmp_id가 서버 id로 재조정 안 됨 → 후속 편집 404 | `sync_aware_lesson_repository.dart:124` |
| G-17 backfill-absent | P2 | 기존 로컬 전용 데이터(녹음 등) 서버 백필 없음 | `rg backfill` 0 |
| G-18 unknown-socket-not-served | P2 | `DioExceptionType.unknown`+SocketException은 캐시 미서빙 | `response_cache_interceptor.dart:119-129` |
| G-19 no-reconnect-read-revalidation | P2 | 재접속 시 읽기 재검증 없음(쓰기 큐만) | `connectivity_service` 리스너 2곳 |
| G-20 sibling-endpoints-uncovered | P2 | segment-aware가 형제 경로(`/subscriptions-templates` 등) 제외 | `response_cache_policy.dart:53-68` |
| G-21 no-dedupe-coalesce | P2 | 동일 엔티티 반복 쓰기 중복 제거 없음. 미배선 `requestFingerprint` getter는 서버측 dedupe(#1117)가 동기를 흡수해 제거함(#1163). 화면단 재진입 가드는 개별 대응 | `sync_queue_entry.dart` |
| G-22 no-replay-e2e-tests | P2 | 도메인별 재생 e2e/역할별 인증-클리어 행위 테스트 없음(G-01이 이래서 유출) | `sync_service_test.dart` lesson만 |
| G-23 cache-no-schema-version | P3 | 캐시 payload에 앱/스키마 버전 스탬프 없음(앱 업데이트 후 파싱 실패 가능) | `response_cache_store.dart:26-39` |
| G-24 inflight-get-dedupe | P3 | 동일 in-flight GET 병합 없음(느린링크 슬롯 낭비) | 없음 |
| G-25 stats-stream-lag | P3 | 실패 배너가 최대 30s 폴 지연 | `sync_service.dart:57` |

## 10. 반영 계획 · 이슈 매핑 (2026-07-03)

| 갭 | 이슈 | 상태 |
|----|------|------|
| G-01 schedule NO_ADAPTER 유실 | #1113 | 본 PR 수정 |
| G-02 로그아웃 교차사용자 재생 | #1114 | 해소(PR #1159) — 클리어 통지 잔여 #1188 |
| G-03 큐 정리 미전송 삭제 | #1115 | 해소(PR #1159) — 만료 삭제 알림 잔여 #1188 |
| G-04·G-05·G-06 느린망 읽기(SWR·allowlist·stale표시) | #1116 | 수정(SWR 레이스+재검증버스 · 배치2 allowlist · stale배너). 배치3~4 allowlist·전 프로바이더 라이브갱신은 후속 |
| G-07 타임아웃 중복 생성(멱등키) | #1117 | 반영(INV-2 충족) — FE 키 생성·큐 저장·재생 + BE `idempotency_keys` reserve-first dedupe. §4.1·§4.3(고아 복구 #1162) 참조 |
| G-08 sendTimeout/refresh 타임아웃 | #1118 | 후속 |
| G-09 D4 LWW/거절 SnackBar dead | #1119 | 해소 — 전송 전 `If-Unmodified-Since` 조건부 요청 + 412 거절 즉시 terminal + `rejectionStream` SnackBar. [§7](#7-충돌-해결-계약-d4) |
| G-10 상태 UI 미완 | #1120 | 해소 — 전 역할 공통 `SyncStatusBanner`(대기/동기화중/실패 + 항목별 재시도/삭제). [§8](#8-상태-ui-계약-요구안-7) |
| G-21 requestFingerprint dead code | #1163 | 해소 — 미사용 getter 제거(서버측 dedupe #1117이 동기 흡수) |
| G-11~G-25 P2/P3 잔여 | #1121 | 트래킹 |

> INV-1~INV-4는 신규/변경 코드의 HARD-GATE. 특히 새 도메인 큐잉 추가 시 레지스트리 등록 + 재생 e2e 테스트 필수(G-01 재발 방지, #1113).

## 관련 문서

- 요구안 원본(대체 일부): 옵시디언 `14-RA-동기화-상세스펙`
- 채택 계획/롤아웃 이력: `docs/specs/architecture/offline_first_migration_plan.md`
- 관련 이슈: #872(practice sync 미구현) · #879(billing read-through) · #880(delta sync)
