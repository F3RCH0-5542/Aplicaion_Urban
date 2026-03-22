// lib/screens/admin/pedidos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pedido_model.dart';
import '../../services/pedido_service.dart';
import '../../providers/auth_provider.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<Pedido> _pedidos = [];
  List<Pedido> _pedidosFiltrados = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _currentPage = 0;
  int _pageSize = 10;
  static const _pageSizes = [5, 10, 20, 50];

  List<Pedido> get _pedidosPaginados {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _pedidosFiltrados.length);
    if (start >= _pedidosFiltrados.length) return [];
    return _pedidosFiltrados.sublist(start, end);
  }

  int get _totalPages => _pedidosFiltrados.isEmpty
      ? 1
      : (_pedidosFiltrados.length / _pageSize).ceil();

  static const _estados = [
    'todos', 'pendiente', 'en_proceso', 'enviado', 'completado', 'cancelado'
  ];

  static const _coloresEstado = {
    'pendiente':  Color(0xFFF59E0B),
    'en_proceso': Color(0xFF3B82F6),
    'enviado':    Color(0xFF8B5CF6),
    'completado': Color(0xFF10B981),
    'cancelado':  Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _currentPage = 0;
        _aplicarFiltro();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _cargarPedidos() async {
    setState(() => _isLoading = true);
    final r = await PedidoService.getAll(_getToken());
    if (r['success']) {
      setState(() {
        _pedidos = r['data'] as List<Pedido>;
        _currentPage = 0;
        _aplicarFiltro();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _mostrarError(r['message'] ?? 'Error al cargar pedidos');
    }
  }

  void _aplicarFiltro() {
    var lista = _filtroEstado == 'todos'
        ? List<Pedido>.from(_pedidos)
        : _pedidos.where((p) => p.estado == _filtroEstado).toList();

    if (_searchQuery.isNotEmpty) {
      lista = lista.where((p) {
        final idMatch     = p.idPedido.toString().contains(_searchQuery);
        final nombreMatch = (p.usuario?.nombreCompleto ?? '').toLowerCase().contains(_searchQuery);
        return idMatch || nombreMatch;
      }).toList();
    }
    _pedidosFiltrados = lista;
  }

  Widget _buildImagen(String? imagen, {double size = 90}) {
    if (imagen == null || imagen.isEmpty) return _imgPlaceholder(size: size);
    if (imagen.startsWith('http://') || imagen.startsWith('https://')) {
      return Image.network(
        imagen, width: size, height: size, fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: size, height: size, color: const Color(0xFF2a2a2a),
                child: const Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2)))),
        errorBuilder: (_, __, ___) => _imgPlaceholder(size: size),
      );
    }
    return Image.asset(imagen, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgPlaceholder(size: size));
  }

  // ── FIX L138: _cambiarEstado partido en sub-métodos ───────────────────

  Widget _buildOpcionesEstado(String? estadoSel, void Function(String) onSelect) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _estados.skip(1).map((estado) {
        final color    = _coloresEstado[estado] ?? Colors.grey;
        final selected = estadoSel == estado;
        return GestureDetector(
          onTap: () => onSelect(estado),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.25) : const Color(0xFF0a0a0a),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? color : const Color(0xFF2a2a2a),
                  width: selected ? 2 : 1),
            ),
            child: Text(
              estado.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                  color: selected ? color : Colors.white54,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _cambiarEstado(Pedido pedido) async {
    final estadoActual = pedido.estado;
    String? nuevoEstado = estadoActual;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.edit, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Text('Pedido #${pedido.idPedido}',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: StatefulBuilder(
          builder: (ctx2, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cambiar estado:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              // ✅ FIX L138: opciones extraídas a _buildOpcionesEstado
              _buildOpcionesEstado(nuevoEstado, (e) => setStateDialog(() => nuevoEstado = e)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              if (nuevoEstado == estadoActual) { Navigator.pop(ctx); return; }
              Navigator.pop(ctx);
              final r = await PedidoService.updateEstado(
                  pedido.idPedido!, token: _getToken(), estado: nuevoEstado!);
              r['success']
                  ? _mostrarExito(r['message'] ?? 'Estado actualizado')
                  : _mostrarError(r['message'] ?? 'Error');
              if (r['success']) _cargarPedidos();
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPedido(Pedido pedido) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar pedido', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar el pedido #${pedido.idPedido}? El stock será devuelto.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final r = await PedidoService.delete(pedido.idPedido!, _getToken());
    r['success']
        ? _mostrarExito(r['message'] ?? 'Pedido eliminado')
        : _mostrarError(r['message'] ?? 'Error');
    if (r['success']) _cargarPedidos();
  }

  // ── FIX L248: _verDetalles partido en sub-métodos ─────────────────────

  Widget _buildHeaderPedido(Pedido p, Pedido pedido) {
    final color = _coloresEstado[p.estado] ?? Colors.grey;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pedido #${p.idPedido}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(p.usuario?.nombreCompleto ?? 'Usuario #${p.idUsuario}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          if (p.usuario?.correo != null)
            Text(p.usuario!.correo,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
        GestureDetector(
          onTap: () { Navigator.pop(context); _cambiarEstado(pedido); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.6)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(p.estado.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 11, color: color),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.calendar_today, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(p.fechaPedido ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 16),
        const Icon(Icons.payment, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(p.metodoPago ?? 'N/A', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    ]);
  }

  Widget _buildListaProductos(Pedido p) {
    if (p.detalles.isEmpty) {
      return const Text('Sin productos', style: TextStyle(color: Colors.white54));
    }
    return Column(
      children: p.detalles.map((d) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0a0a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a2a2a)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: _buildImagen(d.imagen, size: 90)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.nombreProducto ?? 'Producto #${d.idProducto}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF2a2a2a), borderRadius: BorderRadius.circular(6)),
                child: Text('x${d.cantidad}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text('\$${d.precioUnitario.toStringAsFixed(0)} c/u',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            Text('Subtotal: \$${d.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
          ])),
        ]),
      )).toList(),
    );
  }

  Future<void> _verDetalles(Pedido pedido) async {
    final r = await PedidoService.getById(pedido.idPedido!, _getToken());
    if (!r['success']) { _mostrarError(r['message'] ?? 'Error'); return; }
    final p = r['data'] as Pedido;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),

            // ✅ FIX L248: header extraído
            _buildHeaderPedido(p, pedido),
            const SizedBox(height: 20),

            // ✅ FIX L248: productos extraídos
            _seccionTitulo('PRODUCTOS', Icons.shopping_bag),
            const SizedBox(height: 8),
            _buildListaProductos(p),
            const SizedBox(height: 20),

            if (p.envio != null) ...[
              _seccionTitulo('ENVÍO', Icons.local_shipping),
              const SizedBox(height: 8),
              _infoCard([
                _infoRow(Icons.location_on, 'Dirección', p.envio!.direccion ?? 'N/A'),
                _infoRow(Icons.location_city, 'Ciudad', p.envio!.ciudad ?? 'N/A'),
                if (p.envio!.telefono != null && p.envio!.telefono!.isNotEmpty)
                  _infoRow(Icons.phone, 'Teléfono', p.envio!.telefono!),
                _infoRow(Icons.local_shipping, 'Estado', p.envio!.estadoEnvio ?? 'pendiente'),
              ]),
              const SizedBox(height: 20),
            ],

            if (p.pago != null) ...[
              _seccionTitulo('PAGO', Icons.credit_card),
              const SizedBox(height: 8),
              _infoCard([
                _infoRow(Icons.payment, 'Método', p.pago!.metodoPago ?? 'N/A'),
                _infoRow(Icons.attach_money, 'Monto',
                    '\$${p.pago!.monto?.toStringAsFixed(0) ?? '0'}'),
                _infoRow(Icons.check_circle, 'Estado', p.pago!.estadoPago ?? 'pendiente'),
              ]),
              const SizedBox(height: 20),
            ],

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${p.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _seccionTitulo(String titulo, IconData icono) => Row(children: [
        Icon(icono, color: const Color(0xFFEF4444), size: 16),
        const SizedBox(width: 6),
        Text(titulo, style: const TextStyle(
            color: Color(0xFFEF4444), fontSize: 12,
            fontWeight: FontWeight.bold, letterSpacing: 1)),
      ]);

  Widget _infoCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0a0a0a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2a2a2a)),
        ),
        child: Column(children: children),
      );

  Widget _infoRow(IconData icono, String label, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icono, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(child: Text(valor,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _imgPlaceholder({double size = 60}) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.image, color: Colors.white38, size: 28),
      );

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Widget _buildPaginacion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              icon: const Icon(Icons.expand_more, color: Color(0xFFEF4444), size: 16),
              items: _pageSizes.map((s) => DropdownMenuItem(value: s, child: Text('$s / pág'))).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() { _pageSize = val; _currentPage = 0; });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _btnPagina(icon: Icons.chevron_left, enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final isSelected = i == _currentPage;
                return GestureDetector(
                  onTap: () => setState(() => _currentPage = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 32 : 28, height: isSelected ? 32 : 28,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF2a2a2a)),
                    ),
                    child: Center(child: Text('${i + 1}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: isSelected ? 13 : 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ))),
                  ),
                );
              }),
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
            border: Border.all(
                color: enabled ? const Color(0xFF2a2a2a) : const Color(0xFF1a1a1a)),
          ),
          child: Icon(icon,
              color: enabled ? const Color(0xFFEF4444) : Colors.white24, size: 20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('Gestión de Pedidos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFEF4444)),
              onPressed: _cargarPedidos),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID o nombre...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white38),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _currentPage = 0;
                              _aplicarFiltro();
                            }),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1a1a1a),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: _estados.length,
                  itemBuilder: (_, i) {
                    final estado   = _estados[i];
                    final selected = _filtroEstado == estado;
                    final color    = estado == 'todos'
                        ? const Color(0xFFEF4444)
                        : (_coloresEstado[estado] ?? Colors.grey);
                    return GestureDetector(
                      onTap: () => setState(() {
                        _filtroEstado = estado;
                        _currentPage = 0;
                        _aplicarFiltro();
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.2) : const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected ? color : const Color(0xFF2a2a2a),
                              width: selected ? 1.5 : 1),
                        ),
                        child: Text(
                          estado == 'todos' ? 'TODOS' : estado.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                              color: selected ? color : Colors.white54,
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(children: [
                  Text('${_pedidosFiltrados.length} pedido(s)',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Spacer(),
                  if (_totalPages > 1)
                    Text('Pág. ${_currentPage + 1} de $_totalPages',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ),
              Expanded(
                child: _pedidosFiltrados.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        const Text('No hay pedidos',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _pedidosPaginados.length,
                        itemBuilder: (_, i) => _buildPedidoCard(_pedidosPaginados[i], auth),
                      ),
              ),
              _buildPaginacion(),
            ]),
    );
  }

  Widget _buildPedidoCard(Pedido pedido, AuthProvider auth) {
    final color = _coloresEstado[pedido.estado] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF1a1a1a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _verDetalles(pedido),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('#${pedido.idPedido}',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(
                pedido.usuario?.nombreCompleto ?? 'Usuario #${pedido.idUsuario}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(pedido.estado.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Text(pedido.fechaPedido ?? 'Sin fecha',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 16),
              if (pedido.metodoPago != null) ...[
                const Icon(Icons.payment, color: Colors.white38, size: 13),
                const SizedBox(width: 4),
                Text(pedido.metodoPago!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
              const Spacer(),
              Text('\$${pedido.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            if (auth.isSuperAdmin) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton.icon(
                  onPressed: () => _cambiarEstado(pedido),
                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFFEF4444)),
                  label: const Text('Estado',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _eliminarPedido(pedido),
                  icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                  label: const Text('Eliminar',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}