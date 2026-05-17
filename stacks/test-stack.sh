#!/usr/bin/env bash
set -euo pipefail
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  echo "No .env file found. Run this script from the dns-core directory."
  exit 1
fi
set -a
source "$ENV_FILE"
set +a
DNS_SERVER="${DNS_BIND_IP:-127.0.0.1}"
DNS_TEST_PORT="${DNS_PORT:-53}"
WEB_TEST_PORT="${WEB_PORT:-8080}"
UNBOUND_TEST_IP="${UNBOUND_IP:-172.30.0.3}"
GITEA_TEST_PORT="${GITEA_WEB_PORT:-3001}"
echo "== Locals Only DNS + Gitea Stack Test =="
echo "DNS server: ${DNS_SERVER}"
echo "DNS port:   ${DNS_TEST_PORT}"
echo "Pi-hole UI: http://127.0.0.1:${WEB_TEST_PORT}/admin"
echo "Gitea UI:   http://127.0.0.1:${GITEA_TEST_PORT}"
echo
echo "== Docker containers =="
docker compose ps
echo
echo "== Testing Pi-hole UDP DNS =="
dig @"$DNS_SERVER" -p "$DNS_TEST_PORT" example.com +short
echo
echo "== Testing Pi-hole TCP DNS =="
dig +tcp @"$DNS_SERVER" -p "$DNS_TEST_PORT" example.com +short
echo
echo "== Testing pi.hole =="
dig @"$DNS_SERVER" -p "$DNS_TEST_PORT" pi.hole +short || true
echo
echo "== Testing Unbound from inside Pi-hole container =="
docker compose exec pihole dig @"$UNBOUND_TEST_IP" example.com +short
echo
echo "== Testing Pi-hole web UI =="
curl -I "http://127.0.0.1:${WEB_TEST_PORT}/admin" | head
echo
echo "== Testing Gitea web UI =="
curl -I "http://127.0.0.1:${GITEA_TEST_PORT}" | head
echo
echo "== Upstream configured in Pi-hole =="
docker compose exec pihole pihole-FTL --config dns.upstreams || true
echo
echo "== Local Git status =="
if [ -d ".git" ]; then
  git status --short
  git remote -v || true
else
  echo "No local .git directory yet. Initialize Git after Gitea setup."
fi
echo
echo "If DNS returned answers, Pi-hole and Gitea returned HTTP headers, and containers are running, the stack is working."
