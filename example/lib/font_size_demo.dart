// example/lib/font_size_demo.dart

import 'package:blue_thermal_helper/blue_thermal_helper.dart';

/// Demonstrasi penggunaan FontSize manual dan fitur rowLabel
Future<void> demoFontSizeAndRowLabel(BlueThermalHelper printer) async {
  final receipt = await ThermalReceipt.create();

  // ===== HEADER =====
  receipt.text(
    'CONTOH RECEIPT',
    bold: true,
    center: true,
    size: FontSize.header, // 24pt
  );

  receipt.text(
    'FontSize Manual Demo',
    center: true,
    size: FontSize.large, // 16pt
  );

  receipt.hr();

  // ===== DEMONSTRASI BERBAGAI UKURAN FONT =====
  receipt.text('Demonstrasi Font Size:', bold: true, size: FontSize.large);

  receipt.text('Ini adalah teks 8pt (Small)', size: FontSize.small);
  receipt.text('Ini adalah teks 10pt (Normal)', size: FontSize.normal);
  receipt.text('Ini adalah teks 12pt (Medium)', size: FontSize.medium);
  receipt.text('Ini adalah teks 16pt (Large)', size: FontSize.large);
  receipt.text('Ini adalah teks 20pt (Extra Large)', size: FontSize.extraLarge);
  
  receipt.text(
    'Ini adalah teks custom 14pt',
    size: FontSize(14.0),
  );

  receipt.hr();

  // ===== DEMONSTRASI SMART ROW ALIGNMENT =====
  receipt.text('Smart Row dengan Alignment :', bold: true, size: FontSize.large);
  receipt.feed();

  // Contoh 1: Label pendek
  receipt.rowLabel('Nama Penerima', 'John Doe');
  receipt.rowLabel('Email', 'john@example.com');
  receipt.rowLabel('No. HP', '08123456789');

  receipt.feed();

  // Contoh 2: Label panjang
  receipt.rowLabel('Nomor Referensi', 'TXN-2026-0203-001');
  receipt.rowLabel('Tanggal Transaksi', '2026-02-03');
  receipt.rowLabel('Status', 'BERHASIL');

  receipt.hr();

  // ===== DEMONSTRASI ROW LABEL DENGAN UKURAN FONT BERBEDA =====
  receipt.text('Row Label (Font 12pt):', bold: true, size: FontSize.large);
  receipt.feed();

  receipt.rowLabel('Total Belanja', 'Rp 250.000', size: FontSize.medium);
  receipt.rowLabel('Diskon', '- Rp 25.000', size: FontSize.medium);
  receipt.rowLabel('Ongkir', 'Rp 15.000', size: FontSize.medium);

  receipt.hr();

  receipt.text('Row Label (Font 8pt):', bold: true, size: FontSize.large);
  receipt.feed();

  receipt.rowLabel('Bank', 'BCA', size: FontSize.small);
  receipt.rowLabel('No. Rekening', '123456789', size: FontSize.small);
  receipt.rowLabel('Atas Nama', 'PT Example Corp', size: FontSize.small);

  receipt.hr();

  // ===== DEMONSTRASI PENGHITUNGAN KARAKTER =====
  receipt.text('Info Karakter per Baris:', size: FontSize.small);
  receipt.feed();

  final charsNormal = FontSize.normal.getCharsPerLine58mm();
  final charsLarge = FontSize.large.getCharsPerLine58mm();
  final charsSmall = FontSize.small.getCharsPerLine58mm();

  receipt.rowLabel(
    'Normal (10pt)',
    '$charsNormal chars',
    size: FontSize.small,
  );
  receipt.rowLabel(
    'Large (16pt)',
    '$charsLarge chars',
    size: FontSize.small,
  );
  receipt.rowLabel(
    'Small (8pt)',
    '$charsSmall chars',
    size: FontSize.small,
  );

  receipt.hr();

  // ===== FOOTER =====
  receipt.feed(2);
  receipt.text('Terima Kasih!', center: true, size: FontSize.large);
  receipt.text(
    'Powered by Blue Thermal Helper v2.0',
    center: true,
    size: FontSize.small,
  );

  receipt.cut();

  // Print preview
  // ignore: unused_local_variable
  final preview = receipt.preview();
  // Silently log preview untuk debugging

  // Print actual receipt
  await printer.printReceipt((_) async {
    // Reuse existing receipt atau buat baru
    // ignore: unused_local_variable
    final receipt2 = await ThermalReceipt.create();
    await demoFontSizeAndRowLabel(printer);
  });
}

