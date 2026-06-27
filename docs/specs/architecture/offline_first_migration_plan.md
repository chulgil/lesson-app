# 오프라인-퍼스트 전면 적용 계획 (47-site)

> 상태: 계획(draft) — 코드 착수 전 검토용. 작성 2026-06-27.
> 트리거: "서버 미연결 시 로컬데이터 표기 + 나중에 동기화" 컨셉과 현재 동작 불일치 제보.
> 관련: 조사 결과(이 세션), `core/sync/`, 이슈 #872(practice_journal remote/sync) · #879(billing read-through) · #880(delta sync).

## 1. 결론 먼저

앱은 "오프라인 시 로컬데이터 표기 + 나중 동기화"를 **의도**하지만, 현재는 **opt-in**이라 48개 repository 호출 중 **5개 도메인만** 폴백하고 **나머지는 remote 직결로 오프라인 시 fail-closed**(ApiException/무한로딩)된다. 해결 = 오프라인 저하(degradation)를 **factory 경계의 기본값**으로 만들고, 48 call-site를 도메인별로 마이그레이션한다. 단, "제네릭 캐시 데코레이터" 방식에는 Dart 리플렉션 부재로 인한 설계 분기가 있어(아래 3절) **방식 선택이 선행 결정**이다.

## 2. 현황 (정확한 측정)

### 2.1 오프라인 스택은 이미 존재 (opt-in)

`core/sync/`: `connectivity_service` · `mutation_queue_helper` · `sync_service` · `sync_adapter_registry` · `initial_pull_service` · `offline_banner`.

### 2.2 3개 factory (`core/providers/repository_provider.dart`)

| factory | 동작 | 사용 |
|---|---|---|
| `createRepository` | mock \| remote(apiClient) — **캐시·연결체크 없음** | **48 파일** |
| `createSyncAwareRepository` | mock \| syncAware(apiClient, queue) — read 캐시폴백 + write 큐 | 5 도메인 |
| `createLocalFallbackRepository` | mock \| fallback() — **빈 스텁**(실데이터 없음) | 6 곳 |

`createRepository`의 remote 경로는 네트워크 실패 시 RemoteRepository가 NetworkException/ApiException을 던지고, FutureProvider/AsyncNotifier가 error/loading에 빠져 **서버오류 또는 무한 스피너**로 표면화된다.

### 2.3 폴백 채택 도메인 (degrade O)

`createSyncAwareRepository`: lessons · students · subscription · practice · schedule (5).
손코딩 `*CacheStore`: lessons · students · subscription · schedule (4).

### 2.4 기존 데코레이터 패턴 (`SyncAwareLessonRepository`)

- 도메인 인터페이스(`LessonRepository`)를 **손으로 구현**.
- READ: `_readListWithCache(key, fetch)` — 성공 시 캐시, 네트워크 실패 시 캐시 last-known-good 반환, 미스면 rethrow.
- WRITE: `MutationQueueHelper.executeMutation(remoteCall, queueCall, optimisticResult)` — 온라인 즉시 / 오프라인 큐 + 낙관적 결과.
- `_isNetworkFailure` = NetworkException | ServerException | 5xx.

**채택이 5개에 머문 이유**: 도메인마다 (1) 전체 인터페이스를 구현한 SyncAware 데코레이터 + (2) 타입별 put/get/key를 가진 CacheStore를 **둘 다 손코딩**해야 한다. 보일러플레이트가 크다.

### 2.5 48 call-site 도메인 분포

practice 7 · subscription 5 · lessons 5 · students 4 · schedule 4 · academy 4 · settings 2 · search 2 · parent_home 2 · follow 2 · auth 2 · (각 1) student_home · share · relationship · profile · onboarding · gamification · billing · analytics · core:providers.

