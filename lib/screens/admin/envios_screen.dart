// lib/screens/admin/envios_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_config.dart';

class EnviosScreen extends StatefulWidget {
  const EnviosScreen({super.key});

  @override
  State<EnviosScreen> createState() => _EnviosScreenState();
}

class _EnviosScreenState extends State<EnviosScreen> {
  List<dynamic> _envios = [];
  List<dynamic> _enviosFiltrados = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';
  final TextEditingController _busquedaCtrl = TextEditingController();

  int _currentPage = 0;
  int _pageSize = 10;
  static const _pageSizes = [5, 10, 20, 50];

  List<dynamic> get _enviosPaginados {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _enviosFiltrados.length);
    if (start >= _enviosFiltrados.length) return [];
    return _enviosFiltrados.sublist(start, end);
  }

  int get _totalPages => _enviosFiltrados.isEmpty
      ? 1
      : (_enviosFiltrados.length / _pageSize).ceil();

  final List<String> _estados = ['todos', 'pendiente', 'en_camino', 'entregado', 'devuelto'];

  final Map<String, Color> _coloresEstado = {
    'pendiente': const Color(0xFFF59E0B),
    'en_camino': const Color(0xFF3B82F6),
    'entregado': const Color(0xFF10B981),
    'devuelto':  const Color(0xFFEF4444),
  };

  final Map<String, IconData> _iconosEstado = {
    'pendiente': Icons.hourglass_empty,
    'en_camino': Icons.local_shipping,
    'entregado': Icons.check_circle,
    'devuelto':  Icons.replay,
  };

  @override
  void initState() {
    super.initState();
    _cargarEnvios();
    _busquedaCtrl.addListener(() {
      setState(() { _currentPage = 0; _aplicarFiltros(); });
    });
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

  // ✅ Header correcto
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-access-token': token,
  };

  Future<void> _cargarEnvios() async {
    setState(() => _cargando = true);
    try {
      final token = await _getToken();
      if (token == null) { _mostrarError('No autenticado'); return; }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/envios'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _envios = data is List ? data : [];
          _currentPage = 0;
          _aplicarFiltros();
        });
      } else {
        _mostrarError('Error al cargar envíos (${response.statusCode})');
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
      _enviosFiltrados = _envios.where((e) {
        final pedido  = e['Pedido'];
        final usuario = pedido?['Usuario'];
        final nombre  = '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'.toLowerCase();
        final idEnvio = e['id_envio'].toString();
        final ciudad  = (e['ciudad'] ?? '').toLowerCase();
        final coincideBusqueda = busqueda.isEmpty ||
            nombre.contains(busqueda) ||
            idEnvio.contains(busqueda) ||
            ciudad.contains(busqueda);
        final coincideEstado = _filtroEstado == 'todos' || e['estado_envio'] == _filtroEstado;
        return coincideBusqueda && coincideEstado;
      }).toList();
    });
  }

  Future<void> _cambiarEstado(dynamic envio) async {
    String estadoSeleccionado = envio['estado_envio'] ?? 'pendiente';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.local_shipping, color: Color(0xFFF97316), size: 20),
            const SizedBox(width: 8),
            Text('Envío #${envio['id_envio']}',
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
                children: ['pendiente', 'en_camino', 'entregado', 'devuelto'].map((e) {
                  final seleccionado = estadoSeleccionado == e;
                  final color = _coloresEstado[e] ?? Colors.grey;
                  return GestureDetector(
                    onTap: () => setStateDialog(() => estadoSeleccionado = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: seleccionado ? color.withOpacity(0.25) : const Color(0xFF0a0a0a),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: seleccionado ? color : const Color(0xFF2a2a2a),
                          width: seleccionado ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        e.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: seleccionado ? color : Colors.white54,
                          fontSize: 11,
                          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (estadoSeleccionado == envio['estado_envio']) { Navigator.pop(ctx); return; }
                Navigator.pop(ctx);
                await _actualizarEstado(envio['id_envio'], estadoSeleccionado);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actualizarEstado(int idEnvio, String nuevoEstado) async {
    try {
      final token = await _getToken();
      if (token == null) { _mostrarError('No autenticado'); return; }
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/envios/$idEnvio'),
        headers: _headers(token),
        body: jsonEncode({'estado_envio': nuevoEstado}),
      );
      if (response.statusCode == 200) {
        _mostrarSnack('Estado actualizado');
        await _cargarEnvios();
      } else {
        _mostrarError('No se pudo actualizar el estado');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    }
  }

  void _mostrarDetalle(dynamic envio) {
    final pedido  = envio['Pedido'];
    final usuario = pedido?['Usuario'];
    final color   = _coloresEstado[envio['estado_envio']] ?? Colors.grey;
    final icono   = _iconosEstado[envio['estado_envio']] ?? Icons.local_shipping;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Envío #${envio['id_envio']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () { Navigator.pop(context); _cambiarEstado(envio); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.6)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icono, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          (envio['estado_envio'] ?? '').replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 11, color: color),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _seccion('Dirección de entrega', Icons.location_on, [
                _fila('Dirección', envio['direccion'] ?? '-'),
                _fila('Ciudad',    envio['ciudad']    ?? '-'),
                _fila('Teléfono',  envio['telefono']  ?? '-'),
                _fila('Fecha',     _formatFecha(envio['fecha'])),
              ]),
              const SizedBox(height: 12),

              if (usuario != null) ...[
                _seccion('Cliente', Icons.person, [
                  _fila('Nombre', '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'),
                  _fila('Correo', usuario['correo'] ?? '-'),
                ]),
                const SizedBox(height: 12),
              ],

              if (pedido != null)
                _seccion('Pedido vinculado', Icons.receipt_long, [
                  _fila('ID pedido',    '#${pedido['id_pedido']}'),
                  _fila('Fecha pedido', _formatFecha(pedido['fecha_pedido'])),
                  _fila('Total',        '\$${double.tryParse(pedido['total'].toString())?.toStringAsFixed(2) ?? '0.00'}'),
                ]),
            ],
          ),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icono, color: const Color(0xFFF97316), size: 15),
          const SizedBox(width: 6),
          Text(titulo,
              style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 10),
        ...hijos,
      ],
    ),
  );

  Widget _fila(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Flexible(
          child: Text(valor,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '-';
    try {
      final dt = DateTime.parse(fecha.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return fecha.toString(); }
  }

  void _mostrarError(String msg) => _mostrarSnack(msg, color: const Color(0xFFEF4444));

  void _mostrarSnack(String msg, {Color color = const Color(0xFF10B981)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('Envíos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2a2a2a)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFF97316)),
            onPressed: _cargarEnvios,
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: TextField(
              controller: _busquedaCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, ciudad o # envío...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white24),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          setState(() { _currentPage = 0; _aplicarFiltros(); });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1a1a1a),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // Filtros con contadores
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: _estados.map((estado) {
                final sel   = _filtroEstado == estado;
                final color = estado == 'todos'
                    ? const Color(0xFFF97316)
                    : (_coloresEstado[estado] ?? Colors.grey);
                final count = estado == 'todos'
                    ? _envios.length
                    : _envios.where((e) => e['estado_envio'] == estado).length;
                return GestureDetector(
                  onTap: () => setState(() {
                    _filtroEstado = estado;
                    _currentPage = 0;
                    _aplicarFiltros();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.15) : const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? color : const Color(0xFF2a2a2a),
                          width: sel ? 1.5 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        estado == 'todos' ? 'Todos' : estado.replaceAll('_', ' '),
                        style: TextStyle(
                          color: sel ? color : Colors.white38,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: sel ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: TextStyle(
                                color: sel ? color : Colors.white24,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Lista
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)))
                : _enviosPaginados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                size: 72, color: Colors.grey[800]),
                            const SizedBox(height: 14),
                            const Text('Sin envíos',
                                style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ))
                    : RefreshIndicator(
                        onRefresh: _cargarEnvios,
                        color: const Color(0xFFF97316),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _enviosPaginados.length,
                          itemBuilder: (_, i) => _buildEnvioCard(_enviosPaginados[i]),
                        ),
                      ),
          ),

          _buildPaginacion(),
        ],
      ),
    );
  }

  Widget _buildEnvioCard(dynamic envio) {
    final pedido  = envio['Pedido'];
    final usuario = pedido?['Usuario'];
    final color   = _coloresEstado[envio['estado_envio']] ?? Colors.grey;
    final icono   = _iconosEstado[envio['estado_envio']] ?? Icons.local_shipping;

    return GestureDetector(
      onTap: () => _mostrarDetalle(envio),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('#${envio['id_envio']}',
                        style: const TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}'.trim().isEmpty
                          ? 'Sin cliente'
                          : '${usuario?['nombre'] ?? ''} ${usuario?['apellido'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${envio['ciudad'] ?? ''} · ${envio['direccion'] ?? ''}'.trim() == '·' ? 'Sin dirección' : '${envio['ciudad'] ?? ''} · ${envio['direccion'] ?? ''}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatFecha(envio['fecha']),
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  (envio['estado_envio'] ?? '').replaceAll('_', ' '),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
            icon: const Icon(Icons.expand_more, color: Color(0xFFF97316), size: 16),
            items: _pageSizes
                .map((s) => DropdownMenuItem(value: s, child: Text('$s / pág')))
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() { _pageSize = val; _currentPage = 0; });
            },
          ),
        ),
      ),
      const SizedBox(width: 8),
      _btnPagina(Icons.chevron_left, _currentPage > 0, () => setState(() => _currentPage--)),
      Expanded(
        child: Center(
          child: Text('Pág. ${_currentPage + 1} / $_totalPages',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      ),
      _btnPagina(Icons.chevron_right, _currentPage < _totalPages - 1,
          () => setState(() => _currentPage++)),
    ]),
  );

  Widget _btnPagina(IconData icon, bool enabled, VoidCallback onTap) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF1a1a1a) : const Color(0xFF0a0a0a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: enabled ? const Color(0xFF2a2a2a) : Colors.transparent),
      ),
      child: Icon(icon, color: enabled ? const Color(0xFFF97316) : Colors.white12, size: 18),
    ),
  );
}