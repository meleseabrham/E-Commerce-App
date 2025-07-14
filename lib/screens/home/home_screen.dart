import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../../theme/app_colors.dart';
import '../../services/firebase_service.dart';
import '../auth/login_screen.dart';
import '../auth/registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Product> featuredProducts = [
    Product(
      id: 'featured1',
      name: 'Ethiopian Coffee',
      price: 15.99,
      image: 'assets/food/coffee.jpg',
      description: 'Premium Ethiopian coffee beans, freshly roasted.',
    ),
    Product(
      id: 'featured2',
      name: 'Traditional Scarf',
      price: 24.99,
      image: 'assets/cloth/scarf.jpg',
      description: 'Beautiful Ethiopian cotton scarf.',
    ),
    Product(
      id: 'featured3',
      name: 'Cross Pendant',
      price: 89.99,
      image: 'assets/jewelry/jewelry.jpg',
      description: 'Traditional Ethiopian cross pendant.',
    ),
    Product(
      id: 'featured4',
      name: 'Teff Flour',
      price: 12.99,
      image: 'assets/food/teff.jpg',
      description: 'High-quality teff flour for making injera.',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredProducts = featuredProducts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchProducts(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredProducts = featuredProducts;
      } else {
        _filteredProducts = featuredProducts.where((product) {
          return product.name.toLowerCase().contains(query.toLowerCase()) ||
                 product.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
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
            builder: (context, cart, child) => IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
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
                      width: 400,
                      child: LoginScreen(),
                    ),
                  ),
                );
              },
              child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: SizedBox(
                      width: 400,
                      child: RegistrationScreen(),
                    ),
                  ),
                );
              },
              child: const Text('Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.person,),
              onPressed: () => Navigator.pushNamed(context, '/account'),
              tooltip: 'Account',
            ),
            // IconButton(
            //   icon: const Icon(Icons.logout),
            //   onPressed: () async {
            //     await FirebaseService.signOut();
            //     if (mounted) setState(() {});
            //   },
            //   tooltip: 'Logout',
            // ),
          ],
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh logic
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              if (_isSearching)
                _buildSearchResults()
              else
                Column(
                  children: [
                    _buildCategories(),
                    _buildFeaturedProducts(),
                    _buildNewArrivals(),
                  ],
                ),
            ],
          ),
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

  Widget _buildDrawer(BuildContext context, user) {
    return Drawer(
      width: 260,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.zero,
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
          _buildDrawerCategory(
            context,
            icon: Icons.restaurant,
            title: 'Food & Beverages',
            route: '/food',
            color: AppColors.successColor,
          ),
          _buildDrawerCategory(
            context,
            icon: Icons.shopping_bag,
            title: 'Clothing',
            route: '/clothing',
            color: AppColors.secondary,
          ),
          _buildDrawerCategory(
            context,
            icon: Icons.handyman,
            title: 'Handicrafts',
            route: '/handicrafts',
            color: AppColors.warningColor,
          ),
          _buildDrawerCategory(
            context,
            icon: Icons.diamond,
            title: 'Jewelry',
            route: '/jewelry',
            color: AppColors.infoColor,
          ),
          _buildDrawerCategory(
            context,
            icon: Icons.devices,
            title: 'Electronics',
            route: '/electronics',
            color: AppColors.primary,
          ),
          if (user == null) ...[
            _buildDrawerItem(
              context,
              icon: Icons.login,
              title: 'Login',
              route: '/login',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.app_registration,
              title: 'Register',
              route: '/register',
            ),
          ] else ...[
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Account',
              route: '/account',
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseService.signOut();
                if (mounted) setState(() {});
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
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
        Navigator.pushNamed(context, route);
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

  Widget _buildSearchResults() {
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
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            return ProductCard(product: _filteredProducts[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.restaurant, 'name': 'Food', 'route': '/food'},
      {'icon': Icons.shopping_bag, 'name': 'Clothing', 'route': '/clothing'},
      {'icon': Icons.devices, 'name': 'Electronics', 'route': '/electronics'},
      {'icon': Icons.diamond, 'name': 'Jewelry', 'route': '/jewelry'},
      {'icon': Icons.handyman, 'name': 'Crafts', 'route': '/handicrafts'},
      
    ];

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, category['route'] as String),
            child: Container(
              width: 80,
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
                      category['icon'] as IconData,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Featured Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: featuredProducts.length,
          itemBuilder: (context, index) {
            return ProductCard(product: featuredProducts[index]);
          },
        ),
      ],
    );
  }

  Widget _buildNewArrivals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'New Arrivals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featuredProducts.length,
            itemBuilder: (context, index) {
              final product = featuredProducts[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(product.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.green),
            title: const Text('Food & Beverages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/food');
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.green),
            title: const Text('Clothing'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/clothing');
            },
          ),
          ListTile(
            leading: const Icon(Icons.handyman, color: Colors.green),
            title: const Text('Handicrafts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/handicrafts');
            },
          ),
          ListTile(
            leading: const Icon(Icons.diamond, color: Colors.green),
            title: const Text('Jewelry'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/jewelry');
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices, color: Colors.green),
            title: const Text('Electronics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/electronics');
            },
          ),
        ],
      ),
    );
  }

  // Add this new helper for colored category items
  Widget _buildDrawerCategory(
    BuildContext context, {
      required IconData icon,
      required String title,
      required String route,
      required Color color,
    }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: color.withOpacity(0.08),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
} 