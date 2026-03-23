// lib/screens/admin/ventas_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List<dynamic> _ventas = [];
  List<dynamic> _ventasFiltradas = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';
  final TextEditingController _busquedaCtrl = TextEditingController();

  int _currentPage = 0;
  int _pageSize = 10;
  static const _pageSizes = [5, 10, 20, 50];
  static const _amber = Color(0xFFF59E0B);
  static const _green = Color(0xFF10B981);
  static const _red   = Color(0xFFEF4444);

  List<dynamic> get _ventasPaginadas {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _ventasFiltradas.length);
    if (start >= _ventasFiltradas.length) return [];
    return _ventasFiltradas.sublist(start, end);
  }

  int get _totalPages => _ventasFiltradas.isEmpty
      ? 1
      : (_ventasFiltradas.length / _pageSize).ceil();

  final List<String> _estados = ['todos', 'pendiente', 'completada', 'cancelada', 'reembolsada'];

  final Map<String, Color> _coloresEstado = {
    'pendiente':   const Color(0xFFF59E0B),
    'completada':  const Color(0xFF10B981),
    'cancelada':   const Color(0xFFEF4444),
    'reembolsada': const Color(0xFF8B5CF6),
  };

  @override
  void initState() {
    super.initState();
    _cargarVentas();
    _busquedaCtrl.addListener(_onBusquedaChanged);
  }

  void _onBusquedaChanged() {
    setState(() { _currentPage = 0; _aplicarFiltros(); });
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ventas'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ventas = data is List ? data : [];
          _currentPage = 0;
          _aplicarFiltros();
        });
      } else {
        _mostrarError('Error al cargar ventas');
      }
    } catch (e) {
      _mostrarError('Error de conexión: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _aplicarFiltros() {
    final busqueda = _busquedaCtrl.text.toLowerCase();
    setState(() {
      _ventasFiltradas = _ventas.where((v) {
        final usuario = v['Usuario'];
        final nombre  = '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'.toLowerCase();
        final idVenta = v['id_venta'].toString();
        final okBusqueda = busqueda.isEmpty || nombre.contains(busqueda) || idVenta.contains(busqueda);
        final okEstado   = _filtroEstado == 'todos' || v['estado'] == _filtroEstado;
        return okBusqueda && okEstado;
      }).toList();
    });
  }

  // ── Cambiar estado ────────────────────────────────────────────────────────

  Widget _buildChipEstado(String e, String estadoSel, void Function(String) onSel) {
    final seleccionado = estadoSel == e;
    final color = _coloresEstado[e] ?? Colors.grey;
    return GestureDetector(
      onTap: () => onSel(e),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.25) : const Color(0xFF0a0a0a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? color : const Color(0xFF2a2a2a),
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Text(e.toUpperCase(),
            style: TextStyle(
              color: seleccionado ? color : Colors.white54,
              fontSize: 11,
              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Future<void> _cambiarEstado(dynamic venta) async {
    String estadoSeleccionado = venta['estado'];
    final estadoOpciones = ['pendiente', 'completada', 'cancelada', 'reembolsada'];
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.edit, color: _amber, size: 20),
            const SizedBox(width: 8),
            Text('Venta #${venta['id_venta']}',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cambiar estado:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: estadoOpciones.map((e) => _buildChipEstado(
                  e, estadoSeleccionado,
                  (v) => setStateDialog(() => estadoSeleccionado = v),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _amber),
              onPressed: () async {
                if (estadoSeleccionado == venta['estado']) { Navigator.pop(ctx); return; }
                Navigator.pop(ctx);
                await _actualizarEstado(venta['id_venta'], estadoSeleccionado);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actualizarEstado(int idVenta, String nuevoEstado) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/ventas/$idVenta'),
        headers: _headers(token),
        body: jsonEncode({'estado': nuevoEstado}),
      );
      if (response.statusCode == 200) {
        _mostrarSnack('Estado actualizado', color: _green);
        await _cargarVentas();
      } else {
        _mostrarError('No se pudo actualizar el estado');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  // ── Detalle bottom sheet ──────────────────────────────────────────────────

  Widget _buildDetalleHeader(dynamic venta, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Venta #${venta['id_venta']}',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      _buildBotonEstadoDetalle(venta, color),
    ]);
  }

  Widget _buildBotonEstadoDetalle(dynamic venta, Color color) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); _cambiarEstado(venta); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(venta['estado'] ?? '',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 11, color: color),
        ]),
      ),
    );
  }

  Widget _buildDetalleTotalCard(dynamic venta) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('TOTAL',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(
          '\$${double.tryParse(venta['total'].toString())?.toStringAsFixed(2) ?? '0.00'}',
          style: const TextStyle(color: _amber, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  Widget _buildDetalleContenido(dynamic venta) {
    final usuario = venta['Usuario'];
    final pedido  = venta['Pedido'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
      )),
      _buildDetalleHeader(venta, _coloresEstado[venta['estado']] ?? Colors.grey),
      const SizedBox(height: 16),
      _seccion('Cliente', Icons.person, [
        _fila('Nombre', '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'),
        _fila('Correo', usuario?['correo'] ?? '-'),
        _fila('ID usuario', '${usuario?['id_usuario'] ?? '-'}'),
      ]),
      const SizedBox(height: 12),
      if (pedido != null) ...[
        _seccion('Pedido vinculado', Icons.receipt_long, [
          _fila('ID pedido', '#${pedido['id_pedido']}'),
          _fila('Fecha pedido', _formatFecha(pedido['fecha_pedido'])),
          _fila('Estado pedido', pedido['estado'] ?? '-'),
        ]),
        const SizedBox(height: 12),
      ],
      _seccion('Detalle de venta', Icons.shopping_cart, [
        _fila('Fecha venta', _formatFecha(venta['fecha'])),
        _fila('Total', '\$${double.tryParse(venta['total'].toString())?.toStringAsFixed(2) ?? '0.00'}'),
        _fila('Estado', venta['estado'] ?? '-'),
      ]),
      const SizedBox(height: 24),
      _buildDetalleTotalCard(venta),
    ]);
  }

  void _mostrarDetalle(dynamic venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: _buildDetalleContenido(venta),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _seccion(String titulo, IconData icono, List<Widget> hijos) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icono, color: _amber, size: 16),
          const SizedBox(width: 6),
          Text(titulo, style: const TextStyle(
              color: _amber, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ...hijos,
      ]),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    try {
      final dt = DateTime.parse(fecha.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  void _mostrarError(String msg) => _mostrarSnack(msg, color: _red);

  void _mostrarSnack(String msg, {Color color = _green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Paginación ────────────────────────────────────────────────────────────

  Widget _buildNumeroPagina(int i) {
    final sel = i == _currentPage;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: sel ? 32 : 28,
        height: sel ? 32 : 28,
        decoration: BoxDecoration(
          color: sel ? _amber : const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? _amber : const Color(0xFF2a2a2a)),
        ),
        child: Center(child: Text('${i + 1}',
            style: TextStyle(
              color: sel ? Colors.black : Colors.white54,
              fontSize: sel ? 13 : 12,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ))),
      ),
    );
  }

  Widget _buildSelectorTamano() {
    return Container(
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
          icon: const Icon(Icons.expand_more, color: _amber, size: 16),
          items: _pageSizes.map((s) => DropdownMenuItem(value: s, child: Text('$s / pág'))).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() { _pageSize = val; _currentPage = 0; });
          },
        ),
      ),
    );
  }

  Widget _buildPaginacion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0a0a0a),
        border: Border(top: BorderSide(color: Color(0xFF1e1e1e))),
      ),
      child: Row(children: [
        _buildSelectorTamano(),
        const SizedBox(width: 8),
        _btnPagina(icon: Icons.chevron_left, enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, _buildNumeroPagina),
            ),
          ),
        ),
        _btnPagina(icon: Icons.chevron_right, enabled: _currentPage < _totalPages - 1,
            onTap: () => setState(() => _currentPage++)),
      ]),
    );
  }

  Widget _btnPagina({required IconData icon, required bool enabled, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFF1a1a1a) : const Color(0xFF0f0f0f),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: enabled ? const Color(0xFF2a2a2a) : const Color(0xFF1a1a1a)),
          ),
          child: Icon(icon, color: enabled ? _amber : Colors.white24, size: 20),
        ),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  Widget _buildChipFiltro(String e) {
    final seleccionado = _filtroEstado == e;
    final color = e == 'todos' ? _amber : (_coloresEstado[e] ?? Colors.grey);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() { _filtroEstado = e; _currentPage = 0; _aplicarFiltros(); }),
        child: Chip(
          label: Text(e, style: TextStyle(
              color: seleccionado ? Colors.black : Colors.white, fontSize: 12)),
          backgroundColor: seleccionado ? color : color.withOpacity(0.15),
        ),
      ),
    );
  }

  Widget _buildCardVenta(dynamic v) {
    final usuario = v['Usuario'];
    final color   = _coloresEstado[v['estado']] ?? Colors.grey;
    final total   = double.tryParse(v['total'].toString()) ?? 0.0;
    return GestureDetector(
      onTap: () => _mostrarDetalle(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shopping_cart, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Venta #${v['id_venta']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            Text(_formatFecha(v['fecha']),
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${total.toStringAsFixed(2)}',
                style: const TextStyle(color: _amber, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(v['estado'] ?? '', style: TextStyle(color: color, fontSize: 11)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildListaVentas() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: _amber));
    if (_ventasPaginadas.isEmpty) {
      return const Center(child: Text('No hay ventas', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _ventasPaginadas.length,
      itemBuilder: (_, i) => _buildCardVenta(_ventasPaginadas[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('VENTAS',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _amber), onPressed: _cargarVentas),
        ],
      ),
      body: Column(children: [
        _buildBarraBusqueda(),
        _buildContador(),
        Expanded(child: _buildListaVentas()),
        _buildPaginacion(),
      ]),
    );
  }

  Widget _buildBarraBusqueda() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(children: [
        TextField(
          controller: _busquedaCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar por cliente o # venta...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Colors.white38),
            suffixIcon: _busquedaCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () {
                      _busquedaCtrl.clear();
                      setState(() { _currentPage = 0; _aplicarFiltros(); });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1a1a1a),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _estados.map(_buildChipFiltro).toList()),
        ),
      ]),
    );
  }

  Widget _buildContador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Text('${_ventasFiltradas.length} ventas',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        if (_totalPages > 1)
          Text('Pág. ${_currentPage + 1} de $_totalPages',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    );
  }
}