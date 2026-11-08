#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
compose() { docker compose "$@"; }
load_env() {
  if [[ ! -f .env ]]; then cp .env.example .env; fi
  # This file is generated locally by this lab; do not source untrusted .env files.
  source .env
}
save_env() { printf 'STABLE_IMAGE=%s\nCANARY_IMAGE=%s\n' "$STABLE_IMAGE" "$CANARY_IMAGE" > .env; }
config_client() {
  local number="$1" target="$2"
  cat > "routing/client${number}.conf" <<EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://${target}:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        add_header Cache-Control "no-store" always;
    }
}
EOF
}
reload_clients() {
  for n in 1 2 3; do
    compose exec -T "client$n" nginx -s reload >/dev/null
  done
}
validate_image() {
  [[ "$1" =~ ^ghcr\.io/[a-z0-9_.-]+/[a-z0-9_.-]+:sha-[0-9a-f]{40}$ ]] || {
    echo "Expected owner/repo and FULL 40-character Git commit SHA." >&2; exit 1;
  }
}
image_from_args() {
  [[ $# == 3 ]] || { echo "Usage: $0 $COMMAND GITHUB_OWNER REPO FULL_SHA"; exit 1; }
  IMAGE="ghcr.io/${1,,}/${2,,}:sha-${3,,}"
  validate_image "$IMAGE"
}
case "${1:-help}" in
  init)
    load_env
    docker build -t cicd-lab:local .
    config_client 1 stable; config_client 2 stable; config_client 3 stable
    compose up -d --no-build
    echo "Open http://localhost:8081 http://localhost:8082 http://localhost:8083"
    ;;
  deploy-stable)
    COMMAND=$1; shift; image_from_args "$@"; load_env
    docker pull "$IMAGE"
    STABLE_IMAGE="$IMAGE"; save_env
    compose up -d --no-build stable
    reload_clients
    echo "Stable now $STABLE_IMAGE"
    ;;
  deploy-canary)
    COMMAND=$1; shift; image_from_args "$@"; load_env
    docker pull "$IMAGE"
    CANARY_IMAGE="$IMAGE"; save_env
    compose up -d --no-build canary
    reload_clients
    echo "Canary now $CANARY_IMAGE"
    ;;
  route-canary)
    load_env
    config_client 1 canary
    compose exec -T client1 nginx -s reload
    echo "Client 1 -> canary; clients 2 and 3 -> stable"
    ;;
  route-stable)
    config_client 1 stable
    compose exec -T client1 nginx -s reload
    echo "All clients -> stable"
    ;;
  promote)
    load_env
    [[ "$STABLE_IMAGE" != "$CANARY_IMAGE" ]] || { echo "Stable and canary are already the same image."; exit 1; }
    printf '%s\n' "$STABLE_IMAGE" > .previous-stable-image
    STABLE_IMAGE="$CANARY_IMAGE"; save_env
    compose up -d --no-build stable
    config_client 1 stable
    reload_clients
    echo "All clients now receive $STABLE_IMAGE"
    ;;
  rollback)
    load_env
    if [[ -f .previous-stable-image ]]; then
      STABLE_IMAGE="$(cat .previous-stable-image)"
      save_env
      compose up -d --no-build stable
      echo "Restored previous stable image: $STABLE_IMAGE"
    fi
    config_client 1 stable
    reload_clients
    echo "All clients -> stable"
    ;;
  status)
    load_env
    echo "STABLE=$STABLE_IMAGE"
    echo "CANARY=$CANARY_IMAGE"
    compose ps
    for n in 1 2 3; do
      printf 'client%s: ' "$n"
      curl -fsS "http://localhost:808$n/api/info" || true
      printf '\n'
    done
    ;;
  stop) compose down ;;
  *)
    echo "Usage: ./scripts/lab.sh {init|deploy-stable OWNER REPO SHA|deploy-canary OWNER REPO SHA|route-canary|route-stable|promote|rollback|status|stop}"
    ;;
esac
