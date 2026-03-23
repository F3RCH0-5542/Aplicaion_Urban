// lib/screens/public/personalizaciones_publicas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'solicitar_personalizacion_screen.dart';

class PersonalizacionesPublicasScreen extends StatelessWidget {
  const PersonalizacionesPublicasScreen({super.key});

  static const _bg      = Color(0xFF000000);
  static const _surface = Color(0xFF0a0a0a);
  static const _card    = Color(0xFF1a1a1a);
  static const _border  = Color(0xFF2a2a2a);
  static const _accent  = Color(0xFF667eea);
  static const _danger  = Color(0xFFFF2770);

  // ✅ Ruta constante para evitar literales duplicados (SonarQube)
  static const String _routeLogin = '/login';

  static final _tipos = [
    {'tipo': 'bordado',   'titulo': 'Bordado',    'descripcion': 'Diseños en hilo de alta resistencia directamente sobre la gorra.', 'icono': Icons.gesture,      'color': const Color(0xFFEF4444)},
    {'tipo': 'estampado', 'titulo': 'Estampado',  'descripcion': 'Impresión digital de alta definición sobre tela.',                  'icono': Icons.print,        'color': const Color(0xFF3B82F6)},
    {'tipo': 'parche',    'titulo': 'Parche',      'descripcion': 'Apliques cosidos o termoadhesivos con tu diseño.',                  'icono': Icons.layers,       'color': const Color(0xFF8B5CF6)},
    {'tipo': 'tie-dye',   'titulo': 'Tie-Dye',    'descripcion': 'Técnica artesanal de teñido para un look único e irrepetible.',     'icono': Icons.palette,      'color': const Color(0xFF10B981)},
    {'tipo': 'otro',      'titulo': 'Otro',        'descripcion': 'Cuéntanos tu idea y la hacemos realidad.',                          'icono': Icons.auto_awesome, 'color': const Color(0xFFF59E0B)},
  ];

  static final _pasos = [
    {'numero': '01', 'titulo': 'Elige el tipo',    'desc': 'Selecciona bordado, estampado, parche, tie-dye u otro.'},
    {'numero': '02', 'titulo': 'Describe tu idea', 'desc': 'Detalla colores, talla e imagen de referencia.'},
    {'numero': '03', 'titulo': 'Revisamos',        'desc': 'Nuestro equipo evalúa y te envía precio en 24h.'},
    {'numero': '04', 'titulo': '¡Listo!',           'desc': 'Aprobado el diseño, producimos y enviamos tu gorra.'},
  ];

