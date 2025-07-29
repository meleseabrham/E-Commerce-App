import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDrawer extends StatelessWidget {
  final String selected;
  final int notificationCount;
  const AdminDrawer({required this.selected, this.notificationCount = 0, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(Icons.admin_panel_settings, size: 32, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Dashboard', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              _buildMenuItem(context, '/dashboard', Icons.dashboard, 'Dashboard'),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                ),
                child: ExpansionTile(
                  initiallyExpanded: selected.startsWith('/products'),
                  leading: Icon(Icons.shopping_bag, color: selected.startsWith('/products') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  title: Text(
                    'Products',
                    style: TextStyle(
                      color: selected.startsWith('/products') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected.startsWith('/products') ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    selected.startsWith('/products') ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    _modernDrawerSubItem(
                      context,
                      selected == '/products/available',
                      Icons.check_box,
                      'Available',
                      '/products/available',
                      Colors.green,
                    ),
                    _modernDrawerSubItem(
                      context,
                      selected == '/products/sold',
                      Icons.sell,
                      'Sold',
                      '/products/sold',
                      Colors.red,
                    ),
                  ],
                ),
              ),
              _buildMenuItem(context, '/categories', Icons.category, 'Categories'),
              _buildMenuItem(context, '/users', Icons.people, 'Users'),
            
              // Modernized Orders expandable menu
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                ),
                child: ExpansionTile(
                  initiallyExpanded: selected.startsWith('/orders'),
                  leading: Icon(Icons.shopping_cart, color: selected.startsWith('/orders') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  title: Text(
                    'Orders',
                    style: TextStyle(
                      color: selected.startsWith('/orders') ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected.startsWith('/orders') ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    selected.startsWith('/orders') ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    _modernDrawerSubItem(
                      context,
                      selected == '/orders/all',
                      Icons.list_alt,
                      'All',
                      '/orders/all',
                      Colors.blueGrey,
                    ),
                    _modernDrawerSubItem(
                      context,
                      selected == '/orders/accepted',
                      Icons.check_circle,
                      'Accepted',
                      '/orders/accepted',
                      Theme.of(context).colorScheme.primary,
                    ),
                    _modernDrawerSubItem(
                      context,
                      selected == '/orders/rejected',
                      Icons.cancel,
                      'Rejected',
                      '/orders/rejected',
                      Colors.red,
                    ),
                    _modernDrawerSubItem(
                      context,
                      selected == '/orders/pending',
                      Icons.hourglass_empty,
                      'Pending',
                      '/orders/pending',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              _buildMenuItem(context, '/analytics', Icons.bar_chart, 'Analytics'),
              _buildMenuItem(context, '/audit_logs', Icons.history, 'Audit Logs'),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                hoverColor: Colors.red.withOpacity(0.08),
                onTap: () async {
                  // Sign out the user
                  await Supabase.instance.client.auth.signOut();
                  // Navigate to login page
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String route, IconData icon, String title, {Widget? trailing}) {
    final isSelected = selected == route;
    return ListTile(
      selected: isSelected,
      leading: Icon(icon, color: isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      onTap: () => Navigator.pushReplacementNamed(context, route),
    );
  }

  // Add this helper for modern sub-items
  Widget _modernDrawerSubItem(BuildContext context, bool selected, IconData icon, String title, String route, Color color) {
    return ListTile(
      selected: selected,
      leading: Icon(icon, color: selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      onTap: () => Navigator.pushReplacementNamed(context, route),
    );
  }
} 