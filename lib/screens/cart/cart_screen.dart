import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import '../payment/payment_screen.dart';
import '../auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    // Allow guests to view cart, but only load user cart if logged in
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Provider.of<CartProvider>(context, listen: false).loadUserCart();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading cart: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clearCart(context),
          ),
          if (user == null) ...[
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: SizedBox(
                      height: 500,
                      width: 400,
                      child: LoginScreen(
                        onLoginSuccess: () {
                          // After login, sync cart to Supabase and proceed to payment
                          cart.saveCart();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentScreen(
                                items: cart.items.values.toList(),
                                totalAmount: cart.totalAmount,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              child: Text('Login', style: TextStyle(color: Colors.white)),
            ),
            // If RegistrationScreen is not defined, comment out or replace with a placeholder
            // TextButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       builder: (context) => Dialog(child: RegistrationScreen()),
            //     );
            //   },
            //   child: Text('Register', style: TextStyle(color: Colors.white)),
            // ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.person),
onPressed: () {
    Navigator.pushNamed(context, '/account');
  },
            ),
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) {
                  return _buildEmptyCart();
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) {
                          final cartItem = cart.items.values.toList()[i];
                          return CartItemWidget(cartItem: cartItem);
                        },
                      ),
                    ),
                    _buildCheckoutSection(context, cart),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.secondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${cart.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () => _proceedToCheckout(context, cart),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToCheckout(BuildContext context, CartProvider cart) {
    final user = Supabase.instance.client.auth.currentUser;
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;
    if (user == null) {
      // Show only login dialog (no option dialog)
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(
            height: 500,
            width: 400,
            child: LoginScreen(
              onLoginSuccess: () {
                // After login, sync cart to Supabase and proceed to payment
                cart.saveCart();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      items: cart.items.values.toList(),
                      totalAmount: cart.totalAmount,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          items: cart.items.values.toList(),
          totalAmount: cart.totalAmount,
        ),
      ),
    );
  }

  void _clearCart(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;

  const CartItemWidget({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: cartItem.imageUrl.startsWith('http')
                  ? Image.network(
                      cartItem.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    )
                  : Image.asset(
                      cartItem.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.name,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cartItem.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildQuantityButton(
                        context,
                        Icons.remove,
                        () => _updateQuantity(context, cartItem.quantity - 1),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${cartItem.quantity}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        context,
                        Icons.add,
                        () => _updateQuantity(context, cartItem.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _removeItem(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  void _updateQuantity(BuildContext context, int newQuantity) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (newQuantity <= 0) {
      _removeItem(context);
      return;
    }
    cart.updateQuantity(cartItem.productId, newQuantity);
  }

  void _removeItem(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.removeItem(cartItem.productId);
  }
} 