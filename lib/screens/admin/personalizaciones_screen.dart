// lib/screens/admin/personalizaciones_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/personalizacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/personalizacion_service.dart';

class PersonalizacionesAdminScreen extends StatefulWidget {
  const PersonalizacionesAdminScreen({super.key});

  @override
  State<PersonalizacionesAdminScreen> createState() =>
      _PersonalizacionesAdminScreenState();
}

class _PersonalizacionesAdminScreenState
    extends State<PersonalizacionesAdminScreen> {

  List<Personalizacion> _items    = [];
  List<Personalizacion> _filtrados = [];
  bool   _isLoading    = true;
  String _filtroEstado = 'todos';
  String _searchQuery  = '';
  final  _searchCtrl   = TextEditingController();

  int _page     = 0;
  int _pageSize = 10;
  static const _pageSizes = [5, 10, 20, 50];

  List<Personalizacion> get _paginados {
    final s = _page * _pageSize;
    final e = (s + _pageSize).clamp(0, _filtrados.length);
    return s >= _filtrados.length ? [] : _filtrados.sublist(s, e);
  }
  int get _totalPages =>
      _filtrados.isEmpty ? 1 : (_filtrados.length / _pageSize).ceil();

  static const _estados = ['todos', 'pendiente', 'en_proceso', 'aprobada', 'rechazada'];
  static const _coloresEstado = {
    'pendiente':  Color(0xFFF59E0B),
    'en_proceso': Color(0xFF3B82F6),
    'aprobada':   Color(0xFF10B981),
    'rechazada':  Color(0xFFEF4444),
  };
  static const _iconosTipo = {
    'bordado':   Icons.gesture,
    'estampado': Icons.print,
    'parche':    Icons.layers,
    'tie-dye':   Icons.palette,
    'otro':      Icons.auto_awesome,
  };
  static const _bg      = Color(0xFF000000);
  static const _surface = Color(0xFF0a0a0a);
  static const _card    = Color(0xFF1a1a1a);
  static const _border  = Color(0xFF2a2a2a);
  static const _red     = Color(0xFFEF4444);

  // ── FIX L151: constante para el literal duplicado ─────────────────────
  static const _sinUsuario = 'Usuario desconocido';

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
        _page = 0;
        _aplicarFiltro();
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  String _token() => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    final r = await PersonalizacionService.getAll(_token());
    setState(() {
      if (r['success']) {
        _items = r['data'] as List<Personalizacion>;
        _page  = 0;
        _aplicarFiltro();
      }
      _isLoading = false;
    });
    if (!r['success']) _snack(r['message'] ?? 'Error', error: true);
  }

  void _aplicarFiltro() {
    var lista = _filtroEstado == 'todos'
        ? List<Personalizacion>.from(_items)
        : _items.where((p) => p.estado == _filtroEstado).toList();
    if (_searchQuery.isNotEmpty) {
      lista = lista.where((p) =>
          p.idPersonalizacion.toString().contains(_searchQuery) ||
          p.nombreUsuario.toLowerCase().contains(_searchQuery) ||
          p.descripcion.toLowerCase().contains(_searchQuery)).toList();
    }
    _filtrados = lista;
  }

  // ── FIX L110: _gestionar partido en sub-métodos ───────────────────────

  Widget _buildGestionarInfoUsuario(Personalizacion item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        const Icon(Icons.person_outline, color: Colors.white38, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          item.nombreUsuario.isNotEmpty ? item.nombreUsuario : _sinUsuario,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        )),
      ]),
    );
  }

  Widget _buildGestionarSelectorEstado(String? estadoSel, void Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Estado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _estados.skip(1).map((estado) {
          final color = _coloresEstado[estado] ?? Colors.grey;
          final sel   = estadoSel == estado;
          return GestureDetector(
            onTap: () => onSelect(estado),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.2) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? color : _border, width: sel ? 2 : 1),
              ),
              child: Text(
                estado.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                    color: sel ? color : Colors.white38,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildGestionarCampoPrecio(TextEditingController precioCtrl, void Function(double?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Precio adicional (\$)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(
        controller: precioCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        onChanged: (v) => onChanged(double.tryParse(v)),
        decoration: InputDecoration(
          prefixText: '\$ ',
          prefixStyle: const TextStyle(color: _red, fontSize: 20, fontWeight: FontWeight.bold),
          hintText: '0',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 20),
          filled: true, fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _red, width: 2)),
        ),
      ),
    ]);
  }

  // ✅ FIX L110: complejidad reducida extrayendo sub-widgets
  Future<void> _gestionar(Personalizacion item) async {
    String? nuevoEstado = item.estado;
    double? nuevoPrecio = item.precioAdicional;
    final precioCtrl = TextEditingController(
        text: item.precioAdicional > 0 ? item.precioAdicional.toStringAsFixed(0) : '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.tune, color: _red, size: 18),
          const SizedBox(width: 8),
          Text('Solicitud #${item.idPersonalizacion}',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: StatefulBuilder(
          builder: (_, set) => SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGestionarInfoUsuario(item),
                const SizedBox(height: 16),
                _buildGestionarSelectorEstado(nuevoEstado, (e) => set(() => nuevoEstado = e)),
                const SizedBox(height: 16),
                _buildGestionarCampoPrecio(precioCtrl, (v) => nuevoPrecio = v ?? 0),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              final r = await PersonalizacionService.actualizar(
                id:              item.idPersonalizacion!,
                token:           _token(),
                estado:          nuevoEstado,
                precioAdicional: nuevoPrecio,
              );
              _snack(r['message'] ?? (r['success'] ? 'Guardado' : 'Error'), error: !r['success']);
              if (r['success']) _cargar();
            },
            child: const Text('Guardar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── FIX L277: _verDetalle partido en sub-métodos ──────────────────────

  Widget _buildDetalleHeader(Personalizacion item, Color color) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Solicitud #${item.idPersonalizacion}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          item.nombreUsuario.isNotEmpty ? item.nombreUsuario : _sinUsuario,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ])),
      GestureDetector(
        onTap: () { Navigator.pop(context); _gestionar(item); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(item.estado.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.edit, size: 11, color: color),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildDetallePrecio(Personalizacion item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.precioAdicional > 0 ? _red.withOpacity(0.1) : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: item.precioAdicional > 0 ? _red.withOpacity(0.3) : _border),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PRECIO ADICIONAL',
              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            item.precioAdicional > 0
                ? '\$${item.precioAdicional.toStringAsFixed(0)}'
                : 'Por definir',
            style: TextStyle(
                color: item.precioAdicional > 0 ? _red : Colors.white38,
                fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ]),
        GestureDetector(
          onTap: () { Navigator.pop(context); _gestionar(item); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red.withOpacity(0.4)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit, color: _red, size: 14),
              SizedBox(width: 6),
              Text('Gestionar', style: TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildDetallePersonalizacion(Personalizacion item) {
    return _infoBox([
      if (item.tipoPersonalizacion != null)
        _fila(
          _iconosTipo[item.tipoPersonalizacion] ?? Icons.build,
          'Tipo',
          item.tipoPersonalizacion!.replaceAll('-', ' ').toUpperCase(),
          valueColor: _coloresEstado.values.first,
        ),
      if (item.talla != null) _fila(Icons.straighten, 'Talla', item.talla!),
      if (item.colorDeseado != null) _fila(Icons.color_lens, 'Color', item.colorDeseado!),
      if (item.descripcionPersonalizacion != null)
        _filaMultilinea(Icons.description, 'Descripción', item.descripcionPersonalizacion!),
    ]);
  }

  // ✅ FIX L277: complejidad reducida extrayendo sub-widgets
  void _verDetalle(Personalizacion item) {
    final color = _coloresEstado[item.estado] ?? Colors.grey;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            _buildDetalleHeader(item, color),
            const SizedBox(height: 20),
            _buildDetallePrecio(item),
            const SizedBox(height: 20),
            _sheetLabel('PERSONALIZACIÓN'),
            const SizedBox(height: 10),
            _buildDetallePersonalizacion(item),
            const SizedBox(height: 20),
            if (item.producto != null) ...[
              _sheetLabel('GORRA BASE'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: _buildImagen(item.producto!.imagen, size: 60)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.producto!.nombre,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('\$${item.producto!.precio.toStringAsFixed(0)} base',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),
            ],
            if (item.imagenReferencia != null && item.imagenReferencia!.isNotEmpty) ...[
              _sheetLabel('IMAGEN DE REFERENCIA'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImagenReferencia(item.imagenReferencia!),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _eliminar(Personalizacion item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar solicitud', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar solicitud #${item.idPersonalizacion}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final r = await PersonalizacionService.eliminar(item.idPersonalizacion!, _token());
    _snack(r['message'] ?? (r['success'] ? 'Eliminado' : 'Error'), error: !r['success']);
    if (r['success']) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Personalizaciones',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: _red), onPressed: _cargar)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _red))
          : Column(children: [
              _buildBuscador(),
              _buildFiltrosEstado(),
              const SizedBox(height: 4),
              Expanded(child: _buildLista(auth)),
              _buildPaginacion(),
            ]),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por ID, usuario o descripción...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white24),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                  onPressed: () => setState(() {
                    _searchCtrl.clear(); _searchQuery = ''; _page = 0; _aplicarFiltro();
                  }),
                )
              : null,
          filled: true, fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildFiltrosEstado() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: _estados.map((estado) {
          final sel   = _filtroEstado == estado;
          final color = estado == 'todos' ? _red : (_coloresEstado[estado] ?? Colors.grey);
          final count = estado == 'todos'
              ? _items.length
              : _items.where((i) => i.estado == estado).length;
          return GestureDetector(
            onTap: () => setState(() { _filtroEstado = estado; _page = 0; _aplicarFiltro(); }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.15) : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? color : _border, width: sel ? 1.5 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  estado == 'todos' ? 'Todos' : _capitalize(estado.replaceAll('_', ' ')),
                  style: TextStyle(
                      color: sel ? color : Colors.white38,
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal),
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
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildLista(AuthProvider auth) {
    if (_filtrados.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.palette_outlined, size: 72, color: Colors.grey[800]),
        const SizedBox(height: 14),
        const Text('Sin solicitudes', style: TextStyle(color: Colors.grey, fontSize: 15)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      color: _red,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _paginados.length,
        itemBuilder: (_, i) => _buildCard(_paginados[i], auth),
      ),
    );
  }

  // ── FIX L544: _buildCard partido en sub-widgets ───────────────────────

  Widget _buildCardFila1(Personalizacion item, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _red.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
        child: Text('#${item.idPersonalizacion}',
            style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(
        item.nombreUsuario.isNotEmpty ? item.nombreUsuario : _sinUsuario,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(item.estado.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _buildCardFila2(Personalizacion item) {
    final tipo = item.tipoPersonalizacion;
    return Row(children: [
      if (tipo != null) ...[
        Icon(_iconosTipo[tipo] ?? Icons.build, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(tipo[0].toUpperCase() + tipo.substring(1),
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 10),
      ],
      if (item.talla != null) ...[_chip(item.talla!), const SizedBox(width: 6)],
      if (item.colorDeseado != null)
        _chip(item.colorDeseado!, icon: Icons.circle, iconColor: Colors.white38),
      const Spacer(),
      if (item.precioAdicional > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: _red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withOpacity(0.3))),
          child: Text('+\$${item.precioAdicional.toStringAsFixed(0)}',
              style: const TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 13)),
        )
      else
        const Text('Precio pendiente', style: TextStyle(color: Colors.white24, fontSize: 11)),
    ]);
  }

  Widget _buildCardAcciones(Personalizacion item) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton.icon(
        onPressed: () => _gestionar(item),
        icon: const Icon(Icons.tune, size: 14, color: _red),
        label: const Text('Gestionar', style: TextStyle(color: _red, fontSize: 12)),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: () => _eliminar(item),
        icon: const Icon(Icons.delete_outline, size: 14, color: Colors.white24),
        label: const Text('Eliminar', style: TextStyle(color: Colors.white24, fontSize: 12)),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ),
    ]);
  }

  // ✅ FIX L544: complejidad reducida extrayendo sub-widgets
  Widget _buildCard(Personalizacion item, AuthProvider auth) {
    final color = _coloresEstado[item.estado] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: InkWell(
        onTap: () => _verDetalle(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCardFila1(item, color),
            const SizedBox(height: 10),
            _buildCardFila2(item),
            if (item.descripcionPersonalizacion != null) ...[
              const SizedBox(height: 8),
              Text(
                item.descripcionPersonalizacion!,
                style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ],
            if (auth.isSuperAdmin) ...[
              const SizedBox(height: 10),
              _buildCardAcciones(item),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildPaginacion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
          color: _surface, border: Border(top: BorderSide(color: _border))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSize,
              dropdownColor: _card, isDense: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.expand_more, color: _red, size: 16),
              items: _pageSizes.map((s) => DropdownMenuItem(value: s, child: Text('$s / pág'))).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() { _pageSize = v; _page = 0; });
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        _btnPag(Icons.chevron_left, _page > 0, () => setState(() => _page--)),
        Expanded(child: Center(child: Text(
          'Pág. ${_page + 1} / $_totalPages',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ))),
        _btnPag(Icons.chevron_right, _page < _totalPages - 1, () => setState(() => _page++)),
      ]),
    );
  }

  Widget _btnPag(IconData icon, bool enabled, VoidCallback onTap) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: enabled ? _card : _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: enabled ? _border : Colors.transparent),
          ),
          child: Icon(icon, color: enabled ? _red : Colors.white12, size: 18),
        ),
      );

  Widget _sheetLabel(String t) => Text(t,
      style: const TextStyle(
          color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2));

  Widget _infoBox(List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Column(children: children),
      );

  Widget _fila(IconData icon, String label, String valor, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, color: Colors.white24, size: 14),
          const SizedBox(width: 10),
          Text('$label ', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Expanded(child: Text(valor,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _filaMultilinea(IconData icon, String label, String valor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Colors.white24, size: 14),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 4),
            Text(valor, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
          ])),
        ]),
      );

  Widget _chip(String label, {IconData? icon, Color? iconColor}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, color: iconColor ?? Colors.white38, size: 8), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      );

  Widget _buildImagen(String? url, {double size = 80}) {
    if (url == null || url.isEmpty) return _placeholder(size, size);
    if (url.startsWith('http')) {
      return Image.network(url, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size, size));
    }
    return Image.asset(url, width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size, size));
  }

  Widget _buildImagenReferencia(String url) {
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes, width: double.infinity, height: 240, fit: BoxFit.cover);
      } catch (_) {
        return _placeholder(double.infinity, 240);
      }
    }
    if (url.startsWith('http')) {
      return Image.network(url, width: double.infinity, height: 240, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(double.infinity, 240));
    }
    return _placeholder(double.infinity, 240);
  }

  Widget _placeholder(double w, double h) => Container(
        width: w, height: h,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.image_not_supported, color: Colors.white12, size: 28),
      );

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}