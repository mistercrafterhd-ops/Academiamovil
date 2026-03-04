import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/curso.dart';
import '../models/alumno.dart';
import '../services/supabase_service.dart';

class AsistenciasScreen extends StatefulWidget {
  final Alumno? alumno;
  final Curso? curso;

  const AsistenciasScreen({Key? key, this.alumno, this.curso}) : super(key: key);

  @override
  State<AsistenciasScreen> createState() => _AsistenciasScreenState();
}

class _AsistenciasScreenState extends State<AsistenciasScreen> {
  final supa = SupabaseService.instance;

  List<Curso> cursos = [];
  Curso? cursoSeleccionado;
  DateTime fechaSeleccionada = DateTime.now();

  List<Alumno> alumnosCurso = [];
  Map<int, bool> valoresAsistencia = {};

  bool cargandoCursos = true;
  bool cargandoAlumnos = false;

  @override
  void initState() {
    super.initState();
    cursoSeleccionado = widget.curso;
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    setState(() => cargandoCursos = true);
    try {
      final data = await supa.getCursos();

      // Solo cursos con id válido
      final lista = data.where((c) => c.id != null).toList();

      setState(() {
        cursos = lista;

        // si viene curso por parámetro, asegúrate de que existe en la lista
        if (cursoSeleccionado != null) {
          final existe = cursos.any((c) => c.id == cursoSeleccionado!.id);
          if (!existe) cursoSeleccionado = null;
        }

        // si no hay curso seleccionado, selecciona el primero
        cursoSeleccionado ??= (cursos.isNotEmpty ? cursos.first : null);
      });

      if (cursoSeleccionado != null) {
        await _cargarAsistencias();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando cursos: $e')),
      );
    } finally {
      if (mounted) setState(() => cargandoCursos = false);
    }
  }

  Future<void> _cargarAsistencias() async {
    if (cursoSeleccionado?.id == null) return;

    setState(() => cargandoAlumnos = true);
    try {
      final cursoId = cursoSeleccionado!.id!;
      final strFecha = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);

      // 1) alumnos matriculados en ese curso
      final alumnos = await supa.getAlumnosMatriculadosPorCurso(cursoId);

      // 2) mapa asistencias ya guardadas para ese día
      final mapaGuardado = await supa.getAsistenciasMap(
        cursoId: cursoId,
        fechaYYYYMMDD: strFecha,
      );

      // 3) construir valores para la UI
      final valores = <int, bool>{};
      for (final alum in alumnos) {
        if (alum.id == null) continue;
        valores[alum.id!] = mapaGuardado[alum.id!] ?? false;
      }

      setState(() {
        alumnosCurso = alumnos;
        valoresAsistencia = valores;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando asistencias: $e')),
      );
    } finally {
      if (mounted) setState(() => cargandoAlumnos = false);
    }
  }

  Future<void> _guardarAsistencias() async {
    if (cursoSeleccionado?.id == null) return;

    final cursoId = cursoSeleccionado!.id!;
    final strFecha = DateFormat('yyyy-MM-dd').format(fechaSeleccionada);

    // si entraste filtrado por un alumno, guarda solo ese alumno
    Map<int, bool> aGuardar = valoresAsistencia;
    if (widget.alumno?.id != null) {
      final id = widget.alumno!.id!;
      aGuardar = {id: valoresAsistencia[id] ?? false};
    }

    try {
      await supa.upsertAsistencias(
        cursoId: cursoId,
        fechaYYYYMMDD: strFecha,
        presentesPorAlumnoId: aGuardar,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Asistencias guardadas')),
      );

      // recargar para confirmar
      await _cargarAsistencias();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error guardando asistencias: $e')),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != fechaSeleccionada) {
      setState(() => fechaSeleccionada = picked);
      await _cargarAsistencias();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaTxt = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Asistencias')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: cargandoCursos
                      ? const LinearProgressIndicator()
                      : DropdownButton<Curso>(
                          isExpanded: true,
                          hint: const Text('Seleccionar Curso'),
                          value: cursoSeleccionado,
                          items: cursos
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.nombre),
                                  ))
                              .toList(),
                          onChanged: (val) async {
                            setState(() => cursoSeleccionado = val);
                            await _cargarAsistencias();
                          },
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _seleccionarFecha,
                ),
                Text(fechaTxt),
              ],
            ),
          ),

          Expanded(
            child: (cursoSeleccionado == null)
                ? const Center(child: Text('Seleccione un curso para ver los alumnos matriculados.'))
                : cargandoAlumnos
                    ? const Center(child: CircularProgressIndicator())
                    : alumnosCurso.isEmpty
                        ? const Center(child: Text('No hay alumnos matriculados en este curso.'))
                        : ListView.builder(
                            itemCount: alumnosCurso.length,
                            itemBuilder: (context, index) {
                              final alumno = alumnosCurso[index];

                              if (widget.alumno?.id != null && widget.alumno!.id != alumno.id) {
                                return const SizedBox.shrink();
                              }

                              return CheckboxListTile(
                                title: Text('${alumno.nombre} ${alumno.apellido}'),
                                subtitle: Text('DNI: ${alumno.dni}'),
                                value: (alumno.id != null) ? (valoresAsistencia[alumno.id!] ?? false) : false,
                                onChanged: (val) {
                                  if (alumno.id == null) return;
                                  setState(() {
                                    valoresAsistencia[alumno.id!] = val ?? false;
                                  });
                                },
                              );
                            },
                          ),
          ),

          if (cursoSeleccionado != null && alumnosCurso.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _guardarAsistencias,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Guardar Asistencias'),
              ),
            ),
        ],
      ),
    );
  }
}