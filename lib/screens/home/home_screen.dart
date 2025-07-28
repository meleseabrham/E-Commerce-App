import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/registration_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../account/account_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show InternetAddress;
import '../categories/category_products_screen.dart';
import '../../providers/wishlist_provider.dart';

const List<Map<String, dynamic>> kStaticCategories = [
  {"id": 1, "name": "Food and Beverages", "icon": Icons.restaurant_menu},
  {"id": 2, "name": "Clothing", "icon": Icons.shopping_bag},
  {"id": 3, "name": "Handicrafts", "icon": Icons.handyman},
  {"id": 4, "name": "Jewelry", "icon": Icons.diamond},
  {"id": 5, "name": "Electronics", "icon": Icons.computer},
];

Future<bool> hasInternetConnection() async {
  if (kIsWeb) {
    return true; // Assume online for web, or implement a web-specific check if needed
  } else {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _wishlistCount = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;
  int _unreadCount = 0;
  RealtimeChannel? _notificationChannel;

  @override
  void initState() {
    super.initState();
    _fetchWishlistCount();
    _fetchUnreadNotifications();
    _subscribeToNotifications();
    // Listen to wishlist changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      wishlistProvider.addListener(_updateWishlistCount);
    });
    // No need to set _filteredProducts = featuredProducts
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    // Remove wishlist listener
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    wishlistProvider.removeListener(_updateWishlistCount);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['showLoginSuccess'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Welcome to MeHal Gebeya'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  Future<void> _fetchWishlistCount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _wishlistCount = 0);
      return;
    }
    final data = await Supabase.instance.client
        .from('wishlist')
        .select('product_id')
        .eq('user_id', user.id);
    setState(() => _wishlistCount = data.length);
  }

  Future<void> _fetchUnreadNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final notifications = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('type', 'order_accepted')
        .eq('read', false);
    setState(() {
      _unreadCount = notifications.length;
    });
  }

  void _subscribeToNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _notificationChannel = Supabase.instance.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            column: 'user_id',
            value: userId,
            type: PostgresChangeFilterType.eq,
          ),
          callback: (payload) async {
            // Only increment if the notification is of type 'order_accepted' and unread
            final newNotification = payload.newRecord;
            if (newNotification != null &&
                newNotification['type'] == 'order_accepted' &&
                newNotification['read'] == false) {
              setState(() {
                _unreadCount += 1;
              });
            }
          },
        )
        .subscribe();
  }

  void _searchProducts(String query) async {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    if (query.isEmpty) {
      setState(() => _filteredProducts = []);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('products')
          .select()
          .eq('is_sold', false)
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);
      final products = (data as List)
          .map((map) => Product.fromMap(map as Map<String, dynamic>))
          .toList();
      setState(() => _filteredProducts = products);
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No internet connection.', textAlign: TextAlign.center)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final gridColumns = isWeb
        ? (screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2)
        : 2;
    final iconSize = isWeb ? 40.0 : 30.0;
    final circleRadius = isWeb ? 32.0 : 24.0;
    final gridPadding = isWeb ? 16.0 : 8.0;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'M', style: TextStyle(color: AppColors.secondary)),
              TextSpan(text: 'e', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'H', style: TextStyle(color: AppColors.warningColor)),
              TextSpan(text: 'al ', style: TextStyle(color: AppColors.textPrimary)),
              TextSpan(text: 'G', style: TextStyle(color: AppColors.error)),
              TextSpan(text: 'ebeya', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '${cart.itemCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (user != null)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.pushNamed(context, '/my_orders'); // or your notifications screen
                  },
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '$_unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          if (user != null)
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite),
                  tooltip: 'My Wishlist',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WishlistScreen()),
                    );
                    _fetchWishlistCount();
                  },
                ),
                if (_wishlistCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        '$_wishlistCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          if (user == null) ...[
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: SizedBox(
                      height: 500,
                      child: LoginScreen(),
                    ),
                  ),
                );
              },
              child: Text('Login', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: SizedBox(
                      height: 500,
                      child: RegistrationScreen(),
                    ),
                  ),
                );
              },
              child: Text('Register', style: TextStyle(color: Colors.white)),
            ),
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
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchProducts,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchProducts('');
                          },
                        )
                      : const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 8),
            Builder(
              builder: (context) {
                // Check if both products and categories have no internet
                final productsError = false;
                final categoriesError = false;
                // This will be set in the FutureBuilders below
                return Column(
                  children: [
                    _buildCategories(context, iconSize, circleRadius),
                    SizedBox(height: 8),
                    _isSearching
                        ? _buildSearchResults(gridColumns, gridPadding)
                        : FutureBuilder(
                            future: (() async {
                              try {
                                final data = await Supabase.instance.client
                                    .from('products')
                                    .select()
                                    .eq('is_sold', false)
                                    .order('created_at', ascending: false);
                                return data;
                              } catch (e) {
                                throw e;
                              }
                            })(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                final error = snapshot.error.toString();
                                if (error.contains('SocketException')) {
                                  return SizedBox.shrink(); // Don't show here
                                }
                                return Center(child: Text('Error: \n [${snapshot.error}'));
                              }
                              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                              final products = (snapshot.data as List)
                                  .map((map) => Product.fromMap(map as Map<String, dynamic>))
                                  .toList();
                              if (products.isEmpty) return Center(child: Text('No products found.'));
                              final user = Supabase.instance.client.auth.currentUser;
                              return Consumer<WishlistProvider>(
                                builder: (context, wishlistProvider, child) {
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gridColumns,
                                      childAspectRatio: isWeb ? 0.8 : 0.65,
                                      mainAxisSpacing: gridPadding,
                                      crossAxisSpacing: gridPadding,
                                    ),
                                    padding: EdgeInsets.all(gridPadding),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      return ProductCard(
                                        product: products[index],
                                        onFavoriteToggle: (isFav) async {
                                          final user = Supabase.instance.client.auth.currentUser;
                                          if (user == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Login to save your wishlist!')),
                                            );
                                          } else {
                                            setState(() => products[index].isFavorite = isFav);
                                            _fetchWishlistCount();
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                // Only show the error message once if either categories or products fail
                final hasNoInternet = false; // Will be set below
                return FutureBuilder(
                  future: (() async {
                    try {
                      await Supabase.instance.client.from('categories').select('id, name');
                      await Supabase.instance.client.from('products').select();
                      return false;
                    } catch (e) {
                      final error = e.toString();
                      if (error.contains('SocketException')) {
                        return true;
                      }
                      return false;
                    }
                  })(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return Center(child: Text('No internet connection.', textAlign: TextAlign.center));
                    }
                    return SizedBox.shrink();
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 1) {
            showModalBottomSheet(
              context: context,
              builder: (context) => _buildCategoriesSheet(context),
            );
          } else if (index == 2) {
            Navigator.pushNamed(context, '/settings');
          }
        },
      ),
    );
  }

  Future<void> _refreshProducts() async {
    setState(() {}); // Triggers FutureBuilder to re-fetch products
  }

  Widget _buildDrawer(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    return Drawer(
      width: 260,
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: AppColors.error, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...kStaticCategories.map((category) {
                  return _buildDrawerCategory(
                    context: context,
                    icon: category['icon'],
                    title: category['name'],
                    onTap: () async {
                      if (await hasInternetConnection()) {
                        final response = await Supabase.instance.client
                            .from('categories')
                            .select('id')
                            .eq('name', category['name'])
                            .maybeSingle();
                        if (response != null && response['id'] != null) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryId: response['id'],
                                categoryName: category['name'],
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No products found in ${category['name']}.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No internet connection.', textAlign: TextAlign.center)),
                        );
                      }
                    },
                  );
                }).toList(),
                Divider(),
                if (isLoggedIn) ...[
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person,
                    title: 'Account',
                    onTap: () => Navigator.pushNamed(context, '/account'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _searchProducts,
        decoration: InputDecoration(
          hintText: 'Search products...',
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchProducts('');
                  },
                )
              : const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkInputBackground
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults(int gridColumns, double gridPadding) {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : Colors.grey[600],
              ),
            ),
            
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Search Results (${_filteredProducts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            childAspectRatio: kIsWeb ? 0.8 : 0.75,
            mainAxisSpacing: gridPadding,
            crossAxisSpacing: gridPadding,
          ),
          padding: EdgeInsets.all(gridPadding),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            return ProductCard(product: _filteredProducts[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context, double iconSize, double circleRadius) {
    return Container(
      height: circleRadius * 2 + 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kStaticCategories.length,
        itemBuilder: (context, index) {
          final category = kStaticCategories[index];
          return GestureDetector(
            onTap: () async {
              if (await hasInternetConnection()) {
                final response = await Supabase.instance.client
                    .from('categories')
                    .select('id')
                    .eq('name', category['name'])
                    .maybeSingle();
                if (response != null && response['id'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        categoryId: response['id'],
                        categoryName: category['name'],
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No products found in ${category['name']}.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No internet connection.', textAlign: TextAlign.center)),
                );
              }
            },
            child: Container(
              width: circleRadius * 2 + 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category['icon'],
                      color: Colors.green,
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      category['name'] ?? '',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ...kStaticCategories.map((category) {
            return ListTile(
              leading: Icon(category['icon'], color: Colors.green),
              title: Text(category['name'] ?? ''),
              onTap: () async {
                if (await hasInternetConnection()) {
                  final response = await Supabase.instance.client
                      .from('categories')
                      .select('id')
                      .eq('name', category['name'])
                      .maybeSingle();
                  if (response != null && response['id'] != null) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryProductsScreen(
                          categoryId: response['id'],
                          categoryName: category['name'],
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No products found in ${category['name']}.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No internet connection.', textAlign: TextAlign.center)),
                  );
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  // Add this new helper for colored category items
  Widget _buildDrawerCategory({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green, size: 28),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.green.withOpacity(0.08),
      onTap: onTap,
    );
  }

  void _updateWishlistCount() {
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    setState(() {
      _wishlistCount = wishlistProvider.wishlist.length;
    });
  }
} 