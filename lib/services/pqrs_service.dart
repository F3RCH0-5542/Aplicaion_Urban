// lib/services/pqrs_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class PqrsService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3001/api/pqrs';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001/api/pqrs';
    } else if (Platform.isIOS) {
      return 'http://localhost:3001/api/pqrs';
    } else {
      return 'http://localhost:3001/api/pqrs';
    }
  }

  /// Crear PQRS
  static Future<Map<String, dynamic>> crearPqrs({
    required String nombre,
    required String correo,
    required String tipoPqrs,
    required String descripcion,
    int? idUsuario, // ← AGREGADO
  }) async {
    try {
      // print('🔵 Creando PQRS en: $baseUrl');
      // print('🔵 id_usuario: $idUsuario');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'tipo_pqrs': tipoPqrs.toLowerCase(),
          'descripcion': descripcion,
          'id_usuario': idUsuario, // ← AGREGADO
        }),
      ).timeout(const Duration(seconds: 10));

      // print('✅ Status Code: ${response.statusCode}');
      // print('✅ Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al crear PQRS'};
      }
    } catch (e) {
      // print('❌ Error al crear PQRS: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Obtener todos los PQRS (admin)
  static Future<List<dynamic>> obtenerPqrs(String token) async {
    try {
      // print('🔵 Obteniendo PQRS desde: $baseUrl');
      // print('🔵 Token: ${token.isNotEmpty ? "Presente" : "Vacío"}');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      // print('✅ Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        // print('✅ PQRS encontradas: ${data.length}');
        return data;
      } else {
        // print('❌ Error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      // print('❌ Error en obtenerPqrs: $e');
      return [];
    }
  }

  /// Responder PQRS (admin)
  static Future<Map<String, dynamic>> responderPqrs({
    required int idPqrs,
    required String respuesta,
    required String token,
    String estado = 'Resuelto',
  }) async {
    try {
      // print('🔵 Respondiendo PQRS #$idPqrs en: $baseUrl/$idPqrs/responder');

      final response = await http.post(
        Uri.parse('$baseUrl/$idPqrs/responder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'respuesta': respuesta,
          'estado': estado,
        }),
      ).timeout(const Duration(seconds: 10));

      // print('✅ Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['msg'] ?? 'Error al responder PQRS'};
      }
    } catch (e) {
      // print('❌ Error al responder PQRS: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Eliminar PQRS (admin)
  static Future<Map<String, dynamic>> eliminarPqrs({
    required int idPqrs,
    required String token,
  }) async {
    try {
      // print('🔵 Eliminando PQRS #$idPqrs');

      final response = await http.delete(
        Uri.parse('$baseUrl/$idPqrs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      // print('✅ Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['msg'] ?? 'Error al eliminar PQRS'};
      }
    } catch (e) {
      // print('❌ Error al eliminar PQRS: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}