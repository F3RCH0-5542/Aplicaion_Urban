// lib/screens/public/solicitar_personalizacion_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/personalizacion_service.dart';
import '../../services/api_config.dart';

class SolicitarPersonalizacionScreen extends StatefulWidget {
  const SolicitarPersonalizacionScreen({super.key});
  @override
  State<SolicitarPersonalizacionScreen> createState() =>
      _SolicitarPersonalizacionScreenState();
}

class _SolicitarPersonalizacionScreenState
    extends State<SolicitarPersonalizacionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey         = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _colorCtrl       = TextEditingController();

  String?               _tipoSeleccionado;
  String?               _tallaSeleccionada;
  Map<String, dynamic>? _gorraSeleccionada;
  bool                  _enviando = false;

  List<Map<String, dynamic>> _gorras = [];
  bool    _cargandoGorras = true;
  String? _errorGorras;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // ── Constantes UI ────────────────────────────────────────────────
  static const _bg      = Color(0xFF000000);
  static const _surface = Color(0xFF0a0a0a);
  static const _card    = Color(0xFF111111);
  static const _border  = Color(0xFF2a2a2a);
  static const _red     = Color(0xFFEF4444);
  static const _accent  = Color(0xFF667eea);

  static const _tipos  = ['bordado', 'estampado', 'parche', 'tie-dye', 'otro'];
  static const _tallas = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'ÚNICA'];

  static const _tipoData = {
    'bordado':   {'icon': Icons.gesture,      'color': Color(0xFFEF4444), 'desc': 'Hilo de alta resistencia'},
    'estampado': {'icon': Icons.print,        'color': Color(0xFF3B82F6), 'desc': 'Impresión digital HD'},
    'parche':    {'icon': Icons.layers,       'color': Color(0xFF8B5CF6), 'desc': 'Aplique cosido o termoadhesivo'},
    'tie-dye':   {'icon': Icons.palette,      'color': Color(0xFF10B981), 'desc': 'Teñido artesanal único'},
    'otro':      {'icon': Icons.auto_awesome, 'color': Color(0xFFF59E0B), 'desc': 'Cuéntanos tu idea'},
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _cargarGorras();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _descripcionCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  // ── Cargar gorras ────────────────────────────────────────────────
  Future<void> _cargarGorras() async {
    setState(() {
      _cargandoGorras = true;
      _errorGorras = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/productos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final lista = (data is List
                ? data
                : (data['productos'] ?? data['data'] ?? []))
            as List;
        setState(() {
          _gorras = lista
              .where((p) => p['activo'] == true || p['activo'] == 1)
              .map((p) => {
                    'id':     p['id_producto'],
                    'nombre': p['nombre_producto'] ?? p['nombre'] ?? 'Producto',
                    'imagen': p['imagen'] ?? '',
                    'precio': p['precio'] ?? 0,
                  })
              .toList()
              .cast<Map<String, dynamic>>();
          _cargandoGorras = false;
        });
      } else {
        setState(() {
          _errorGorras    = 'No se pudieron cargar las gorras';
          _cargandoGorras = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorGorras    = 'Error de conexión';
        _cargandoGorras = false;
      });
    }
  }

  // ── Enviar solicitud ─────────────────────────────────────────────
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSeleccionado == null) {
      _snack('Selecciona un tipo de personalización', error: true);
      return;
    }
    if (_gorraSeleccionada == null) {
      _snack('Selecciona una gorra de referencia', error: true);
      return;
    }

    setState(() => _enviando = true);
    final colorTexto = _colorCtrl.text.trim();
    final r = await PersonalizacionService.crear(
      token:        _token,
      idProducto:   _gorraSeleccionada!['id'] as int?,
      tipo:         _tipoSeleccionado!,
      descripcion:  _descripcionCtrl.text.trim(),
      colorDeseado: colorTexto.isEmpty ? null : colorTexto,
      talla:        _tallaSeleccionada,
    );
    setState(() => _enviando = false);

    if (r['success'] == true) {
      _snack('¡Solicitud enviada! Te contactaremos pronto.');
      if (mounted) Navigator.pop(context, true);
    } else {
      _snack(r['message'] ?? 'Error al enviar', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: error ? _red : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroHeader(),
                      const SizedBox(height: 32),
                      _buildSeccion('01', 'Elige tu gorra base',
                          Icons.shopping_bag_outlined, _buildDropdownGorra()),
                      const SizedBox(height: 24),
                      _buildSeccion('02', 'Tipo de personalización',
                          Icons.palette_outlined, _buildTipos()),
                      const SizedBox(height: 24),
                      _buildSeccion('03', 'Cuéntanos tu idea',
                          Icons.edit_outlined, _buildDescripcion()),
                      const SizedBox(height: 24),
                      _buildSeccionRow(),
                      const SizedBox(height: 24),
                      _buildInfoPrecio(),
                      const SizedBox(height: 32),
                      _buildBotonEnviar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _surface,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1a0a0a),
                Color(0xFF2d0000),
                Color(0xFF000000)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _red.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -30, left: 40,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 20, left: 20, right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _red.withOpacity(0.3)),
                    ),
                    child: const Text('PERSONALIZACIÓN EXCLUSIVA',
                        style: TextStyle(
                            color: _red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 8),
                  const Text('Diseña tu\ngorra única',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _red.withOpacity(0.08),
            _accent.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.star_outline, color: _red, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Proceso en 3 pasos',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              SizedBox(height: 4),
              Text(
                  'Elige gorra → Describe tu idea → Recibe cotización en 24h',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Sección con número ───────────────────────────────────────────
  Widget _buildSeccion(
      String numero, String titulo, IconData icono, Widget contenido) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: _red, borderRadius: BorderRadius.circular(8)),
          child: Center(
              child: Text(numero,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Icon(icono, color: _red, size: 18),
        const SizedBox(width: 6),
        Text(titulo,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 14),
      contenido,
    ]);
  }

  // ── Dropdown gorras ──────────────────────────────────────────────
  // ✅ Complejidad reducida extrayendo métodos auxiliares
  Widget _buildDropdownGorra() {
    if (_cargandoGorras) return _buildDropdownLoading();
    if (_errorGorras != null) return _buildDropdownError();
    return _buildDropdownContent();
  }

  Widget _buildDropdownLoading() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: _red, strokeWidth: 2)),
      ),
    );
  }

  Widget _buildDropdownError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: _red, size: 18),
        const SizedBox(width: 10),
        Text(_errorGorras!,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        TextButton(
            onPressed: _cargarGorras,
            child: const Text('Reintentar',
                style: TextStyle(color: _red))),
      ]),
    );
  }

  Widget _buildDropdownContent() {
    final borderColor =
        _gorraSeleccionada != null ? _red.withOpacity(0.5) : _border;
    final borderWidth = _gorraSeleccionada != null ? 1.5 : 1.0;

    return Column(children: [
      Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Map<String, dynamic>>(
            value: _gorraSeleccionada,
            isExpanded: true,
            dropdownColor: const Color(0xFF1a1a1a),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white38),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            hint: const Row(children: [
              Icon(Icons.shopping_bag_outlined,
                  color: Colors.white24, size: 18),
              SizedBox(width: 10),
              Text('Selecciona una gorra',
                  style:
                      TextStyle(color: Colors.white38, fontSize: 14)),
            ]),
            items: _gorras.map(_buildDropdownItem).toList(),
            onChanged: (val) => setState(() => _gorraSeleccionada = val),
          ),
        ),
      ),
      if (_gorraSeleccionada != null) ...[
        const SizedBox(height: 12),
        _buildGorraPreview(),
      ],
    ]);
  }

  DropdownMenuItem<Map<String, dynamic>> _buildDropdownItem(
      Map<String, dynamic> gorra) {
    return DropdownMenuItem<Map<String, dynamic>>(
      value: gorra,
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildImagenGorra(gorra['imagen'] as String, 36, 36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(gorra['nombre'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              Text(
                  '\$${(gorra['precio'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF10B981), fontSize: 11)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildGorraPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImagenGorra(
              _gorraSeleccionada!['imagen'] as String, 64, 64),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GORRA SELECCIONADA',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_gorraSeleccionada!['nombre'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                  'Precio base: \$${(_gorraSeleccionada!['precio'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF10B981), fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.check_circle,
            color: Color(0xFF10B981), size: 22),
      ]),
    );
  }

  Widget _buildImagenGorra(String imagen, double w, double h) {
    if (imagen.startsWith('http')) {
      return Image.network(imagen,
          width: w, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imgPlaceholder(w, h));
    }
    return Image.asset(imagen,
        width: w, height: h, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgPlaceholder(w, h));
  }

  Widget _imgPlaceholder(double w, double h) => Container(
    width: w, height: h,
    color: const Color(0xFF2a2a2a),
    child: const Icon(Icons.storefront, color: Colors.white24, size: 20),
  );

  // ── Tipos ────────────────────────────────────────────────────────
  Widget _buildTipos() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _tipos.map(_buildTipoChip).toList(),
    );
  }

  Widget _buildTipoChip(String tipo) {
    final data  = _tipoData[tipo]!;
    final color = data['color'] as Color;
    final icono = data['icon'] as IconData;
    final desc  = data['desc'] as String;
    final sel   = _tipoSeleccionado == tipo;

    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.15) : _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: sel ? color : _border, width: sel ? 2 : 1),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono,
              color: sel ? color : Colors.white38, size: 16),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              tipo[0].toUpperCase() + tipo.substring(1),
              style: TextStyle(
                  color: sel ? color : Colors.white70,
                  fontSize: 13,
                  fontWeight:
                      sel ? FontWeight.bold : FontWeight.normal),
            ),
            if (sel)
              Text(desc,
                  style: TextStyle(
                      color: color.withOpacity(0.7), fontSize: 10)),
          ]),
        ]),
      ),
    );
  }

  // ── Descripción ──────────────────────────────────────────────────
  Widget _buildDescripcion() {
    return TextFormField(
      controller: _descripcionCtrl,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Describe tu idea' : null,
      decoration: InputDecoration(
        hintText:
            'Ej: Quiero el logo de Chicago Bulls bordado en rojo en la parte frontal...',
        hintStyle:
            const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: _card,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _red, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }

  // ── Talla + Color ────────────────────────────────────────────────
  Widget _buildSeccionRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
              color: _red, borderRadius: BorderRadius.circular(8)),
          child: const Center(
              child: Text('04',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.straighten, color: _red, size: 18),
        const SizedBox(width: 6),
        const Text('Talla y color',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _tallas.map(_buildTallaChip).toList(),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _colorCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Color deseado — Ej: Rojo vivo, Azul navy...',
          hintStyle:
              const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.color_lens_outlined,
              color: Colors.white38, size: 20),
          filled: true,
          fillColor: _card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red, width: 1.5)),
        ),
      ),
    ]);
  }

  // ✅ Ternarias anidadas extraídas a método independiente (L706-L715)
  Widget _buildTallaChip(String t) {
    final sel = _tallaSeleccionada == t;
    final bgColor     = sel ? _red.withOpacity(0.15) : _card;
    final borderColor = sel ? _red : _border;
    final borderWidth = sel ? 2.0 : 1.0;
    final textColor   = sel ? _red : Colors.white54;
    final fontWeight  = sel ? FontWeight.bold : FontWeight.normal;

    return GestureDetector(
      onTap: () => setState(() => _tallaSeleccionada = sel ? null : t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Text(t,
            style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: 13)),
      ),
    );
  }

  // ── Info precio ──────────────────────────────────────────────────
  Widget _buildInfoPrecio() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFF59E0B).withOpacity(0.08),
          const Color(0xFFF59E0B).withOpacity(0.03),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 8),
          Text('¿Cuánto costará?',
              style: TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        _infoRow(Icons.check, 'Cotización personalizada según complejidad'),
        const SizedBox(height: 6),
        _infoRow(Icons.check, 'Respuesta en menos de 24 horas'),
        const SizedBox(height: 6),
        _infoRow(Icons.check, 'Sin compromiso — tú decides si aceptas'),
        if (_gorraSeleccionada != null) ...[
          const SizedBox(height: 12),
          _buildPrecioBase(),
        ],
      ]),
    );
  }

  Widget _buildPrecioBase() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Text('Precio base gorra: ',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        Text(
            '\$${(_gorraSeleccionada!['precio'] as num).toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const Text(' + precio personalización',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String texto) => Row(children: [
        Icon(icon, color: const Color(0xFF10B981), size: 14),
        const SizedBox(width: 8),
        Text(texto,
            style:
                const TextStyle(color: Colors.white54, fontSize: 12)),
      ]);

  // ── Botón enviar ─────────────────────────────────────────────────
  // ✅ Complejidad reducida extrayendo métodos auxiliares
  Widget _buildBotonEnviar() {
    final listo = _tipoSeleccionado != null && _gorraSeleccionada != null;
    return Column(children: [
      if (listo) ...[
        _buildResumenSolicitud(),
        const SizedBox(height: 16),
      ],
      _buildBotonPrincipal(listo),
    ]);
  }

  Widget _buildResumenSolicitud() {
    final tallaTexto = _tallaSeleccionada != null
        ? ' · Talla $_tallaSeleccionada'
        : '';
    final tipoCapitalizado = _tipoSeleccionado != null
        ? '${_tipoSeleccionado![0].toUpperCase()}${_tipoSeleccionado!.substring(1)}'
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.summarize_outlined, color: _accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resumen de tu solicitud',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '${_gorraSeleccionada!['nombre']} · $tipoCapitalizado$tallaTexto',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildBotonPrincipal(bool listo) {
    final bgColor    = listo ? _red : Colors.grey[900]!;
    final iconWidget = listo
        ? const Icon(Icons.send, color: Colors.white, size: 18)
        : const Icon(Icons.lock_outline, color: Colors.white38, size: 18);
    final labelText  = listo
        ? 'ENVIAR SOLICITUD'
        : 'Completa los campos requeridos';
    final textColor  = listo ? Colors.white : Colors.white38;
    final letterSpacing = listo ? 1.0 : 0.0;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: listo ? 4 : 0,
        ),
        onPressed: _enviando ? null : _enviar,
        child: _enviando
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: 10),
                  Text(labelText,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: letterSpacing)),
                ],
              ),
      ),
    );
  }
}