# 선생님/학원 검색 마스터 스펙

> 구현 상태: ⚠️ 부분 구현 — 선생님/학원 검색·상세는 구현, Academy 개념·areas는 BE 미연동(Mock만), 통합 검색(SearchScope) 미구현 예약
> Last updated: 2026-06-03 신설(코드 역공학)
> 관련 코드: `features/search/`

---

## 1. 개요

학생이 선생님 또는 학원(academy)을 찾아 공개 프로필을 열람하고 레슨을 요청하기까지의 검색 서브시스템. 키워드·악기·지역·레슨 유형·경력·자격증·완성도 필터와 정렬을 제공하며, "학원" 탭과 "개인 강사" 탭으로 나뉜다.

검색 도메인은 도메인 엔티티 대부분을 `profile/` 도메인에서 재export하여 사용한다(`TeacherProfile`, `TeacherPublicProfile`, `TeacherSearchFilter` 등). search 도메인 고유 엔티티는 `AcademyInfo`와 (예약된) `SearchHistoryEntry`다.

비유: 부동산 앱에서 매물을 지역·가격·옵션으로 거르고 상세 페이지를 여는 흐름과 동일하다. 여기서 "매물"은 선생님/학원, "옵션"은 악기·레슨 유형·자격증이다.

---

## 2. 핵심 기능

### 2.1 검색 탭 (학원 / 개인 강사)

| 항목 | 설명 |
|------|------|
| 탭 구분 | `TeacherSearchType.academy`(학원) / `TeacherSearchType.individual`(개인) 2탭. 기본 탭 = academy |
| 판별 기준 | `organizationId != null` → 학원 소속(`isAcademy`), `null` → 개인 강사(`isIndividual`) |
| 탭 ↔ 필터 연동 | 탭 선택값이 `TeacherSearchFilter.teacherType`로 주입됨. `isEmpty` 판정에는 `teacherType` 제외(탭이 제어하므로) |

### 2.2 필터

`TeacherSearchFilter` 기준. 필터 시트(`TeacherSearchFilterSheet`)에서 조작.

| 필터 | 필드 | 비고 |
|------|------|------|
| 키워드 | `keyword` | 이름/소개 등 텍스트 검색 |
| 악기 | `instruments` (List) | Remote는 첫 항목만 BE 전달(`instrument`) |
| 지역 | `areas` (List) | Remote는 첫 항목만 BE 전달(`area`). BE areas 미보유 → 빈 목록 |
| 레슨 유형 | `lessonTypes` (List<LessonTypeOption>) | inPerson / online / visit |
| 레슨료 범위 | `minFee` / `maxFee` | |
| 최소 경력 | `minExperience` | 클라이언트 측 필터 |
| 자격증 인증 | `hasVerifiedCertificate` | 클라이언트 측 필터 |
| 최소 완성도 | `minCompletionLevel` (ProfileCompletionLevel) | |
| 강사 유형 | `teacherType` (TeacherSearchType) | 탭이 제어, 시트 미노출 |

`clearKeyword()`는 keyword만 비우고 나머지 보존, `clearFilter()`는 탭(teacherType)만 유지하고 초기화.

### 2.3 정렬

`TeacherSortOption`: `relevance`(기본), `experienceDesc`, `experienceAsc`, `feeAsc`, `feeDesc`, `rating`, `completionLevel`. (`rating`/`relevance`는 Remote에서 별도 정렬 미적용.)

### 2.4 페이지네이션

`searchTeachers(page, pageSize=20)`. `TeacherSearchResult.hasMore` 기준 무한 스크롤(`loadMore`). Remote는 1-based 페이지(`page + 1`)로 변환하여 BE 호출.

### 2.5 공개 프로필 / 전체 프로필

| 메서드 | 용도 |
|------|------|
| `getTeacherPublicProfile` | 가시성 설정 반영된 공개 프로필(`TeacherPublicProfile.fromProfile`) |
| `getTeacherFullProfile` | 연결된 학생용 전체 프로필(계좌 등 포함, `TeacherProfile`) |

