# FontSize Manual & Smart Row Alignment - Dokumentasi

Versi terbaru Blue Thermal Helper (v2.0) memperkenalkan sistem **FontSize Manual** yang fleksibel dan fitur **Smart Row Alignment** untuk tanda `:` yang selaras sempurna.

## FontSize Manual

Sistem FontSize memungkinkan Anda menentukan ukuran teks secara spesifik menggunakan satuan **point (pt)**, mirip dengan Microsoft Word atau text editor lainnya.

### Rentang Ukuran Supported

- **Minimum**: 6pt
- **Maximum**: 32pt
- **Fleksibel**: Semua nilai desimal antara 6pt-32pt didukung

### Penggunaan Dasar

#### 1. Menggunakan Preset FontSize

```dart
import 'package:blue_thermal_helper/blue_thermal_helper.dart';

final receipt = await ThermalReceipt.create();

// Preset standar tersedia
receipt.text('ExtraSmall - 6pt', size: FontSize.extraSmall);
receipt.text('Small - 8pt', size: FontSize.small);
receipt.text('Normal - 10pt', size: FontSize.normal);
receipt.text('Medium - 12pt', size: FontSize.medium);
receipt.text('Large - 16pt', size: FontSize.large);
receipt.text('ExtraLarge - 20pt', size: FontSize.extraLarge);
receipt.text('Header - 24pt', size: FontSize.header);
```

#### 2. Menggunakan Custom FontSize

```dart
// Custom size dengan nilai pt spesifik
receipt.text('Custom 14pt', size: FontSize(14.0));
receipt.text('Custom 18pt', size: FontSize(18.5));
receipt.text('Custom 22pt', size: FontSize(22.0));
```

#### 3. Kombinasi dengan Bold dan Center

```dart
receipt.text(
  'Bold Header',
  size: FontSize.header,
  bold: true,
  center: true,
);
```

### Konversi Otomatis ke ESC/POS

FontSize secara otomatis menghitung multiplier yang tepat untuk printer thermal:

```
6pt  → 1x (width: 1, height: 1)
10pt → 1x (width: 1, height: 1) - standar
16pt → 2x (width: 2, height: 2) - double
24pt → 3x (width: 3, height: 3) - triple
32pt → 4x (width: 4, height: 4) - quad (max)
```

Formula internal: `multiplier = (sizeInPoints - 4) / 6`

### Perhitungan Jumlah Karakter per Baris

FontSize menyediakan method untuk menghitung berapa banyak karakter yang dapat ditampilkan:

```dart
final fontSize = FontSize.normal; // 10pt

// Untuk paper 58mm
int chars58 = fontSize.getCharsPerLine58mm(); // Hasil: ~32 karakter

// Untuk paper 80mm
int chars80 = fontSize.getCharsPerLine80mm(); // Hasil: ~48 karakter

// Contoh dengan font berbeda
int charsLarge = FontSize.large.getCharsPerLine58mm(); // Hasil: ~16 karakter
int charsSmall = FontSize.small.getCharsPerLine58mm(); // Hasil: ~32 karakter
```

### Method-Method FontSize

```dart
final size = FontSize(14.0);

// Mendapatkan width multiplier (1-4)
int widthMul = size.getWidthMultiplier();

// Mendapatkan height multiplier (1-4)
int heightMul = size.getHeightMultiplier();

// Menghitung karakter per baris untuk 58mm
int chars58 = size.getCharsPerLine58mm();

// Menghitung karakter per baris untuk 80mm
int chars80 = size.getCharsPerLine80mm();

// Menghitung pixel width untuk 58mm
int pixels58 = size.getPixelWidth58mm();

// Menghitung pixel width untuk 80mm
int pixels80 = size.getPixelWidth80mm();

// String representation
print(size); // "14.0 pt" atau "Medium (12.0 pt)" untuk preset
```

## Smart Row Alignment dengan Tanda ":"

Fitur baru ini memungkinkan Anda membuat baris dengan tanda `:` yang selaras sempurna vertikal, mirip dengan fitur alignment di text editor profesional.

### Metode: `rowLabel()`

