# 🔥 Firebase - Configuración Completada

## ✅ Estado Actual

Tu proyecto Firebase está configurado y listo para usar:

- **Proyecto ID**: `trasnporteinteligente`
- **Plataformas configuradas**: Android, iOS, Web, Windows
- **Archivo de configuración**: `lib/firebase_options.dart` ✅

---

## 📋 Próximos Pasos

### 1. Habilitar Servicios en Firebase Console

Ve a [Firebase Console](https://console.firebase.google.com/project/trasnporteinteligente) y habilita:

#### a) Authentication
1. Ve a **Build → Authentication**
2. Clic en **"Comenzar"**
3. Habilita **Email/Password**
4. Guarda

#### b) Firestore Database
1. Ve a **Build → Firestore Database**
2. Clic en **"Crear base de datos"**
3. Selecciona **"Iniciar en modo de producción"**
4. Ubicación: **us-central** (o la más cercana)
5. Clic en **"Habilitar"**

**Reglas de seguridad** (pestaña "Reglas"):
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

#### c) Realtime Database
1. Ve a **Build → Realtime Database**
2. Clic en **"Crear base de datos"**
3. Ubicación: **United States (us-central1)**
4. Selecciona **"Iniciar en modo bloqueado"**
5. Clic en **"Habilitar"**

**Reglas de seguridad** (pestaña "Reglas"):
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

### 2. Migrar Datos de PostgreSQL a Firebase

Ejecuta el script de migración:

```bash
cd d:\Programacion\transporte_inteligente

# Instalar dependencias
npm install firebase-admin pg dotenv

# Descargar Service Account Key de Firebase Console
# 1. Ve a Project Settings → Service Accounts
# 2. Clic en "Generate new private key"
# 3. Guarda como: firebase-service-account.json

# Ejecutar migración
node migrate_to_firebase.js
```

---

### 3. Probar la App

```bash
cd mobile_app
flutter pub get
flutter run
```

**Funcionalidades a probar:**
- ✅ Login de conductor (Firebase Auth)
- ✅ Envío de ubicación GPS (Realtime Database)
- ✅ Chat en tiempo real (Firestore)
- ✅ Inicio/fin de viajes (Firestore)

---

## 🎯 Archivos Importantes

| Archivo | Descripción |
|---------|-------------|
| `lib/firebase_options.dart` | ✅ Configuración generada automáticamente |
| `lib/services/auth_service.dart` | ✅ Autenticación con Firebase |
| `lib/services/location_service.dart` | ✅ GPS con Realtime Database |
| `lib/services/chat_service.dart` | ✅ Chat con Firestore |
| `migrate_to_firebase.js` | Script de migración de datos |

---

## 📱 Apps Registradas

| Plataforma | App ID | Bundle ID |
|------------|--------|-----------|
| Android | `1:760062119302:android:3b79ae3a8fe99f3765b007` | `com.example.transporte_inteligente` |
| iOS | `1:760062119302:ios:a8c8002df5f67c3f65b007` | `com.example.flutterApplication1` |
| Web | `1:760062119302:web:a87f983b3de0079e65b007` | - |
| Windows | `1:760062119302:web:198dc0588a11be7665b007` | - |

---

## ⚠️ Notas Importantes

1. **Reglas de Seguridad**: Asegúrate de configurarlas antes de usar la app en producción
2. **Service Account**: Necesario para el script de migración
3. **Costos**: Firebase tiene límites en el plan gratuito (Spark)
4. **Backend antiguo**: Mantén el backend Node.js como respaldo hasta confirmar que todo funciona

---

## 🆘 ¿Problemas?

- **Error de autenticación**: Verifica que Authentication esté habilitado
- **Error de permisos**: Revisa las reglas de seguridad
- **App no compila**: Ejecuta `flutter clean && flutter pub get`
