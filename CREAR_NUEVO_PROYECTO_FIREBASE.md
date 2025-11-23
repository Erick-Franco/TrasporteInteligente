    # 🔥 Guía: Crear Nuevo Proyecto Firebase (Modo Native)

## Paso 1: Crear el Proyecto

1. Ve a: https://console.firebase.google.com/
2. Clic en **"Agregar proyecto"** o **"Create a project"**
3. **Nombre del proyecto:** `transporte-inteligente-app`
4. Clic en **"Continuar"**
5. **Google Analytics:** Puedes deshabilitarlo (opcional)
6. Clic en **"Crear proyecto"**
7. Espera 30-60 segundos mientras se crea
8. Clic en **"Continuar"**

---

## Paso 2: Habilitar Firestore Database (MODO NATIVE)

1. En el menú lateral, ve a **"Build" → "Firestore Database"**
2. Clic en **"Create database"**
3. **MUY IMPORTANTE:** Selecciona **"Start in production mode"**
4. Clic en **"Next"**
5. **Ubicación:** Selecciona **"us-central"** (o la más cercana)
6. Clic en **"Enable"**
7. Espera 1-2 minutos mientras se crea

✅ **Verificación:** Deberías ver la pestaña "Data" con mensaje "No hay colecciones"

---

## Paso 3: Habilitar Realtime Database

1. En el menú lateral, ve a **"Build" → "Realtime Database"**
2. Clic en **"Create Database"**
3. **Ubicación:** **United States (us-central1)**
4. **Reglas de seguridad:** Selecciona **"Start in locked mode"**
5. Clic en **"Enable"**

✅ **Verificación:** Deberías ver la URL: `https://transporte-inteligente-app-default-rtdb.firebaseio.com/`

---

## Paso 4: Habilitar Authentication

1. En el menú lateral, ve a **"Build" → "Authentication"**
2. Clic en **"Get started"**
3. En la pestaña **"Sign-in method"**
4. Clic en **"Email/Password"**
5. **Habilita** el toggle de "Email/Password"
6. Clic en **"Save"**

✅ **Verificación:** Deberías ver "Email/Password" con estado "Habilitado"

---

## Paso 5: Descargar Service Account Key

1. Ve a **⚙️ Configuración del proyecto** (ícono de engranaje arriba a la izquierda)
2. Clic en **"Cuentas de servicio"** o **"Service accounts"**
3. Clic en **"Generar nueva clave privada"** o **"Generate new private key"**
4. Clic en **"Generar clave"**
5. Se descargará un archivo JSON
6. **Renombra el archivo** a: `firebase-service-account-new.json`
7. **Guárdalo en:** `d:\Programacion\transporte_inteligente\`

---

## Paso 6: Actualizar la App Móvil con el Nuevo Proyecto

Ejecuta en la terminal:

```bash
cd d:\Programacion\transporte_inteligente\mobile_app
flutterfire configure
```

**Durante la configuración:**
- Selecciona el nuevo proyecto: `transporte-inteligente-app`
- Selecciona las plataformas: **android, ios, web, windows**
- Esto actualizará automáticamente `lib/firebase_options.dart`

---

## Paso 7: Reemplazar el Service Account Key

```bash
cd d:\Programacion\transporte_inteligente
del firebase-service-account.json
ren firebase-service-account-new.json firebase-service-account.json
```

O manualmente:
1. Elimina el archivo `firebase-service-account.json` actual
2. Renombra `firebase-service-account-new.json` a `firebase-service-account.json`

---

## Paso 8: Ejecutar la Migración

```bash
cd d:\Programacion\transporte_inteligente
node migrate_to_firebase.js
```

**Deberías ver:**
```
MIGRACION DE POSTGRESQL A FIREBASE
===================================
Verificando conexion a PostgreSQL...
OK Conectado a PostgreSQL
Migrando rutas...
OK 4 rutas migradas
Migrando puntos de ruta...
OK X puntos de ruta migrados
...
MIGRACION COMPLETADA EXITOSAMENTE
```

---

## Paso 9: Configurar Reglas de Seguridad

### Firestore Rules

1. Ve a **Firestore Database → Rules**
2. Pega este código:

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

3. Clic en **"Publicar"**

### Realtime Database Rules

1. Ve a **Realtime Database → Rules**
2. Pega este código:

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

3. Clic en **"Publicar"**

---

## Paso 10: Verificar Todo

1. **Firestore:** Deberías ver colecciones con datos
2. **Authentication:** Deberías ver usuarios creados
3. **Realtime Database:** Estará vacío hasta que conductores envíen GPS

---

## ✅ Checklist Final

- [ ] Proyecto Firebase creado
- [ ] Firestore habilitado en **modo Native**
- [ ] Realtime Database habilitado
- [ ] Authentication habilitado (Email/Password)
- [ ] Service Account Key descargado y reemplazado
- [ ] `flutterfire configure` ejecutado
- [ ] Migración ejecutada exitosamente
- [ ] Reglas de seguridad configuradas
- [ ] Datos verificados en Firebase Console

---

## 🆘 Si algo falla

- **Error "NOT_FOUND":** Espera 2-3 minutos después de crear Firestore
- **Error de permisos:** Verifica que el Service Account sea del proyecto correcto
- **Error de conexión:** Verifica que `DATABASE_URL` en `.env` sea correcta
