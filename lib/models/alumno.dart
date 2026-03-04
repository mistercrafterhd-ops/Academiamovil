class Alumno {
  final int? id;
  final String nombre;
  final String apellido;
  final String dni;

  Alumno({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.dni,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
    };
  }

  factory Alumno.fromMap(Map<String, dynamic> map) {
    return Alumno(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      dni: map['dni'] ?? '',
    );
  }
}