// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_inteligente/main.dart';

void main() {
  testWidgets('La app de Transporte Inteligente inicia correctamente',
      (WidgetTester tester) async {
    // Construye la app
    await tester.pumpWidget(const MyApp());

    // Verifica que MaterialApp existe
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verifica que el título de la app es correcto
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'Transporte Inteligente');
  });

  testWidgets('La app usa el tema correcto', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verifica que se usa Material 3
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, true);
  });

  testWidgets('La app no muestra el banner de debug',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.debugShowCheckedModeBanner, false);
  });
}
