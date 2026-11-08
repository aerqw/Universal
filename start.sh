#!/bin/bash
set -Eeuo pipefail

echo "Starting 3x-ui with nginx reverse proxy..."

# PORT is supplied by many PaaS platforms. Keep 3000 as the Docker default.
export PORT="${PORT:-3000}"
export PANEL_PORT="${PANEL_PORT:-2053}"
export SUB_PORT="${SUB_PORT:-2096}"
export INBOUND_PORT="${INBOUND_PORT:-8080}"
export WEB_BASE_PATH="${WEB_BASE_PATH:-/managepanel/}"

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || ! [[ "$PANEL_PORT" =~ ^[0-9]+$ ]] \
   || ! [[ "$SUB_PORT" =~ ^[0-9]+$ ]] || ! [[ "$INBOUND_PORT" =~ ^[0-9]+$ ]]; then
    echo "PORT, PANEL_PORT, SUB_PORT and INBOUND_PORT must be numeric." >&2
    exit 1
fi

cd /usr/local/x-ui

echo "Applying panel settings..."
./x-ui setting -port "$PANEL_PORT" -webBasePath "$WEB_BASE_PATH" || true

echo "Generating nginx config (public port: ${PORT})..."
envsubst '${PORT} ${PANEL_PORT} ${SUB_PORT} ${INBOUND_PORT} ${WEB_BASE_PATH}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Starting x-ui..."
./x-ui &
X_UI_PID=$!

cleanup() {
    echo "Stopping services..."
    kill "$X_UI_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Give x-ui a moment to initialize before nginx starts.
sleep 2
if ! kill -0 "$X_UI_PID" 2>/dev/null; then
    echo "x-ui exited during startup." >&2
    wait "$X_UI_PID" || true
    exit 1
fi

nginx -t
nginx -g "daemon off;" &
NGINX_PID=$!

# Exit if either main process exits; the container should not look healthy
# while one half of the service is down.
set +e
wait -n "$X_UI_PID" "$NGINX_PID"
STATUS=$?
set -e
kill "$X_UI_PID" "$NGINX_PID" 2>/dev/null || true
wait "$X_UI_PID" "$NGINX_PID" 2>/dev/null || true
exit "$STATUS"