/// Contoh penggunaan FontSize untuk receipt invoice
Future<void> demoInvoiceWithFontSize(BlueThermalHelper printer) async {
  final receipt = await ThermalReceipt.create();

  // Header dengan font besar
  receipt.text(
    'INVOICE',
    bold: true,
    center: true,
    size: FontSize.header, // 24pt
  );

  receipt.text(
    'PT Example Corp',
    bold: true,
    center: true,
    size: FontSize.large, // 16pt
  );

  receipt.hr();

  // Detail invoice dengan font medium
  receipt.rowLabelCustom(
    'Invoice No',
    'INV-2026-00001',
    labelWidth: 15,
    size: FontSize.medium, // 12pt
  );

  receipt.rowLabelCustom(
    'Tanggal',
    '03 Februari 2026',
    labelWidth: 15,
    size: FontSize.medium,
  );

  receipt.rowLabelCustom(
    'Periode',
    '01 - 28 Februari 2026',
    labelWidth: 15,
    size: FontSize.medium,
  );

  receipt.hr();

  // Informasi pelanggan
  receipt.text('PELANGGAN:', bold: true, size: FontSize.large);
  receipt.rowLabel('Nama', 'John Doe', size: FontSize.normal);
  receipt.rowLabel('Alamat', 'Jl. Contoh No 123', size: FontSize.normal);
  receipt.rowLabel('Kota', 'Jakarta', size: FontSize.normal);
  receipt.rowLabel('No. HP', '0812345678', size: FontSize.normal);

  receipt.hr();

  // Item list dengan font normal
  receipt.text('DETAIL TRANSAKSI:', bold: true, size: FontSize.large);
  receipt.feed();

  receipt.rowItem(qty: 2, name: 'Produk A', price: 50000);
  receipt.rowItem(qty: 1, name: 'Produk B', price: 75000);
  receipt.rowItem(qty: 3, name: 'Produk C', price: 25000);

  receipt.hr();

  // Ringkasan dengan font medium dan label selaras
  receipt.text('RINGKASAN:', bold: true, size: FontSize.large);
  receipt.feed();

  receipt.rowLabel('Subtotal', 'Rp 250.000', size: FontSize.medium);
  receipt.rowLabel('PPN 10%', 'Rp 25.000', size: FontSize.medium);
  receipt.rowLabel('Diskon', '- Rp 15.000', size: FontSize.medium);
  receipt.rowLabel('Total', 'Rp 260.000', size: FontSize.medium, bold: true);

  receipt.hr();

  // Catatan dengan font kecil
  receipt.text('CATATAN:', size: FontSize.small);
  receipt.text('- Pembayaran harus dilakukan dalam 7 hari', size: FontSize.small);
  receipt.text(
    '- Silakan hubungi kami jika ada pertanyaan',
    size: FontSize.small,
  );

  receipt.feed(2);

  // Footer
  receipt.text('Terima Kasih atas Pesanan Anda', center: true, size: FontSize.large);
  receipt.text('www.example.com', center: true, size: FontSize.small);

  receipt.cut();

  // Print
  await printer.printReceipt((_) async {
    // ignore: unused_local_variable
    final receipt2 = await ThermalReceipt.create();
    await demoInvoiceWithFontSize(printer);
  });
}

/// Contoh penggunaan berbagai ukuran font berdasarkan tipe konten
Future<void> demoHierarchicalFontSizes(BlueThermalHelper printer) async {
  final receipt = await ThermalReceipt.create();

  // Level 1: Header utama (24pt)
  receipt.text(
    'TOKO RETAIL',
    bold: true,
    center: true,
    size: FontSize.header, // 24pt
  );

  receipt.hr();

  // Level 2: Subheader (16pt)
  receipt.text('STRUK PEMBELIAN', bold: true, size: FontSize.large); // 16pt
  receipt.feed();

  // Level 3: Informasi penting (12pt)
  receipt.rowLabel('No. Struk', 'STK-001-2026', size: FontSize.medium); // 12pt
  receipt.rowLabel('Jam', '14:30', size: FontSize.medium);
  receipt.rowLabel('Kasir', 'Dina', size: FontSize.medium);

  receipt.hr();

  // Level 4: Konten normal (10pt)
  receipt.text('PRODUK:', bold: true, size: FontSize.normal); // 10pt
  receipt.feed();

  receipt.rowItem(qty: 1, name: 'Beras 10kg', price: 150000, size: FontSize.normal);
  receipt.rowItem(
    qty: 2,
    name: 'Minyak Goreng 2L',
    price: 35000,
    size: FontSize.normal,
  );

  receipt.hr();

  // Level 5: Teks kecil, detail tambahan (8pt)
  receipt.text('CATATAN:', size: FontSize.small); // 8pt
  receipt.text('Tanda terima ini adalah bukti pembayaran', size: FontSize.small);
  receipt.text('Simpan dengan baik untuk proses klaim garansi', size: FontSize.small);

  receipt.cut();

  // Print
  await printer.printReceipt((_) async {
    // ignore: unused_local_variable
    final receipt2 = await ThermalReceipt.create();
    await demoHierarchicalFontSizes(printer);
  });
}
