// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/public/home_page.dart';
import 'screens/public/login_screen.dart';
import 'screens/public/register_screen.dart';
import 'screens/products/chicago_page.dart';
import 'screens/products/boston_page.dart';
import 'screens/products/lakers_page.dart';
import 'screens/products/atlanta_page.dart';
import 'screens/products/falcon_page.dart';
import 'screens/products/arizona_page.dart';
import 'screens/products/vegas_page.dart';
import 'screens/products/red_page.dart';
import 'screens/products/white_page.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/usuarios_screen.dart';
import 'screens/admin/pqrs_admin_screen.dart';
import 'screens/admin/roles_screen.dart';
import 'screens/admin/inventario_screen.dart';
import 'screens/admin/pedidos_screen.dart';
import 'screens/admin/personalizaciones_screen.dart';
import 'screens/public/personalizaciones_publicas_screen.dart'; // ✅ NUEVO

import 'screens/cart_screen.dart';
import 'screens/products/pqrs_page.dart';
import 'screens/public/user_panel_page.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

void main() {
  runApp(const UrbanCopsApp());
}

class UrbanCopsApp extends StatelessWidget {
  const UrbanCopsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'URBAN COPS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/chicago': (context) => const ChicagoPage(),
          '/boston': (context) => const BostonPage(),
          '/lakers': (context) => const LakersPage(),
          '/atlanta': (context) => const AtlantaPage(),
          '/falcon': (context) => const FalconPage(),
          '/arizona': (context) => const ArizonaPage(),
          '/vegas': (context) => const VegasPage(),
          '/red': (context) => const RedPage(),
          '/white': (context) => const WhitePage(),
          '/admin': (context) => const AdminDashboard(),
          '/admin/usuarios': (context) => const UsuariosScreen(),
          '/admin/pqrs': (context) => const PqrsAdminScreen(),
          '/admin/roles': (context) => const RolesScreen(),
          '/admin/inventario': (context) => const InventarioScreen(),
          '/admin/pedidos': (context) => const PedidosScreen(),
          '/admin/personalizaciones': (context) => const PersonalizacionesAdminScreen(),
          '/personalizadas': (context) => const PersonalizacionesPublicasScreen(),
          '/cart': (context) => const CartScreen(),
          '/pqrs': (context) => const PqrsPage(),
          '/mi-cuenta': (context) => const UserPanelPage(),
        },
      ),
    );
  }
}