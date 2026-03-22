// lib/services/personalizacion_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/personalizacion_model.dart';

class PersonalizacionService {
  static String get _base => '${ApiConfig.baseUrl}/personalizaciones';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-access-token': token,
  };

  static Future<Map<String, dynamic>> getAll(String token) async {
    try {
      final res = await http.get(Uri.parse(_base), headers: _headers(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final lista = (body as List).map((e) => Personalizacion.fromJson(e)).toList();
        return {'success': true, 'data': lista};
      }
      return {'success': false, 'message': body['msg'] ?? 'Error al obtener'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> getById(int id, String token) async {
    try {
      final res = await http.get(Uri.parse('$_base/$id'), headers: _headers(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'data': Personalizacion.fromJson(body)};
      return {'success': false, 'message': body['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> crear({
    required String token,
    int? idProducto,
    required String tipo,
    required String descripcion,
    String? imagenReferencia,
    String? colorDeseado,
    String? talla,
    double precioAdicional = 0,
  }) async {
    try {
      final body = <String, dynamic>{
        'tipo_personalizacion': tipo,
        'descripcion_personalizacion': descripcion,
        'precio_adicional': precioAdicional,
        if (idProducto != null) 'id_producto': idProducto,
        if (imagenReferencia != null && imagenReferencia.isNotEmpty)
          'imagen_referencia': imagenReferencia,
        if (colorDeseado != null && colorDeseado.isNotEmpty)
          'color_deseado': colorDeseado,
        if (talla != null && talla.isNotEmpty) 'talla': talla,
      };
      final res = await http.post(
        Uri.parse(_base),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {
          'success': true,
          'message': data['msg'] ?? 'Solicitud enviada',
          'data': Personalizacion.fromJson(data['personalizacion']),
        };
      }
      return {'success': false, 'message': data['msg'] ?? 'Error al crear'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> actualizar({
    required int id,
    required String token,
    String? estado,
    double? precioAdicional,
  }) async {
    try {
      final body = <String, dynamic>{
        if (estado != null) 'estado': estado,
        if (precioAdicional != null) 'precio_adicional': precioAdicional,
      };
      final res = await http.patch(
        Uri.parse('$_base/$id'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': data['msg'] ?? 'Actualizado',
          'data': Personalizacion.fromJson(data['personalizacion']),
        };
      }
      return {'success': false, 'message': data['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> eliminar(int id, String token) async {
    try {
      final res = await http.delete(Uri.parse('$_base/$id'), headers: _headers(token));
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'message': data['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }
}