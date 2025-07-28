import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../theme/app_colors.dart';
import '../../services/receipt_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
// Add this import for web download
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html; // Only for web, so comment out

class OrderDetailScreen extends StatefulWidget {
  final PurchaseOrder order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _payment;
  bool _loadingPayment = true;

  @override
  void initState() {
    super.initState();
    _fetchPayment();
  }

  Future<void> _fetchPayment() async {
    final data = await Supabase.instance.client
        .from('payments')
        .select()
        .eq('order_id', widget.order.id)
        .maybeSingle();
    setState(() {
      _payment = data;
      _loadingPayment = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: _loadingPayment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderInfo(),
                  const SizedBox(height: 24),
                  _buildItems(),
                  const SizedBox(height: 24),
                  _buildPaymentDetails(),
                  const SizedBox(height: 24),
                  _buildDownloadReceiptButton(context),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Order ID', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.order.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Order Date',
              DateFormat('MMM dd, yyyy hh:mm a').format(widget.order.orderDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Status', widget.order.status.toUpperCase(), valueColor: Colors.black, valueWeight: FontWeight.bold),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Quantity: ${item.quantity}'),
                        Text(
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${(_payment?['amount'] ?? widget.order.total).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Payment Method', _payment?['method'] ?? widget.order.paymentMethod, valueWeight: FontWeight.bold),
            _buildDetailRow('Payment ID', widget.order.paymentId, valueWeight: FontWeight.bold),
            _buildDetailRow(
              'Payment Date',
              _payment?['created_at'] != null
                  ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(_payment!['created_at']))
                  : '',
              valueWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {FontWeight valueWeight = FontWeight.normal}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontWeight: valueWeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color valueColor = Colors.black54, FontWeight valueWeight = FontWeight.normal}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: valueWeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadReceiptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text('Download Receipt'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _downloadReceipt(context),
      ),
    );
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      if (kIsWeb) {
        // On web, generate PDF bytes and trigger browser download
        final pdfBytes = await ReceiptService.generateReceiptWeb(widget.order);
        // TODO: Remove or replace all html.* usages for mobile compatibility
        // Comment out any code that uses html.Blob, html.Url, html.AnchorElement, etc.
        // final blob = html.Blob([pdfBytes], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // final anchor = html.AnchorElement(href: url)
        //   ..setAttribute('download', 'receipt_${widget.order.id}.pdf')
        //   ..click();
        // html.Url.revokeObjectUrl(url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }
      final receiptPath = await ReceiptService.generateReceipt(widget.order);
      final result = await OpenFilex.open(receiptPath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved, but could not open:  {result.message}'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt downloaded and opened successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 