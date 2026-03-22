// lib/screens/public/home_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  bool _showSearch = false;

  final PageController _mainCarouselController = PageController();
  int _currentMainPage = 0;
  Timer? _mainCarouselTimer;

  final PageController _secondCarouselController = PageController();
  int _currentSecondPage = 0;
  Timer? _secondCarouselTimer;

  static const Color _bg = Color(0xFF000000);
  static const Color _surface = Color(0xFF0a0a0a);
  static const Color _card = Color(0xFF1a1a1a);
  static const Color _border = Color(0xFF2a2a2a);
  static const Color _accent = Color(0xFF667eea);
  static const Color _accentAlt = Color(0xFF764ba2);
  static const Color _danger = Color(0xFFFF2770);

  @override
  void initState() {
    super.initState();
    _startCarousel(_mainCarouselController, (p) => _currentMainPage = p,
        () => _currentMainPage, (t) => _mainCarouselTimer = t);
    _startCarousel(_secondCarouselController, (p) => _currentSecondPage = p,
        () => _currentSecondPage, (t) => _secondCarouselTimer = t);
  }

  void _startCarousel(
    PageController controller,
    Function(int) setPage,
    int Function() getPage,
    Function(Timer) setTimer,
  ) {
    setTimer(Timer.periodic(const Duration(seconds: 4), (_) {
      int next = (getPage() + 1) % 3;
      setPage(next);
      if (controller.hasClients) {
        controller.animateToPage(next,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut);
      }
    }));
  }

  @override
  void dispose() {
    _mainCarouselTimer?.cancel();
    _secondCarouselTimer?.cancel();
    _mainCarouselController.dispose();
    _secondCarouselController.dispose();
    super.dispose();
  }

  void _addToCart(int idProducto, String name, int price, String image) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(
        idProducto: idProducto, nombre: name, precio: price, imagen: image);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text('$name agregado al carrito',
                style: const TextStyle(fontSize: 13))),
      ]),
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF10b981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 800;
    final isTablet = w >= 800 && w < 1200;

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(isMobile),
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isMobile && _showSearch) _buildMobileSearchBar(),
            _buildMainCarousel(isMobile),
            const SizedBox(height: 48),
            _buildSection('NBA',
                'Colección oficial de gorras New Era de la NBA.',
                _buildNBAProducts(), isMobile, isTablet),
            const SizedBox(height: 48),
            _buildSection('NFL',
                'Colección oficial de gorras New Era de la NFL.',
                _buildNFLProducts(), isMobile, isTablet),
            const SizedBox(height: 48),
            _buildCollections(isMobile, isTablet),
            const SizedBox(height: 48),
            _buildSecondCarousel(isMobile),
            const SizedBox(height: 48),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isMobile ? 58 : 66),
      child: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
        leading: isMobile
            ? Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              )
            : null,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 16),
            child: isMobile ? _buildMobileAppBar() : _buildDesktopAppBar(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopAppBar() {
    final auth = Provider.of<AuthProvider>(context);
    return Row(
      children: [
        _buildLogo(38),
        const SizedBox(width: 16),
        _buildNavMenu('NBA', [
          _buildNavMenuItem('Chicago Bulls', '/chicago'),
          _buildNavMenuItem('Boston Celtics', '/boston'),
          _buildNavMenuItem('Los Angeles Lakers', '/lakers'),
        ]),
        const SizedBox(width: 6),
        _buildNavMenu('NFL', [
          _buildNavMenuItem('Atlanta Falcons', '/falcon'),
          _buildNavMenuItem('Arizona Cardinals', '/arizona'),
          _buildNavMenuItem('Las Vegas Raiders', '/vegas'),
        ]),
        const SizedBox(width: 6),
        _buildNavMenu('MLB', [
          _buildNavMenuItem('Boston Red Sox', '/red'),
          _buildNavMenuItem('Chicago White Sox', '/white'),
          _buildNavMenuItem('Atlanta Braves', '/atlanta'),
        ]),
        const SizedBox(width: 6),
        _buildNavButton('Personalizadas',
            () => Navigator.pushNamed(context, '/personalizadas')),
        const SizedBox(width: 6),
        _buildNavButton('PQRS', () => Navigator.pushNamed(context, '/pqrs')),
        const Spacer(),
        _buildDesktopSearchBar(),
        const SizedBox(width: 12),
        if (auth.isLoggedIn) ...[
          IconButton(
            icon: const Icon(Icons.account_circle, color: _accent),
            tooltip: 'Mi Cuenta',
            onPressed: () => Navigator.pushNamed(context, '/mi-cuenta'),
          ),
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: _danger),
              tooltip: 'Panel Admin',
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          _buildUserBadge(auth.userFullName),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            tooltip: 'Cerrar sesión',
            onPressed: () => _handleLogout(auth),
          ),
        ] else
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.person, color: Colors.white, size: 18),
            label: const Text('Iniciar Sesión',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        const SizedBox(width: 8),
        _buildCartButton(),
      ],
    );
  }

  Widget _buildMobileAppBar() {
    final auth = Provider.of<AuthProvider>(context);
    return Row(
      children: [
        const SizedBox(width: 44),
        _buildLogo(32),
        const Spacer(),
        IconButton(
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            color: Colors.white70,
            size: 22,
          ),
          onPressed: () => setState(() => _showSearch = !_showSearch),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        if (auth.isLoggedIn)
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: _accent, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/mi-cuenta'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        _buildCartButton(),
      ],
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: TextField(
        autofocus: true,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar gorras...',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          filled: true,
          fillColor: _card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double size) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/'),
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/img/logo12.png',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accent, _accentAlt]),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text('UC',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.38)),
        ),
      ),
    );
  }

  Widget _buildDesktopSearchBar() {
    return Container(
      width: 200,
      height: 38,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'Buscar gorras...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildUserBadge(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          _accent.withOpacity(0.25),
          _accentAlt.withOpacity(0.25),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withOpacity(0.6)),
      ),
      child: Text(name,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCartButton() {
    final cart = Provider.of<CartProvider>(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/cart'),
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        if (cart.itemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_danger, Color(0xFFFF6B9D)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: _danger.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1)
                ],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('${cart.itemCount}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DRAWER MÓVIL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobileDrawer() {
    final auth = Provider.of<AuthProvider>(context);
    return Drawer(
      backgroundColor: _surface,
      width: MediaQuery.of(context).size.width * 0.82,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accent, _accentAlt],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(children: [
                  _buildLogo(44),
                  const SizedBox(width: 12),
                  const Text('URBAN COPS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                ]),
                const SizedBox(height: 8),
                Text(
                  auth.isLoggedIn
                      ? 'Hola, ${auth.userFullName}'
                      : 'Gorras Urbanas Auténticas',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildDrawerSection('NBA', Icons.sports_basketball_outlined, [
            _buildDrawerItem('Chicago Bulls', '/chicago'),
            _buildDrawerItem('Boston Celtics', '/boston'),
            _buildDrawerItem('Los Angeles Lakers', '/lakers'),
          ]),
          _buildDrawerDivider(),
          _buildDrawerSection('NFL', Icons.sports_football_outlined, [
            _buildDrawerItem('Atlanta Falcons', '/falcon'),
            _buildDrawerItem('Arizona Cardinals', '/arizona'),
            _buildDrawerItem('Las Vegas Raiders', '/vegas'),
          ]),
          _buildDrawerDivider(),
          _buildDrawerSection('MLB', Icons.sports_baseball_outlined, [
            _buildDrawerItem('Boston Red Sox', '/red'),
            _buildDrawerItem('Chicago White Sox', '/white'),
            _buildDrawerItem('Atlanta Braves', '/atlanta'),
          ]),
          _buildDrawerDivider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: Color(0xFFFF6B9D), size: 22),
            title: const Text('Personalizadas',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/personalizadas');
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined,
                color: Color(0xFFFFB347), size: 22),
            title: const Text('PQRS',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/pqrs');
            },
          ),
          _buildDrawerDivider(),
          if (auth.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.account_circle_outlined, color: _accent, size: 22),
              title: const Text('Mi Cuenta',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/mi-cuenta');
              },
            ),
            if (auth.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined,
                    color: _danger, size: 22),
                title: const Text('Panel Admin',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin');
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white54, size: 22),
              title: const Text('Cerrar Sesión',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(auth);
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.login_rounded, color: Colors.white70, size: 22),
              title: const Text('Iniciar Sesión',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerDivider() =>
      const Divider(color: Color(0xFF222222), height: 1, indent: 16, endIndent: 16);

  // ══════════════════════════════════════════════════════════════════════════
  // CARRUSELES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMainCarousel(bool isMobile) {
    final h = isMobile
        ? (MediaQuery.of(context).size.height * 0.32).clamp(200.0, 300.0)
        : (MediaQuery.of(context).size.height * 0.58).clamp(380.0, 580.0);

    return SizedBox(
      height: h,
      child: Stack(
        children: [
          PageView(
            controller: _mainCarouselController,
            onPageChanged: (i) => setState(() => _currentMainPage = i),
            children: [
              _buildCarouselImage('assets/img/Containera.webp'),
              _buildCarouselImage('assets/img/containerb.webp'),
              _buildCarouselImage('assets/img/Contanerc.webp'),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_bg, _bg.withOpacity(0)],
                ),
              ),
            ),
          ),
          if (!isMobile) ...[
            _buildArrow(isLeft: true, onPressed: () {
              _mainCarouselController.previousPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut);
            }),
            _buildArrow(isLeft: false, onPressed: () {
              _mainCarouselController.nextPage(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut);
            }),
          ],
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _buildIndicators(_currentMainPage),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondCarousel(bool isMobile) {
    final h = isMobile ? 220.0 : 380.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
      child: SizedBox(
        height: h,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView(
                controller: _secondCarouselController,
                onPageChanged: (i) => setState(() => _currentSecondPage = i),
                children: [
                  _buildCarouselImage(
                      'assets/img/An-Assortment-of-Baseball-Hats-Displayed-on-Shelves_2468753_wh860.png'),
                  _buildCarouselImage(
                      'assets/img/image_79235f70-f04a-433c-bd7e-4978de0eec57.jpg'),
                  _buildCarouselImage(
                      'assets/img/desktop-wallpaper-colourful-caps-caps.jpg'),
                ],
              ),
            ),
            if (!isMobile) ...[
              _buildArrow(isLeft: true, onPressed: () {
                _secondCarouselController.previousPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut);
              }),
              _buildArrow(isLeft: false, onPressed: () {
                _secondCarouselController.nextPage(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut);
              }),
            ],
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: _buildIndicators(_currentSecondPage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselImage(String path) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: _card,
        child: const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 60, color: _border)),
      ),
    );
  }

  Widget _buildArrow({required bool isLeft, required VoidCallback onPressed}) {
    return Positioned(
      left: isLeft ? 16 : null,
      right: isLeft ? null : 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isLeft
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators(int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == currentPage ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == currentPage ? _accent : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECCIONES DE PRODUCTOS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSection(String title, String subtitle, List<Widget> products,
      bool isMobile, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_accent, _accentAlt]),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: isMobile ? 26 : 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ),
          ),
          const SizedBox(height: 20),
          if (isMobile)
            SizedBox(
              height: 340,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => products[i],
              ),
            )
          else
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: products,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildNBAProducts() {
    return [
      _buildProductCard(2, 'Chicago Bulls',
          'Gorra New Era 59FIFTY colección NBA Classic.', 95000, 'assets/img/chicago.png'),
      _buildProductCard(11, 'Boston Celtics',
          'Logotipo bordado y diseño premium.', 92000, 'assets/img/Raiders12.png'),
      _buildProductCard(20, 'Los Angeles Lakers',
          'Modelo clásico con detalles bordados oficiales.', 98000, 'assets/img/Lakers12.png'),
    ];
  }

  List<Widget> _buildNFLProducts() {
    return [
      _buildProductCard(29, 'Atlanta Falcons',
          'Gorra New Era 59FIFTY colección Classic.', 95000, 'assets/img/Atlanta12.png'),
      _buildProductCard(38, 'Arizona Cardinals',
          'Logotipo bordado y diseño premium.', 92000, 'assets/img/Arizona12.png'),
      _buildProductCard(47, 'Las Vegas Raiders',
          'Modelo clásico con detalles bordados oficiales.', 98000, 'assets/img/Raiders12.png'),
    ];
  }

  // ✅ MÉTODO CORREGIDO - sin duplicado
  Widget _buildProductCard(int idProducto, String name, String description,
      int price, String imagePath) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 800;
    final cardWidth = isMobile ? w * 0.68 : 300.0;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              height: isMobile ? 150 : 200,
              width: double.infinity,
              color: const Color(0xFF0d0d0d),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 48, color: _border)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500], height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text('\$${_formatPrice(price)} COP',
                    style: TextStyle(
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: _accent)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _addToCart(idProducto, name, price, imagePath),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Agregar al carrito',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLECCIONES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCollections(bool isMobile, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFF2770), Color(0xFFFF6B9D)]),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('Colecciones Destacadas',
                  style: TextStyle(
                      fontSize: isMobile ? 22 : 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isMobile ? 1.0 : 1.1,
            children: [
              _buildCollectionImage('assets/img/sti.webp'),
              _buildCollectionImage('assets/img/NIgga.webp'),
              _buildCollectionImage('assets/img/blanco.webp'),
              _buildCollectionImage('assets/img/rap.webp'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionImage(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: const Center(
              child: Icon(Icons.image_not_supported_outlined,
                  size: 36, color: _border)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 40, vertical: isMobile ? 32 : 44),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060606), Color(0xFF000000)],
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                const LinearGradient(colors: [_accent, _accentAlt])
                    .createShader(bounds),
            child: Text('UrbanCops',
                style: TextStyle(
                    fontSize: isMobile ? 26 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.5)),
          ),
          const SizedBox(height: 14),
          Text(
            'Gorras urbanas exclusivas con estilo auténtico.\nRepresenta tu equipo, tu barrio y tu esencia.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(Icons.facebook, const Color(0xFF1877F2)),
              const SizedBox(width: 12),
              _buildSocialButton(Icons.camera_alt_outlined, _danger),
              const SizedBox(width: 12),
              _buildSocialButton(Icons.phone_outlined, const Color(0xFF25D366)),
            ],
          ),
          const SizedBox(height: 28),
          Container(height: 1, color: _border),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} UrbanCops · Todos los derechos reservados.',
            style: TextStyle(color: Colors.grey[700], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {},
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS DESKTOP NAV
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNavMenu(String title, List<PopupMenuEntry<String>> items) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _border),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white54, size: 18),
          ],
        ),
      ),
      itemBuilder: (_) => items,
      onSelected: (v) => Navigator.pushNamed(context, v),
    );
  }

  PopupMenuItem<String> _buildNavMenuItem(String title, String route) {
    return PopupMenuItem<String>(
      value: route,
      height: 40,
      child: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _buildNavButton(String title, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildDrawerSection(String title, IconData icon, List<Widget> items) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        listTileTheme: const ListTileThemeData(dense: true),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: _accent, size: 22),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white38,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        children: items,
      ),
    );
  }

  Widget _buildDrawerItem(String title, String route) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      dense: true,
      title: Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Future<void> _handleLogout(AuthProvider auth) async {
    await auth.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Sesión cerrada correctamente'),
      backgroundColor: const Color(0xFF10b981),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}