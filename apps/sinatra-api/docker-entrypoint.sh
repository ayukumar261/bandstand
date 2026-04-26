#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" && -n "${DB_PASSWORD:-}" ]]; then
  ENC_PW=$(ruby -ruri -e 'print URI.encode_www_form_component(ENV["DB_PASSWORD"])')
  export DATABASE_URL="postgres://${DB_USER}:${ENC_PW}@/${DB_NAME}?host=${DB_SOCKET_DIR}"
fi

exec bundle exec rackup config.ru -p "${PORT:-8080}" -o 0.0.0.0 -q