```dart
receipt.rowLabel(
  String label,
  String value, {
  FontSize size = FontSize.normal,
  bool bold = false,
}
```

#### Contoh Penggunaan

```dart
// Alignment otomatis untuk tanda ":"
receipt.rowLabel('Nama Pelanggan', 'John Doe');
receipt.rowLabel('Email', 'john@example.com');
receipt.rowLabel('No. HP', '08123456789');
```

**Output:**

```
Nama Pelanggan : John Doe
Email          : john@example.com
No. HP         : 08123456789
```

Perhatikan bagaimana tanda `:` selaras vertikal! Padding ditambahkan otomatis berdasarkan label terpanjang.

#### Contoh dengan FontSize Berbeda

```dart
// Header dengan font besar
receipt.text('DETAIL TRANSAKSI:', bold: true, size: FontSize.large);

// Detail dengan font medium
receipt.rowLabel('No. Invoice', 'INV-2026-00001', size: FontSize.medium);
receipt.rowLabel('Tanggal', '03 Februari 2026', size: FontSize.medium);
receipt.rowLabel('Status', 'LUNAS', size: FontSize.medium);

// Keterangan dengan font kecil
receipt.feed();
receipt.rowLabel('Pesan', 'Terima kasih atas pembelian Anda', size: FontSize.small);
```

### Metode: `rowLabelCustom()`

Untuk kontrol lebih presisi terhadap lebar label:

```dart
receipt.rowLabelCustom(
  String label,
  String value, {
  int labelWidth = 20,
  FontSize size = FontSize.normal,
  bool bold = false,
}
```

#### Contoh

```dart
// Tentukan lebar label custom
receipt.rowLabelCustom('Bank', 'BCA', labelWidth: 15);
receipt.rowLabelCustom('No. Rekening', '123456789', labelWidth: 15);
receipt.rowLabelCustom('Atas Nama', 'PT Example Corp', labelWidth: 15);
```

**Output:**

```
Bank           : BCA
No. Rekening   : 123456789
Atas Nama      : PT Example Corp
```

## Contoh Kasus Penggunaan Lengkap

### 1. Receipt Pembelian Hierarki Jelas

```dart
final receipt = await ThermalReceipt.create();

// Level 1: Judul utama (24pt)
receipt.text('TOKO RETAIL', bold: true, center: true, size: FontSize.header);

receipt.hr();

// Level 2: Subheading (16pt)
receipt.text('STRUK PEMBELIAN', bold: true, size: FontSize.large);
receipt.feed();

// Level 3: Info penting (12pt)
receipt.rowLabel('No. Struk', 'STK-001-2026', size: FontSize.medium);
receipt.rowLabel('Kasir', 'Dina', size: FontSize.medium);

receipt.hr();

// Level 4: Konten normal (10pt)
receipt.rowItem(qty: 1, name: 'Beras 10kg', price: 150000);
receipt.rowItem(qty: 2, name: 'Minyak 2L', price: 35000);

receipt.hr();

// Level 5: Catatan kecil (8pt)
receipt.text('Simpan struk ini sebagai bukti pembelian', size: FontSize.small);

receipt.cut();
```

### 2. Invoice dengan Alignment Tanda ":"

```dart
final receipt = await ThermalReceipt.create();

receipt.text('INVOICE', bold: true, center: true, size: FontSize.header);
receipt.hr();

// Detail dengan alignment
receipt.rowLabel('No. Invoice', 'INV-2026-00001');
receipt.rowLabel('Tanggal', '03 Feb 2026');
receipt.rowLabel('Jatuh Tempo', '10 Feb 2026');

receipt.hr();

receipt.text('PELANGGAN:', bold: true, size: FontSize.large);
receipt.rowLabel('Nama', 'John Doe', size: FontSize.normal);
receipt.rowLabel('Alamat', 'Jl. Contoh No 123', size: FontSize.normal);
receipt.rowLabel('No. HP', '08123456789', size: FontSize.normal);

receipt.hr();

// Ringkasan dengan medium font
receipt.rowLabel('Subtotal', 'Rp 250.000', size: FontSize.medium);
receipt.rowLabel('Pajak', 'Rp 25.000', size: FontSize.medium);
receipt.rowLabel('Total', 'Rp 275.000', size: FontSize.medium, bold: true);

receipt.cut();
```

