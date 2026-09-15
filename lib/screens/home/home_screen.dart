import 'package:flutter/material.dart';
import 'package:mehal_gebeya/utils/app_notify.dart';
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
import '../../utils/error_handler.dart';


const List<Map<String, dynamic>> kStaticCategories = [

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
  bool _hasShownLoginMessage = false;
  List<Map<String, dynamic>> _categories = [];
  int _shippedCount = 0;
  RealtimeChannel? _ordersChannel;

  @override
  void initState() {
    super.initState();
    _fetchWishlistCount();
    _fetchUnreadNotifications();
    _subscribeToNotifications();
    _fetchShippedCount();
    _subscribeToShippedOrders();
    _fetchCategories();
    // Listen to wishlist changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      wishlistProvider.addListener(_updateWishlistCount);
    });
    // No need to set _filteredProducts = featuredProducts
  }

  Future<void> _fetchCategories() async {
    try {
      // Fetch all categories
      final cats = await Supabase.instance.client
          .from('categories')
          .select('id, name, icon')
          .order('name');

      // Fetch category ids from products that are available (unsold)
      final productCategoryRows = await Supabase.instance.client
          .from('products')
          .select('category_id')
          .eq('is_sold', false);

      // Build a Set of category ids that have at least one available product
      final Set<String> nonEmptyCategoryIds = {
        for (final row in productCategoryRows as List)
          if ((row['category_id'] ?? '').toString().isNotEmpty)
            row['category_id'].toString(),
      };

      // Filter categories to only those present in nonEmptyCategoryIds
      final filtered = (cats as List)
          .where((c) => nonEmptyCategoryIds.contains(c['id'].toString()))
          .toList();

      setState(() {
        _categories = List<Map<String, dynamic>>.from(filtered);
      });
    } catch (_) {
      // Keep static fallback on failure
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    if (_ordersChannel != null) {
      Supabase.instance.client.removeChannel(_ordersChannel!);
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
    if (args is Map && args['showLoginSuccess'] == true && !_hasShownLoginMessage) {
      _hasShownLoginMessage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNotify.success(context, 'Login successful! Welcome to MeHal Gebeya');
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

  Future<void> _fetchShippedCount() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final data = await Supabase.instance.client
        .from('orders')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'shipped');
    setState(() {
      _shippedCount = (data as List).length;
    });
  }

  void _subscribeToShippedOrders() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _ordersChannel = Supabase.instance.client
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(column: 'user_id', value: userId, type: PostgresChangeFilterType.eq),
          callback: (payload) {
            _fetchShippedCount();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(column: 'user_id', value: userId, type: PostgresChangeFilterType.eq),
          callback: (payload) {
            _fetchShippedCount();
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
      AppNotify.error(context, ErrorHandler.getErrorMessage(e));
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (user != null)
            Row(
              children: [
                // Shipped orders badge (truck icon)
                // Stack(
                //   children: [
                //     IconButton(
                //       icon: Icon(Icons.local_shipping),
                //       tooltip: 'Shipped orders',
                //       onPressed: () {
                //         Navigator.pushNamed(context, '/my_orders');
                //       },
                //     ),
                //     if (_shippedCount > 0)
                //       Positioned(
                //         right: 8,
                //         top: 8,
                //         child: Container(
                //           padding: EdgeInsets.all(4),
                //           decoration: BoxDecoration(
                //             color: Colors.red,
                //             shape: BoxShape.circle,
                //           ),
                //           constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                //           child: Text(
                //             '$_shippedCount',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 12,
                //               fontWeight: FontWeight.bold,
                //             ),
                //             textAlign: TextAlign.center,
                //           ),
                //         ),
                //       ),
                //   ],
                // ),
                // Notifications badge (bell icon)
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
                          ),
                        ),
                      ),
                  ],
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
                  builder: (context) => const Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.all(24),
                    child: LoginScreen(),
                  ),
                );
              },
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.all(24),
                    child: RegistrationScreen(),
                  ),
                );
              },
              child: const Text('Register', style: TextStyle(color: Colors.white)),
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
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkInputBackground
                      : Colors.white,
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
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      ErrorHandler.getErrorMessage(snapshot.error!),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );

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
                                            AppNotify.error(context, 'Login to save your wishlist!');
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
                      return Center(child: Text('No internet connection.'));
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
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to exit the app?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result ?? false;
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
                ...(_categories.isNotEmpty ? _categories : kStaticCategories).map((category) {
                  return _buildDrawerCategory(
                    context: context,
                    icon: null,
                    iconWidget: _buildCategoryIcon(category['icon'], color: Colors.green),
                    title: category['name'],
                    onTap: () async {
                      if (await hasInternetConnection()) {
                        final categoryId = category['id'];
                        if (categoryId != null) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryId: categoryId,
                                categoryName: category['name'],
                              ),
                            ),
                          );
                        } else {
                          AppNotify.error(context, 'No products found in ${category['name']}.');
                        }
                      } else {
                        AppNotify.error(context, 'No internet connection.');
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
        itemCount: (_categories.isNotEmpty ? _categories : kStaticCategories).length,
        itemBuilder: (context, index) {
          final list = _categories.isNotEmpty ? _categories : kStaticCategories;
          final category = list[index];
          return GestureDetector(
            onTap: () async {
              if (await hasInternetConnection()) {
                final categoryId = category['id'];
                if (categoryId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(
                        categoryId: categoryId,
                        categoryName: category['name'],
                      ),
                    ),
                  );
                } else {
                  AppNotify.error(context, 'No products found in ${category['name']}.');
                }
              } else {
                AppNotify.error(context, 'No internet connection.');
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkInputBackground
                          : Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _buildCategoryIcon(category['icon'], size: iconSize, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      category['name'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : Colors.black87,
                      ),
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
    final list = _categories.isNotEmpty ? _categories : kStaticCategories;
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final category = list[index];
                  return ListTile(
                    leading: _buildCategoryIcon(category['icon'], color: Colors.green),
                    title: Text(category['name'] ?? ''),
                    onTap: () async {
                      if (await hasInternetConnection()) {
                        final categoryId = category['id'];
                        if (categoryId != null) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryId: categoryId,
                                categoryName: category['name'],
                              ),
                            ),
                          );
                        } else {
                          AppNotify.error(context, 'No products found in ${category['name']}.');
                        }
                      } else {
                        AppNotify.error(context, 'No internet connection.');
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new helper for colored category items
  Widget _buildCategoryIcon(dynamic icon, {double size = 24, Color? color}) {
    if (icon is IconData) {
      return Icon(icon, color: color, size: size);
    }
    if (icon is String) {
      if (icon.startsWith('http')) {
        return SizedBox(width: size, height: size, child: Image.network(icon, fit: BoxFit.contain));
      }
      // treat as emoji
      return Text(icon, style: TextStyle(fontSize: size));
    }
    return Icon(Icons.category, color: color, size: size);
  }
  Widget _buildDrawerCategory({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: iconWidget ?? Icon(icon ?? Icons.category, color: Colors.green, size: 28),
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