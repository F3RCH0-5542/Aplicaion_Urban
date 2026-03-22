import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class FalconPage extends StatefulWidget {
  const FalconPage({super.key});

  @override
  State<FalconPage> createState() => _FalconPageState();
}

class _FalconPageState extends State<FalconPage> {
  final List<Map<String, dynamic>> productos = [
    {
      'id': 29,
      'nombre': 'Atlanta Falcons Classic',
      'precio': 95000,
      'imagen': 'assets/img/atlanta/10517894_1-removebg-preview.png',
      'desc':
          'Diseño clásico en negro con visera recta y escudo frontal bordado.'
    },
    {
      'id': 30,
      'nombre': 'Atlanta Falcons Black',
      'precio': 92000,
      'imagen': 'assets/img/atlanta/ATL-removebg-preview.png',
      'desc':
          'Gorra negra con detalles en rojo y logotipo frontal en alto relieve.'
    },
    {
      'id': 31,
      'nombre': 'Atlanta Falcons Logo',
      'precio': 98000,
      'imagen':
          'assets/img/atlanta/0ac1e7f183016ec72c3de6715c4a0e2a-removebg-preview.png',
      'desc': 'Modelo oscuro con bordado oficial y bandera lateral.'
    },
    {
      'id': 32,
      'nombre': 'Falcons Blanca Tricolor',
      'precio': 95000,
      'imagen': 'assets/img/atlanta/images-removebg-preview.png',
      'desc': 'Blanca con visera negra y detalles en rojo.'
    },
    {
      'id': 33,
      'nombre': 'Falcons Azul Hielo',
      'precio': 92000,
      'imagen': 'assets/img/atlanta/10517894_1-removebg-preview.png',
      'desc': 'Tonos azul grisáceo con estilo moderno y escudo clásico.'
    },
    {
      'id': 34,
      'nombre': 'Falcons Roja Curva',
      'precio': 98000,
      'imagen': 'assets/img/atlanta/images__2_-removebg-preview.png',
      'desc': 'Roja con visera curva y diseño deportivo.'
    },
    {
      'id': 35,
      'nombre': 'Falcons Roja Clásica',
      'precio': 95000,
      'imagen': 'assets/img/atlanta/atlantafalcoms2-removebg-preview.png',
      'desc': 'Negra con visera roja y bordado frontal en blanco.'
    },
    {
      'id': 36,
      'nombre': 'Falcons Blanca con Rojo',
      'precio': 92000,
      'imagen': 'assets/img/atlanta/negraroja-removebg-preview.png',
      'desc': 'Panel frontal blanco, visera gris y detalles en rojo.'
    },
    {
      'id': 37,
      'nombre': 'Falcons Gris Hormada',
      'precio': 98000,
      'imagen': 'assets/img/atlanta/rojaynegra-removebg-preview.png',
      'desc': 'Gris texturizada con logo bordado y estructura firme.'
    },
  ];

