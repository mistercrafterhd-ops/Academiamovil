class Curso {
  final int? id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? fechaInicio;
  final String? fechaFin;

  Curso({
    this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.fechaInicio,
    this.fechaFin,
  });

  // ✅ Para Supabase: NO mandes el id (lo crea la BD)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
    };
  }

  factory Curso.fromMap(Map<String, dynamic> map) {
    final rawPrecio = map['precio'];
    double precioParsed = 0.0;
    if (rawPrecio is num) {
      precioParsed = rawPrecio.toDouble();
    } else if (rawPrecio != null) {
      precioParsed = double.tryParse(rawPrecio.toString()) ?? 0.0;
    }

    return Curso(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      nombre: (map['nombre'] ?? '') as String,
      descripcion: (map['descripcion'] ?? '') as String,
      precio: precioParsed,
      fechaInicio: map['fecha_inicio']?.toString(),
      fechaFin: map['fecha_fin']?.toString(),
    );
  }
}