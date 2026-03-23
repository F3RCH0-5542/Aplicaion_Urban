// lib/screens/public/user_panel_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class UserPanelPage extends StatefulWidget {
  const UserPanelPage({super.key});

  @override
  State<UserPanelPage> createState() => _UserPanelPageState();
}

class _UserPanelPageState extends State<UserPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.white54),
              const SizedBox(height: 20),
              const Text('Debes iniciar sesión',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Cuenta',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Text(authProvider.userFullName,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white54),
            onPressed: () => Navigator.pushNamed(context, '/'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1e1e1e))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF667eea),
              indicatorWeight: 2,
              labelColor: const Color(0xFF667eea),
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.shopping_bag, size: 20), text: 'Pedidos'),
                Tab(icon: Icon(Icons.palette, size: 20), text: 'Personaliz.'),
                Tab(icon: Icon(Icons.support_agent, size: 20), text: 'PQRS'),
                Tab(icon: Icon(Icons.person, size: 20), text: 'Perfil'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PedidosTab(userService: _userService),
          _PersonalizacionesTab(userService: _userService),
          _PqrsTab(userService: _userService),
          _PerfilTab(userService: _userService),
        ],
      ),
    );
  }
}

// ==========================================
// 📦 TAB PEDIDOS
// ==========================================
class _PedidosTab extends StatefulWidget {
  final UserService userService;
  const _PedidosTab({required this.userService});
  @override
  State<_PedidosTab> createState() => _PedidosTabState();
}

