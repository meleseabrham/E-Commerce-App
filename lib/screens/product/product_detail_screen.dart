import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import 'package:provider/provider.dart';
import '../payment/payment_screen.dart';
import '../cart/cart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart'; // Added import for LoginScreen

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoadingReviews = true;
  final _reviewController = TextEditingController();
  int _selectedRating = 5;
  Map<String, dynamic>? _myReview;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _loadMyReview();
  }

  Future<void> _loadMyReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final existing = await Supabase.instance.client
        .from('product_reviews')
        .select()
        .eq('product_id', widget.product.id)
        .eq('user_id', user.id)
        .maybeSingle();
    if (existing != null) {
      setState(() {
        _myReview = existing;
        _selectedRating = existing['rating'] ?? 5;
        _reviewController.text = existing['review'] ?? '';
      });
    }
  }

  Future<void> _fetchReviews() async {
    final data = await Supabase.instance.client
        .from('product_reviews')
        .select()
        .eq('product_id', widget.product.id)
        .order('created_at', ascending: false);
    setState(() {
      _reviews = List<Map<String, dynamic>>.from(data);
      if (_reviews.isNotEmpty) {
        _averageRating = _reviews.map((r) => (r['rating'] as int)).reduce((a, b) => a + b) / _reviews.length;
      } else {
        _averageRating = 0.0;
      }
      _isLoadingReviews = false;
    });
  }

  Future<void> _submitReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login to leave a review!')),
      );
      return;
    }
    final existing = await Supabase.instance.client
        .from('product_reviews')
        .select()
        .eq('product_id', widget.product.id)
        .eq('user_id', user.id)
        .maybeSingle();
    if (existing != null) {
      await Supabase.instance.client.from('product_reviews').update({
        'rating': _selectedRating,
        'review': _reviewController.text,
      }).eq('id', existing['id']);
    } else {
      await Supabase.instance.client.from('product_reviews').insert({
        'product_id': widget.product.id,
        'user_id': user.id,
        'rating': _selectedRating,
        'review': _reviewController.text,
      });
    }
    _reviewController.clear();
    _selectedRating = 5;
    await _loadMyReview();
    _fetchReviews();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Icon(Icons.check_circle, color: Colors.green, size: 48),
          content: Text('Thank you for reviewing ${widget.product.name}!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProductImage(String imageUrl, {double height = 300}) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 80)),
      );
    } else {
      return Image.asset(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 80)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              child: widget.product.imageUrl != null && widget.product.imageUrl.isNotEmpty
                  ? _buildProductImage(widget.product.imageUrl)
                  : Center(child: Icon(Icons.image_not_supported, size: 80)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.product.categoryName ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _addToCart(context),
                          child: const Text('Add to Cart'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _buyNow(context),
                          child: const Text('Buy Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(_averageRating.toStringAsFixed(1)),
                  SizedBox(width: 8),
                  Text('(${_reviews.length} reviews)'),
                ],
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _isLoadingReviews
                ? Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('No reviews yet.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _reviews.length,
                        itemBuilder: (context, i) {
                          final review = _reviews[i];
                          return ListTile(
                            leading: Icon(Icons.person),
                            title: Row(
                              children: [
                                ...List.generate(
                                  review['rating'],
                                  (index) => Icon(Icons.star, color: Colors.amber, size: 16),
                                ),
                              ],
                            ),
                            subtitle: Text(review['review'] ?? ''),
                          );
                        },
                      ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leave a Review', style: TextStyle(fontWeight: FontWeight.bold)),
                  Builder(
                    builder: (context) {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Login to leave a review.', style: TextStyle(color: Colors.red)),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Rating: '),
                              DropdownButton<int>(
                                value: _selectedRating,
                                items: List.generate(5, (i) => i + 1)
                                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedRating = v ?? 5),
                              ),
                            ],
                          ),
                          TextField(
                            controller: _reviewController,
                            decoration: InputDecoration(labelText: 'Write your review...'),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _submitReview,
                            child: Text(_myReview != null ? 'Update Review' : 'Submit Review'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    // Allow guests to add to cart (cart is local for guests)
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(widget.product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartScreen()),
            );
          },
        ),
      ),
    );
  }

  void _buyNow(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItem = CartItem(
      id: widget.product.id,
      productId: widget.product.id,
      name: widget.product.name,
      price: widget.product.price,
      quantity: 1,
      imageUrl: widget.product.imageUrl,
    );
    void goToPayment() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            items: cartProvider.items.values.toList(),
            totalAmount: cartProvider.totalAmount,
          ),
        ),
      );
    }
    if (user == null) {
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
                cartProvider.addItem(widget.product);
                Navigator.pop(context); // Close dialog
                goToPayment();
              },
            ),
          ),
        ),
      );
      return;
    }
    cartProvider.addItem(widget.product);
    goToPayment();
  }
} 