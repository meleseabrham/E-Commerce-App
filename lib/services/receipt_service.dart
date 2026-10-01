import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/order.dart';
import 'dart:typed_data';

class ReceiptService {
  static Future<pw.MemoryImage?> _loadLogoImage() async {
    try {
      final byteData = await rootBundle.load('assets/icon/icon.png');
      return pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      try {
        final byteData = await rootBundle.load('assets/logo/animate.png');
        return pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (_) {
        return null;
      }
    }
  }

  static Future<String> generateReceipt(PurchaseOrder order) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogoImage();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark (centered, faint)
              if (logoImage != null)
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
                  if (order.paymentMethod.isNotEmpty)
                    pw.Text('Payment Method: ${order.paymentMethod}'),
                  if (order.paymentId.isNotEmpty)
                    pw.Text('Payment Account: ${order.paymentId}'),
                  pw.Text('Order Status: ${order.status.toUpperCase()}'),
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
              if (logoImage != null)
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
    final logoImage = await _loadLogoImage();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark (centered, faint)
              if (logoImage != null)
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
                  if (order.paymentMethod.isNotEmpty)
                    pw.Text('Payment Method: ${order.paymentMethod}'),
                  if (order.paymentId.isNotEmpty)
                    pw.Text('Payment Account: ${order.paymentId}'),
                  pw.Text('Order Status: ${order.status.toUpperCase()}'),
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
              if (logoImage != null)
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
    // Compute true subtotal from individual items
    final double subtotal = order.items.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );
    final double tax = subtotal * 0.15;
    final double total = subtotal + tax;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildTotalRow('Subtotal:', '\$${subtotal.toStringAsFixed(2)}'),
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
    final y = date.year;
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final mi = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$y-$mo-$d  $h:$mi:$s';
  }

  static Future<void> sendReceiptByEmail(String userEmail, String receiptPath, PurchaseOrder order) async {
    // Placeholder: send receipt by email via backend / SMTP
  }
} 