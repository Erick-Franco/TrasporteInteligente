# 🔥 Guía de Migración de Datos a Firebase

## Paso 1: Descargar Service Account Key

1. Ve a [Firebase Console](https://console.firebase.google.com/project/trasnporteinteligente/settings/serviceaccounts/adminsdk)
2. Clic en la pestaña **"Service accounts"**
3. Clic en **"Generate new private key"**
4. Confirma y descarga el archivo JSON
5. **Renombra el archivo a `firebase-service-account.json`**
6. **Guárdalo en:** `d:\Programacion\transporte_inteligente\firebase-service-account.json`

⚠️ **IMPORTANTE**: Este archivo contiene credenciales sensibles. NO lo subas a Git.

---

## Paso 2: Crear archivo .env

Crea un archivo `.env` en `d:\Programacion\transporte_inteligente\.env` con tu conexión a PostgreSQL:

```env
DATABASE_URL=postgresql://usuario:contraseña@host:puerto/database
```

### Ejemplo con Supabase:
```env
DATABASE_URL=postgresql://postgres.xxxxx:tu_password@aws-0-us-east-1.pooler.supabase.com:5432/postgres
```

---

## Paso 3: Instalar Dependencias

```bash
cd d:\Programacion\transporte_inteligente
npm install firebase-admin pg dotenv
```

---

## Paso 4: Habilitar Servicios en Firebase Console

Antes de migrar, asegúrate de habilitar:

### a) Authentication
1. Ve a **Build → Authentication**
2. Clic en **"Get started"**
3. Habilita **"Email/Password"**

### b) Firestore Database
1. Ve a **Build → Firestore Database**
2. Clic en **"Create database"**
3. Selecciona **"Start in production mode"**
4. Ubicación: **us-central** (o la más cercana)

### c) Realtime Database
1. Ve a **Build → Realtime Database**
2. Clic en **"Create database"**
3. Ubicación: **United States (us-central1)**
4. Selecciona **"Start in locked mode"**

---

## Paso 5: Ejecutar Migración

```bash
cd d:\Programacion\transporte_inteligente
node migrate_to_firebase.js
```

El script migrará:
- ✅ Rutas
- ✅ Puntos de control
- ✅ Vehículos
- ✅ Conductores (con cuentas en Firebase Auth)
- ✅ Gerentes (con cuentas en Firebase Auth)
- ✅ Viajes (últimos 30 días)
- ✅ Mensajes de chat (últimos 7 días)

---

## Paso 6: Verificar Datos

1. Ve a [Firebase Console](https://console.firebase.google.com/project/trasnporteinteligente/firestore)
2. Verifica que las colecciones se crearon:
   - `rutas`
   - `puntos_control`
   - `vehiculos`
   - `conductores`
   - `gerentes`
   - `viajes`
   - `mensajes_chat`

3. Ve a **Authentication** y verifica que se crearon los usuarios

---

## Paso 7: Configurar Reglas de Seguridad

### Firestore Rules

Ve a **Firestore Database → Rules** y pega:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rutas/{rutaId} {
      allow read: if true;
      allow write: if false;
    }
    
    match /puntos_control/{puntoId} {
      allow read: if true;
      allow write: if false;
    }
    
    match /vehiculos/{vehiculoId} {
      allow read: if true;
      allow write: if false;
    }
    
    match /conductores/{conductorId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == conductorId;
    }
    
    match /gerentes/{gerenteId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == gerenteId;
    }
    
    match /viajes/{viajeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.conductor_id;
    }
    
    match /mensajes_chat/{mensajeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

### Realtime Database Rules

Ve a **Realtime Database → Rules** y pega:

```json
{
  "rules": {
    "ubicaciones_tiempo_real": {
      "$conductor_id": {
        ".read": true,
        ".write": "$conductor_id === auth.uid"
      }
    }
  }
}
```

---

## ⚠️ Solución de Problemas

### Error: "Cannot find module 'firebase-admin'"
```bash
npm install firebase-admin pg dotenv
```

### Error: "ENOENT: no such file or directory, open './firebase-service-account.json'"
- Verifica que el archivo esté en la raíz del proyecto
- Verifica que se llame exactamente `firebase-service-account.json`

### Error: "Connection refused" (PostgreSQL)
- Verifica que tu `DATABASE_URL` sea correcta
- Verifica que tengas acceso a la base de datos

### Error: "auth/email-already-exists"
- El script maneja esto automáticamente y actualiza los datos existentes

---

## 📊 Después de la Migración

1. **Probar la app móvil:**
   ```bash
   cd mobile_app
   flutter run
   ```

2. **Verificar login de conductores** con los emails migrados

3. **Verificar que el GPS se envíe** a Realtime Database

4. **Verificar chat en tiempo real** en Firestore

---

## 🔒 Seguridad

- ✅ Agrega `firebase-service-account.json` a `.gitignore`
- ✅ Agrega `.env` a `.gitignore`
- ✅ Nunca compartas estas credenciales
- ✅ Configura las reglas de seguridad antes de usar en producción
