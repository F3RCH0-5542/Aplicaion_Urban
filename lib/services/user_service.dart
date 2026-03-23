import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String baseUrl       = 'http://localhost:3001/api';
  static const String _noAutenticado = 'No autenticado';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-access-token': token,
  };

  // ── PEDIDOS ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerMisPedidos() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/mis-pedidos'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al obtener pedidos'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerPedidoPorId(int idPedido) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.get(
        Uri.parse('$baseUrl/pedidos/$idPedido'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al obtener pedido'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  // ── PERSONALIZACIONES ─────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerMisPersonalizaciones() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.get(
        Uri.parse('$baseUrl/personalizaciones/mis-personalizaciones'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al obtener personalizaciones'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  Future<Map<String, dynamic>> crearPedidoDesdePersonalizacion({
    required int idPersonalizacion,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.post(
        Uri.parse('$baseUrl/pedidos/desde-personalizacion'),
        headers: _headers(token),
        body: jsonEncode({'id_personalizacion': idPersonalizacion}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['msg'] ?? 'Pedido creado', 'data': data};
      }
      return {'success': false, 'message': data['msg'] ?? 'Error al crear pedido'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmarVentaPersonalizacion({
    required int    idPedido,
    required double total,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.post(
        Uri.parse('$baseUrl/ventas'),
        headers: _headers(token),
        body: jsonEncode({'id_pedido': idPedido, 'total': total, 'estado': 'completada'}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['msg'] ?? 'Venta registrada', 'data': data};
      }
      return {'success': false, 'message': data['msg'] ?? 'Error al confirmar pedido'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  // ── PQRS ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerMisPqrs() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.get(
        Uri.parse('$baseUrl/pqrs/mis-pqrs'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al obtener PQRS'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  // ── PERFIL ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerMiPerfil() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/perfil'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al obtener perfil'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  Future<Map<String, dynamic>> actualizarPerfil({String? nombre, String? apellido}) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (apellido != null) body['apellido'] = apellido;
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/perfil'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return {'success': true, 'data': jsonDecode(response.body)};
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al actualizar perfil'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  Future<Map<String, dynamic>> cambiarContrasena({
    required String claveActual,
    required String claveNueva,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': _noAutenticado};
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/cambiar-contrasena'),
        headers: _headers(token),
        body: jsonEncode({'clave_actual': claveActual, 'clave_nueva': claveNueva}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Contrasena actualizada correctamente'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['msg'] ?? 'Error al cambiar contrasena'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }
}