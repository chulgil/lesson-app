# CLAUDE.md - Lesson App

> 마지막 업데이트: 2025-12-31

음악 레슨/연습 관리 앱 (Flutter)

## 빠른 참조

| 항목 | 값 |
|------|-----|
| 기술 스택 | Flutter, Riverpod (@riverpod 코드생성), Go Router, Hive |
| 플랫폼 | iOS, Android |
| 상태 | Phase 1 완료 (100%) |

## 명령어

```bash
flutter pub get                    # 의존성
flutter run                        # 실행
dart run build_runner build --delete-conflicting-outputs  # 코드 생성
flutter analyze                    # 분석
```

## 프로젝트 구조

```
lesson-app/
├── lib/
│   ├── core/theme/          # AppColors, AppTypography, AppSpacing
│   ├── features/            # auth, home, lessons, students, practice, profile, student_home, schedule
│   ├── models/              # student, payment, lesson, piece, practice_item, lesson_booking, tip_template, recording
│   ├── repositories/        # 인터페이스 + Mock 구현
│   ├── providers/           # Riverpod (@riverpod 코드생성 적용)
│   └── services/            # API, Storage
├── docs/                    # 모든 프로젝트 문서
│   ├── requirement/         # 요구사항
│   ├── proposal/            # 기획 제안서, Q&A
│   ├── specs/               # 기능 명세 (도메인별)
│   └── README.md            # 문서 인덱스
└── CLAUDE.md
```

---

## 문서 구조

> **중요**: 모든 프로젝트 문서는 `docs/` 폴더에 위치합니다.

### 문서 위치

| 폴더 | 내용 | 예시 |
|------|------|------|
| `docs/requirement/` | 요구사항, 구현 현황 | requirement.md, implementation_status.md |
| `docs/proposal/` | 기획 제안서, 브레인스토밍 Q&A | parent_system.md, minor_registration_policy.md |
| `docs/specs/[domain]/` | 도메인별 기능 명세 | lesson/, practice/, payment/ |

### 도메인별 스펙

