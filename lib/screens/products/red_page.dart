import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class RedPage extends StatefulWidget {
  const RedPage({super.key});

  @override
  State<RedPage> createState() => _RedPageState();
}

class _RedPageState extends State<RedPage> {
  // ✅ Constantes para evitar literales duplicados (SonarQube)
  static const String _teamName          = 'Boston Red Sox';
  static const String _descLogoBordado   = 'Gorra con logotipo bordado y diseño premium.';
  static const String _descModeloClasico = 'Modelo clásico con detalles bordados oficiales.';

  static const String _routeHome           = '/';
  static const String _routeChicago        = '/chicago';
  static const String _routeBoston         = '/boston';
  static const String _routeLakers         = '/lakers';
  static const String _routeFalcon         = '/falcon';
  static const String _routeArizona        = '/arizona';
  static const String _routeVegas          = '/vegas';
  static const String _routeRed            = '/red';
  static const String _routeWhite          = '/white';
  static const String _routeAtlanta        = '/atlanta';
  static const String _routePersonalizadas = '/personalizadas';
  static const String _routePqrs           = '/pqrs';
  static const String _routeAdmin          = '/admin';
  static const String _routeCart           = '/cart';
  static const String _routeLogin          = '/login';

  static const String _teamChicagoBulls     = 'Chicago Bulls';
  static const String _teamBostonCeltics    = 'Boston Celtics';
  static const String _teamLosAngelesLakers = 'Los Angeles Lakers';
  static const String _teamAtlantaFalcons   = 'Atlanta Falcons';
  static const String _teamArizonaCardinals = 'Arizona Cardinals';
  static const String _teamLasVegasRaiders  = 'Las Vegas Raiders';
  static const String _teamChicagoWhiteSox  = 'Chicago White Sox';
  static const String _teamAtlantaBraves    = 'Atlanta Braves';

  final List<Map<String, dynamic>> productos = [
    {'id': 56, 'nombre': '$_teamName - Orgullo de Fenway',        'precio': 95000, 'imagen': 'assets/img/Red/1-removebg-preview.png',       'desc': 'Gorra New Era 59FIFTY de la colección MLB Classic.'},
    {'id': 57, 'nombre': '$_teamName - Leyenda Americana',        'precio': 92000, 'imagen': 'assets/img/Red/2-removebg-preview.png',       'desc': _descLogoBordado},
    {'id': 58, 'nombre': '$_teamName - Espíritu de Campeones',    'precio': 98000, 'imagen': 'assets/img/Red/3-removebg-preview.png',       'desc': _descModeloClasico},
    {'id': 59, 'nombre': '$_teamName - Tradición Inquebrantable', 'precio': 95000, 'imagen': 'assets/img/Red/4-removebg-preview.png',       'desc': 'Gorra New Era con diseño icónico.'},
    {'id': 60, 'nombre': '$_teamName - Estilo Beisbolero',        'precio': 92000, 'imagen': 'assets/img/Red/5-removebg-preview.png',       'desc': _descLogoBordado},
    {'id': 61, 'nombre': '$_teamName - Pasión Roja',              'precio': 98000, 'imagen': 'assets/img/Red/6-removebg-preview.png',       'desc': _descModeloClasico},
    {'id': 62, 'nombre': '$_teamName - Poder y Gloria',           'precio': 95000, 'imagen': 'assets/img/Red/7-removebg-preview (1).png',  'desc': 'Gorra New Era de la colección MLB Classic.'},
    {'id': 63, 'nombre': '$_teamName - Clásico de Boston',        'precio': 92000, 'imagen': 'assets/img/Red/8-removebg-preview.png',       'desc': _descLogoBordado},
    {'id': 64, 'nombre': '$_teamName - Herencia Deportiva',       'precio': 98000, 'imagen': 'assets/img/Red/9-removebg-preview.png',       'desc': _descModeloClasico},
  ];

