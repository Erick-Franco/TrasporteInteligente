# Configuración de Firebase para Transporte Inteligente

Este documento te guía paso a paso para configurar Firebase en tu proyecto.

---

## 📋 Paso 1: Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en **"Agregar proyecto"**
3. Nombre del proyecto: `transporte-inteligente-juliaca` (o el que prefieras)
4. Desactiva Google Analytics (opcional para este proyecto)
5. Haz clic en **"Crear proyecto"**

---

## 🔐 Paso 2: Configurar Authentication

1. En el menú lateral, ve a **Build → Authentication**
2. Haz clic en **"Comenzar"**
3. En la pestaña **"Sign-in method"**, habilita:
   - ✅ **Correo electrónico/contraseña** (Email/Password)
4. Guarda los cambios

---

## 📊 Paso 3: Configurar Firestore Database

1. En el menú lateral, ve a **Build → Firestore Database**
2. Haz clic en **"Crear base de datos"**
3. Selecciona **"Iniciar en modo de producción"**
4. Elige la ubicación: **us-central** (o la más cercana)
5. Haz clic en **"Habilitar"**

### Configurar Reglas de Seguridad

Una vez creada la base de datos, ve a la pestaña **"Reglas"** y reemplaza con:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Rutas: lectura pública, escritura solo admin
    match /rutas/{rutaId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Puntos de control: lectura pública
    match /puntos_control/{puntoId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Vehículos: lectura pública
    match /vehiculos/{vehiculoId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Conductores: solo pueden leer/editar su propio documento
    match /conductores/{conductorId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == conductorId;
    }
    
    // Gerentes: solo pueden leer/editar su propio documento
    match /gerentes/{gerenteId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == gerenteId;
    }
    
    // Viajes: conductores pueden crear/editar sus viajes
    match /viajes/{viajeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.conductor_id;
    }
    
    // Chat: usuarios autenticados pueden leer y escribir
    match /mensajes_chat/{mensajeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

Haz clic en **"Publicar"**.

---

## 📍 Paso 4: Configurar Realtime Database

1. En el menú lateral, ve a **Build → Realtime Database**
2. Haz clic en **"Crear base de datos"**
3. Selecciona la ubicación: **United States (us-central1)**
4. Selecciona **"Iniciar en modo bloqueado"**
5. Haz clic en **"Habilitar"**

### Configurar Reglas de Seguridad

Ve a la pestaña **"Reglas"** y reemplaza con:

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

Haz clic en **"Publicar"**.

---

## 📱 Paso 5: Registrar App Android

1. En la página principal del proyecto, haz clic en el ícono de **Android**
2. Ingresa los siguientes datos:
   - **Nombre del paquete Android**: `com.example.transporte_inteligente`
   - **Alias de la app**: `Transporte Inteligente`
   - **SHA-1**: (opcional por ahora, déjalo vacío)
3. Haz clic en **"Registrar app"**
4. **Descarga el archivo `google-services.json`**
5. Coloca el archivo en: `mobile_app/android/app/google-services.json`
6. Continúa con los pasos que indica Firebase Console

### Modificar build.gradle (Proyecto)

Abre `mobile_app/android/build.gradle` y agrega:

```gradle
buildscript {
    dependencies {
        // ... otras dependencias
        classpath 'com.google.gms:google-services:4.4.0'  // ← AGREGAR ESTA LÍNEA
    }
}
```

### Modificar build.gradle (App)

Abre `mobile_app/android/app/build.gradle` y agrega al final del archivo:

```gradle
apply plugin: 'com.google.gms.google-services'  // ← AGREGAR ESTA LÍNEA
```

---

## 🍎 Paso 6: Registrar App iOS (Opcional)

Si planeas compilar para iOS:

1. En la página principal del proyecto, haz clic en el ícono de **iOS**
2. Ingresa:
   - **Bundle ID**: `com.example.transporteInteligente`
   - **Alias**: `Transporte Inteligente`
3. Descarga `GoogleService-Info.plist`
4. Coloca el archivo en: `mobile_app/ios/Runner/GoogleService-Info.plist`

---

## 🔧 Paso 7: Actualizar firebase_options.dart

1. Abre `mobile_app/lib/config/firebase_options.dart`
2. En Firebase Console, ve a **Configuración del proyecto** (ícono de engranaje)
3. En la sección **"Tus apps"**, selecciona tu app Android
4. Copia los valores y reemplázalos en `firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'TU_API_KEY_AQUI',              // ← De Firebase Console
  appId: 'TU_APP_ID_AQUI',                // ← De Firebase Console
  messagingSenderId: 'TU_SENDER_ID_AQUI', // ← De Firebase Console
  projectId: 'TU_PROJECT_ID_AQUI',        // ← De Firebase Console
  storageBucket: 'TU_BUCKET_AQUI',        // ← De Firebase Console
);
```

---

## ✅ Paso 8: Verificar Instalación

Ejecuta en la terminal:

```bash
cd mobile_app
flutter pub get
flutter run
```

Si todo está configurado correctamente, la app debería iniciar sin errores de Firebase.

---

## 👥 Paso 9: Crear Usuarios de Prueba

### Opción A: Desde Firebase Console (Manual)

1. Ve a **Authentication → Users**
2. Haz clic en **"Agregar usuario"**
3. Crea conductores y gerentes:

**Conductores:**
- Email: `conductor1@transporte.com` / Password: `123456`
- Email: `conductor2@transporte.com` / Password: `123456`

**Gerentes:**
- Email: `gerente18@transporte.com` / Password: `123456`
- Email: `gerente22@transporte.com` / Password: `123456`

4. Copia los **UIDs** generados

### Opción B: Script de Migración (Recomendado)

Usaremos un script para migrar todos los datos de PostgreSQL a Firebase (próximo paso).

---

## 📦 Paso 10: Migrar Datos de PostgreSQL a Firebase

Ejecutaremos un script Node.js que:
1. Lee los datos de PostgreSQL
2. Crea usuarios en Firebase Auth
3. Importa datos a Firestore

**Este script se creará en el siguiente paso.**

---

## 🎯 Próximos Pasos

Una vez completada la configuración:

1. ✅ Migrar datos de PostgreSQL a Firestore
2. ✅ Actualizar servicios de la app móvil
3. ✅ Actualizar providers
4. ✅ Migrar panel de gerente
5. ✅ Probar funcionalidad completa

---

## 🆘 Solución de Problemas

### Error: "google-services.json not found"
- Asegúrate de que el archivo esté en `mobile_app/android/app/google-services.json`

### Error: "FirebaseOptions not configured"
- Verifica que `firebase_options.dart` tenga los valores correctos de Firebase Console

### Error: "Permission denied" en Firestore
- Revisa las reglas de seguridad en Firestore Console

---

## 📚 Recursos

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
