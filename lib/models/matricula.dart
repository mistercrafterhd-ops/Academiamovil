class Matricula {
  final int? id;
  final int alumnoId;
  final int cursoId;
  final String? fechaMatricula; // YYYY-MM-DD

  Matricula({
    this.id,
    required this.alumnoId,
    required this.cursoId,
    this.fechaMatricula,
  });

  Map<String, dynamic> toMap() {
    return {
      'alumno_id': alumnoId,
      'curso_id': cursoId,
      // fecha_matricula la pone la BD por defecto, pero si quieres enviarla:
      if (fechaMatricula != null) 'fecha_matricula': fechaMatricula,
    };
  }

  factory Matricula.fromMap(Map<String, dynamic> map) {
    return Matricula(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      alumnoId: map['alumno_id'] is int
          ? map['alumno_id']
          : int.parse(map['alumno_id'].toString()),
      cursoId: map['curso_id'] is int
          ? map['curso_id']
          : int.parse(map['curso_id'].toString()),
      fechaMatricula: map['fecha_matricula']?.toString(),
    );
  }
}