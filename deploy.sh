#!/usr/bin/env bash
#
# Rebuild and (re)start the hetzner-stack containers.
#
#   ./deploy.sh                rebuild + restart both services
#   ./deploy.sh api            rebuild + restart only the Go API
#   ./deploy.sh web            rebuild + restart only the Next.js frontend
#   ./deploy.sh --pull         git pull first, then rebuild only what changed
#   ./deploy.sh --pull all     git pull first, then rebuild both regardless
#
set -euo pipefail
cd "$(dirname "$0")"

# --- how to call docker: plain if we can reach the daemon, else via sudo ---
if docker info >/dev/null 2>&1; then
  DC="docker compose"
else
  DC="sudo docker compose"
fi
DOCKER="${DC% compose}"   # "docker" or "sudo docker"

# --- parse args ----------------------------------------------------------
PULL=0
TARGET="${1:-}"
if [[ "$TARGET" == "--pull" ]]; then
  PULL=1
  TARGET="${2:-}"
fi

SERVICES=()

if [[ "$PULL" == "1" ]]; then
  git rev-parse HEAD >/dev/null 2>&1 || { echo "no commits in this repo yet"; exit 1; }
  before=$(git rev-parse HEAD)
  git pull --ff-only
  after=$(git rev-parse HEAD)

  case "$TARGET" in
    api|web) SERVICES=("$TARGET") ;;
    all)     SERVICES=(api web) ;;
    "")
      if [[ "$before" == "$after" ]]; then
        echo "already up to date — nothing pulled, nothing to rebuild"
        exit 0
      fi
      changed=$(git diff --name-only "$before" "$after")
      if grep -q '^backend/'  <<<"$changed"; then SERVICES+=(api); fi
      if grep -q '^frontend/' <<<"$changed"; then SERVICES+=(web); fi
      if grep -q '^docker-compose\.yml$' <<<"$changed"; then SERVICES=(api web); fi
      if [[ ${#SERVICES[@]} -eq 0 ]]; then
        echo "no backend/ or frontend/ changes in ${before:0:7}..${after:0:7} — nothing to rebuild"
        exit 0
      fi
      ;;
    *) echo "usage: $0 [--pull] [api|web|all]" >&2; exit 2 ;;
  esac
else
  case "$TARGET" in
    api|web) SERVICES=("$TARGET") ;;
    ""|all)  SERVICES=(api web) ;;
    *) echo "usage: $0 [--pull] [api|web|all]" >&2; exit 2 ;;
  esac
fi

echo "==> rebuilding: ${SERVICES[*]}"
$DC up -d --build "${SERVICES[@]}"

echo "==> pruning dangling images"
$DOCKER image prune -f

echo "==> status"
$DC ps

# --- health checks -----------------------------------------------------
echo "==> health"
ok=0
for i in $(seq 1 15); do
  if body=$(curl -fsS http://127.0.0.1:8080/healthz 2>/dev/null); then
    echo "api  ok   $body"
    ok=1
    break
  fi
  sleep 1
done
if [[ "$ok" != "1" ]]; then
  echo "api  FAIL  /healthz never came up"
  $DC logs --tail 50 api
  exit 1
fi

code=$(curl -fsS -o /dev/null -w '%{http_code}' http://127.0.0.1:3000 || true)
if [[ "$code" == "200" ]]; then
  echo "web  ok   200 on :3000"
else
  echo "web  WARN got '$code' on :3000"
  $DC logs --tail 50 web
fi

echo "==> done"
