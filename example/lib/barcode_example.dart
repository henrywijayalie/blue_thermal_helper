import 'package:blue_thermal_helper/blue_thermal_helper.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Contoh penggunaan Barcode & QR Code di Blue Thermal Helper
/// Mendemonstrasikan berbagai use case barcode/QR code yang praktis

class BarcodeExamples {
  /// Example 1: Simple QR Code
  /// 
  /// Use case: Cetak QR code untuk URL/tracking dengan mudah
  static Future<List<int>> simpleQRCode() async {
    final receipt = await ThermalReceipt.create();
    
    receipt.text('QR CODE EXAMPLE', center: true, bold: true);
    receipt.feed(1);
    
    // QR code untuk URL
    receipt.qrcode('https://github.com/henrywijayalie/blue_thermal_helper');
    
    receipt.feed(2);
    receipt.text('Scan to visit GitHub', size: FontSize.small, center: true);
    receipt.feed(2);
    receipt.cut();
    
    return receipt.build();
  }

  /// Example 2: Invoice dengan QR Code
  /// 
  /// Use case: Billing/invoice dengan QR code untuk tracking/payment
  static Future<List<int>> invoiceWithQRCode() async {
    final receipt = await ThermalReceipt.create(paper: PaperSize.mm58);
    
    // Header
    receipt.text('INVOICE', size: FontSize.header, bold: true, center: true);
    receipt.feed(1);
    receipt.hr();
    
    // Invoice details
    receipt.rowLabel('Invoice No', 'INV-2026-000123');
    receipt.rowLabel('Date', '2026-02-03');
    receipt.rowLabel('Customer', 'PT. Maju Jaya');
    receipt.feed(1);
    receipt.hr();
    
    // Items
    receipt.text('Items', bold: true);
    receipt.row('Product A', 'Rp 150.000');
    receipt.row('Product B', 'Rp 200.000');
    receipt.row('Service Fee', 'Rp 25.000');
    receipt.hr();
    
    receipt.rowLabel('Total', 'Rp 375.000', size: FontSize.medium, bold: true);
    receipt.feed(2);
    
    // QR Code untuk tracking
    receipt.text('Tracking QR Code', size: FontSize.small, center: true);
    receipt.qrcode(
      'https://example.com/invoice/INV-2026-000123',
      fallbackText: 'INV-2026-000123',
    );
    
    receipt.feed(2);
    receipt.cut();
    
    return receipt.build();
  }

  /// Example 3: Product Label dengan EAN-13
  /// 
  /// Use case: Label produk retail dengan barcode EAN-13
  static Future<List<int>> productLabelWithEAN13() async {
    final receipt = await ThermalReceipt.create(paper: PaperSize.mm58);
    
    receipt.text('PRODUCT LABEL', size: FontSize.medium, bold: true);
    receipt.feed(1);
    
    // Product info
    receipt.rowLabel('Product', 'Coffee Maker Pro');
    receipt.rowLabel('Brand', 'TechBrew');
    receipt.rowLabel('Price', 'Rp 1.299.000');
    receipt.rowLabel('Stock', '45 units');
    
    receipt.feed(2);
    
    // EAN-13 Barcode (contoh: 5901234123457)
    receipt.text('EAN-13 Code', size: FontSize.small, center: true);
    receipt.barcode(
      BarcodeData.ean13(
        '5901234123457',
        height: 4,
        withLabel: true,
      ),
    );
    
    receipt.feed(2);
    receipt.cut();
    
    return receipt.build();
  }

  /// Example 4: Receipt dengan Multiple Barcodes
  /// 
  /// Use case: Receipt dengan berbagai tipe barcode untuk berbagai keperluan
  static Future<List<int>> receiptWithMultipleBarcodes() async {
    final receipt = await ThermalReceipt.create();
    
    // Header
    receipt.text('PAYMENT RECEIPT', size: FontSize.header, center: true, bold: true);
    receipt.feed(1);
    receipt.hr();
    
    // Transaction details
    receipt.rowLabel('Transaction ID', 'TRX-2026-004567');
    receipt.rowLabel('Amount', 'Rp 500.000');
    receipt.rowLabel('Method', 'QRIS/Transfer');
    receipt.rowLabel('Date', '2026-02-03 14:30');
    
    receipt.feed(2);
    receipt.hr();
    
    // Barcode 1: Order/Receipt code (Code128)
    receipt.text('Order Code', size: FontSize.small, center: true);
    receipt.barcode128('ORD-2026-004567', height: 3);
    
    receipt.feed(2);
    
    // Barcode 2: QR Code untuk payment verification
    receipt.text('Payment Verification QR', size: FontSize.small, center: true);
    receipt.qrcode(
      'https://example.com/verify/TRX-2026-004567',
      fallbackText: 'TRX-2026-004567',
    );
    
    receipt.feed(2);
    receipt.cut();
    
    return receipt.build();
  }

