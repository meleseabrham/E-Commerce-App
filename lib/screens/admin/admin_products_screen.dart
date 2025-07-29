import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_dashboard_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  final String? filter;
  const AdminProductsScreen({Key? key, this.filter}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId; // null means all

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await Supabase.instance.client.from('categories').select();
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      // Optionally show error
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
        .from('products')
        .select('*, categories(name), is_sold');
      setState(() {
        _products = (data as List).map((e) => Product.fromMap({
          ...e,
          'category_name': e['categories']?['name'],
        })).toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = _products;
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (widget.filter == 'available') {
      filtered = filtered.where((p) => p.isSold != true).toList();
    } else if (widget.filter == 'sold') {
      filtered = filtered.where((p) => p.isSold == true).toList();
    }
    return filtered;
  }

  Widget _buildCategoryDropdown() {
    return DropdownButton<String>(
      value: _selectedCategoryId,
      hint: Text('All Categories'),
      items: [
        DropdownMenuItem(value: null, child: Text('All Categories')),
        ..._categories.map((cat) => DropdownMenuItem(
          value: cat['id'],
          child: Text(cat['name']),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
    );
  }

  Future<void> _addOrEditProduct({Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    String? selectedCategoryId = product?.categoryId;

    final isEdit = product != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
              TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
              TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: imageUrlController, decoration: InputDecoration(labelText: 'Image URL')),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['id'],
                    child: Text(cat['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) => selectedCategoryId = val,
                decoration: InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final imageUrl = imageUrlController.text.trim();

                if (name.isEmpty || price <= 0 || selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name, price, and category are required.')));
                  return;
                }

                if (isEdit) {
                  await Supabase.instance.client.from('products').update({
                    'name': name,
                    'description': desc,
                    'price': price,
                    'image_url': imageUrl,
                    'category_id': selectedCategoryId,
                  }).eq('id', product!.id);
                } else {
                  await Supabase.instance.client.from('products').insert({
                    'name': name,
                    'description': desc,
                    'price': price,
                    'image_url': imageUrl,
                    'category_id': selectedCategoryId,
                  });
                }
                Navigator.pop(context);
                _fetchProducts();
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

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client.from('products').delete().eq('id', id);
        _fetchProducts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
        title: Text('Admin: Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _addOrEditProduct(),
            tooltip: 'Add Product',
          ),
        ],
      ),
      drawer: AdminDrawer(selected: '/products'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildCategoryDropdown(),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return ListTile(
                            leading: product.imageUrl.isNotEmpty
                                ? _buildProductImage(product.imageUrl, width: 50, height: 50)
                                : Icon(Icons.image, size: 50),
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${product.price.toStringAsFixed(2)}'),
                                Text('Category: ${product.categoryName ?? "-"}'),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('is_sold: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    product.isSold == true
                                        ? Chip(label: Text('SOLD', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red)
                                        : Chip(label: Text('Available', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _addOrEditProduct(product: product),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteProduct(product.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
