import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orders/my_orders_screen.dart';
import 'change_password_screen.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import '../account/address_book_screen.dart'; // Use relative import
import '../../models/product.dart';
import 'personal_info_screen.dart'; // <-- Add this import

Widget buildProductImage(String imageUrl, {double width = 50, double height = 50}) {
  if (imageUrl.startsWith('http')) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: width, color: Colors.grey),
    );
  } else {
    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: width, color: Colors.grey),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _notificationsEnabled = true;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _loadUserProfile();
    _fetchWishlistCount();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      setState(() {
        _userProfile = data;
        _isLoading = false;
        _nameController.text = data['full_name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      });
    } catch (e) {
      final errorStr = e.toString();
      if (mounted) {
        if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup') || errorStr.contains('No address associated')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No internet connection. Please check your connection and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load profile. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        }
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('users').update({
        'full_name': _nameController.text,
        'phone': _phoneController.text,
      }).eq('id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('My Account')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = Supabase.instance.client.auth.currentUser;
    final isAdmin = _userProfile?['is_admin'] == true;
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
        actions: [
         
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            SizedBox(height: 20),
            Text(
              _userProfile?['full_name'] ?? 'User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            // Personal Information Card
            _buildMenuCard(
              icon: Icons.person,
              title: 'Personal Information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonalInfoScreen(),
                  ),
                );
              },
            ),
            // Change Password Card
            _buildMenuCard(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(),
                  ),
                );
              },
            ),
            // My Orders Card
            _buildMenuCard(
              icon: Icons.shopping_bag,
              title: 'My Orders',
              onTap: () {
                Navigator.pushNamed(context, '/my_orders');
              },
            ),
            // Settings Card
            _buildMenuCard(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              },
              child: Text('Log Out'),
            ),
            // if (isAdmin) ...[
            //   SizedBox(height: 20),
            //   ElevatedButton.icon(
            //     icon: Icon(Icons.admin_panel_settings),
            //     label: Text('Admin Dashboard'),
            //     onPressed: () {
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(builder: (context) => AccountAdminDashboardScreen()),
            //       );
            //     },
            //   ),
            // ],
            SizedBox(height: 20),
            // If AddressBookScreen is not defined, comment out or replace with a placeholder
            // ElevatedButton.icon(
            //   icon: Icon(Icons.location_on),
            //   label: Text('Manage Addresses'),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => AddressBookScreen()),
            //     );
            //   },
            // ),
           
            SizedBox(height: 30),
            Divider(),
           
            // If you want to show order history here, use a FutureBuilder or remove this block
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _showPersonalInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Personal Information')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Full Name', _userProfile?['fullName'] ?? 'Not set'),
                _buildInfoRow('Email', _userProfile?['email'] ?? 'Not set'),
                _buildInfoRow('Phone', _userProfile?['phone'] ?? 'Not set'),
                _buildInfoRow('Date of Birth', _userProfile?['dateOfBirth'] ?? 'Not set'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMyOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyOrdersScreen(),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    String orderId,
    String date,
    String amount,
    String status,
    String imagePath,
    String productName,
  ) {
    Color statusColor = status == 'Delivered' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(date),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amount,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(status),
                  backgroundColor: statusColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Product> _wishlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('wishlist')
        .select('product_id')
        .eq('user_id', user.id);
    final productIds = data.map((e) => e['product_id']).toList();
    if (productIds.isEmpty) {
      setState(() {
        _wishlist = [];
        _isLoading = false;
      });
      return;
    }
    final productsData = await Supabase.instance.client
        .from('products')
        .select()
        .inFilter('id', productIds);
    setState(() {
      _wishlist = List<Map<String, dynamic>>.from(productsData)
          .map((map) => Product.fromMap({...map, 'isFavorite': true}))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _removeFromWishlist(Product product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('wishlist')
        .delete()
        .eq('user_id', user.id)
        .eq('product_id', product.id);
    _fetchWishlist();
  }

  Future<void> _addToCart(Product product) async {
    // You may want to use your CartProvider here
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart!')),
    );
    // Optionally remove from wishlist after adding to cart
    await _removeFromWishlist(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Wishlist')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _wishlist.isEmpty
              ? Center(child: Text('No favorites yet.'))
              : ListView.builder(
                  itemCount: _wishlist.length,
                  itemBuilder: (context, i) {
                    final product = _wishlist[i];
                    return ListTile(
                      leading: buildProductImage(product.imageUrl, width: 50, height: 50),
                      title: Text(product.name),
                      subtitle: Text(product.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.favorite),
                            tooltip: 'Remove from Wishlist',
                            onPressed: () => _removeFromWishlist(product),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_shopping_cart),
                            tooltip: 'Add to Cart',
                            onPressed: () => _addToCart(product),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class AccountAdminDashboardScreen extends StatefulWidget {
  const AccountAdminDashboardScreen({super.key});

  @override
  State<AccountAdminDashboardScreen> createState() => _AccountAdminDashboardScreenState();
}

class _AccountAdminDashboardScreenState extends State<AccountAdminDashboardScreen> {
  int _tabIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        bottom: TabBar(
          onTap: (i) => setState(() => _tabIndex = i),
          tabs: [
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
            Tab(text: 'Users'),
          ],
          controller: TabController(length: 3, vsync: ScaffoldState()),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('products').select('*, is_sold'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        return Stack(
          children: [
            ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return ListTile(
                  leading: _buildProductImage(p['image'], width: 50, height: 50),
                  title: Text(p['name'] ?? ''),
                  subtitle: Text(p['description'] ?? ''),
                  onTap: () => _showProductDialog(context, product: p),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await Supabase.instance.client.from('products').delete().eq('id', p['id']);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showProductDialog(context),
                child: Icon(Icons.add),
                tooltip: 'Add Product',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descController = TextEditingController(text: product?['description'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final categoryController = TextEditingController(text: product?['category'] ?? '');
    final imageController = TextEditingController(text: product?['image'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
              TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
              TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Category')),
              TextField(controller: imageController, decoration: InputDecoration(labelText: 'Image URL or asset path')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'description': descController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'category': categoryController.text,
                'image': imageController.text,
              };
              if (product == null) {
                await Supabase.instance.client.from('products').insert(data);
              } else {
                await Supabase.instance.client.from('products').update(data).eq('id', product['id']);
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(product == null ? 'Add' : 'Save'),
          ),
        ],
      ),


    );
  }

  Widget _buildOrdersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('orders').select(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            final o = orders[i];
            return ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text('Order #${o['id']?.toString().substring(0, 8) ?? ''}'),
              subtitle: Text('Total: ${o['totalAmount'] ?? ''}'),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('users').select(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];
            return ListTile(
              leading: Icon(Icons.person),
              title: Text(u['email'] ?? ''),
              subtitle: Text(u['full_name'] ?? ''),
            );
          },
        );
      },
    );
  }

  Widget _buildProductImage(String imageUrl, {double width = 50, double height = 50}) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: width, color: Colors.grey),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: width, color: Colors.grey),
      );
    }
  }
} 