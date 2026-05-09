# Interview — R6 Trust Building (버전 체크 + 리뷰 프롬프트 + 새 소식/로드맵)

> 날짜: 2026-05-10
> 요청자: cglee
> 소스 스펙: 옵시디언 `12-R6-신뢰구축-상세스펙.md`

## 원 요청

"방치 앱" 인식 리스크 대응 — 3곳에 "활발한 개발" 시그널 배치:
1. 버전 체크 + 업데이트 배너
2. 스마트 리뷰 프롬프트
3. 새 소식 + 로드맵 화면

## 목적과 배경

- **왜 지금**: 앱 스토어 출시 후 사용자가 "또 방치 앱" 으로 인식하면 이탈. 활발한 개발 시그널이 신뢰 구축의 핵심.
- **성공 기준**:
  - 앱 버전 < 최신 → 홈 상단 배너 노출
  - 앱 버전 < 최소 → 강제 업데이트 화면 차단
  - 레슨 완료 조건 충족 시 리뷰 프롬프트 노출
  - 프로필 메뉴에서 새 소식/로드맵 접근 가능

## 기능 범위

### 반드시 포함
- 백엔드 `GET /api/v1/app/version` 엔드포인트 (latest, min, news, roadmap 반환)
- 버전 비교 + 1시간 캐시 (SharedPreferences)
- 업데이트 배너 (홈 상단, dismiss 가능)
- 강제 업데이트 화면 (current < min 시 홈 차단)
- 리뷰 프롬프트 (조건: 설치 7일+, 마지막 프롬프트 90일+, 선생님 레슨 5회+ / 학생 연습 3회+)
- 새 소식 화면 (변경 로그 리스트)
- 로드맵 화면 (planned / inProgress / shipped 상태)
- 프로필 메뉴 통합 ("새 소식", "개발 로드맵" 항목)

### 명시적 제외
- 자동 업데이트 (스토어 리디렉트만)
- Push 알림으로 버전 강제
- 사용자 투표 기반 로드맵 우선순위

## 현재 구현 상태 (코드 갭 분석)

### ✅ 이미 구현됨

| 항목 | 파일 | 상태 |
|------|------|------|
| 엔티티: AppVersionSnapshot, AppNewsItem, AppRoadmapItem | `settings/domain/entities/app_release.dart` | 완료 |
| 엔티티: ReviewPromptPolicy, AppReviewState | `settings/domain/entities/` | 완료 |
| 리뷰 트리거 서비스 | `settings/domain/services/app_review_trigger_service.dart` | 완료 |
| 리뷰 상태 저장소 (Hive) | `settings/data/repositories/hive_app_review_state_repository.dart` | 완료 |
| 리뷰 클라이언트 (in_app_review) | `settings/data/repositories/local_app_review_client.dart` | 완료 |
| Remote 릴리즈 리포지토리 | `settings/data/repositories/remote_app_release_repository.dart` | 완료 |
| Local 릴리즈 리포지토리 (Mock) | `settings/data/repositories/local_app_release_repository.dart` | 완료 (하드코딩 데이터) |
| 새 소식/로드맵 화면 | `settings/presentation/screens/news_roadmap_screen.dart` | 완료 |
| 업데이트 배너 위젯 | `home/presentation/widgets/app_update_banner.dart` | 완료 |
| 라우트 등록 | `core/router/routes/settings_routes.dart` | 완료 |
| AppStrings | `core/l10n/app_strings.dart` | 완료 |
| 패키지 | `in_app_review`, `package_info_plus` | pubspec.yaml 등록됨 |

### ❌ 미구현 (남은 갭)

