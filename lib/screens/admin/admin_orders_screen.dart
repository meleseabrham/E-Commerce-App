import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_drawer.dart';
import 'dart:convert';
// import 'dart:html' as html; // Only for web, so comment out
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart';
import 'admin_dashboard_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String status;
  const AdminOrdersScreen({Key? key, this.status = 'all'}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;
  late String _filter;
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'status', 'total_desc', 'total_asc'
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  Set<String> _selectedOrderIds = {};
  RealtimeChannel? _ordersChannel;
  bool _adminChecked = false;

  int get _totalOrders => _orders.length;
  double get _totalRevenue => _orders.fold(0.0, (sum, o) => sum + ((o['total'] ?? o['totalAmount'] ?? 0) as num).toDouble());
  int _countByStatus(String status) => _orders.where((o) => o['status'] == status).length;

  @override
  void initState() {
    super.initState();
    _checkAdminAndInit();
  }

  Future<void> _checkAdminAndInit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access denied: Please log in.')),
        );
      });
      return;
    }
    final data = await Supabase.instance.client
        .from('users')
        .select('is_admin')
        .eq('id', user.id)
        .single();
    // Only restrict if this is an admin-only page
    if (data == null || data['is_admin'] != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access denied: Admins only')),
        );
      });
      return;
    }
    _filter = widget.status;
    _fetchOrders();
    _subscribeToOrderEvents();
    setState(() {
      _adminChecked = true;
    });
  }

  @override
  void dispose() {
    if (_ordersChannel != null) {
      Supabase.instance.client.removeChannel(_ordersChannel!);
    }
    super.dispose();
  }

  void _subscribeToOrderEvents() {
    _ordersChannel = Supabase.instance.client
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('New order placed!')),
            );
            _fetchOrders();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order updated!')),
            );
            _fetchOrders();
          },
        )
        .subscribe();
  }

  void _applySearchAndSort() {
    List<Map<String, dynamic>> filtered = _orders;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((order) {
        final user = (order['users']?['full_name'] ?? order['users']?['email'] ?? '').toString().toLowerCase();
        final id = order['id'].toString().toLowerCase();
        final status = (order['status'] ?? '').toString().toLowerCase();
        return user.contains(q) || id.contains(q) || status.contains(q);
      }).toList();
    }
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => (a['created_at'] ?? '').compareTo(b['created_at'] ?? ''));
        break;
      case 'date_desc':
        filtered.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        break;
      case 'status':
        filtered.sort((a, b) => (a['status'] ?? '').compareTo(b['status'] ?? ''));
        break;
      case 'total_asc':
        filtered.sort((a, b) => ((a['total'] ?? 0) as num).compareTo((b['total'] ?? 0) as num));
        break;
      case 'total_desc':
        filtered.sort((a, b) => ((b['total'] ?? 0) as num).compareTo((a['total'] ?? 0) as num));
        break;
    }
    setState(() {
      _filteredOrders = filtered;
    });
  }

  Future<void> _fetchOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      var query = Supabase.instance.client
          .from('orders')
          .select('*, users(full_name, email)');
      if (_filter != 'all') {
        if (_filter == 'pending') {
          query = query.eq('status', 'pending');
        } else if (_filter == 'accepted') {
          query = query.eq('status', 'accepted');
        } else if (_filter == 'rejected') {
          query = query.eq('status', 'rejected');
        } else if (_filter == 'shipped') {
          query = query.eq('status', 'shipped');
        } else if (_filter == 'delivered') {
          query = query.eq('status', 'delivered');
        } else if (_filter == 'cancelled') {
          query = query.eq('status', 'cancelled');
        }
      }
      final from = (_currentPage - 1) * _pageSize;
      final to = from + _pageSize - 1;
      final response = await query.range(from, to).order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _totalCount = _orders.length;
      });
      _applySearchAndSort();
    } catch (e) {
      setState(() { _error = 'Failed to load orders: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _goToPage(int page) {
    setState(() { _currentPage = page; });
    _fetchOrders();
  }

  void _exportToCSV() {
    if (_filteredOrders.isEmpty) return;
    final headers = _filteredOrders.first.keys.toList();
    final rows = [
      headers,
      ..._filteredOrders.map((order) => headers.map((h) => '${order[h] ?? ''}').toList()),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    // TODO: Implement platform-specific export logic
    // Web-only code removed for mobile compatibility
    // if (kIsWeb) {
    //   final blob = html.Blob([bytes]);
    //   final url = html.Url.createObjectUrlFromBlob(blob);
    //   final anchor = html.AnchorElement(href: url)
    //     ..setAttribute('download', 'orders_export.csv')
    //     ..click();
    //   html.Url.revokeObjectUrl(url);
    // } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exporting to CSV is not supported on this platform yet.')),
      );
    // }
  }

  void _toggleSelectOrder(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _toggleSelectAll(bool? selectAll) {
    setState(() {
      if (selectAll == true) {
        _selectedOrderIds = _filteredOrders.map((o) => o['id'].toString()).toSet();
      } else {
        _selectedOrderIds.clear();
      }
    });
  }

  Future<void> _logAudit(String action, String orderId, String details, {String? userId}) async {
    final admin = Supabase.instance.client.auth.currentUser;
    if (admin == null) return;
    await Supabase.instance.client.from('audit_logs').insert({
      'admin_id': admin.id,
      'actor_id': userId ?? admin.id,
      'action': action,
      'order_id': orderId,
      'details': details,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  void _bulkUpdateStatus(String status) async {
    if (_selectedOrderIds.isEmpty) return;
    await Supabase.instance.client
        .from('orders')
        .update({'status': status})
        .inFilter('id', _selectedOrderIds.toList());
    for (final id in _selectedOrderIds) {
      await _logAudit('bulk_update_status', id, 'Bulk status changed to $status');
    }
    _selectedOrderIds.clear();
    _fetchOrders();
  }

  void _exportSelectedToCSV() {
    final selectedOrders = _filteredOrders.where((o) => _selectedOrderIds.contains(o['id'].toString())).toList();
    if (selectedOrders.isEmpty) return;
    final headers = selectedOrders.first.keys.toList();
    final rows = [
      headers,
      ...selectedOrders.map((order) => headers.map((h) => '${order[h] ?? ''}').toList()),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    // TODO: Implement platform-specific export logic
    // Web-only code removed for mobile compatibility
    // if (kIsWeb) {
    //   final blob = html.Blob([bytes]);
    //   final url = html.Url.createObjectUrlFromBlob(blob);
    //   final anchor = html.AnchorElement(href: url)
    //     ..setAttribute('download', 'orders_selected_export.csv')
    //     ..click();
    //   html.Url.revokeObjectUrl(url);
    // } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exporting selected orders to CSV is not supported on this platform yet.')),
      );
    // }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.amber;
        break;
      case 'shipped':
        color = Colors.blue;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
      case 'rejected':
        color = Colors.red;
        break;
      case 'accepted':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }
    return Tooltip(
      message: status[0].toUpperCase() + status.substring(1),
      child: Chip(
        label: Text(status[0].toUpperCase() + status.substring(1)),
        backgroundColor: color,
        labelStyle: TextStyle(color: Colors.white),
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
      await _logAudit('update_status', orderId, 'Status changed to $status', userId: userId);
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
        'type': type,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      }
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateAcceptedOrderStatus(String orderId, String? userId, String status) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
      await _logAudit('update_status', orderId, 'Status changed to $status', userId: userId);
      // Send notification for all status changes
      String message = 'Your order status has been updated to $status.';
      if (userId != null && userId.isNotEmpty) {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'order_id': orderId,
        'type': 'order_status_update',
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      }
      _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        final items = order['items'] is String ? [] : (order['items'] as List<dynamic>?);
        final shipping = order['shipping_address'];
        final payment = order['paymentId'] ?? order['paymentMethod'];
        return AlertDialog(
          title: Text('Order Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${order['id']}', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('User: ${order['users']?['full_name'] ?? order['users']?['email'] ?? ''}'),
                SizedBox(height: 8),
                Text('Status: ${order['status']}'),
                SizedBox(height: 8),
                if (items != null && items.isNotEmpty) ...[
                  Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...items.map((item) => Text('- ${item['name'] ?? ''} x${item['quantity'] ?? ''}')).toList(),
                  SizedBox(height: 8),
                ],
                if (shipping != null) ...[
                  Text('Shipping Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('City: ${shipping['city'] ?? ''}'),
                  Text('Country: ${shipping['country'] ?? ''}'),
                  Text('Address: ${shipping['address_line1'] ?? ''}'),
                  Text('Created: ${shipping['created_at'] ?? ''}'),
                  SizedBox(height: 8),
                ],
                if (payment != null) ...[
                  Text('Payment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(payment.toString()),
                  SizedBox(height: 8),
                ],
                Text('Total: ${order['total'] ?? order['totalAmount'] ?? ''}'),
                SizedBox(height: 16),
                Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  decoration: InputDecoration(hintText: 'Add notes (not saved yet)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: color.withOpacity(0.08),
      child: Container(
        width: 120,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // Add a helper to build each order card
  Widget _buildOrderCard(Map<String, dynamic> order) {
    return InkWell(
      onTap: () => _showOrderDetailsDialog(order),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _selectedOrderIds.contains(order['id'].toString()),
                onChanged: (val) => _toggleSelectOrder(order['id'].toString()),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                child: order['users']?['full_name'] != null
                    ? Text(order['users']['full_name'][0].toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                    : Icon(Icons.person, size: 24, color: Colors.grey[700]),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: order['id'],
                      child: Text(
                        'Order #${order['id'].toString().substring(0, 8)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Tooltip(
                          message: order['users']?['email'] ?? '',
                          child: Text(
                            order['users']?['full_name'] ?? order['users']?['email'] ?? '',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(order['status'] ?? ''),
                        // Add status change icon
                        PopupMenuButton<String>(
                          icon: Icon(Icons.edit, color: Colors.grey[700], size: 20),
                          onSelected: (String newStatus) {
                            _updateOrderStatusAndNotify(
                              order['id'].toString(),
                              order['users']?['id'],
                              newStatus,
                            );
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'pending', child: Text('Pending')),
                            PopupMenuItem(value: 'accepted', child: Text('Accepted')),
                            PopupMenuItem(value: 'shipped', child: Text('Shipped')),
                            PopupMenuItem(value: 'delivered', child: Text('Delivered')),
                            PopupMenuItem(value: 'rejected', child: Text('Rejected')),
                            PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                          ],
                        ),
                        SizedBox(width: 12),
                        Tooltip(
                          message: 'Order Date',
                          child: Text(
                            order['created_at'] != null ? order['created_at'].toString().split('T').first : '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Status: ${order['status']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_adminChecked) return Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: Text('Admin: Orders'),
        actions: [
          Builder(
            builder: (context) {
              final allowedFilters = [
                'all', 'pending', 'accepted', 'rejected', 'shipped', 'delivered', 'cancelled'
              ];
              if (!allowedFilters.contains(_filter)) {
                _filter = 'all';
              }
              return DropdownButton<String>(
                value: _filter,
                items: allowedFilters.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() { _filter = val!; });
                  _fetchOrders();
                },
                dropdownColor: Colors.green[800],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                underline: Container(
                  height: 2,
                  color: Colors.white54,
                ),
                iconEnabledColor: Colors.white,
              );
            },
          ),
        ],
      ),
      drawer: AdminDrawer(selected: '/orders'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            // Mobile: stack vertically or wrap
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildStatCard('Total Orders', _totalOrders.toString(), Icons.list_alt, Colors.blueGrey),
                                _buildStatCard('Revenue', _totalRevenue.toStringAsFixed(2), Icons.attach_money, Colors.green),
                                _buildStatCard('Pending', _countByStatus('pending').toString(), Icons.hourglass_empty, Colors.amber[800]!),
                                _buildStatCard('Accepted', _countByStatus('accepted').toString(), Icons.check_circle, Colors.teal),
                                _buildStatCard('Delivered', _countByStatus('delivered').toString(), Icons.local_shipping, Colors.green[700]!),
                                _buildStatCard('Rejected', _countByStatus('rejected').toString(), Icons.cancel, Colors.red),
                              ],
                            );
                          } else {
                            // Desktop/tablet: horizontal row
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard('Total Orders', _totalOrders.toString(), Icons.list_alt, Colors.blueGrey),
                            _buildStatCard('Revenue', _totalRevenue.toStringAsFixed(2), Icons.attach_money, Colors.green),
                            _buildStatCard('Pending', _countByStatus('pending').toString(), Icons.hourglass_empty, Colors.amber[800]!),
                            _buildStatCard('Accepted', _countByStatus('accepted').toString(), Icons.check_circle, Colors.teal),
                            _buildStatCard('Delivered', _countByStatus('delivered').toString(), Icons.local_shipping, Colors.green[700]!),
                            _buildStatCard('Rejected', _countByStatus('rejected').toString(), Icons.cancel, Colors.red),
                          ],
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _selectedOrderIds.length == _filteredOrders.length && _filteredOrders.isNotEmpty,
                              tristate: true,
                              onChanged: (val) => _toggleSelectAll(val),
                              activeColor: Theme.of(context).colorScheme.primary,
                              checkColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            SizedBox(
                              width: 250, // Adjust as needed for your layout
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search by user, order ID, or status',
                                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                ),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                onChanged: (val) {
                                  setState(() { _searchQuery = val; });
                                  _applySearchAndSort();
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            DropdownButton<String>(
                              value: _sortBy,
                              items: [
                                DropdownMenuItem(value: 'date_desc', child: Text('Newest First')),
                                DropdownMenuItem(value: 'date_asc', child: Text('Oldest First')),
                                DropdownMenuItem(value: 'status', child: Text('Status')),
                                DropdownMenuItem(value: 'total_desc', child: Text('Total (High-Low)')),
                                DropdownMenuItem(value: 'total_asc', child: Text('Total (Low-High)')),
                              ],
                              onChanged: (val) {
                                setState(() { _sortBy = val!; });
                                _applySearchAndSort();
                              },
                              underline: Container(height: 2, color: Theme.of(context).colorScheme.primary),
                              dropdownColor: Theme.of(context).colorScheme.surface,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              iconEnabledColor: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _filteredOrders.isEmpty ? null : _exportToCSV,
                              icon: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                              label: Text('Export CSV', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedOrderIds.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Row(
                            children: [
                              Text('${_selectedOrderIds.length} selected', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                              SizedBox(width: 16),
                              DropdownButton<String>(
                                hint: Text('Bulk Update Status', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                                items: [
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                                  DropdownMenuItem(value: 'shipped', child: Text('Shipped')),
                                  DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                                ],
                                onChanged: (val) {
                                  if (val != null) _bulkUpdateStatus(val);
                                },
                                dropdownColor: Theme.of(context).colorScheme.surface,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                iconEnabledColor: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _exportSelectedToCSV,
                                icon: Icon(Icons.download, color: Theme.of(context).colorScheme.primary),
                                label: Text('Export Selected', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) => _buildOrderCard(_filteredOrders[index]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                            child: Text('Previous'),
                          ),
                          SizedBox(width: 16),
                          Text('Page $_currentPage of ${(_totalCount / _pageSize).ceil().clamp(1, 999)}'),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _currentPage < (_totalCount / _pageSize).ceil() ? () => _goToPage(_currentPage + 1) : null,
                            child: Text('Next'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}