  void _addToCart(int idProducto, String name, int price, String image) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(
      idProducto: idProducto,
      nombre: name,
      precio: price,
      imagen: image,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $name agregado al carrito'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
        child: Column(
          children: [
            _buildHeroImage(),
            const SizedBox(height: 40),
            _buildProductSection(isMobile),
            const SizedBox(height: 40),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: const Color(0xFF0a0a0a),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.5),
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
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
    return Row(
      children: [
        _buildLogo(40),
        const SizedBox(width: 16),
        _buildNavMenu('NBA', [
          _buildNavMenuItem('Chicago Bulls', '/chicago'),
          _buildNavMenuItem('Boston Celtics', '/boston'),
          _buildNavMenuItem('Los Angeles Lakers', '/lakers')
        ]),
        const SizedBox(width: 8),
        _buildNavMenu('NFL', [
          _buildNavMenuItem('Atlanta Falcons', '/falcon'),
          _buildNavMenuItem('Arizona Cardinals', '/arizona'),
          _buildNavMenuItem('Las Vegas Raiders', '/vegas')
        ]),
        const SizedBox(width: 8),
        _buildNavMenu('MLB', [
          _buildNavMenuItem('Boston Red Sox', '/red'),
          _buildNavMenuItem('Chicago White Sox', '/white'),
          _buildNavMenuItem('Atlanta Braves', '/atlanta')
        ]),
        const SizedBox(width: 8),
        _buildNavButton('Personalizadas',
            () => Navigator.pushNamed(context, '/personalizadas')),
        const SizedBox(width: 8),
        _buildNavButton('PQRS', () => Navigator.pushNamed(context, '/pqrs')),
        const Spacer(),
        _buildSearchBar(),
        const SizedBox(width: 12),
        if (authProvider.isLoggedIn) ...[
          if (authProvider.isAdmin)
            IconButton(
                icon: const Icon(Icons.admin_panel_settings,
                    color: Color(0xFFFF2770)),
                tooltip: 'Panel Admin',
                onPressed: () => Navigator.pushNamed(context, '/admin')),
          _buildUserBadge(authProvider.userFullName),
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Cerrar sesión',
              onPressed: () => _handleLogout(authProvider)),
        ] else
          TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.person, color: Colors.white, size: 18),
              label: const Text('Iniciar Sesión',
                  style: TextStyle(color: Colors.white, fontSize: 13))),
        const SizedBox(width: 8),
        _buildCartButton(),
      ],
    );
  }

  Widget _buildMobileAppBar() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Row(
      children: [
        const SizedBox(width: 40),
        _buildLogo(35),
        const Spacer(),
        if (authProvider.isLoggedIn)
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(authProvider.userFullName.split(' ')[0],
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500))),
        _buildCartButton(),
      ],
    );
  }

  Widget _buildLogo(double size) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/'),
      child: Image.asset('assets/img/logo12.png',
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text('UC',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.4))))),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 200,
      height: 40,
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true)),
    );
  }

  Widget _buildUserBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF667eea).withOpacity(0.3),
            const Color(0xFF764ba2).withOpacity(0.3)
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF667eea), width: 1.5)),
      child: Text(name,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCartButton() {
    final cartProvider = Provider.of<CartProvider>(context);
    return Stack(
      children: [
        IconButton(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart, color: Colors.white)),
        if (cartProvider.itemCount > 0)
          Positioned(
              right: 8,
              top: 8,
              child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF2770), Color(0xFFFF6B9D)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFF2770).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('${cartProvider.itemCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center))),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    final authProvider = Provider.of<AuthProvider>(context);
    return Drawer(
      backgroundColor: const Color(0xFF0a0a0a),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2)
                  ])),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLogo(50),
                    const SizedBox(height: 12),
                    const Text('URBAN COPS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(
                        authProvider.isLoggedIn
                            ? 'Hola, ${authProvider.userFullName}'
                            : 'Atlanta Falcons Collection',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14))
                  ])),
          _buildDrawerSection('NBA', [
            _buildDrawerItem(
                'Chicago Bulls', Icons.sports_basketball, '/chicago'),
            _buildDrawerItem(
                'Boston Celtics', Icons.sports_basketball, '/boston'),
            _buildDrawerItem(
                'Los Angeles Lakers', Icons.sports_basketball, '/lakers')
          ]),
          const Divider(color: Color(0xFF2a2a2a)),
          _buildDrawerSection('NFL', [
            _buildDrawerItem(
                'Atlanta Falcons', Icons.sports_football, '/falcon'),
            _buildDrawerItem(
                'Arizona Cardinals', Icons.sports_football, '/arizona'),
            _buildDrawerItem(
                'Las Vegas Raiders', Icons.sports_football, '/vegas')
          ]),
          const Divider(color: Color(0xFF2a2a2a)),
          _buildDrawerSection('MLB', [
            _buildDrawerItem('Boston Red Sox', Icons.sports_baseball, '/red'),
            _buildDrawerItem(
                'Chicago White Sox', Icons.sports_baseball, '/white'),
            _buildDrawerItem(
                'Atlanta Braves', Icons.sports_baseball, '/atlanta')
          ]),
          const Divider(color: Color(0xFF2a2a2a)),
          ListTile(
            leading: const Icon(Icons.palette, color: Color(0xFFFF6B9D)),
            title: const Text('Personalizadas',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/personalizadas');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF10b981)),
            title: const Text('PQRS', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/pqrs');
            },
          ),
          const Divider(color: Color(0xFF2a2a2a)),
          if (authProvider.isLoggedIn) ...[
            if (authProvider.isAdmin)
              ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Color(0xFFFF2770)),
                  title: const Text('Panel Admin',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin');
                  }),
            ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text('Cerrar Sesión',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout(authProvider);
                }),
          ] else
            ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: const Text('Iniciar Sesión',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                }),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
        height: 500,
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red.shade900, Colors.black])),
        child: ClipRect(
            child: Image.asset('assets/img/falconw.jpg',
                fit: BoxFit.contain,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.sports_football,
                        size: 100, color: Colors.white54)))));
  }

  Widget _buildProductSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      child: Column(
        children: [
          Text('Atlanta Falcons',
              style: TextStyle(
                  fontSize: isMobile ? 28 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(
              'Los Atlanta Falcons se han convertido en un símbolo del fútbol americano gracias a su garra, historia y pasión en el campo. Su emblema, el halcón rojo, transmite fuerza y velocidad, convirtiéndose en un ícono que va más allá del deporte. Las gorras de los Falcons son una muestra de estilo urbano con identidad deportiva, ideales para fanáticos y amantes del diseño con actitud.',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: productos
                  .map((p) => _buildProductCard(p['id'], p['nombre'], p['desc'],
                      p['precio'], p['imagen'], isMobile))
                  .toList()),
        ],
      ),
    );
  }

  Widget _buildProductCard(int id, String nombre, String desc, int precio,
      String imagen, bool isMobile) {
    final cardWidth = isMobile ? MediaQuery.of(context).size.width - 40 : 320.0;
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a1a), Color(0xFF0f0f0f)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2a2a2a), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: Color(0xFF0a0a0a),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12))),
              child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(imagen,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image,
                              size: 60, color: Color(0xFF2a2a2a)))))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(desc,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[400], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Text('\$${_formatPrice(precio)} COP',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea))),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                        onPressed: () => _addToCart(id, nombre, precio, imagen),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0),
                        child: const Text('Agregar al carrito',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 30 : 40),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0a0a0a), Color(0xFF000000)])),
        child: Column(children: [
          const Text('UrbanCops',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          Text(
              'Gorras urbanas exclusivas con estilo auténtico.\nRepresenta tu equipo, tu barrio y tu esencia.',
              style:
                  TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildSocialButton(Icons.facebook),
            _buildSocialButton(Icons.camera_alt),
            _buildSocialButton(Icons.phone)
          ]),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text(
              '© ${DateTime.now().year} UrbanCops. Todos los derechos reservados.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12))
        ]));
  }

  Widget _buildSocialButton(IconData icon) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2a2a2a))),
        child: IconButton(
            onPressed: () {}, icon: Icon(icon, color: Colors.white)));
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
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)
            ])),
        itemBuilder: (context) => items,
        onSelected: (value) => Navigator.pushNamed(context, value));
  }

  PopupMenuItem<String> _buildNavMenuItem(String title, String route) {
    return PopupMenuItem<String>(
        value: route,
        child: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)));
  }

  Widget _buildNavButton(String title, VoidCallback onPressed) {
    return TextButton(
        onPressed: onPressed,
        child: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)));
  }

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return ExpansionTile(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        children: items);
  }

  Widget _buildDrawerItem(String title, IconData icon, String route) {
    return ListTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        });
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
