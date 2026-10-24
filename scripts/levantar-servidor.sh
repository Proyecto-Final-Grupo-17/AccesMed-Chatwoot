#!/usr/bin/env bash
# Levanta (o actualiza) Chatwoot en el servidor Linux.
# Uso, desde la carpeta del repo:  ./scripts/levantar-servidor.sh
#
# Hace: pull de imagenes -> prepara/migra la base (db:chatwoot_prepare, se puede
# correr siempre) -> levanta todo -> espera a que la web responda.
# Sirve tanto para la primera instalacion como para actualizar de version.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Falta el .env. Generalo primero, por ejemplo:" >&2
  echo "  ./scripts/generar-env.sh http://chat.accesmed.site 3100" >&2
  exit 1
fi
PUERTO="$(grep -E '^CHATWOOT_PORT=' .env | cut -d= -f2- || true)"
PUERTO="${PUERTO:-3000}"

echo "[1/4] Descargando imagenes..."
docker compose pull

echo "[2/4] Levantando Postgres y Redis..."
docker compose up -d postgres redis
sleep 10

echo "[3/4] Preparando la base de datos..."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare

echo "[4/4] Levantando Chatwoot..."
docker compose up -d

echo "Esperando a que Chatwoot responda en 127.0.0.1:${PUERTO} ..."
for i in $(seq 1 60); do
  CODIGO="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PUERTO}/api" || true)"
  if [ "$CODIGO" = "200" ]; then
    echo "Chatwoot esta funcionando en 127.0.0.1:${PUERTO}"
    docker compose ps
    exit 0
  fi
  sleep 5
done
echo "Chatwoot no respondio despues de 5 minutos. Ultimos logs:" >&2
docker compose logs --tail 80 rails >&2
exit 1
