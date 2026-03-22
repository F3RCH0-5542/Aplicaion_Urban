// lib/screens/products/pqrs_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/pqrs_service.dart';
import '../../providers/auth_provider.dart';

class PqrsPage extends StatefulWidget {
  const PqrsPage({super.key});

  @override
  State<PqrsPage> createState() => _PqrsPageState();
}

class _PqrsPageState extends State<PqrsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _tipoPqrsSeleccionado = 'Queja';
  bool _isLoading = false;

  final List<String> _tiposPqrs = ['Queja', 'Petición', 'Reclamo', 'Sugerencia'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // ── DEBUG ──────────────────────────────────────────────────────────
      debug// print('🔍 [PQRS] isLoggedIn: ${auth.isLoggedIn}');
      debug// print('🔍 [PQRS] userId: ${auth.userId}');
      debug// print('🔍 [PQRS] userFullName: ${auth.userFullName}');
      debug// print('🔍 [PQRS] userEmail: ${auth.userEmail}');
      debug// print('🔍 [PQRS] userData: ${auth.userData}');
      // ──────────────────────────────────────────────────────────────────

      if (auth.isLoggedIn) {
        _nombreController.text = auth.userFullName;
        _correoController.text = auth.userEmail;
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _enviarPqrs() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // ── DEBUG ──────────────────────────────────────────────────────────
    debug// print('🚀 [PQRS] Intentando enviar PQRS...');
    debug// print('🔍 [PQRS] isLoggedIn: ${auth.isLoggedIn}');
    debug// print('🔍 [PQRS] userId al enviar: ${auth.userId}');
    debug// print('🔍 [PQRS] userData al enviar: ${auth.userData}');
    // ──────────────────────────────────────────────────────────────────

    // Bloquear si no está logueado
    if (!auth.isLoggedIn) {
      _mostrarError('Debes iniciar sesión para enviar una PQRS');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final idUsuario = auth.userId;
      debug// print('📤 [PQRS] Enviando con id_usuario: $idUsuario');

      final resultado = await PqrsService.crearPqrs(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        tipoPqrs: _tipoPqrsSeleccionado,
        descripcion: _descripcionController.text.trim(),
        idUsuario: idUsuario,
      );

      setState(() => _isLoading = false);

      if (resultado['success']) {
        debug// print('✅ [PQRS] Creada exitosamente: ${resultado['data']}');
        _mostrarDialogoExito();
        _limpiarFormulario();
      } else {
        _mostrarError(resultado['message'] ?? 'Error al enviar PQRS');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debug// print('❌ [PQRS] Error: $e');
      _mostrarError('Error de conexión: $e');
    }
  }

  void _limpiarFormulario() {
    _descripcionController.clear();
    setState(() => _tipoPqrsSeleccionado = 'Queja');
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      _nombreController.clear();
      _correoController.clear();
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10b981), size: 32),
            SizedBox(width: 12),
            Text('¡Enviado!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Tu solicitud ha sido recibida exitosamente. Te responderemos pronto al correo proporcionado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar', style: TextStyle(color: Color(0xFF667eea))),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $mensaje'),
        backgroundColor: const Color(0xFFef4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        elevation: 4,
        title: const Text('PQRS', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),

                // Banner si NO está logueado
                if (!auth.isLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7c3aed).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFF7c3aed), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Debes iniciar sesión para enviar una PQRS.',
                            style: TextStyle(color: Color(0xFFc4b5fd), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                _buildFormulario(isMobile, auth.isLoggedIn),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de Atención',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Peticiones, Quejas, Reclamos y Sugerencias',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Estamos aquí para ayudarte. Completa el formulario y te responderemos lo antes posible.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormulario(bool isMobile, bool isLoggedIn) {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a1a), Color(0xFF0f0f0f)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2a2a2a)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCampoTexto(
              controller: _nombreController,
              label: 'Nombre completo',
              icon: Icons.person,
              readOnly: isLoggedIn,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildCampoTexto(
              controller: _correoController,
              label: 'Correo electrónico',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              readOnly: isLoggedIn,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa tu correo';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildSelectorTipo(),
            const SizedBox(height: 20),
            _buildCampoTexto(
              controller: _descripcionController,
              label: 'Descripción detallada',
              icon: Icons.description,
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor describe tu caso';
                }
                if (value.trim().length < 20) {
                  return 'La descripción debe tener al menos 20 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isLoading || !isLoggedIn) ? null : _enviarPqrs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  disabledBackgroundColor: const Color(0xFF667eea).withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isLoggedIn ? 'Enviar Solicitud' : 'Inicia sesión para enviar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey[400] : Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? const Color(0xFF111111) : const Color(0xFF0a0a0a),
            prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2a2a2a)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2a2a2a)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFef4444)),
            ),
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorTipo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de solicitud',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0a0a0a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2a2a2a)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _tipoPqrsSeleccionado,
              isExpanded: true,
              dropdownColor: const Color(0xFF1a1a1a),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF667eea)),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: _tiposPqrs.map((tipo) {
                final iconos = {
                  'Queja': Icons.report_problem,
                  'Petición': Icons.request_page,
                  'Reclamo': Icons.gavel,
                  'Sugerencia': Icons.lightbulb,
                };
                return DropdownMenuItem<String>(
                  value: tipo,
                  child: Row(
                    children: [
                      Icon(iconos[tipo] ?? Icons.help, color: const Color(0xFF667eea), size: 20),
                      const SizedBox(width: 12),
                      Text(tipo),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _tipoPqrsSeleccionado = value);
              },
            ),
          ),
        ),
      ],
    );
  }
}