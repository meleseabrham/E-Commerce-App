import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/product_detail_screen.dart';
import '../../providers/wishlist_provider.dart';
import '../../screens/cart_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WishlistView();
  }
}

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlist = wishlistProvider.wishlist;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: Colors.green,
      ),
      body: wishlistProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlist.isEmpty
              ? const Center(child: Text('No favorites yet.'))
              : ListView.builder(
                  itemCount: wishlist.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, i) {
                    final product = wishlist[i];
                    final isFavorite = wishlistProvider.wishlist.any((p) => p.id == product.id);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product.imageUrl.startsWith('http')
                                    ? Image.network(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover)
                                    : Image.asset(product.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.description,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              tooltip: isFavorite ? 'Remove from Wishlist' : 'Add to Wishlist',
                              onPressed: () => wishlistProvider.toggleWishlist(product),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
