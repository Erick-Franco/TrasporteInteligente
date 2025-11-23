// ════════════════════════════════════════════════════════
// 🔐 SERVICIO DE AUTENTICACIÓN - TRANSPORTE INTELIGENTE
// lib/services/auth_service.dart
// MIGRADO A FIREBASE
// ════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/conductor_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════
  // 🔐 AUTENTICACIÓN
  // ════════════════════════════════════════════════════════

  /// Usuario actual autenticado
  static User? get currentUser => _auth.currentUser;

  /// Stream de cambios de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login de conductor con email y contraseña
  static Future<Conductor?> loginConductor({
    required String email,
    required String password,
  }) async {
    User? user;
    try {
      print('🔐 Intentando login conductor...');
      print('📧 Email: $email');

      // Autenticar con Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Error de autenticación: ${e.code}');
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Usuario no encontrado');
        case 'wrong-password':
          throw Exception('Contraseña incorrecta');
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'user-disabled':
          throw Exception('Usuario deshabilitado');
        case 'too-many-requests':
          throw Exception('Demasiados intentos. Intenta más tarde');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      // Workaround para error de PigeonUserDetails en algunas versiones
      if (_auth.currentUser != null) {
        print(
            '⚠️ Error en login ignorado porque el usuario sí se autenticó: $e');
        user = _auth.currentUser;
      } else {
        print('❌ Error en login conductor: $e');
        rethrow;
      }
    }

    if (user == null) {
      throw Exception('Error en autenticación: Usuario nulo');
    }

    try {
      // Obtener datos del conductor desde Firestore
      final conductorDoc =
          await _firestore.collection('conductores').doc(user.uid).get();

      if (!conductorDoc.exists) {
        // Si no existe en conductores, verificar si es gerente
        final gerenteDoc =
            await _firestore.collection('gerentes').doc(user.uid).get();

        if (gerenteDoc.exists) {
          throw Exception('Este usuario es un gerente, no un conductor');
        }

        throw Exception('Datos de conductor no encontrados');
      }

      final conductorData = conductorDoc.data()!;

      // Convertir a modelo Conductor
      final conductor = Conductor(
        id: user.uid,
        nombre: conductorData['nombre'] ?? '',
        licencia: conductorData['licencia'] ?? '',
        email: conductorData['email'] ?? email,
        telefono: conductorData['telefono'] ?? '',
        vehiculoId: conductorData['vehiculo_id'] ?? '',
        rutaId: conductorData['ruta_id'] ?? '',
        activo: conductorData['activo'] ?? true,
      );

      print('✅ Login exitoso - Conductor: ${conductor.nombre}');
      return conductor;
    } catch (e) {
      print('❌ Error obteniendo datos del conductor: $e');
      // Si falla la obtención de datos, hacemos logout para no dejar sesión inconsistente
      await _auth.signOut();
      rethrow;
    }
  }

  /// Login alternativo con licencia (compatibilidad)
  /// Nota: En Firebase usamos email, pero mantenemos la interfaz por compatibilidad
  static Future<Conductor?> loginConductorConLicencia({
    required String licencia,
    required String password,
  }) async {
    // Intentar login usando licencia como email
    // Asumimos que la licencia es el email o parte de él
    return await loginConductor(
      email: licencia.contains('@') ? licencia : '$licencia@transporte.com',
      password: password,
    );
  }

  // ════════════════════════════════════════════════════════
  // 📊 INFORMACIÓN DEL CONDUCTOR
  // ════════════════════════════════════════════════════════

  /// Obtener información del conductor actual
  static Future<Map<String, dynamic>?> obtenerInfoConductor() async {
    try {
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final doc = await _firestore
          .collection('conductores')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Error obteniendo info conductor: $e');
      return null;
    }
  }

  /// Actualizar datos del conductor
  static Future<bool> actualizarConductor(Map<String, dynamic> data) async {
    try {
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      await _firestore
          .collection('conductores')
          .doc(currentUser!.uid)
          .update(data);

      print('✅ Datos de conductor actualizados');
      return true;
    } catch (e) {
      print('❌ Error actualizando conductor: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🎯 VIAJES
  // ════════════════════════════════════════════════════════

  /// Obtener viaje actual del conductor
  static Future<Map<String, dynamic>?> obtenerViajeActual() async {
    try {
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      final snapshot = await _firestore
          .collection('viajes')
          .where('conductor_id', isEqualTo: currentUser!.uid)
          .where('estado', isEqualTo: 'activo')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      print('❌ Error obteniendo viaje actual: $e');
      return null;
    }
  }

  /// Iniciar un viaje
  static Future<Map<String, dynamic>?> iniciarViaje({
    required String vehiculoId,
    required String rutaId,
    String tipo = 'ida',
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('No hay usuario autenticado');
      }

      print('🚀 Iniciando viaje...');
      print('   - Vehículo: $vehiculoId');
      print('   - Ruta: $rutaId');
      print('   - Tipo: $tipo');

      final viajeRef = await _firestore.collection('viajes').add({
        'conductor_id': currentUser!.uid,
        'vehiculo_id': vehiculoId,
        'ruta_id': rutaId,
        'tipo': tipo,
        'inicio': FieldValue.serverTimestamp(),
        'fin': null,
        'estado': 'activo',
        'distancia_recorrida': 0.0,
      });

      final viajeDoc = await viajeRef.get();
      final viajeData = viajeDoc.data()!;
      viajeData['id'] = viajeDoc.id;

      print('✅ Viaje iniciado: ${viajeDoc.id}');
      return viajeData;
    } catch (e) {
      print('❌ Error al iniciar viaje: $e');
      return null;
    }
  }

  /// Finalizar viaje
  static Future<bool> finalizarViaje(String viajeId,
      {double distanciaRecorrida = 0.0}) async {
    try {
      print('🏁 Finalizando viaje $viajeId...');

      await _firestore.collection('viajes').doc(viajeId).update({
        'fin': FieldValue.serverTimestamp(),
        'estado': 'finalizado',
        'distancia_recorrida': distanciaRecorrida,
      });

      print('✅ Viaje finalizado');
      return true;
    } catch (e) {
      print('❌ Error al finalizar viaje: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🚪 LOGOUT
  // ════════════════════════════════════════════════════════

  /// Cerrar sesión del conductor
  static Future<void> logout() async {
    try {
      print('🚪 Cerrando sesión...');
      await _auth.signOut();
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════
  // 🔧 MÉTODOS DE COMPATIBILIDAD
  // ════════════════════════════════════════════════════════

  /// Verificar si hay sesión activa
  static bool get isAuthenticated => currentUser != null;

  /// Obtener UID del conductor actual
  static String? get conductorId => currentUser?.uid;

  /// Obtener email del conductor actual
  static String? get conductorEmail => currentUser?.email;
}
