# hetzner-stack

Next.js frontend + Go (chi) API, each containerized, deployed on a Hetzner VPS
behind the host's nginx (which terminates TLS).

```
hetzner.pratham82.in       -> host nginx -> 127.0.0.1:3000  web (Next.js standalone)
api.hetzner.pratham82.in   -> host nginx -> 127.0.0.1:8080  api (Go + chi)
```

## Layout

- `frontend/` — Next.js app, `output: "standalone"`, multi-stage Dockerfile.
- `backend/`  — Go + chi API (`/healthz`, `/api/hello`), multi-stage Dockerfile.
- `docker-compose.yml` — builds both, binds ports to `127.0.0.1` only.
- `.env` — `NEXT_PUBLIC_API_URL` (git-ignored; baked into the web image at build time).

## Local run

```bash
# backend only
cd backend && go run .        # http://localhost:8080/api/hello

# frontend only (talks to localhost:8080 by default)
cd frontend && npm install && npm run dev
```

## Full stack via Docker

```bash
docker compose build
docker compose up -d
docker compose ps
curl -s http://127.0.0.1:8080/healthz
curl -sI http://127.0.0.1:3000
```

## Deploy (manual, until CI/CD exists)

Use the helper script (rebuilds the image, recreates the container, prunes
dangling images, runs health checks):

```bash
./deploy.sh            # rebuild + restart both
./deploy.sh api        # only the Go API
./deploy.sh web        # only the frontend
./deploy.sh --pull     # git pull first, rebuild only the service that changed
```

Equivalent by hand:

```bash
git pull
docker compose up -d --build
docker image prune -f
```

## Notes

- `NEXT_PUBLIC_API_URL` is compiled into the frontend bundle. Changing it means
  `docker compose build web`, not just a restart.
- Never publish ports without the `127.0.0.1:` prefix — nginx is the only front door.
- nginx server blocks live on the host (`/etc/nginx/`), not in this repo.
