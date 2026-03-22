// lib/services/api_config.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001/api';
    return 'http://10.0.2.2:3001/api';
  }

  static Map<String, String> headers({String? token}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['x-access-token'] = token;
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static String get auth              => '$baseUrl/auth';
  static String get usuarios          => '$baseUrl/usuarios';
  static String get roles             => '$baseUrl/roles';
  static String get productos         => '$baseUrl/productos';
  static String get pedidos           => '$baseUrl/pedidos';
  static String get personalizaciones => '$baseUrl/personalizaciones';
  static String get pagos             => '$baseUrl/pagos';
  static String get ventas            => '$baseUrl/ventas';
  static String get envios            => '$baseUrl/envios';
  static String get inventario        => '$baseUrl/inventario';
  static String get pqrs              => '$baseUrl/pqrs';

  static String get info =>'Base URL: $baseUrl\nEntorno: ${kIsWeb ? "Web" : "Movil"}\nVersion: 1.0.0';
}