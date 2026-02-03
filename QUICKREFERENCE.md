// Quick Reference untuk FontSize Manual & Smart Row Alignment

/*
╔════════════════════════════════════════════════════════════════════════════╗
║           QUICK REFERENCE: FontSize Manual & Smart Row Alignment          ║
╚════════════════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════════════════════
SECTION 1: IMPORT DAN BASIC SETUP
═══════════════════════════════════════════════════════════════════════════════

import 'package:blue_thermal_helper/blue_thermal_helper.dart';

// Buat receipt
final receipt = await ThermalReceipt.create();

// Atau dengan paper size spesifik
final receipt = await ThermalReceipt.create(
  paper: PaperSize.mm80,  // Default mm58
);

═══════════════════════════════════════════════════════════════════════════════
SECTION 2: PRESET FONTSIZE (Recommended)
═══════════════════════════════════════════════════════════════════════════════

FontSize.extraSmall  → 6pt  (Untuk teks footer, disclaimer)
FontSize.small       → 8pt  (Untuk detail kecil, keterangan)
FontSize.normal      → 10pt (Default, body text)
FontSize.medium      → 12pt (Info penting, ringkasan)
FontSize.large       → 16pt (Subheading, kategori)
FontSize.extraLarge  → 20pt (Judul section besar)
FontSize.header      → 24pt (Header utama, title besar)

═══════════════════════════════════════════════════════════════════════════════
SECTION 3: CUSTOM FONTSIZE (Untuk Kebutuhan Spesifik)
═══════════════════════════════════════════════════════════════════════════════

FontSize(11.0)   → 11pt custom
FontSize(14.5)   → 14.5pt custom
FontSize(18.0)   → 18pt custom
FontSize(28.75)  → 28.75pt custom (desimal supported)

⚠ BATASAN: 6pt (minimum) hingga 32pt (maximum)

═══════════════════════════════════════════════════════════════════════════════
SECTION 4: METHOD TEXT DASAR
═══════════════════════════════════════════════════════════════════════════════

receipt.text(
  'Hello World',
  size: FontSize.normal,        // opsional, default normal
  bold: false,                  // opsional, default false
  center: false,                // opsional, default false (left)
);

Contoh:
  receipt.text('Header', bold: true, center: true, size: FontSize.header);
  receipt.text('Body text', size: FontSize.normal);
  receipt.text('Footer', size: FontSize.small, center: true);

═══════════════════════════════════════════════════════════════════════════════
SECTION 5: SMART ROW ALIGNMENT - rowLabel() ✨
═══════════════════════════════════════════════════════════════════════════════

receipt.rowLabel(
  String label,
  String value,
  {
    FontSize size = FontSize.normal,
    bool bold = false,
  }
);

FITUR: Otomatis menambahkan padding ke label sehingga tanda ":" selaras vertikal!

Contoh:
  receipt.rowLabel('Nama', 'John Doe');
  receipt.rowLabel('Email', '<john@example.com>');
  receipt.rowLabel('No. Telepon', '08123456789');

Output (tanda : selaras):
  Nama          : John Doe
  Email         : <john@example.com>
  No. Telepon   : 08123456789

═══════════════════════════════════════════════════════════════════════════════
SECTION 6: SMART ROW ALIGNMENT - rowLabelCustom() (Advanced)
═══════════════════════════════════════════════════════════════════════════════

receipt.rowLabelCustom(
  String label,
  String value,
  {
    int labelWidth = 20,                // Kontrol lebar label
    FontSize size = FontSize.normal,
    bool bold = false,
  }
);

Contoh dengan custom width:
  receipt.rowLabelCustom('Bank', 'BCA', labelWidth: 12);
  receipt.rowLabelCustom('No. Rek', '1234567890', labelWidth: 12);
  receipt.rowLabelCustom('Atas Nama', 'PT Example', labelWidth: 12);

═══════════════════════════════════════════════════════════════════════════════
SECTION 7: METHOD ROW KLASIK (Tetap Tersedia)
═══════════════════════════════════════════════════════════════════════════════

receipt.row(
  String left,
  String right,
  {
    bool bold = false,
    FontSize size = FontSize.normal,
  }
);

Catatan: Gunakan rowLabel() untuk hasil yang lebih rapi dengan alignment tanda ":"

═══════════════════════════════════════════════════════════════════════════════
SECTION 8: METHOD ROW ITEMS (Untuk List Produk)
═══════════════════════════════════════════════════════════════════════════════

receipt.rowItem(
  {
    required int qty,
    required String name,
    required num price,
    FontSize size = FontSize.normal,
  }
);

Contoh:
  receipt.rowItem(qty: 1, name: 'Beras 10kg', price: 150000);
  receipt.rowItem(qty: 2, name: 'Minyak 2L', price: 35000);
  receipt.rowItem(qty: 1, name: 'Gula 1kg', price: 18000);

═══════════════════════════════════════════════════════════════════════════════
SECTION 9: METHOD UTILITY
═══════════════════════════════════════════════════════════════════════════════

receipt.hr()              → Horizontal rule (garis)
receipt.feed(n)           → Tambah n baris kosong
receipt.cut()             → Perintah potong kertas

Contoh:
  receipt.hr();
  receipt.feed(2);
  receipt.cut();

═══════════════════════════════════════════════════════════════════════════════
SECTION 10: FORMULA FONT SIZE KE MULTIPLIER
═══════════════════════════════════════════════════════════════════════════════

Internal formula:
  multiplier = (sizeInPoints - 4) / 6 → rounded → clamped 1-4

Contoh:
  6pt  → (6-4)/6  = 0.33 → 0 → clamped to 1 → 1x
  10pt → (10-4)/6 = 1    → 1 → 1x (standard)
  16pt → (16-4)/6 = 2    → 2 → 2x (double)
  24pt → (24-4)/6 = 3.33 → 3 → 3x (triple)
  32pt → (32-4)/6 = 4.67 → 5 → clamped to 4 → 4x (max)

═══════════════════════════════════════════════════════════════════════════════
SECTION 11: KALKULASI JUMLAH KARAKTER
═══════════════════════════════════════════════════════════════════════════════

receipt.getCharsPerLine58mm()
receipt.getCharsPerLine80mm()

Contoh:
  FontSize.normal.getCharsPerLine58mm()  // ~32 karakter
  FontSize.large.getCharsPerLine58mm()   // ~16 karakter
  FontSize.small.getCharsPerLine58mm()   // ~32 karakter

Gunakan untuk dynamic text wrapping!

═══════════════════════════════════════════════════════════════════════════════
SECTION 12: CONTOH RECEIPT LENGKAP (Copy-Paste Ready)
═══════════════════════════════════════════════════════════════════════════════

Future<void> exampleReceipt() async {
  final receipt = await ThermalReceipt.create();

  // Header
  receipt.text(
    'TOKO RETAIL',
    bold: true,
    center: true,
    size: FontSize.header,  // 24pt
  );

  receipt.hr();

  // Detail dengan smart alignment
  receipt.rowLabel('No. Struk', 'STK-001-2026', size: FontSize.medium);
  receipt.rowLabel('Tanggal', '03 Feb 2026', size: FontSize.medium);
  receipt.rowLabel('Kasir', 'Dina', size: FontSize.medium);

  receipt.hr();

  // Produk
  receipt.text('PRODUK:', bold: true, size: FontSize.large);
  receipt.feed();

  receipt.rowItem(qty: 1, name: 'Beras 10kg', price: 150000);
  receipt.rowItem(qty: 2, name: 'Minyak 2L', price: 35000);

  receipt.hr();

  // Total
  receipt.rowLabel(
    'TOTAL',
    'Rp 220.000',
    size: FontSize.medium,
    bold: true,
  );

  receipt.hr();

  // Footer
  receipt.feed(2);
  receipt.text('Terima Kasih!', center: true, size: FontSize.large);
  receipt.text(
    'Powered by Blue Thermal Helper',
    center: true,
    size: FontSize.small,
  );

  receipt.cut();

  // Print
  await BlueThermalHelper.instance.printReceipt((_) async => receipt.build());
}

═══════════════════════════════════════════════════════════════════════════════
SECTION 13: BEST PRACTICES
═══════════════════════════════════════════════════════════════════════════════

✅ DO:
  • Gunakan preset FontSize untuk konsistensi
  • Buat hierarchy font yang jelas (header > body > footer)
  • Gunakan rowLabel() untuk label-value pairs
  • Test di berbagai printer model
  • Gunakan bold untuk highlight informasi penting
  • Center alignment untuk header/footer

❌ DON'T:
  • Jangan gunakan font terlalu kecil (< 8pt = sulit dibaca)
  • Jangan mix terlalu banyak ukuran font (max 4-5 tingkat)
  • Jangan gunakan font besar untuk teks panjang (akan wrap)
  • Jangan assume semua printer support 4x multiplier
  • Jangan lupa receipt.cut() di akhir receipt

═══════════════════════════════════════════════════════════════════════════════
SECTION 14: MIGRASI DARI VERSI LAMA
═══════════════════════════════════════════════════════════════════════════════

LAMA:                           BARU:
ThermalFontSize.extraSmall   → FontSize.extraSmall
ThermalFontSize.small        → FontSize.small
ThermalFontSize.normal       → FontSize.normal
ThermalFontSize.large        → FontSize.large (16pt)
(tidak ada)                  → FontSize.header (24pt BARU)
(tidak ada)                  → FontSize(custom) (BARU!)

Contoh migrasi:
  // LAMA
  receipt.text('Halo', size: ThermalFontSize.large);

  // BARU
  receipt.text('Halo', size: FontSize.large);  // atau FontSize.header untuk 24pt

═══════════════════════════════════════════════════════════════════════════════
SECTION 15: TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════════

Q: Font size tidak berubah di printer?
A: Beberapa printer hanya support size 1-2. Pastikan printer Anda support multiplier lebih besar.

Q: Tanda ":" tidak selaras?
A: Gunakan rowLabel() bukan row(). rowLabel() menambah padding otomatis.

Q: Teks terlalu kecil dan tidak terbaca?
A: Gunakan FontSize.normal (10pt) atau lebih besar. Minimum 8pt untuk readability.

Q: Bagaimana cara mengetahui berapa karakter yang muat?
A: Gunakan fontSize.getCharsPerLine58mm() atau getCharsPerLine80mm()

Q: Bisa pake font lebih kecil dari 6pt?
A: Tidak, 6pt adalah minimum yang diizinkan system.

═══════════════════════════════════════════════════════════════════════════════

Dokumentasi lengkap: Lihat FONTSIZE_GUIDE.md
Contoh code: Lihat example/lib/font_size_demo.dart
Contoh sederhana: Lihat example/lib/font_size_example_simple.dart

*/
