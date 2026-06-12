# backend/Makefile — beta integration test runner
#
# 필요 환경변수:
#   INTERNAL_API_KEY  (필수) beta 게이트 키
#   BETA_BASE_URL     (선택, 기본: https://api-beta.lessonaza.app)
#   ONLY              (선택) 시나리오 파일명 키워드 (-k 필터)
#   BETA_RESET        (선택) 시드 리셋 안내 echo 후 실행

PYTEST     := uv run pytest
TEST_DIR   := tests/integration_beta
PYTEST_OPTS := -p no:xdist -v

.PHONY: beta-integration

## beta-integration: Run all beta integration tests.
##   make beta-integration
##   make beta-integration ONLY=signup       # -k keyword filter
##   BETA_RESET=1 make beta-integration      # seed reset reminder + run
beta-integration:
ifdef BETA_RESET
	@echo ""
	@echo "[BETA_RESET] 시드 초기화가 필요합니다."
	@echo "  beta 서버에 SSH 접속 후 아래 명령을 실행하세요:"
	@echo "    docker compose exec api uv run python scripts/seeds/seed_beta.py --reset"
	@echo "  또는 서버 관리자에게 seed reset을 요청하세요."
	@echo ""
endif
ifdef ONLY
	$(PYTEST) $(TEST_DIR) $(PYTEST_OPTS) -k "$(ONLY)"
else
	$(PYTEST) $(TEST_DIR) $(PYTEST_OPTS)
endif
