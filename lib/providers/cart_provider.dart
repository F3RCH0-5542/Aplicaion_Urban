import 'package:flutter/foundation.dart';

class CartItem {
  final int? idProducto; // ID del producto en la BD
  final String nombre;
  final int precio;
  final String imagen;
  int cantidad;

  CartItem({
    this.idProducto,
    required this.nombre,
    required this.precio,
    required this.imagen,
    this.cantidad = 1,
  });

  // Subtotal de este item
  int get subtotal => precio * cantidad;

  // Convertir a Map para guardar/enviar
  Map<String, dynamic> toMap() {
    return {
      'id_producto': idProducto,
      'nombre': nombre,
      'precio': precio,
      'imagen': imagen,
      'cantidad': cantidad,
    };
  }

  // Crear desde Map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      idProducto: map['id_producto'],
      nombre: map['nombre'] ?? '',
      precio: map['precio'] ?? 0,
      imagen: map['imagen'] ?? '',
      cantidad: map['cantidad'] ?? 1,
    );
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  // Getter para obtener todos los items
  Map<String, CartItem> get items => {..._items};

  // Lista de items
  List<CartItem> get itemsList => _items.values.toList();

  // Cantidad total de items (suma de cantidades)
  int get itemCount {
    return _items.values.fold(0, (sum, item) => sum + item.cantidad);
  }

  // Total del carrito en pesos
  int get totalAmount {
    return _items.values.fold(0, (sum, item) => sum + item.subtotal);
  }

  // Verificar si el carrito está vacío
  bool get isEmpty => _items.isEmpty;

  // Agregar producto al carrito
  void addItem({
    int? idProducto,
    required String nombre,
    required int precio,
    required String imagen,
  }) {
    // Usar el nombre como clave única
    final key = nombre;

    if (_items.containsKey(key)) {
      // Si ya existe, aumentar cantidad
      _items[key]!.cantidad++;
    } else {
      // Si es nuevo, agregarlo
      _items[key] = CartItem(
        idProducto: idProducto,
        nombre: nombre,
        precio: precio,
        imagen: imagen,
        cantidad: 1,
      );
    }
    notifyListeners();
  }

  // Aumentar cantidad de un item
  void increaseQuantity(String key) {
    if (_items.containsKey(key)) {
      _items[key]!.cantidad++;
      notifyListeners();
    }
  }

  // Disminuir cantidad de un item
  void decreaseQuantity(String key) {
    if (!_items.containsKey(key)) return;

    if (_items[key]!.cantidad > 1) {
      _items[key]!.cantidad--;
    } else {
      // Si llega a 0, eliminar del carrito
      _items.remove(key);
    }
    notifyListeners();
  }

  // Eliminar un producto del carrito
  void removeItem(String key) {
    _items.remove(key);
    notifyListeners();
  }

  // Vaciar todo el carrito
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Obtener un item específico
  CartItem? getItem(String key) {
    return _items[key];
  }

  // Verificar si un producto está en el carrito
  bool containsProduct(String nombre) {
    return _items.containsKey(nombre);
  }

  // Obtener cantidad de un producto específico
  int getQuantity(String nombre) {
    return _items[nombre]?.cantidad ?? 0;
  }

  // Obtener lista de productos para enviar al backend
  List<Map<String, dynamic>> getProductsForOrder() {
    return _items.values.map((item) => item.toMap()).toList();
  }
}
