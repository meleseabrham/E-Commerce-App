import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // Load cart items for current user
  Future<void> loadUserCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('carts')
          .select()
          .eq('user_id', user.id)
          .single();
      if (response != null && response['items'] != null) {
        _items.clear();
        final items = response['items'] as List<dynamic>;
        for (var item in items) {
          final cartItem = CartItem.fromMap(item as Map<String, dynamic>);
          _items[cartItem.id] = cartItem;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to Firestore
  Future<void> saveCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('carts').upsert({
        'user_id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
        'items': _items.values.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: product.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          imageUrl: existingCartItem.imageUrl,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id,
          productId: product.id,
          name: product.name,
          price: product.price,
          quantity: 1,
          imageUrl: product.imageUrl,
        ),
      );
    }
    saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: quantity,
          imageUrl: existingCartItem.imageUrl,
        ),
      );
      saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    saveCart();
    notifyListeners();
  }
} 