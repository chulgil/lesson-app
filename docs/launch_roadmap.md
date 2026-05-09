# 출시 로드맵: iOS App Store 런칭

> 작성일: 2026-03-02 (갱신: 2026-03-12)
> 상태: 계획 (Phase 1 대부분 완료)
> 목표: iOS App Store 우선 출시 → Android Google Play 후속

---

## 1. 현재 상태 요약

### 완성 기능 (Frontend Phase 1 - 100% 완료)

| 영역 | 주요 기능 | 상태 |
|------|----------|:----:|
| 인증 | Google/Kakao 로그인 UI, 역할 선택 (선생님/학생) | ✅ |
| 선생님 | 대시보드, 학생 CRUD, 레슨 캘린더(월/주), 레슨 노트/녹음, 수강료 관리 | ✅ |
| 학생 | 대시보드, 레슨 일정, 피드백, 연습 스트릭, 레퍼토리 관리 | ✅ |
| 학부모 | 이중 역할 전환, 프로필 스위처, 미연결 자녀 대시보드 | ✅ |
| 초대/연결 | 양방향 초대 (QR/URL/코드), 승인/거절 워크플로우 | ✅ |
| 스케줄 | 체험/정규 레슨 신청, 다중 옵션 제안, 승인 대기 목록 | ✅ |
| 연습 | 레퍼토리 연동, 다중 구간, 좋아요, 알림 | ✅ |
| 메트로놈 | 커스텀 네이티브 엔진, 고양이 인디케이터, 사운드 템플릿 | ✅ |
| 녹음 | 파형, A-B 루프, 속도 조절, 핀치 줌, 스마트 트리밍, 대표녹음 | ✅ |
| 튜너 | 피치 감지, 원형 12음계, 고양이 피드백, 콤보, 설정 저장 | ✅ |

### 미완성 항목