| 도메인 | 문서 | 설명 |
|--------|------|------|
| **lesson/** | lesson_schedule.md | 레슨 스케줄 시스템 |
| | Lesson_Types_Analysis.md | 레슨 유형 분석 |
| | Lesson_Schedule_Design.md | 레슨 스케줄 설계 |
| | student_centered_architecture.md | 학생 중심 아키텍처 |
| | Unified_Lesson_Booking_Spec.md | 통합 예약 스펙 |
| **practice/** | practice_system.md | 연습 시스템 스펙 |
| | Practice_System_Spec.md | 연습 시스템 상세 |
| | practice_streak_spec.md | 연습 스트릭 |
| | recording_requirement.md | 녹음 기능 요구사항 |
| | recording_player_ui.md | 녹음 재생 UI 스펙 |
| **metronome/** | metronome_system.md | 메트로놈 시스템 |
| | metronome_sound.md | 사운드 이펙트 |
| | metronome_indicator.md | UI 인디케이터 |
| **payment/** | payment_system.md | 결제 시스템 |
| | payment_flow.md | 결제 플로우 |
| | payment_requirement.md | 결제 요구사항 |
| **user/** | parent_system.md | 학부모 시스템 (이중 역할, 미연결 자녀 포함) |
| | parent_login_flow.md | 학부모 로그인 |
| | teacher_registration.md | 선생님 등록 |
| **notification/** | notification_system.md | 알림 시스템 |
| **review/** | review_system.md | 리뷰/피드백 시스템 |
| **trial/** | trial_lesson_system.md | 체험 레슨 |
| **invite/** | invite_system_v2.md | 양방향 초대 시스템 (선생님↔학부모 직접 초대 포함) |
| **design/** | ux_guidelines.md | UX 가이드라인 |
| | figma_templates.md | Figma 템플릿 |
| | competitive_analysis.md | 경쟁사 분석 |

→ [전체 문서 인덱스](docs/README.md)

---

## 핵심 규칙

### 디자인
- 색상: 반드시 `AppColors` 클래스 사용 (하드코딩 금지)
- Primary: #6B5B95, Secondary: #F4A460, Background: #FFFAF5
- UX 가이드라인: [docs/specs/design/ux_guidelines.md](docs/specs/design/ux_guidelines.md)

### 코드
- Dart 스타일 가이드 준수
- `flutter analyze` 경고 없이 유지
- 주석 영어, 커밋 메시지 한글 (Conventional Commits)

### 아키텍처
- Repository 패턴: 인터페이스 + Mock 분리
- Provider: @riverpod 어노테이션 사용
- 대형 위젯: 별도 파일로 분리 (500줄 이상 지양)

---

## 구현 현황

### 완료
- 로그인 UI (OAuth 연동 예정)
- 선생님/학생 대시보드
- 학생 관리 (CRUD, 레벨)
- 레슨 캘린더 (월/주 뷰)
- 레슨 노트/녹음
- 수강료 관리 (2단계 입금확인)
- 연습 시스템 Phase 1-2 (레퍼토리 연동, 다중 구간)
- 레퍼토리 관리
- 팁 템플릿 시스템
- 연습 스트릭 (주말 제외 정책)
- Debug 역할 전환
- 메트로놈 시스템 (엔진, 하단 바, 풀스크린 모달, 고양이 UI)
- 고양이 비트 인디케이터 (발바닥 애니메이션, 박자별 강세, 하단 바 깜박임)
- 녹음 파형 애니메이션 (곡선 사인파 흐름)
- 녹음 시 BPM 표시
- 레슨 스케줄 시스템 (화면, 라우터 연결)
- 연습 알림 시스템 (FCM + Local Notification)
- 외부 선생님 등록 시스템 (온보딩 3단계, 프로필 설정)
- 선생님 검색 시스템 (필터링, 프로필 상세)
- 양방향 초대 시스템 (QR/URL/코드, 연결 요청 관리)
- 학부모 시스템 (이중 역할 전환, 프로필 스위처, 미연결 자녀 대시보드)
- 녹음 재생 시스템 (웨이브폼, A-B 루프, 속도 조절, 메트로놈 연동)

### 진행중
- 없음

### 예정
- 푸시 알림 (FCM)
- 뱃지 시스템
- 백엔드 API (FastAPI)
- OAuth 연동 (Google, Kakao) - 백엔드 필요
- 통계/리포트
- AI 레슨 요약

---

## Claude 작업 워크플로우

```
1. docs/requirement/ 확인 → 요구사항 파악
2. docs/specs/[domain]/ 확인 → 관련 스펙 파악
3. 구현 작업 수행
4. docs/specs/ 명세 업데이트 → 구현 내용 반영
5. 필요시 proposal/ 에 Q&A 기록
```

### 브레인스토밍 Q&A 작성 규칙

기획 브레인스토밍 시 사용자와의 Q&A 세션 내용은 `docs/proposal/` 폴더에 저장합니다.

1. **파일 위치**: `docs/proposal/{기능명}.md`
2. **필수 포함 내용**:
   - 타사 사례 조사 결과
   - 제시된 질문 목록 (Q1, Q2, ...)
   - 각 질문별 옵션 (A, B, C, D)
   - 사용자 결정 사항
   - 결정 요약 테이블
3. **연결 스펙**: 해당 Q&A를 기반으로 작성된 스펙 문서 경로 명시

---

## 주요 모델

| 모델 | 용도 |
|------|------|
| Student | 학생 정보, 레벨 (beginner/elementary/intermediate/advanced) |
| Payment | 결제 (trial/regular), 2단계 입금확인 |
| Lesson | 레슨 기록, 노트, 녹음 |
| PracticeItem | 연습 과제 (priority: must/should/could) |
| LessonBooking | 체험/정규레슨 예약 (pending/confirmed/completed) |
| MetronomeSettings | BPM, 박자표, 사운드 템플릿 |
| Recording | 녹음 파일 (UUID, 경로, 메타데이터) |
| UserProfile | 이중 역할 지원 (학부모/학생/자녀), 프로필 전환 |
| ChildProfile | 자녀 프로필 (connected/pending/unconnected) |

---

## 작업 우선순위

| 순위 | 작업 | 상태 | 긴급도 |
|:----:|------|:----:|:------:|
| 1 | 외부 선생님 등록 | ✅ 완료 | - |
| 2 | 양방향 QR/URL 초대 | ✅ 완료 | - |
| 3 | 학부모 시스템 | ✅ 완료 | - |
| 4 | 푸시 알림 | 대기 | 높음 |
| 5 | 뱃지 시스템 | 대기 | 높음 |
| 6 | 백엔드 API (FastAPI) | 대기 | 중간 |
| 7 | OAuth 연동 (백엔드 필요) | 대기 | 중간 |

> Claude 작업 시: 위 순위대로 진행, 상태 업데이트 필수

---

## 문제 해결

```bash
# iOS 빌드 에러
cd ios && pod install && cd .. && flutter clean && flutter pub get

# Android 빌드 에러
cd android && ./gradlew clean && cd .. && flutter clean && flutter pub get
```
