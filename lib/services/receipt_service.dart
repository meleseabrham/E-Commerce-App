import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/order.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:pdf/widgets.dart' show BarcodeWidget, Barcode;

class ReceiptService {
  static Future<String> generateReceipt(PurchaseOrder order) async {
    final pdf = pw.Document();

    // Download logo from remote URL
    final logoUrl = 'https://lpndjssicpcnssmngqln.supabase.co/storage/v1/object/sign/mehalgebeya/assets/logo/icon.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yMjMyMzlhYy1jM2IwLTQ5ZDEtYmQzYS0wYzg4NWMwNDkxZmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJtZWhhbGdlYmV5YS9hc3NldHMvbG9nby9pY29uLnBuZyIsImlhdCI6MTc1Mjc0NDMzMSwiZXhwIjoxNzg0MjgwMzMxfQ.xwoHp7O4wHLcijjE-d7UNmvWMR-pUTeE7Ax07dkEbP4';
    final response = await http.get(Uri.parse(logoUrl));
    final logoImage = pw.MemoryImage(response.bodyBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark (centered, faint)
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.08,
                    child: pw.Image(logoImage, width: 400, height: 400, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              // QR code (bottom left)
              pw.Positioned(
                left: 20,
                bottom: 30,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: order.id,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              // Main content
              pw.Column(
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
              ),
              // Seal (bottom right)
              pw.Positioned(
                bottom: 30,
                right: 30,
                child: pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey, width: 2),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
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

  static Future<Uint8List> generateReceiptWeb(PurchaseOrder order) async {
    final pdf = pw.Document();

    // Download logo from remote URL
    final logoUrl = 'https://lpndjssicpcnssmngqln.supabase.co/storage/v1/object/sign/mehalgebeya/assets/logo/icon.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yMjMyMzlhYy1jM2IwLTQ5ZDEtYmQzYS0wYzg4NWMwNDkxZmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJtZWhhbGdlYmV5YS9hc3NldHMvbG9nby9pY29uLnBuZyIsImlhdCI6MTc1Mjc0NDMzMSwiZXhwIjoxNzg0MjgwMzMxfQ.xwoHp7O4wHLcijjE-d7UNmvWMR-pUTeE7Ax07dkEbP4';
    final response = await http.get(Uri.parse(logoUrl));
    final logoImage = pw.MemoryImage(response.bodyBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark (centered, faint)
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.08,
                    child: pw.Image(logoImage, width: 400, height: 400, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              // QR code (bottom left)
              pw.Positioned(
                left: 0,
                bottom: 30,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: order.id,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              // Main content
              pw.Column(
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
              ),
              // Seal (bottom right)
              pw.Positioned(
                bottom: 30,
                right: 30,
                child: pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue, width: 0.5),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
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