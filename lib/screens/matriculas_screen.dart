import 'package:flutter/material.dart';
import '../models/alumno.dart';
import '../models/curso.dart';
import '../models/matricula.dart';
import '../services/supabase_service.dart';

class MatriculasScreen extends StatefulWidget {
  const MatriculasScreen({Key? key}) : super(key: key);

  @override
  State<MatriculasScreen> createState() => _MatriculasScreenState();
}

class _MatriculasScreenState extends State<MatriculasScreen> {
  final supa = SupabaseService.instance;

  List<Alumno> alumnos = [];
  List<Curso> cursos = [];
  List<Map<String, dynamic>> matriculas = [];

  int? alumnoSeleccionadoId;
  int? cursoSeleccionadoId;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => cargando = true);
    try {
      final a = await supa.getAlumnos();
      final c = await supa.getCursos();
      final m = await supa.getMatriculasJoined();

      setState(() {
        alumnos = a;
        cursos = c;
        matriculas = m;
        // Selecciones por defecto (si hay datos)
        alumnoSeleccionadoId = alumnos.isNotEmpty ? alumnos.first.id : null;
        cursoSeleccionadoId = cursos.isNotEmpty ? cursos.first.id : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando matrículas: $e')),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _crearMatricula() async {
    if (alumnoSeleccionadoId == null || cursoSeleccionadoId == null) return;

    try {
      await supa.addMatricula(
        Matricula(alumnoId: alumnoSeleccionadoId!, cursoId: cursoSeleccionadoId!),
      );
      await _refrescarMatriculas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Matrícula creada')),
      );
    } catch (e) {
      // Si tienes UNIQUE (alumno_id, curso_id), aquí caerá si ya existe
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo matricular: $e')),
      );
    }
  }

  Future<void> _refrescarMatriculas() async {
    final m = await supa.getMatriculasJoined();
    setState(() => matriculas = m);
  }

  Future<void> _eliminarMatricula(int id) async {
    try {
      await supa.deleteMatricula(id);
      await _refrescarMatriculas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑 Matrícula eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrículas')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // --- Selector alumno/curso + botón matricular ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            value: alumnoSeleccionadoId,
                            decoration: const InputDecoration(labelText: 'Alumno'),
                            items: alumnos
                                .where((a) => a.id != null)
                                .map((a) => DropdownMenuItem(
                                      value: a.id!,
                                      child: Text('${a.nombre} ${a.apellido} (${a.dni})'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => alumnoSeleccionadoId = v),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: cursoSeleccionadoId,
                            decoration: const InputDecoration(labelText: 'Curso'),
                            items: cursos
                                .where((c) => c.id != null)
                                .map((c) => DropdownMenuItem(
                                      value: c.id!,
                                      child: Text('${c.nombre} - ${c.precio.toStringAsFixed(2)} €'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => cursoSeleccionadoId = v),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _crearMatricula,
                              icon: const Icon(Icons.how_to_reg),
                              label: const Text('Matricular'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- Lista matrículas ---
                  Expanded(
                    child: matriculas.isEmpty
                        ? const Center(child: Text('No hay matrículas registradas.'))
                        : RefreshIndicator(
                            onRefresh: _refrescarMatriculas,
                            child: ListView.builder(
                              itemCount: matriculas.length,
                              itemBuilder: (context, index) {
                                final m = matriculas[index];
                                final id = m['id'] as int;

                                final alumno = m['alumnos']; // join
                                final curso = m['cursos']; // join

                                final alumnoTxt = alumno != null
                                    ? '${alumno['nombre']} ${alumno['apellido']} (${alumno['dni']})'
                                    : 'Alumno ID: ${m['alumno_id']}';

                                final cursoTxt = curso != null
                                    ? '${curso['nombre']} - ${curso['precio']} €'
                                    : 'Curso ID: ${m['curso_id']}';

                                final fecha = m['fecha_matricula']?.toString() ?? '';

                                return ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.school)),
                                  title: Text(alumnoTxt),
                                  subtitle: Text('$cursoTxt\nFecha: $fecha'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarMatricula(id),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}