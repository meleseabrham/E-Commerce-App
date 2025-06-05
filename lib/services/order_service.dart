import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class OrderService {
  static const String baseUrl = 'meleseabrham90@gmail.com'; // Replace with your actual API URL

  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load order');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String?> downloadReceipt(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/receipt'),
        headers: {'Content-Type': 'application/pdf'},
      );

      if (response.statusCode == 200) {
        // Handle PDF download and saving
        // Return the local path where the PDF is saved
        return 'path/to/saved/receipt.pdf';
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Error downloading receipt: $e');
    }
  }
} 