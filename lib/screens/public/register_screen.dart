// lib/screens/public/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  final _confirmarClaveController = TextEditingController();

  String _mensaje = '';
  String _tipo = '';
  bool _mostrarClave = false;
  bool _mostrarConfirmarClave = false;
  bool _intentoSubmit = false;

  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _correoController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _intentoSubmit = true);

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _mensaje = '');

    final success = await authProvider.register(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      correo: _correoController.text.trim(),
      clave: _claveController.text,
      documento: _documentoController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _tipo = 'success';
        _mensaje = '✅ Registro exitoso. Redirigiendo...';
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        _tipo = 'danger';
        _mensaje = authProvider.errorMessage ?? '❌ Error en el registro';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 420;
    final boxWidth = isSmallScreen ? size.width * 0.9 : 380.0;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: boxWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Stack(
              children: [
                // Animaciones de borde giratorias
                ...List.generate(4, (index) {
                  return AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value + (index * 1.57),
                        child: Container(
                          width: boxWidth,
                          height: size.height * 0.9, // Dinámico, no fijo
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: index % 2 == 0
                                  ? [
                                      Colors.transparent,
                                      Colors.transparent,
                                      const Color(0xFF45F3FF).withOpacity(0.8),
                                      const Color(0xFF45F3FF),
                                    ]
                                  : [
                                      Colors.transparent,
                                      Colors.transparent,
                                      const Color(0xFFFF2770).withOpacity(0.8),
                                      const Color(0xFFFF2770),
                                    ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Contenedor del formulario
                Container(
                  margin: const EdgeInsets.all(4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 25,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Mensaje de alerta
                        if (_mensaje.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: _tipo == 'danger'
                                  ? const Color(0xFFFFDDDD)
                                  : const Color(0xFFDDFFDD),
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: _tipo == 'danger'
                                      ? Colors.red
                                      : Colors.green,
                                  width: 5,
                                ),
                              ),
                            ),
                            child: Text(
                              _mensaje,
                              style: TextStyle(
                                color: _tipo == 'danger'
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),

                        // Nombre
                        _buildInputField(
                          controller: _nombreController,
                          label: 'Nombre',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingrese su nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Apellido
                        _buildInputField(
                          controller: _apellidoController,
                          label: 'Apellido',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingrese su apellido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Documento — solo dígitos, máx 15
                        _buildInputField(
                          controller: _documentoController,
                          label: 'Documento (Cédula o ID)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su documento';
                            }
                            if (value.length < 6) {
                              return 'El documento debe tener al menos 6 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Correo
                        _buildInputField(
                          controller: _correoController,
                          label: 'Correo electrónico',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingrese su correo';
                            }
                            if (!_emailRegex.hasMatch(value.trim())) {
                              return 'Ingrese un correo válido (ej: nombre@dominio.com)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Contraseña
                        _buildInputField(
                          controller: _claveController,
                          label: 'Contraseña',
                          isPassword: true,
                          mostrarClave: _mostrarClave,
                          onToggleClave: () =>
                              setState(() => _mostrarClave = !_mostrarClave),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirmar contraseña
                        _buildInputField(
                          controller: _confirmarClaveController,
                          label: 'Confirmar contraseña',
                          isPassword: true,
                          mostrarClave: _mostrarConfirmarClave,
                          onToggleClave: () => setState(() =>
                              _mostrarConfirmarClave = !_mostrarConfirmarClave),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor confirme su contraseña';
                            }
                            if (value != _claveController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Botón de submit
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                authProvider.isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF45F3FF),
                              foregroundColor: const Color(0xFF111111),
                              disabledBackgroundColor:
                                  const Color(0xFF45F3FF).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF111111),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Registrarse',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Link a login — movido debajo del botón
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿Ya tienes cuenta?',
                              style: TextStyle(
                                  color: Color(0xFF8F8F8F), fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  color: Color(0xFF45F3FF),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool? mostrarClave,
    VoidCallback? onToggleClave,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !(mostrarClave ?? false),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      autovalidateMode: _intentoSubmit
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF8F8F8F),
          fontSize: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF9EB6B8),
          fontSize: 12,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (mostrarClave ?? false)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8F8F8F),
                  size: 20,
                ),
                onPressed: onToggleClave,
              )
            : null,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF45F3FF), width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF45F3FF), width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
      validator: validator,
    );
  }
}