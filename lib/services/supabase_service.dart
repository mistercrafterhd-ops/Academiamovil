import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alumno.dart';
import '../models/curso.dart';
import '../models/matricula.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ===================== ALUMNOS =====================

  Future<List<Alumno>> getAlumnos() async {
    final data = await _db.from('alumnos').select().order('id');
    return (data as List)
        .map((json) => Alumno.fromMap(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> addAlumno(Alumno alumno) async {
    await _db.from('alumnos').insert(alumno.toMap());
  }

  Future<void> updateAlumno(Alumno alumno) async {
    if (alumno.id == null) throw Exception('Alumno sin id');
    await _db.from('alumnos').update(alumno.toMap()).eq('id', alumno.id!);
  }

  Future<void> deleteAlumno(int id) async {
    await _db.from('alumnos').delete().eq('id', id);
  }

  // ===================== CURSOS =====================

  Future<List<Curso>> getCursos() async {
    final data = await _db.from('cursos').select().order('id');
    return (data as List)
        .map((json) => Curso.fromMap(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<void> addCurso(Curso curso) async {
    await _db.from('cursos').insert(curso.toMap());
  }

  Future<void> updateCurso(Curso curso) async {
    if (curso.id == null) throw Exception('Curso sin id');
    await _db.from('cursos').update(curso.toMap()).eq('id', curso.id!);
  }

  Future<void> deleteCurso(int id) async {
    await _db.from('cursos').delete().eq('id', id);
  }
  // ===================== MATRÍCULAS =====================

// Lista matrículas con join para mostrar nombre del alumno y curso
Future<List<Map<String, dynamic>>> getMatriculasJoined() async {
  final data = await _db
      .from('matriculas')
      .select('id, fecha_matricula, alumno_id, curso_id, alumnos(nombre, apellido, dni), cursos(nombre, precio)')
      .order('id');

  return List<Map<String, dynamic>>.from(data as List);
}

Future<void> addMatricula(Matricula matricula) async {
  await _db.from('matriculas').insert(matricula.toMap());
}

Future<void> deleteMatricula(int id) async {
  await _db.from('matriculas').delete().eq('id', id);
}
// ===================== ASISTENCIAS =====================

// 1) Alumnos matriculados en un curso (join matriculas -> alumnos)
Future<List<Alumno>> getAlumnosMatriculadosPorCurso(int cursoId) async {
  final data = await _db
      .from('matriculas')
      .select('alumno_id, alumnos(id, nombre, apellido, dni)')
      .eq('curso_id', cursoId);

  final alumnosJson = (data as List)
      .map((row) => row['alumnos'])
      .where((a) => a != null)
      .map((a) => Map<String, dynamic>.from(a))
      .toList();

  return alumnosJson.map((j) => Alumno.fromMap(j)).toList();
}

// 2) Asistencias guardadas para un curso y fecha (para precargar checks)
Future<Map<int, bool>> getAsistenciasMap({
  required int cursoId,
  required String fechaYYYYMMDD,
}) async {
  final data = await _db
      .from('asistencias')
      .select('alumno_id, presente')
      .eq('curso_id', cursoId)
      .eq('fecha', fechaYYYYMMDD);

  final map = <int, bool>{};
  for (final row in (data as List)) {
    final alumnoId = (row['alumno_id'] as num).toInt();
    final presente = row['presente'] as bool? ?? false;
    map[alumnoId] = presente;
  }
  return map;
}

// 3) Guardar/actualizar asistencias en bloque (UPSERT)
Future<void> upsertAsistencias({
  required int cursoId,
  required String fechaYYYYMMDD,
  required Map<int, bool> presentesPorAlumnoId,
}) async {
  final rows = presentesPorAlumnoId.entries.map((e) {
    return {
      'alumno_id': e.key,
      'curso_id': cursoId,
      'fecha': fechaYYYYMMDD,
      'presente': e.value,
    };
  }).toList();

  await _db.from('asistencias').upsert(rows);
}
}