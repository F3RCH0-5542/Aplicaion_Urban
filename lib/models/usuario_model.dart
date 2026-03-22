// lib/models/usuario_model.dart

// Clase auxiliar para datos personales
class UsuarioDatosPersonales {
  final String nombre;
  final String apellido;
  final String? documento;

  const UsuarioDatosPersonales({
    required this.nombre,
    required this.apellido,
    this.documento,
  });
}

// Clase auxiliar para datos de acceso
class UsuarioAcceso {
  final String email;
  final String? usuario;
  final int idRol;
  final String? nombreRol;

  const UsuarioAcceso({
    required this.email,
    this.usuario,
    required this.idRol,
    this.nombreRol,
  });
}

class Usuario {
  final int? idUsuario;
  final UsuarioDatosPersonales datosPersonales;
  final UsuarioAcceso acceso;
  final DateTime? fechaRegistro;
  final bool? activo;

  // Getters de conveniencia para compatibilidad con el código existente
  String get nombre      => datosPersonales.nombre;
  String get apellido    => datosPersonales.apellido;
  String? get documento  => datosPersonales.documento;
  String get email       => acceso.email;
  String? get usuario    => acceso.usuario;
  int get idRol          => acceso.idRol;
  String? get nombreRol  => acceso.nombreRol;
  String get nombreCompleto => '${datosPersonales.nombre} ${datosPersonales.apellido}'.trim();

  const Usuario({
    this.idUsuario,
    required this.datosPersonales,
    required this.acceso,
    this.fechaRegistro,
    this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        idUsuario: json['id_usuario'],
        datosPersonales: UsuarioDatosPersonales(
          nombre:    json['nombre'] ?? '',
          apellido:  json['apellido'] ?? '',
          documento: json['documento']?.toString(),
        ),
        acceso: UsuarioAcceso(
          email:     json['correo'] ?? '',
          usuario:   json['usuario'],
          idRol:     json['id_rol'] ?? 3,
          nombreRol: json['Rol']?['nombre_rol'] ?? json['nombre_rol'],
        ),
        fechaRegistro: json['fecha_registro'] != null
            ? DateTime.tryParse(json['fecha_registro'].toString())
            : null,
        activo: json['activo'],
      );

  Map<String, dynamic> toJson() => {
        if (idUsuario != null) 'id_usuario': idUsuario,
        'nombre':   nombre,
        'apellido': apellido,
        'correo':   email,
        if (documento != null) 'documento': documento,
        if (usuario != null)   'usuario':   usuario,
        'id_rol':   idRol,
        if (activo != null) 'activo': activo,
      };

  Usuario copyWith({
    int? idUsuario,
    UsuarioDatosPersonales? datosPersonales,
    UsuarioAcceso? acceso,
    DateTime? fechaRegistro,
    bool? activo,
  }) =>
      Usuario(
        idUsuario:       idUsuario       ?? this.idUsuario,
        datosPersonales: datosPersonales ?? this.datosPersonales,
        acceso:          acceso          ?? this.acceso,
        fechaRegistro:   fechaRegistro   ?? this.fechaRegistro,
        activo:          activo          ?? this.activo,
      );
}