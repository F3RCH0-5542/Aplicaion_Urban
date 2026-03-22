// lib/services/inventario_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/inventario_model.dart';

class InventarioService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001/api/inventario';
    return 'http://10.0.2.2:3001/api/inventario';
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Lista de productos con imagen (para formulario) ───────────────────
  static Future<Map<String, dynamic>> obtenerProductosLista(
      String token) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/productos-lista'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final lista = (data['productos'] as List)
            .map((j) => ProductoInventario.fromJson(j))
            .toList();
        return {'success': true, 'data': lista};
      }
      final error = jsonDecode(res.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── GET todos los movimientos ─────────────────────────────────────────
  static Future<Map<String, dynamic>> obtenerMovimientos(
    String token, {
    String? tipo,
    String? idProducto,
  }) async {
    try {
      final params = <String, String>{};
      if (tipo != null) params['tipo'] = tipo;
      if (idProducto != null) params['id_producto'] = idProducto;

      final uri = Uri.parse(baseUrl)
          .replace(queryParameters: params.isEmpty ? null : params);

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lista = (data['movimientos'] as List)
            .map((j) => Movimiento.fromJson(j))
            .toList();
        return {'success': true, 'data': lista, 'total': data['total']};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── GET historial de un producto ──────────────────────────────────────
  static Future<Map<String, dynamic>> obtenerHistorial(
      String token, int idProducto) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/producto/$idProducto'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final movimientos = (data['movimientos'] as List)
            .map((j) => Movimiento.fromJson(j))
            .toList();
        return {
          'success': true,
          'data': movimientos,
          'producto': data['producto'],
        };
      }
      final error = jsonDecode(res.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── GET stock bajo ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> obtenerStockBajo(String token) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/stock-bajo'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'data': data['productos'],
          'total': data['total']
        };
      }
      final error = jsonDecode(res.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── POST registrar movimiento ─────────────────────────────────────────
  static Future<Map<String, dynamic>> registrarMovimiento({
    required String token,
    required int idProducto,
    required String tipo,
    required int cantidad,
    int stockMinimo = 5,
    String? motivo,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/movimiento'),
            headers: _headers(token),
            body: jsonEncode({
              'id_producto': idProducto,
              'tipo': tipo,
              'cantidad': cantidad,
              'stock_minimo': stockMinimo,
              if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return {
          'success': true,
          'message': data['msg'],
          'stock_actual': data['stock_actual'],
          'alerta': data['alerta'] != null,
        };
      }
      final error = jsonDecode(res.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── DELETE movimiento ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> eliminarMovimiento(
      String token, int id) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl/$id'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'message': data['msg']};
      }
      final error = jsonDecode(res.body);
      return {'success': false, 'message': error['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}