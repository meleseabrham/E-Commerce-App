import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_dashboard_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.from('users').select();
      setState(() { _users = List<Map<String, dynamic>>.from(data); });
    } catch (e) {
      setState(() { _error = 'Failed to load users: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _toggleActive(String id, bool isActive) async {
    try {
      await Supabase.instance.client.from('users').update({'is_active': !isActive}).eq('id', id);
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _toggleAdmin(String id, bool isAdmin) async {
    try {
      await Supabase.instance.client.from('users').update({'is_admin': !isAdmin}).eq('id', id);
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Admin: Users'),
      ),
      drawer: AdminDrawer(selected: '/users'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.person),
                          backgroundColor: Colors.grey[200],
                        ),
                        title: Text(user['full_name'] ?? user['email'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user['email'] != null)
                              Text(user['email'], style: TextStyle(color: Colors.grey[700])),
                            if (user['phone'] != null)
                              Text(user['phone'], style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: user['is_active'] ?? true,
                              onChanged: (val) => _toggleActive(user['id'], user['is_active'] ?? true),
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                            IconButton(
                              icon: Icon(user['is_admin'] == true ? Icons.admin_panel_settings : Icons.person),
                              tooltip: user['is_admin'] == true ? 'Revoke admin' : 'Make admin',
                              onPressed: () => _toggleAdmin(user['id'], user['is_admin'] ?? false),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'reset') {
                                  final email = user['email'];
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Reset Password'),
                                      content: Text('Send password reset email to $email?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text('Send'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    try {
                                      await Supabase.instance.client.auth.resetPasswordForEmail(email);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Password reset email sent!')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to send reset email: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                              ],
                              icon: Icon(Icons.more_vert),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}