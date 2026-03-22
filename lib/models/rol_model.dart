// 📁 lib/models/rol_model.dart

class Rol {
  final int? idRol;
  final String nombreRol;
  final String? descripcion;

  Rol({
    this.idRol,
    required this.nombreRol,
    this.descripcion,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      idRol: json['id_rol'],
      nombreRol: json['nombre_rol'] ?? '',
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idRol != null) 'id_rol': idRol,
      'nombre_rol': nombreRol,
      'descripcion': descripcion,
    };
  }
}
