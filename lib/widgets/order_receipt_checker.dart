import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderReceiptChecker extends StatefulWidget {
  const OrderReceiptChecker({Key? key}) : super(key: key);

  @override
  _OrderReceiptCheckerState createState() => _OrderReceiptCheckerState();
}

class _OrderReceiptCheckerState extends State<OrderReceiptChecker> {
  final _orderIdController = TextEditingController();
  final _orderService = OrderService();
  Order? _order;
  bool _isLoading = false;
  String? _error;

  Future<void> _checkOrder() async {
    if (_orderIdController.text.isEmpty) {
      setState(() => _error = 'Please enter an order ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _order = null;
    });

    try {
      final order = await _orderService.getOrderById(_orderIdController.text);
      setState(() {
        _order = order;
        if (order == null) {
          _error = 'Order not found';
        }
      });
    } catch (e) {
      setState(() => _error = 'Error checking order: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReceipt() async {
    if (_order == null || _order!.receiptUrl == null) return;

    setState(() => _isLoading = true);

    try {
      final receiptPath = await _orderService.downloadReceipt(_order!.id);
      if (receiptPath != null) {
        if (!await launchUrl(Uri.parse(receiptPath))) {
          throw Exception('Could not open receipt');
        }
      } else {
        setState(() => _error = 'Receipt not available');
      }
    } catch (e) {
      setState(() => _error = 'Error downloading receipt: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _orderIdController,
            decoration: InputDecoration(
              labelText: 'Order ID',
              hintText: 'Enter your order ID',
              prefixIcon: const Icon(Icons.receipt_long),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkInputBackground
                  : Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _checkOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Check Order',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
              ),
            ),
          ],
          if (_order != null) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${_order!.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${_order!.date.toString().split(' ')[0]}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Total: \$${_order!.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_order!.receiptUrl != null)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _downloadReceipt,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 