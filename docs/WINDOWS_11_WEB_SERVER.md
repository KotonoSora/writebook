# Storynest Production Guide on Windows 11

## 1. Goal

Run Storynest in production mode on a Windows 11 machine with Docker, then expose it through Cloudflare Tunnel.

This runbook uses:

1. `docker/docker-compose.prod.yml`
2. `.env.prod` at repository root

This runbook does not use `docker/docker-compose.local.yml`.

## 2. File Locations

Required files:

1. `docker/docker-compose.prod.yml`
2. `.env.prod` (at repo root)

Why this matters:

1. The compose file is in `docker/`.
2. It is configured to build from repo root and read env from `../.env.prod`.

## 3. Production Compose Configuration

Current `docker/docker-compose.prod.yml`:

```yml
services:
    writebook:
        build:
            context: ..
        container_name: storynest_prod

        ports:
            - "8080:80"

        env_file:
            - ../.env.prod

        environment:
            RAILS_ENV: production
            DISABLE_SSL: "true"

        volumes:
            - writebook_storage:/rails/storage
            - writebook_db:/rails/db

        restart: unless-stopped

        healthcheck:
            test: ["CMD-SHELL", "curl -fsS http://127.0.0.1/up || exit 1"]
            interval: 30s
            timeout: 5s
            retries: 5
            start_period: 20s

volumes:
    writebook_storage:
    writebook_db:
```

Notes:

1. No source bind mount in production.
2. `writebook_storage` persists uploaded files.
3. `writebook_db` persists SQLite database.
4. App listens on localhost port 8080.

## 4. Create `.env.prod`

At repository root, create `.env.prod` with at least:

```env
RAILS_ENV=production
DISABLE_SSL=true
APP_NAME=Storynest
APP_LOGO_ASSET=site-logo.svg
APP_VERSION=1.0.0
GIT_REVISION=1.0.1
SECRET_KEY_BASE=REPLACE_WITH_STRONG_SECRET
```

Generate strong `SECRET_KEY_BASE` example:

```bash
openssl rand -hex 64
```

or

```bash
# Unix
docker compose -f docker/docker-compose.local.yml run --rm -T --entrypoint /bin/sh writebook -lc "bin/rails secret; echo"

# Windows 11
docker compose -f docker/docker-compose.local.yml run --rm -T --entrypoint ruby writebook -e "require 'securerandom'; puts SecureRandom.hex(64)"

git config core.autocrlf false
git add --renormalize .
```

Notes:

1. Keep `.env.prod` private.
2. If Cloudflare terminates HTTPS, `DISABLE_SSL=true` is correct.

## 5. Start Production Stack

From repository root:

```bash
docker compose -f docker/docker-compose.prod.yml up -d --build
```

Check status:

```bash
docker compose -f docker/docker-compose.prod.yml ps
```

Check logs:

```bash
docker compose -f docker/docker-compose.prod.yml logs -f
```

Local check:

```bash
curl -I http://localhost:8080/session/new
```

## 6. Cloudflare Tunnel Setup

Install cloudflared (Windows):

```powershell
winget install --id Cloudflare.cloudflared
```

Login:

```powershell
cloudflared tunnel login
```

Create tunnel:

```powershell
cloudflared tunnel create storynest-prod
```

Create DNS route (example):

```powershell
cloudflared tunnel route dns storynest-prod books.yourdomain.com
```

Create config file:

`C:\Users\YOUR_USER\.cloudflared\config.yml`

```yml
tunnel: YOUR_TUNNEL_ID
credentials-file: C:\Users\YOUR_USER\.cloudflared\YOUR_TUNNEL_ID.json

ingress:
    - hostname: books.yourdomain.com
        service: http://localhost:8080
    - service: http_status:404
```

Run tunnel:

```powershell
cloudflared tunnel run storynest-prod
```

Public URL:

`https://books.yourdomain.com`

Optional Windows service:

```powershell
cloudflared service install
```

## 7. Update Process (Production)

### 7.1 Normal code update

```bash
git pull
docker compose -f docker/docker-compose.prod.yml up -d --build
```

### 7.2 If `.env.prod` changed

```bash
docker compose -f docker/docker-compose.prod.yml up -d --force-recreate writebook
```

Important:

1. `restart` does not apply changed env values.
2. Use recreate when environment or compose settings change.

## 8. Operations

Stop:

```bash
docker compose -f docker/docker-compose.prod.yml stop
```

Start again:

```bash
docker compose -f docker/docker-compose.prod.yml start
```

Down:

```bash
docker compose -f docker/docker-compose.prod.yml down
```

Do not use `down -v` unless you intentionally want to remove persistent data.

## 9. Downtime Expectations

With one production container, updates cause brief downtime during rebuild/recreate.

If you need near-zero downtime:

1. Run blue/green app containers on different ports.
2. Put Caddy or Nginx in front.
3. Switch upstream after health check.

## 10. Quick Checklist

1. `docker/docker-compose.prod.yml` is present
2. `.env.prod` exists at repo root with strong secret
3. App is reachable at `http://localhost:8080`
4. Cloudflare tunnel is configured and running
5. Public domain serves app over HTTPS
6. Team uses production update commands from this guide