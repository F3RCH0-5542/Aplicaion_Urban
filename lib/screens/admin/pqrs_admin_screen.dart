// lib/screens/admin/pqrs_admin_screen.dart
import 'package:flutter/material.dart';
import '../../models/pqrs_model.dart';
import '../../services/pqrs_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PqrsAdminScreen extends StatefulWidget {
  const PqrsAdminScreen({super.key});

  @override
  State<PqrsAdminScreen> createState() => _PqrsAdminScreenState();
}

class _PqrsAdminScreenState extends State<PqrsAdminScreen> {
  List<Pqrs> _pqrsList = [];
  List<Pqrs> _filtrados = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';

  static const _cyan   = Color(0xFF45F3FF);
  static const _pink   = Color(0xFFFF2770);
  static const _bg     = Color(0xFF0D0D0D);
  static const _card   = Color(0xFF1A1A1A);
  static const _border = Color(0xFF2A2A2A);
  static const _estadoEnProceso = 'En Proceso';

  @override
  void initState() {
    super.initState();
    _cargarPqrs();
  }

  Future<void> _cargarPqrs() async {
    setState(() => _cargando = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';
    final data = await PqrsService.obtenerPqrs(token);
    final lista = data.map((e) => Pqrs.fromJson(e)).toList();
    setState(() {
      _pqrsList = lista;
      _aplicarFiltro(_filtroEstado);
      _cargando = false;
    });
  }

  void _aplicarFiltro(String estado) {
    setState(() {
      _filtroEstado = estado;
      _filtrados = estado == 'todos'
          ? List.from(_pqrsList)
          : _pqrsList.where((p) => p.estado.toLowerCase() == estado.toLowerCase()).toList();
    });
  }

  Widget _buildInfoSolicitante(Pqrs pqrs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('👤 ${pqrs.nombre}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text('✉️ ${pqrs.correo}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 6),
        Text(pqrs.descripcion,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSelectorEstado(String estadoSel, void Function(String) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Estado:', style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: estadoSel,
        dropdownColor: _card,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black26,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
        ),
        items: [_estadoEnProceso, 'Resuelto', 'Cerrado']
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
      ),
    ]);
  }

  Widget _buildCampoRespuesta(TextEditingController controller) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Respuesta:', style: TextStyle(color: Colors.white54, fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black26,
          hintText: 'Escribe tu respuesta aquí...',
          hintStyle: const TextStyle(color: Colors.white38),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _cyan),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
        ),
      ),
    ]);
  }

  void _abrirDialogoResponder(Pqrs pqrs) {
    final controller = TextEditingController(text: pqrs.respuesta ?? '');
    String estadoSeleccionado = 'Resuelto';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _cyan, width: 1),
          ),
          title: Text(
            'Responder PQRS #${pqrs.idPqrs}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildInfoSolicitante(pqrs),
              const SizedBox(height: 16),
              _buildSelectorEstado(estadoSeleccionado,
                  (v) => setStateDialog(() => estadoSeleccionado = v)),
              const SizedBox(height: 16),
              _buildCampoRespuesta(controller),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await _enviarRespuesta(
                  pqrs: pqrs,
                  respuesta: controller.text.trim(),
                  estado: estadoSeleccionado,
                );
              },
              child: const Text('Enviar respuesta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarRespuesta({
    required Pqrs pqrs,
    required String respuesta,
    required String estado,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';
    final result = await PqrsService.responderPqrs(
      idPqrs: pqrs.idPqrs!,
      respuesta: respuesta,
      token: token,
      estado: estado,
    );
    if (!mounted) return;
    if (result['success'] == true) {
      _mostrarSnack('✅ PQRS respondida correctamente', _cyan);
      _cargarPqrs();
    } else {
      _mostrarSnack('❌ ${result['message']}', _pink);
    }
  }

  void _confirmarEliminar(Pqrs pqrs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _pink),
        ),
        title: const Text('Eliminar PQRS', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar el PQRS #${pqrs.idPqrs} de ${pqrs.nombre}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _eliminarPqrs(pqrs);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPqrs(Pqrs pqrs) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';
    try {
      final response = await PqrsService.eliminarPqrs(idPqrs: pqrs.idPqrs!, token: token);
      if (!mounted) return;
      if (response['success'] == true) {
        _mostrarSnack('🗑️ PQRS eliminada', _cyan);
        _cargarPqrs();
      } else {
        _mostrarSnack('❌ ${response['message']}', _pink);
      }
    } catch (e) {
      _mostrarSnack('❌ Error al eliminar', _pink);
    }
  }

  void _mostrarSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.black)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        title: const Text('Gestión de PQRS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _cyan), onPressed: _cargarPqrs),
        ],
      ),
      body: Column(children: [
        _buildFiltros(),
        _buildContador(),
        Expanded(child: _buildCuerpo()),
      ]),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: _cyan));
    if (_filtrados.isEmpty) return _buildVacio();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filtrados.length,
      itemBuilder: (_, i) => _buildCard(_filtrados[i]),
    );
  }

  Widget _buildFiltros() {
    final filtros = ['todos', 'Pendiente', _estadoEnProceso, 'Resuelto', 'Cerrado'];
    return Container(
      color: _card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filtros.map((f) => _buildChipFiltro(f)).toList(),
        ),
      ),
    );
  }

  Widget _buildChipFiltro(String f) {
    final activo = _filtroEstado == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _aplicarFiltro(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: activo ? _cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activo ? _cyan : _border),
          ),
          child: Text(
            f == 'todos' ? 'Todos' : f,
            style: TextStyle(
              color: activo ? Colors.black : Colors.white54,
              fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContador() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _bg,
      child: Row(children: [
        Text('${_filtrados.length} PQRS',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const Spacer(),
        _miniStat('Pendiente', _pink),
        const SizedBox(width: 12),
        _miniStat(_estadoEnProceso, Colors.orange),
        const SizedBox(width: 12),
        _miniStat('Resuelto', _cyan),
      ]),
    );
  }

  Widget _miniStat(String estado, Color color) {
    final count = _pqrsList
        .where((p) => p.estado.toLowerCase() == estado.toLowerCase())
        .length;
    return Row(children: [
      Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  Widget _buildCardCabecera(Pqrs pqrs, Color estadoColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
      child: Row(children: [
        _chipTipo(pqrs.tipoDisplay),
        const SizedBox(width: 8),
        _chipEstado(pqrs.estadoDisplay, estadoColor),
        const Spacer(),
        Text('#${pqrs.idPqrs}',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }

  Widget _buildCardRespuesta(Pqrs pqrs) {
    if (pqrs.respuesta == null || pqrs.respuesta!.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _cyan.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cyan.withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.reply, color: _cyan, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(pqrs.respuesta!,
              style: const TextStyle(color: Colors.white60, fontSize: 12))),
        ]),
      ),
    ]);
  }

  Widget _buildCardAcciones(Pqrs pqrs) {
    final tieneRespuesta = pqrs.respuesta != null && pqrs.respuesta!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton.icon(
          onPressed: () => _confirmarEliminar(pqrs),
          icon: const Icon(Icons.delete_outline, size: 16, color: _pink),
          label: const Text('Eliminar', style: TextStyle(color: _pink, fontSize: 13)),
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _abrirDialogoResponder(pqrs),
          icon: const Icon(Icons.reply, size: 16),
          label: Text(
            tieneRespuesta ? 'Editar respuesta' : 'Responder',
            style: const TextStyle(fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ]),
    );
  }

  Widget _buildCard(Pqrs pqrs) {
    final estadoColor = _colorEstado(pqrs.estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildCardCabecera(pqrs, estadoColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.person_outline, color: Colors.white38, size: 16),
              const SizedBox(width: 6),
              Text(pqrs.nombre,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(pqrs.correo,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            Text(pqrs.descripcion,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            _buildCardRespuesta(pqrs),
            if (pqrs.fechaCreacion != null) ...[
              const SizedBox(height: 8),
              Text(_formatFecha(pqrs.fechaCreacion!),
                  style: const TextStyle(color: Colors.white24, fontSize: 11)),
            ],
          ]),
        ),
        _buildCardAcciones(pqrs),
      ]),
    );
  }

  Widget _chipTipo(String tipo) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
    child: Text(tipo, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  );

  Widget _chipEstado(String estado, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(estado,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':   return _pink;
      case 'en proceso':
      case 'en_proceso':  return Colors.orange;
      case 'resuelto':    return _cyan;
      case 'cerrado':     return Colors.white38;
      default:            return Colors.white38;
    }
  }

  Widget _buildVacio() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.inbox_outlined, size: 64, color: Colors.white12),
      const SizedBox(height: 12),
      Text(
        _filtroEstado == 'todos'
            ? 'No hay PQRS'
            : 'No hay PQRS con estado "$_filtroEstado"',
        style: const TextStyle(color: Colors.white38),
      ),
    ]),
  );

  String _formatFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}  '
      '${fecha.hour.toString().padLeft(2, '0')}:'
      '${fecha.minute.toString().padLeft(2, '0')}';
}