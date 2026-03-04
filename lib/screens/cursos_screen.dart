import 'package:flutter/material.dart';
import '../models/curso.dart';
import '../services/supabase_service.dart';

class CursosScreen extends StatefulWidget {
  const CursosScreen({Key? key}) : super(key: key);

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  final supa = SupabaseService.instance;

  List<Curso> cursos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    setState(() => cargando = true);
    try {
      final data = await supa.getCursos();
      setState(() => cursos = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando cursos: $e')),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void _mostrarFormulario([Curso? curso]) {
    final nombreCtrl = TextEditingController(text: curso?.nombre ?? '');
    final descCtrl = TextEditingController(text: curso?.descripcion ?? '');
    final precioCtrl = TextEditingController(
      text: curso == null ? '' : curso.precio.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(curso == null ? 'Nuevo Curso' : 'Editar Curso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Curso'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty ||
                  precioCtrl.text.trim().isEmpty) return;

              final nuevoCurso = Curso(
                id: curso?.id,
                nombre: nombreCtrl.text.trim(),
                descripcion: descCtrl.text.trim(),
                precio: double.tryParse(precioCtrl.text.trim()) ?? 0.0,
              );

              try {
                if (curso == null) {
                  await supa.addCurso(nuevoCurso);
                } else {
                  await supa.updateCurso(nuevoCurso);
                }
                if (!mounted) return;
                Navigator.pop(context);
                _cargarCursos();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error guardando curso: $e')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCurso(int id) async {
    try {
      await supa.deleteCurso(id);
      _cargarCursos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando curso: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Cursos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : cursos.isEmpty
              ? const Center(child: Text('No hay cursos registrados.'))
              : RefreshIndicator(
                  onRefresh: _cargarCursos,
                  child: ListView.builder(
                    itemCount: cursos.length,
                    itemBuilder: (context, index) {
                      final curso = cursos[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.book)),
                        title: Text(curso.nombre),
                        subtitle: Text(
                          '${curso.descripcion}\nPrecio: ${curso.precio.toStringAsFixed(2)} €',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _mostrarFormulario(curso),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: curso.id == null
                                  ? null
                                  : () => _eliminarCurso(curso.id!),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}