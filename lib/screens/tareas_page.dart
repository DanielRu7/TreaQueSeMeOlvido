import 'dart:async';

import 'package:flutter/material.dart';
import '../data/base_tareas.dart';
import '../models/tarea.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.abrirBase});

  final BaseTareas Function() abrirBase;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  List<Tarea> _tareas = [];
  late final BaseTareas _base;
  bool _ocupada = false;
  bool _errorCarga = false;
  Future<void>? _operacion;

  @override
  void initState() {
    super.initState();
    _base = widget.abrirBase();
    _actualizar();
  }

  void _actualizar([Future<void> Function()? escribir]) {
    if (_ocupada) return;
    _operacion = _cargar(escribir);
  }

  Future<void> _cargar(Future<void> Function()? escribir) async {
    setState(() => _ocupada = true);
    var escribiendo = escribir != null;
    try {
      if (escribir != null) await escribir();
      escribiendo = false;
      if (!mounted) return;
      final tareas = await _base.listar();
      if (!mounted) return;
      setState(() {
        _tareas = tareas;
        _errorCarga = false;
      });
    } on ArgumentError catch (error) {
      if (mounted) _avisar(error.message.toString());
    } catch (error) {
      debugPrint('Error de SQLite: $error');
      if (!mounted) return;
      if (escribiendo) {
        _avisar('No se pudo guardar el cambio.');
      } else {
        setState(() => _errorCarga = true);
      }
    } finally {
      if (mounted) setState(() => _ocupada = false);
    }
  }

  void _agregarTarea() {
    final titulo = _tituloController.text;
    _actualizar(() async {
      await _base.agregar(titulo);
      if (mounted && _tituloController.text == titulo) {
        _tituloController.clear();
      }
    });
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final titulo = await showDialog<String>(
      context: context,
      builder: (_) => _EditarTitulo(titulo: tarea.titulo),
    );
    if (mounted && titulo != null) {
      _actualizar(() => _base.editar(tarea.id, titulo));
    }
  }

  Future<void> _cerrarBase() async {
    await _operacion;
    try {
      await _base.close();
    } catch (error) {
      debugPrint('No se pudo cerrar SQLite: $error');
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    unawaited(_cerrarBase());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de tareas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Nueva tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _ocupada || _errorCarga ? null : _agregarTarea,
              icon: const Icon(Icons.add),
              label: const Text('Agregar tarea'),
            ),
            const SizedBox(height: 12),
            const Text('Mis tareas', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: _errorCarga
                  ? Center(
                      child: OutlinedButton(
                        onPressed: _ocupada ? null : () => _actualizar(),
                        child: const Text('No se pudo cargar. Reintentar'),
                      ),
                    )
                  : _ocupada && _tareas.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _tareas.isEmpty
                  ? const Center(child: Text('Todavía no hay tareas guardadas'))
                  : ListView.builder(
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: tarea.completada,
                              onChanged: _ocupada
                                  ? null
                                  : (valor) {
                                      if (valor != null) {
                                        _actualizar(
                                          () => _base.cambiarEstado(
                                            tarea.id,
                                            valor,
                                          ),
                                        );
                                      }
                                    },
                            ),
                            title: Text(tarea.titulo),
                            subtitle: Text('ID: ${tarea.id}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: _ocupada
                                      ? null
                                      : () => _editarTarea(tarea),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _ocupada
                                      ? null
                                      : () => _actualizar(
                                          () => _base.eliminar(tarea.id),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditarTitulo extends StatefulWidget {
  const _EditarTitulo({required this.titulo});

  final String titulo;

  @override
  State<_EditarTitulo> createState() => _EditarTituloState();
}

class _EditarTituloState extends State<_EditarTitulo> {
  final _formulario = GlobalKey<FormState>();
  late final _controlador = TextEditingController(text: widget.titulo);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formulario.currentState!.validate()) {
      Navigator.pop(context, _controlador.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar tarea'),
    content: Form(
      key: _formulario,
      child: TextFormField(
        controller: _controlador,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Título'),
        validator: (valor) => (valor ?? '').trim().isEmpty
            ? 'Escribe un título para la tarea.'
            : null,
        onFieldSubmitted: (_) => _guardar(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _guardar, child: const Text('Guardar')),
    ],
  );
}
