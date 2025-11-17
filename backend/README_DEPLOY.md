# Despliegue del backend (Node.js + socket.io)

Este documento explica cómo desplegar el backend en una plataforma que soporte WebSockets persistentes (Render o Railway recomendados). También incluye las variables de entorno necesarias para producción.

Requisitos
- Repositorio en GitHub/GitLab/Bitbucket.
- Cuenta en Render (https://render.com) o Railway (https://railway.app).
- `DATABASE_URL` de Supabase (pg connection string).

Variables de entorno obligatorias
- `DATABASE_URL` — connection string completa de Postgres (p.ej. la de Supabase). Ej: `postgresql://user:pass@host:port/dbname`
- `PORT` — puerto del servicio (opcional, default 3000)
- `NODE_ENV` — `production`
- `JWT_SECRET` — secreto para firmar tokens (si lo usas)
- `CORS_ORIGIN` — origen permitido para CORS (ej. `https://tu-panel.vercel.app`)

Variables recomendadas
- `LOG_LEVEL`, `SMTP_*` si tu app envía correos, etc.

Despliegue en Render (rápido)
1. Subir tu repo a GitHub.
2. En Render, crea un nuevo **Web Service**.
   - Conecta tu cuenta de GitHub y selecciona el repo.
   - Branch: `main` (o la rama que uses).
   - Root Directory: deja vacío (o `backend` si quieres apuntar solo a la carpeta backend).
   - En *Environment*, selecciona `Docker` si usas `Dockerfile` (Render detectará el Dockerfile) o `Node` y configura Build/Start commands (`npm install` / `npm start`).
3. En Settings → Environment, agrega las variables de entorno listadas arriba (`DATABASE_URL`, `JWT_SECRET`, `CORS_ORIGIN`, etc.).
4. Deploy: Render hará build y levantará el servicio. Al terminar tendrás una URL pública como `https://mi-backend.onrender.com`.

Despliegue en Railway (alternativa)
1. Conecta tu repo desde Railway y crea un nuevo service (Web Service).
2. Railway detectará el proyecto Node; configura las environment variables en la interfaz (`DATABASE_URL`, etc.).
3. Deploy y obtendrás una URL pública.

Notas sobre WebSockets
- El backend usa socket.io; Render y Railway soportan WebSockets persistentes. Asegúrate de que el dominio del panel (Vercel) esté incluido en `CORS_ORIGIN` y en la configuración de socket.io si la limitas.

Configuración del panel (Vercel)
- Despliega `panel-gerente` en Vercel (sitio estático). En Vercel configura `PROJECT SETTINGS -> Environment Variables`:
  - `API_URL` = `https://mi-backend.onrender.com/api`
  - `WS_URL` = `https://mi-backend.onrender.com`

Comprobaciones locales
- Para probar localmente:
  - Asegúrate de tener `backend/.env` con `DATABASE_URL` apuntando a Supabase.
  - Ejecuta:
    ```powershell
    cd backend
    npm install
    npm start
    ```
  - Revisa la salida: deberías ver `Conectado a PostgreSQL` y la URL del servidor.

Soporte
- Si quieres, puedo:
  - Crear y subir este `Dockerfile` y este README (ya creado).
  - Preparar el `vercel.json` y scripts para generar `config.js` en `panel-gerente` (opcional).
