import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_dashboard_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.from('categories').select();
      setState(() { _categories = List<Map<String, dynamic>>.from(data); });
    } catch (e) {
      setState(() { _error = 'Failed to load categories: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _addOrEditCategory({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final iconController = TextEditingController(text: category?['icon'] ?? '');
    final isEdit = category != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Category' : 'Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: iconController, decoration: InputDecoration(labelText: 'Icon (emoji or url)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final name = nameController.text.trim();
                final icon = iconController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name is required.')));
                  return;
                }
                if (isEdit) {
                  await Supabase.instance.client.from('categories').update({'name': name, 'icon': icon}).eq('id', category!['id']);
                } else {
                  await Supabase.instance.client.from('categories').insert({'name': name, 'icon': icon});
                }
                Navigator.pop(context);
                _fetchCategories();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client.from('categories').delete().eq('id', id);
        _fetchCategories();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        title: Text('Admin: Categories'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addOrEditCategory(),
            tooltip: 'Add Category',
          ),
        ],
      ),
      drawer: AdminDrawer(selected: '/categories'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      leading: Text(category['icon'] ?? '📦', style: TextStyle(fontSize: 24)),
                      title: Text(category['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _addOrEditCategory(category: category),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(category['id']),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}