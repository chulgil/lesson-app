# Codex Review — backend #404 #405 #406 (model: gpt-5-codex)

Date: 2026-05-28
Reviewer: codex-cli 0.130.0 (read-only sandbox)
Target commits: 2b978049 (#404), 8097f2a6 (#405), 425886d3 (#406)

## Raw Codex Output

**판정**: AGREE with caveats.

**Q1 사각지대**: 기본값은 안전합니다. `apply_iap_receipt()`는 receipt를 저장한 뒤 `_iap_dev_auto_grant_allowed()`가 false면 plan 변경 없이 반환하고, `/iap/validate`도 `granted=False`를 실패 응답으로 처리합니다. 단, `PRODUCTION_LIKE_ENVIRONMENTS={"production","beta"}`만 막으므로 `prod`, `staging`, `Production` 같은 운영성 환경명이 쓰이고 `IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY=true`면 자동 grant가 열립니다. 운영 설정 명칭 통제가 전제입니다.

**Q2 sync 잔재**: 지정 파일 기준 sync 잔재는 보이지 않습니다. `flush`, `refresh`, `scalar` 모두 await 됩니다. `commit()`은 서비스가 아니라 API/호출자가 담당하는 패턴으로 보입니다.

**Q3 DB 제약 함정**: FK `ON DELETE CASCADE`와 `UNIQUE(user_id)`, `UNIQUE(platform, transaction_id)` 자체는 Postgres/MySQL에서 의도대로 동작합니다. `users.id`도 `String(36)`이라 타입은 맞습니다. 다만 Postgres downgrade에서 enum type을 drop하지 않아 재실행 시 타입 충돌 가능성이 있습니다. MySQL은 InnoDB 전제가 필요합니다.

**Q4 테스트 품질**: 단순 구현 복사만은 아닙니다. forged receipt가 Pro로 승급되지 않는지, audit row가 남는지, production/beta flag 무시, endpoint DB 상태, UNIQUE replay 차단을 실제로 잡습니다. 부족한 점은 cascade 삭제 테스트와 Postgres/MySQL dialect 마이그레이션 검증, 환경 alias 사각지대 테스트가 없다는 점입니다.

**Claude 와 의견 불일치**: 있다면 "우회 불가능" 표현입니다. 코드 경로는 안전하지만 환경명 allowlist가 좁아 운영 설정 실수에는 취약합니다.

## 권장 후속 조치 (Claude 가 해석)

1. `PRODUCTION_LIKE_ENVIRONMENTS` 에 `prod`, `staging`, `Production` (대소문자) alias 추가 + 정규화 함수
2. alembic downgrade 에 `op.execute("DROP TYPE iap_status")` 등 enum drop 추가
3. cascade 삭제 회귀 테스트 1건 + 환경 alias 사각지대 테스트 1건 추가
4. MySQL 사용 시 `mysql_engine='InnoDB'` 명시 확인
