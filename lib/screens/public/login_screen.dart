// lib/screens/public/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/connection_test_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _claveController  = TextEditingController();

  String _mensaje = '';
  String _tipo    = '';

  late AnimationController _animationController;
  late Animation<double>   _rotationAnimation;

  // ✅ Constantes de color para evitar duplicados y reducir complejidad
  static const Color _cyan    = Color(0xFF45F3FF);
  static const Color _pink    = Color(0xFFFF2770);
  static const Color _dark    = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF222222);
  static const Color _grey    = Color(0xFF8F8F8F);
  static const Color _greyAlt = Color(0xFF9EB6B8);
  static const Color _black   = Color(0xFF111111);

  // ✅ Rutas como constantes
  static const String _routeAdmin    = '/admin';
  static const String _routeHome     = '/';
  static const String _routeRegister = '/register';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159)
        .animate(_animationController);
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
    setState(() => _mensaje = '');

    final success = await authProvider.login(
      _correoController.text,
      _claveController.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _tipo    = 'success';
        _mensaje = '✅ Inicio de sesión exitoso. Redirigiendo...';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      // ✅ Navegación extraída para reducir complejidad cognitiva
      _navegarTrasLogin(authProvider);
    } else {
      setState(() {
        _tipo    = 'danger';
        _mensaje = authProvider.errorMessage ?? '❌ Error en el inicio de sesión';
      });
    }
  }

  // ✅ Extraído para reducir complejidad cognitiva de _handleSubmit
  void _navegarTrasLogin(AuthProvider authProvider) {
    final ruta = authProvider.isAdmin ? _routeAdmin : _routeHome;
    Navigator.pushReplacementNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    final size          = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 420;
    final boxWidth      = isSmallScreen ? size.width * 0.9 : 380.0;
    final authProvider  = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _dark,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width:  boxWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child:  Stack(children: [
              ..._buildRotatingBorders(boxWidth),
              _buildFormContainer(boxWidth, authProvider),
            ]),
          ),
        ),
      ),
    );
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  List<Widget> _buildRotatingBorders(double boxWidth) {
    return List.generate(4, (index) {
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
                  end:   Alignment.bottomCenter,
                  colors: _borderColors(index),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  // ✅ Ternaria anidada extraída
  List<Color> _borderColors(int index) {
    if (index % 2 == 0) {
      return [Colors.transparent, Colors.transparent, _cyan.withOpacity(0.8), _cyan];
    }
    return [Colors.transparent, Colors.transparent, _pink.withOpacity(0.8), _pink];
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildFormContainer(double boxWidth, AuthProvider authProvider) {
    return Container(
      margin:  const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 25, spreadRadius: 8)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Iniciar sesión',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            if (_mensaje.isNotEmpty) _buildAlertMessage(),

            _buildInputField(
              controller: _correoController,
              label: 'Correo electrónico',
              validator: _validarCorreo,
            ),
            const SizedBox(height: 25),

            _buildInputField(
              controller: _claveController,
              label: 'Contraseña',
              isPassword: true,
              validator: _validarClave,
            ),
            const SizedBox(height: 15),

            _buildLinks(),
            const SizedBox(height: 25),

            _buildSubmitButton(authProvider),
            const SizedBox(height: 30),
            const Divider(color: Color(0xFF2a2a2a)),
            const SizedBox(height: 15),
            const ConnectionTestButton(),
          ],
        ),
      ),
    );
  }

  // ✅ Validadores extraídos para reducir complejidad cognitiva
  String? _validarCorreo(String? value) {
    if (value == null || value.isEmpty) return 'Por favor ingrese su correo';
    if (!value.contains('@')) return 'Correo inválido';
    return null;
  }

  String? _validarClave(String? value) {
    if (value == null || value.isEmpty) return 'Por favor ingrese su contraseña';
    return null;
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildAlertMessage() {
    final isDanger  = _tipo == 'danger';
    final bgColor   = isDanger ? const Color(0xFFFFDDDD) : const Color(0xFFDDFFDD);
    final textColor = isDanger ? Colors.red : Colors.green;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(10),
      margin:  const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: textColor, width: 5)),
      ),
      child: Text(_mensaje,
          style: TextStyle(color: textColor, fontFamily: 'Arial')),
    );
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, _routeRegister),
          child: const Text('Registrarse', style: TextStyle(color: _grey, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, _routeHome),
          child: const Text('Volver al inicio', style: TextStyle(color: _grey, fontSize: 13)),
        ),
      ],
    );
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildSubmitButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: authProvider.isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: _black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: authProvider.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: _black, strokeWidth: 2))
            : const Text('Iniciar sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText:           label,
        labelStyle:          const TextStyle(color: _grey, fontSize: 16),
        floatingLabelStyle:  const TextStyle(color: _greyAlt, fontSize: 12),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _cyan, width: 2)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _cyan, width: 2)),
        errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2)),
      ),
      validator:         validator,
      autovalidateMode:  AutovalidateMode.onUserInteraction,
    );
  }
}