| 항목 | 현재 상태 | 필요 작업 |
|------|----------|----------|
| 백엔드 API | 미착수 | FastAPI + Supabase 구축 |
| OAuth 인증 | UI만 완료 | Google/Kakao OAuth 실제 연동 |
| 푸시 알림 (FCM) | 미착수 | Firebase Cloud Messaging 연동 |
| 뱃지 시스템 | ✅ 완료 | Phase 1 게이미피케이션으로 구현 (#98) |
| 테스트 | 미착수 | 단위/통합/E2E 테스트 |
| 앱스토어 배포 | 미착수 | Apple Developer, 스크린샷, 심사 준비 |

### 열린 이슈

| 이슈 | 내용 | 우선순위 |
|------|------|:--------:|
| [#7](https://github.com/chulgil/lesson-app/issues/7) | 스마트 녹음 트림 후 실제 재생 시간 표시 | ✅ |
| [#8](https://github.com/chulgil/lesson-app/issues/8) | 연습완료 날짜별 완료 상태 동기화 | 🟠 High |

---

## 2. MVP 범위 (v1.0)

### v1.0에 포함

| 기능 | 설명 |
|------|------|
| 1:1 레슨 관리 | 선생님-학생 레슨 예약, 캘린더, 노트 |
| 연습 추적 | 레퍼토리/섹션 관리, 연습 기록, 스트릭 |
| 오디오 도구 | 메트로놈, 튜너, 녹음/재생 |
| 학부모 연동 | 프로필 스위처, 자녀 연습 모니터링 |
| 백엔드 API | FastAPI + Supabase (데이터 동기화, 사용자 관리) |
| 인증 | Google/Kakao OAuth (실제 로그인) |
| 푸시 알림 | FCM (레슨 리마인더, 연습 알림) |

### v1.1 이후로 연기

| 기능 | 이유 |
|------|------|
| 뱃지 시스템 | MVP 핵심 기능이 아님 |
| 학원 모드 (LessonClass, 수강권) | 1:1 개인 레슨 우선, 학원 지원은 후속 |
| 통계/리포트 | 데이터 축적 후 의미 있음 |
| 다국어 지원 | 한국 시장 우선 공략 |
| 웹 버전 | 모바일 앱 안정화 우선 |

> **참고**: 학원/수강권/3자 관계 시스템의 구현 계획은 [implementation_roadmap.md](specs/dev/implementation_roadmap.md) 참조

---

## 3. Phase별 로드맵

### Phase 1: MVP 마무리 (이슈 해결 + UI 폴리시)

> 목표: 현재 열린 이슈 해결 + 출시 전 UI/UX 다듬기
> 상태: ⚠️ 대부분 완료 — UX 점검 10회(#104~#142), 게이미피케이션/분석/과제 대시보드 구현 완료

| 작업 | 상세 | 체크 |
|------|------|:----:|
| Issue #7 해결 | 스마트 녹음 트림 후 실제 재생 시간 표시 | ✅ |
| Issue #8 해결 | 연습완료 날짜별 완료 상태 동기화 | ⬜ |
| UI 폴리시 | 로딩 상태, 에러 처리, 빈 상태 화면 점검 | ✅ (UX 점검 10회) |
| 게이미피케이션 | 포인트/레벨/뱃지 시스템 구현 | ✅ (#98) |
| 분석 대시보드 | 월별 통계/차트/연습률 랭킹 | ✅ (#97) |
| 과제 대시보드 | 전체 학생 주간 과제 현황 | ✅ (#101) |
| 오프라인 모드 검증 | Hive 로컬 데이터만으로 핵심 기능 동작 확인 | ⬜ |
| 앱 아이콘 | 최종 앱 아이콘 제작 및 적용 | ⬜ |
| 스플래시 화면 | 브랜딩 스플래시 화면 적용 | ⬜ |

### Phase 2: 백엔드 API 구축 (FastAPI + Supabase)

> 목표: 데이터 동기화를 위한 서버 API 구축

| 작업 | 상세 | 체크 |
|------|------|:----:|
| Supabase 프로젝트 생성 | PostgreSQL DB, Auth, Storage 설정 | ⬜ |
| FastAPI 프로젝트 셋업 | `backend/` 디렉토리 구조, uv 패키지 관리 | ⬜ |
| 사용자 API | 회원가입, 프로필 관리, 역할 관리 | ⬜ |
| 학생 API | 학생 CRUD, 선생님-학생 관계 | ⬜ |
| 레슨 API | 레슨 CRUD, 캘린더 조회 | ⬜ |
| 연습 API | 레퍼토리, 섹션, 연습 기록 | ⬜ |
| 녹음 API | 녹음 파일 업로드/다운로드 (Supabase Storage) | ⬜ |
| 초대 API | 초대 코드 생성, 수락/거절 | ⬜ |
| Flutter 연동 | Hive → Supabase 동기화 레이어 구현 | ⬜ |

### Phase 3: 인증 연동 (Google/Kakao OAuth)

> 목표: 실제 소셜 로그인 연동

| 작업 | 상세 | 체크 |
|------|------|:----:|
| Supabase Auth 설정 | Google/Kakao OAuth Provider 등록 | ⬜ |
| Google OAuth | Google Cloud Console 설정, iOS 번들 등록 | ⬜ |
| Kakao OAuth | Kakao Developers 앱 등록, 네이티브 키 설정 | ⬜ |
| Flutter 인증 플로우 | 로그인 → 토큰 저장 → 자동 갱신 | ⬜ |
| 역할 온보딩 | 첫 로그인 시 선생님/학생 역할 선택 연동 | ⬜ |
| 로그아웃/탈퇴 | 계정 탈퇴, 데이터 삭제 처리 | ⬜ |

### Phase 4: 푸시 알림 (FCM)

> 목표: Firebase Cloud Messaging 연동

| 작업 | 상세 | 체크 |
|------|------|:----:|
| Firebase 프로젝트 생성 | iOS/Android 앱 등록 | ⬜ |
| FCM 토큰 관리 | 기기별 토큰 저장, 갱신 | ⬜ |
| 레슨 리마인더 | 레슨 시작 전 알림 (30분/1시간) | ⬜ |
| 연습 알림 | 일일 연습 리마인더 | ⬜ |
| 초대 알림 | 새 초대/수락/거절 알림 | ⬜ |
| 백엔드 발송 | FastAPI에서 FCM 메시지 발송 | ⬜ |

### Phase 5: 테스트 + QA

> 목표: 출시 전 품질 보증

| 작업 | 상세 | 체크 |
|------|------|:----:|
| 단위 테스트 | 엔티티, Repository, Provider 테스트 | ⬜ |
| 위젯 테스트 | 주요 화면 UI 테스트 | ⬜ |
| 통합 테스트 | API 연동 테스트 | ⬜ |
| E2E 테스트 | 핵심 플로우 (로그인 → 레슨 예약 → 연습) | ⬜ |
| 실기기 테스트 | iPhone 다양한 모델에서 테스트 | ⬜ |
| 성능 테스트 | 메트로놈 타이밍, 녹음 안정성, 메모리 사용량 | ⬜ |
| 베타 테스트 | TestFlight으로 소규모 베타 테스트 | ⬜ |

### Phase 6: iOS App Store 배포

> 목표: iOS App Store 심사 제출 및 출시

| 작업 | 상세 | 체크 |
|------|------|:----:|
| Apple Developer 계정 | Apple Developer Program 등록 ($99/년) | ⬜ |
| 번들 ID 등록 | App ID, Provisioning Profile 설정 | ⬜ |
| App Store Connect 설정 | 앱 정보, 가격, 카테고리 등록 | ⬜ |
| 스크린샷 준비 | 6.7"(iPhone 15 Pro Max), 6.1"(iPhone 15 Pro) | ⬜ |
| 앱 설명 작성 | 한국어 앱 설명문 + 키워드 최적화 | ⬜ |
| 개인정보처리방침 | [초안](specs/subscription/privacy_policy.md) 법률 검토 후 확정, URL 게시 | ⬜ |
| 이용약관 | [초안](specs/subscription/terms_of_service.md) 법률 검토 후 확정 | ⬜ |
| 앱 심사 제출 | Archive → Upload → 심사 제출 | ⬜ |
| 심사 대응 | 리젝 사유 대응 및 재제출 | ⬜ |

→ 상세 체크리스트: [4. iOS 앱스토어 배포 체크리스트](#4-ios-앱스토어-배포-체크리스트)

### Phase 7: Android Google Play 배포

> 목표: Google Play Store 출시

| 작업 | 상세 | 체크 |
|------|------|:----:|
| Google Play Console 등록 | 개발자 계정 등록 ($25 일회성) | ⬜ |
| Android 빌드 설정 | 서명 키 생성, Gradle 설정 | ⬜ |
| 스크린샷 준비 | Phone, 7" Tablet 사이즈 | ⬜ |
| 스토어 등록 정보 | 한국어 설명, 그래픽 에셋 | ⬜ |
| 내부 테스트 | 내부 테스트 트랙 배포 | ⬜ |
| 심사 제출 | 프로덕션 트랙 출시 | ⬜ |

→ 상세 체크리스트: [5. Android Google Play 배포 체크리스트](#5-android-google-play-배포-체크리스트)

### Phase 8: 출시 후 운영 (v1.1 계획)

> 목표: 사용자 피드백 반영 + 기능 확장

| 작업 | 상세 | 체크 |
|------|------|:----:|
| 크래시 모니터링 | Firebase Crashlytics 설정 | ⬜ |
| 사용자 분석 | Firebase Analytics 이벤트 추적 | ⬜ |
| 피드백 수집 | 인앱 피드백, 앱스토어 리뷰 모니터링 | ⬜ |
| v1.1 기능 개발 | 뱃지 시스템, 통계/리포트 | ⬜ |
| 성능 최적화 | 사용자 데이터 기반 병목 개선 | ⬜ |

---

## 4. iOS 앱스토어 배포 체크리스트

### 4.1 Apple Developer 계정

| 항목 | 상세 | 체크 |
|------|------|:----:|
| Apple Developer Program 가입 | $99/년, [developer.apple.com](https://developer.apple.com) | ⬜ |
| App ID 등록 | Bundle ID 설정 (예: `com.chulgil.lessonapp`) | ⬜ |
| Provisioning Profile | Distribution Profile 생성 | ⬜ |
| Push Notification 인증서 | APNs 키 생성 (FCM 연동용) | ⬜ |

### 4.2 앱 메타데이터

| 항목 | 요구사항 | 체크 |
|------|---------|:----:|
| 앱 이름 | 30자 이내, 한국어 | ⬜ |
| 부제목 | 30자 이내 | ⬜ |
| 카테고리 | 교육 (Primary), 음악 (Secondary) | ⬜ |
| 키워드 | 100자 이내, 쉼표 구분 | ⬜ |
| 앱 설명 | 한국어, 핵심 기능 강조 | ⬜ |
| 프로모션 텍스트 | 170자 이내, 수시 변경 가능 | ⬜ |
| 지원 URL | 고객 지원 페이지 | ⬜ |
| 개인정보처리방침 URL | HTTPS로 게시 필수 | ⬜ |

### 4.3 스크린샷 및 에셋

| 항목 | 규격 | 체크 |
|------|------|:----:|
| 6.7" 스크린샷 | 1290 × 2796 px (iPhone 15 Pro Max) | ⬜ |
| 6.1" 스크린샷 | 1179 × 2556 px (iPhone 15 Pro) | ⬜ |
| 앱 아이콘 | 1024 × 1024 px (단일 레이어, 투명 불가) | ⬜ |
| 앱 미리보기 영상 | 선택사항, 최대 30초 | ⬜ |

> 스크린샷은 최소 3장, 최대 10장. 주요 기능 화면 위주로 준비

### 4.4 빌드 설정

| 항목 | 상세 | 체크 |
|------|------|:----:|
| iOS Deployment Target | iOS 16.0 이상 권장 | ⬜ |
| 버전 번호 | Semantic Versioning (1.0.0) | ⬜ |
| 빌드 번호 | 정수, 제출마다 증가 | ⬜ |
| 앱 서명 | Automatic Signing 또는 Manual | ⬜ |
| Archive 빌드 | `flutter build ipa --release` | ⬜ |
| Xcode Upload | Xcode Organizer 또는 `xcrun altool` | ⬜ |

### 4.5 심사 준비

| 항목 | 상세 | 체크 |
|------|------|:----:|
| 데모 계정 | 심사원용 테스트 계정 준비 | ⬜ |
| 심사 노트 | 앱 사용법, 특이사항 설명 | ⬜ |
| 개인정보처리방침 | [초안](specs/subscription/privacy_policy.md) → 법률 검토 → 웹 게시 | ⬜ |
| 이용약관 | [초안](specs/subscription/terms_of_service.md) → 법률 검토 → 인앱 포함 | ⬜ |
| 연령 등급 | 4+ (교육용 앱) | ⬜ |
| 수출 규정 | 암호화 사용 여부 확인 (HTTPS만 → 면제) | ⬜ |

---

## 5. Android Google Play 배포 체크리스트

### 5.1 Google Play Console

| 항목 | 상세 | 체크 |
|------|------|:----:|
| 개발자 계정 등록 | $25 일회성, [play.google.com/console](https://play.google.com/console) | ⬜ |
| 앱 생성 | 앱 이름, 기본 언어(한국어) | ⬜ |
| 콘텐츠 등급 | IARC 설문 작성 | ⬜ |
| 타겟 연령 | 모든 연령 또는 13세 이상 | ⬜ |

### 5.2 스토어 등록 정보

| 항목 | 규격 | 체크 |
|------|------|:----:|
| 앱 아이콘 | 512 × 512 px | ⬜ |
| 그래픽 이미지 | 1024 × 500 px | ⬜ |
| Phone 스크린샷 | 최소 2장, 16:9 또는 9:16 | ⬜ |
| 7" Tablet 스크린샷 | 선택사항 | ⬜ |
| 간단한 설명 | 80자 이내 | ⬜ |
| 자세한 설명 | 4000자 이내 | ⬜ |

### 5.3 빌드 설정

| 항목 | 상세 | 체크 |
|------|------|:----:|
| 서명 키 생성 | `keytool`로 업로드 키 생성 | ⬜ |
| `key.properties` | 키 경로, 비밀번호 설정 | ⬜ |
| `build.gradle` | 서명 설정, minSdkVersion 21 | ⬜ |
| App Bundle 빌드 | `flutter build appbundle --release` | ⬜ |
| Play App Signing | Google에서 앱 서명 관리 (권장) | ⬜ |

### 5.4 심사 준비

| 항목 | 상세 | 체크 |
|------|------|:----:|
| 데이터 안전 섹션 | 수집하는 데이터 유형 선언 | ⬜ |
| 개인정보처리방침 | URL 등록 (iOS와 동일) | ⬜ |
| 광고 포함 여부 | 없음 선택 | ⬜ |
| 내부 테스트 | 내부 테스트 트랙에서 먼저 배포 | ⬜ |
| 프로덕션 출시 | 단계적 출시 (10% → 50% → 100%) 권장 | ⬜ |

---

## 6. 출시 후 계획 (v1.1 ~ v2.0)

### v1.1 - 보상 및 분석

| 기능 | 설명 | 우선순위 |
|------|------|:--------:|
| 뱃지 시스템 | ✅ Phase 1에서 구현 완료 (#98) | - |
| 통계/리포트 | 연습 데이터 시각화, 주간/월간 리포트 | 🟠 High |
| 점진적 템포 증가 | 메트로놈 자동 템포 증가 기능 | 🟡 Medium |

### v1.2 - 학원 모드

| 기능 | 설명 | 우선순위 |
|------|------|:--------:|
| LessonClass 시스템 | 학원/개인 레슨 구분 | 🟠 High |
| 수강권 시스템 | 체험/월정액/회차제 수강권 | 🟠 High |
| 결제 관리 확장 | 미수금 관리, 입금 확인 | 🟡 Medium |

> **참고**: 학원/수강권 구현 상세는 [implementation_roadmap.md](specs/dev/implementation_roadmap.md) 참조

### v2.0 - 확장

| 기능 | 설명 | 우선순위 |
|------|------|:--------:|
| 다국어 지원 | 영어, 일본어 | 🟡 Medium |
| 웹 버전 | Flutter Web 또는 별도 웹앱 | 🟡 Medium |
| AI 피드백 | Whisper + Claude 기반 연습 분석 | 🔵 Low |

---

## 참조 문서

| 문서 | 내용 |
|------|------|
| [implementation_roadmap.md](specs/dev/implementation_roadmap.md) | 학원/수강권/3자 관계 구현 로드맵 |
| [implementation_status.md](requirement/implementation_status.md) | 기능별 구현 현황 |
| [privacy_policy.md](specs/subscription/privacy_policy.md) | 개인정보처리방침 초안 |
| [terms_of_service.md](specs/subscription/terms_of_service.md) | 이용약관 초안 |
| [architecture.md](architecture.md) | 앱 아키텍처 가이드 |
| [../CLAUDE.md](../CLAUDE.md) | 프로젝트 가이드 |
