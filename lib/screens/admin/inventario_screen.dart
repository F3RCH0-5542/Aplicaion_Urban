// lib/screens/admin/inventario_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inventario_model.dart';
import '../../services/inventario_service.dart';
import '../../providers/auth_provider.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Movimiento> _movimientos = [];
  List<dynamic> _stockBajo = [];

  bool _isLoading = true;
  bool _isLoadingStockBajo = true;

  String _filtroTipo = 'todos';
  int _paginaActual = 0;
  int _porPagina = 15;
  static const _pageSizes = [10, 15, 20, 50];

  static const _cyan = Color(0xFF45F3FF);
  static const _pink = Color(0xFFFF2770);
  static const _bg   = Color(0xFF0D0D0D);
  static const _card = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _stockBajo.isEmpty) {
        _cargarStockBajo();
      }
    });
    _cargarMovimientos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);
    final r = await InventarioService.obtenerMovimientos(
      _getToken(),
      tipo: _filtroTipo == 'todos' ? null : _filtroTipo,
    );
    setState(() {
      _movimientos = r['success'] ? (r['data'] as List<Movimiento>) : [];
      _isLoading = false;
      _paginaActual = 0;
    });
    if (!r['success']) _mostrarError(r['message'] ?? 'Error al cargar');
  }

  Future<void> _cargarStockBajo() async {
    setState(() => _isLoadingStockBajo = true);
    final r = await InventarioService.obtenerStockBajo(_getToken());
    setState(() {
      _stockBajo = r['success'] ? (r['data'] as List) : [];
      _isLoadingStockBajo = false;
    });
  }

  List<Movimiento> get _paginados {
    final inicio = _paginaActual * _porPagina;
    final fin = (inicio + _porPagina).clamp(0, _movimientos.length);
    if (inicio >= _movimientos.length) return [];
    return _movimientos.sublist(inicio, fin);
  }

  int get _totalPaginas =>
      (_movimientos.length / _porPagina).ceil().clamp(1, 9999);

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: _pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  // ── Formulario con lista visual de gorras ─────────────────────────────
  void _abrirFormulario() async {
    final r = await InventarioService.obtenerProductosLista(_getToken());
    if (!r['success']) {
      _mostrarError(r['message'] ?? 'No se pudieron cargar los productos');
      return;
    }
    final productos = r['data'] as List<ProductoInventario>;
    if (!mounted) return;

    ProductoInventario? productoSel;
    String tipo = 'entrada';
    final cantidadCtrl = TextEditingController();
    final motivoCtrl   = TextEditingController();
    final searchCtrl   = TextEditingController();
    String searchQuery = '';
    final fk = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtrados = searchQuery.isEmpty
              ? productos
              : productos
                  .where((p) => p.nombreProducto
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _cyan, width: 1),
            ),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_box, color: _cyan, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Registrar Movimiento',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ]),
            content: SizedBox(
              width: 400,
              child: Form(
                key: fk,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Tipo ─────────────────────────────────────────
                      const Text('Tipo de movimiento',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _tipoBtn('entrada', tipo, Icons.arrow_downward_rounded,
                            const Color(0xFF10B981),
                            (v) => setS(() => tipo = v)),
                        const SizedBox(width: 8),
                        _tipoBtn('salida', tipo, Icons.arrow_upward_rounded,
                            _pink, (v) => setS(() => tipo = v)),
                        const SizedBox(width: 8),
                        _tipoBtn('ajuste', tipo, Icons.tune, _cyan,
                            (v) => setS(() => tipo = v)),
                      ]),

                      // Descripción del tipo seleccionado
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _colorTipo(tipo).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _colorTipo(tipo).withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          Icon(_iconoTipo(tipo),
                              color: _colorTipo(tipo), size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _descripcionTipo(tipo),
                              style: TextStyle(
                                  color: _colorTipo(tipo).withOpacity(0.9),
                                  fontSize: 12),
                            ),
                          ),
                        ]),
                      ),

                      // ── Gorra seleccionada ────────────────────────────
                      const Text('Seleccionar gorra',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      if (productoSel != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: _cyan.withOpacity(0.5)),
                          ),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child:
                                  _buildImagen(productoSel!.imagen, size: 44),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(productoSel!.nombreProducto,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text(
                                    'Stock actual: ${productoSel!.stockDisponible}',
                                    style: const TextStyle(
                                        color: _cyan, fontSize: 11)),
                              ]),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setS(() => productoSel = null),
                              child: const Icon(Icons.close,
                                  color: Colors.white38, size: 18),
                            ),
                          ]),
                        ),

                      if (productoSel == null) ...[
                        TextField(
                          controller: searchCtrl,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          onChanged: (v) => setS(() => searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Buscar gorra...',
                            hintStyle:
                                const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.white38, size: 18),
                            filled: true,
                            fillColor: Colors.black26,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2A2A2A))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2A2A2A))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: _cyan, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 190,
                          child: filtrados.isEmpty
                              ? const Center(
                                  child: Text('Sin resultados',
                                      style: TextStyle(
                                          color: Colors.white38)))
                              : ListView.builder(
                                  itemCount: filtrados.length,
                                  itemBuilder: (_, i) {
                                    final p = filtrados[i];
                                    return GestureDetector(
                                      onTap: () => setS(() {
                                        productoSel = p;
                                        searchCtrl.clear();
                                        searchQuery = '';
                                      }),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 6),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(
                                                  0xFF2A2A2A)),
                                        ),
                                        child: Row(children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: _buildImagen(p.imagen,
                                                size: 38),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(p.nombreProducto,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight
                                                            .w500),
                                                    overflow: TextOverflow
                                                        .ellipsis),
                                                Text(
                                                    'Stock: ${p.stockDisponible}',
                                                    style: TextStyle(
                                                        color: p.stockDisponible <=
                                                                5
                                                            ? Colors.orange
                                                            : Colors.white38,
                                                        fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right,
                                              color: Colors.white24,
                                              size: 16),
                                        ]),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // ── Cantidad ──────────────────────────────────────
                      const Text('Cantidad',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: cantidadCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (int.tryParse(v) == null ||
                              int.parse(v) <= 0)
                            return 'Ingresa un número válido';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: tipo == 'ajuste'
                              ? 'Nuevo stock total (reemplaza el actual)'
                              : 'Cantidad a ${tipo == "entrada" ? "agregar" : "restar"}',
                          hintStyle:
                              const TextStyle(color: Colors.white38),
                          prefixIcon: Icon(_iconoTipo(tipo),
                              color: _colorTipo(tipo), size: 18),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2A2A2A))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2A2A2A))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _colorTipo(tipo), width: 2)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Motivo ────────────────────────────────────────
                      const Text('Motivo (opcional)',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: motivoCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: _hintMotivo(tipo),
                          hintStyle:
                              const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.notes,
                              color: Colors.white38, size: 18),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2A2A2A))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2A2A2A))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _cyan, width: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorTipo(tipo),
                  foregroundColor: tipo == 'entrada'
                      ? Colors.white
                      : Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  if (productoSel == null) {
                    _mostrarError('Selecciona una gorra');
                    return;
                  }
                  if (!fk.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  final r = await InventarioService.registrarMovimiento(
                    token:      _getToken(),
                    idProducto: productoSel!.idProducto,
                    tipo:       tipo,
                    cantidad:   int.parse(cantidadCtrl.text.trim()),
                    motivo:     motivoCtrl.text.trim().isEmpty
                        ? null
                        : motivoCtrl.text.trim(),
                  );
                  if (r['success']) {
                    _mostrarExito(r['message'] ?? 'Movimiento registrado');
                    if (r['alerta'] == true) {
                      _mostrarError('⚠️ Stock bajo en este producto');
                    }
                    _cargarMovimientos();
                  } else {
                    _mostrarError(r['message'] ?? 'Error');
                  }
                },
                child: Text(
                  tipo == 'entrada'
                      ? 'Agregar stock'
                      : tipo == 'salida'
                          ? 'Registrar salida'
                          : 'Aplicar ajuste',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Inventario',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: _cyan),
              onPressed: _cargarMovimientos),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _cyan,
          indicatorWeight: 3,
          labelColor: _cyan,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.list_alt, size: 18),
                const SizedBox(width: 6),
                Text('Movimientos (${_movimientos.length})'),
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber,
                    size: 18,
                    color: _stockBajo.isNotEmpty ? Colors.orange : null),
                const SizedBox(width: 6),
                Text('Stock Bajo'
                    '${_stockBajo.isNotEmpty ? " (${_stockBajo.length})" : ""}'),
              ]),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabMovimientos(),
          _buildTabStockBajo(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: _cyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Movimiento',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabMovimientos() {
    return Column(children: [
      Container(
        color: _card,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                ['todos', 'entrada', 'salida', 'ajuste'].map((f) {
              final activo = _filtroTipo == f;
              final color = _colorTipo(f);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _filtroTipo = f);
                    _cargarMovimientos();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: activo
                          ? color.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: activo
                              ? color
                              : const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      if (f != 'todos') ...[
                        Icon(_iconoTipo(f),
                            color: activo ? color : Colors.white38,
                            size: 14),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        f == 'todos'
                            ? 'Todos'
                            : f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          color: activo ? color : Colors.white54,
                          fontWeight: activo
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      Expanded(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _cyan))
            : _movimientos.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(Icons.inbox_outlined,
                          size: 64, color: Colors.white12),
                      const SizedBox(height: 12),
                      const Text('No hay movimientos',
                          style: TextStyle(color: Colors.white38)),
                    ]))
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    itemCount: _paginados.length,
                    itemBuilder: (_, i) =>
                        _buildCardMovimiento(_paginados[i]),
                  ),
      ),
      if (!_isLoading && _movimientos.isNotEmpty) _buildPaginacion(),
    ]);
  }

  Widget _buildCardMovimiento(Movimiento m) {
    final color    = _colorTipo(m.tipo);
    final stockBajo = m.stockResultante <= m.stockMinimo;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  // Imagen de la gorra
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImagen(m.imagen, size: 56),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconoTipo(m.tipo),
                                    color: color, size: 10),
                                const SizedBox(width: 3),
                                Text(m.tipo.toUpperCase(),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            m.nombreProducto ??
                                'Producto #${m.idProducto}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        _miniChip('x${m.cantidad}', Colors.white54),
                        const SizedBox(width: 6),
                        _miniChip(
                          'Stock: ${m.stockResultante}',
                          stockBajo ? Colors.orange : Colors.white38,
                          icon: stockBajo
                              ? Icons.warning_amber
                              : null,
                        ),
                      ]),
                      if (m.motivo != null &&
                          m.motivo!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.notes,
                              color: Colors.white24, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(m.motivo!,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],
                      if (m.fechaMovimiento != null) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.access_time,
                              color: Colors.white24, size: 11),
                          const SizedBox(width: 4),
                          Text(_formatFecha(m.fechaMovimiento!),
                              style: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10)),
                        ]),
                      ],
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPaginacion() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _card,
        border:
            Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _porPagina,
              dropdownColor: _card,
              isDense: true,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12),
              icon: const Icon(Icons.expand_more,
                  color: _cyan, size: 16),
              items: _pageSizes
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text('$s / pág')))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _porPagina = val;
                  _paginaActual = 0;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _btnPag(Icons.chevron_left, _paginaActual > 0,
            () => setState(() => _paginaActual--)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPaginas, (i) {
                final sel = i == _paginaActual;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _paginaActual = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 3),
                    width: sel ? 32 : 28,
                    height: sel ? 32 : 28,
                    decoration: BoxDecoration(
                      color: sel
                          ? _cyan
                          : const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel
                              ? _cyan
                              : const Color(0xFF2A2A2A)),
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                            color: sel
                                ? Colors.black
                                : Colors.white54,
                            fontSize: sel ? 13 : 12,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        _btnPag(
            Icons.chevron_right,
            _paginaActual < _totalPaginas - 1,
            () => setState(() => _paginaActual++)),
      ]),
    );
  }

  Widget _btnPag(
          IconData icon, bool enabled, VoidCallback onTap) =>
      GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF0D0D0D)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: enabled
                    ? const Color(0xFF2A2A2A)
                    : Colors.transparent),
          ),
          child: Icon(icon,
              color: enabled ? _cyan : Colors.white12,
              size: 20),
        ),
      );

  Widget _buildTabStockBajo() {
    if (_isLoadingStockBajo) {
      return const Center(
          child: CircularProgressIndicator(color: _cyan));
    }
    if (_stockBajo.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 56, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 16),
          const Text('¡Todo el stock está bien!',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('No hay productos con stock bajo',
              style:
                  TextStyle(color: Colors.white38, fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stockBajo.length,
      itemBuilder: (ctx, i) {
        final item    = _stockBajo[i];
        final actual  = item['stock_actual'] ?? 0;
        final minimo  = item['stock_minimo'] ?? 5;
        final nombre  = item['nombre_producto'] ??
            'Producto #${item['id_producto']}';
        final imagen  = item['imagen'];
        final pct =
            minimo > 0 ? (actual / minimo).clamp(0.0, 1.0) : 0.0;
        final critico = pct < 0.3;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (critico ? _pink : Colors.orange)
                    .withOpacity(0.4)),
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImagen(imagen, size: 56),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                    child: Text(nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (critico ? _pink : Colors.orange)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$actual / $minimo',
                        style: TextStyle(
                            color: critico ? _pink : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 6),
                Stack(children: [
                  Container(
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius:
                              BorderRadius.circular(4))),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                            color:
                                critico ? _pink : Colors.orange,
                            borderRadius:
                                BorderRadius.circular(4))),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  critico ? '🔴 Stock crítico' : '🟠 Stock bajo',
                  style: TextStyle(
                      color: critico ? _pink : Colors.orange,
                      fontSize: 11),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  Widget _buildImagen(String? path, {double size = 56}) {
    if (path == null || path.isEmpty) return _placeholder(size);
    if (path.startsWith('http')) {
      return Image.network(path,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size));
    }
    return Image.asset(path,
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(size));
  }

  Widget _placeholder(double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.inventory_2,
            color: Colors.white24, size: 22),
      );

  Widget _miniChip(String label, Color color, {IconData? icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _tipoBtn(String value, String current, IconData icon,
      Color color, void Function(String) onTap) {
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                sel ? color.withOpacity(0.2) : Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel
                    ? color
                    : const Color(0xFF2A2A2A),
                width: sel ? 1.5 : 1),
          ),
          child: Column(children: [
            Icon(icon,
                color: sel ? color : Colors.white38, size: 20),
            const SizedBox(height: 4),
            Text(
              value[0].toUpperCase() + value.substring(1),
              style: TextStyle(
                  color: sel ? color : Colors.white38,
                  fontSize: 11,
                  fontWeight: sel
                      ? FontWeight.bold
                      : FontWeight.normal),
            ),
          ]),
        ),
      ),
    );
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'entrada': return const Color(0xFF10B981);
      case 'salida':  return _pink;
      case 'ajuste':  return _cyan;
      default:        return Colors.white54;
    }
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'entrada': return Icons.arrow_downward_rounded;
      case 'salida':  return Icons.arrow_upward_rounded;
      case 'ajuste':  return Icons.tune;
      default:        return Icons.swap_horiz;
    }
  }

  String _descripcionTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Llegaron gorras nuevas. El stock sube.';
      case 'salida':
        return 'Se retiran gorras (daño, pérdida, regalo). El stock baja.';
      case 'ajuste':
        return 'La cantidad que ingreses REEMPLAZA el stock actual (para corregir errores).';
      default:
        return '';
    }
  }

  String _hintMotivo(String tipo) {
    switch (tipo) {
      case 'entrada': return 'Ej: Compra proveedor marzo';
      case 'salida':  return 'Ej: Gorra dañada en bodega';
      case 'ajuste':  return 'Ej: Conteo físico marzo';
      default:        return '';
    }
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}  '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }
}