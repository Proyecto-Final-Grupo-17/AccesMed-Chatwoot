#!/usr/bin/env bash
# Publica (o actualiza) el sitio de Nginx de chat.accesmed.site en el servidor:
#   - deploy/nginx/chat.accesmed.site.conf -> /etc/nginx/sites-available/ (+ enlace en sites-enabled)
#   - deploy/publico/                      -> /var/www/chat.accesmed.site/ (politica de privacidad)
#
# Uso (como root, desde la carpeta del repo, con el certificado ya instalado):
#   ./scripts/publicar-sitio.sh
#
# Las paginas se copian a /var/www porque Nginx (usuario www-data) no puede leer /root.
# Si nginx -t falla, deja la configuracion anterior y no recarga Nginx.
set -euo pipefail
cd "$(dirname "$0")/.."

DOMINIO="${DOMINIO:-chat.accesmed.site}"
CONF_ORIGEN="deploy/nginx/$DOMINIO.conf"
CONF_DESTINO="/etc/nginx/sites-available/$DOMINIO"
CONF_ENLACE="/etc/nginx/sites-enabled/$DOMINIO"
WEB_DESTINO="/var/www/$DOMINIO"

[ -f "$CONF_ORIGEN" ] || { echo "No existe $CONF_ORIGEN" >&2; exit 1; }

echo "[1/3] Copiando paginas publicas a $WEB_DESTINO ..."
mkdir -p "$WEB_DESTINO"
cp -r deploy/publico/. "$WEB_DESTINO/"
chmod -R a+rX "$WEB_DESTINO"

echo "[2/3] Instalando la configuracion de Nginx..."
COPIA=""
if [ -f "$CONF_DESTINO" ]; then
  COPIA="$CONF_DESTINO.bak-$(date +%Y%m%d-%H%M%S)"
  cp -p "$CONF_DESTINO" "$COPIA"
fi
cp "$CONF_ORIGEN" "$CONF_DESTINO"
ln -sf "$CONF_DESTINO" "$CONF_ENLACE"

echo "[3/3] Probando y recargando Nginx..."
if nginx -t; then
  systemctl reload nginx
else
  if [ -n "$COPIA" ]; then
    cp -p "$COPIA" "$CONF_DESTINO"
    echo "nginx -t fallo: se restauro la configuracion anterior. Nginx NO se recargo." >&2
  else
    rm -f "$CONF_ENLACE"
    echo "nginx -t fallo: se quito el sitio nuevo. Nginx NO se recargo." >&2
  fi
  exit 1
fi

sleep 1
URL="https://$DOMINIO/privacidad/"
CODIGO="$(curl -s -o /dev/null -w '%{http_code}' --resolve "$DOMINIO:443:127.0.0.1" "$URL" || true)"
echo
echo "$URL -> HTTP $CODIGO"
if [ "$CODIGO" = "200" ]; then
  echo "Listo. URLs para la app de Meta:"
  echo "  Politica de privacidad:     $URL"
  echo "  Eliminacion de datos:       ${URL}#eliminacion-de-datos"
else
  echo "La pagina no respondio 200: revisa $WEB_DESTINO/privacidad/ y los logs de Nginx." >&2
  exit 1
fi
