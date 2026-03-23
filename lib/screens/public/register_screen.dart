// lib/screens/public/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey                  = GlobalKey<FormState>();
  final _nombreController         = TextEditingController();
  final _apellidoController       = TextEditingController();
  final _documentoController      = TextEditingController();
  final _correoController         = TextEditingController();
  final _claveController          = TextEditingController();
  final _confirmarClaveController = TextEditingController();

  String _mensaje   = '';
  String _tipo      = '';
  bool _mostrarClave          = false;
  bool _mostrarConfirmarClave = false;
  bool _intentoSubmit         = false;

  late AnimationController _animationController;
  late Animation<double>   _rotationAnimation;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // ✅ Colores extraídos como constantes para reducir duplicados y complejidad
  static const Color _cyan    = Color(0xFF45F3FF);
  static const Color _pink    = Color(0xFFFF2770);
  static const Color _dark    = Color(0xFF0D0D0D);
  static const Color _surface = Color(0xFF222222);
  static const Color _grey    = Color(0xFF8F8F8F);
  static const Color _greyAlt = Color(0xFF9EB6B8);
  static const Color _black   = Color(0xFF111111);

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
      nombre:    _nombreController.text.trim(),
      apellido:  _apellidoController.text.trim(),
      correo:    _correoController.text.trim(),
      clave:     _claveController.text,
      documento: _documentoController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _tipo    = 'success';
        _mensaje = '✅ Registro exitoso. Redirigiendo...';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } else {
      setState(() {
        _tipo    = 'danger';
        _mensaje = authProvider.errorMessage ?? '❌ Error en el registro';
      });
    }
  }

  // ── Validadores extraídos para reducir complejidad cognitiva de build() ──

  String? _validarNombre(String? v) {
    if (v == null || v.trim().isEmpty) return 'Por favor ingrese su nombre';
    return null;
  }

  String? _validarApellido(String? v) {
    if (v == null || v.trim().isEmpty) return 'Por favor ingrese su apellido';
    return null;
  }

  String? _validarDocumento(String? v) {
    if (v == null || v.isEmpty) return 'Por favor ingrese su documento';
    if (v.length < 6) return 'El documento debe tener al menos 6 dígitos';
    return null;
  }

  String? _validarCorreo(String? v) {
    if (v == null || v.trim().isEmpty) return 'Por favor ingrese su correo';
    if (!_emailRegex.hasMatch(v.trim())) {
      return 'Ingrese un correo válido (ej: nombre@dominio.com)';
    }
    return null;
  }

  String? _validarClave(String? v) {
    if (v == null || v.isEmpty) return 'Por favor ingrese su contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validarConfirmarClave(String? v) {
    if (v == null || v.isEmpty) return 'Por favor confirme su contraseña';
    if (v != _claveController.text) return 'Las contraseñas no coinciden';
    return null;
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
            width: boxWidth,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Stack(children: [
              // Animaciones de borde giratorias
              ..._buildRotatingBorders(boxWidth, size.height),
              // Formulario
              _buildFormContainer(boxWidth, authProvider),
            ]),
          ),
        ),
      ),
    );
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  List<Widget> _buildRotatingBorders(double boxWidth, double screenHeight) {
    return List.generate(4, (index) {
      return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value + (index * 1.57),
            child: Container(
              width:  boxWidth,
              height: screenHeight * 0.9,
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

  // ✅ Ternaria anidada extraída a método independiente (L425)
  List<Color> _borderColors(int index) {
    if (index % 2 == 0) {
      return [
        Colors.transparent,
        Colors.transparent,
        _cyan.withOpacity(0.8),
        _cyan,
      ];
    }
    return [
      Colors.transparent,
      Colors.transparent,
      _pink.withOpacity(0.8),
      _pink,
    ];
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildFormContainer(double boxWidth, AuthProvider authProvider) {
    return Container(
      margin:  const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color:       Colors.black.withOpacity(0.5),
            blurRadius:  25,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Registrarse',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),

            if (_mensaje.isNotEmpty) _buildAlertMessage(),

            _buildInputField(controller: _nombreController,    label: 'Nombre',                validator: _validarNombre),
            const SizedBox(height: 20),
            _buildInputField(controller: _apellidoController,  label: 'Apellido',              validator: _validarApellido),
            const SizedBox(height: 20),
            _buildInputField(
              controller:       _documentoController,
              label:            'Documento (Cédula o ID)',
              keyboardType:     TextInputType.number,
              inputFormatters:  [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
              validator:        _validarDocumento,
            ),
            const SizedBox(height: 20),
            _buildInputField(controller: _correoController,    label: 'Correo electrónico',    keyboardType: TextInputType.emailAddress, validator: _validarCorreo),
            const SizedBox(height: 20),
            _buildPasswordField(
              controller:     _claveController,
              label:          'Contraseña',
              mostrarClave:   _mostrarClave,
              onToggle:       () => setState(() => _mostrarClave = !_mostrarClave),
              validator:      _validarClave,
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              controller:     _confirmarClaveController,
              label:          'Confirmar contraseña',
              mostrarClave:   _mostrarConfirmarClave,
              onToggle:       () => setState(() => _mostrarConfirmarClave = !_mostrarConfirmarClave),
              validator:      _validarConfirmarClave,
            ),
            const SizedBox(height: 30),

            _buildSubmitButton(authProvider),
            const SizedBox(height: 15),
            _buildLoginLink(),
          ],
        ),
      ),
    );
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildAlertMessage() {
    final isDanger   = _tipo == 'danger';
    final bgColor    = isDanger ? const Color(0xFFFFDDDD) : const Color(0xFFDDFFDD);
    final textColor  = isDanger ? Colors.red : Colors.green;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(10),
      margin:  const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: textColor, width: 5)),
      ),
      child: Text(_mensaje, style: TextStyle(color: textColor)),
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
          backgroundColor:         _cyan,
          foregroundColor:         _black,
          disabledBackgroundColor: _cyan.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: authProvider.isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: _black, strokeWidth: 2))
            : const Text('Registrarse',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ✅ Extraído para reducir complejidad cognitiva de build()
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta?', style: TextStyle(color: _grey, fontSize: 13)),
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          style: TextButton.styleFrom(
            padding:        const EdgeInsets.symmetric(horizontal: 6),
            minimumSize:    Size.zero,
            tapTargetSize:  MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Iniciar sesión', style: TextStyle(color: _cyan, fontSize: 13)),
        ),
      ],
    );
  }

  // ── Campos de texto ──────────────────────────────────────────────────────

  /// Campo de texto genérico (sin password). Máx 6 parámetros → ✅ dentro del límite
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return _buildBaseField(
      controller:      controller,
      label:           label,
      obscureText:     false,
      suffixIcon:      null,
      keyboardType:    keyboardType,
      inputFormatters: inputFormatters,
      validator:       validator,
    );
  }

  /// Campo de contraseña. Separado para mantener cada método ≤ 7 parámetros
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool mostrarClave,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    // ✅ Ícono calculado fuera del árbol para no anidar ternarias
    final visibilityIcon = mostrarClave
        ? Icons.visibility_off_outlined
        : Icons.visibility_outlined;

    return _buildBaseField(
      controller:  controller,
      label:       label,
      obscureText: !mostrarClave,
      suffixIcon: IconButton(
        icon: Icon(visibilityIcon, color: _grey, size: 20),
        onPressed: onToggle,
      ),
      validator: validator,
    );
  }

  /// Implementación base compartida por _buildInputField y _buildPasswordField
  Widget _buildBaseField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:      controller,
      obscureText:     obscureText,
      keyboardType:    keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      autovalidateMode: _intentoSubmit
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText:           label,
        labelStyle:          const TextStyle(color: _grey, fontSize: 16),
        floatingLabelStyle:  const TextStyle(color: _greyAlt, fontSize: 12),
        suffixIcon:          suffixIcon,
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _cyan, width: 2)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _cyan, width: 2)),
        errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
      validator: validator,
    );
  }
}