# Backend - Lesson App API

> FastAPI 기반 백엔드 서버 (개발 예정)

## 기술 스택

- **Framework**: FastAPI
- **Database**: PostgreSQL (예정)
- **ORM**: SQLAlchemy / SQLModel
- **Package Manager**: UV

## 폴더 구조

```
backend/
├── app/
│   ├── api/           # API 라우터
│   ├── core/          # 설정, 보안
│   ├── models/        # DB 모델
│   ├── schemas/       # Pydantic 스키마
│   ├── services/      # 비즈니스 로직
│   └── main.py        # 앱 엔트리포인트
├── tests/             # 테스트
├── pyproject.toml     # 의존성
└── README.md
```

## 명령어

```bash
# 가상환경 생성 및 의존성 설치
uv sync

# 개발 서버 실행
uv run uvicorn app.main:app --reload

# 테스트 실행
uv run pytest

# 타입 체크
uv run mypy app/
```

## API 문서

서버 실행 후:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 환경 변수

`.env` 파일 생성:
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/lesson_app
SECRET_KEY=your-secret-key
```
