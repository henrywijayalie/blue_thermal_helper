// example/lib/font_size_example_simple.dart

import 'package:flutter/material.dart';

/// Contoh Sederhana: Menggunakan FontSize Manual

class FontSizeExampleSimple extends StatelessWidget {
  const FontSizeExampleSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FontSize Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== CONTOH 1: Berbagai Ukuran Font =====
          const SectionTitle('1. Berbagai Ukuran FontSize'),
          ExampleCard(
            title: 'Preset FontSize',
            code: '''
receipt.text('6pt - Extra Small', size: FontSize.extraSmall);
receipt.text('8pt - Small', size: FontSize.small);
receipt.text('10pt - Normal', size: FontSize.normal);
receipt.text('12pt - Medium', size: FontSize.medium);
receipt.text('16pt - Large', size: FontSize.large);
receipt.text('24pt - Header', size: FontSize.header);
receipt.text('Custom 14pt', size: FontSize(14.0));
            ''',
            description: 'Gunakan preset untuk konsistensi visual',
          ),

          // ===== CONTOH 2: Smart Row Alignment =====
          const SectionTitle('2. Smart Row Alignment dengan Tanda ":"'),
          ExampleCard(
            title: 'rowLabel()',
            code: '''
receipt.rowLabel('Nama Pelanggan', 'John Doe');
receipt.rowLabel('Email', 'john@example.com');
receipt.rowLabel('No. HP', '0812345678');

// Output:
// Nama Pelanggan : John Doe
// Email          : john@example.com
// No. HP         : 0812345678
            ''',
            description: 'Tanda ":" akan selaras otomatis vertikal',
          ),

          // ===== CONTOH 3: Receipt Sederhana =====
          const SectionTitle('3. Receipt Lengkap Sederhana'),
          ExampleCard(
            title: 'Complete Receipt Example',
            code: '''
final receipt = await ThermalReceipt.create();

// Header
receipt.text('TOKO SAYA', 
  bold: true, center: true, size: FontSize.header);

receipt.hr();

// Detail dengan smart row
receipt.rowLabel('No. Struk', 'STK-001');
receipt.rowLabel('Tanggal', '2026-02-03');

receipt.hr();

// Items
receipt.text('PRODUK:', bold: true, size: FontSize.large);
receipt.rowItem(qty: 1, name: 'Produk A', price: 50000);
receipt.rowItem(qty: 2, name: 'Produk B', price: 25000);

receipt.hr();

// Total
receipt.rowLabel('Total', 'Rp 100.000',
  size: FontSize.medium, bold: true);

receipt.cut();

await printer.printReceipt((_) => receipt.build());
            ''',
            description: 'Contoh receipt yang siap digunakan',
          ),

          // ===== CONTOH 4: Font Size dengan Kondisi =====
          const SectionTitle('4. Dynamic FontSize berdasarkan Kondisi'),
          ExampleCard(
            title: 'Conditional FontSize',
            code: '''
// Gunakan font lebih kecil jika teks panjang
final label = 'Label yang Sangat Panjang Sekali';
final fontSize = label.length > 20 
  ? FontSize.small  // 8pt untuk label panjang
  : FontSize.normal; // 10pt normal

receipt.rowLabel(label, 'Value', size: fontSize);
            ''',
            description: 'Sesuaikan ukuran berdasarkan panjang teks',
          ),

          // ===== CONTOH 5: Hierarchy Font yang Jelas =====
          const SectionTitle('5. Hierarchy Font yang Jelas'),
          ExampleCard(
            title: 'Clear Visual Hierarchy',
            code: '''
// Level 1: Utama (24pt)
receipt.text('INVOICE', bold: true, center: true,
  size: FontSize.header);

// Level 2: Subheader (16pt)
receipt.text('Detail Invoice', bold: true,
  size: FontSize.large);

// Level 3: Info penting (12pt)
receipt.rowLabel('No. Invoice', 'INV-001',
  size: FontSize.medium);

// Level 4: Body text (10pt)
receipt.text('Produk:', size: FontSize.normal);

// Level 5: Keterangan kecil (8pt)
receipt.text('* Berlaku sampai akhir tahun',
  size: FontSize.small);
            ''',
            description: 'Struktur visual yang mudah dibaca',
          ),

          // ===== CONTOH 6: Kalkulasi Karakter =====
          const SectionTitle('6. Menghitung Karakter per Baris'),
          ExampleCard(
            title: 'Dynamic Text Wrapping',
            code: '''
final fontSize = FontSize.large; // 16pt

// Hitung berapa karakter yang muat
int charsPerLine = fontSize.getCharsPerLine58mm();
// Hasil: ~16 karakter untuk 16pt di paper 58mm

// Gunakan untuk wrap teks otomatis
final text = 'Lorem ipsum dolor sit amet...';
final maxChars = fontSize.getCharsPerLine58mm();
final lines = wrapText(text, maxChars);

for (final line in lines) {
  receipt.text(line, size: fontSize);
}
            ''',
            description: 'Jangan perlu manual count karakter lagi',
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }
}

class ExampleCard extends StatelessWidget {
  final String title;
  final String code;
  final String description;

  const ExampleCard({
    super.key,
    required this.title,
    required this.code,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            // Code
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                code.trim(),
                style: TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
