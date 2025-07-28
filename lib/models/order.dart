import 'cart_item.dart';

class PurchaseOrder {
  final String id;
  final String userId;
  final String userEmail;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String paymentId;
  final DateTime orderDate;
  final String status;

  PurchaseOrder({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentId,
    required this.orderDate,
    this.status = 'pending',
  });

  double get total => totalAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'order_date': orderDate.toIso8601String(),
      'status': status,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    try {
      final itemsList = map['items'];
      List<CartItem> parsedItems = [];
      if (itemsList != null && itemsList is List) {
        parsedItems = itemsList
            .map((item) => item is Map<String, dynamic> ? CartItem.fromMap(item) : CartItem.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
      return PurchaseOrder(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        userEmail: map['user_email']?.toString() ?? '',
        items: parsedItems,
        totalAmount: (map['total_amount'] ?? map['total'] ?? map['totalAmount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: map['payment_method']?.toString() ?? map['paymentMethod']?.toString() ?? '',
        paymentId: map['paymentId']?.toString() ?? map['payment_id']?.toString() ?? '',
        orderDate: map['order_date'] != null
            ? DateTime.tryParse(map['order_date'].toString()) ?? DateTime.now()
            : (map['orderDate'] != null ? DateTime.tryParse(map['orderDate'].toString()) ?? DateTime.now() : DateTime.now()),
        status: map['status']?.toString() ?? 'pending',
      );
    } catch (e) {
      print('Error parsing order: $e');
      return PurchaseOrder(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        userEmail: '',
        items: [],
        totalAmount: 0.0,
        paymentMethod: '',
        paymentId: '',
        orderDate: DateTime.now(),
        status: 'error',
      );
    }
  }
}

class Order {
  final String id;
  final String userId;
  final double total;
  final DateTime date;
  final String status;
  final String? receiptUrl;

  Order({
    required this.id,
    required this.userId,
    required this.total,
    required this.date,
    required this.status,
    this.receiptUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['userId'],
      total: json['total'].toDouble(),
      date: DateTime.parse(json['date']),
      status: json['status'],
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'total': total,
      'date': date.toIso8601String(),
      'status': status,
      'receiptUrl': receiptUrl,
    };
  }
} 