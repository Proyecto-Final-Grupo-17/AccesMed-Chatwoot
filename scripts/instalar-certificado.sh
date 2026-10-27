#!/usr/bin/env bash
# Instala (o renueva) el certificado SSL de chat.accesmed.site en el servidor.
#
# Uso (como root, con los 3 archivos descargados de DonWeb > Certificados SSL > Gestionar):
#   ./scripts/instalar-certificado.sh chat.crt chat.key intermedio.crt
#
# Verifica que el certificado sea del dominio, que la clave corresponda y que no tenga
# contrasena; guarda una copia de los archivos anteriores; arma fullchain.crt
# (certificado + intermedio) y recarga Nginx. Los archivos de origen no se borran.
set -euo pipefail

DOMINIO="${DOMINIO:-chat.accesmed.site}"
DESTINO="${CERT_DIR:-/etc/ssl/$DOMINIO}"

if [ "$#" -ne 3 ]; then
  echo "Uso: $0 <certificado.crt> <clave.key> <intermedio.crt>" >&2
  exit 1
fi
CERT="$1"; CLAVE="$2"; INTERMEDIO="$3"
for f in "$CERT" "$CLAVE" "$INTERMEDIO"; do
  [ -s "$f" ] || { echo "No existe o esta vacio: $f" >&2; exit 1; }
done

echo "[1/4] Verificando archivos..."
openssl x509 -in "$CERT" -noout >/dev/null 2>&1 || { echo "$CERT no es un certificado PEM valido." >&2; exit 1; }
openssl x509 -in "$INTERMEDIO" -noout >/dev/null 2>&1 || { echo "$INTERMEDIO no es un certificado PEM valido." >&2; exit 1; }
openssl pkey -in "$CLAVE" -passin pass: -noout >/dev/null 2>&1 \
  || { echo "$CLAVE no es una clave valida o tiene contrasena (Nginx necesita una sin contrasena)." >&2; exit 1; }
openssl x509 -in "$CERT" -noout -checkhost "$DOMINIO" | grep -q 'does match' \
  || { echo "El certificado no es para $DOMINIO." >&2; exit 1; }
PUB_CERT="$(openssl x509 -in "$CERT" -noout -pubkey | openssl sha256)"
PUB_CLAVE="$(openssl pkey -in "$CLAVE" -pubout | openssl sha256)"
[ "$PUB_CERT" = "$PUB_CLAVE" ] || { echo "La clave no corresponde al certificado." >&2; exit 1; }

echo "[2/4] Guardando copia de los archivos anteriores (si hay)..."
mkdir -p "$DESTINO"
FECHA="$(date +%Y%m%d-%H%M%S)"
for f in fullchain.crt privkey.key; do
  [ -f "$DESTINO/$f" ] && cp -p "$DESTINO/$f" "$DESTINO/$f.bak-$FECHA"
done

echo "[3/4] Instalando en $DESTINO ..."
{ cat "$CERT"; echo; cat "$INTERMEDIO"; } > "$DESTINO/fullchain.crt"
install -m 600 "$CLAVE" "$DESTINO/privkey.key"
chmod 644 "$DESTINO/fullchain.crt"

echo "[4/4] Recargando Nginx..."
if nginx -t; then
  systemctl reload nginx
else
  echo "nginx -t fallo: Nginx NO se recargo. Revisa la configuracion; las copias anteriores quedaron como *.bak-$FECHA" >&2
  exit 1
fi

echo
echo "Certificado instalado para $DOMINIO:"
openssl x509 -in "$DESTINO/fullchain.crt" -noout -issuer -enddate
echo "Anota la fecha de vencimiento (notAfter): antes de esa fecha hay que reemitirlo en DonWeb."
