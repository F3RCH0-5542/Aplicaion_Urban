// lib/services/pqrs_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class PqrsService {
  // ✅ Constantes para evitar literales duplicados (SonarQube)
  static const String _baseUrlDefault = 'http://localhost:3001/api/pqrs';
  static const String _baseUrlAndroid = 'http://10.0.2.2:3001/api/pqrs';
  static const String _contentTypeKey  = 'Content-Type';
  static const String _contentTypeJson = 'application/json';
  static const String _authKey         = 'Authorization';

  static Map<String, String> get _jsonHeaders => {
    _contentTypeKey: _contentTypeJson,
  };

  static Map<String, String> _authHeaders(String token) => {
    _contentTypeKey: _contentTypeJson,
    _authKey: 'Bearer $token',
  };

  static String get baseUrl {
    if (kIsWeb)              return _baseUrlDefault;
    if (Platform.isAndroid)  return _baseUrlAndroid;
    return _baseUrlDefault;
  }

  /// Crear PQRS
  static Future<Map<String, dynamic>> crearPqrs({
    required String nombre,
    required String correo,
    required String tipoPqrs,
    required String descripcion,
    int? idUsuario,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _jsonHeaders,
        body: jsonEncode({
          'nombre':      nombre,
          'correo':      correo,
          'tipo_pqrs':   tipoPqrs.toLowerCase(),
          'descripcion': descripcion,
          'id_usuario':  idUsuario,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al crear PQRS'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtener todos los PQRS (admin)
  static Future<List<dynamic>> obtenerPqrs(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Responder PQRS (admin)
  static Future<Map<String, dynamic>> responderPqrs({
    required int    idPqrs,
    required String respuesta,
    required String token,
    String estado = 'Resuelto',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$idPqrs/responder'),
        headers: _authHeaders(token),
        body: jsonEncode({'respuesta': respuesta, 'estado': estado}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['msg'] ?? 'Error al responder PQRS'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Eliminar PQRS (admin)
  static Future<Map<String, dynamic>> eliminarPqrs({
    required int    idPqrs,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$idPqrs'),
        headers: _authHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['msg'] ?? 'Error al eliminar PQRS'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}