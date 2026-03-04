import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pago.dart';
import '../models/alumno.dart';
import '../models/curso.dart'; // import required to check the course if needed
import '../db/database_helper.dart';
import '../widgets/nuevo_pago_dialog.dart';

class PagosScreen extends StatefulWidget {
  final Alumno? alumno;
  final Curso? curso;

  const PagosScreen({Key? key, this.alumno, this.curso}) : super(key: key);

  @override
  _PagosScreenState createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Pago> pagos = [];
  Map<int, Alumno> mapaAlumnos = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final lsPagos = await dbHelper.getTodosLosPagos();
    final lsAlumnos = await dbHelper.getAlumnos();
    
    Map<int, Alumno> map = {};
    for (var a in lsAlumnos) {
      if (a.id != null) map[a.id!] = a;
    }

    setState(() {
      // Filtrar si vienen por alumno o curso desde la pantalla de matriculas.
      if (widget.alumno != null && widget.curso != null) {
        pagos = lsPagos.where((p) => p.idAlumno == widget.alumno!.id && p.idCurso == widget.curso!.id).toList();
      } else {
        pagos = lsPagos;
      }
      mapaAlumnos = map;
    });
  }

  void _mostrarNuevoPago() async {
    final lsAlumnos = await dbHelper.getAlumnos();
    if (lsAlumnos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay alumnos registrados')));
      return;
    }

    if (widget.alumno == null || widget.curso == null) {
        // En un futuro podríamos mejorar este diálogo genérico para que pida el curso
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desde aquí se requiere ir por una matrícula')));
        return;
    }

    final bool? registrado = await showDialog<bool>(
      context: context,
      builder: (context) => NuevoPagoDialog(alumnoId: widget.alumno!.id!, cursoId: widget.curso!.id!),
    );

    if (registrado == true) {
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.alumno != null ? 'Pagos de \${widget.alumno!.nombre}' : 'Registro de Pagos')),
      body: pagos.isEmpty
          ? const Center(child: Text('No hay pagos registrados.'))
          : ListView.builder(
              itemCount: pagos.length,
              itemBuilder: (context, index) {
                final pago = pagos[index];
                final alumno = mapaAlumnos[pago.idAlumno];
                DateTime? fecha;
                try {
                  fecha = DateTime.parse(pago.fecha);
                } catch(e) {
                  // Fallback
                }
                final fechaFormateada = fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : pago.fecha;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pago.pagado == 1 ? Colors.green : Colors.red, 
                    child: const Icon(Icons.attach_money, color: Colors.white)
                  ),
                  title: Text(alumno != null ? '\${alumno.nombre} \${alumno.apellido}' : 'Alumno Desconocido'),
                  subtitle: Text('Método: \${pago.metodo}\nFecha: \$fechaFormateada'),
                  trailing: Text('\$\${pago.cantidad.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  isThreeLine: true,
                );
              },
            ),
      floatingActionButton: (widget.alumno != null && widget.curso != null) ? FloatingActionButton(
        onPressed: _mostrarNuevoPago,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
