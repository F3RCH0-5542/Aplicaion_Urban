// lib/models/pedido_model.dart

class DetallePedido {
  final int? idDetalle;
  final int idProducto;
  final String? nombreProducto;
  final String? imagen;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final int? idPersonalizacion;

  DetallePedido({
    this.idDetalle,
    required this.idProducto,
    this.nombreProducto,
    this.imagen,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.idPersonalizacion,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) => DetallePedido(
        idDetalle: json['id_detalle'],
        idProducto: json['id_producto'] ?? 0,
        nombreProducto: json['nombre_producto'],
        imagen: json['imagen'],
        cantidad: json['cantidad'] ?? 0,
        precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0,
        subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
        idPersonalizacion: json['id_personalizacion'],
      );
}

class UsuarioPedido {
  final int idUsuario;
  final String nombre;
  final String apellido;
  final String correo;

  UsuarioPedido({
    required this.idUsuario,
    required this.nombre,
    required this.apellido,
    required this.correo,
  });

  factory UsuarioPedido.fromJson(Map<String, dynamic> json) => UsuarioPedido(
        idUsuario: json['id_usuario'] ?? 0,
        nombre: json['nombre'] ?? '',
        apellido: json['apellido'] ?? '',
        correo: json['correo'] ?? '',
      );

  String get nombreCompleto => '$nombre $apellido';
}

class EnvioPedido {
  final String? direccion;
  final String? ciudad;
  final String? telefono;
  final String? estadoEnvio;

  EnvioPedido({this.direccion, this.ciudad, this.telefono, this.estadoEnvio});

  factory EnvioPedido.fromJson(Map<String, dynamic> json) => EnvioPedido(
        direccion: json['direccion'],
        ciudad: json['ciudad'],
        telefono: json['telefono'],
        estadoEnvio: json['estado_envio'],
      );
}

class PagoPedido {
  final String? metodoPago;
  final double? monto;
  final String? estadoPago;
  final String? fechaPago;

  PagoPedido({this.metodoPago, this.monto, this.estadoPago, this.fechaPago});

  factory PagoPedido.fromJson(Map<String, dynamic> json) => PagoPedido(
        metodoPago: json['metodo_pago'],
        monto: double.tryParse(json['monto']?.toString() ?? '0'),
        estadoPago: json['estado_pago'],
        fechaPago: json['fecha_pago']?.toString(),
      );
}

class Pedido {
  final int? idPedido;
  final String? fechaPedido;
  final double total;
  final String estado;
  final String? metodoPago;
  final int idUsuario;
  final UsuarioPedido? usuario;
  final List<DetallePedido> detalles;
  final EnvioPedido? envio;
  final PagoPedido? pago;

  Pedido({
    this.idPedido,
    this.fechaPedido,
    required this.total,
    required this.estado,
    this.metodoPago,
    required this.idUsuario,
    this.usuario,
    this.detalles = const [],
    this.envio,
    this.pago,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        idPedido: json['id_pedido'],
        fechaPedido: json['fecha_pedido']?.toString(),
        total: double.tryParse(json['total'].toString()) ?? 0,
        estado: json['estado'] ?? 'pendiente',
        metodoPago: json['metodo_pago'],
        idUsuario: json['id_usuario'] ?? 0,
        usuario: json['Usuario'] != null
            ? UsuarioPedido.fromJson(json['Usuario'])
            : null,
        detalles: json['detalles'] != null
            ? (json['detalles'] as List)
                .map((d) => DetallePedido.fromJson(d))
                .toList()
            : [],
        envio: json['envio'] != null
            ? EnvioPedido.fromJson(json['envio'])
            : null,
        pago: json['pago'] != null
            ? PagoPedido.fromJson(json['pago'])
            : null,
      );
}