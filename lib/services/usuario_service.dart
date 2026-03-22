// lib/services/usuario_service.dart
// El token se pasa como parámetro igual que en pqrs_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../models/usuario_model.dart';

class UsuarioService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001/api/usuarios';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001/api/usuarios';
    return 'http://localhost:3001/api/usuarios';
  }

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // GET todos
  static Future<Map<String, dynamic>> getAll(String token) async {
    try {
      print('🔵 GET $baseUrl');
      print('🔵 Token presente: ${token.isNotEmpty}');

      final response = await http
          .get(Uri.parse(baseUrl), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      print('✅ Status: ${response.statusCode}');
      print('✅ Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> lista = data is List ? data : (data['usuarios'] ?? []);
        final usuarios = lista.map((j) => Usuario.fromJson(j)).toList();
        return {'success': true, 'data': usuarios};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al obtener usuarios'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // CREATE
  static Future<Map<String, dynamic>> create({
    required String token,
    required String nombre,
    required String apellido,
    required String correo,
    required String clave,
    String? documento,
    int idRol = 2,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: _headers(token),
            body: jsonEncode({
              'nombre': nombre,
              'apellido': apellido,
              'correo': correo,
              'clave': clave,
              if (documento != null && documento.isNotEmpty) 'documento': documento,
              'id_rol': idRol,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Usuario.fromJson(data['usuario']), 'message': data['msg']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al crear usuario'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // UPDATE
  static Future<Map<String, dynamic>> update(int id, {
    required String token,
    String? nombre,
    String? apellido,
    String? correo,
    String? documento,
    int? idRol,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (apellido != null) body['apellido'] = apellido;
      if (correo != null) body['correo'] = correo;
      if (documento != null && documento.isNotEmpty) body['documento'] = documento;
      if (idRol != null) body['id_rol'] = idRol;

      final response = await http
          .put(Uri.parse('$baseUrl/$id'), headers: _headers(token), body: jsonEncode(body))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Usuario.fromJson(data['usuario']), 'message': data['msg']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // TOGGLE estado
  static Future<Map<String, dynamic>> toggleEstado(int id, bool activo, {required String token}) async {
    try {
      final response = await http
          .patch(Uri.parse('$baseUrl/$id/status'), headers: _headers(token), body: jsonEncode({'activo': activo}))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Usuario.fromJson(data['usuario']), 'message': data['msg']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al cambiar estado'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // DELETE
  static Future<Map<String, dynamic>> delete(int id, {required String token}) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$id'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['msg']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al eliminar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}