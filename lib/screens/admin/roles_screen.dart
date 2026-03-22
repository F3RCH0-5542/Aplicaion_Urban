// lib/screens/admin/roles_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/rol_model.dart';
import '../../services/rol_service.dart';
import '../../providers/auth_provider.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  List<Rol> _roles = [];
  bool _isLoading = true;

  static const _cyan  = Color(0xFF45F3FF);
  static const _pink  = Color(0xFFFF2770);
  static const _green = Color(0xFF10B981);

  final Map<int, Color> _coloresRol = {
    1: _pink,
    2: _cyan,
    3: _green,
  };

  final Map<int, IconData> _iconosRol = {
    1: Icons.shield,
    2: Icons.person,
    3: Icons.admin_panel_settings,
  };

  @override
  void initState() {
    super.initState();
    _cargarRoles();
  }

  String _getToken() =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _cargarRoles() async {
    setState(() => _isLoading = true);
    final r = await RolService.getAll(_getToken());
    if (r['success']) {
      setState(() { _roles = r['data'] as List<Rol>; _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
      _mostrarError(r['message'] ?? 'Error al cargar roles');
    }
  }

  // ✅ FIX: sub-widgets para reducir complejidad de _mostrarFormularioEditar
  Widget _buildCampoNombre(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      validator: (v) => v!.isEmpty ? 'Requerido' : null,
      decoration: InputDecoration(
        labelText: 'Nombre del rol',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.badge, color: _cyan, size: 20),
        filled: true, fillColor: const Color(0xFF0a0a0a),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cyan, width: 2)),
      ),
    );
  }

  Widget _buildCampoDescripcion(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Descripción (opcional)',
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.description, color: _cyan, size: 20),
        filled: true, fillColor: const Color(0xFF0a0a0a),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2a2a2a))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cyan, width: 2)),
      ),
    );
  }

  // ✅ FIX L55: complejidad reducida extrayendo sub-widgets
  Future<void> _mostrarFormularioEditar(Rol rol) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isSuperAdmin) {
      _mostrarError('Solo el Super Admin puede editar roles.');
      return;
    }

    final nombreCtrl      = TextEditingController(text: rol.nombreRol);
    final descripcionCtrl = TextEditingController(text: rol.descripcion ?? '');
    final fk              = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.edit, color: _cyan, size: 20),
          SizedBox(width: 8),
          Text('Editar Rol', style: TextStyle(color: Colors.white)),
        ]),
        content: SizedBox(
          width: 400,
          child: Form(
            key: fk,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildCampoNombre(nombreCtrl),
              const SizedBox(height: 12),
              _buildCampoDescripcion(descripcionCtrl),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _cyan),
            onPressed: () async {
              if (!fk.currentState!.validate()) return;
              Navigator.pop(ctx);
              final r = await RolService.update(
                rol.idRol!,
                token: _getToken(),
                nombreRol: nombreCtrl.text.trim(),
                descripcion: descripcionCtrl.text.trim().isEmpty
                    ? null
                    : descripcionCtrl.text.trim(),
              );
              r['success']
                  ? _mostrarExito(r['message'] ?? 'Actualizado')
                  : _mostrarError(r['message'] ?? 'Error');
              if (r['success']) _cargarRoles();
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _pink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        title: const Text('Gestión de Roles',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _cyan),
            onPressed: _cargarRoles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _cyan))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildInfoBanner(auth),
                const SizedBox(height: 20),
                const Text('ROLES DEL SISTEMA',
                    style: TextStyle(
                        color: _cyan, fontSize: 14,
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Expanded(child: _buildLista(auth)),
              ]),
            ),
    );
  }

  Widget _buildInfoBanner(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: _cyan, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          auth.isSuperAdmin
              ? 'Como Super Admin puedes ver y editar los roles del sistema.'
              : 'Puedes ver los roles del sistema. Solo el Super Admin puede editarlos.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        )),
      ]),
    );
  }

  Widget _buildLista(AuthProvider auth) {
    if (_roles.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.theater_comedy, size: 80, color: Colors.grey[700]),
        const SizedBox(height: 16),
        const Text('No hay roles', style: TextStyle(color: Colors.grey, fontSize: 16)),
      ]));
    }
    return ListView.builder(
      itemCount: _roles.length,
      itemBuilder: (ctx, i) => _buildRolCard(_roles[i], auth),
    );
  }

  Widget _buildRolCard(Rol rol, AuthProvider auth) {
    final color = _coloresRol[rol.idRol] ?? const Color(0xFF667eea);
    final icono = _iconosRol[rol.idRol] ?? Icons.person;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1a1a1a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#${rol.idRol}',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(rol.nombreRol,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            if (rol.descripcion != null && rol.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(rol.descripcion!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ])),
          if (auth.isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.edit, color: _cyan),
              onPressed: () => _mostrarFormularioEditar(rol),
              tooltip: 'Editar rol',
            ),
        ]),
      ),
    );
  }
}