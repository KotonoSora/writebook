# Docker Compose Commands

Compose files in this repository:

```bash
docker/docker-compose.local.yml
```

## Local Development

Use this file for local development/hot reload:

```bash
docker compose -f docker/docker-compose.local.yml up -d
```

Start and rebuild image:

```bash
docker compose -f docker/docker-compose.local.yml up -d --build
```

Start existing stopped containers:

```bash
docker compose -f docker/docker-compose.local.yml start
```

Stop running containers (keep containers/resources):

```bash
docker compose -f docker/docker-compose.local.yml stop
```

Stop and remove containers/network:

```bash
docker compose -f docker/docker-compose.local.yml down
```

Stop and remove containers/network/volumes (removes persisted volume data):

```bash
docker compose -f docker/docker-compose.local.yml down -v
```

Show running status:

```bash
docker compose -f docker/docker-compose.local.yml ps
```

Show logs:

```bash
docker compose -f docker/docker-compose.local.yml logs
```

Follow live logs:

```bash
docker compose -f docker/docker-compose.local.yml logs -f
```

## Restart vs Recreate

Use restart (same container config):

```bash
docker compose -f docker/docker-compose.local.yml restart
```

Use recreate after changing environment, ports, volumes, or service config:

```bash
docker compose -f docker/docker-compose.local.yml up -d --force-recreate
```

## Quick Workflows

Local development:

```bash
docker compose -f docker/docker-compose.local.yml up -d
docker compose -f docker/docker-compose.local.yml ps
docker compose -f docker/docker-compose.local.yml logs -f
docker compose -f docker/docker-compose.local.yml stop
```

Rebuild and restart local image:

```bash
docker compose -f docker/docker-compose.local.yml up -d --build
```

Changed environment, ports, volumes, or service config:

```bash
docker compose -f docker/docker-compose.local.yml up -d --force-recreate
```

## Utility

Generate `SECRET_KEY_BASE`:

```bash
openssl rand -hex 64
```

---

# Use these commands carefully. They are destructive.

## Stop and remove all containers
```bash
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
```

## Remove all images
```bash
docker rmi -f $(docker images -aq)
```

## One command to clean almost everything
```bash
docker system prune -a --volumes -f
```

What it removes:
1. stopped containers
2. unused networks
3. unused images
4. build cache
5. volumes if `--volumes` is included

## If you want remove all containers first, then all images
```bash
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -aq)
```

## If you only want clear exited containers
```bash
docker container prune -f
```

## If you only want clear unused images
```bash
docker image prune -a -f
```

## Recommended full reset
```bash
docker rm -f $(docker ps -aq)
docker system prune -a --volumes -f
```

Warning:
1. This can delete local databases, volumes, cached layers, and all containers.
2. If you are using this project with SQLite or Docker volumes, back up first.

If you want, I can give you:
1. safe cleanup commands
2. full reset commands
3. project-only cleanup commands