공개 프로필은 `ProfileVisibilitySettings`에 따라 name/photo/fee/career/certificate 필드를 선택적으로 노출(`ProfileVisibility.public`일 때만).

### 2.6 학원(Academy) — BE 대기

`AcademyInfo` 및 `getAcademyInfo` / `getTeachersByOrganization` / `getAllAcademies`는 Mock만 구현. Remote 구현은 "Academy concept not in backend yet" 주석과 함께 `null`/빈 목록 반환 → **BE 대기**.

### 2.7 통합 검색(SearchScope) — 미구현 예약

`SearchScope`(all/teachers/students/lessons), `SearchResultType`(teacher/student/lesson/practice), `SearchHistoryEntry`는 검색 히스토리/통합 검색용으로 **정의만 존재**(`// ignore: unused-enum`). 검색 UI 미구현 — 통합 검색/히스토리 구현 시 활용 예정.

---

## 3. 데이터 모델

### 3.1 search 도메인 고유

#### AcademyInfo
> 소스: `search/domain/repositories/teacher_search_repository.dart`

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | String | 학원(조직) ID |
| `name` | String | 학원명 |
| `address` | String? | 주소 |
| `phone` | String? | 전화 |
| `instruments` | List<String> | 취급 악기 |
| `teacherCount` | int | 소속 선생님 수 |

#### SearchHistoryEntry (예약)
> 소스: `search/domain/entities/search_filter.dart`

| 필드 | 타입 | 설명 |
|------|------|------|
| `query` | String | 검색어 |
| `scope` | SearchScope | 검색 범위 |
| `searchedAt` | DateTime | 검색 시각 |

### 3.2 enum

| enum | 값 | 출처 | 상태 |
|------|------|------|------|
| `TeacherSearchType` | academy, individual | profile/teacher_search.dart | 사용 중 |
| `TeacherSortOption` | relevance, experienceDesc, experienceAsc, feeAsc, feeDesc, rating, completionLevel | profile/teacher_search.dart | 사용 중 |
| `SearchScope` | all, teachers, students, lessons | search/search_filter.dart | 예약(미사용) |
| `SearchResultType` | teacher, student, lesson, practice | search/search_filter.dart | 예약(미사용) |

> 참조 enum(profile 도메인): `LessonTypeOption`(inPerson/online/visit, alias `LessonType`), `ProfileCompletionLevel`(minimum/basic/standard/complete), `ProfileVisibility`(public/students/private), `VerificationBadge`.

### 3.3 profile 도메인에서 재export하는 엔티티

`search/domain/entities/entities.dart`가 재export:

| 엔티티 | 핵심 필드 | 출처 |
|------|------|------|
| `TeacherSearchFilter` | keyword, instruments, areas, lessonTypes, minFee, maxFee, minExperience, hasVerifiedCertificate, minCompletionLevel, teacherType | profile/teacher_search.dart |
| `TeacherSearchResult` | teachers(List<TeacherProfile>), totalCount, page, pageSize, hasMore | profile/teacher_search.dart |
| `TeacherPublicProfile` | id, name, profileImage, organizationId/Name, instruments, introduction, experienceYears, feeRange, lessonAreas, lessonTypes, education, career, verifiedCertificates, badges, completionLevel, publicPageConsent. getter: `isAcademy`, `isIndividual` | profile/teacher_search.dart |
| `TeacherProfile` | (전체 선생님 프로필) | profile/teacher_profile.dart |

> `TeacherPublicProfile.fromProfile(profile, {publicPageConsent})`: 가시성 설정에 따라 공개 필드를 마스킹하여 생성.

---

## 4. Repository 계약

### 4.1 TeacherSearchRepository
> 소스: `search/domain/repositories/teacher_search_repository.dart`
> 구현: `MockTeacherSearchRepository`(mock), `RemoteTeacherSearchRepository`(api, `GET /teachers`, `GET /teachers/{id}`)

