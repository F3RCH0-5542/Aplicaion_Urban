// lib/services/rol_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../models/rol_model.dart';

class RolService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001/api/roles';
    if (Platform.isAndroid) return 'http://10.0.2.2:3001/api/roles';
    return 'http://localhost:3001/api/roles';
  }

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-access-token': token,  // ✅ CORREGIDO
  };

  // GET todos
  static Future<Map<String, dynamic>> getAll(String token) async {
    try {
      print('🔵 GET roles: $baseUrl');
      print('🔵 Token presente: ${token.isNotEmpty}');
      final response = await http
          .get(Uri.parse(baseUrl), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
      print('✅ Status roles: ${response.statusCode}');
      print('✅ Body roles: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> lista = data is List ? data : (data['roles'] ?? []);
        final roles = lista.map((j) => Rol.fromJson(j)).toList();
        return {'success': true, 'data': roles};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al obtener roles'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // UPDATE
  static Future<Map<String, dynamic>> update(int id, {
    required String token,
    required String nombreRol,
    String? descripcion,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/$id'),
            headers: _headers(token),
            body: jsonEncode({
              'nombre_rol': nombreRol,
              if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['msg'] ?? 'Rol actualizado'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['msg'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}