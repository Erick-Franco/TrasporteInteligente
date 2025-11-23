// ════════════════════════════════════════════════════════
// 🔥 FIREBASE SERVICE - TRANSPORTE INTELIGENTE
// lib/services/firebase_service.dart
// ════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;

/// Servicio centralizado para interactuar con Firebase
class FirebaseService {
  // Instancias de Firebase
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final rtdb.FirebaseDatabase _realtimeDb =
      rtdb.FirebaseDatabase.instance;

  // ════════════════════════════════════════════════════════
  // 🔐 AUTHENTICATION
  // ════════════════════════════════════════════════════════

  /// Usuario actual autenticado
  static User? get currentUser => _auth.currentUser;

  /// Stream de cambios de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login con email y contraseña
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Crear usuario (solo para admin)
  static Future<UserCredential> createUser({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ════════════════════════════════════════════════════════
  // 📊 FIRESTORE - COLECCIONES
  // ════════════════════════════════════════════════════════

  /// Colección de rutas
  static CollectionReference get rutasCollection =>
      _firestore.collection('rutas');

  /// Colección de puntos de control
  static CollectionReference get puntosControlCollection =>
      _firestore.collection('puntos_control');

  /// Colección de vehículos
  static CollectionReference get vehiculosCollection =>
      _firestore.collection('vehiculos');

  /// Colección de conductores
  static CollectionReference get conductoresCollection =>
      _firestore.collection('conductores');

  /// Colección de gerentes
  static CollectionReference get gerentesCollection =>
      _firestore.collection('gerentes');

  /// Colección de viajes
  static CollectionReference get viajesCollection =>
      _firestore.collection('viajes');

  /// Colección de mensajes de chat
  static CollectionReference get mensajesChatCollection =>
      _firestore.collection('mensajes_chat');

  // ════════════════════════════════════════════════════════
  // 📍 REALTIME DATABASE - UBICACIONES GPS
  // ════════════════════════════════════════════════════════

  /// Referencia a ubicaciones en tiempo real
  static rtdb.DatabaseReference get ubicacionesRef =>
      _realtimeDb.ref('ubicaciones_tiempo_real');

  /// Escribir ubicación de un conductor
  static Future<void> setUbicacionConductor({
    required String conductorId,
    required double latitud,
    required double longitud,
    required double velocidad,
    required double direccion,
    String? viajeId,
    String? rutaId,
  }) async {
    await ubicacionesRef.child(conductorId).set({
      'latitud': latitud,
      'longitud': longitud,
      'velocidad': velocidad,
      'direccion': direccion,
      'timestamp': rtdb.ServerValue.timestamp,
      'viaje_id': viajeId,
      'ruta_id': rutaId,
    });
  }

  /// Escuchar ubicación de un conductor específico
  static Stream<rtdb.DatabaseEvent> listenUbicacionConductor(
      String conductorId) {
    return ubicacionesRef.child(conductorId).onValue;
  }

  /// Escuchar todas las ubicaciones en tiempo real
  static Stream<rtdb.DatabaseEvent> listenTodasUbicaciones() {
    return ubicacionesRef.onValue;
  }

  /// Eliminar ubicación de un conductor (cuando termina viaje)
  static Future<void> removeUbicacionConductor(String conductorId) async {
    await ubicacionesRef.child(conductorId).remove();
  }

  // ════════════════════════════════════════════════════════
  // 🚌 RUTAS
  // ════════════════════════════════════════════════════════

  /// Obtener todas las rutas activas
  static Future<List<Map<String, dynamic>>> getRutasActivas() async {
    final snapshot =
        await rutasCollection.where('activa', isEqualTo: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Obtener puntos de control de una ruta
  static Future<List<Map<String, dynamic>>> getPuntosControl({
    required String rutaId,
    String? tipo, // 'ida' o 'vuelta'
  }) async {
    Query query = puntosControlCollection
        .where('ruta_id', isEqualTo: rutaId)
        .orderBy('orden');

    if (tipo != null) {
      query = query.where('tipo', isEqualTo: tipo);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ════════════════════════════════════════════════════════
  // 🚍 VEHÍCULOS
  // ════════════════════════════════════════════════════════

  /// Obtener vehículos activos
  static Future<List<Map<String, dynamic>>> getVehiculosActivos() async {
    final snapshot =
        await vehiculosCollection.where('activo', isEqualTo: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ════════════════════════════════════════════════════════
  // 👤 CONDUCTORES
  // ════════════════════════════════════════════════════════

  /// Obtener datos de un conductor por UID
  static Future<Map<String, dynamic>?> getConductor(String uid) async {
    final doc = await conductoresCollection.doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  /// Actualizar datos de conductor
  static Future<void> updateConductor(
      String uid, Map<String, dynamic> data) async {
    await conductoresCollection.doc(uid).update(data);
  }

  // ════════════════════════════════════════════════════════
  // 🚗 VIAJES
  // ════════════════════════════════════════════════════════

  /// Crear un nuevo viaje
  static Future<String> crearViaje({
    required String conductorId,
    required String vehiculoId,
    required String rutaId,
    required String tipo, // 'ida' o 'vuelta'
  }) async {
    final docRef = await viajesCollection.add({
      'conductor_id': conductorId,
      'vehiculo_id': vehiculoId,
      'ruta_id': rutaId,
      'tipo': tipo,
      'inicio': FieldValue.serverTimestamp(),
      'fin': null,
      'estado': 'activo',
      'distancia_recorrida': 0.0,
    });

    return docRef.id;
  }

  /// Finalizar un viaje
  static Future<void> finalizarViaje(
      String viajeId, double distanciaRecorrida) async {
    await viajesCollection.doc(viajeId).update({
      'fin': FieldValue.serverTimestamp(),
      'estado': 'finalizado',
      'distancia_recorrida': distanciaRecorrida,
    });
  }

  /// Obtener viaje actual de un conductor
  static Future<Map<String, dynamic>?> getViajeActual(
      String conductorId) async {
    final snapshot = await viajesCollection
        .where('conductor_id', isEqualTo: conductorId)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['id'] = snapshot.docs.first.id;
      return data;
    }
    return null;
  }

  /// Obtener viajes activos
  static Future<List<Map<String, dynamic>>> getViajesActivos() async {
    final snapshot =
        await viajesCollection.where('estado', isEqualTo: 'activo').get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ════════════════════════════════════════════════════════
  // 💬 CHAT
  // ════════════════════════════════════════════════════════

  /// Enviar mensaje al chat global
  static Future<void> enviarMensaje({
    required String usuarioId,
    required String usuarioNombre,
    required String usuarioTipo, // 'conductor' o 'gerente'
    required String mensaje,
  }) async {
    await mensajesChatCollection.add({
      'usuario_id': usuarioId,
      'usuario_nombre': usuarioNombre,
      'usuario_tipo': usuarioTipo,
      'mensaje': mensaje,
      'timestamp': FieldValue.serverTimestamp(),
      'leido': false,
    });
  }

  /// Escuchar mensajes del chat en tiempo real
  static Stream<QuerySnapshot> listenMensajesChat({int limit = 50}) {
    return mensajesChatCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Obtener mensajes del chat (una vez)
  static Future<List<Map<String, dynamic>>> getMensajesChat(
      {int limit = 50}) async {
    final snapshot = await mensajesChatCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ════════════════════════════════════════════════════════
  // 🗺️ MAPEO ANUAL DE RUTAS
  // ════════════════════════════════════════════════════════

  /// Guardar ruta mapeada anualmente
  static Future<String> guardarRutaAnual({
    required String nombre,
    required List<Map<String, double>> coordinadas,
    required String tipo, // 'ida' o 'vuelta'
  }) async {
    // Crear documento de ruta
    final rutaRef = await rutasCollection.add({
      'nombre': nombre,
      'activa': true,
      'created_at': FieldValue.serverTimestamp(),
      'tipo_mapeo': 'anual',
      'total_puntos': coordinadas.length,
    });

    final rutaId = rutaRef.id;

    // Guardar puntos de control en batch
    final batch = _firestore.batch();

    for (int i = 0; i < coordinadas.length; i++) {
      final puntoRef = puntosControlCollection.doc();
      batch.set(puntoRef, {
        'ruta_id': rutaId,
        'latitud': coordinadas[i]['lat'],
        'longitud': coordinadas[i]['lng'],
        'orden': i,
        'tipo': tipo,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    return rutaId;
  }
}
