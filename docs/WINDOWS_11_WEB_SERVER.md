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

To expose your app to the public internet, use Cloudflare Tunnel. You can run cloudflared natively on Windows or as a Docker container. Choose the method that fits your deployment.

### 6a. Cloudflare Tunnel (Windows)

1. Install cloudflared:
    ```powershell
    winget install --id Cloudflare.cloudflared
    ```

2. Login to Cloudflare:
    ```powershell
    cloudflared tunnel login
    ```

3. Create a tunnel:
    ```powershell
    cloudflared tunnel create storynest-prod
    ```

4. Create a DNS route (example):
    ```powershell
    cloudflared tunnel route dns storynest-prod books.yourdomain.com
    ```

5. Create config file:
    `C:\Users\YOUR_USER\.cloudflared\config.yml`
    ```yml
    tunnel: YOUR_TUNNEL_ID
    credentials-file: C:/Users/YOUR_USER/.cloudflared/YOUR_TUNNEL_ID.json

    ingress:
      - hostname: books.yourdomain.com
         service: http://localhost:8080
      - service: http_status:404
    ```

6. Run the tunnel:
    ```powershell
    cloudflared tunnel run storynest-prod
    ```

7. Public URL:
    `https://books.yourdomain.com`

---

**Notes:**
- Use `localhost:8080` for the service if running cloudflared natively on Windows.
- If you want to run cloudflared as a Docker container, see the next section.

### 6b. Cloudflare Tunnel as a Docker Container

If you want to run Cloudflare Tunnel (cloudflared) as a Docker container (recommended for production automation), follow these steps:

1. **Create a user-defined Docker network (if not already):**
    ```powershell
    docker network create storynest-net
    ```

2. **Ensure your production Compose file joins this network.**
    Add the following to your `docker-compose.prod.yml`:
    ```yaml
    services:
      writebook:
         # ...existing config...
         networks:
            - storynest-net
    networks:
      storynest-net:
         external: true
    ```

3. **Start your app stack:**
    ```powershell
    docker compose -f docker/docker-compose.prod.yml up -d --build
    ```

4. **Run cloudflared in a container on the same network:**

        **Option 1: With local config file (advanced, for multiple tunnels or custom ingress):**
        ```powershell
        docker run -d --name cloudflared \
            --network storynest-net \
            -v C:/Users/YOUR_USER/.cloudflared:/etc/cloudflared \
            cloudflare/cloudflared:latest tunnel run storynest-prod
        ```

        **Option 2: With Cloudflare token (simple, no local config needed):**
        ```powershell
        docker run -d --name cloudflared \
            --network storynest-net \
            cloudflare/cloudflared:latest tunnel --no-autoupdate run --token <YOUR_TOKEN_HERE>
        ```

        Replace `<YOUR_TOKEN_HERE>` with your Cloudflare Tunnel token. This method does not require a config file or volume mount.

5. **Update your cloudflared config file (`C:/Users/YOUR_USER/.cloudflared/config.yml`):**
    ```yml
    tunnel: YOUR_TUNNEL_ID
    credentials-file: C:/Users/YOUR_USER/.cloudflared/YOUR_TUNNEL_ID.json

    ingress:
      - hostname: books.yourdomain.com
         service: http://storynest_prod:80
      - service: http_status:404
    ```

6. **Public URL:**
    `https://books.yourdomain.com`

---

**Notes:**
- Use the Docker Compose service/container name (`storynest_prod`) and port 80 for the service in your config, not `localhost:8080`.
- Both containers must be on the same Docker network for communication.
- You can still use the Windows service method if running cloudflared natively, but for Dockerized cloudflared, use the above approach.





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