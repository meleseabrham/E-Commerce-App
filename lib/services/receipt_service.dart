import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';

class ReceiptService {
  static Future<String> generateReceipt(PurchaseOrder order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('MeHal Gebeya', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Receipt', style: pw.TextStyle(fontSize: 24)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Order #${order.id}'),
              pw.Text('Date: ${_formatDate(order.orderDate)}'),
              pw.SizedBox(height: 20),
              pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildItemsTable(order),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _buildTotalSection(order),
              pw.SizedBox(height: 40),
              pw.Text('Thank you for shopping with MeHal Gebeya!'),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${order.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildItemsTable(PurchaseOrder order) {
    return pw.Table.fromTextArray(
      headers: ['Item', 'Quantity', 'Price', 'Total'],
      data: order.items.map((item) => [
        item.name,
        item.quantity.toString(),
        '\$${item.price.toStringAsFixed(2)}',
        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
      ]).toList(),
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  static pw.Widget _buildTotalSection(PurchaseOrder order) {
    final tax = order.totalAmount * 0.15;
    final total = order.totalAmount + tax;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildTotalRow('Subtotal:', '\$${order.totalAmount.toStringAsFixed(2)}'),
        _buildTotalRow('Tax (15%):', '\$${tax.toStringAsFixed(2)}'),
        pw.SizedBox(height: 5),
        _buildTotalRow('Total:', '\$${total.toStringAsFixed(2)}', isBold: true),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            amount,
            style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 