> 주의: academy(4)는 **읽기 전용 표시 + web console 소관**(CLAUDE.md HARD-GATE). 캐시는 적용하되 쓰기 큐는 불요. billing/payment(#879)는 서버 권위 — 읽기 캐시만, 표시 전용.

## 3. 기반 설계 — 핵심 분기 (선행 결정)

Dart는 런타임 리플렉션이 없어 **임의 인터페이스 T를 자동 래핑하는 제네릭 데코레이터**를 만들 수 없다. 따라서 "read 캐시폴백을 어디에 둘지"가 갈린다.

### 옵션 A — HTTP 레이어 응답 캐시 인터셉터 (권장)

네트워크 계층(Dio interceptor)에 **GET 응답 캐시**를 둔다. 키=URL(+쿼리), 값=원시 JSON. GET 네트워크 실패 시 캐시된 응답을 반환 → **모든 remote 리포지토리가 도메인 코드 변경 0으로 오프라인 읽기를 획득**.

- 장점: 48 도메인을 **한 번에** 커버. 도메인별 데코레이터/CacheStore 불요. 직렬화는 이미 HTTP JSON.
- 단점: 캐시 단위가 "엔드포인트 응답"(엔티티 단위 무효화 어려움). 쓰기 후 관련 캐시 무효화는 도메인 매핑 필요(태그/경로 prefix 무효화로 완화).
- 쓰기(오프라인 mutation 큐)는 별도 — `MutationQueueHelper` 유지(낙관적 UI는 도메인 형태 필요).

### 옵션 B — 제네릭 `JsonCacheStore<E>` + 도메인별 데코레이터

엔티티 JSON(`*.g.dart`) 기반 제네릭 캐시 스토어를 제공해 **손코딩 CacheStore를 제거**하되, 인터페이스 구현 데코레이터는 도메인별 유지.

- 장점: 캐시가 엔티티 단위(정밀 무효화). 기존 SyncAware 패턴과 동형.
- 단점: 도메인마다 데코레이터(인터페이스 구현)는 여전히 손코딩 → 보일러플레이트 절반만 감소.

### 옵션 C — 현행 유지(도메인별 데코레이터+스토어 둘 다 손코딩)

- 장점: 최대 정밀도. 단점: 48 도메인 × 2 파일 = 과도한 작업/유지비.

> **권장**: **옵션 A(HTTP 응답 캐시) + 쓰기는 MutationQueueHelper 유지**. 읽기 저하를 전 도메인에 즉시 부여하고, 쓰기 낙관성은 트래픽 높은 도메인부터 점진. 정밀 무효화가 필요한 소수 도메인만 옵션 B로 보강.

## 4. 결정 필요 항목 (Lore 후보)

| # | 결정 | 기본 제안 |
|---|---|---|
| D1 | 읽기 캐시 위치 | 옵션 A(HTTP 인터셉터) |
| D2 | staleness 정책 | 오프라인 중 stale 무기한 제공 + "마지막 동기화 HH:MM" 배너. 온라인 복귀 시 재검증 |
| D3 | TTL | 표시 전용 도메인 무TTL(연결 복귀 시 갱신). 민감(billing) 짧은 TTL + 항상 서버 우선 |
| D4 | 쓰기 충돌 | 기본 last-write-wins + 서버 거절 시 SnackBar 노출. 결제/정산은 큐잉 금지(서버 권위) |
| D5 | 낙관적 쓰기 범위 | 읽기 캐시는 전 도메인 / 낙관적 쓰기는 lessons·schedule·subscription·students 우선, 나머지는 온라인 전용 유지 |
| D6 | academy/billing | 읽기 캐시만(표시). 쓰기 큐 제외 |

## 5. 롤아웃 (도메인 배치, 읽기-핵심 우선)

| 배치 | 도메인 | 비고 |
|---|---|---|
| 0 (기반) | `core/providers` + 인터셉터/캐시 | 단일 PR, 코드 전 D1~D6 확정 |
| 1 | schedule · lessons · subscription · students | 이미 SyncAware 4 — 인터셉터로 일원화 + 회귀 |
| 2 | parent_home · student_home · practice · gamification | 읽기 많은 사용자 화면 |
| 3 | profile · settings · search · follow · relationship · onboarding · auth | 표시/조회 |
| 4 | academy · billing · analytics · share | 읽기 캐시만(쓰기 제외) |

각 배치는 별도 worktree/PR. 배치 간 회귀 격리.

## 6. 검증 (도메인별 필수)

- **오프라인 스모크**: 연결 끊김 상태에서 화면 진입 → 로컬/빈상태 표시, 크래시·무한로딩 0. (실라우터 + 2뷰포트, [[feedback-smoke-test-false-green]] 회피)
- **연결 복귀**: 큐된 mutation 재생 + 캐시 재검증.
- **아키텍처 테스트**: `flutter test test/architecture` 회귀 0 ([[feedback-run-architecture-tests]]).
- **쓰기 충돌**: 큐 재생 시 서버 거절 표면화 테스트.

## 7. 리스크

| 리스크 | 완화 |
|---|---|
| stale 캐시 정합성 | staleness 배너 + 연결 복귀 재검증. 민감 도메인 TTL/서버우선 |
| 쓰기 큐 순서/충돌 | 도메인 단위 순서 보장, LWW + 거절 노출. 결제 큐 제외 |
| Hive 증가 | 응답 캐시 LRU/상한, 사용자 scoped 키 |
| 낙관적-서버 발산 | 낙관 범위를 4개 핵심 도메인으로 제한, 나머지 읽기 캐시만 |
| 대규모 blast radius(48) | 배치별 PR + 도메인 오프라인 스모크, 인터셉터는 점진 enable 플래그 |

## 8. 비범위 / 의존

- delta(증분) sync(#880)는 후속 — 본 계획은 full-pull + 응답 캐시 전제.
- practice_journal remote/sync(#872)는 BE 배포 선행 — 그 전까지 `createLocalFallbackRepository` 유지.
- academy 입력 UI는 web console 소관 — Flutter는 읽기 캐시만.

## 9. 다음 액션

1. D1~D6 결정 확정(특히 D1 옵션 A 채택 여부).
2. 배치 0(기반) PR — 인터셉터 + 응답 캐시 + factory 기본값화 + enable 플래그.
3. 배치 1부터 도메인 마이그레이션 + 오프라인 스모크.
