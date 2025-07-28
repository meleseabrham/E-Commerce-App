import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_dashboard_screen.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  late Future<List<Map<String, dynamic>>> _logsFuture;
  String _search = '';
  String _actionFilter = 'all';
  String _entityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
  }

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    // Fetch audit logs
    final logs = await Supabase.instance.client
        .from('audit_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    // For each log, fetch user info for actor_id
    for (final log in logs) {
      final actorId = log['actor_id'];
      if (actorId != null) {
        final userList = await Supabase.instance.client
            .from('users')
            .select('full_name, email, phone')
            .eq('id', actorId)
            .limit(1);
        if (userList != null && userList.isNotEmpty) {
          log['user'] = userList[0];
        }
      }
    }
    return List<Map<String, dynamic>>.from(logs);
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'read':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  void _showAuditLogDetails(BuildContext context, Map<String, dynamic> log) {
    final user = log['user'] ?? {};
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  child: Text(user['full_name'] != null && user['full_name'].isNotEmpty ? user['full_name'][0] : '?', style: TextStyle(fontSize: 24)),
                ),
                title: Text(user['full_name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user['email'] != null) Text(user['email']),
                    if (user['phone'] != null) Text(user['phone']),
                  ],
                ),
              ),
              Divider(),
              Row(
                children: [
                  Chip(
                    label: Text(log['action'] ?? ''),
                    backgroundColor: _actionColor(log['action'] ?? ''),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Entity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(log['entity'] ?? ''),
                  if (log['entity_id'] != null) ...[
                    SizedBox(width: 8),
                    Text('ID: ${log['entity_id']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]
                ],
              ),
              SizedBox(height: 8),
              Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(log['details'] ?? ''),
              SizedBox(height: 8),
              Text('At:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(log['created_at'] ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Logs'),
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
      ),
      drawer: AdminDrawer(selected: '/audit_logs'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading logs: ${snapshot.error}'));
          }
          final logs = snapshot.data ?? [];
          // Filter/search
          final filteredLogs = logs.where((log) {
            final user = log['user'] ?? {};
            final matchesSearch = _search.isEmpty ||
              (user['full_name']?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
              (log['action']?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
              (log['entity']?.toLowerCase().contains(_search.toLowerCase()) ?? false);
            final matchesAction = _actionFilter == 'all' || log['action'] == _actionFilter;
            final matchesEntity = _entityFilter == 'all' || log['entity'] == _entityFilter;
            return matchesSearch && matchesAction && matchesEntity;
          }).toList();

          if (logs.isEmpty) {
            return Center(child: Text('No audit logs found.'));
          }

          // Responsive layout
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search and filter bar
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by user, action, entity',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _search = val),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _actionFilter,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Actions')),
                        DropdownMenuItem(value: 'create', child: Text('Create')),
                        DropdownMenuItem(value: 'update', child: Text('Update')),
                        DropdownMenuItem(value: 'delete', child: Text('Delete')),
                        DropdownMenuItem(value: 'read', child: Text('Read')),
                      ],
                      onChanged: (val) => setState(() => _actionFilter = val!),
                    ),
                    DropdownButton<String>(
                      value: _entityFilter,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Entities')),
                        ...{
                          ...logs.map((l) => l['entity'] ?? '').where((e) => e != null && e != '').toSet()
                        }.map((entity) => DropdownMenuItem<String>(value: entity as String, child: Text(entity.toString()))).toList(),
                      ],
                      onChanged: (val) => setState(() => _entityFilter = val!),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      return ListView.separated(
                        itemCount: filteredLogs.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, i) {
                          final log = filteredLogs[i];
                          final user = log['user'] ?? {};
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(user['full_name'] != null && user['full_name'].isNotEmpty ? user['full_name'][0] : '?'),
                              ),
                              title: Row(
                                children: [
                                  Text(user['full_name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                ],
                              ),
                              subtitle: isMobile
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(log['action'] ?? ''),
                                              backgroundColor: _actionColor(log['action'] ?? ''),
                                              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                                              padding: EdgeInsets.symmetric(horizontal: 6),
                                            ),
                                            SizedBox(width: 8),
                                            Text('on ${log['entity'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        if (log['details'] != null)
                                          Text('Details: ${log['details']}', style: TextStyle(color: Colors.grey[600])),
                                        Text(
                                          log['created_at'] != null
                                              ? 'At: ${log['created_at']}'
                                              : '',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Chip(
                                          label: Text(log['action'] ?? ''),
                                          backgroundColor: _actionColor(log['action'] ?? ''),
                                          labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                                          padding: EdgeInsets.symmetric(horizontal: 6),
                                        ),
                                        SizedBox(width: 8),
                                        Text('on ${log['entity'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                                        if (log['details'] != null) ...[
                                          SizedBox(width: 8),
                                          Text('Details: ${log['details']}', style: TextStyle(color: Colors.grey[600])),
                                        ],
                                        SizedBox(width: 8),
                                        Text(
                                          log['created_at'] != null
                                              ? 'At: ${log['created_at']}'
                                              : '',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                        ),
                                      ],
                                    ),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () => _showAuditLogDetails(context, log),
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
        },
      ),
    );
  }
}