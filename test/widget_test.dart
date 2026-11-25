import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/base_tareas.dart';
import 'package:gestor_tareas_local/main.dart';

void main() {
  testWidgets('La pantalla inicial se muestra sin errores', (tester) async {
    await tester.pumpWidget(
      GestorTareasApp(abrirBase: () => BaseTareas(NativeDatabase.memory())),
    );
    expect(find.text('Gestor de tareas'), findsOneWidget);
    expect(find.text('Agregar tarea'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
