# CLAUDE.md - Lesson App

음악 레슨/연습 관리 앱 (Flutter)

## 빠른 참조

| 항목 | 값 |
|------|-----|
| 기술 스택 | Flutter, Riverpod (@riverpod 코드생성), Go Router, Hive |
| 플랫폼 | iOS, Android |
| 상태 | Phase 1 진행중 (95% 완료) |

## 명령어

```bash
flutter pub get                    # 의존성
flutter run                        # 실행
dart run build_runner build --delete-conflicting-outputs  # 코드 생성
flutter analyze                    # 분석
```

## 프로젝트 구조

```
lib/
├── core/theme/          # AppColors, AppTypography, AppSpacing
├── features/            # auth, home, lessons, students, practice, profile, student_home, schedule
├── models/              # student, payment, lesson, piece, practice_item, lesson_booking, tip_template
├── repositories/        # 인터페이스 + Mock 구현
├── providers/           # Riverpod (@riverpod 코드생성 적용)
└── services/            # API, Storage
```

## 핵심 규칙

### 디자인
- 색상: 반드시 `AppColors` 클래스 사용 (하드코딩 금지)
- Primary: #6B5B95, Secondary: #F4A460, Background: #FFFAF5

### 코드
- Dart 스타일 가이드 준수
- `flutter analyze` 경고 없이 유지
- 주석 영어, 커밋 메시지 한글 (Conventional Commits)

### 아키텍처
- Repository 패턴: 인터페이스 + Mock 분리
- Provider: @riverpod 어노테이션 사용
- 대형 위젯: 별도 파일로 분리 (500줄 이상 지양)

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

### 진행중
- 레슨 스케줄 시스템 (화면 완료, 라우터 연결 필요)
- 연습 알림 시스템

### 예정
- OAuth 연동 (Google, Kakao)
- 푸시 알림
- 뱃지 시스템
- 통계/리포트
- AI 레슨 요약

## 주요 모델

| 모델 | 용도 |
|------|------|
| Student | 학생 정보, 레벨 (beginner/elementary/intermediate/advanced) |
| Payment | 결제 (trial/regular), 2단계 입금확인 |
| Lesson | 레슨 기록, 노트, 녹음 |
| PracticeItem | 연습 과제 (priority: must/should/could) |
| LessonBooking | 체험/정규레슨 예약 (pending/confirmed/completed) |
| MetronomeSettings | BPM, 박자표, 사운드 템플릿 |

## 문서 참조

| 문서 | 위치 |
|------|------|
| 요구사항 | `idea/lesson-app/requirement.md` |
| 구현 현황 | `idea/lesson-app/implementation_status.md` |
| 연습 시스템 스펙 | `idea/lesson-app/specs/practice_system.md` |
| 수강료 스펙 | `idea/lesson-app/specs/payment_system.md` |
| 레슨 스케줄 스펙 | `idea/lesson-app/specs/lesson_schedule.md` |
| 체험 레슨 스펙 | `idea/lesson-app/specs/trial_lesson_system.md` |
| 가용시간 관리 스펙 | `idea/lesson-app/specs/trial_lesson_system.md#가용시간-관리-시스템-상세` |
| 노쇼/취소 정책 스펙 | `idea/lesson-app/specs/trial_lesson_system.md#노쇼취소-정책-시스템-상세` |
| 메트로놈 스펙 | `idea/lesson-app/specs/metronome_system.md` |
| 알림 시스템 스펙 | `idea/lesson-app/specs/notification_system.md` |
| 결제 플로우 스펙 | `idea/lesson-app/specs/payment_flow.md` |
| 선생님 등록 스펙 | `idea/lesson-app/specs/teacher_registration.md` |
| 리뷰 시스템 스펙 | `idea/lesson-app/specs/review_system.md` |
| 학부모 시스템 스펙 | `idea/lesson-app/specs/parent_system.md` |

> 경로 기준: `/Volumes/SSD/Dev/Personal/development/`

## 브레인스토밍 Q&A

기획 브레인스토밍 시 사용자와의 Q&A 세션 내용은 `proposal/` 폴더에 저장합니다.

| 문서 | 위치 |
|------|------|
| 학부모 시스템 Q&A | `idea/lesson-app/proposal/parent_system.md` |

### Q&A 문서 작성 규칙

1. **파일 위치**: `idea/lesson-app/proposal/{기능명}.md`
2. **필수 포함 내용**:
   - 타사 사례 조사 결과
   - 제시된 질문 목록 (Q1, Q2, ...)
   - 각 질문별 옵션 (A, B, C, D)
   - 사용자 결정 사항
   - 결정 요약 테이블
3. **연결 스펙**: 해당 Q&A를 기반으로 작성된 스펙 문서 경로 명시

## 다음 우선순위

1. 레슨 스케줄 라우터 연결
2. 연습 알림 시스템
3. 외부 선생님 등록
4. 백엔드 API (FastAPI)

## 문제 해결

```bash
# iOS 빌드 에러
cd ios && pod install && cd .. && flutter clean && flutter pub get

# Android 빌드 에러
cd android && ./gradlew clean && cd .. && flutter clean && flutter pub get
```
