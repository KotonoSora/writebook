# Docker Compose Commands

Run these commands from the project folder:

```bash
cd /Users/thangnguyen/kotonosora/tools/writebook
```

Compose file used in this project:

```bash
-f docker-compose.local.yml
```

## Start

Start containers in background:

```bash
docker compose -f docker-compose.local.yml up -d
```

Start and rebuild image:

```bash
docker compose -f docker-compose.local.yml up -d --build
```

Start existing stopped containers:

```bash
docker compose -f docker-compose.local.yml start
```

## Stop

Stop running containers (keep containers/resources):

```bash
docker compose -f docker-compose.local.yml stop
```

Stop and remove containers/network:

```bash
docker compose -f docker-compose.local.yml down
```

Stop and remove containers/network/volumes (this removes persisted volume data):

```bash
docker compose -f docker-compose.local.yml down -v
```

## Restart

```bash
docker compose -f docker-compose.local.yml restart
```

## Status and logs

Show running status:

```bash
docker compose -f docker-compose.local.yml ps
```

Show logs:

```bash
docker compose -f docker-compose.local.yml logs
```

Follow live logs:

```bash
docker compose -f docker-compose.local.yml logs -f
```

## Quick workflow

```bash
# start
docker compose -f docker-compose.local.yml up -d

# check status
docker compose -f docker-compose.local.yml ps

# watch logs
docker compose -f docker-compose.local.yml logs -f

# stop when done
docker compose -f docker-compose.local.yml stop
# or cleanup completely:
# docker compose -f docker-compose.local.yml down
```

---

```bash
# create secret key base
openssl rand -hex 64
```
