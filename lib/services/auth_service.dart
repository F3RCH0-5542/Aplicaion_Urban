// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:3001/api';

  /// Login del usuario
  static Future<Map<String, dynamic>> login(String correo, String clave) async {
    try {
      debug// print('🔵 [AUTH] Intentando login para: $correo');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'correo': correo.trim(), 'clave': clave}),
      );

      debug// print('📥 [AUTH] Respuesta: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _saveUserSession(
          token: data['token'],
          userId: data['id_usuario'],
          nombre: data['nombre'],
          apellido: data['apellido'],
          correo: correo,
          rol: data['id_rol'],
        );
        debug// print('✅ [AUTH] Login exitoso. userId guardado: ${data['id_usuario']}');
        return {'success': true, 'message': 'Login exitoso', 'data': data};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Credenciales inválidas'};
      }
    } catch (e) {
      debug// print('❌ [AUTH] Error: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  /// Registro
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String clave,
    String? documento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'correo': correo.trim(),
          'clave': clave,
          'documento': documento ?? '',
          'usuario': correo.split('@')[0],
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        if (data['token'] != null) {
          await _saveUserSession(
            token: data['token'],
            userId: data['usuario']['id'],
            nombre: data['usuario']['nombre'],
            apellido: data['usuario']['apellido'],
            correo: data['usuario']['correo'],
            rol: data['usuario']['rol'],
          );
        }
        return {'success': true, 'message': 'Registro exitoso'};
      } else {
        return {'success': false, 'message': data['msg'] ?? 'Error en el registro'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debug// print('🚪 [AUTH] Sesión cerrada');
  }

  // ─── SESIÓN ────────────────────────────────────────────────────────
  static Future<void> _saveUserSession({
    required String token,
    required int userId,
    required String nombre,
    required String apellido,
    required String correo,
    required int rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('userId', userId);
    await prefs.setString('nombre', nombre);
    await prefs.setString('apellido', apellido);
    await prefs.setString('correo', correo);
    await prefs.setInt('rol', rol);
    await prefs.setString('rolNombre', rol == 1 ? 'admin' : 'usuario');
    debug// print('💾 [AUTH] Sesión guardada: $nombre $apellido (rol: $rol, id: $userId)');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    return {
      // ← CORREGIDO: clave 'id_usuario' para que AuthProvider.userId lo encuentre
      'id_usuario': prefs.getInt('userId'),
      'id': prefs.getInt('userId'), // fallback por compatibilidad
      'nombre': prefs.getString('nombre'),
      'apellido': prefs.getString('apellido'),
      'correo': prefs.getString('correo'),
      'rol': prefs.getInt('rol'),
      'id_rol': prefs.getInt('rol'), // fallback
      'rolNombre': prefs.getString('rolNombre'),
    };
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── PETICIONES AUTENTICADAS ───────────────────────────────────────
  static Future<http.Response> authenticatedGet(String endpoint) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  static Future<http.Response> authenticatedPost(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode(body),
    );
  }

  static Future<http.Response> authenticatedPut(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode(body),
    );
  }

  static Future<http.Response> authenticatedDelete(String endpoint) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  static Future<bool> checkServerConnection() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3001'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> debugPrintSession() async {
    final prefs = await SharedPreferences.getInstance();
    debug// print('═══════════════════════════════════════');
    debug// print('🔍 SESIÓN ACTUAL');
    debug// print('Token: ${prefs.getString('token')}');
    debug// print('UserId: ${prefs.getInt('userId')}');
    debug// print('Nombre: ${prefs.getString('nombre')} ${prefs.getString('apellido')}');
    debug// print('Rol: ${prefs.getString('rolNombre')}');
    debug// print('═══════════════════════════════════════');
  }
}