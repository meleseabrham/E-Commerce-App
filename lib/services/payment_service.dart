import '../models/order.dart';
import 'receipt_service.dart';

class PaymentService {
  static Future<bool> processPayment(PurchaseOrder order, String userEmail) async {
    try {
      // Process payment logic here
      // This is a placeholder for your actual payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // After successful payment, generate and send receipt
      final receiptPath = await ReceiptService.generateReceipt(order);
      await ReceiptService.sendReceiptByEmail(userEmail, receiptPath, order);
      
      return true;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }
} 