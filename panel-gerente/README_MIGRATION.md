# 🚀 Migración del Panel del Gerente a Firebase

Este documento detalla los cambios realizados para migrar el Panel del Gerente (`panel-gerente/`) de la antigua API REST/Socket.IO a **Firebase (Auth, Firestore, Realtime Database)**.

## 📋 Cambios Realizados

1.  **Autenticación (`js/auth.js`)**:
    *   Se reemplazó el login REST por `firebase.auth().signInWithEmailAndPassword`.
    *   La sesión se maneja automáticamente con el SDK de Firebase.
    *   **Nota:** Debes crear usuarios en Firebase Authentication para que los gerentes puedan iniciar sesión.

2.  **Mapa y Tiempo Real (`js/map.js`)**:
    *   **Rutas:** Se leen de la colección `rutas` en Firestore.
    *   **Conductores:** Se escuchan en tiempo real desde la colección `conductores` en Firestore.
    *   **Ubicaciones GPS:** Se escuchan desde el nodo `ubicaciones` en Firebase Realtime Database (igual que la app móvil).
    *   **Socket.IO eliminado:** Ya no se depende del servidor Node.js antiguo.

3.  **Asignaciones (`js/assignments.js`)**:
    *   Lista de conductores y rutas obtenida directamente de Firestore.

## 🧪 Cómo Probar

1.  **Abrir el Panel**:
    *   Abre `panel-gerente/index.html` en tu navegador (o usa Live Server).

2.  **Iniciar Sesión**:
    *   Usa un correo y contraseña registrados en tu proyecto de Firebase.
    *   *Si no tienes uno, créalo en la consola de Firebase > Authentication.*

3.  **Verificar Dashboard**:
    *   Deberías ver el mapa cargado.
    *   Si el usuario tiene una `ruta_id` asignada (simulada en el código si no existe en Firestore), verás el trazado de la ruta.
    *   Si hay conductores activos con la app móvil, deberían aparecer los buses moviéndose en el mapa.

## ⚠️ Requisitos Previos en Firebase

Asegúrate de que tu proyecto de Firebase tenga:

1.  **Authentication**: Email/Password habilitado.
2.  **Firestore**:
    *   Colección `rutas`: Documentos con campos `nombre`, `color`, `codigo`.
    *   Subcolección `rutas/{id}/puntos_control`: Puntos para dibujar la línea.
    *   Colección `conductores`: Documentos con `nombre`, `placa`, `ruta_id`, `disponible` (bool).
3.  **Realtime Database**:
    *   Nodo `ubicaciones/{conductorId}`: Con `latitud`, `longitud`, `velocidad`, `timestamp`.

## 📝 Notas para el Desarrollador

*   **Datos del Gerente:** Actualmente, `js/map.js` intenta leer datos extra del usuario desde una colección `usuarios` en Firestore. Si no existe, usa datos simulados basados en el email (ej. si el email tiene "18", asigna la Ruta 18).
*   **Reglas de Seguridad:** Asegúrate de que las reglas de Firestore permitan leer `rutas` y `conductores` a los usuarios autenticados.

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rutas/{document=**} {
      allow read: if request.auth != null;
    }
    match /conductores/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Para que los conductores actualicen su estado
    }
    match /usuarios/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
