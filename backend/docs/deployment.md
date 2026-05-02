# Deployment Guide

> 마지막 업데이트: 2026-03-02

> ⚠️ 현재 코드와 Docker Compose 기준 실제 DB는 PostgreSQL 17입니다.
> 이 문서는 과거 MySQL/systemd 배포안이 많이 남아 있어 참고용으로만 사용하고,
> 실제 배포는 `backend/docker-compose.yml`, `backend/docker-compose.beta.yml`,
> `backend/env.beta.example`을 기준으로 진행하세요.

## 개요

codenavi 서버(108.61.162.25)에 FastAPI 백엔드를 배포하는 가이드.
MySQL 8.0 + Nginx 리버스 프록시 + systemd 서비스로 구성한다.

---

## 서버 사양

| 항목 | 값 |
|------|-----|
| 호스트 | 108.61.162.25 (codenavi) |
| OS | Ubuntu 22.04 |
| User | admin |
| SSH Key | `~/Library/Mobile Documents/com~apple~CloudDocs/MacOS/ssh/home/id_rsa` |
| 프로젝트 경로 | `~/apps/lesson-app-backend` |
| Python | 3.12+ |
| 패키지 관리 | UV |

---

## 1. 서버 초기 설정

### 1.1 MySQL 8.0 설치

```bash
# MySQL 설치
sudo apt update
sudo apt install mysql-server-8.0 -y

# 보안 설정
sudo mysql_secure_installation

# DB 및 사용자 생성
sudo mysql -u root -p
```

```sql
CREATE DATABASE lesson_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'lesson_app'@'localhost' IDENTIFIED BY '<secure_password>';
GRANT ALL PRIVILEGES ON lesson_app.* TO 'lesson_app'@'localhost';
FLUSH PRIVILEGES;
```

### 1.2 Python 3.12 + UV 설치

```bash
# Python 3.12
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.12 python3.12-venv python3.12-dev -y

# UV 설치
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 1.3 프로젝트 클론 및 설정

```bash
cd ~/apps
git clone <repository_url> lesson-app-backend
cd lesson-app-backend

# 의존성 설치
uv sync

# 환경변수 설정
cp .env.example .env
nano .env  # DB URL, JWT Secret, OAuth 키 등 설정
```

### 1.4 Alembic 마이그레이션

```bash
cd ~/apps/lesson-app-backend

# 초기 마이그레이션 생성 (개발 시)
uv run alembic revision --autogenerate -m "initial"

# 마이그레이션 적용
uv run alembic upgrade head

# 마이그레이션 상태 확인
uv run alembic current
```

---

## 2. Systemd 서비스 설정

### 2.1 서비스 파일 생성

```bash
sudo nano /etc/systemd/system/lesson-app.service
```

```ini
[Unit]
Description=Lesson App Backend API
After=network.target mysql.service
Requires=mysql.service

[Service]
Type=exec
User=admin
Group=admin
WorkingDirectory=/home/admin/apps/lesson-app-backend
Environment="PATH=/home/admin/.local/bin:/usr/bin"
ExecStart=/home/admin/.local/bin/uv run uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 2 \
    --log-level info \
    --access-log
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 2.2 서비스 활성화

```bash
sudo systemctl daemon-reload
sudo systemctl enable lesson-app
sudo systemctl start lesson-app

# 상태 확인
sudo systemctl status lesson-app

# 로그 확인
sudo journalctl -u lesson-app -f
```

---

## 3. Nginx 리버스 프록시

### 3.1 Nginx 설치

```bash
sudo apt install nginx -y
```

### 3.2 사이트 설정

```bash
sudo nano /etc/nginx/sites-available/lesson-app
```

```nginx
server {
    listen 80;
    server_name api.lesson-app.com;

    # Let's Encrypt 인증 후 HTTPS로 리다이렉트
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name api.lesson-app.com;

    # SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/api.lesson-app.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.lesson-app.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Upload size (recordings)
    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Static files / docs
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
    }

    location /redoc {
        proxy_pass http://127.0.0.1:8000/redoc;
    }
}
```

