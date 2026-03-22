// lib/screens/admin/productos_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<dynamic> _productos = [];
  List<dynamic> _filtrados = [];
  bool _cargando = true;
  String _filtroCategoria = 'todas';
  final _busquedaCtrl = TextEditingController();

  int _currentPage = 0;
  int _pageSize = 10;
  static const _pageSizes = [5, 10, 20, 50];

  List<dynamic> get _paginados {
    final s = _currentPage * _pageSize;
    final e = (s + _pageSize).clamp(0, _filtrados.length);
    return s >= _filtrados.length ? [] : _filtrados.sublist(s, e);
  }

  int get _totalPages =>
      _filtrados.isEmpty ? 1 : (_filtrados.length / _pageSize).ceil();

  static const _purple = Color(0xFF8B5CF6);
  static const _red    = Color(0xFFEF4444);
  static const _green  = Color(0xFF10B981);

  List<String> get _categorias {
    final cats = _productos
        .map((p) => p['categoria']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['todas', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _cargar();
    _busquedaCtrl.addListener(() {
      setState(() { _currentPage = 0; _aplicarFiltro(); });
    });
  }

  @override
  void dispose() { _busquedaCtrl.dispose(); super.dispose(); }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-access-token': token,
  };

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final token = await _getToken();
      if (token == null) { _snack('No autenticado', error: true); return; }
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/productos'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? body;
        setState(() {
          _productos = data is List ? data : [];
          _currentPage = 0;
          _aplicarFiltro();
        });
      } else {
        _snack('Error al cargar productos (${res.statusCode})', error: true);
      }
    } catch (e) {
      _snack('Error de conexión: $e', error: true);
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _aplicarFiltro() {
    final q = _busquedaCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _productos.where((p) {
        final nombre = (p['nombre_producto'] ?? '').toLowerCase();
        final desc   = (p['descripcion'] ?? '').toLowerCase();
        final id     = p['id_producto'].toString();
        final okQ    = q.isEmpty || nombre.contains(q) || desc.contains(q) || id.contains(q);
        final okCat  = _filtroCategoria == 'todas' || p['categoria'] == _filtroCategoria;
        return okQ && okCat;
      }).toList();
    });
  }

  // ✅ FIX L111: sub-widgets para reducir complejidad de _abrirFormulario
  Widget _buildCampoFormulario(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType tipo = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: tipo,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF0a0a0a),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _purple)),
        ),
      ),
    ]);
  }

  bool _validarFormulario(TextEditingController nombreCtrl, TextEditingController precioCtrl) {
    if (nombreCtrl.text.trim().isEmpty || precioCtrl.text.trim().isEmpty) {
      _snack('Nombre y precio son obligatorios', error: true);
      return false;
    }
    final precio = double.tryParse(precioCtrl.text.trim());
    if (precio == null || precio <= 0) {
      _snack('Precio inválido', error: true);
      return false;
    }
    return true;
  }

  Map<String, dynamic> _buildBodyProducto({
    required TextEditingController nombreCtrl,
    required TextEditingController descCtrl,
    required TextEditingController precioCtrl,
    required TextEditingController stockCtrl,
    required TextEditingController catCtrl,
  }) {
    return {
      'nombre_producto': nombreCtrl.text.trim(),
      'descripcion': descCtrl.text.trim(),
      'precio_base': double.parse(precioCtrl.text.trim()),
      'stock_disponible': int.tryParse(stockCtrl.text.trim()) ?? 0,
      'categoria': catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
    };
  }

  // ✅ FIX L111: complejidad reducida con sub-métodos
  Future<void> _abrirFormulario({dynamic producto}) async {
    final esEdicion  = producto != null;
    final nombreCtrl = TextEditingController(text: esEdicion ? producto['nombre_producto'] : '');
    final descCtrl   = TextEditingController(text: esEdicion ? producto['descripcion'] ?? '' : '');
    final precioCtrl = TextEditingController(text: esEdicion ? producto['precio_base'].toString() : '');
    final stockCtrl  = TextEditingController(text: esEdicion ? producto['stock_disponible'].toString() : '0');
    final catCtrl    = TextEditingController(text: esEdicion ? producto['categoria'] ?? '' : '');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(esEdicion ? Icons.edit : Icons.add_circle, color: _purple, size: 22),
              const SizedBox(width: 10),
              Text(
                esEdicion ? 'Editar producto' : 'Nuevo producto',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ]),
            const SizedBox(height: 20),
            _buildCampoFormulario('Nombre del producto *', nombreCtrl),
            const SizedBox(height: 12),
            _buildCampoFormulario('Descripción', descCtrl, maxLines: 3),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _buildCampoFormulario('Precio base *', precioCtrl, tipo: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoFormulario('Stock', stockCtrl, tipo: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            _buildCampoFormulario('Categoría', catCtrl),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFF2a2a2a)),
                    ),
                  ),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (!_validarFormulario(nombreCtrl, precioCtrl)) return;
                    Navigator.pop(ctx);
                    final body = _buildBodyProducto(
                      nombreCtrl: nombreCtrl, descCtrl: descCtrl,
                      precioCtrl: precioCtrl, stockCtrl: stockCtrl, catCtrl: catCtrl,
                    );
                    if (esEdicion) {
                      await _actualizar(producto['id_producto'], body);
                    } else {
                      await _crear(body);
                    }
                  },
                  child: Text(
                    esEdicion ? 'Guardar' : 'Crear',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _crear(Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/productos'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        _snack(data['message'] ?? 'Producto creado');
        await _cargar();
      } else {
        _snack(data['message'] ?? 'Error al crear', error: true);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _actualizar(int id, Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/productos/$id'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _snack(data['message'] ?? 'Producto actualizado');
        await _cargar();
      } else {
        _snack(data['message'] ?? 'Error al actualizar', error: true);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Future<void> _confirmarEliminar(dynamic producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber, color: _red, size: 22),
          SizedBox(width: 8),
          Text('Desactivar producto', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text(
          '¿Desactivar "${producto['nombre_producto']}"?\nNo se eliminará de la base de datos.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) await _eliminar(producto['id_producto']);
  }

  Future<void> _eliminar(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/productos/$id'),
        headers: _headers(token),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _snack(data['message'] ?? 'Producto desactivado');
        await _cargar();
      } else {
        _snack(data['message'] ?? 'Error', error: true);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ✅ FIX L360: build() simplificado con sub-widgets
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('Productos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2a2a2a)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _purple), onPressed: _cargar),
          IconButton(
              icon: const Icon(Icons.add_circle_outline, color: _purple),
              onPressed: () => _abrirFormulario()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _purple,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        _buildBuscador(),
        _buildFiltrosCategorias(),
        _buildContador(),
        Expanded(child: _buildCuerpo()),
        _buildPaginacion(),
      ]),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _busquedaCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, descripción o ID...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white24),
          suffixIcon: _busquedaCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    setState(() { _currentPage = 0; _aplicarFiltro(); });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFiltrosCategorias() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: _categorias.map((cat) {
          final sel   = _filtroCategoria == cat;
          final count = cat == 'todas'
              ? _productos.length
              : _productos.where((p) => p['categoria'] == cat).length;
          return GestureDetector(
            onTap: () => setState(() {
              _filtroCategoria = cat;
              _currentPage = 0;
              _aplicarFiltro();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? _purple.withValues(alpha: 0.15) : const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? _purple : const Color(0xFF2a2a2a),
                    width: sel ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  cat == 'todas' ? 'Todas' : cat,
                  style: TextStyle(
                    color: sel ? _purple : Colors.white38,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: sel ? _purple.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          color: sel ? _purple : Colors.white24,
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Text('${_filtrados.length} productos',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: _purple));
    if (_paginados.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[800]),
        const SizedBox(height: 14),
        const Text('Sin productos', style: TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _purple),
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Crear producto', style: TextStyle(color: Colors.white)),
        ),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: _purple,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _paginados.length,
        itemBuilder: (_, i) => _buildCard(_paginados[i]),
      ),
    );
  }

  Widget _buildCard(dynamic p) {
    final stock     = p['stock_disponible'] ?? 0;
    final precio    = double.tryParse(p['precio_base'].toString()) ?? 0;
    final stockBajo = stock <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stockBajo ? _red.withValues(alpha: 0.4) : _purple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2, color: _purple, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('#${p['id_producto']}',
                  style: const TextStyle(color: _purple, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(
              p['nombre_producto'] ?? '-',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: 4),
          if (p['descripcion'] != null && p['descripcion'].toString().isNotEmpty)
            Text(p['descripcion'],
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          const SizedBox(height: 4),
          Row(children: [
            if (p['categoria'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(p['categoria'],
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: stockBajo ? _red.withValues(alpha: 0.12) : _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('Stock: $stock',
                  style: TextStyle(
                    color: stockBajo ? _red : _green,
                    fontSize: 10, fontWeight: FontWeight.bold,
                  )),
            ),
          ]),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${precio.toStringAsFixed(0)}',
              style: const TextStyle(color: _purple, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            _iconBtn(Icons.edit_outlined, Colors.white54, () => _abrirFormulario(producto: p)),
            const SizedBox(width: 6),
            _iconBtn(Icons.delete_outline, _red, () => _confirmarEliminar(p)),
          ]),
        ]),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );

  Widget _buildPaginacion() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: const BoxDecoration(
      color: Color(0xFF0a0a0a),
      border: Border(top: BorderSide(color: Color(0xFF1e1e1e))),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2a2a2a)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _pageSize,
            dropdownColor: const Color(0xFF1a1a1a),
            isDense: true,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            icon: const Icon(Icons.expand_more, color: _purple, size: 16),
            items: _pageSizes.map((s) => DropdownMenuItem(value: s, child: Text('$s / pág'))).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() { _pageSize = v; _currentPage = 0; });
            },
          ),
        ),
      ),
      const SizedBox(width: 8),
      _btnPag(Icons.chevron_left, _currentPage > 0, () => setState(() => _currentPage--)),
      Expanded(child: Center(child: Text(
        'Pág. ${_currentPage + 1} / $_totalPages',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ))),
      _btnPag(Icons.chevron_right, _currentPage < _totalPages - 1,
          () => setState(() => _currentPage++)),
    ]),
  );

  Widget _btnPag(IconData icon, bool enabled, VoidCallback onTap) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF1a1a1a) : const Color(0xFF0a0a0a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: enabled ? const Color(0xFF2a2a2a) : Colors.transparent),
      ),
      child: Icon(icon, color: enabled ? _purple : Colors.white12, size: 18),
    ),
  );
}