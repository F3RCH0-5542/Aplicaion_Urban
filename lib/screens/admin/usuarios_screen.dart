// lib/screens/admin/usuarios_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario_model.dart';
import '../../services/usuario_service.dart';
import '../../providers/auth_provider.dart';

// ── Data class para agrupar controladores del formulario ──────────────────
class _UsuarioControllers {
  final TextEditingController nombre    = TextEditingController();
  final TextEditingController apellido  = TextEditingController();
  final TextEditingController correo    = TextEditingController();
  final TextEditingController documento = TextEditingController();
  final TextEditingController? clave;

  _UsuarioControllers({bool conClave = false})
      : clave = conClave ? TextEditingController() : null;

  _UsuarioControllers.fromUsuario(Usuario u) : clave = null {
    nombre.text    = u.nombre;
    apellido.text  = u.apellido;
    correo.text    = u.email;
    documento.text = u.documento ?? '';
  }

  void dispose() {
    nombre.dispose(); apellido.dispose();
    correo.dispose(); documento.dispose();
    clave?.dispose();
  }
}

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _todos = [];
  List<Usuario> _filtrados = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _paginaActual = 0;
  int _usuariosPorPagina = 10;
  final TextEditingController _searchCtrl = TextEditingController();
  final List<int> _opcionesPagina = [5, 10, 20, 50];

  static const _cyan   = Color(0xFF45F3FF);
  static const _pink   = Color(0xFFFF2770);
  static const _green  = Color(0xFF10B981);
  static const _purple = Color(0xFF667eea);
  static const _amber  = Color(0xFFf59e0b);

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    final r = await UsuarioService.getAll(_getToken());
    if (r['success']) {
      final lista = r['data'] as List<Usuario>;
      setState(() {
        _todos = lista;
        _filtrados = lista;
        _isLoading = false;
        _paginaActual = 0;
      });
    } else {
      setState(() => _isLoading = false);
      _mostrarError(r['message'] ?? 'Error al cargar');
    }
  }

  void _buscar(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      _paginaActual = 0;
      if (_searchQuery.isEmpty) { _filtrados = _todos; return; }
      if (int.tryParse(_searchQuery) != null) {
        final id = int.parse(_searchQuery);
        _filtrados = _todos.where((u) => u.idUsuario == id).toList();
        return;
      }
      _filtrados = _todos.where((u) =>
        u.nombre.toLowerCase().contains(_searchQuery) ||
        u.apellido.toLowerCase().contains(_searchQuery) ||
        u.email.toLowerCase().contains(_searchQuery) ||
        (u.documento ?? '').contains(_searchQuery)
      ).toList();
    });
  }

  List<Usuario> get _paginados {
    final inicio = _paginaActual * _usuariosPorPagina;
    final fin = (inicio + _usuariosPorPagina).clamp(0, _filtrados.length);
    if (inicio >= _filtrados.length) return [];
    return _filtrados.sublist(inicio, fin);
  }

  int get _totalPaginas =>
      (_filtrados.length / _usuariosPorPagina).ceil().clamp(1, 9999);

  Future<void> _toggleEstado(Usuario u) async {
    if (u.idUsuario == null) return;
    final nuevo = !(u.activo ?? true);
    final r = await UsuarioService.toggleEstado(u.idUsuario!, nuevo, token: _getToken());
    if (r['success']) {
      _mostrarExito(nuevo ? 'Usuario activado' : 'Usuario desactivado');
      _cargarUsuarios();
    } else {
      _mostrarError(r['message'] ?? 'Error');
    }
  }

  Future<void> _eliminarUsuario(Usuario u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar eliminación', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar a ${u.nombre} ${u.apellido}?\nEsta acción no se puede deshacer.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: _pink),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || u.idUsuario == null) return;
    final r = await UsuarioService.delete(u.idUsuario!, token: _getToken());
    if (r['success']) {
      _mostrarExito(r['message'] ?? 'Eliminado');
      _cargarUsuarios();
    } else {
      final msg = r['message'] ?? '';
      final tieneRelaciones = msg.contains('foreign') ||
          msg.contains('ibfk') || msg.contains('500') || msg.contains('Error');
      if (tieneRelaciones) {
        _mostrarDialogoDesactivar(u);
      } else {
        _mostrarError(msg);
      }
    }
  }

  Future<void> _mostrarDialogoDesactivar(Usuario u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber, color: _amber),
          SizedBox(width: 8),
          Text('No se puede eliminar', style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text(
            '${u.nombre} ${u.apellido} tiene registros asociados y no puede eliminarse.\n\n¿Deseas desactivarlo en su lugar?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: _amber),
              child: const Text('Desactivar', style: TextStyle(color: Colors.black))),
        ],
      ),
    );
    if (ok == true) {
      final r = await UsuarioService.toggleEstado(u.idUsuario!, false, token: _getToken());
      r['success'] ? _mostrarExito('Usuario desactivado') : _mostrarError(r['message'] ?? 'Error');
      _cargarUsuarios();
    }
  }

  // ── Formulario helpers ────────────────────────────────────────────────────

  Widget _buildCamposFormulario(
    _UsuarioControllers ctrls,
    int rol,
    bool esAdminLimitado,
    void Function(int?) onRolChanged,
  ) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _field(ctrls.nombre, 'Nombre', Icons.person,
          validator: (v) => v!.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 10),
      _field(ctrls.apellido, 'Apellido', Icons.person_outline,
          validator: (v) => v!.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 10),
      _field(ctrls.correo, 'Correo', Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => v!.isEmpty ? 'Requerido' : null),
      const SizedBox(height: 10),
      if (ctrls.clave != null) ...[
        _field(ctrls.clave!, 'Contraseña', Icons.lock,
            obscure: true,
            validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null),
        const SizedBox(height: 10),
      ],
      _field(ctrls.documento, 'Documento (opcional)', Icons.badge),
      const SizedBox(height: 10),
      _rolDropdown(rol, onRolChanged, soloCliente: esAdminLimitado),
    ]);
  }

  Widget _buildAccionesDialog(BuildContext ctx, String labelGuardar, VoidCallback onGuardar) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: _cyan),
        onPressed: onGuardar,
        child: Text(labelGuardar, style: const TextStyle(color: Colors.black)),
      ),
    ]);
  }

  // ── Lógica de guardado extraída para bajar complejidad ───────────────────

  Future<void> _guardarCrear(
    GlobalKey<FormState> fk,
    _UsuarioControllers ctrls,
    int rol,
    BuildContext ctx,
  ) async {
    if (!fk.currentState!.validate()) return;
    Navigator.pop(ctx);
    final documento = ctrls.documento.text.trim().isEmpty
        ? null
        : ctrls.documento.text.trim();
    final r = await UsuarioService.create(
      token:     _getToken(),
      nombre:    ctrls.nombre.text.trim(),
      apellido:  ctrls.apellido.text.trim(),
      correo:    ctrls.correo.text.trim(),
      clave:     ctrls.clave!.text.trim(),
      documento: documento,
      idRol:     rol,
    );
    r['success']
        ? _mostrarExito(r['message'] ?? 'Creado')
        : _mostrarError(r['message'] ?? 'Error');
    if (r['success']) _cargarUsuarios();
  }

  Future<void> _guardarEditar(
    GlobalKey<FormState> fk,
    _UsuarioControllers ctrls,
    int rol,
    Usuario u,
    BuildContext ctx,
  ) async {
    if (!fk.currentState!.validate()) return;
    Navigator.pop(ctx);
    final documento = ctrls.documento.text.trim().isEmpty
        ? null
        : ctrls.documento.text.trim();
    final r = await UsuarioService.update(
      u.idUsuario!,
      token:     _getToken(),
      nombre:    ctrls.nombre.text.trim(),
      apellido:  ctrls.apellido.text.trim(),
      correo:    ctrls.correo.text.trim(),
      documento: documento,
      idRol:     rol,
    );
    r['success']
        ? _mostrarExito(r['message'] ?? 'Actualizado')
        : _mostrarError(r['message'] ?? 'Error');
    if (r['success']) _cargarUsuarios();
  }

  // ── Formularios ───────────────────────────────────────────────────────────

  Future<void> _mostrarFormularioCrear() async {
    final ctrls = _UsuarioControllers(conClave: true);
    final auth  = Provider.of<AuthProvider>(context, listen: false);
    final esAdminLimitado = auth.isAdminLimitado;
    int rol = 2;
    final fk = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nuevo Usuario', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: fk,
              child: SingleChildScrollView(
                child: _buildCamposFormulario(
                  ctrls, rol, esAdminLimitado,
                  (v) => setS(() => rol = v!),
                ),
              ),
            ),
          ),
          actions: [
            _buildAccionesDialog(ctx, 'Crear',
                () => _guardarCrear(fk, ctrls, rol, ctx)),
          ],
        ),
      ),
    );
    ctrls.dispose();
  }

  Future<void> _mostrarFormularioEditar(Usuario u) async {
    final ctrls = _UsuarioControllers.fromUsuario(u);
    final auth  = Provider.of<AuthProvider>(context, listen: false);
    final esAdminLimitado = auth.isAdminLimitado;
    int rol = u.idRol;
    final fk = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Usuario', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: fk,
              child: SingleChildScrollView(
                child: _buildCamposFormulario(
                  ctrls, rol, esAdminLimitado,
                  (v) => setS(() => rol = v!),
                ),
              ),
            ),
          ),
          actions: [
            _buildAccionesDialog(ctx, 'Guardar',
                () => _guardarEditar(fk, ctrls, rol, u, ctx)),
          ],
        ),
      ),
    );
    ctrls.dispose();
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, bool obscure = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboardType, obscureText: obscure,
      validator: validator, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: _cyan, size: 20),
        filled: true, fillColor: const Color(0xFF0a0a0a),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cyan, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _pink)),
      ),
    );
  }

  Widget _rolDropdown(int value, void Function(int?) onChanged, {bool soloCliente = false}) {
    final valorSeguro = (value == 1 || value == 2 || value == 3) ? value : 2;
    final valorFinal  = soloCliente ? 2 : valorSeguro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0a0a0a),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2a2a2a)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: valorFinal,
          isExpanded: true,
          dropdownColor: const Color(0xFF1a1a1a),
          style: const TextStyle(color: Colors.white),
          onChanged: soloCliente ? null : onChanged,
          items: soloCliente
              ? const [DropdownMenuItem(value: 2, child: Text('Usuario (Cliente)'))]
              : const [
                  DropdownMenuItem(value: 1, child: Text('Super Admin')),
                  DropdownMenuItem(value: 2, child: Text('Usuario')),
                  DropdownMenuItem(value: 3, child: Text('Admin')),
                ],
        ),
      ),
    );
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
        backgroundColor: _pink, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
        backgroundColor: _green, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  // ── Scaffold ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('Gestión de Usuarios',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _cyan), onPressed: _cargarUsuarios),
        ],
      ),
      body: Column(children: [
        _buildBuscador(),
        if (!_isLoading) _buildContador(),
        Expanded(child: _buildCuerpo()),
        if (!_isLoading && _filtrados.isNotEmpty) _buildPaginacion(),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioCrear,
        backgroundColor: _cyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nuevo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por ID, nombre, apellido, correo o documento...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _cyan),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () { _searchCtrl.clear(); _buscar(''); })
              : null,
          filled: true, fillColor: const Color(0xFF1a1a1a),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: _buscar,
      ),
    );
  }

  Widget _buildContador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Text('${_filtrados.length} usuario${_filtrados.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        const Text('Mostrar: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2a2a2a)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _usuariosPorPagina,
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              isDense: true,
              items: _opcionesPagina.map((n) =>
                  DropdownMenuItem(value: n, child: Text('$n'))).toList(),
              onChanged: (v) => setState(() { _usuariosPorPagina = v!; _paginaActual = 0; }),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCuerpo() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _cyan));
    if (_filtrados.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline, size: 80, color: Colors.grey[700]),
        const SizedBox(height: 16),
        Text(_searchQuery.isEmpty ? 'No hay usuarios' : 'Sin resultados para "$_searchQuery"',
            style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _cargarUsuarios,
      color: _cyan,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _paginados.length,
        itemBuilder: (ctx, i) => _buildCard(_paginados[i]),
      ),
    );
  }

  Widget _buildPaginacion() {
    return Container(
      color: const Color(0xFF0a0a0a),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          icon: const Icon(Icons.first_page, color: _cyan),
          onPressed: _paginaActual > 0 ? () => setState(() => _paginaActual = 0) : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _cyan),
          onPressed: _paginaActual > 0 ? () => setState(() => _paginaActual--) : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _cyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cyan.withOpacity(0.4)),
          ),
          child: Text('Página ${_paginaActual + 1} de $_totalPaginas',
              style: const TextStyle(color: _cyan, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: _cyan),
          onPressed: _paginaActual < _totalPaginas - 1 ? () => setState(() => _paginaActual++) : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page, color: _cyan),
          onPressed: _paginaActual < _totalPaginas - 1
              ? () => setState(() => _paginaActual = _totalPaginas - 1) : null,
        ),
      ]),
    );
  }

  Widget _buildCard(Usuario u) {
    final activo = u.activo ?? true;
    final auth   = Provider.of<AuthProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF1a1a1a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _cyan.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          _buildAvatar(u, activo),
          const SizedBox(width: 12),
          Expanded(child: _buildCardInfo(u, activo)),
          _buildCardMenu(u, activo, auth),
        ]),
      ),
    );
  }

  Widget _buildAvatar(Usuario u, bool activo) {
    return CircleAvatar(
      backgroundColor: activo ? _cyan : Colors.grey[700],
      radius: 22,
      child: Text(
        '${u.nombre.isNotEmpty ? u.nombre[0] : "?"}${u.apellido.isNotEmpty ? u.apellido[0] : "?"}'.toUpperCase(),
        style: TextStyle(color: activo ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildCardInfo(Usuario u, bool activo) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _purple.withOpacity(0.4)),
          ),
          child: Text('#${u.idUsuario}',
              style: const TextStyle(color: _purple, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text('${u.nombre} ${u.apellido}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 3),
      Row(children: [
        const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(u.email,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis)),
      ]),
      if (u.documento != null && u.documento!.isNotEmpty) ...[
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.badge_outlined, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(u.documento!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ],
      const SizedBox(height: 4),
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _pink.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(u.nombreRol ?? (u.idRol == 1 ? 'Admin' : 'Usuario'),
              style: const TextStyle(color: _pink, fontSize: 11)),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: activo ? _green.withOpacity(0.2) : _pink.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                  color: activo ? _green : _pink,
                  fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    ]);
  }

  Widget _buildCardMenu(Usuario u, bool activo, AuthProvider auth) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF2a2a2a),
      onSelected: (v) {
        if (v == 'editar')   _mostrarFormularioEditar(u);
        if (v == 'toggle')   _toggleEstado(u);
        if (v == 'eliminar') _eliminarUsuario(u);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'editar',
            child: Row(children: [Icon(Icons.edit, color: _cyan), SizedBox(width: 8),
                Text('Editar', style: TextStyle(color: Colors.white))])),
        PopupMenuItem(value: 'toggle',
            child: Row(children: [
              Icon(activo ? Icons.block : Icons.check_circle, color: _pink),
              const SizedBox(width: 8),
              Text(activo ? 'Desactivar' : 'Activar', style: const TextStyle(color: Colors.white)),
            ])),
        if (auth.isSuperAdmin)
          const PopupMenuItem(value: 'eliminar',
              child: Row(children: [Icon(Icons.delete, color: _pink), SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.white))])),
      ],
    );
  }
}