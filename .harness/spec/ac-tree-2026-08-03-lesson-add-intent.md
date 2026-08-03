# AC Tree — lesson-add-intent

> 최종 갱신: 2026-08-03 20:10 — PR-A~D+후속 2건 전부 머지(#1227/#1228/#1229/#1230/#1231/#1232). AC-6.3 만 partial(mock 데이터 상태 한계)
> Spec: `docs/specs/subscription/subscription_required_spec.md` §2.6~2.7 (origin/main `5455a3b4`)
> DAG: `decomposition-2026-08-03-lesson-add-intent.md`

## AC-0 [lesson-add-intent] 레슨 추가 인텐트 분기 + 수기(미가입) 경계 (in_progress)
- **설명**: 레슨 추가의 회계 영향 자동 처리 3종(잔여 0 보너스·크레딧 미소비·체험권 발급)을 명시적 선택/안내로 승격하고, 미가입 학생 특칙과 다음 회차 배선을 구현
- **만족 조건**: 모든 자식 AC passed
- **담당 job**: —

  ### AC-1 [BE 회계] 레슨 생성 회계 모드 (passed)
  - **만족 조건**: 자식 AC passed + 레거시 호출(파라미터 없음) 동작 불변
  - **담당 job**: —

    #### AC-1.1 [overflow_mode] 파라미터 분기 (passed)
    - **만족 조건**: `bonus`(명시 보너스) / `renewal_pending`(isPreview, 카운터 불변) / `None`(레거시 §2.3 회귀) 분기 테스트 통과
    - **담당 job**: J1
    - **관련 테스트**: backend/tests/ — overflow_mode 분기 3종 + 레거시 회귀

    #### AC-1.2 [크레딧 소비] makeup_credit 모드 (passed)
    - **만족 조건**: 잔여>0 에서도 크레딧 차감·정규 카운터 불변 / usedLessonId 연결 / 크레딧 0개 422 (booking 경로와 동일 시맨틱 — 구현 시 409 계획을 정정)
    - **담당 job**: J2
    - **관련 테스트**: backend/tests/ — makeup_credit 소비 3종

    #### AC-1.3 [체험 가드] trial_already_used (passed)
    - **만족 조건**: 가입 학생 자동 체험권 2회째 차단 / 미가입 학생 무제한 / 첫 생성 회귀
    - **담당 job**: J3
    - **관련 테스트**: backend/tests/ — 가드 3분기

    #### AC-1.4 [preview 전환] 갱신 입금 확인 시 정식 회차 (passed)
    - **만족 조건**: 입금 확인 → `is_preview=False` + 신규 수강권 재귀속 + 회차 카운터 정합 / 갱신 거절·만료 시 preview 처리 정의·테스트
    - **담당 job**: J16
    - **관련 테스트**: backend/tests/ — preview 전환 2분기

  ### AC-2 [FE 인텐트] 레슨 추가 상태별 UI (passed)
  - **만족 조건**: 자식 AC passed + S1/S2 흔한 경우 탭 수·동작 불변 (회귀)
  - **담당 job**: —

    #### AC-2.1 [S5/S6 배너] 체험 자동발급 명시 + 발급 유도 (passed)
    - **만족 조건**: S5 배너+보조 버튼 / S6 `trial_already_used` 발급 유도 다이얼로그 / smoke test / AppStrings
    - **담당 job**: J5
    - **관련 테스트**: frontend/test/ — 배너 상태 3종 + smoke

    #### AC-2.2 [S3 시트] 잔여 0 처리 방식 (passed)
    - **만족 조건**: 잔여 0 저장 시 시트 / 기본 강조=갱신(D1) / 크레딧 0개면 보강 항목 숨김 / 미가입=갱신 발급 분기 / 항목별 overflow_mode 전송 / **S1·S2(잔여>0) 시트 미노출·즉시 저장 회귀**
    - **담당 job**: J6
    - **관련 테스트**: frontend/test/ — 시트 4분기 + S1/S2 회귀 + smoke

    #### AC-2.3 [S4 토글] 보강 처리 + 배지 (passed)
    - **만족 조건**: 크레딧>0 에만 토글 노출 / 기본 OFF(D3) / ON 시 makeup_credit 전송 / 보강 배지=MakeupCredit 연결 표시(신규 enum 0) / 체험 배지(`type==trial`) 기존 구현 확인 후 회귀 또는 추가
    - **담당 job**: J7
    - **관련 테스트**: frontend/test/ — 토글 3분기 + 배지

  ### AC-3 [FE 플로우] 발급·등록 연속 (passed)
  - **만족 조건**: 자식 AC passed
  - **담당 job**: —

    #### AC-3.1 [returnTo] 발급 왕복 (passed)
    - **만족 조건**: 즉시 발급 → add_lesson 복귀 + 새 수강권 자동 귀속 / 제안 경로 복귀 없음 + 안내 / 레슨 선생성 0
    - **담당 job**: J8
    - **관련 테스트**: frontend/test/ — spy-mock 라우팅 왕복

    #### AC-3.2 [새 학생] 인라인 등록 (passed)
    - **만족 조건**: 시트 최상단 항목 / 등록 복귀 자동 선택 / 발급 다이얼로그 스킵
    - **담당 job**: J9
    - **관련 테스트**: frontend/test/ — spy-mock 등록 왕복

  ### AC-4 [배선] 다음 회차 예약 CTA (passed)
  - **만족 조건**: 미정 회차 시 CTA(死문자열 재사용) / 정규권 비노출 / subscriptionId 프리필 귀속 / 학생측 직접예약 라우팅
  - **담당 job**: J10
  - **관련 테스트**: frontend/test/ — CTA 3분기 + 프리필

  ### AC-5 [미가입 특칙] 수기 학생 경계 (passed)
  - **만족 조건**: 자식 AC passed
  - **담당 job**: —

    #### AC-5.1 [즉시발급만] 제안 UI 숨김 (passed)
    - **만족 조건**: 미가입 학생 발급 화면에서 제안 버튼 비노출, 즉시 발급만
    - **담당 job**: J8
    - **관련 테스트**: frontend/test/ — 미가입 분기 위젯

    #### AC-5.2 [확인 카드 스킵] 고아 카드 방지 (passed)
    - **만족 조건**: 미가입 학생 즉시발급 → 확인 카드 0건 + 알림 발송 0건 (이미 스킵이면 회귀 테스트로 고정)
    - **담당 job**: J4
    - **관련 테스트**: backend/tests/ — 카드 생성 분기

    #### AC-5.3 [단독 일정 변경] 편집 잠금 해제 (passed)
    - **만족 조건**: 미가입 학생 수강권 레슨 날짜/시간 편집 허용 + 액션 시트 "일정 수정(직접)" 대체 / 가입 학생 잠금 회귀
    - **담당 job**: J11
    - **관련 테스트**: frontend/test/ — 편집 분기 + 액션 시트

  ### AC-6 [검증] 회귀·평가 (in_progress)
  - **만족 조건**: 자식 AC passed
  - **담당 job**: —

    #### AC-6.1 [스위트] 전체 회귀 (passed)
    - **만족 조건**: FE 전체 + architecture + BE 전체 0 신규 실패 (main 기존 실패 4건 baseline 대조)
    - **담당 job**: J12
    - **관련 테스트**: 전체 스위트

    #### AC-6.2 [critic] code + test critic (passed)
    - **만족 조건**: code critic 스펙 준수 PASS + test critic(코드 미열람) PASS
    - **담당 job**: J13, J14
    - **관련 테스트**: — (eval)

    #### AC-6.3 [실기] UI 시나리오 6종 (in_progress)
    - **만족 조건**: web-server + 375/1440 뷰포트에서 시나리오 6종 시각 확인 (frontend-verify)
    - **담당 job**: J15
    - **관련 테스트**: — (eval, 스크린샷 증거)
    - **커버 (2026-08-03 실기, mock 웹)**: 새 학생 등록 시트 항목 / S1·S2 배너+선택 시트+자동완성 / S4 토글 조건부 비노출 / G8 CTA("3회차 예약 필요"+예약하기)→AddLesson subscriptionId 프리필 왕복 / 1440 레이아웃 / 콘솔 에러 0
    - **잔여 (mock 에 상태 부재 — 베타 실기 or mock 시나리오 보강 후)**: S3 잔여0 시트 / S4 토글 ON 저장 / S5·S6 무수강권·체험 재사용 / 미가입 편집·발급 시트 / 제안 경로 레슨 미선생성 부정 확인(test critic 요구)
