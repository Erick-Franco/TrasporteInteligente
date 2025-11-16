// ════════════════════════════════════════════════════════
// 🚀 MAIN - TRANSPORTE INTELIGENTE
// lib/main.dart
// ════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/bus_provider.dart';
import 'presentation/providers/ruta_provider.dart';
import 'presentation/providers/ubicacion_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/conductor_provider.dart';
import 'presentation/screens/welcome_screen.dart';

void main() {
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
        ChangeNotifierProvider(create: (_) => ChatProvider()), // ✅ IMPORTANTE
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Pequeño delay para mostrar el splash
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Error inicializando app: $e';
        _initialized = true; // Permitir que la app continúe
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      // Mostrar error pero permitir continuar
      return Stack(
        children: [
          const WelcomeScreen(),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Advertencia: $_error',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
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
            const Icon(
              Icons.directions_bus_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'Transporte Inteligente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Inicializando...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
