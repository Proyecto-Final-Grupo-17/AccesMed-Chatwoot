#!/usr/bin/env bash
# Genera .env a partir de .env.example con claves nuevas (Linux / servidor).
# Uso:  ./scripts/generar-env.sh [URL_PUBLICA]
#   ej: ./scripts/generar-env.sh https://chat.accesmed.com
# Sin argumento deja FRONTEND_URL=http://localhost:3000
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -f .env ]; then
  echo ".env ya existe; no se modifica. Borralo o renombralo si queres generar uno nuevo." >&2
  exit 1
fi
command -v openssl >/dev/null || { echo "Falta openssl (apt install openssl)." >&2; exit 1; }

cp .env.example .env
chmod 600 .env

poner() { sed -i "s|^$1=.*|$1=$2|" .env; }

poner SECRET_KEY_BASE "$(openssl rand -hex 64)"
poner ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY "$(openssl rand -hex 16)"
poner ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY "$(openssl rand -hex 16)"
poner ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT "$(openssl rand -hex 16)"
poner REDIS_PASSWORD "$(openssl rand -hex 16)"
poner POSTGRES_PASSWORD "$(openssl rand -hex 16)"

if [ "${1:-}" != "" ]; then
  poner FRONTEND_URL "$1"
fi

echo ".env generado con claves nuevas (FRONTEND_URL=$(grep '^FRONTEND_URL=' .env | cut -d= -f2-))."
echo "Revisa SMTP_* si queres que Chatwoot envie mails."
