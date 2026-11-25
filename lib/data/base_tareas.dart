import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/tarea.dart';

class BaseTareas extends GeneratedDatabase {
  BaseTareas(super.executor);

  BaseTareas._conectar(super.connection) : super.connect();

  factory BaseTareas.local() => BaseTareas._conectar(
    driftDatabase(
      name: 'gestor_tareas',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
        onResult: (resultado) {
          if (resultado.chosenImplementation.name == 'inMemory') {
            throw StateError(
              'El navegador no ofrece almacenamiento persistente.',
            );
          }
        },
      ),
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => customStatement('''
      CREATE TABLE tareas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL CHECK (length(trim(titulo)) > 0),
        completada INTEGER NOT NULL DEFAULT 0 CHECK (completada IN (0, 1))
      )
    '''),
  );

  Future<List<Tarea>> listar() async {
    final filas = await customSelect(
      'SELECT id, titulo, completada FROM tareas ORDER BY id',
    ).get();
    return filas
        .map(
          (fila) => Tarea(
            id: fila.read<int>('id'),
            titulo: fila.read<String>('titulo'),
            completada: fila.read<int>('completada') == 1,
          ),
        )
        .toList();
  }

  Future<void> agregar(String titulo) => customStatement(
    'INSERT INTO tareas (titulo) VALUES (?)',
    [_validarTitulo(titulo)],
  );

  Future<void> editar(int id, String titulo) => customStatement(
    'UPDATE tareas SET titulo = ? WHERE id = ?',
    [_validarTitulo(titulo), id],
  );

  Future<void> cambiarEstado(int id, bool completada) => customStatement(
    'UPDATE tareas SET completada = ? WHERE id = ?',
    [completada ? 1 : 0, id],
  );

  Future<void> eliminar(int id) =>
      customStatement('DELETE FROM tareas WHERE id = ?', [id]);

  String _validarTitulo(String titulo) {
    final limpio = titulo.trim();
    if (limpio.isEmpty) {
      throw ArgumentError('Escribe un título para la tarea.');
    }
    return limpio;
  }
}