  void _addToCart(int idProducto, String name, int price, String image) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(idProducto: idProducto, nombre: name, precio: price, imagen: image);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $name agregado al carrito'),
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF10b981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 60 : 70),
        child: _buildAppBar(isMobile),
      ),
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHeroImage(),
          const SizedBox(height: 40),
          _buildProductSection(isMobile),
          const SizedBox(height: 40),
          _buildFooter(isMobile),
        ]),
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: const Color(0xFF0a0a0a),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.5),
      leading: isMobile
          ? Builder(builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer()))
          : null,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
          child: isMobile ? _buildMobileAppBar() : _buildDesktopAppBar(),
        ),
      ),
    );
  }

  Widget _buildDesktopAppBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Row(children: [
      _buildLogo(40),
      const SizedBox(width: 16),
      _buildNavMenu('NBA', [
        _buildNavMenuItem(_teamChicagoBulls,     _routeChicago),
        _buildNavMenuItem(_teamBostonCeltics,    _routeBoston),
        _buildNavMenuItem(_teamLosAngelesLakers, _routeLakers),
      ]),
      const SizedBox(width: 8),
      _buildNavMenu('NFL', [
        _buildNavMenuItem(_teamAtlantaFalcons,   _routeFalcon),
        _buildNavMenuItem(_teamArizonaCardinals, _routeArizona),
        _buildNavMenuItem(_teamLasVegasRaiders,  _routeVegas),
      ]),
      const SizedBox(width: 8),
      _buildNavMenu('MLB', [
        _buildNavMenuItem(_teamName,            _routeRed),
        _buildNavMenuItem(_teamChicagoWhiteSox, _routeWhite),
        _buildNavMenuItem(_teamAtlantaBraves,   _routeAtlanta),
      ]),
      const SizedBox(width: 8),
      _buildNavButton('Personalizadas', () => Navigator.pushNamed(context, _routePersonalizadas)),
      const SizedBox(width: 8),
      _buildNavButton('PQRS', () => Navigator.pushNamed(context, _routePqrs)),
      const Spacer(),
      _buildSearchBar(),
      const SizedBox(width: 12),
      if (authProvider.isLoggedIn) ...[
        if (authProvider.isAdmin)
          IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFFF2770)),
              tooltip: 'Panel Admin',
              onPressed: () => Navigator.pushNamed(context, _routeAdmin)),
        _buildUserBadge(authProvider.userFullName),
        IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () => _handleLogout(authProvider)),
      ] else
        TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, _routeLogin),
            icon: const Icon(Icons.person, color: Colors.white, size: 18),
            label: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white, fontSize: 13))),
      const SizedBox(width: 8),
      _buildCartButton(),
    ]);
  }

  Widget _buildMobileAppBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Row(children: [
      const SizedBox(width: 40),
      _buildLogo(35),
      const Spacer(),
      if (authProvider.isLoggedIn)
        Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(authProvider.userFullName.split(' ')[0],
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))),
      _buildCartButton(),
    ]);
  }

  Widget _buildLogo(double size) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, _routeHome),
      child: Image.asset('assets/img/logo12.png', width: size, height: size,
          errorBuilder: (_, __, ___) => Container(
              width: size, height: size,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('UC',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4))))),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 200, height: 40,
      decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2a2a2a))),
      child: const TextField(
          style: TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
              hintText: 'Buscar gorras...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true)),
    );
  }

  Widget _buildUserBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF667eea).withOpacity(0.3),
            const Color(0xFF764ba2).withOpacity(0.3),
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF667eea), width: 1.5)),
      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCartButton() {
    final cartProvider = Provider.of<CartProvider>(context);
    return Stack(children: [
      IconButton(
          onPressed: () => Navigator.pushNamed(context, _routeCart),
          icon: const Icon(Icons.shopping_cart, color: Colors.white)),
      if (cartProvider.itemCount > 0)
        Positioned(
            right: 8, top: 8,
            child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF2770), Color(0xFFFF6B9D)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFFF2770).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('${cartProvider.itemCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center))),
    ]);
  }

  Widget _buildMobileDrawer() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Drawer(
      backgroundColor: const Color(0xFF0a0a0a),
      child: ListView(padding: EdgeInsets.zero, children: [
        DrawerHeader(
            decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              _buildLogo(50),
              const SizedBox(height: 12),
              const Text('URBAN COPS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(authProvider.isLoggedIn ? 'Hola, ${authProvider.userFullName}' : '$_teamName Collection',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ])),
        _buildDrawerSection('NBA', [
          _buildDrawerItem(_teamChicagoBulls,     Icons.sports_basketball, _routeChicago),
          _buildDrawerItem(_teamBostonCeltics,    Icons.sports_basketball, _routeBoston),
          _buildDrawerItem(_teamLosAngelesLakers, Icons.sports_basketball, _routeLakers),
        ]),
        const Divider(color: Color(0xFF2a2a2a)),
        _buildDrawerSection('NFL', [
          _buildDrawerItem(_teamAtlantaFalcons,   Icons.sports_football, _routeFalcon),
          _buildDrawerItem(_teamArizonaCardinals, Icons.sports_football, _routeArizona),
          _buildDrawerItem(_teamLasVegasRaiders,  Icons.sports_football, _routeVegas),
        ]),
        const Divider(color: Color(0xFF2a2a2a)),
        _buildDrawerSection('MLB', [
          _buildDrawerItem(_teamName,            Icons.sports_baseball, _routeRed),
          _buildDrawerItem(_teamChicagoWhiteSox, Icons.sports_baseball, _routeWhite),
          _buildDrawerItem(_teamAtlantaBraves,   Icons.sports_baseball, _routeAtlanta),
        ]),
        const Divider(color: Color(0xFF2a2a2a)),
        ListTile(
          leading: const Icon(Icons.palette, color: Color(0xFFFF6B9D)),
          title: const Text('Personalizadas', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); Navigator.pushNamed(context, _routePersonalizadas); },
        ),
        ListTile(
          leading: const Icon(Icons.support_agent, color: Color(0xFFFFB347)),
          title: const Text('PQRS', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(context); Navigator.pushNamed(context, _routePqrs); },
        ),
        const Divider(color: Color(0xFF2a2a2a)),
        if (authProvider.isLoggedIn) ...[
          if (authProvider.isAdmin)
            ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFFF2770)),
                title: const Text('Panel Admin', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(context); Navigator.pushNamed(context, _routeAdmin); }),
          ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _handleLogout(authProvider); }),
        ] else
          ListTile(
              leading: const Icon(Icons.person, color: Colors.white70),
              title: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); Navigator.pushNamed(context, _routeLogin); }),
      ]),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
        height: 500, width: double.infinity,
        child: Image.asset('assets/img/Red/Wall2.jpg', fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.red.shade900, Colors.black])),
                child: const Center(child: Icon(Icons.sports_baseball, size: 100, color: Colors.white54)))));
  }

  Widget _buildProductSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      child: Column(children: [
        Text(_teamName, style: TextStyle(fontSize: isMobile ? 28 : 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('$_teamName no solo representan un equipo, representan historia, pasión y estilo. Son símbolo de Boston, del béisbol real y del orgullo que nunca pasa de moda.',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Wrap(
            spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
            children: productos.map((p) =>
                _buildProductCard(p['id'], p['nombre'], p['desc'], p['precio'], p['imagen'], isMobile)).toList()),
      ]),
    );
  }

  Widget _buildProductCard(int id, String nombre, String desc, int precio, String imagen, bool isMobile) {
    final cardWidth = isMobile ? MediaQuery.of(context).size.width - 40 : 320.0;
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a1a), Color(0xFF0f0f0f)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a2a2a), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            height: 200, width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF0a0a0a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(imagen, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image, size: 60, color: Color(0xFF2a2a2a)))))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Text('\$${_formatPrice(precio)} COP',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity, height: 45,
                child: ElevatedButton(
                    onPressed: () => _addToCart(id, nombre, precio, imagen),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                    child: const Text('Agregar al carrito', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 30 : 40),
        decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF0a0a0a), Color(0xFF000000)])),
        child: Column(children: [
          const Text('UrbanCops', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 16),
          Text('Gorras urbanas exclusivas con estilo auténtico.\nRepresenta tu equipo, tu barrio y tu esencia.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildSocialButton(Icons.facebook),
            _buildSocialButton(Icons.camera_alt),
            _buildSocialButton(Icons.phone),
          ]),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('© ${DateTime.now().year} UrbanCops. Todos los derechos reservados.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ]));
  }

  Widget _buildSocialButton(IconData icon) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a), shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2a2a2a))),
        child: IconButton(onPressed: () {}, icon: Icon(icon, color: Colors.white)));
  }

  Widget _buildNavMenu(String title, List<PopupMenuEntry<String>> items) {
    return PopupMenuButton<String>(
        offset: const Offset(0, 50),
        color: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF2a2a2a))),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            ])),
        itemBuilder: (context) => items,
        onSelected: (value) => Navigator.pushNamed(context, value));
  }

  PopupMenuItem<String> _buildNavMenuItem(String title, String route) {
    return PopupMenuItem<String>(
        value: route,
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)));
  }

  Widget _buildNavButton(String title, VoidCallback onPressed) {
    return TextButton(
        onPressed: onPressed,
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)));
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return ExpansionTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        children: items);
  }

  Widget _buildDrawerItem(String title, IconData icon, String route) {
    return ListTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        onTap: () { Navigator.pop(context); Navigator.pushNamed(context, route); });
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    await authProvider.logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Sesión cerrada correctamente'),
          backgroundColor: const Color(0xFF10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      Navigator.pushReplacementNamed(context, _routeHome);
    }
  }
}