# ⚠️ ERROR DE MIGRACIÓN - SOLUCIÓN

## Problema
```
Error: 5 NOT_FOUND
```

Este error significa que **Firestore Database NO está habilitado** en tu proyecto Firebase.

## Solución - Habilitar Firestore

### 1. Ve a Firebase Console
https://console.firebase.google.com/project/trasnporteinteligente/firestore

### 2. Habilita Firestore Database
1. Clic en **"Build" → "Firestore Database"** en el menú lateral
2. Clic en **"Create database"**
3. Selecciona **"Start in production mode"** (configuraremos las reglas después)
4. Ubicación: **us-central** (o la más cercana a tu ubicación)
5. Clic en **"Enable"**

### 3. Habilita Realtime Database (para GPS)
1. Ve a **"Build" → "Realtime Database"**
2. Clic en **"Create Database"**
3. Ubicación: **United States**
4. Selecciona **"Start in locked mode"**
5. Clic en **"Enable"**

### 4. Habilita Authentication
1. Ve a **"Build" → "Authentication"**
2. Clic en **"Get started"**
3. En la pestaña **"Sign-in method"**
4. Habilita **"Email/Password"**
5. Guarda los cambios

## Después de habilitar los servicios

Ejecuta nuevamente el script de migración:

```bash
cd d:\Programacion\transporte_inteligente
node migrate_to_firebase.js
```

## Verificar que funcionó

Después de la migración exitosa, verifica en Firebase Console:

1. **Firestore Database** → Deberías ver colecciones:
   - `rutas`
   - `puntos_control`
   - `vehiculos`
   - `conductores`
   - `gerentes`

2. **Authentication** → Deberías ver usuarios creados con los emails de conductores y gerentes

3. **Realtime Database** → Estará vacío hasta que los conductores empiecen a enviar GPS

## Reglas de Seguridad (configurar DESPUÉS de la migración)

### Firestore Rules
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
