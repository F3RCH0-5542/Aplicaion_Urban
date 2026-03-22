import 'package:flutter/material.dart';
import 'package:urban_flutter/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get userData => _userData;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _userData != null && _token != null;

  int? get userId => _userData?['id_usuario'] ?? _userData?['id'];
  int? get userRole => _userData?['id_rol'] ?? _userData?['rol'];

  bool get isSuperAdmin =>
      _userData != null && (userRole == 1 || userId == 72);

  bool get isAdminLimitado =>
      _userData != null && userRole == 3;

  bool get isAdmin => isSuperAdmin || isAdminLimitado;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userData = await AuthService.getUserData();
      _token = await AuthService.getToken();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String correo, String clave) async {
    _isLoading = true;
    notifyListeners();

    final result = await AuthService.login(correo, clave);

    _isLoading = false;

    if (result['success']) {
      await _loadUserData();
      return true;
    }

    _errorMessage = result['message'];
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String nombre,
    required String apellido,
    required String correo,
    required String clave,
    String? documento,      // ← agregado
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await AuthService.register(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      clave: clave,
      documento: documento, // ← agregado
    );

    _isLoading = false;

    if (result['success']) {
      await _loadUserData();
      return true;
    }

    _errorMessage = result['message'];
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _userData = null;
    _token = null;
    notifyListeners();
  }

  String get userFullName =>
      '${_userData?['nombre'] ?? ''} ${_userData?['apellido'] ?? ''}'.trim();

  String get userEmail => _userData?['correo'] ?? '';
}