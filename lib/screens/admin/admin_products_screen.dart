import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import '../../models/product.dart';
import '../../widgets/admin_drawer.dart';
import 'admin_dashboard_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../product/product_detail_screen.dart';
import '../../utils/error_handler.dart';


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
        _error = ErrorHandler.getErrorMessage(e);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[600]!
            : Colors.grey[300]!,
        ),
      ),
      child: DropdownButton<String?>(
        value: _selectedCategoryId,
        hint: Text(
          'All Categories',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[300]
              : Colors.grey[700],
          ),
        ),
        dropdownColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.white,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
        ),
        underline: Container(), // Remove default underline
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'All Categories',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[700],
              ),
            ),
          ),
          ..._categories.map((cat) => DropdownMenuItem<String?>(
            value: cat['id'],
            child: Text(
              cat['name'],
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              ),
            ),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategoryId = value;
          });
        },
      ),
    );
  }

  Future<void> _addOrEditProduct({Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');

    // Multiple images: first required, up to 4
    final List<File> pendingImages = [];
    final List<String> pendingImageNames = [];
    final List<String> pendingImagePaths = [];
    final List<Uint8List> pendingImageBytes = []; // For web support

    // Existing images (editable)
    List<String> existingImageUrls = List<String>.from(product?.imageUrls ?? []);
    String existingPrimary = product?.imageUrl ?? (existingImageUrls.isNotEmpty ? existingImageUrls.first : '');

    String? selectedCategoryId = product?.categoryId;

    final isEdit = product != null;

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Product' : 'Add Product'),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'],
                      child: Text(cat['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedCategoryId = val;
                    setState(() {});
                  },
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
                TextField(controller: priceController, decoration: InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: stockController, decoration: InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                if (kIsWeb) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Web: Click "Choose Images" to select multiple images, or "Add One" for single images. Drag and drop is also supported.',
                            style: TextStyle(color: Colors.blue[800], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final picked = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: true,
                            withData: true, // Important for web support
                          );
                          if (picked == null) return;
                          
                          for (final f in picked.files) {
                            if (pendingImages.length >= 4) break;
                            
                            if (kIsWeb) {
                              // Web platform: use bytes
                              if (f.bytes != null) {
                                pendingImageBytes.add(f.bytes!);
                                pendingImageNames.add(f.name);
                                // Create a placeholder for web
                                pendingImages.add(File('web_image_${pendingImages.length}'));
                                pendingImagePaths.add('web_image_${pendingImages.length}');
                              }
                            } else {
                              // Mobile platform: use file path
                              if (f.path != null) {
                                pendingImagePaths.add(f.path!);
                                pendingImageNames.add(f.name);
                                pendingImages.add(File(f.path!));
                              }
                            }
                          }
                          
                          // Ensure at most 4
                          while (pendingImages.length > 4) {
                            pendingImages.removeLast();
                            pendingImageNames.removeLast();
                            pendingImagePaths.removeLast();
                            if (kIsWeb) pendingImageBytes.removeLast();
                          }
                          setState(() {});
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error picking images: $e')),
                          );
                        }
                      },
                      child: Text(kIsWeb ? 'Choose Images (max 4)' : 'Pick Images (max 4)'),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final picked = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                              withData: true,
                            );
                            if (picked != null && picked.files.isNotEmpty) {
                              final f = picked.files.first;
                              if (f.bytes != null && pendingImages.length < 4) {
                                pendingImageBytes.add(f.bytes!);
                                pendingImageNames.add(f.name);
                                pendingImages.add(File('web_image_${pendingImages.length}'));
                                pendingImagePaths.add('web_image_${pendingImages.length}');
                                setState(() {});
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error picking image: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add One'),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pendingImages.isEmpty
                            ? 'No image selected'
                            : '${pendingImages.length} selected',
                        overflow: TextOverflow.fade,
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (pendingImages.isNotEmpty)
                  SizedBox(
                    height: 70,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < pendingImages.length; i++) ...[
                            kIsWeb 
                              ? Image.memory(
                                  pendingImageBytes[i],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  pendingImages[i],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                            const SizedBox(width: 4),
                            Text(i == 0 ? 'Primary' : 'Extra'),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (existingImageUrls.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text('Existing images:'),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: existingImageUrls.length,
                          itemBuilder: (context, i) {
                            final url = existingImageUrls[i];
                            final isPrimary = url == existingPrimary;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        existingImageUrls.removeAt(i);
                                        // If primary removed, reset to first or empty
                                        if (isPrimary) {
                                          existingPrimary = existingImageUrls.isNotEmpty ? existingImageUrls.first : '';
                                        }
                                        setState(() {});
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  if (isPrimary)
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: Container(
                                        color: Colors.black54,
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    )
                                  else
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: () {
                                          existingPrimary = url;
                                          setState(() {});
                                        },
                                        child: Container(
                                          color: Colors.black54,
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: const Text('Make primary', style: TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
              try {
                final currentUser = Supabase.instance.client.auth.currentUser;
                if (currentUser == null) {
                  Navigator.pop(dialogContext, 'Please log in to add products.');
                  return;
                }
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final stock = int.tryParse(stockController.text.trim()) ?? 0;

                if (name.isEmpty || price <= 0 || selectedCategoryId == null) {
                  Navigator.pop(dialogContext, 'Name, price, and category are required.');
                  return;
                }
                if (pendingImages.isEmpty && !isEdit) {
                  Navigator.pop(dialogContext, 'Please select at least one image.');
                  return;
                }

                // Upload images if any were selected in this session
                String imageUrl = existingPrimary;
                List<String> imageUrls = List<String>.from(existingImageUrls);
                if (pendingImages.isNotEmpty) {
                  final storage = Supabase.instance.client.storage;
                  final bucket = storage.from('product-images');
                  final List<String> uploadedUrls = [];
                  
                  for (int i = 0; i < pendingImages.length; i++) {
                    final fn = pendingImageNames[i];
                    String contentType = 'image/jpeg';
                    
                    if (kIsWeb) {
                      // Web platform: upload bytes
                      final bytes = pendingImageBytes[i];
                      final storagePath = 'products/${DateTime.now().millisecondsSinceEpoch}_${i}_$fn';
                      
                      await bucket.uploadBinary(
                        storagePath,
                        bytes,
                        fileOptions: FileOptions(
                          cacheControl: '3600',
                          upsert: true,
                          contentType: contentType,
                        ),
                      );
                      
                      String url = bucket.getPublicUrl(storagePath);
                      if (!url.startsWith('http')) {
                        url = await bucket.createSignedUrl(storagePath, 60 * 60 * 24 * 365);
                      }
                      if (!url.startsWith('http')) {
                        throw Exception('Failed to generate image URL');
                      }
                      uploadedUrls.add(url);
                    } else {
                      // Mobile platform: upload file
                      final fp = pendingImagePaths[i];
                      contentType = lookupMimeType(fp) ?? 'application/octet-stream';
                      final storagePath = 'products/${DateTime.now().millisecondsSinceEpoch}_${i}_$fn';
                      
                      await bucket.upload(
                        storagePath,
                        pendingImages[i],
                        fileOptions: FileOptions(
                          cacheControl: '3600',
                          upsert: true,
                          contentType: contentType,
                        ),
                      );
                      
                      String url = bucket.getPublicUrl(storagePath);
                      if (!url.startsWith('http')) {
                        url = await bucket.createSignedUrl(storagePath, 60 * 60 * 24 * 365);
                      }
                      if (!url.startsWith('http')) {
                        throw Exception('Failed to generate image URL');
                      }
                      uploadedUrls.add(url);
                    }
                  }
                  
                  // Merge: prepend new uploads; keep existing afterwards
                  imageUrls = [...uploadedUrls, ...imageUrls];
                  imageUrl = uploadedUrls.isNotEmpty ? uploadedUrls.first : imageUrl;
                }

                Map<String, dynamic>? savedRow;
                if (isEdit) {
                  final updated = await Supabase.instance.client.from('products').update({
                    'name': name,
                    'description': desc,
                    'price': price,
                    'stock': stock,
                    'is_sold': stock <= 0,
                    'image_url': imageUrl,
                    'image_urls': imageUrls,
                    'category_id': selectedCategoryId,
                  }).eq('id', product!.id).select().maybeSingle();
                  savedRow = updated;
                } else {
                  final inserted = await Supabase.instance.client.from('products').insert({
                    'name': name,
                    'description': desc,
                    'price': price,
                    'stock': stock,
                    'is_sold': stock <= 0,
                    'image_url': imageUrl,
                    'image_urls': imageUrls,
                    'category_id': selectedCategoryId,
                  }).select().maybeSingle();
                  savedRow = inserted;
                }
                if (savedRow != null) {
                  Navigator.pop(dialogContext, 'saved');
                } else {
                  Navigator.pop(dialogContext, 'Insert/Update failed.');
                }
              } catch (e) {
                Navigator.pop(dialogContext, ErrorHandler.getErrorMessage(e));
              }

              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (result == 'saved') {
      await _fetchProducts();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(isEdit ? 'Product updated' : 'Product added'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    } else if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(result),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    }
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
        if (mounted) {
          await _fetchProducts();
        }
      } catch (e) {
        if (mounted) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(SnackBar(content: Text('Error: $e')));
        }
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]
        : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]
          : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87,
        elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
        title: Text(
          'Admin: Products',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.green[300]
                : Colors.green[600],
            ),
            onPressed: () => _addOrEditProduct(),
            tooltip: 'Add Product',
          ),
        ],
      ),
      drawer: AdminDrawer(selected: '/products'),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.green[300]
                  : Colors.green[600],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red[300]
                          : Colors.red[600],
                      ),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCategoryDropdown(),
                    ),
                    Expanded(
                      child: _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try changing the category filter or add some products',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isEvenRow = index % 2 == 0;
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: isEvenRow 
                                    ? Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800] // Dark theme even row
                                      : Colors.grey[50]  // Light theme even row
                                    : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[900] // Dark theme odd row
                                      : Colors.white,    // Light theme odd row
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(product: product),
                                      ),
                                    );
                                  },
                                  leading: product.imageUrl.isNotEmpty
                                      ? _buildProductImage(product.imageUrl, width: 50, height: 50)
                                      : Icon(Icons.image, size: 50),
                                  title: Text(
                                    product.name,
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.green[300]
                                            : Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Category: ${product.categoryName ?? "-"}',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Stock: ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                              '${product.stock}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: (product.stock > 0) 
                                              ? Colors.green 
                                              : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.blue[300]
                                            : Colors.blue[600],
                                        ),
                                        onPressed: () => _addOrEditProduct(product: product),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.red[300]
                                            : Colors.red[600],
                                        ),
                                        onPressed: () => _deleteProduct(product.id),
                                      ),
                                    ],
                                  ),
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