class _PedidosTabState extends State<_PedidosTab> {
  List<dynamic> _pedidos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; });
    final r = await widget.userService.obtenerMisPedidos();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r['success']) { _pedidos = r['data'] ?? []; } else { _error = r['message']; }
    });
  }

  Color _colorEstado(String? e) {
    switch (e) {
      case 'pendiente':  return const Color(0xFFF59E0B);
      case 'en_proceso': return const Color(0xFF3B82F6);
      case 'enviado':    return const Color(0xFF8B5CF6);
      case 'completado': return const Color(0xFF10B981);
      case 'cancelado':  return const Color(0xFFEF4444);
      default:           return Colors.grey;
    }
  }

  IconData _iconEstado(String? e) {
    switch (e) {
      case 'pendiente':  return Icons.hourglass_empty;
      case 'en_proceso': return Icons.autorenew;
      case 'enviado':    return Icons.local_shipping;
      case 'completado': return Icons.check_circle;
      case 'cancelado':  return Icons.cancel;
      default:           return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
    if (_error != null) return _errorWidget(_error!, _cargar);
    if (_pedidos.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey[800]),
        const SizedBox(height: 16),
        const Text('No tienes pedidos aún', style: TextStyle(color: Colors.white54, fontSize: 16)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea)),
          child: const Text('Explorar productos'),
        ),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pedidos.length,
        itemBuilder: (_, i) {
          final p        = _pedidos[i];
          final estado   = p['estado'] ?? 'pendiente';
          final color    = _colorEstado(estado);
          final total    = double.tryParse(p['total']?.toString() ?? '0') ?? 0;
          final fecha    = (p['fecha_pedido'] ?? '').toString().split('T')[0];
          final detalles = (p['detalles'] as List?) ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_iconEstado(estado), color: color, size: 22),
                ),
                title: Row(children: [
                  Text('Pedido #${p['id_pedido']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(estado.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ]),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(fecha, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
                trailing: Text('\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold)),
                children: detalles.isEmpty
                    ? [const Text('Sin detalles', style: TextStyle(color: Colors.white38, fontSize: 13))]
                    : [
                        const Divider(color: Color(0xFF2a2a2a)),
                        const SizedBox(height: 8),
                        ...detalles.map((d) {
                          final nombreProd = d['Producto']?['nombre_producto'] ?? 'Producto #${d['id_producto']}';
                          final subtotal   = double.tryParse(d['subtotal']?.toString() ?? '0') ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0a0a0a),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.inventory_2_outlined,
                                    color: Colors.white24, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombreProd,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                  Text('Cant: ${d['cantidad']}  ·  \$${double.tryParse(d['precio_unitario']?.toString() ?? '0')?.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              )),
                              Text('\$${subtotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Color(0xFF667eea), fontWeight: FontWeight.bold)),
                            ]),
                          );
                        }),
                      ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 🎨 TAB PERSONALIZACIONES
// ==========================================
class _PersonalizacionesTab extends StatefulWidget {
  final UserService userService;
  const _PersonalizacionesTab({required this.userService});
  @override
  State<_PersonalizacionesTab> createState() => _PersonalizacionesTabState();
}

class _PersonalizacionesTabState extends State<_PersonalizacionesTab> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _procesando = {};

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; });
    final r = await widget.userService.obtenerMisPersonalizaciones();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r['success']) { _items = r['data'] ?? []; } else { _error = r['message']; }
    });
  }

  Future<void> _confirmarPedido(Map<String, dynamic> pers) async {
    final idPers = pers['id_personalizacion'] as int;
    final precio = double.tryParse(pers['precio_adicional']?.toString() ?? '0') ?? 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.shopping_cart_checkout, color: Color(0xFF10B981), size: 20),
          SizedBox(width: 8),
          Text('Confirmar pedido', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Tu personalización fue aprobada y está lista.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Column(children: [
              const Text('TOTAL A PAGAR',
                  style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('\$${precio.toStringAsFixed(0)} COP',
                  style: const TextStyle(
                      color: Color(0xFF10B981), fontSize: 26, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('¿Confirmar y generar pedido?',
              style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _procesando.add(idPers));
    final r = await widget.userService.crearPedidoDesdePersonalizacion(idPersonalizacion: idPers);
    if (!mounted) return;
    setState(() => _procesando.remove(idPers));
    if (r['success']) { _snack('¡Pedido generado correctamente!'); _cargar(); }
    else { _snack(r['message'] ?? 'Error al confirmar', error: true); }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Color _colorEstado(String? e) {
    switch (e) {
      case 'aprobada':   return const Color(0xFF10B981);
      case 'rechazada':  return const Color(0xFFEF4444);
      case 'en_proceso': return const Color(0xFF3B82F6);
      default:           return const Color(0xFFF59E0B);
    }
  }

  IconData _iconEstado(String? e) {
    switch (e) {
      case 'aprobada':   return Icons.check_circle;
      case 'rechazada':  return Icons.cancel;
      case 'en_proceso': return Icons.hourglass_top;
      default:           return Icons.schedule;
    }
  }

  String _labelEstado(String? e) {
    switch (e) {
      case 'aprobada':   return 'APROBADA';
      case 'rechazada':  return 'RECHAZADA';
      case 'en_proceso': return 'EN REVISIÓN';
      default:           return 'PENDIENTE';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
    if (_error != null) return _errorWidget(_error!, _cargar);
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.palette_outlined, size: 72, color: Colors.grey[800]),
        const SizedBox(height: 16),
        const Text('No tienes personalizaciones aún',
            style: TextStyle(color: Colors.white54, fontSize: 16)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/personalizadas'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea)),
          child: const Text('Crear personalización'),
        ),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: const Color(0xFF667eea),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _buildPersonalizacionCard(_items[i]),
      ),
    );
  }

  BoxDecoration _buildCardBorder(String estado, Color color) {
    final esAprobada = estado == 'aprobada';
    return BoxDecoration(
      color: const Color(0xFF1a1a1a),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: color.withOpacity(esAprobada ? 0.5 : 0.25),
        width: esAprobada ? 1.5 : 1,
      ),
    );
  }

  Widget _buildPersonalizacionCard(Map<String, dynamic> pers) {
    final idPers         = pers['id_personalizacion'] as int;
    final estado         = pers['estado'] ?? 'pendiente';
    final tipo           = pers['tipo_personalizacion'] ?? 'Personalización';
    final desc           = pers['descripcion_personalizacion'] ?? '';
    final precio         = double.tryParse(pers['precio_adicional']?.toString() ?? '0') ?? 0;
    final idPedido       = pers['id_pedido'];
    final color          = _colorEstado(estado);
    final procesando     = _procesando.contains(idPers);
    final puedeConfirmar = estado == 'aprobada' && idPedido == null;
    final yaConfirmada   = estado == 'aprobada' && idPedido != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _buildCardBorder(estado, color),
      child: Column(children: [
        _buildPersHeader(idPers, tipo, estado, color),
        if (desc.isNotEmpty) _buildPersDesc(desc),
        if (estado == 'aprobada') _buildPrecioAprobado(precio),
        if (estado == 'rechazada') _buildRechazadaInfo(),
        if (puedeConfirmar) _buildConfirmarBtn(pers, procesando),
        if (yaConfirmada) _buildYaConfirmada(idPedido),
      ]),
    );
  }

  Widget _buildPersHeader(int idPers, String tipo, String estado, Color color) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(_iconEstado(estado), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tipo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('#$idPers', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(_labelEstado(estado),
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildPersDesc(String desc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(desc,
              style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
    );
  }

  Widget _buildPrecioAprobado(double precio) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 18),
        const SizedBox(width: 8),
        const Text('Precio aprobado:', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        Text('\$${precio.toStringAsFixed(0)} COP',
            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  Widget _buildRechazadaInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
        SizedBox(width: 8),
        Expanded(child: Text(
          'Solicitud rechazada. Puedes crear una nueva con más detalles.',
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, height: 1.4),
        )),
      ]),
    );
  }

  Widget _buildConfirmarBtn(Map<String, dynamic> pers, bool procesando) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        width: double.infinity, height: 46,
        child: ElevatedButton.icon(
          onPressed: procesando ? null : () => _confirmarPedido(pers),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: procesando
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 18),
          label: Text(procesando ? 'Generando pedido...' : 'Confirmar y generar pedido',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildYaConfirmada(dynamic idPedido) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF667eea).withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.verified, color: Color(0xFF667eea), size: 16),
          const SizedBox(width: 8),
          Text('Pedido #$idPedido generado ✓',
              style: const TextStyle(
                  color: Color(0xFF667eea), fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ==========================================
// 📨 TAB PQRS
// ==========================================
class _PqrsTab extends StatefulWidget {
  final UserService userService;
  const _PqrsTab({required this.userService});
  @override
  State<_PqrsTab> createState() => _PqrsTabState();
}

class _PqrsTabState extends State<_PqrsTab> {
  List<dynamic> _pqrs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; });
    final r = await widget.userService.obtenerMisPqrs();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r['success']) { _pqrs = r['data'] ?? []; } else { _error = r['message']; }
    });
  }

  Color _colorEstado(String? e) {
    switch (e?.toLowerCase()) {
      case 'pendiente':  return const Color(0xFFF59E0B);
      case 'en_proceso': return const Color(0xFF3B82F6);
      case 'resuelta':   return const Color(0xFF10B981);
      case 'cerrada':    return Colors.grey;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
    if (_error != null) return _errorWidget(_error!, _cargar);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/pqrs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva PQRS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      if (_pqrs.isEmpty)
        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_outlined, size: 72, color: Colors.grey[800]),
            const SizedBox(height: 16),
            const Text('No tienes PQRS registradas',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        )))
      else
        Expanded(child: RefreshIndicator(
          onRefresh: _cargar,
          color: const Color(0xFF667eea),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _pqrs.length,
            itemBuilder: (_, i) => _buildPqrsCard(_pqrs[i]),
          ),
        )),
    ]);
  }

  Widget _buildPqrsCard(Map<String, dynamic> p) {
    final estado    = p['estado'] ?? 'pendiente';
    final color     = _colorEstado(estado);
    final respuesta = p['respuesta'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.support_agent, color: color, size: 20),
          ),
          title: Text(p['asunto'] ?? 'Sin asunto',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text((p['tipo'] ?? '').toUpperCase(),
                    style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(estado.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text((p['fecha_creacion'] ?? '').toString().split('T')[0],
                  style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ]),
          ),
          children: [
            const Divider(color: Color(0xFF2a2a2a)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tu mensaje:',
                    style: TextStyle(color: Color(0xFF667eea), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(p['mensaje'] ?? '',
                    style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 13)),
                if (respuesta != null && respuesta.toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 6),
                        Text('Respuesta del administrador:',
                            style: TextStyle(
                                color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Text(respuesta,
                          style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 13)),
                    ]),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 👤 TAB PERFIL
// ==========================================
class _PerfilTab extends StatefulWidget {
  final UserService userService;
  const _PerfilTab({required this.userService});
  @override
  State<_PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<_PerfilTab> {
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _actCtrl      = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confCtrl     = TextEditingController();

  Map<String, dynamic>? _perfil;
  bool _isLoading  = true;
  bool _isUpdating = false;
  String? _error;
  bool _showPass   = false;

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _apellidoCtrl.dispose();
    _actCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; });
    final r = await widget.userService.obtenerMiPerfil();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r['success']) {
        _perfil = r['data'];
        _nombreCtrl.text   = _perfil?['nombre'] ?? '';
        _apellidoCtrl.text = _perfil?['apellido'] ?? '';
      } else { _error = r['message']; }
    });
  }

  Future<void> _guardar() async {
    setState(() => _isUpdating = true);
    final r = await widget.userService.actualizarPerfil(
        nombre: _nombreCtrl.text.trim(), apellido: _apellidoCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isUpdating = false);
    _snack(r['success'] ? 'Perfil actualizado' : r['message'] ?? 'Error', error: !r['success']);
    if (r['success']) _cargar();
  }

  Future<void> _cambiarPass() async {
    if (_newCtrl.text != _confCtrl.text) { _snack('Las contraseñas no coinciden', error: true); return; }
    if (_newCtrl.text.length < 6) { _snack('Mínimo 6 caracteres', error: true); return; }
    setState(() => _isUpdating = true);
    final r = await widget.userService.cambiarContrasena(
        claveActual: _actCtrl.text, claveNueva: _newCtrl.text);
    if (!mounted) return;
    setState(() => _isUpdating = false);
    if (r['success']) { _actCtrl.clear(); _newCtrl.clear(); _confCtrl.clear(); }
    _snack(r['success'] ? 'Contraseña actualizada' : r['message'] ?? 'Error', error: !r['success']);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF667eea)));
    if (_error != null) return _errorWidget(_error!, _cargar);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildAvatar(authProvider),
        const SizedBox(height: 20),
        _buildDatosPersonales(),
        const SizedBox(height: 16),
        _buildCambiarContrasena(),
        const SizedBox(height: 20),
        _buildLogoutButton(authProvider),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildAvatar(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.person, size: 48, color: Color(0xFF667eea)),
        ),
        const SizedBox(height: 12),
        Text(authProvider.userFullName,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(_perfil?['correo'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _buildDatosPersonales() {
    return _seccion('Datos personales', Icons.person_outline, [
      _input('Nombre', _nombreCtrl),
      const SizedBox(height: 12),
      _input('Apellido', _apellidoCtrl),
      const SizedBox(height: 12),
      _input('Correo', TextEditingController(text: _perfil?['correo']), readOnly: true),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isUpdating
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }

  Widget _buildCambiarContrasena() {
    return _seccion('Cambiar contraseña', Icons.lock_outline, [
      _input('Contraseña actual',          _actCtrl,  obscure: !_showPass),
      const SizedBox(height: 12),
      _input('Nueva contraseña',           _newCtrl,  obscure: !_showPass),
      const SizedBox(height: 12),
      _input('Confirmar nueva contraseña', _confCtrl, obscure: !_showPass),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () => setState(() => _showPass = !_showPass),
        child: Row(children: [
          Icon(_showPass ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38, size: 16),
          const SizedBox(width: 6),
          Text(_showPass ? 'Ocultar contraseñas' : 'Mostrar contraseñas',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isUpdating ? null : _cambiarPass,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isUpdating
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }

  // ✅ FIX: usa mounted en lugar de context.mounted en callback asíncrono
  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await authProvider.logout();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/');
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
        label: const Text('Cerrar sesión',
            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _seccion(String titulo, IconData icono, List<Widget> hijos) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1a1a1a),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2a2a2a)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icono, color: const Color(0xFF667eea), size: 16),
        const SizedBox(width: 8),
        Text(titulo, style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 14),
      ...hijos,
    ]),
  );

  Widget _input(String label, TextEditingController ctrl,
      {bool readOnly = false, bool obscure = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      obscureText: obscure,
      style: TextStyle(color: readOnly ? Colors.white38 : Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: readOnly ? const Color(0xFF0a0a0a) : const Color(0xFF111111),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF667eea))),
      ),
    );
  }
}

// ── Helper global ──────────────────────────────────────────────────
Widget _errorWidget(String msg, VoidCallback onRetry) => Center(
  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 60, color: Color(0xFFEF4444)),
    const SizedBox(height: 16),
    Text(msg, style: const TextStyle(color: Colors.white54), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    ElevatedButton(
      onPressed: onRetry,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea)),
      child: const Text('Reintentar'),
    ),
  ]),
);