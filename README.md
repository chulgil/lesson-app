# Lessonaza

음악 레슨/연습 관리 앱

## 프로젝트 구조

```
lesson-app/
├── docs/              # 📚 프로젝트 문서
├── backend/           # 🐍 백엔드 (FastAPI)
├── frontend/          # 📱 프론트엔드 (Flutter)
├── CLAUDE.md          # Claude 작업 가이드
└── README.md          # 이 파일
```

## 시작하기

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

### Backend (FastAPI)

```bash
cd backend
uv sync
uv run uvicorn app.main:app --reload
```

## 문서

- [CLAUDE.md](CLAUDE.md) - 전체 프로젝트 가이드
- [docs/](docs/) - 상세 문서
  - [architecture.md](docs/architecture.md) - 아키텍처
  - [specs/](docs/specs/) - 기능 명세
  - [requirement/](docs/requirement/) - 요구사항
