// ════════════════════════════════════════════════════════
// 🚀 MAIN - TRANSPORTE INTELIGENTE
// lib/main.dart
// ════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/providers/bus_provider.dart';
import 'presentation/providers/ruta_provider.dart';
import 'presentation/providers/ubicacion_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/conductor_provider.dart';
import 'presentation/screens/welcome_screen.dart';

void main() {
  // Asegurar inicialización de bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Ejecutar app inmediatamente (la inicialización de Firebase será dentro)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ TODOS LOS PROVIDERS EN ORDEN
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => RutaProvider()),
        ChangeNotifierProvider(create: (_) => UbicacionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
      ],
      child: MaterialApp(
        title: 'Transporte Inteligente',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.indigo.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  String? _error;
  String _statusMessage = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    // Iniciar proceso de carga después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      if (mounted) setState(() => _statusMessage = 'Conectando servicios...');

      // 1. Inicializar Firebase con timeout
      print('🚀 Inicializando Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('La conexión con Firebase tardó demasiado.');
      });
      print('✅ Firebase inicializado');

      if (mounted) setState(() => _statusMessage = 'Cargando datos...');

      // 2. Pequeño delay para UX
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('❌ Error fatal en inicialización: $e');
      if (mounted) {
        setState(() {
          _error = 'Error inicializando app: $e';
          _initialized = true; // Permitir continuar para mostrar el error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      // Mostrar error pero permitir continuar a la pantalla de bienvenida
      return Stack(
        children: [
          const WelcomeScreen(),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_error',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() => _error = null);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const WelcomeScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.indigo.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Transporte Inteligente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
