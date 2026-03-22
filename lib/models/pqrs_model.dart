// lib/models/pqrs_model.dart

// Clase auxiliar para agrupar datos del solicitante
class PqrsSolicitante {
  final int idUsuario;
  final String? nombreUsuario;
  final String nombre;
  final String correo;

  const PqrsSolicitante({
    required this.idUsuario,
    this.nombreUsuario,
    required this.nombre,
    required this.correo,
  });
}

// Clase auxiliar para agrupar datos de la solicitud
class PqrsContenido {
  final String tipo;
  final String asunto;
  final String descripcion;

  const PqrsContenido({
    required this.tipo,
    this.asunto = '',
    required this.descripcion,
  });
}

// Clase auxiliar para agrupar estado y respuesta
class PqrsEstado {
  final String estado;
  final String? respuesta;
  final DateTime? fechaCreacion;
  final DateTime? fechaRespuesta;

  const PqrsEstado({
    this.estado = 'pendiente',
    this.respuesta,
    this.fechaCreacion,
    this.fechaRespuesta,
  });
}

class Pqrs {
  final int? idPqrs;
  final PqrsSolicitante solicitante;
  final PqrsContenido contenido;
  final PqrsEstado estadoInfo;

  // Getters de conveniencia para compatibilidad con el código existente
  int get idUsuario       => solicitante.idUsuario;
  String? get nombreUsuario => solicitante.nombreUsuario;
  String get nombre       => solicitante.nombre;
  String get correo       => solicitante.correo;
  String get tipo         => contenido.tipo;
  String get asunto       => contenido.asunto;
  String get descripcion  => contenido.descripcion;
  String get estado       => estadoInfo.estado;
  String? get respuesta   => estadoInfo.respuesta;
  DateTime? get fechaCreacion   => estadoInfo.fechaCreacion;
  DateTime? get fechaRespuesta  => estadoInfo.fechaRespuesta;

  const Pqrs({
    this.idPqrs,
    required this.solicitante,
    required this.contenido,
    required this.estadoInfo,
  });

  factory Pqrs.fromJson(Map<String, dynamic> json) {
    final tipoRaw   = (json['tipo_pqrs'] ?? 'peticion').toString().toLowerCase();
    final estadoRaw = (json['estado'] ?? 'pendiente').toString().toLowerCase();
    final respuestaRaw = json['respuesta']?.toString();

    return Pqrs(
      idPqrs: json['id_pqrs'],
      solicitante: PqrsSolicitante(
        idUsuario: json['id_usuario'] ?? 0,
        nombreUsuario: json['Usuario'] != null
            ? '${json['Usuario']['nombre']} ${json['Usuario']['apellido']}'
            : json['nombre'],
        nombre: json['nombre'] ?? '',
        correo: json['correo'] ?? '',
      ),
      contenido: PqrsContenido(
        tipo:        tipoRaw,
        asunto:      json['asunto'] ?? json['tipo_pqrs'] ?? '',
        descripcion: json['descripcion'] ?? '',
      ),
      estadoInfo: PqrsEstado(
        estado:    estadoRaw,
        respuesta: (respuestaRaw == null || respuestaRaw.isEmpty)
            ? null
            : respuestaRaw,
        fechaCreacion: json['fecha_solicitud'] != null
            ? DateTime.tryParse(json['fecha_solicitud'])
            : null,
        fechaRespuesta: json['fecha_respuesta'] != null
            ? DateTime.tryParse(json['fecha_respuesta'])
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        if (idPqrs != null) 'id_pqrs': idPqrs,
        'id_usuario':  idUsuario,
        'nombre':      nombre,
        'correo':      correo,
        'tipo_pqrs':   tipo,
        'asunto':      asunto,
        'descripcion': descripcion,
        'estado':      estado,
        'respuesta':   respuesta,
      };

  Pqrs copyWith({
    int? idPqrs,
    PqrsSolicitante? solicitante,
    PqrsContenido? contenido,
    PqrsEstado? estadoInfo,
  }) =>
      Pqrs(
        idPqrs:      idPqrs      ?? this.idPqrs,
        solicitante: solicitante ?? this.solicitante,
        contenido:   contenido   ?? this.contenido,
        estadoInfo:  estadoInfo  ?? this.estadoInfo,
      );

  // Helper para cambiar solo el estado/respuesta fácilmente
  Pqrs conEstado(String nuevoEstado, {String? nuevaRespuesta}) => copyWith(
        estadoInfo: PqrsEstado(
          estado:        nuevoEstado,
          respuesta:     nuevaRespuesta ?? respuesta,
          fechaCreacion: fechaCreacion,
          fechaRespuesta: nuevaRespuesta != null ? DateTime.now() : fechaRespuesta,
        ),
      );

  String get tipoDisplay {
    switch (tipo) {
      case 'peticion':   return 'Petición';
      case 'queja':      return 'Queja';
      case 'reclamo':    return 'Reclamo';
      case 'sugerencia': return 'Sugerencia';
      default:           return tipo;
    }
  }

  String get estadoDisplay {
    switch (estado) {
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