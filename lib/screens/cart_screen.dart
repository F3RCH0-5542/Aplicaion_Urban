import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _procesando = false;

  // Controladores para el formulario
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  String _metodoPago = 'efectivo';

  @override
  void dispose() {
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _finalizarCompra() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Verificar autenticación
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Debes iniciar sesión para finalizar la compra'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _procesando = true);

    try {
      final productos = cartProvider.getProductsForOrder();
      final total = cartProvider.totalAmount;

      final datosCompra = {
        'productos': productos,
        'total': total,
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'metodo_pago': _metodoPago,
      };

      print('📤 Enviando pedido: $datosCompra');

      final response = await http.post(
        Uri.parse('http://localhost:3001/api/pedidos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: json.encode(datosCompra),
      );

      final data = json.decode(response.body);
      print('📥 Respuesta: $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        // Mostrar mensaje de éxito
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ ¡Compra Exitosa!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido #${data['pedido']?['id_pedido'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Total: \$${_formatPrice(total)} COP'),
                const SizedBox(height: 8),
                Text('Envío a: ${_ciudadController.text}'),
                const SizedBox(height: 8),
                Text('Pago: $_metodoPago'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cartProvider.clear();
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${data['msg'] ?? 'Error al procesar el pedido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al conectar con el servidor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Row(
          children: [
            Image.asset(
              'assets/img/logo12.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag),
            ),
            const SizedBox(width: 12),
            const Text('UrbanCops'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Volver a la tienda',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            children: [
              // Título
              const Text(
                '🛒 Tu Carrito de Compras',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Contenido del carrito
              if (cartProvider.isEmpty)
                _buildEmptyCart()
              else
                Column(
                  children: [
                    _buildCartItems(cartProvider, isMobile),
                    const SizedBox(height: 32),
                    _buildCheckoutForm(cartProvider, isMobile),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Carrito vacío
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(fontSize: 24, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Ir a comprar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Grid de productos en el carrito
  Widget _buildCartItems(CartProvider cartProvider, bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 4,
        childAspectRatio: isMobile ? 1.3 : 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cartProvider.itemsList.length,
      itemBuilder: (context, index) {
        final item = cartProvider.itemsList[index];
        final key = item.nombre;
        return _buildCartCard(item, key, cartProvider);
      },
    );
  }

  // Card de producto individual
  Widget _buildCartCard(CartItem item, String key, CartProvider cartProvider) {
    return Card(
      color: const Color(0xFF1a1a1a),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2a2a2a),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Image.asset(
              item.imagen,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),

          // Información
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    item.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Precio unitario
                  Text(
                    '\$${_formatPrice(item.precio)} COP',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),

                  // Controles de cantidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => cartProvider.decreaseQuantity(key),
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.white70,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.cantidad}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => cartProvider.increaseQuantity(key),
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.white70,
                      ),
                    ],
                  ),

                  // Subtotal
                  Text(
                    'Subtotal: \$${_formatPrice(item.subtotal)} COP',
                    style: const TextStyle(
                      color: Color(0xFF10b981),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Botón eliminar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => cartProvider.removeItem(key),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Formulario de checkout
  Widget _buildCheckoutForm(CartProvider cartProvider, bool isMobile) {
    return Card(
      color: const Color(0xFF1a1a1a),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Información de Envío y Pago',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Layout responsive
              isMobile
                  ? Column(
                      children: [
                        _buildFormSection(),
                        const SizedBox(height: 24),
                        _buildSummarySection(cartProvider),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildFormSection()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildSummarySection(cartProvider)),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Sección del formulario
  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 Dirección de Envío',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Dirección
        TextFormField(
          controller: _direccionController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Dirección Completa *',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'Calle 123 #45-67, Barrio Centro',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa tu dirección';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Ciudad
        TextFormField(
          controller: _ciudadController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Ciudad *',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'Ej: Bogotá',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa tu ciudad';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Teléfono
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Teléfono *',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'Ej: 3001234567',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa tu teléfono';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        const Divider(color: Colors.white24),
        const SizedBox(height: 24),

        // Método de pago
        const Text(
          '💳 Método de Pago',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _metodoPago
          dropdownColor: const Color(0xFF2a2a2a),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'efectivo', child: Text('💵 Efectivo')),
            DropdownMenuItem(value: 'nequi', child: Text('📱 Nequi')),
            DropdownMenuItem(value: 'daviplata', child: Text('📱 Daviplata')),
            DropdownMenuItem(value: 'tarjeta', child: Text('💳 Tarjeta')),
            DropdownMenuItem(
                value: 'transferencia', child: Text('🏦 Transferencia')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _metodoPago = value);
            }
          },
        ),
      ],
    );
  }

  // Sección de resumen
  Widget _buildSummarySection(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Resumen del pedido',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de productos
          ...cartProvider.itemsList.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${item.nombre} x${item.cantidad}',
                        style: const TextStyle(color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${_formatPrice(item.subtotal)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(color: Colors.white24, height: 32),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '\$${_formatPrice(cartProvider.totalAmount)} COP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Envío
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Envío:',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                'GRATIS',
                style: TextStyle(
                  color: Color(0xFF10b981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 32),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a pagar:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${_formatPrice(cartProvider.totalAmount)} COP',
                style: const TextStyle(
                  color: Color(0xFF10b981),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Botones
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _procesando ? null : _finalizarCompra,
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label:
                      Text(_procesando ? 'Procesando...' : 'Confirmar Pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _procesando
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('¿Vaciar carrito?'),
                              content: const Text(
                                  '¿Estás seguro de que quieres eliminar todos los productos?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    cartProvider.clear();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Vaciar',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Vaciar Carrito'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
