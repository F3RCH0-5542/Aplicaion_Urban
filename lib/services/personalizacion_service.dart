// lib/services/personalizacion_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/personalizacion_model.dart';

// ✅ Objeto de parámetros para evitar función con 8 parámetros (SonarQube)
class CrearPersonalizacionRequest {
  final String  token;
  final int?    idProducto;
  final String  tipo;
  final String  descripcion;
  final String? imagenReferencia;
  final String? colorDeseado;
  final String? talla;
  final double  precioAdicional;

  const CrearPersonalizacionRequest({
    required this.token,
    required this.tipo,
    required this.descripcion,
    this.idProducto,
    this.imagenReferencia,
    this.colorDeseado,
    this.talla,
    this.precioAdicional = 0,
  });
}

class PersonalizacionService {
  static String get _base => '${ApiConfig.baseUrl}/personalizaciones';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-access-token': token,
  };

  static Future<Map<String, dynamic>> getAll(String token) async {
    try {
      final res  = await http.get(Uri.parse(_base), headers: _headers(token));
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
      final res  = await http.get(Uri.parse('$_base/$id'), headers: _headers(token));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return {'success': true, 'data': Personalizacion.fromJson(body)};
      return {'success': false, 'message': body['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  /// ✅ Acepta un objeto request en lugar de 8 parámetros individuales
  static Future<Map<String, dynamic>> crear(CrearPersonalizacionRequest req) async {
    try {
      final body = <String, dynamic>{
        'tipo_personalizacion':        req.tipo,
        'descripcion_personalizacion': req.descripcion,
        'precio_adicional':            req.precioAdicional,
        if (req.idProducto != null) 'id_producto': req.idProducto,
        if (req.imagenReferencia != null && req.imagenReferencia!.isNotEmpty)
          'imagen_referencia': req.imagenReferencia,
        if (req.colorDeseado != null && req.colorDeseado!.isNotEmpty)
          'color_deseado': req.colorDeseado,
        if (req.talla != null && req.talla!.isNotEmpty) 'talla': req.talla,
      };
      final res  = await http.post(Uri.parse(_base), headers: _headers(req.token), body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {
          'success': true,
          'message': data['msg'] ?? 'Solicitud enviada',
          'data':    Personalizacion.fromJson(data['personalizacion']),
        };
      }
      return {'success': false, 'message': data['msg'] ?? 'Error al crear'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> actualizar({
    required int    id,
    required String token,
    String?  estado,
    double?  precioAdicional,
  }) async {
    try {
      final body = <String, dynamic>{
        if (estado != null) 'estado': estado,
        if (precioAdicional != null) 'precio_adicional': precioAdicional,
      };
      final res  = await http.patch(Uri.parse('$_base/$id'), headers: _headers(token), body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': data['msg'] ?? 'Actualizado',
          'data':    Personalizacion.fromJson(data['personalizacion']),
        };
      }
      return {'success': false, 'message': data['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> eliminar(int id, String token) async {
    try {
      final res  = await http.delete(Uri.parse('$_base/$id'), headers: _headers(token));
      final data = jsonDecode(res.body);
      return {'success': res.statusCode == 200, 'message': data['msg'] ?? 'Error'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion: $e'};
    }
  }
}