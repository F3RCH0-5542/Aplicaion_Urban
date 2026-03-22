// lib/models/inventario_model.dart

class Movimiento {
  final int? idInventario;
  final int idProducto;
  final String tipo;
  final int cantidad;
  final int stockResultante;
  final int stockMinimo;
  final String? motivo;
  final String? idReferencia;
  final DateTime? fechaMovimiento;
  // ── Campos enriquecidos desde el backend ──
  final String? nombreProducto;
  final String? imagen;
  final int? stockDisponible;

  Movimiento({
    this.idInventario,
    required this.idProducto,
    required this.tipo,
    required this.cantidad,
    required this.stockResultante,
    this.stockMinimo = 5,
    this.motivo,
    this.idReferencia,
    this.fechaMovimiento,
    this.nombreProducto,
    this.imagen,
    this.stockDisponible,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      idInventario:    json['id_inventario'],
      idProducto:      json['id_producto'] ?? 0,
      tipo:            json['tipo'] ?? '',
      cantidad:        json['cantidad'] ?? 0,
      stockResultante: json['stock_resultante'] ?? 0,
      stockMinimo:     json['stock_minimo'] ?? 5,
      motivo:          json['motivo'],
      idReferencia:    json['id_referencia']?.toString(),
      fechaMovimiento: json['fecha_movimiento'] != null
          ? DateTime.tryParse(json['fecha_movimiento'].toString())
          : null,
      nombreProducto:  json['nombre_producto'],
      imagen:          json['imagen'],
      stockDisponible: json['stock_disponible'],
    );
  }
}

// Modelo para la lista de productos en el formulario
class ProductoInventario {
  final int idProducto;
  final String nombreProducto;
  final int stockDisponible;
  final String? categoria;
  final String? imagen;

  ProductoInventario({
    required this.idProducto,
    required this.nombreProducto,
    required this.stockDisponible,
    this.categoria,
    this.imagen,
  });

  factory ProductoInventario.fromJson(Map<String, dynamic> json) {
    return ProductoInventario(
      idProducto:      json['id_producto'],
      nombreProducto:  json['nombre_producto'] ?? '',
      stockDisponible: json['stock_disponible'] ?? 0,
      categoria:       json['categoria'],
      imagen:          json['imagen'],
    );
  }
}