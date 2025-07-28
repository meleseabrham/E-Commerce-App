import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Product> _wishlist = [];
  bool _isLoading = false;

  List<Product> get wishlist => List.unmodifiable(_wishlist);
  bool get isLoading => _isLoading;

  Future<void> fetchWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    final data = await Supabase.instance.client
        .from('wishlist')
        .select('product_id')
        .eq('user_id', user.id);
    final productIds = data.map((e) => e['product_id']).toList();
    if (productIds.isEmpty) {
      _wishlist.clear();
      _isLoading = false;
      notifyListeners();
      return;
    }
    final productsData = await Supabase.instance.client
        .from('products')
        .select()
        .inFilter('id', productIds)
        .eq('is_sold', false);
    _wishlist
      ..clear()
      ..addAll(List<Map<String, dynamic>>.from(productsData)
          .map((map) => Product.fromMap({...map, 'isFavorite': true})));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addToWishlist(Product product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('wishlist').insert({
        'user_id': user.id,
        'product_id': product.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ignore duplicate insert errors
      if (!e.toString().contains('duplicate')) {
        rethrow;
      }
    }
    await fetchWishlist();
  }

  Future<void> removeFromWishlist(Product product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client
        .from('wishlist')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', product.id);
    await fetchWishlist();
  }

  Future<void> toggleWishlist(Product product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (_wishlist.any((p) => p.id == product.id)) {
      await removeFromWishlist(product);
    } else {
      await addToWishlist(product);
    }
    await fetchWishlist(); // Always refresh after change
  }
} 