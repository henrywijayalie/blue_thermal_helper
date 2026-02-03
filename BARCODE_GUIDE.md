---
title: Panduan Barcode & QR Code
language: id
version: 2.1.0
last_updated: 2026-02-03
---

# Panduan Barcode & QR Code Generation

Fitur barcode dan QR code memungkinkan Anda untuk generate dan mencetak berbagai format barcode ke thermal printer dengan mudah dan fleksibel.

## 📋 Daftar Isi

1. [Pengenalan](#pengenalan)
2. [Tipe Barcode yang Didukung](#tipe-barcode-yang-didukung)
3. [Basic Usage](#basic-usage)
4. [API Reference](#api-reference)
5. [Contoh Praktis](#contoh-praktis)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Pengenalan

Barcode dan QR code adalah cara yang efisien untuk:

- Menyimpan informasi produk atau nomor referensi
- Memudahkan scanning dengan smartphone atau scanner khusus
- Meningkatkan tracking dan inventory management
- Memberikan pengalaman pelanggan yang modern

Library ini mendukung **7 tipe barcode** dengan konfigurasi yang fleksibel.

## Tipe Barcode yang Didukung

| Tipe | Nama | Penggunaan | Data | Catatan |
|------|------|-----------|------|---------|
| Code128 | Code 128 | Default barcode | Teks/angka | Paling fleksibel |
| EAN13 | EAN-13 | Produk retail | 13 digit | Standard internasional |
| EAN8 | EAN-8 | Produk kecil | 8 digit | Versi singkat EAN13 |
| Code39 | Code 39 | Industri/logistik | A-Z, 0-9, spesial | Older standard |
| UPCA | UPC-A | Produk USA | 12 digit | Format barcode lama |
| Codabar | Codabar | Perpustakaan/medis | Spesifik | Jarang digunakan |
| QRCode | QR Code | URL/data kompleks | Apapun | Dapat discan smartphone |

### Karakteristik Barcode

```
┌─ Barcode Standar ─┐
│                   │
│  ║█║█ ║ █║█║ │    │  ← Stripe pattern
│  INVOICE-001      │     (jika withLabel: true)
│                   │
└───────────────────┘

┌─── QR Code ───┐
│ ██████████    │
│ ██      ██    │
│ ██  ██  ██    │
│ ██      ██    │
│ ██████████    │  ← Square, dapat handle banyak data
│               │
└───────────────┘
```

## Basic Usage

### 1. Generate QR Code (Paling Umum)

```dart
import 'package:blue_thermal_helper/blue_thermal_helper.dart';

void buildReceipt() async {
  final receipt = await ThermalReceipt.create();
  
  // QR code dengan default ukuran
  receipt.qrcode('https://example.com/invoice/001');
  
  // QR code dengan custom ukuran (lebih besar)
  receipt.qrcode('REF-2026-000123', size: 10);
  
  // QR code dengan fallback text jika gagal
  receipt.qrcode(
    'https://example.com/order/123',
    fallbackText: 'https://example.com/order/123',
  );
}
```

### 2. Generate Barcode Standard

```dart
// Code128 (paling fleksibel untuk berbagai data)
receipt.barcode128('INVOICE-2026-001234');

// Code128 dengan ukuran custom
receipt.barcode128(
  'ORD-2026-000456',
  height: 4,
  width: 3.0,
  withLabel: true,
);

// EAN-13 (untuk produk retail)
receipt.barcode(BarcodeData.ean13('1234567890123'));

// EAN-8 (untuk produk kecil)
receipt.barcode(BarcodeData.ean8('12345678'));
```

### 3. Barcode dengan Fallback

```dart
// Jika data tidak valid atau error saat generate, 
// maka tampilkan text alternative
receipt.barcode128(
  'INVALID',
  fallbackText: 'INVALID-REF-001',
);

receipt.qrcode(
  'https://very-long-url.com/order/123',
  fallbackText: 'Scan failed - Order #123',
);
```

## API Reference

### Class: BarcodeData

Model untuk menyimpan informasi barcode yang akan di-generate.

#### Constructor

```dart
const BarcodeData({
  required String data,           // Data yang akan di-encode
  BarcodeType type = code128,     // Tipe barcode (default: Code128)
  int height = 3,                 // Tinggi barcode (1-10)
  double width = 2.0,             // Width ratio (1.0-4.0)
  bool withLabel = true,          // Tampilkan text di bawah barcode
  String? fallbackText,           // Text jika generate gagal
})
```

#### Factory Constructors

##### `BarcodeData.qrcode()`

```dart
factory BarcodeData.qrcode(
  String data,
  {
    int size = 8,
    String? fallbackText,
  }
)
```

Membuat QR code dengan default optimal untuk scanning.

- **size**: 1-10 (default 8)
- **fallbackText**: Text pengganti jika gagal

##### `BarcodeData.ean13()`

```dart
factory BarcodeData.ean13(
  String data,
  {
    int height = 3,
    bool withLabel = true,
    String? fallbackText,
  }
)
```

Membuat EAN-13 barcode dengan validasi 13 digit.

- **data**: Harus tepat 13 digit numerik
- Throws `FormatException` jika tidak sesuai format

##### `BarcodeData.ean8()`

```dart
factory BarcodeData.ean8(
  String data,
  {
    int height = 3,
    bool withLabel = true,
    String? fallbackText,
  }
)
```

Membuat EAN-8 barcode dengan validasi 8 digit.

##### `BarcodeData.code128()`, `BarcodeData.code39()`

```dart
// Code128 - paling fleksibel
factory BarcodeData.code128(
  String data,
  {
    int height = 3,
    double width = 2.0,
    bool withLabel = true,
    String? fallbackText,
  }
)

// Code39 - untuk industri/logistik
factory BarcodeData.code39(
  String data,
  {
    int height = 3,
    bool withLabel = true,
    String? fallbackText,
  }
)
```

#### Methods

##### `isValid()`

```dart
bool isValid()
```

Validasi apakah data sesuai dengan format barcode type-nya.

```dart
final data = BarcodeData.ean13('1234567890123');
if (data.isValid()) {
  receipt.barcode(data);
}
```

### Class: ThermalReceipt

Method-method barcode dalam ThermalReceipt:

#### `barcode()` - Generate Barcode Custom

```dart
void barcode(
  BarcodeData barcodeData,
  {
    PosAlign align = PosAlign.center,
  }
)
```

Method utama untuk generate barcode dengan konfigurasi custom.

**Parameters:**

- `barcodeData`: BarcodeData object dengan konfigurasi barcode
- `align`: Alignment barcode di halaman (left/center/right)

**Example:**

```dart
receipt.barcode(
  BarcodeData.code128('INV-2026-001'),
  align: PosAlign.center,
);

receipt.barcode(
  BarcodeData.qrcode('https://example.com'),
  align: PosAlign.center,
);
```

#### `barcode128()` - Code128 Shortcut

```dart
void barcode128(
  String data,
  {
    PosAlign align = PosAlign.center,
    int height = 3,
    double width = 2.0,
    bool withLabel = true,
    String? fallbackText,
  }
)
```

Shortcut untuk Code128 barcode dengan parameter yang lebih ringkas.

**Example:**

```dart
receipt.barcode128('INVOICE-001');

receipt.barcode128(
  'ORDER-12345',
  height: 4,
  width: 3.0,
  withLabel: false,
);
```

#### `qrcode()` - QR Code Shortcut

```dart
void qrcode(
  String data,
  {
    int size = 8,
    PosAlign align = PosAlign.center,
    String? fallbackText,
  }
)
```

Shortcut untuk QR code dengan parameter yang optimal.

**Parameters:**

- `data`: Apapun (URL, text, nomor, dll)
- `size`: 1-10 (default 8 - ukuran optimal)
- `align`: Alignment QR code
- `fallbackText`: Text pengganti jika gagal

**Example:**

```dart
// QR code untuk URL
receipt.qrcode('https://example.com/invoice/123');

// QR code dengan fallback
receipt.qrcode(
  'REF-2026-000456',
  fallbackText: 'REF-2026-000456',
);
```

## Contoh Praktis

### Contoh 1: Invoice dengan QR Code

```dart
void buildInvoiceWithQR() async {
  final receipt = await ThermalReceipt.create();
  
  receipt.text('INVOICE', size: FontSize.header, center: true, bold: true);
  receipt.hr();
  receipt.feed(1);
  
  receipt.rowLabel('Invoice No', 'INV-2026-000001');
  receipt.rowLabel('Date', DateTime.now().toString().split(' ')[0]);
  receipt.rowLabel('Customer', 'John Doe');
  receipt.feed(1);
  receipt.hr();
  
  // Add QR code untuk tracking
  receipt.feed(1);
  receipt.qrcode('https://example.com/invoice/INV-2026-000001');
  receipt.text('Scan untuk tracking', size: FontSize.small, center: true);
  
  receipt.feed(2);
  receipt.cut();
  
  // Send to printer
  final bytes = receipt.build();
  // await bluetoothPrinter.printBytes(bytes);
}
```

### Contoh 2: Product Label dengan EAN-13

```dart
void buildProductLabel() async {
  final receipt = await ThermalReceipt.create(paper: PaperSize.mm58);
  
  receipt.text('PRODUCT LABEL', size: FontSize.medium, bold: true);
  receipt.feed(1);
  
  receipt.rowLabel('Product', 'Coffee Maker');
  receipt.rowLabel('SKU', 'CM-2026-001');
  receipt.rowLabel('Price', 'Rp 299.000');
  receipt.feed(1);
  
  // EAN-13 barcode
  receipt.barcode(
    BarcodeData.ean13(
      '1234567890123',
      height: 4,
      withLabel: true,
    ),
  );
  
  receipt.feed(1);
  receipt.cut();
}
```

### Contoh 3: Receipt dengan Multiple Barcodes

```dart
void buildReceiptWithBarcodes() async {
  final receipt = await ThermalReceipt.create();
  
  // Header
  receipt.text('RECEIPT', size: FontSize.header, center: true, bold: true);
  receipt.hr();
  receipt.feed(1);
  
  // Order info
  receipt.rowLabel('Order ID', 'ORD-2026-000789');
  receipt.rowLabel('Date', '2026-02-03');
  
  // Products
  receipt.feed(1);
  receipt.hr();
  receipt.rowLabel('Item 1', 'Price');
  receipt.row('Coffee', 'Rp 50.000');
  receipt.row('Cake', 'Rp 35.000');
  receipt.hr();
  
  // Barcodes section
  receipt.feed(2);
  receipt.text('Order Code', size: FontSize.small, center: true);
  receipt.barcode128('ORD-2026-000789', height: 3);
  
  receipt.feed(2);
  receipt.text('Tracking QR', size: FontSize.small, center: true);
  receipt.qrcode('https://example.com/track/ORD-2026-000789');
  
  receipt.feed(2);
  receipt.cut();
}
```

## Best Practices

### 1. Pilih Tipe Barcode yang Tepat

```dart
// ✅ GOOD - Gunakan QR code untuk URL atau data kompleks
receipt.qrcode('https://example.com/invoice/123');

// ✅ GOOD - Gunakan EAN-13 untuk produk retail
receipt.barcode(BarcodeData.ean13('1234567890123'));

// ❌ AVOID - Jangan gunakan Code128 untuk hal sederhana jika ada yang lebih spesifik
// receipt.barcode(BarcodeData.code128('1234567890123')); // Terlalu umum
```

### 2. Validasi Data Sebelum Generate

```dart
// ❌ BAD - Langsung generate tanpa validasi
receipt.barcode(BarcodeData.ean13('123456')); // Akan error!

// ✅ GOOD - Validasi dulu
final data = BarcodeData.ean13('1234567890123');
if (data.isValid()) {
  receipt.barcode(data);
} else {
  receipt.text('Invalid barcode data', size: FontSize.small);
}
```

### 3. Gunakan Fallback Text

```dart
// ✅ GOOD - Selalu sediakan fallback
receipt.qrcode(
  'https://example.com/invoice/123',
  fallbackText: 'https://example.com/invoice/123',
);

receipt.barcode128(
  'INV-001',
  fallbackText: 'INV-001',
);
```

### 4. Ukuran yang Tepat

```dart
// QR Code ukuran optimal
receipt.qrcode('data', size: 8);  // Ukuran standar

// Untuk data pendek/sederhana
receipt.qrcode('REF-001', size: 6);  // Ukuran lebih kecil

// Untuk data panjang/kompleks
receipt.qrcode('https://example.com/very/long/url/path', size: 10);  // Lebih besar

// Barcode height untuk thermal printer
receipt.barcode128('DATA', height: 3);  // Standar
receipt.barcode128('DATA', height: 4);  // Lebih tebal untuk readability
```

### 5. Jarak dan Spacing

```dart
receipt.text('Invoice Number', size: FontSize.medium, bold: true);
receipt.feed(1);  // Space

receipt.barcode128('INV-2026-001', height: 3);

receipt.feed(2);  // Extra space setelah barcode
receipt.text('Scan untuk validasi', size: FontSize.small, center: true);
```

## Troubleshooting

### Issue 1: "Invalid barcode data for type"

**Penyebab:** Data tidak sesuai dengan format barcode type.

```dart
// ❌ ERROR - EAN-13 harus 13 digit
receipt.barcode(BarcodeData.ean13('123456'));  // Hanya 6 digit

// ✅ SOLUTION
receipt.barcode(BarcodeData.ean13('1234567890123'));  // 13 digit
```

### Issue 2: Barcode terlalu kecil / tidak terbaca

**Solusi:**

```dart
// Naikkan height dan width
receipt.barcode128(
  'DATA',
  height: 5,      // Default: 3
  width: 3.5,     // Default: 2.0
  withLabel: true,
);
```

### Issue 3: QR Code terlalu besar

**Solusi:**

```dart
// Turunkan size
receipt.qrcode('DATA', size: 5);  // Default: 8
```

### Issue 4: Generate barcode gagal, ingin fallback

**Solusi:** Gunakan parameter `fallbackText`:

```dart
receipt.qrcode(
  'very-long-data-that-might-fail',
  fallbackText: 'Ref: 12345',
);
```

### Issue 5: Barcode tidak selaras dengan text

**Solusi:** Gunakan align parameter:

```dart
receipt.barcode128('DATA', align: PosAlign.center);  // Tengah
receipt.barcode128('DATA', align: PosAlign.left);    // Kiri
receipt.barcode128('DATA', align: PosAlign.right);   // Kanan
```

## Parameter Reference

### BarcodeData Constructor Parameters

| Parameter | Type | Default | Range | Keterangan |
|-----------|------|---------|-------|-----------|
| data | String | Required | - | Data untuk di-encode |
| type | BarcodeType | code128 | - | Tipe barcode |
| height | int | 3 | 1-10 | Tinggi barcode di printer |
| width | double | 2.0 | 1.0-4.0 | Width ratio (tidak untuk QR) |
| withLabel | bool | true | - | Tampilkan text di bawah |
| fallbackText | String? | null | - | Text jika generate gagal |

### Dimensi Barcode di Thermal Printer

```
Height (dalam unit printer):
1 unit ≈ 1mm

height: 1 → ║ (sangat tipis, sulit dibaca)
height: 2 → ║║ (tipis)
height: 3 → ║║║ (standar) ← RECOMMENDED
height: 4 → ║║║║ (lebih tebal, lebih mudah dibaca)
height: 5-10 → ║...║ (sangat besar, ambil banyak space)

Width (ratio):
width: 1.0 → Sangat narrow (hampir tidak terlihat)
width: 2.0 → Standar ← RECOMMENDED
width: 3.0 → Lebih lebar
width: 4.0 → Sangat lebar (mungkin tidak fit di 58mm paper)

QR Code:
size: 1-3 → Sangat kecil (susah scan)
size: 6 → Kecil (untuk data pendek)
size: 8 → Standar ← RECOMMENDED
size: 10 → Besar (untuk jarak jauh)
```

---

**Version:** 2.1.0  
**Last Updated:** 2026-02-03  
**Language:** Indonesian