| 항목 | 설명 |
|------|------|
| **백엔드 API** | `GET /api/v1/app/version` 엔드포인트 없음 |
| **버전 캐시** | SharedPreferences 1시간 캐시 미구현 (매번 API 호출) |
| **강제 업데이트 화면** | `ForceUpdateScreen` 미구현 (current < min 시 홈 차단) |
| **프로필 메뉴 통합** | "새 소식", "개발 로드맵" 메뉴 항목 미추가 |
| **업데이트 배너 위치** | 현재 login_screen에만 배치, 홈 dashboard_tab에 미배치 |
| **리뷰 프롬프트 UI** | 트리거 서비스는 있으나 실제 다이얼로그 UI 미구현 |
| **리뷰 프롬프트 호출 지점** | 레슨 완료 / 스트릭 달성 시 트리거 연결 미구현 |

## 사용자 / 행위자

| 행위자 | 행동 |
|--------|------|
| 선생님 | 업데이트 배너 확인, 리뷰 작성, 새 소식/로드맵 열람 |
| 학생 | 업데이트 배너 확인, 리뷰 작성, 새 소식/로드맵 열람 |
| 관리자 (백엔드) | 버전 정보, 새 소식, 로드맵 데이터 관리 |

## 데이터 / 스키마

### 새 엔티티 (백엔드)
- `app_versions` 테이블: latest_version, min_version, release_notes, published_at
- `app_news` 테이블: id, title, summary, published_at, link
- `app_roadmap` 테이블: id, title, summary, status (planned/inProgress/shipped), target_date

### 기존 스키마 변경
- 없음

## 도메인 용어 (Ubiquitous Language)

| 용어 | 영문 | 설명 |
|------|------|------|
| 앱 버전 스냅샷 | AppVersionSnapshot | 현재/최신/빌드 버전 정보 |
| 새 소식 | AppNewsItem | 변경 로그 항목 |
| 로드맵 항목 | AppRoadmapItem | 개발 예정/진행중/완료 기능 |
| 릴리즈 스냅샷 | AppReleaseSnapshot | 버전 + 뉴스 + 로드맵 통합 |
| 리뷰 프롬프트 | ReviewPrompt | 앱 스토어 리뷰 요청 대화상자 |
| 리뷰 상태 | AppReviewState | 프롬프트 이력 (Hive 저장) |
| 강제 업데이트 | ForceUpdate | min 버전 미만 시 홈 차단 |

## 통합 포인트

- **외부 API**: Apple App Store (SKStoreReviewController via in_app_review)
- **내부 서비스**: 레슨 완료 이벤트 → 리뷰 트리거, 게이미피케이션 스트릭 → 리뷰 트리거

## 제약 조건

- **성능**: 버전 체크 1시간 캐시 (API 과부하 방지)
- **보안**: min_version 강제는 서버 사이드에서 결정 (클라이언트 조작 방지)
- **iOS**: SKStoreReviewController는 연간 3회 제한 (OS 레벨), 추가 제한 불필요
- **기존 아키텍처**: settings feature 모듈에 이미 구조 배치됨

## 비기능 요구사항

- **가용성**: 버전 API 실패 시 graceful degradation (배너 미노출, 앱 정상 작동)
- **관측성**: 리뷰 프롬프트 노출/응답 로그 (향후 분석용)

## 해결되지 않은 질문

- [x] 새 소식/로드맵 데이터 소스: 백엔드 DB vs 하드코딩 → **백엔드 API** (스펙 확정)
- [x] 리뷰 프롬프트 조건: 선생님 레슨 5회 / 학생 연습 3회 → **코드에 이미 구현됨**
- [ ] ~~백엔드 데이터 관리 UI (어드민 대시보드) 필요 여부~~ → Phase 1 범위 외, 초기에는 시드 데이터 또는 직접 DB로 관리

## Ambiguity Score

```
Ambiguity Score: 0.10 / 1.0 [PASS]
  Specificity:   0.10 (API 스펙, 엔티티, 조건 수치 모두 명시)
  Measurability: 0.10 (버전 비교 로직, 리뷰 조건, 캐시 TTL 측정 가능)
  Unresolved:    0.05 (남은 질문 0개, 어드민 UI는 범위 외)

📍 Phase 2 (cg-spec-and-harness) 진행 가능
```
