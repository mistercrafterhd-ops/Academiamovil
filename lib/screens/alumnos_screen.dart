import 'package:flutter/material.dart';
import '../models/alumno.dart';
import '../services/supabase_service.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({Key? key}) : super(key: key);

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  final supa = SupabaseService.instance;

  List<Alumno> alumnos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  Future<void> _cargarAlumnos() async {
    setState(() => cargando = true);
    try {
      final data = await supa.getAlumnos();
      setState(() {
        alumnos = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando alumnos: $e')),
      );
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  void _mostrarFormulario([Alumno? alumno]) {
    final nombreCtrl = TextEditingController(text: alumno?.nombre ?? '');
    final apellidoCtrl = TextEditingController(text: alumno?.apellido ?? '');
    final dniCtrl = TextEditingController(text: alumno?.dni ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alumno == null ? 'Nuevo Alumno' : 'Editar Alumno'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: apellidoCtrl,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              TextField(
                controller: dniCtrl,
                decoration: const InputDecoration(labelText: 'DNI'),
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
                  apellidoCtrl.text.trim().isEmpty ||
                  dniCtrl.text.trim().isEmpty) {
                return;
              }

              final nuevoAlumno = Alumno(
                id: alumno?.id,
                nombre: nombreCtrl.text.trim(),
                apellido: apellidoCtrl.text.trim(),
                dni: dniCtrl.text.trim(),
              );

              try {
                if (alumno == null) {
                  await supa.addAlumno(nuevoAlumno);
                } else {
                  // Necesitas este método en el service (te lo dejo abajo)
                  await supa.updateAlumno(nuevoAlumno);
                }

                if (!mounted) return;
                Navigator.pop(context);
                _cargarAlumnos();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error guardando: $e')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarAlumno(int id) async {
    try {
      await supa.deleteAlumno(id);
      _cargarAlumnos();
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
      appBar: AppBar(title: const Text('Gestión de Alumnos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : alumnos.isEmpty
              ? const Center(child: Text('No hay alumnos registrados.'))
              : RefreshIndicator(
                  onRefresh: _cargarAlumnos,
                  child: ListView.builder(
                    itemCount: alumnos.length,
                    itemBuilder: (context, index) {
                      final alumno = alumnos[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${alumno.nombre} ${alumno.apellido}'),
                        subtitle: Text('DNI: ${alumno.dni}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _mostrarFormulario(alumno),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: alumno.id == null
                                  ? null
                                  : () => _eliminarAlumno(alumno.id!),
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