// lib/screens/admin/pagos_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  List<dynamic> _pagos = [];
  List<dynamic> _pagosFiltrados = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';
  final _busquedaCtrl = TextEditingController();

  int _currentPage = 0;
  int _pageSize = 10;
  static const _pageSizes = [5, 10, 20, 50];

  List<dynamic> get _pagosPaginados {
    final s = _currentPage * _pageSize;
    final e = (s + _pageSize).clamp(0, _pagosFiltrados.length);
    return s >= _pagosFiltrados.length ? [] : _pagosFiltrados.sublist(s, e);
  }

  int get _totalPages =>
      _pagosFiltrados.isEmpty ? 1 : (_pagosFiltrados.length / _pageSize).ceil();

  static const _estados = ['todos', 'pendiente', 'completado', 'fallido', 'reembolsado'];

  static const _coloresEstado = {
    'pendiente':   Color(0xFFF59E0B),
    'completado':  Color(0xFF10B981),
    'fallido':     Color(0xFFEF4444),
    'reembolsado': Color(0xFF8B5CF6),
  };

  static const _iconosMetodo = {
    'efectivo':        Icons.payments,
    'tarjeta_credito': Icons.credit_card,
    'tarjeta_debito':  Icons.credit_card,
    'transferencia':   Icons.account_balance,
    'pse':             Icons.account_balance,
    'nequi':           Icons.phone_android,
    'daviplata':       Icons.phone_android,
    'paypal':          Icons.payment,
    'personalizacion': Icons.palette,
  };

  static const _cyan = Color(0xFF06B6D4);
  static const _red  = Color(0xFFEF4444);
  static const _green = Color(0xFF10B981);

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
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/pagos'), headers: _headers(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _pagos = data is List ? data : []; _currentPage = 0; _aplicarFiltro(); });
      } else {
        _snack('Error al cargar pagos (${res.statusCode})', error: true);
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
      _pagosFiltrados = _pagos.where((p) {
        final pedido  = p['Pedido'];
        final usuario = pedido?['Usuario'];
        final nombre  = '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'.toLowerCase();
        final idPago  = p['id_pago'].toString();
        final metodo  = (p['metodo_pago'] ?? '').toLowerCase();
        final ok      = q.isEmpty || nombre.contains(q) || idPago.contains(q) || metodo.contains(q);
        final okEstado = _filtroEstado == 'todos' || p['estado_pago'] == _filtroEstado;
        return ok && okEstado;
      }).toList();
    });
  }

  Future<void> _actualizarEstado(int idPago, String nuevoEstado) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/pagos/$idPago'),
        headers: _headers(token),
        body: jsonEncode({'estado_pago': nuevoEstado}),
      );
      if (res.statusCode == 200) {
        _snack('Estado actualizado');
        await _cargar();
      } else {
        _snack('No se pudo actualizar', error: true);
      }
    } catch (e) {
      _snack('Error: $e', error: true);
    }
  }

  Widget _buildInfoPago(dynamic pago) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0a0a0a),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2a2a2a)),
      ),
      child: Column(children: [
        _infoFila('Monto', '\$${double.tryParse(pago['monto'].toString())?.toStringAsFixed(0) ?? '0'}'),
        _infoFila('Método', (pago['metodo_pago'] ?? '-').replaceAll('_', ' ')),
        if (pago['referencia'] != null) _infoFila('Referencia', pago['referencia']),
      ]),
    );
  }

  Widget _buildSelectorEstado(String estadoSel, void Function(String) onSelect) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _estados.skip(1).map((e) {
        final color = _coloresEstado[e] ?? Colors.grey;
        final sel   = estadoSel == e;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.2) : const Color(0xFF0a0a0a),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? color : const Color(0xFF2a2a2a), width: sel ? 2 : 1),
            ),
            child: Text(e.toUpperCase(),
                style: TextStyle(
                    color: sel ? color : Colors.white38,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _cambiarEstado(dynamic pago) async {
    String estadoSel = pago['estado_pago'] ?? 'pendiente';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.payment, color: _cyan, size: 18),
            const SizedBox(width: 8),
            Text('Pago #${pago['id_pago']}',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildInfoPago(pago),
            const SizedBox(height: 16),
            const Text('Estado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            _buildSelectorEstado(estadoSel, (e) => set(() => estadoSel = e)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                if (estadoSel == pago['estado_pago']) { Navigator.pop(ctx); return; }
                Navigator.pop(ctx);
                await _actualizarEstado(pago['id_pago'], estadoSel);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDetalle(dynamic pago, Color color, IconData icono) {
    return Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: _cyan.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icono, color: _cyan, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Pago #${pago['id_pago']}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text((pago['metodo_pago'] ?? '').replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ])),
      GestureDetector(
        onTap: () { Navigator.pop(context); _cambiarEstado(pago); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text((pago['estado_pago'] ?? '').toUpperCase(),
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 11, color: color),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildMontoDetalle(dynamic pago) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('MONTO',
            style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('\$${double.tryParse(pago['monto'].toString())?.toStringAsFixed(0) ?? '0'}',
            style: const TextStyle(color: _cyan, fontSize: 28, fontWeight: FontWeight.w900)),
        if (pago['referencia'] != null) ...[
          const SizedBox(height: 4),
          Text('Ref: ${pago['referencia']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ]),
    );
  }

  // ✅ FIX L440: sub-widgets para reducir complejidad de _verDetalle
  Widget _buildDetalleCliente(dynamic usuario) {
    if (usuario == null) return const SizedBox.shrink();
    return Column(children: [
      _seccion('CLIENTE', Icons.person, [
        _fila('Nombre', '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'),
        _fila('Correo', usuario['correo'] ?? '-'),
      ]),
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildDetallePedido(dynamic pedido) {
    if (pedido == null) return const SizedBox.shrink();
    return _seccion('PEDIDO', Icons.receipt_long, [
      _fila('ID', '#${pedido['id_pedido']}'),
      _fila('Fecha', _formatFecha(pedido['fecha_pedido'])),
      _fila('Total pedido',
          '\$${double.tryParse(pedido['total'].toString())?.toStringAsFixed(0) ?? '0'}'),
    ]);
  }

  // ✅ FIX L440: complejidad reducida extrayendo sub-widgets
  void _verDetalle(dynamic pago) {
    final pedido = pago['Pedido'];
    final usuario = pedido?['Usuario'];
    final color  = _coloresEstado[pago['estado_pago']] ?? Colors.grey;
    final icono  = _iconosMetodo[pago['metodo_pago']] ?? Icons.payment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.55, maxChildSize: 0.85,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            _buildHeaderDetalle(pago, color, icono),
            const SizedBox(height: 20),
            _buildMontoDetalle(pago),
            const SizedBox(height: 16),
            _seccion('PAGO', Icons.receipt, [
              _fila('Método', (pago['metodo_pago'] ?? '-').replaceAll('_', ' ')),
              _fila('Fecha', _formatFecha(pago['fecha_pago'])),
            ]),
            const SizedBox(height: 12),
            _buildDetalleCliente(usuario),
            _buildDetallePedido(pedido),
          ]),
        ),
      ),
    );
  }

  Widget _seccion(String titulo, IconData icono, List<Widget> hijos) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF0a0a0a),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2a2a2a)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icono, color: _cyan, size: 14),
        const SizedBox(width: 6),
        Text(titulo, style: const TextStyle(
            color: _cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ]),
      const SizedBox(height: 10),
      ...hijos,
    ]),
  );

  Widget _fila(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Flexible(child: Text(valor,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _infoFila(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      Text(valor, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
  );

  String _formatFecha(dynamic f) {
    if (f == null) return '-';
    try {
      final dt = DateTime.parse(f.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return f.toString(); }
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

  Widget _buildCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: _cyan));
    if (_pagosPaginados.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.payment_outlined, size: 72, color: Colors.grey[800]),
        const SizedBox(height: 14),
        const Text('Sin pagos', style: TextStyle(color: Colors.grey, fontSize: 15)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: _cyan,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _pagosPaginados.length,
        itemBuilder: (_, i) => _buildCard(_pagosPaginados[i]),
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _busquedaCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por ID, cliente o método...',
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

  Widget _buildChipFiltro(String estado) {
  final sel   = _filtroEstado == estado;
  final color = estado == 'todos' ? _cyan : (_coloresEstado[estado] ?? Colors.grey);
  final count = estado == 'todos'
      ? _pagos.length
      : _pagos.where((p) => p['estado_pago'] == estado).length;
  final chipColor    = sel ? color.withOpacity(0.15) : const Color(0xFF1a1a1a);
  final borderColor  = sel ? color : const Color(0xFF2a2a2a);
  final labelColor   = sel ? color : Colors.white38;
  final countColor   = sel ? color : Colors.white24;
  final countBgColor = sel ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05);
  final label        = estado == 'todos' ? 'Todos' : estado;

  return GestureDetector(
    onTap: () => setState(() { _filtroEstado = estado; _currentPage = 0; _aplicarFiltro(); }),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: sel ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
            color: labelColor, fontSize: 12,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: countBgColor, borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: TextStyle(
              color: countColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    ),
  );
}

Widget _buildFiltrosEstado() {
  return SizedBox(
    height: 42,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: _estados.map(_buildChipFiltro).toList(),
    ),
  );
}
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('Pagos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2a2a2a)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _cyan), onPressed: _cargar),
        ],
      ),
      body: Column(children: [
        _buildBuscador(),
        _buildFiltrosEstado(),
        const SizedBox(height: 4),
        Expanded(child: _buildCuerpo()),
        _buildPaginacion(),
      ]),
    );
  }

  Widget _buildCard(dynamic pago) {
    final pedido  = pago['Pedido'];
    final usuario = pedido?['Usuario'];
    final color   = _coloresEstado[pago['estado_pago']] ?? Colors.grey;
    final icono   = _iconosMetodo[pago['metodo_pago']] ?? Icons.payment;
    final monto   = double.tryParse(pago['monto'].toString()) ?? 0;
    final nombre  = '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'.trim();

    return GestureDetector(
      onTap: () => _verDetalle(pago),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, color: _cyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                child: Text('#${pago['id_pago']}',
                    style: const TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(
                nombre.isEmpty ? 'Sin cliente' : nombre,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              )),
            ]),
            const SizedBox(height: 4),
            Text((pago['metodo_pago'] ?? '-').replaceAll('_', ' '),
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${monto.toStringAsFixed(0)}',
                style: const TextStyle(color: _cyan, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text((pago['estado_pago'] ?? '').toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
        ]),
      ),
    );
  }

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
            icon: const Icon(Icons.expand_more, color: _cyan, size: 16),
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
      _btnPag(Icons.chevron_right, _currentPage < _totalPages - 1, () => setState(() => _currentPage++)),
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
      child: Icon(icon, color: enabled ? _cyan : Colors.white12, size: 18),
    ),
  );
}