// lib/models/pqrs.dart
class Pqrs {
  final int? idPqrs;
  final int idUsuario;
  final String? nombreUsuario;
  final String nombre; // ✅ Agregado
  final String correo; // ✅ Agregado
  final String tipo;
  final String asunto;
  final String descripcion;
  final String estado;
  final String? respuesta;
  final DateTime? fechaCreacion;
  final DateTime? fechaRespuesta;

  Pqrs({
    this.idPqrs,
    required this.idUsuario,
    this.nombreUsuario,
    required this.nombre,
    required this.correo,
    required this.tipo,
    this.asunto = '', // ✅ Opcional con default
    required this.descripcion,
    this.estado = 'pendiente',
    this.respuesta,
    this.fechaCreacion,
    this.fechaRespuesta,
  });

  // ✅ ACTUALIZADO: Ajustado a la respuesta real del backend
  factory Pqrs.fromJson(Map<String, dynamic> json) {
    return Pqrs(
      idPqrs: json['id_pqrs'],
      idUsuario: json['id_usuario'] ?? 0, // Si es null, usa 0
      nombreUsuario: json['Usuario'] != null
          ? '${json['Usuario']['nombre']} ${json['Usuario']['apellido']}'
          : json['nombre'], // ✅ Usa el nombre del JSON si no hay Usuario
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      tipo: (json['tipo_pqrs'] ?? 'peticion')
          .toString()
          .toLowerCase(), // ✅ Normaliza a minúsculas
      asunto: json['asunto'] ??
          json['tipo_pqrs'] ??
          '', // Usa tipo_pqrs como asunto si no existe
      descripcion: json['descripcion'] ?? '',
      estado: (json['estado'] ?? 'pendiente')
          .toString()
          .toLowerCase(), // ✅ Normaliza a minúsculas
      respuesta: json['respuesta']?.toString().isEmpty ?? true
          ? null
          : json['respuesta'],
      fechaCreacion: json['fecha_solicitud'] != null // ✅ Usa 'fecha_solicitud'
          ? DateTime.parse(json['fecha_solicitud'])
          : null,
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idPqrs != null) 'id_pqrs': idPqrs,
      'id_usuario': idUsuario,
      'nombre': nombre,
      'correo': correo,
      'tipo_pqrs': tipo,
      'asunto': asunto,
      'descripcion': descripcion,
      'estado': estado,
      'respuesta': respuesta,
    };
  }

  Pqrs copyWith({
    int? idPqrs,
    int? idUsuario,
    String? nombreUsuario,
    String? nombre,
    String? correo,
    String? tipo,
    String? asunto,
    String? descripcion,
    String? estado,
    String? respuesta,
    DateTime? fechaCreacion,
    DateTime? fechaRespuesta,
  }) {
    return Pqrs(
      idPqrs: idPqrs ?? this.idPqrs,
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      tipo: tipo ?? this.tipo,
      asunto: asunto ?? this.asunto,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      respuesta: respuesta ?? this.respuesta,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
    );
  }

  String get tipoDisplay {
    switch (tipo.toLowerCase()) {
      case 'peticion':
        return 'Petición';
      case 'queja':
        return 'Queja';
      case 'reclamo':
        return 'Reclamo';
      case 'sugerencia':
        return 'Sugerencia';
      default:
        return tipo;
    }
  }

  String get estadoDisplay {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en proceso':
      case 'en_proceso':
        return 'En Proceso';
      case 'resuelto':
        return 'Resuelto';
      case 'cerrado':
        return 'Cerrado';
      default:
        return estado;
    }
  }
}
