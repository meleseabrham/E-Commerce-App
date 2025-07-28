import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  RealtimeChannel? _notificationChannel;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
    _fetchNotifications();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    if (_notificationChannel != null) {
      Supabase.instance.client.removeChannel(_notificationChannel!);
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final data = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _fetchNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Fetch user profile to check if admin
    final userProfile = await Supabase.instance.client
        .from('users')
        .select('is_admin')
        .eq('id', user.id)
        .single();
    List notifications;
    if (userProfile != null && userProfile['is_admin'] == true) {
      // Admin: fetch all notifications (or filter by admin_id if you want)
      notifications = await Supabase.instance.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
    } else {
      // User: fetch only their notifications
      notifications = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
    }
    setState(() {
      _notifications = List<Map<String, dynamic>>.from(notifications);
      _unreadCount = _notifications.where((n) => n['read'] == false).length;
    });
  }

  void _subscribeToNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Fetch user profile to check if admin
    final userProfile = await Supabase.instance.client
        .from('users')
        .select('is_admin')
        .eq('id', user.id)
        .single();
    if (userProfile != null && userProfile['is_admin'] == true) {
      // Admin: subscribe to all notifications
      _notificationChannel = Supabase.instance.client
          .channel('public:notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              setState(() {
                _unreadCount += 1;
              });
              _fetchNotifications();
            },
          )
          .subscribe();
    } else {
      // User: subscribe to their notifications only
      _notificationChannel = Supabase.instance.client
          .channel('public:notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              column: 'user_id',
              value: user.id,
              type: PostgresChangeFilterType.eq,
            ),
            callback: (payload) {
              setState(() {
                _unreadCount += 1;
              });
              _fetchNotifications();
            },
          )
          .subscribe();
    }
  }

  Future<void> _markNotificationRead(String notificationId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
    _fetchNotifications();
  }

  Future<void> _markAllNotificationsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
    setState(() {
      _unreadCount = 0;
    });
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                tooltip: 'Notifications',
                onPressed: () async {
                  await _markAllNotificationsRead();
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
        ],
      ),
      body: Column(
        children: [
          if (_notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      return ListTile(
                        title: Text(n['message'] ?? ''),
                        subtitle: Text(n['created_at'] ?? ''),
                        trailing: n['is_read'] == true ? null : Icon(Icons.fiber_new, color: Colors.red),
                        onTap: () => _markNotificationRead(n['id']),
                      );
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }
                final orders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    final items = order['items'] is String
                        ? []
                        : (order['items'] as List<dynamic>?);
                    final firstItem = items != null && items.isNotEmpty ? items[0] : null;
                    final orderDate = order['orderDate'] ?? order['created_at'];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final purchaseOrder = PurchaseOrder.fromMap(order);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(order: purchaseOrder),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  _buildStatusPill(order['status'] ?? 'PENDING'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (firstItem != null) ...[
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        firstItem['imageUrl'] ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            firstItem['name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatPrice(firstItem['price']),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                _formatDate(orderDate),
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = Colors.orange.shade200;
        break;
      case 'COMPLETED':
        color = Colors.green.shade200;
        break;
      case 'CANCELLED':
        color = Colors.red.shade200;
        break;
      default:
        color = Colors.grey.shade300;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final dt = date is DateTime ? date : DateTime.tryParse(date.toString());
    if (dt == null) return '';
    return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    try {
      final p = price is num ? price : double.parse(price.toString());
      return ' 24${p.toStringAsFixed(2)}';
    } catch (_) {
      return '';
    }
  }
} 