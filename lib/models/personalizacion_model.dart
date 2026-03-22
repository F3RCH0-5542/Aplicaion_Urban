// lib/models/personalizacion_model.dart

class Personalizacion {
  final int? idPersonalizacion;
  final int? idPedido;
  final int? idProducto;
  final String? descripcionPersonalizacion;
  final String? tipoPersonalizacion;
  final String? imagenReferencia;
  final String? colorDeseado;
  final String? talla;
  final String estado;
  final double precioAdicional;
  final ProductoResumen? producto;
  final PedidoResumen? pedido;

  Personalizacion({
    this.idPersonalizacion,
    this.idPedido,
    this.idProducto,
    this.descripcionPersonalizacion,
    this.tipoPersonalizacion,
    this.imagenReferencia,
    this.colorDeseado,
    this.talla,
    required this.estado,
    required this.precioAdicional,
    this.producto,
    this.pedido,
  });

  // Helpers para búsqueda en pantalla admin
  String get nombreUsuario =>
      pedido?.usuario?.nombreCompleto ?? '';

  String get descripcion =>
      descripcionPersonalizacion ?? '';

  factory Personalizacion.fromJson(Map<String, dynamic> json) {
    return Personalizacion(
      idPersonalizacion:          json['id_personalizacion'],
      idPedido:                   json['id_pedido'],
      idProducto:                 json['id_producto'],
      descripcionPersonalizacion: json['descripcion_personalizacion'],
      tipoPersonalizacion:        json['tipo_personalizacion'],
      imagenReferencia:           json['imagen_referencia'],
      colorDeseado:               json['color_deseado'],
      talla:                      json['talla'],
      estado:                     json['estado'] ?? 'pendiente',
      precioAdicional:
          double.tryParse(json['precio_adicional']?.toString() ?? '0') ?? 0.0,
      producto: json['Producto'] != null
          ? ProductoResumen.fromJson(json['Producto'])
          : null,
      pedido: json['Pedido'] != null
          ? PedidoResumen.fromJson(json['Pedido'])
          : null,
    );
  }
}

class ProductoResumen {
  final int idProducto;
  final String nombre;
  final double precio;
  final String? imagen;

  ProductoResumen({
    required this.idProducto,
    required this.nombre,
    required this.precio,
    this.imagen,
  });

  factory ProductoResumen.fromJson(Map<String, dynamic> json) =>
      ProductoResumen(
        idProducto: json['id_producto'],
        nombre:     json['nombre'] ?? '',
        precio:     double.tryParse(json['precio']?.toString() ?? '0') ?? 0.0,
        imagen:     json['imagen'],
      );
}

class PedidoResumen {
  final int idPedido;
  final String? fechaPedido;
  final double total;
  final String? estado;
  final UsuarioResumen? usuario;

  PedidoResumen({
    required this.idPedido,
    this.fechaPedido,
    required this.total,
    this.estado,
    this.usuario,
  });

  factory PedidoResumen.fromJson(Map<String, dynamic> json) => PedidoResumen(
        idPedido:    json['id_pedido'],
        fechaPedido: json['fecha_pedido']?.toString(),
        total:       double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
        estado:      json['estado'],
        usuario:     json['Usuario'] != null
            ? UsuarioResumen.fromJson(json['Usuario'])
            : null,
      );
}

class UsuarioResumen {
  final String nombre;
  final String apellido;
  final String correo;

  UsuarioResumen({
    required this.nombre,
    required this.apellido,
    required this.correo,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory UsuarioResumen.fromJson(Map<String, dynamic> json) => UsuarioResumen(
        nombre:   json['nombre'] ?? '',
        apellido: json['apellido'] ?? '',
        correo:   json['correo'] ?? '',
      );
}