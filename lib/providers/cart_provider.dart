import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  final _firestore = FirebaseFirestore.instance;

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
    final user = FirebaseService.currentUser;
    if (user == null) return;

    try {
      final cartDoc = await _firestore
          .collection('carts')
          .doc(user.uid)
          .get();

      if (cartDoc.exists) {
        final cartData = cartDoc.data() as Map<String, dynamic>;
        _items.clear();
        
        if (cartData.containsKey('items')) {
          final items = cartData['items'] as List<dynamic>;
          for (var item in items) {
            final cartItem = CartItem.fromMap(item as Map<String, dynamic>);
            _items[cartItem.id] = cartItem;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to Firestore
  Future<void> _saveCart() async {
    final user = FirebaseService.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('carts').doc(user.uid).set({
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
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
          image: existingCartItem.image,
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
          image: product.image,
        ),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCart();
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
          image: existingCartItem.image,
        ),
      );
      _saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }
} 