### 3.3 사이트 활성화

```bash
sudo ln -s /etc/nginx/sites-available/lesson-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3.4 SSL 인증서 (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx -y

# 인증서 발급
sudo certbot --nginx -d api.lesson-app.com

# 자동 갱신 확인
sudo certbot renew --dry-run
```

---

## Docker 배포

Docker Compose를 사용하여 MySQL, FastAPI, Nginx를 컨테이너로 실행할 수 있다.

### docker-compose.yml 구성

| 서비스 | 역할 | 포트 |
|--------|------|------|
| `db` | MySQL 8.0 | 3306 (내부) |
| `app` | FastAPI (uvicorn) | 8000 (내부) |
| `nginx` | 리버스 프록시 + SSL | 80, 443 (외부) |

```yaml
# docker-compose.yml 요약
services:
  db:
    image: mysql:8.0
    volumes:
      - mysql_data:/var/lib/mysql
    environment:
      MYSQL_DATABASE: lesson_app
      MYSQL_USER: lesson_app
      MYSQL_PASSWORD: ${DB_PASSWORD}

  app:
    build: .
    depends_on:
      - db
    env_file: .env
    command: uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - app
```

### Docker 초기 설정

```bash
# 1. 환경변수 설정
cp .env.example .env
nano .env

# 2. 컨테이너 빌드 및 실행
docker compose up -d

# 3. DB 마이그레이션
docker compose exec app uv run alembic upgrade head

# 4. 상태 확인
docker compose ps
docker compose logs -f app
```

### Docker 일상 배포

```bash
# 서버에서 실행
cd ~/apps/lesson-app-backend

# 1. 최신 코드 가져오기
git pull

# 2. 앱 컨테이너 재빌드 (캐시 미사용)
docker compose build --no-cache app

# 3. 컨테이너 재시작
docker compose up -d

# 4. DB 마이그레이션 (필요 시)
docker compose exec app uv run alembic upgrade head

# 5. 로그 확인
docker compose logs -f app
```

원격 배포 한 줄 명령:

```bash
ssh -i "$SSH_KEY" admin@108.61.162.25 \
    "cd ~/apps/lesson-app-backend && git pull && docker compose build --no-cache app && docker compose up -d && docker compose exec app uv run alembic upgrade head"
```

### Docker 롤백

```bash
# 서버에서 실행
cd ~/apps/lesson-app-backend

# 1. 이전 커밋으로 복원
git log --oneline -5
git checkout <previous_commit>

# 2. 앱 컨테이너 재빌드
docker compose build --no-cache app

# 3. 컨테이너 재시작
docker compose up -d

# 4. DB 마이그레이션 롤백 (필요 시)
docker compose exec app uv run alembic downgrade -1
```

---

## 4. 배포 워크플로우

### 4.1 일상 배포

```bash
# 로컬에서 개발 → 커밋 → 푸시
cd /Volumes/SSD/Dev/Personal/development/app/lesson-app/backend
git add . && git commit -m "feat: 기능 설명" && git push

# 서버에서 배포
ssh -i "~/Library/Mobile Documents/com~apple~CloudDocs/MacOS/ssh/home/id_rsa" \
    admin@108.61.162.25 \
    "cd ~/apps/lesson-app-backend && git pull && uv sync && uv run alembic upgrade head && sudo systemctl restart lesson-app"
```

### 4.2 배포 스크립트

로컬에 `scripts/deploy.sh` 생성:

```bash
#!/bin/bash
set -e

SSH_KEY="~/Library/Mobile Documents/com~apple~CloudDocs/MacOS/ssh/home/id_rsa"
SERVER="admin@108.61.162.25"
PROJECT_DIR="~/apps/lesson-app-backend"

echo "🚀 Deploying lesson-app backend..."

# 1. Push local changes
git push

# 2. Remote deploy
ssh -i "$SSH_KEY" $SERVER << 'REMOTE'
    cd ~/apps/lesson-app-backend

    # Pull latest
    git pull

    # Install dependencies
    ~/.local/bin/uv sync

    # Run migrations
    ~/.local/bin/uv run alembic upgrade head

    # Restart service
    sudo systemctl restart lesson-app

    # Check status
    sleep 2
    sudo systemctl is-active lesson-app
REMOTE

echo "✅ Deploy complete!"
```

