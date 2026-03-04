import 'package:flutter/material.dart';
import 'alumnos_screen.dart';
import 'cursos_screen.dart';
import 'matriculas_screen.dart';
import 'asistencias_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academia Móvil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            Text(
              'Bienvenido a la Gestión de Academia',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

           ElevatedButton.icon(
  icon: const Icon(Icons.people),
  label: const Text('Gestionar Alumnos'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlumnosScreen()),
    );
  },
),

const SizedBox(height: 10),

ElevatedButton.icon(
  icon: const Icon(Icons.how_to_reg),
  label: const Text('Gestionar Matrículas'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatriculasScreen()),
    );
  },
),

const SizedBox(height: 10),

ElevatedButton.icon(
  icon: const Icon(Icons.fact_check),
  label: const Text('Gestionar Asistencias'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AsistenciasScreen()),
    );
  },
),

const SizedBox(height: 10),

ElevatedButton.icon(
  icon: const Icon(Icons.class_),
  label: const Text('Gestionar Cursos'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CursosScreen()),
    );
  },
),
          ],
        ),
      ),
    );
  }
  
}