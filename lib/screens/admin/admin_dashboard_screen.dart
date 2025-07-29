import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _notificationCount = 0;
  List<Map<String, dynamic>> _latestNotifications = [];
  RealtimeChannel? _notificationChannel;
  bool _hasShownLoginMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['showLoginSuccess'] == true && !_hasShownLoginMessage) {
        _hasShownLoginMessage = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Welcome to MeHal Gebeya'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
    _fetchAdminNotifications();
    _subscribeToAdminNotifications();
  }

  @override
  void dispose() {
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchAdminNotifications() async {
    final notifications = await Supabase.instance.client
        .from('notifications')
        .select()
        .eq('type', 'new_order')
        .eq('read', false)
        .order('created_at', ascending: false);
    setState(() {
      _latestNotifications = List<Map<String, dynamic>>.from(notifications);
      _notificationCount = _latestNotifications.length;
    });
  }

  void _subscribeToAdminNotifications() {
    _notificationChannel = Supabase.instance.client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            column: 'type',
            value: 'new_order',
            type: PostgresChangeFilterType.eq,
          ),
          callback: (payload) {
            _fetchAdminNotifications();
          },
        )
        .subscribe();
  }

  Future<void> _markAdminNotificationsRead() async {
    await Supabase.instance.client
        .from('notifications')
        .update({'read': true})
        .eq('type', 'new_order')
        .eq('read', false);
    setState(() {
      _notificationCount = 0;
    });
  }

  Future<int> _getCount(String table) async {
    final data = await Supabase.instance.client.from(table).select();
    return (data as List).length;
  }

  void _showOrderDetailsDialog(BuildContext context, String orderId) async {
    final order = await Supabase.instance.client
        .from('orders')
        .select('*, users(email), shipping_address')
        .eq('id', orderId)
        .single();
    final items = order['items'] is String ? [] : (order['items'] as List<dynamic>?);
    final userEmail = order['users']?['email'] ?? '';
    final shipping = order['shipping_address'] ?? {};
    final userId = order['user_id'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Order Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${order['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('User Email: $userEmail'),
                SizedBox(height: 8),
                Text('Shipping Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('City: ${shipping['city'] ?? ''}'),
                Text('Address: ${shipping['address_line1'] ?? ''}'),
                SizedBox(height: 8),
                Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (items != null && items.isNotEmpty)
                  ...items.map((item) => Text('- ${item['name']} x${item['quantity']} ( 24${item['price']})')),
                SizedBox(height: 8),
                Text('Total:  24${order['total'] ?? order['totalAmount'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _updateOrderStatusAndNotify(order['id'], userId, 'accepted');
                Navigator.pop(context);
                _fetchAdminNotifications();
              },
              child: Text('Accept', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () async {
                await _updateOrderStatusAndNotify(order['id'], userId, 'rejected');
                Navigator.pop(context);
                _fetchAdminNotifications();
              },
              child: Text('Reject', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Orders'),
        content: SizedBox(
          width: 400,
          child: _latestNotifications.isEmpty
              ? Text('No new orders.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _latestNotifications.length,
                  itemBuilder: (context, i) {
                    final notification = _latestNotifications[i];
                    return ListTile(
                      leading: Icon(Icons.shopping_cart),
                      title: Text(notification['message'] ?? 'New Order'),
                      subtitle: Text('At: ${notification['created_at']}'),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        // Navigate to orders/all page
                        Navigator.pushNamed(context, '/orders/pending');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _markAdminNotificationsRead();
              Navigator.pop(context);
            },
            child: Text('Mark all as read'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatusAndNotify(String orderId, String? userId, String status) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      // Create notification for all status changes
      String message;
      String type;
      switch (status) {
        case 'accepted':
          message = 'Your order has been accepted!';
          type = 'order_accepted';
          break;
        case 'rejected':
          message = 'Your order was not accepted.';
          type = 'order_rejected';
          break;
        default:
          message = 'Your order status has been updated to $status.';
          type = 'order_status_update';
      }
      if (userId != null && userId.isNotEmpty) {
        await Supabase.instance.client.from('notifications').insert({
          'user_id': userId,
          'order_id': orderId,
          'type': type, // always correct type
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
          'is_read': false,
          'read': false,
        });
      }
      _fetchAdminNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                tooltip: 'New Orders',
                onPressed: _showNotifications,
              ),
              if (_notificationCount > 0)
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
                      '$_notificationCount',
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
          SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Icon(Icons.account_circle, color: Colors.green[800], size: 28),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'profile') {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => _buildProfileSheet(context),
                );
              }  else if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.green),
                  title: Text('Personal Information'),
                ),
              ),
            
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
        ],
      ),
      drawer: AdminDrawer(selected: '/dashboard'),
      body: FutureBuilder(
        future: Future.wait([
          _getCount('products'),
          _getCount('orders'),
          _getCount('users'),
        ]),
        builder: (context, AsyncSnapshot<List<int>> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final [productCount, orderCount, userCount] = snapshot.data!;
          return GridView.count(
            crossAxisCount: 2,
            children: [
             _buildStatCard(context, 'Products', productCount, Icons.shopping_bag, '/products', Colors.deepPurple),
_buildStatCard(context, 'Orders', orderCount, Icons.shopping_cart, '/orders', Colors.green),
_buildStatCard(context, 'Users', userCount, Icons.people, '/users', Colors.blue),
            ],
          );
        },
      ),
    );
  }

 Widget _buildStatCard(BuildContext context, String label, int count, IconData icon, String route, Color color) {
  return GestureDetector(
    onTap: () => Navigator.pushNamed(context, route),
      child: Card(
      elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: color.withOpacity(0.12),
        child: Container(
        width: 240,
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
              radius: 36,
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 16),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileSheet(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.green[100],
                child: Icon(Icons.person, color: Colors.green[800], size: 40),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.userMetadata?['full_name'] ?? 'Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          ListTile(
            leading: Icon(Icons.person, color: Colors.green),
            title: Text('Edit Personal Info'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.pushNamed(context, '/personal_info');
              // After returning, refresh dashboard if needed
            },
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.green),
            title: Text('Change Password'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.pushNamed(context, '/change_password');
              // After returning, refresh dashboard if needed
            },
          ),
         
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditPersonalInfoSheet(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    return FutureBuilder(
      future: Supabase.instance.client
          .from('users')
          .select('full_name, email')
          .eq('id', user!.id)
          .single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data as Map<String, dynamic>?;
        _nameController.text = data?['full_name'] ?? '';
        _emailController.text = data?['email'] ?? '';
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24,
              top: 32,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChangePasswordSheet(BuildContext context) {
    final _oldController = TextEditingController();
    final _newController = TextEditingController();
    final _confirmController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        
      ),
    );
  }
}