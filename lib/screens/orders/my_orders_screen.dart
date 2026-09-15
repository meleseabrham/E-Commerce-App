import 'package:flutter/material.dart';
import 'package:mehal_gebeya/utils/app_notify.dart';
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
  int _shippedCount = 0;
  String _statusFilter = 'all'; // all, pending, accepted, shipped, cancelled, rejected, completed

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
    var query = Supabase.instance.client
        .from('orders')
        .select()
        .eq('user_id', user.id);
    if (_statusFilter != 'all') {
      final dbStatus = _statusFilter == 'completed' ? 'delivered' : _statusFilter;
      query = query.eq('status', dbStatus);
    }
    final data = await query.order('created_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(data);
    setState(() {
      _shippedCount = list.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'shipped').length;
    });
    return list;
  }

  Future<void> _fetchNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    // Fetch user profile to check if admin
    final userProfile = await Supabase.instance.client
        .from('users')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();
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
        .maybeSingle();
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
          // Shipped orders badge and sheet trigger
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.local_shipping),
                tooltip: 'Shipped orders',
                onPressed: () async {
                  final orders = await _ordersFuture;
                  final shipped = orders
                      .where((o) => (o['status'] ?? '').toString().toLowerCase() == 'shipped')
                      .toList();
                  if (!mounted) return;
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: shipped.isEmpty
                            ? Center(child: Text('No shipped orders yet.'))
                            : ListView.builder(
                                itemCount: shipped.length,
                                itemBuilder: (context, i) {
                                  final o = shipped[i];
                                  final modalItemsRaw = o['items'];
                                  final List<dynamic> modalItems = modalItemsRaw is List ? modalItemsRaw : [];
                                  return ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: Text('Order #${o['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_formatDate(o['orderDate'] ?? o['created_at'])),
                                        const SizedBox(height: 4),
                                        Text('Total: ${_calculateTotal(modalItems)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () async {
                                        await _markOrderDelivered(o['id'].toString());
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                      },
                                      child: Text('Accept Order'),
                                    ),
                                    children: [
                                      if (modalItems.isNotEmpty)
                                        ...modalItems.map((it) {
                                          final img = it['imageUrl'] ?? it['image'] ?? '';
                                          final name = it['name'] ?? '';
                                          final qty = it['quantity'] ?? 1;
                                          final price = it['price'];
                                          final totalPrice = (price is num ? price : double.tryParse(price.toString()) ?? 0) * qty;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    img,
                                                    width: 52,
                                                    height: 52,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      width: 52,
                                                      height: 52,
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.image, color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 2),
                                                      Text('Qty: $qty', style: const TextStyle(color: Colors.grey)),
                                                      Text('Price: ${_formatPrice(price)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  _formatPrice(totalPrice),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                   
                                    ],
                                  );
                                },
                              ),
                      );
                    },
                  );
                },
              ),
              if (_shippedCount > 0)
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
                      '$_shippedCount',
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
          // Existing notifications icon remains
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
         
          // Filter dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                  DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _statusFilter = val;
                    _ordersFuture = _fetchOrders();
                  });
                },
              ),
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
                              if (items != null && items.isNotEmpty) ...[
                                ...items.map((it) {
                                  final img = it['imageUrl'] ?? '';
                                  final name = it['name'] ?? '';
                                  final qty = it['quantity'] ?? 1;
                                  final price = it['price'];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            img,
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
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 4),
                                              Text('Qty: $qty', style: const TextStyle(color: Colors.grey)),
                                              Text('Price: ${_formatPrice(price)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(order['total']),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                const Divider(),
                              ],
                              Text(
                                _formatDate(orderDate),
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              if ((order['status'] ?? '').toString().toLowerCase() == 'pending')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () async {
                                      await _cancelOrder(order['id'].toString());
                                    },
                                    child: const Text('Cancel Order'),
                                  ),
                                ),
                              if ((order['status'] ?? '').toString().toLowerCase() == 'shipped')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    onPressed: () async {
                                      await _markOrderDelivered(order['id'].toString());
                                    },
                                    child: const Text('Accept Order'),
                                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    Color bg;
    Color fg;
    final label = status.toUpperCase() == 'DELIVERED' ? 'COMPLETED' : status.toUpperCase();
    switch (status.toUpperCase()) {
      case 'PENDING':
        bg = isDark ? Colors.amber.withOpacity(0.25) : Colors.amber.shade200;
        fg = isDark ? Colors.amber : Colors.orange.shade800;
        break;
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'DELIVERED':
        bg = isDark ? Colors.green.withOpacity(0.25) : Colors.green.shade200;
        fg = isDark ? Colors.greenAccent : Colors.green.shade800;
        break;
      case 'REJECTED':
      case 'CANCELLED':
        bg = isDark ? Colors.red.withOpacity(0.25) : Colors.red.shade200;
        fg = isDark ? Colors.redAccent : Colors.red.shade800;
        break;
      default:
        bg = isDark ? Colors.grey.withOpacity(0.25) : Colors.grey.shade300;
        fg = theme.colorScheme.onSurface;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: fg),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final dt = date is DateTime ? date : DateTime.tryParse(date.toString());
    if (dt == null) return '';
    return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
  }

  Widget _buildFilterChip(String key, String label) {
    final bool selected = _statusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          setState(() {
            _statusFilter = key;
            _ordersFuture = _fetchOrders();
          });
        },
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    try {
      final p = price is num ? price : double.parse(price.toString());
      return '${p.toStringAsFixed(2)}';
    } catch (_) {
      return '';
    }
  }

  String _calculateTotal(List<dynamic> items) {
    double total = 0;
    for (final item in items) {
      final price = item['price'];
      final qty = item['quantity'] ?? 1;
      if (price != null) {
        final p = price is num ? price : double.tryParse(price.toString()) ?? 0;
        total += p * qty;
      }
    }
    return _formatPrice(total);
  }

  Future<void> _markOrderDelivered(String orderId) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'delivered',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('notifications').insert({
          'user_id': user.id,
          'order_id': orderId,
          'type': 'order_status_update',
          'message': 'You marked your order as delivered.',
          'created_at': DateTime.now().toIso8601String(),
          'read': false,
          'is_read': false,
        });
      }
      setState(() {
        _ordersFuture = _fetchOrders();
      });
      if (mounted) {
        AppNotify.error(context, ' Your Order Accepted.');
      }
    } catch (e) {
      if (mounted) {
        AppNotify.error(context, 'Failed to update: $e');
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('status', 'pending');
      setState(() {
        _ordersFuture = _fetchOrders();
      });
      if (mounted) {
        AppNotify.error(context, ' Your Order Cancelled.');
      }
    } catch (e) {
      if (mounted) {
        AppNotify.error(context, 'Failed to cancel: $e');
      }
    }
  }
} 