### 4.3 롤백

```bash
# 서버에서 이전 커밋으로 롤백
ssh -i "$SSH_KEY" admin@108.61.162.25 << 'REMOTE'
    cd ~/apps/lesson-app-backend

    # 이전 커밋으로 복원
    git log --oneline -5
    git checkout <previous_commit>

    # 마이그레이션 롤백 (필요 시)
    ~/.local/bin/uv run alembic downgrade -1

    # 재시작
    sudo systemctl restart lesson-app
REMOTE
```

---

## 5. 모니터링

### 5.1 로그 확인

```bash
# 실시간 로그
sudo journalctl -u lesson-app -f

# 최근 100줄
sudo journalctl -u lesson-app -n 100

# 에러만
sudo journalctl -u lesson-app -p err
```

### 5.2 상태 확인

```bash
# 서비스 상태
sudo systemctl status lesson-app

# 포트 확인
ss -tlnp | grep 8000

# MySQL 확인
sudo systemctl status mysql

# 디스크 사용량
df -h
```

### 5.3 헬스체크 엔드포인트

```python
# app/main.py
@app.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    await db.execute(text("SELECT 1"))
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
```

---

## 6. 백업

### 6.1 MySQL 자동 백업

```bash
sudo nano /etc/cron.d/lesson-app-backup
```

```cron
# 매일 새벽 3시 백업
0 3 * * * admin mysqldump -u lesson_app -p'<password>' lesson_app | gzip > /home/admin/backups/lesson_app_$(date +\%Y\%m\%d).sql.gz

# 30일 이상 된 백업 삭제
0 4 * * * admin find /home/admin/backups/ -name "lesson_app_*.sql.gz" -mtime +30 -delete
```

### 6.2 백업 디렉토리 생성

```bash
mkdir -p ~/backups
```

---

## 7. 환경변수 (.env.example)

```bash
# === Database ===
DATABASE_URL=mysql+asyncmy://lesson_app:<password>@localhost:3306/lesson_app
DATABASE_ECHO=false

# === JWT ===
JWT_SECRET_KEY=<generate: openssl rand -hex 32>
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=30

# === OAuth - Google ===
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxx

# === OAuth - Kakao ===
KAKAO_CLIENT_ID=xxx
KAKAO_CLIENT_SECRET=xxx

# === OAuth - Apple ===
APPLE_CLIENT_ID=com.lessonapp.app
APPLE_TEAM_ID=xxx
APPLE_KEY_ID=xxx
APPLE_PRIVATE_KEY_PATH=./keys/AuthKey_xxx.p8

# === Vultr Object Storage ===
VULTR_STORAGE_ENDPOINT=https://sgp1.vultrobjects.com
VULTR_STORAGE_ACCESS_KEY=xxx
VULTR_STORAGE_SECRET_KEY=xxx
VULTR_STORAGE_BUCKET=lesson-app-recordings

# === CORS ===
CORS_ORIGINS=["https://lesson-app.com"]

# === i18n ===
DEFAULT_LOCALE=ko
SUPPORTED_LOCALES=["ko","en","ja"]

# === Server ===
ENVIRONMENT=production
DEBUG=false
```

---

## 8. 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 502 Bad Gateway | uvicorn 미실행 | `systemctl restart lesson-app` |
| DB 연결 실패 | MySQL 미실행 또는 권한 | `systemctl status mysql` + 권한 확인 |
| 마이그레이션 충돌 | 브랜치 머지 후 | `alembic merge heads` |
| 메모리 부족 | workers 과다 | workers=2로 제한 |
| SSL 만료 | certbot 갱신 실패 | `certbot renew` |
| 파일 업로드 실패 | Nginx 크기 제한 | `client_max_body_size 50M` |