| 메서드 | 반환 | Remote 비고 |
|------|------|------|
| `searchTeachers({filter, sort, page, pageSize})` | `TeacherSearchResult` | BE는 q/instrument/area + 페이지만 지원. teacherType/minExperience/hasVerifiedCertificate 및 정렬은 클라이언트 측 적용 |
| `getTeacherPublicProfile(id)` | `TeacherPublicProfile?` | `GET /teachers/{id}` |
| `getTeacherFullProfile(id)` | `TeacherProfile?` | `GET /teachers/{id}` |
| `getFeaturedTeachers({limit})` | `List<TeacherPublicProfile>` | 전용 엔드포인트 없음 → 기본 목록 take(limit) |
| `getAvailableInstruments()` | `List<String>` | 선생님 목록에서 파생 |
| `getAvailableAreas()` | `List<String>` | **BE 대기** — BE areas 미보유, 빈 목록 |
| `getAcademyInfo(orgId)` | `AcademyInfo?` | **BE 대기** — null |
| `getTeachersByOrganization(orgId)` | `List<TeacherPublicProfile>` | **BE 대기** — 빈 목록 |
| `getAllAcademies()` | `List<AcademyInfo>` | **BE 대기** — 빈 목록 |

### 4.2 TeacherRepository (검색 보조)
> 소스: `profile/domain/repositories/teacher_repository.dart` (인터페이스)
> 구현: `MockTeacherRepository`(profile), `RemoteTeacherRepository`(search/data) — `GET /teachers`, `GET /teachers/{id}`

| 메서드 | 반환 |
|------|------|
| `getAllTeachers()` | `List<Teacher>` |
| `getTeacherById(id)` | `Teacher?` |
| `searchTeachers(TeacherFilter)` | `List<Teacher>` (instrument/area BE, onlyAvailable/maxTrialFee/minRating 클라이언트) |
| `getTeachersByInstrument(instrument)` | `List<Teacher>` |
| `getFeaturedTeachers()` | `List<Teacher>` (전용 엔드포인트 없음 → take(5)) |

---

## 5. Provider

### 5.1 teacher_search_provider.dart

| Provider | 타입/반환 | 용도 |
|----------|----------|------|
| `teacherSearchRepositoryProvider` | TeacherSearchRepository (keepAlive) | Mock/Remote 전환 |
| `TeacherSearchTabState` | TeacherSearchType (Notifier) | 학원/개인 탭, `setTab` |
| `TeacherSearchFilterState` | TeacherSearchFilter (Notifier) | 탭 watch → teacherType 주입, updateKeyword/Instruments/Areas/LessonTypes/FeeRange/MinExperience/HasVerifiedCertificate, clearFilter/clearKeyword |
| `TeacherSearchSortState` | TeacherSortOption (Notifier) | `updateSort` |
| `TeacherSearchResults` | Future<TeacherSearchResult> (AsyncNotifier) | filter+sort watch, `loadMore`/`refresh` |
| `teacherPublicProfileProvider(id)` | Future<TeacherPublicProfile?> | |
| `teacherFullProfileProvider(id)` | Future<TeacherProfile?> | |
| `featuredTeachersProvider` | Future<List<TeacherPublicProfile>> | limit 5 |
| `availableInstrumentsProvider` | Future<List<String>> | |
| `availableAreasProvider` | Future<List<String>> | |
| `academyInfoProvider(orgId)` | Future<AcademyInfo?> | |
| `academyTeachersProvider(orgId)` | Future<List<TeacherPublicProfile>> | |
| `allAcademiesProvider` | Future<List<AcademyInfo>> | |

### 5.2 teacher_providers.dart (Teacher 엔티티 기반)

| Provider | 반환 | 용도 |
|----------|------|------|
| `teacherRepositoryProvider` | TeacherRepository (keepAlive) | Mock/Remote 전환 |
| `allTeachersProvider` | Future<List<Teacher>> | 전체 선생님 |
| `teacherProvider(id)` | Future<Teacher?> | 단일 선생님 |
| `featuredTeachersProvider` | Future<List<Teacher>> | (teacher_providers 버전) |
| `teachersByInstrumentProvider(instrument)` | Future<List<Teacher>> | |
| `filteredTeachersProvider(filter)` | Future<List<Teacher>> | |
| `SelectedInstrumentFilter` | String? | UI 상태 |
| `TeacherSearchQuery` | String | UI 상태 |
| `availableTeachersProvider` | Future<List<Teacher>> | 악기+검색어 적용 |

