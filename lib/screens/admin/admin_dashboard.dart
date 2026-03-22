// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'roles_screen.dart';
import 'usuarios_screen.dart';
import 'pqrs_admin_screen.dart';
import 'inventario_screen.dart';
import 'pedidos_screen.dart';
import 'personalizaciones_screen.dart';
import 'ventas_screen.dart';
import 'productos_screen.dart';
import 'envios_screen.dart';
import 'pagos_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loadingStats = true;
  Map<String, dynamic> _stats = {};

  static const _bg     = Color(0xFF000000);
  static const _card   = Color(0xFF1a1a1a);
  static const _border = Color(0xFF2a2a2a);
  static const _accent = Color(0xFF667eea);
  static const _cyan   = Color(0xFF45F3FF);
  static const _green  = Color(0xFF10B981);
  static const _red    = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);
  static const _purple = Color(0xFF8B5CF6);
  static const _pink   = Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _loadingStats = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      const base = 'http://localhost:3001/api';

      // ✅ CORREGIDO: Authorization Bearer
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final results = await Future.wait([
        http.get(Uri.parse('$base/ventas'), headers: headers),
        http.get(Uri.parse('$base/pedidos'), headers: headers),
        http.get(Uri.parse('$base/personalizaciones'), headers: headers),
        http.get(Uri.parse('$base/pqrs'), headers: headers),
        http.get(Uri.parse('$base/usuarios'), headers: headers),
        http.get(Uri.parse('$base/inventario'), headers: headers),
      ]);

      // ✅ Si cualquier endpoint devuelve 401, el token expiró → logout
      if (results.any((r) => r.statusCode == 401)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      List<dynamic> ventas = [], pedidos = [], pers = [], pqrs = [], usuarios = [], inventario = [];

      if (results[0].statusCode == 200) {
        final d = jsonDecode(results[0].body);
        ventas = d is List ? d : (d['ventas'] ?? d['data'] ?? []);
      }
      if (results[1].statusCode == 200) {
        final d = jsonDecode(results[1].body);
        pedidos = d is List ? d : (d['pedidos'] ?? d['data'] ?? []);
      }
      if (results[2].statusCode == 200) {
        final d = jsonDecode(results[2].body);
        pers = d is List ? d : (d['personalizaciones'] ?? d['data'] ?? []);
      }
      if (results[3].statusCode == 200) {
        final d = jsonDecode(results[3].body);
        pqrs = d is List ? d : (d['pqrs'] ?? d['data'] ?? []);
      }
      if (results[4].statusCode == 200) {
        final d = jsonDecode(results[4].body);
        usuarios = d is List ? d : (d['usuarios'] ?? d['data'] ?? []);
      }
      if (results[5].statusCode == 200) {
        final d = jsonDecode(results[5].body);
        // ✅ inventario devuelve { movimientos: [...] }
        inventario = d is List ? d : (d['movimientos'] ?? d['inventario'] ?? d['data'] ?? []);
      }

      final now = DateTime.now();
      final ventasMes = ventas.where((v) {
        try {
          final f = DateTime.parse(v['fecha']?.toString() ?? v['createdAt']?.toString() ?? '');
          return f.month == now.month && f.year == now.year;
        } catch (_) { return false; }
      }).toList();

      double totalMes = ventasMes.fold(0.0, (s, v) =>
          s + (double.tryParse(v['total']?.toString() ?? '0') ?? 0));
      double totalGeneral = ventas.fold(0.0, (s, v) =>
          s + (double.tryParse(v['total']?.toString() ?? '0') ?? 0));

      Map<String, int> estadosPedido = {};
      for (final p in pedidos) {
        final e = p['estado'] ?? 'pendiente';
        estadosPedido[e] = (estadosPedido[e] ?? 0) + 1;
      }

      Map<String, int> estadosPers = {};
      for (final p in pers) {
        final e = p['estado'] ?? 'pendiente';
        estadosPers[e] = (estadosPers[e] ?? 0) + 1;
      }

      Map<String, int> estadosPqrs = {};
      for (final p in pqrs) {
        final e = p['estado'] ?? 'Pendiente';
        estadosPqrs[e] = (estadosPqrs[e] ?? 0) + 1;
      }

      // ✅ Stock bajo — inventario devuelve movimientos, buscar stock_resultante <= stock_minimo
      final stockBajo = inventario.where((i) {
        final disp = int.tryParse(
            i['stock_resultante']?.toString() ??
            i['stock_disponible']?.toString() ??
            i['cantidad']?.toString() ?? '99') ?? 99;
        final min = int.tryParse(i['stock_minimo']?.toString() ?? '5') ?? 5;
        return disp <= min;
      }).toList();

      Map<String, double> ventasPorDia = {};
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final key = '${d.day}/${d.month}';
        ventasPorDia[key] = 0;
      }
      for (final v in ventas) {
        try {
          final f = DateTime.parse(v['fecha']?.toString() ?? v['createdAt']?.toString() ?? '');
          final key = '${f.day}/${f.month}';
          if (ventasPorDia.containsKey(key)) {
            ventasPorDia[key] = (ventasPorDia[key] ?? 0) +
                (double.tryParse(v['total']?.toString() ?? '0') ?? 0);
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        _stats = {
          'totalVentas': ventas.length,
          'totalMes': totalMes,
          'totalGeneral': totalGeneral,
          'ventasMes': ventasMes.length,
          'totalPedidos': pedidos.length,
          'totalPers': pers.length,
          'totalPqrs': pqrs.length,
          'totalUsuarios': usuarios.length,
          'estadosPedido': estadosPedido,
          'estadosPers': estadosPers,
          'estadosPqrs': estadosPqrs,
          'stockBajo': stockBajo,
          'ventasPorDia': ventasPorDia,
          'pqrsRecientes': pqrs.take(5).toList(),
          'pedidosRecientes': pedidos.take(5).toList(),
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  String _formatMoney(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} COP';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('URBAN COPS - Admin',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        backgroundColor: _bg,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view), text: 'Módulos'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reportes'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(authProvider.userFullName,
                  style: const TextStyle(color: _cyan, fontWeight: FontWeight.w600)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _red),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModulos(authProvider),
          _buildReportes(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: MÓDULOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildModulos(AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Panel de Administración',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Bienvenido, ${authProvider.userFullName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ])),
          ]),
        ),
        const SizedBox(height: 30),
        const Text('MÓDULOS DEL SISTEMA',
            style: TextStyle(color: _cyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.0,
          children: [
            _buildAdminCard(context, icon: Icons.people, title: 'USUARIOS',
                subtitle: 'Gestión de usuarios', color: _green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UsuariosScreen()))),
            _buildAdminCard(context, icon: Icons.theater_comedy, title: 'ROLES',
                subtitle: 'Roles y permisos', color: const Color(0xFF3B82F6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RolesScreen()))),
            _buildAdminCard(context, icon: Icons.inventory_2, title: 'INVENTARIO',
                subtitle: 'Productos y stock', color: _purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventarioScreen()))),
            _buildAdminCard(context, icon: Icons.storefront, title: 'PRODUCTOS',
                subtitle: 'Catálogo de productos', color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductosScreen()))),
            _buildAdminCard(context, icon: Icons.shopping_cart, title: 'VENTAS',
                subtitle: 'Ventas y pedidos', color: _orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentasScreen()))),
            _buildAdminCard(context, icon: Icons.receipt_long, title: 'PEDIDOS',
                subtitle: 'Pedidos de clientes', color: _red,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PedidosScreen()))),
            _buildAdminCard(context, icon: Icons.palette, title: 'PERSONALIZ.',
                subtitle: 'Personalizaciones', color: _pink,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalizacionesAdminScreen()))),
            _buildAdminCard(context, icon: Icons.local_shipping, title: 'ENVÍOS',
                subtitle: 'Envíos y entregas', color: const Color(0xFFF97316),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnviosScreen()))),
            _buildAdminCard(context, icon: Icons.payment, title: 'PAGOS',
                subtitle: 'Administración de pagos', color: _cyan,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PagosScreen()))),
            _buildAdminCard(context, icon: Icons.support_agent, title: 'PQRS',
                subtitle: 'Quejas y reclamos', color: _pink,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PqrsAdminScreen()))),
          ],
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: REPORTES
  // ═══════════════════════════════════════════════════════════
  Widget _buildReportes() {
    if (_loadingStats) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: _accent),
        SizedBox(height: 16),
        Text('Cargando estadísticas...', style: TextStyle(color: Colors.white54)),
      ]));
    }

    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;

    return RefreshIndicator(
      onRefresh: _cargarEstadisticas,
      color: _accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          _sectionTitle('Resumen General', Icons.dashboard),
          const SizedBox(height: 12),
          isMobile
            ? Column(children: [
                Row(children: [
                  Expanded(child: _kpi('Ventas este mes', '${_stats['ventasMes'] ?? 0}', Icons.trending_up, _green)),
                  const SizedBox(width: 12),
                  Expanded(child: _kpi('Ingresos mes', _formatMoney((_stats['totalMes'] ?? 0.0) as double), Icons.attach_money, _accent)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _kpi('Pedidos totales', '${_stats['totalPedidos'] ?? 0}', Icons.shopping_bag, _orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _kpi('Usuarios', '${_stats['totalUsuarios'] ?? 0}', Icons.people, _purple)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _kpi('PQRS abiertas', '${(_stats['estadosPqrs'] as Map<String,int>? ?? {})['Pendiente'] ?? 0}', Icons.support_agent, _red)),
                  const SizedBox(width: 12),
                  Expanded(child: _kpi('Personalizaciones', '${_stats['totalPers'] ?? 0}', Icons.palette, _pink)),
                ]),
              ])
            : Row(children: [
                Expanded(child: _kpi('Ventas este mes', '${_stats['ventasMes'] ?? 0}', Icons.trending_up, _green)),
                const SizedBox(width: 12),
                Expanded(child: _kpi('Ingresos mes', _formatMoney((_stats['totalMes'] ?? 0.0) as double), Icons.attach_money, _accent)),
                const SizedBox(width: 12),
                Expanded(child: _kpi('Pedidos totales', '${_stats['totalPedidos'] ?? 0}', Icons.shopping_bag, _orange)),
                const SizedBox(width: 12),
                Expanded(child: _kpi('Usuarios', '${_stats['totalUsuarios'] ?? 0}', Icons.people, _purple)),
                const SizedBox(width: 12),
                Expanded(child: _kpi('PQRS pendientes', '${(_stats['estadosPqrs'] as Map<String,int>? ?? {})['Pendiente'] ?? 0}', Icons.support_agent, _red)),
              ]),

          const SizedBox(height: 28),

          _sectionTitle('Ventas últimos 7 días', Icons.bar_chart),
          const SizedBox(height: 12),
          _ventasChart(),

          const SizedBox(height: 28),

          isMobile
            ? Column(children: [
                _estadosCard('Pedidos por estado', _stats['estadosPedido'] as Map<String,int>? ?? {}, {
                  'pendiente': _orange, 'en_proceso': _accent,
                  'enviado': _purple, 'completado': _green, 'cancelado': _red,
                }),
                const SizedBox(height: 16),
                _estadosCard('PQRS por estado', _stats['estadosPqrs'] as Map<String,int>? ?? {}, {
                  'Pendiente': _red, 'En Proceso': _orange,
                  'Resuelto': _green, 'Cerrado': Colors.white24,
                }),
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _estadosCard('Pedidos por estado',
                    _stats['estadosPedido'] as Map<String,int>? ?? {}, {
                  'pendiente': _orange, 'en_proceso': _accent,
                  'enviado': _purple, 'completado': _green, 'cancelado': _red,
                })),
                const SizedBox(width: 16),
                Expanded(child: _estadosCard('PQRS por estado',
                    _stats['estadosPqrs'] as Map<String,int>? ?? {}, {
                  'Pendiente': _red, 'En Proceso': _orange,
                  'Resuelto': _green, 'Cerrado': Colors.white24,
                })),
              ]),

          const SizedBox(height: 28),

          _sectionTitle('Personalizaciones por estado', Icons.palette),
          const SizedBox(height: 12),
          _estadosCard('', _stats['estadosPers'] as Map<String,int>? ?? {}, {
            'pendiente': _orange, 'en_proceso': _accent,
            'aprobada': _green, 'rechazada': _red,
          }),

          const SizedBox(height: 28),

          if ((_stats['stockBajo'] as List? ?? []).isNotEmpty) ...[
            _sectionTitle('⚠️ Productos con stock bajo', Icons.warning_amber, color: _orange),
            const SizedBox(height: 12),
            _stockBajoTable(),
            const SizedBox(height: 28),
          ],

          _sectionTitle('PQRS recientes', Icons.support_agent),
          const SizedBox(height: 12),
          _pqrsTable(),

          const SizedBox(height: 28),

          _sectionTitle('Pedidos recientes', Icons.receipt_long),
          const SizedBox(height: 12),
          _pedidosTable(),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionTitle(String text, IconData icon, {Color color = Colors.white}) {
    return Row(children: [
      Icon(icon, color: color == Colors.white ? _accent : color, size: 20),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ]),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _ventasChart() {
    final data = _stats['ventasPorDia'] as Map<String, double>? ?? {};
    if (data.isEmpty) return _emptyState('Sin datos de ventas');

    final maxVal = data.values.fold(0.0, (a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Ingresos diarios', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(_formatMoney(data.values.fold(0.0, (a, b) => a + b)),
              style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((e) {
              final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (e.value > 0)
                      Text('\$${(e.value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(color: Colors.white54, fontSize: 9)),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      height: pct * 80 + (e.value > 0 ? 4 : 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [_accent, _accent.withOpacity(0.5)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(e.key, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _estadosCard(String title, Map<String, int> data, Map<String, Color> colors) {
    if (data.isEmpty) return _emptyState('Sin datos');
    final total = data.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title.isNotEmpty) ...[
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
        ],
        ...data.entries.map((e) {
          final color = colors[e.key] ?? Colors.white24;
          final pct = total == 0 ? 0.0 : e.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _stockBajoTable() {
    final items = _stats['stockBajo'] as List? ?? [];
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withOpacity(0.3)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('Producto', style: TextStyle(color: Colors.white54, fontSize: 12))),
            Expanded(child: Text('Stock', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center)),
            Expanded(child: Text('Mínimo', style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center)),
          ]),
        ),
        ...items.map((i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
          child: Row(children: [
            Expanded(flex: 3, child: Text(
              i['nombre_producto'] ?? i['Producto']?['nombre_producto'] ?? 'Producto',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            )),
            Expanded(child: Text(
              '${i['stock_resultante'] ?? i['stock_disponible'] ?? i['cantidad'] ?? 0}',
              style: const TextStyle(color: _red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            )),
            Expanded(child: Text(
              '${i['stock_minimo'] ?? 5}',
              style: const TextStyle(color: Colors.white38),
              textAlign: TextAlign.center,
            )),
          ]),
        )),
      ]),
    );
  }

  Widget _pqrsTable() {
    final items = _stats['pqrsRecientes'] as List? ?? [];
    if (items.isEmpty) return _emptyState('No hay PQRS registradas');

    Color colorEstado(String e) => e == 'Pendiente' ? _red
        : e == 'En Proceso' ? _orange
        : e == 'Resuelto' ? _green
        : Colors.white38;

    return Container(
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(children: [
        _tableHeader(['Nombre', 'Tipo', 'Estado', 'Fecha']),
        ...items.map((p) {
          final estado = p['estado'] ?? 'Pendiente';
          return _tableRow([
            p['nombre'] ?? '—',
            p['tipo_pqrs'] ?? '—',
            estado,
            _formatFecha(p['fecha_solicitud'] ?? p['createdAt']),
          ], estadoColor: colorEstado(estado), estadoIdx: 2);
        }),
      ]),
    );
  }

  Widget _pedidosTable() {
    final items = _stats['pedidosRecientes'] as List? ?? [];
    if (items.isEmpty) return _emptyState('No hay pedidos registrados');

    Color colorEstado(String e) => e == 'pendiente' ? _orange
        : e == 'completado' ? _green
        : e == 'cancelado' ? _red
        : _accent;

    return Container(
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Column(children: [
        _tableHeader(['ID', 'Total', 'Estado', 'Fecha']),
        ...items.map((p) {
          final estado = p['estado'] ?? 'pendiente';
          return _tableRow([
            '#${p['id_pedido'] ?? p['id'] ?? '—'}',
            '\$${p['total'] ?? '0'}',
            estado,
            _formatFecha(p['fecha_pedido'] ?? p['createdAt']),
          ], estadoColor: colorEstado(estado), estadoIdx: 2);
        }),
      ]),
    );
  }

  Widget _tableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(children: cols.map((c) =>
        Expanded(child: Text(c, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)))).toList()),
    );
  }

  Widget _tableRow(List<String> vals, {Color? estadoColor, int estadoIdx = -1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(children: vals.asMap().entries.map((e) {
        final isEstado = e.key == estadoIdx;
        return Expanded(child: isEstado
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (estadoColor ?? Colors.white24).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (estadoColor ?? Colors.white24).withOpacity(0.4)),
              ),
              child: Text(e.value,
                style: TextStyle(color: estadoColor ?? Colors.white, fontSize: 11),
                textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            )
          : Text(e.value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis));
      }).toList()),
    );
  }

  Widget _emptyState(String msg) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
    child: Center(child: Text(msg, style: const TextStyle(color: Colors.white38))),
  );

  String _formatFecha(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return raw.toString(); }
  }

  Widget _buildAdminCard(BuildContext context, {
    required IconData icon, required String title,
    required String subtitle, required Color color, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}