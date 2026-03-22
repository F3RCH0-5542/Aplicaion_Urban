// lib/screens/public/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/connection_test_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();

  String _mensaje = '';
  String _tipo = '';

  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

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
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _mensaje = '';
    });

    final success = await authProvider.login(
      _correoController.text,
      _claveController.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _tipo = 'success';
        _mensaje = '✅ Inicio de sesión exitoso. Redirigiendo...';
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      // Redirigir según el rol
      if (authProvider.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        // Redirigir a la página principal de productos
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      setState(() {
        _tipo = 'danger';
        _mensaje =
            authProvider.errorMessage ?? '❌ Error en el inicio de sesión';
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
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
                          height: 420,
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
                          'Iniciar sesión',
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
                                fontFamily: 'Arial',
                              ),
                            ),
                          ),

                        // Campo de correo
                        _buildInputField(
                          controller: _correoController,
                          label: 'Correo electrónico',
                          isPassword: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su correo';
                            }
                            if (!value.contains('@')) {
                              return 'Correo inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),

                        // Campo de contraseña
                        _buildInputField(
                          controller: _claveController,
                          label: 'Contraseña',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        // Links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                'Registrarse',
                                style: TextStyle(
                                  color: Color(0xFF8F8F8F),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/');
                              },
                              child: const Text(
                                'Volver al inicio',
                                style: TextStyle(
                                  color: Color(0xFF8F8F8F),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

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
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Divider(color: Color(0xFF2a2a2a)),
                        const SizedBox(height: 15),

                        // Botón de prueba de conexión (solo en debug)
                        const ConnectionTestButton(),
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
    required bool isPassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
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
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