  /// Example 5: Shipping Label dengan QR Code
  /// 
  /// Use case: Shipping/courier label dengan QR untuk tracking
  static Future<List<int>> shippingLabelWithQR() async {
    final receipt = await ThermalReceipt.create(paper: PaperSize.mm80);
    
    // Header
    receipt.text('SHIPPING LABEL', size: FontSize.header, bold: true, center: true);
    receipt.feed(1);
    receipt.hr();
    
    // Shipper info
    receipt.text('FROM', bold: true);
    receipt.text('PT. Penjual Emas');
    receipt.text('Jl. Raya Utama No. 123');
    receipt.text('Jakarta, 12345');
    
    receipt.feed(1);
    receipt.hr();
    
    // Recipient info
    receipt.text('TO', bold: true);
    receipt.text('Budi Santoso');
    receipt.text('Jl. Merdeka No. 456');
    receipt.text('Bandung, 40123');
    
    receipt.feed(2);
    receipt.hr();
    
    // Tracking info
    receipt.rowLabel('Tracking No', 'TRACK-2026-0089123');
    receipt.rowLabel('Service', 'Regular (2-3 hari)');
    receipt.rowLabel('Weight', '2.5 kg');
    
    receipt.feed(2);
    
    // QR Code untuk tracking
    receipt.text('SCAN FOR TRACKING', size: FontSize.medium, bold: true, center: true);
    receipt.qrcode(
      'https://track.example.com/TRACK-2026-0089123',
      size: 10,
      fallbackText: 'TRACK-2026-0089123',
    );
    
    receipt.feed(2);
    receipt.cut();
    
    return receipt.build();
  }

  /// Example 6: Barcode dengan Fallback (Error Handling)
  /// 
  /// Use case: Barcode dengan text fallback jika generate gagal
  static Future<List<int>> barcodeWithFallback() async {
    final receipt = await ThermalReceipt.create();
    
    receipt.text('BARCODE WITH FALLBACK', center: true, bold: true);
    receipt.feed(2);
    
    // QR Code dengan fallback text
    receipt.text('Try scanning this QR Code:', size: FontSize.small);
    receipt.feed(1);
    
    receipt.qrcode(
      'https://example.com/product/advanced-thermal-printer-helper',
      fallbackText: 'https://example.com/product/adv-thermal-helper',
    );
    
    receipt.feed(1);
    receipt.text('If scan fails, use the text below:', size: FontSize.small);
    
    receipt.feed(2);
    receipt.hr();
    
    // Code128 dengan fallback
    receipt.text('Order Code:', size: FontSize.small);
    receipt.barcode128(
      'ORDER-COMPLEX-REF-12345',
      height: 3,
      fallbackText: 'ORDER-COMPLEX-REF-12345',
    );
    
    receipt.feed(2);
    receipt.cut();
    
    return receipt.build();
  }
}

/// Demo function untuk menjalankan semua contoh barcode
// ignore: avoid_print
Future<void> runBarcodeExamples() async {
  // ignore: avoid_print
  print('🔄 Generating Barcode Examples...\n');
  
  try {
    final example1 = await BarcodeExamples.simpleQRCode();
    // ignore: avoid_print
    print('✅ Example 1: Simple QR Code (${example1.length} bytes)');
    
    final example2 = await BarcodeExamples.invoiceWithQRCode();
    // ignore: avoid_print
    print('✅ Example 2: Invoice with QR Code (${example2.length} bytes)');
    
    final example3 = await BarcodeExamples.productLabelWithEAN13();
    // ignore: avoid_print
    print('✅ Example 3: Product Label with EAN-13 (${example3.length} bytes)');
    
    final example4 = await BarcodeExamples.receiptWithMultipleBarcodes();
    // ignore: avoid_print
    print('✅ Example 4: Receipt with Multiple Barcodes (${example4.length} bytes)');
    
    final example5 = await BarcodeExamples.shippingLabelWithQR();
    // ignore: avoid_print
    print('✅ Example 5: Shipping Label with QR (${example5.length} bytes)');
    
    final example6 = await BarcodeExamples.barcodeWithFallback();
    // ignore: avoid_print
    print('✅ Example 6: Barcode with Fallback (${example6.length} bytes)');
    
    // ignore: avoid_print
    print('\n🎉 All examples generated successfully!');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Error: $e');
  }
}
