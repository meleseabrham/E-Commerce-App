/// Formats a price value as ETB currency.
/// Example: formatETB(244) → "244.00 ETB"
String formatETB(dynamic price) {
  if (price == null) return '0.00 ETB';
  final p = price is num ? price.toDouble() : double.tryParse(price.toString()) ?? 0.0;
  return '${p.toStringAsFixed(2)} ETB';
}
