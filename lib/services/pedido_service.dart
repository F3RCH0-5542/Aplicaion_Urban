// lib/services/pedido_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/pedido_model.dart';

class PedidoService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001/api/pedidos';
    return 'http://10.0.2.2:3001/api/pedidos';
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ✅ corregido de x-access-token
      };

  // GET todos (solo admin)
  static Future<Map<String, dynamic>> getAll(String token) async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data.map((j) => Pedido.fromJson(j)).toList()};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al obtener pedidos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET por ID
  static Future<Map<String, dynamic>> getById(int id, String token) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$id'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': Pedido.fromJson(jsonDecode(response.body))};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // GET por estado
  static Future<Map<String, dynamic>> getByEstado(String estado, String token) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/estado/$estado'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data.map((j) => Pedido.fromJson(j)).toList()};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // PATCH actualizar estado
  static Future<Map<String, dynamic>> updateEstado(
    int id, {
    required String token,
    required String estado,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/$id'),
            headers: _headers(token),
            body: jsonEncode({'estado': estado}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['msg'] ?? 'Estado actualizado'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al actualizar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // DELETE
  static Future<Map<String, dynamic>> delete(int id, String token) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$id'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['msg'] ?? 'Pedido eliminado'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al eliminar'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}