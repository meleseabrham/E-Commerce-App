import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/product/product_detail_screen.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<bool>? onFavoriteToggle;

  const ProductCard({super.key, required this.product, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFavorite = wishlistProvider.wishlist.any((p) => p.id == product.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: SizedBox(
        height: 220,
        child: Card(
          elevation: 4,
          shadowColor: AppColors.shadow,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 2,
                    child: Center(
                      child: _buildProductImage(product.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                    child: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Builder(
                  builder: (context) {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) {
                      return SizedBox.shrink(); // Do not show the icon for guests
                    }
                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                      onPressed: () async {
                        await wishlistProvider.toggleWishlist(product);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    } else {
      return Image.asset(
        imageUrl,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 80, color: Colors.grey),
      );
    }
  }
} 