  @override
  Widget build(BuildContext context) {
    final auth     = Provider.of<AuthProvider>(context);
    final w        = MediaQuery.of(context).size.width;
    final isMobile = w < 800;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personalizaciones',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        actions: [
          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => _irASolicitar(context, auth),
                icon: const Icon(Icons.add_circle_outline, color: _danger, size: 18),
                label: const Text('Solicitar',
                    style: TextStyle(color: _danger, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHero(isMobile, auth, context),
          _buildTipos(isMobile),
          _buildPasos(isMobile),
          _buildCTA(context, auth, isMobile),
          const SizedBox(height: 40),
        ]),
      ),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => _irASolicitar(context, auth),
              backgroundColor: _danger,
              icon: const Icon(Icons.palette, color: Colors.white),
              label: const Text('Personalizar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHero(bool isMobile, AuthProvider auth, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 60, vertical: isMobile ? 48 : 72),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF0a0a0a), _danger.withOpacity(0.08), const Color(0xFF0a0a0a)],
        ),
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _danger.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _danger.withOpacity(0.4)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_awesome, color: _danger, size: 13),
            SizedBox(width: 6),
            Text('EDICIÓN EXCLUSIVA',
                style: TextStyle(color: _danger, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ]),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (b) =>
              const LinearGradient(colors: [Colors.white, Color(0xFFAAAAAA)]).createShader(b),
          child: Text('Tu gorra,\ntu identidad.',
              style: TextStyle(
                  fontSize: isMobile ? 36 : 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1)),
        ),
        const SizedBox(height: 16),
        Text(
          'Diseña una gorra única con bordado, estampado, parches o tie-dye.\nNosotros la hacemos realidad.',
          style: TextStyle(color: Colors.white54, fontSize: isMobile ? 14 : 16, height: 1.6),
        ),
        const SizedBox(height: 32),
        Wrap(spacing: 12, runSpacing: 12, children: [
          if (auth.isLoggedIn)
            ElevatedButton.icon(
              onPressed: () => _irASolicitar(context, auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.palette, color: Colors.white, size: 18),
              label: const Text('Hacer mi solicitud',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            )
          else
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, _routeLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: _danger,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login, color: Colors.white, size: 18),
              label: const Text('Iniciar sesión para solicitar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.expand_more, color: Colors.white54, size: 18),
            label: const Text('Ver tipos', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 32),
        Wrap(spacing: 24, runSpacing: 12, children: [
          _stat('5', 'Técnicas'),
          _stat('24h', 'Respuesta'),
          _stat('100%', 'Personalizado'),
        ]),
      ]),
    );
  }

  Widget _stat(String valor, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(valor, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ],
  );

  Widget _buildTipos(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 48),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('TÉCNICAS DISPONIBLES'),
        const SizedBox(height: 8),
        Text('Elige cómo quieres personalizar tu gorra',
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 3,
            crossAxisSpacing: 14, mainAxisSpacing: 14,
            childAspectRatio: isMobile ? 1.1 : 1.3,
          ),
          itemCount: _tipos.length,
          itemBuilder: (_, i) {
            final t     = _tipos[i];
            final color = t['color'] as Color;
            final icono = t['icono'] as IconData;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icono, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(t['titulo'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Expanded(child: Text(t['descripcion'] as String,
                    style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildPasos(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 48),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border.symmetric(horizontal: BorderSide(color: _border)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('PROCESO'),
        const SizedBox(height: 8),
        Text('¿Cómo funciona?',
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 28),
        isMobile
            ? Column(children: _pasos.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _pasoCard(p))).toList())
            : Row(children: _pasos.map((p) => Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _pasoCard(p)))).toList()),
      ]),
    );
  }

  Widget _pasoCard(Map<String, String> p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p['numero']!,
            style: TextStyle(color: _danger.withOpacity(0.5), fontSize: 28,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(p['titulo']!,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text(p['desc']!,
            style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _buildCTA(BuildContext context, AuthProvider auth, bool isMobile) {
    return Container(
      margin:  EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 48),
      padding: EdgeInsets.all(isMobile ? 28 : 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_danger.withOpacity(0.15), _accent.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _danger.withOpacity(0.3)),
      ),
      child: Column(children: [
        const Icon(Icons.palette, color: _danger, size: 36),
        const SizedBox(height: 16),
        Text(
          auth.isLoggedIn
              ? '¿Listo para crear tu gorra única?'
              : 'Inicia sesión para personalizar tu gorra',
          style: TextStyle(
              color: Colors.white, fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          auth.isLoggedIn
              ? 'Envía tu solicitud ahora. Nuestro equipo la revisará en menos de 24 horas.'
              : 'Crea una cuenta o inicia sesión para solicitar tu personalización exclusiva.',
          style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => auth.isLoggedIn
              ? _irASolicitar(context, auth)
              : Navigator.pushNamed(context, _routeLogin),
          style: ElevatedButton.styleFrom(
            backgroundColor: _danger,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(auth.isLoggedIn ? Icons.send : Icons.login, color: Colors.white, size: 18),
          label: Text(auth.isLoggedIn ? 'Enviar solicitud' : 'Iniciar sesión',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String texto) => Text(texto,
      style: const TextStyle(
          color: _danger, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5));

  void _irASolicitar(BuildContext context, AuthProvider auth) {
    if (!auth.isLoggedIn) {
      Navigator.pushNamed(context, _routeLogin);
      return;
    }
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SolicitarPersonalizacionScreen()));
  }
}