import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/base_tareas.dart';

void main() {
  test('Rechaza títulos vacíos al agregar y editar', () async {
    final base = BaseTareas(NativeDatabase.memory());
    addTearDown(base.close);

    for (final titulo in ['', '   ', '\t\n']) {
      expect(() => base.agregar(titulo), throwsArgumentError);
    }
    expect(await base.listar(), isEmpty);

    await base.agregar('  Prueba  ');
    final tarea = (await base.listar()).single;
    expect(tarea.titulo, 'Prueba');
    expect(() => base.editar(tarea.id, '   '), throwsArgumentError);
    expect((await base.listar()).single.titulo, 'Prueba');
  });

  test('Conserva altas, edición, estado y borrado al reabrir', () async {
    final carpeta = await Directory.systemTemp.createTemp('gestor_tareas_');
    addTearDown(() => carpeta.delete(recursive: true));
    final archivo = File.fromUri(carpeta.uri.resolve('tareas.sqlite'));

    var base = BaseTareas(NativeDatabase(archivo));
    try {
      await base.agregar("Ir al mercado 'central'");
      await base.agregar('Entregar práctica');
      await base.agregar('Leer');
    } finally {
      await base.close();
    }

    base = BaseTareas(NativeDatabase(archivo));
    try {
      final tareas = await base.listar();
      expect(tareas.map((tarea) => tarea.titulo), [
        "Ir al mercado 'central'",
        'Entregar práctica',
        'Leer',
      ]);
      expect(tareas.first.completada, isFalse);
      await base.cambiarEstado(tareas.first.id, true);
      await base.editar(tareas[1].id, 'Subir práctica');
      await base.eliminar(tareas.last.id);
    } finally {
      await base.close();
    }

    base = BaseTareas(NativeDatabase(archivo));
    try {
      final tareas = await base.listar();
      expect(tareas.map((tarea) => tarea.titulo), [
        "Ir al mercado 'central'",
        'Subir práctica',
      ]);
      expect(tareas.first.completada, isTrue);
      expect(tareas.last.completada, isFalse);
    } finally {
      await base.close();
    }
  });
}
