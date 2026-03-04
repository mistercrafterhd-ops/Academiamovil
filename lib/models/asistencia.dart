class Asistencia {
  final int? id;
  final int idAlumno;
  final int idCurso;
  final String fecha;
  final int presente;

  Asistencia({
    this.id,
    required this.idAlumno,
    required this.idCurso,
    required this.fecha,
    required this.presente,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_alumno': idAlumno,
      'id_curso': idCurso,
      'fecha': fecha,
      'presente': presente,
    };
  }

  factory Asistencia.fromMap(Map<String, dynamic> map) {
    return Asistencia(
      id: map['id'] as int?,
      idAlumno: map['id_alumno'] as int,
      idCurso: map['id_curso'] as int,
      fecha: map['fecha'] as String,
      presente: (map['presente'] ?? 0) as int,
    );
  }
}
