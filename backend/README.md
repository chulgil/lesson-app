# Lessonaza Backend

> FastAPI + PostgreSQL 17 + Docker | [lessonaza.app](https://lessonaza.app)

음악 레슨/연습 관리 앱 Lessonaza의 백엔드 API 서버

## Tech Stack

| 항목 | 기술 |
|------|------|
| Framework | FastAPI |
| ORM | SQLAlchemy 2.0 (async) |
| Database | PostgreSQL 17 |
| Auth | JWT + OAuth (Google, Kakao, Apple) |
| Storage | Vultr Object Storage |
| Package Manager | UV |
| Container | Docker + Docker Compose |

## Quick Start

### Docker (권장)

```bash
# 환경변수 설정
cp .env.example .env
nano .env

# 실행
docker compose up -d

# 마이그레이션
docker compose exec app uv run alembic upgrade head

# 로그 확인
docker compose logs -f app
```

### Local Development

```bash
# 의존성 설치
uv sync

# 환경변수
cp .env.example .env

# 서버 실행
uv run uvicorn app.main:app --reload --port 8000

# 마이그레이션
uv run alembic upgrade head
```

## API Docs

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

## Tests

```bash
uv run pytest
uv run pytest --cov=app
```

## Deployment

```bash
# 서버에서 배포
git pull && docker compose build --no-cache app && docker compose up -d

# 또는 배포 스크립트 사용
./scripts/deploy.sh
```

-> 상세: [docs/deployment.md](docs/deployment.md)

## Project Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI entry point
│   ├── core/                # Config, DB, Auth, i18n
│   ├── models/              # SQLAlchemy ORM models
│   ├── schemas/             # Pydantic v2 schemas
│   ├── api/v1/              # API routes
│   ├── services/            # Business logic
│   └── utils/               # Utilities
├── alembic/                 # DB migrations
├── tests/                   # Test suite
├── nginx/                   # Nginx config
├── docker-compose.yml
├── Dockerfile
└── pyproject.toml
```
