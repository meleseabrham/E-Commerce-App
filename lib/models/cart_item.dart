import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  double get total => price * quantity;

  Product toProduct() {
    return Product(
      id: productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      description: '', // Since cart items don't store description
      categoryId: '',
      categoryName: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'total': total,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    int? quantity,
    double? price,
    String? imageUrl,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
} 