### 3. Receipt Berdasarkan FontSize Dynamic

```dart
// Hitung font size berdasarkan panjang receipt
final labelNormal = 'Nama Penerima';
final labelLong = 'Nomor Referensi Transaksi Panjang';

// Tentukan size berdasarkan kebutuhan
final size = labelLong.length > 20 ? FontSize.small : FontSize.normal;

receipt.rowLabel('Nama Penerima', 'John Doe', size: size);
receipt.rowLabel('Nomor Referensi Transaksi Panjang', '123456789', size: size);
```

## Integration dengan ThermalPaperHelper

Kita dapat menggabungkan FontSize dengan utility dari ThermalPaperHelper:

```dart
// Dapatkan jumlah karakter yang bisa ditampilkan untuk ukuran font tertentu
final paper = ThermalPaper.mm58;
final fontSize = FontSize.large;

final charsPerLine = ThermalPaperHelper.charsPerLineWithFont(paper, fontSize);
print('Karakter per baris (16pt, 58mm): $charsPerLine'); // Output: ~16

// Gunakan untuk dynamic text wrapping
final maxChars = ThermalPaperHelper.charsPerLineWithFont(paper, fontSize);
final wrappedLines = wrapText(longText, maxChars);
```

## Migrasi dari Versi Lama

Jika Anda menggunakan versi lama dengan `ThermalFontSize` enum, ikuti konversi ini:

| Lama (Enum) | Baru (FontSize) | Nilai Point |
|---|---|---|
| `ThermalFontSize.extraSmall` | `FontSize.extraSmall` | 6pt |
| `ThermalFontSize.small` | `FontSize.small` | 8pt |
| `ThermalFontSize.normal` | `FontSize.normal` | 10pt |
| `ThermalFontSize.large` | `FontSize.large` atau `FontSize.header` | 16pt atau 24pt |

**Sebelum:**

```dart
receipt.text('Halo', size: ThermalFontSize.large);
```

**Sesudah:**

```dart
receipt.text('Halo', size: FontSize.large); // atau FontSize.header untuk 24pt
```

## Tips & Best Practices

1. **Gunakan Preset untuk Konsistensi**
   - Gunakan preset FontSize (small, normal, large) untuk konsistensi visual
   - Custom size hanya untuk kebutuhan khusus

2. **Hierarchy Font yang Jelas**
   - Header: 24pt (FontSize.header)
   - Subheader: 16pt (FontSize.large)
   - Body: 10pt (FontSize.normal)
   - Detail/Note: 8pt (FontSize.small)

3. **Manfaatkan Smart Row**
   - Gunakan `rowLabel()` untuk label-value pairs yang rapi
   - Tanda `:` akan otomatis selaras

4. **Test dengan Multiple Printer Models**
   - ESC/POS multiplier 4x tidak didukung oleh semua printer
   - Fallback otomatis ke multiplier maksimum yang didukung

5. **Perhatikan Jumlah Karakter**
   - Gunakan `getCharsPerLine58mm()` atau `getCharsPerLine80mm()` untuk text wrapping
   - Hindari teks yang terlalu panjang untuk ukuran font besar

## Troubleshooting

**Q: Font size tidak berubah di printer**
A: Periksa apakah printer mendukung perubahan ukuran font. Beberapa printer hanya mendukung size 1 dan 2.

**Q: Tanda `:` tidak selaras**
A: Pastikan menggunakan `rowLabel()` atau `rowLabelCustom()`, bukan `row()` biasa.

**Q: Text terlalu kecil dan tidak terbaca**
A: Gunakan FontSize.normal (10pt) atau lebih besar untuk keterbacaan optimal.

**Q: Ingin font yang lebih kecil dari 6pt**
A: Tidak didukung - 6pt adalah minimum. Gunakan teks yang lebih ringkas atau kurangi item list.

---

Semoga dokumentasi ini membantu! Untuk pertanyaan lebih lanjut, silakan buka issue di repository GitHub.
