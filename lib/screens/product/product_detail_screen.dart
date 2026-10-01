import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/currency.dart';
import 'package:mehal_gebeya/utils/app_notify.dart';
import '../../theme/app_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import 'package:provider/provider.dart';
import '../payment/payment_screen.dart';
import '../cart/cart_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart'; // Added import for LoginScreen
import '../../widgets/full_screen_image_viewer.dart';

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

  int _currentImageIndex = 0;
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  List<String> get _allImages {
    final List<String> images = [];
    if (widget.product.imageUrl.isNotEmpty) images.add(widget.product.imageUrl);
    if (widget.product.imageUrls.isNotEmpty) images.addAll(widget.product.imageUrls.where((e) => e.isNotEmpty));
    return images.isEmpty ? [''] : images;
  }

  void _openFullScreenImage(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          images: _allImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchReviews();
    _loadMyReview();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final images = _allImages;
      if (images.length <= 1) return;
      final next = (_currentImageIndex + 1) % images.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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
      AppNotify.error(context, 'Login to leave a review!');
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

  Widget _buildNetworkOrAsset(String url, {double height = 300}) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 80)),
      );
    }
    if (url.isEmpty) {
      return Center(child: Icon(Icons.image_not_supported, size: 80));
    }
    return Image.asset(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 80)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _allImages;
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Auto-sliding image carousel ──────────────────────────
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  // PageView
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openFullScreenImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: _buildNetworkOrAsset(images[index], height: 320),
                        ),
                      );
                    },
                  ),
                  // Bottom gradient
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Dot indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _currentImageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  // Left arrow
                  if (images.length > 1)
                    Positioned(
                      left: 8, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _autoSlideTimer?.cancel();
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                            _startAutoSlide();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (images.length > 1)
                    Positioned(
                      right: 8, top: 0, bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _autoSlideTimer?.cancel();
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                            _startAutoSlide();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ),
                  // Image counter badge
                  if (images.length > 1)
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  // Tap to zoom hint badge
                  Positioned(
                    top: 12, left: 12,
                    child: GestureDetector(
                      onTap: () => _openFullScreenImage(_currentImageIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Zoom',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    formatETB(widget.product.price),
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
    
    AppNotify.success(context, '${widget.product.name} added to cart');
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