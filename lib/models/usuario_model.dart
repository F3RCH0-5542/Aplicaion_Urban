// lib/models/usuario_model.dart

class Usuario {
  final int? idUsuario;
  final String nombre;
  final String apellido;
  final String? documento;
  final String email;
  final String? usuario;
  final int idRol;
  final String? nombreRol;
  final DateTime? fechaRegistro;
  final bool? activo;

  Usuario({
    this.idUsuario,
    required this.nombre,
    required this.apellido,
    this.documento,
    required this.email,
    this.usuario,
    required this.idRol,
    this.nombreRol,
    this.fechaRegistro,
    this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      documento: json['documento']?.toString(),
      email: json['correo'] ?? '',
      usuario: json['usuario'],
      idRol: json['id_rol'] ?? 3,
      nombreRol: json['Rol']?['nombre_rol'] ?? json['nombre_rol'],
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'].toString())
          : null,
      activo: json['activo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idUsuario != null) 'id_usuario': idUsuario,
      'nombre': nombre,
      'apellido': apellido,
      'correo': email,
      if (documento != null) 'documento': documento,
      if (usuario != null) 'usuario': usuario,
      'id_rol': idRol,
      if (activo != null) 'activo': activo,
    };
  }

  Usuario copyWith({
    int? idUsuario,
    String? nombre,
    String? apellido,
    String? documento,
    String? email,
    String? usuario,
    int? idRol,
    String? nombreRol,
    DateTime? fechaRegistro,
    bool? activo,
  }) {
    return Usuario(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      documento: documento ?? this.documento,
      email: email ?? this.email,
      usuario: usuario ?? this.usuario,
      idRol: idRol ?? this.idRol,
      nombreRol: nombreRol ?? this.nombreRol,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      activo: activo ?? this.activo,
    );
  }
}