### 5.3 Facade
> 소스: `search/search_facade.dart`

export: `teacherProvider`, `academyInfoProvider`, `academyTeachersProvider`, `availableAreasProvider`, `availableInstrumentsProvider`, `teacherFullProfileProvider`, `teacherPublicProfileProvider`, `teacherSearchFilterStateProvider`, `teacherSearchResultsProvider`, `teacherSearchSortStateProvider`, `teacherSearchTabStateProvider`.

---

## 6. 화면 / 라우트

### 6.1 라우트
> 소스: `core/router/routes/search_routes.dart`, `core/router/app_routes.dart`, `core/router/routes/schedule_routes.dart`

| 라우트 상수 | 경로 | name | 화면 |
|------|------|------|------|
| `AppRoutes.teacherSearch` | `/search/teachers` | teacherSearch | `TeacherSearchScreen` |
| `AppRoutes.teacherDetail` | `/teachers/:id` | teacherDetail | `TeacherDetailScreen(teacherId)` |
| `AppRoutes.academyDetail` | `/academies/:id` | academyDetail | `AcademyDetailScreen(organizationId)` |
| `AppRoutes.selectTeacher` | (schedule_routes) | selectTeacher | `TeacherSearchScreen` (학생 시작 카드에서 재사용) |

### 6.2 화면

| 화면 | 파일 | 설명 |
|------|------|------|
| `TeacherSearchScreen` | screens/teacher_search_screen.dart | 학원/개인 2탭 + 검색바 + 필터 시트 + 무한 스크롤 결과 |
| `TeacherDetailScreen` | screens/teacher_detail_screen.dart | 선생님 공개 프로필 상세 |
| `AcademyDetailScreen` | screens/academy_detail_screen.dart | 학원 정보 + 소속 선생님 목록 |

### 6.3 위젯

| 위젯 | 파일 |
|------|------|
| `TeacherSearchCard` | widgets/teacher_search_card.dart |
| `TeacherSearchFilterSheet` | widgets/teacher_search_filter_sheet.dart |

---

## 7. 구현 파일 위치

> `features/search/` 기준 상대 경로. 새 파일 추가 시 이 표를 업데이트한다.

| 레이어 | 파일 |
|--------|------|
| Entity | `domain/entities/search_filter.dart` (SearchScope, SearchResultType, SearchHistoryEntry) |
| Entity barrel | `domain/entities/entities.dart` (profile 도메인 재export) |
| Repository 인터페이스 | `domain/repositories/teacher_search_repository.dart` (TeacherSearchRepository, AcademyInfo) |
| Repository 구현 | `data/repositories/{mock_teacher_search,remote_teacher_search,remote_teacher}_repository.dart` |
| Provider | `presentation/providers/{teacher_search_provider,teacher_providers}.dart` (+ `.g.dart`) |
| Screen | `presentation/screens/{teacher_search,teacher_detail,academy_detail}_screen.dart` |
| Widget | `presentation/widgets/{teacher_search_card,teacher_search_filter_sheet}.dart` |
| Facade | `search_facade.dart` |
| Route | `core/router/routes/search_routes.dart` |

---

## 8. 관련 스펙

| 스펙 | 관계 |
|------|------|
| [프로필 마스터](../profile/profile_master.md) | TeacherProfile/TeacherPublicProfile/가시성 설정 SSOT |
| [관계 마스터](../relationship/relationship_master.md) | 검색 → 레슨 요청 → 관계 생성 |
| [수강권 마스터](../subscription/subscription_master.md) | 레슨 요청/수강권 발급 연계 |

---

## 9. 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-06-03 | 코드 역공학으로 마스터 스펙 신설 |
