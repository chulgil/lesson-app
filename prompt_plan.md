# Backend 설계 및 구현

> 확정일: 2026-03-16

## 완료된 작업

### Phase 1: 누락 테이블 추가 (완료)
- [x] 프론트엔드 전체 분석 (20 도메인, 80+ 엔티티, 25+ Mock 레포)
- [x] 기존 백엔드 분석 (43 테이블, 100+ 엔드포인트)
- [x] 누락 21개 테이블 모델 작성 (6개 모델 파일)
- [x] Pydantic v2 스키마 작성 (6개 스키마 파일)
- [x] 서비스 레이어 작성 (6개 서비스 파일)
- [x] API 라우터 작성 (6개 라우터 파일)
- [x] Alembic 마이그레이션 0002 작성
- [x] 전체 54개 테스트 통과 확인
- [x] 스펙 문서 작성

### 결과
- 총 64개 테이블, 154개 API 엔드포인트
- 19개 라우터, 18개 서비스

## 다음 Phase

### Phase 2: 기존 스텁 연결
- [ ] schedule 라우터의 exception 스텁 → ScheduleException 모델 연결
- [ ] Analytics 라우터 추가

### Phase 3: Frontend 연결
- [ ] Mock → Remote 전환 가이드 작성
- [ ] Flutter Remote Repository와 API 매핑 확인
- [ ] 데이터 시딩 스크립트

### Phase 4: 인프라
- [ ] Supabase Auth 실제 연동
- [ ] Redis 캐시
- [ ] FCM Push
- [ ] Docker 배포

---

## 이전 계획

### 수강권 자동 갱신 제안 시스템 (2026-03-15) - 완료
Phase 1~4 모두 완료 (SubscriptionRenewalService, 선생님/학생 UX, 자동화)
