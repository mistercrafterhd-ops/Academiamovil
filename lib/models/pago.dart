class Pago {
  final int? id;
  final int idAlumno;
  final int idCurso;
  final String fecha;
  final double cantidad;
  final String metodo;
  final int pagado;

  Pago({
    this.id,
    required this.idAlumno,
    required this.idCurso,
    required this.fecha,
    required this.cantidad,
    required this.metodo,
    required this.pagado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_alumno': idAlumno,
      'id_curso': idCurso,
      'fecha': fecha,
      'cantidad': cantidad,
      'metodo': metodo,
      'pagado': pagado,
    };
  }

  factory Pago.fromMap(Map<String, dynamic> map) {
    return Pago(
      id: map['id'] as int?,
      idAlumno: map['id_alumno'] as int,
      idCurso: map['id_curso'] as int,
      fecha: map['fecha'] as String,
      cantidad: map['cantidad'] is int
          ? (map['cantidad'] as int).toDouble()
          : (map['cantidad'] as double),
      metodo: (map['metodo'] ?? 'EFECTIVO') as String,
      pagado: (map['pagado'] ?? 0) as int,
    );
  }
}
