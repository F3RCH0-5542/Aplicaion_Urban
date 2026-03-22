// lib/widgets/connection_test_button.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';

/// Widget para probar la conexión con el backend
/// Útil durante el desarrollo
class ConnectionTestButton extends StatefulWidget {
  const ConnectionTestButton({super.key});

  @override
  State<ConnectionTestButton> createState() => _ConnectionTestButtonState();
}

class _ConnectionTestButtonState extends State<ConnectionTestButton> {
  bool _testing = false;
  String? _result;
  bool? _success;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _result = null;
      _success = null;
    });

    try {
      final isConnected = await AuthService.checkServerConnection();

      setState(() {
        _testing = false;
        _success = isConnected;
        _result = isConnected
            ? '✅ Conexión exitosa con el servidor'
            : '❌ No se pudo conectar al servidor';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_result!),
            backgroundColor: isConnected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testing = false;
        _success = false;
        _result = '❌ Error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_result!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text(
          'Información de Conexión',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ApiConfig.info,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pasos para configurar:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Abre config/api_config.dart\n'
                '2. Cambia la línea _host por tu IP\n'
                '3. Guarda y ejecuta flutter run\n'
                '4. Presiona el botón de prueba',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _testing ? null : _testConnection,
          icon: _testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.wifi_find),
          label: Text(_testing ? 'Probando...' : 'Probar Conexión'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showInfo,
          icon: const Icon(Icons.info_outline, size: 16),
          label:
              const Text('Ver configuración', style: TextStyle(fontSize: 12)),
        ),
        if (_result != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _success!
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _success! ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              _result!,
              style: TextStyle(
                color: _success! ? Colors.green : Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
