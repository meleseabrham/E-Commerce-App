class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String? categoryId;
  final String? categoryName; // For display only, not stored in DB
  bool isFavorite;
  double averageRating;
  final bool isSold;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.categoryId,
    this.categoryName,
    this.isFavorite = false,
    this.averageRating = 0.0,
    this.isSold = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'description': description,
      'category_id': categoryId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['image_url'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['category_id'],
      categoryName: map['category_name'], // Only if joined in query
      isFavorite: map['isFavorite'] ?? false,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      isSold: map['is_sold'] ?? false,
    );
  }
} 