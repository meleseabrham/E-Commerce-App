import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    try {
      final itemsList = map['items'];
      List<CartItem> parsedItems = [];

      if (itemsList != null && itemsList is List) {
        parsedItems = itemsList
            .whereType<Map<String, dynamic>>()
            .map((item) => CartItem.fromMap(item))
            .toList();
      } else {
        print('Warning: Order items is null or not a List. Using empty list.');
      }

      return PurchaseOrder(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        userEmail: map['userEmail']?.toString() ?? '',
        items: parsedItems,
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: map['paymentMethod']?.toString() ?? '',
        paymentId: map['paymentId']?.toString() ?? '',
        orderDate: map['orderDate'] is Timestamp 
            ? (map['orderDate'] as Timestamp).toDate()
            : DateTime.now(),
        status: map['status']?.toString() ?? 'pending',
      );
    } catch (e) {
      print('Error parsing order: $e');
      // Return an empty order with minimal data to prevent app crashes
      return PurchaseOrder(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
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