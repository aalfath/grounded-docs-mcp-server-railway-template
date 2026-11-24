#!/bin/sh
# Starts Grounded Docs MCP Server on loopback and Caddy in front of it.
# Caddy asks for WEB_USERNAME/WEB_PASSWORD on the web UI and for
# "Authorization: Bearer MCP_AUTH_TOKEN" on /mcp. If either process stops,
# the container exits non-zero so Railway restarts it.
set -eu

: "${PORT:=8080}"
export PORT
APP_PORT=6281

fail() { echo "start.sh: $*" >&2; exit 1; }

[ -n "${MCP_AUTH_TOKEN:-}" ] && [ "${#MCP_AUTH_TOKEN}" -ge 24 ] \
  || fail "MCP_AUTH_TOKEN must be set (24+ characters); the template generates one."
case "$MCP_AUTH_TOKEN" in *[!A-Za-z0-9_-]*) fail "MCP_AUTH_TOKEN may only use letters, digits, '-' and '_'." ;; esac
[ -n "${WEB_PASSWORD:-}" ] && [ "${#WEB_PASSWORD}" -ge 12 ] \
  || fail "WEB_PASSWORD must be set (12+ characters); the template generates one."
export WEB_USERNAME="${WEB_USERNAME:-admin}"
case "$WEB_USERNAME" in ""|*[!A-Za-z0-9._@-]*) fail "WEB_USERNAME may only use letters, digits and . _ @ -" ;; esac

# Everything the app keeps lives on the volume at /data.
mkdir -p /data/config
chown -R node:node /data 2>/dev/null || true

# The server only answers Host names it knows and checks the browser Origin
# against its public URL, so tell it the Railway domain unless the deployer
# set a custom one.
if [ -z "${DOCS_MCP_SERVER_PUBLIC_URL:-}" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  export DOCS_MCP_SERVER_PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

# Sizing for small plans: read the memory limit from the cgroup.
MEM_MB=0
if [ -r /sys/fs/cgroup/memory.max ]; then
  m=$(cat /sys/fs/cgroup/memory.max)
  [ "$m" != "max" ] && MEM_MB=$((m / 1024 / 1024))
fi
if [ "$MEM_MB" -gt 0 ] && [ "$MEM_MB" -lt 1500 ]; then
  # One page at a time keeps Chromium's renderer inside 0.5-1 GB.
  : "${DOCS_MCP_SCRAPER_MAX_CONCURRENCY:=1}"
  export DOCS_MCP_SCRAPER_MAX_CONCURRENCY
  export CHROMIUM_LOW_MEMORY=1
  heap=$((MEM_MB * 40 / 100))
  [ "$heap" -lt 160 ] && heap=160
  case " ${NODE_OPTIONS:-} " in *max-old-space-size*) ;; *) export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=$heap" ;; esac
fi
export DOCS_MCP_TELEMETRY="${DOCS_MCP_TELEMETRY:-false}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
# An OpenAI-compatible key turns on vector search; without one the server uses full-text search.
[ -z "${OPENAI_API_KEY:-}" ] && unset OPENAI_API_KEY
[ -z "${OPENAI_API_BASE:-}" ] && unset OPENAI_API_BASE
[ -z "${DOCS_MCP_EMBEDDING_MODEL:-}" ] && unset DOCS_MCP_EMBEDDING_MODEL

WEB_PASSWORD_HASH=$(caddy hash-password --plaintext "$WEB_PASSWORD") || fail "could not hash WEB_PASSWORD"
export WEB_PASSWORD_HASH
unset WEB_PASSWORD

# Keep the server and Caddy out of the kernel's OOM choice; the Chromium
# wrapper raises its own score, so a heavy page kills only its render.
echo -900 > /proc/self/oom_score_adj 2>/dev/null || echo "start.sh: could not lower oom_score_adj (continuing)" >&2

RUN="env HOME=/home/node setpriv --reuid=node --regid=node --init-groups"

$RUN node --enable-source-maps dist/index.js server \
  --protocol http --host 127.0.0.1 --port "$APP_PORT" --no-logo &
APP_PID=$!

# Caddy holds only the bearer token and the password hash, not the provider keys.
env -u OPENAI_API_KEY -u GOOGLE_API_KEY XDG_DATA_HOME=/tmp/caddy-data $RUN caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'kill "$APP_PID" "$CADDY_PID" 2>/dev/null; exit 0' TERM INT

# BusyBox-style shells may not return from `wait -n` on the first exit, so poll.
while kill -0 "$APP_PID" 2>/dev/null && kill -0 "$CADDY_PID" 2>/dev/null; do
  sleep 2
done
echo "start.sh: a process stopped unexpectedly; exiting so Railway restarts the service." >&2
kill "$APP_PID" "$CADDY_PID" 2>/dev/null || true
exit 1
