# AccesMed — Chatwoot Community Edition

Configuración para levantar Chatwoot CE (open source, sin licencia) con Docker.
Repositorio: https://github.com/Proyecto-Final-Grupo-17/AccesMed-Chatwoot
Versión: **v4.18.0-ce** · URL: **http://localhost:3000**

## Requisitos

- **Docker Desktop** para Windows (con WSL 2): https://www.docker.com/products/docker-desktop/
- Unos 4 GB de RAM libres y ~5 GB de disco para las imágenes.

## Instalar desde este repositorio

1. Clonar: `git clone https://github.com/Proyecto-Final-Grupo-17/AccesMed-Chatwoot.git`
2. Abrir Docker Desktop y ejecutar `1-instalar.bat`.
   Si no existe el archivo `.env`, el instalador lo genera solo con **claves nuevas**
   a partir de `.env.example`.
3. Entrar a http://localhost:3000 y crear la cuenta de administrador.

Cada instalación tiene su **propia base de datos**: clonar el repo no copia las cuentas
ni las conversaciones de otra PC. Para que todos usen las mismas cuentas hay que
entrar a una misma instalación (el servidor, o la PC de alguien por red/túnel).

**En un servidor Linux:** `./scripts/generar-env.sh https://chat.tudominio.com`
genera el `.env` con la URL pública; después `docker compose pull`,
`docker compose run --rm rails bundle exec rails db:chatwoot_prepare` y `docker compose up -d`.

> El `.env` tiene claves y contraseñas: **nunca se sube a git** (está en `.gitignore`).

## Uso

| Archivo | Para qué |
|---|---|
| `1-instalar.bat` | Primera vez: descarga imágenes, crea la base de datos y levanta todo. |
| `2-iniciar.bat` | Levantar Chatwoot en el día a día. |
| `3-detener.bat` | Detenerlo (los datos se conservan). |
| `ver-logs.bat` | Ver el estado de los contenedores y los logs. |

Antes de cualquiera de ellos, Docker Desktop tiene que estar abierto ("Engine running").

La primera vez que entres a http://localhost:3000 vas a ver un formulario para crear
la cuenta de **administrador** (nombre, empresa, email y contraseña). Esa cuenta es el
Super Admin de tu instalación; desde ahí creás agentes, bandejas (inboxes), etc.

## Qué hay en la carpeta

- `docker-compose.yaml` — servicios: `rails` (web), `sidekiq` (tareas en segundo plano),
  `postgres` (base de datos, con pgvector) y `redis`.
- `.env.example` — plantilla de configuración sin claves (va al repo).
- `.env` — configuración con las **claves secretas de cada instalación**. No se sube ni se comparte.
- `scripts/generar-env.ps1` / `scripts/generar-env.sh` — generan el `.env` con claves nuevas (Windows / Linux).
- `referencia-oficial/` — plantillas originales de Chatwoot, para comparar al actualizar.

Los datos viven en volúmenes de Docker (`chatwoot_postgres_data`, `chatwoot_storage_data`,
`chatwoot_redis_data`), no en esta carpeta, así que OneDrive no interfiere.

## Datos útiles

- **Base de datos** (para DBeaver/pgAdmin): `localhost:5433`, usuario `postgres`,
  contraseña = `POSTGRES_PASSWORD` del `.env`, base `chatwoot_production`.
- **Idioma por defecto:** español (`DEFAULT_LOCALE=es`).
- **Registro público desactivado** (`ENABLE_ACCOUNT_SIGNUP=false`): los usuarios nuevos los crea el admin.
- **Email:** no hay SMTP configurado, así que no salen mails (invitaciones, recuperar contraseña).
  Para habilitarlo completá las variables `SMTP_*` del `.env` (por ejemplo con una cuenta de Gmail y
  contraseña de aplicación) y reiniciá con `docker compose up -d`.
- **Canales:** de forma local funcionan el widget de chat web, la API y el email. WhatsApp,
  Facebook, Instagram, Telegram, etc. necesitan una URL pública con HTTPS (dominio + Nginx,
  o un túnel como Cloudflare Tunnel / ngrok).

## Acceder desde otras PCs de la red

1. En `docker-compose.yaml`, servicio `rails`, cambiar `'127.0.0.1:3000:3000'` por `'3000:3000'`.
2. En `.env`, poner `FRONTEND_URL=http://<IP-de-esta-PC>:3000`.
3. `docker compose up -d` y permitir el puerto 3000 en el firewall de Windows.

## Actualizar de versión

1. Cambiar el tag `v4.18.0-ce` en `docker-compose.yaml` por el nuevo (siempre con sufijo `-ce`;
   lista en https://hub.docker.com/r/chatwoot/chatwoot/tags?name=ce).
2. En una terminal dentro de esta carpeta:
   ```
   docker compose pull
   docker compose up -d
   docker compose run --rm rails bundle exec rails db:chatwoot_prepare
   ```

## Comandos útiles

```
docker compose ps                         # estado
docker compose logs -f rails              # logs de la web
docker exec -it chatwoot-rails-1 sh -c "RAILS_ENV=production bundle exec rails c"   # consola Rails
docker compose down -v                    # BORRA TODO (incluidos los datos)
```

Documentación oficial: https://developers.chatwoot.com/self-hosted/deployment/docker
