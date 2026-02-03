---
title: Barcode & QR Code - Quick Reference
language: id
version: 2.1.0
---

# Barcode & QR Code - Quick Reference

Copy-paste ready code snippets untuk barcode dan QR code.

## 🚀 Get Started (30 detik)

```dart
import 'package:blue_thermal_helper/blue_thermal_helper.dart';

// 1. Buat receipt
final receipt = await ThermalReceipt.create();

// 2. Tambahkan QR code (paling umum)
receipt.qrcode('https://example.com/invoice/123');

// 3. Cetak
final bytes = receipt.build();
await printer.printBytes(bytes);
```

## 📋 Tabel Cepat

| Kebutuhan | Kode | Catatan |
|-----------|------|---------|
| **QR Code** | `receipt.qrcode('data')` | Untuk URL, nomor ref |
| **Code128** | `receipt.barcode128('data')` | Untuk invoice, order |
| **EAN-13** | `receipt.barcode(BarcodeData.ean13('1234567890123'))` | Untuk produk |
| **EAN-8** | `receipt.barcode(BarcodeData.ean8('12345678'))` | Untuk barang kecil |

## 💡 Common Patterns

### Pattern 1: QR Code Sederhana

```dart
receipt.qrcode('https://example.com');
```

### Pattern 2: QR Code dengan Fallback

```dart
receipt.qrcode(
  'https://very-long-url.com/order/123',
  fallbackText: 'REF-123', // Jika QR gagal, tampilkan text ini
);
```

### Pattern 3: Code128 Barcode

```dart
receipt.barcode128('INVOICE-2026-001');
```

### Pattern 4: EAN-13 untuk Produk

```dart
receipt.barcode(
  BarcodeData.ean13('1234567890123'),
);
```

### Pattern 5: Invoice dengan QR

```dart
receipt.text('INVOICE', bold: true, size: FontSize.header);
receipt.rowLabel('No', 'INV-2026-001');
receipt.rowLabel('Date', '2026-02-03');
receipt.feed(2);
receipt.qrcode('https://example.com/invoice/INV-2026-001');
```

### Pattern 6: Product Label

```dart
receipt.text('PRODUCT', bold: true);
receipt.rowLabel('Name', 'Coffee Maker');
receipt.rowLabel('Price', 'Rp 299.000');
receipt.feed(1);
receipt.barcode(BarcodeData.ean13('5901234123457'));
```

### Pattern 7: Multiple Barcodes

```dart
receipt.text('Order Code');
receipt.barcode128('ORD-123');
receipt.feed(2);

receipt.text('Payment QR');
receipt.qrcode('https://pay.example.com/ORD-123');
```

## 🎛 Parameter Configuration

### QR Code Sizing

```dart
receipt.qrcode('data', size: 8);     // Default - balanced
receipt.qrcode('data', size: 6);     // Kecil - untuk data pendek
receipt.qrcode('data', size: 10);    // Besar - untuk jarak jauh
```

### Barcode Height & Width

```dart
// Tinggi barcode
receipt.barcode128('data', height: 3);  // Default - standar
receipt.barcode128('data', height: 5);  // Lebih tebal - lebih mudah dibaca

// Width ratio (tidak untuk QR)
receipt.barcode128('data', width: 2.0);  // Default
receipt.barcode128('data', width: 3.5);  // Lebih lebar
```

### Label Display

```dart
receipt.barcode128('data', withLabel: true);   // Tampilkan text
receipt.barcode128('data', withLabel: false);  // Hanya barcode
```

### Alignment

```dart
receipt.barcode(data, align: PosAlign.center);  // Default
receipt.barcode(data, align: PosAlign.left);
receipt.barcode(data, align: PosAlign.right);
```

## ✅ Validasi Data

```dart
// EAN-13: Harus 13 digit
final data = BarcodeData.ean13('1234567890123');  // ✅ Valid
final data = BarcodeData.ean13('123456');        // ❌ Error

// EAN-8: Harus 8 digit
final data = BarcodeData.ean8('12345678');       // ✅ Valid

// Check validitas sebelum generate
if (data.isValid()) {
  receipt.barcode(data);
}
```

## 🎯 Use Cases

### Invoice/Bill

```dart
receipt.qrcode('https://example.com/invoice/INV-2026-001');
```

### Product/Retail

```dart
receipt.barcode(BarcodeData.ean13('5901234123457'));
```

### Shipping/Courier

```dart
receipt.qrcode('https://track.example.com/TRACK-123');
```

### Order Confirmation

```dart
receipt.barcode128('ORD-2026-001');
```

### Payment/Transaction

```dart
receipt.qrcode('https://pay.example.com/TRX-123');
```

### Support/Reference

```dart
receipt.barcode128('SUP-TICKET-789');
```

## 🚨 Error Handling

### Invalid Data - Gunakan Fallback

```dart
receipt.qrcode(
  invalidData,
  fallbackText: 'REF-123',  // Tampilkan ini jika error
);
```

### Validasi Dulu

```dart
final data = BarcodeData.ean13('123');
if (data.isValid()) {
  receipt.barcode(data);
} else {
  receipt.text('Invalid barcode data');
}
```

## 📊 Type Selection Guide

```
┌─ Pilih tipe barcode ─┐
│                      │
├─ Ada 13 digit? ──────┼─→ EAN-13
├─ Ada 8 digit? ───────┼─→ EAN-8
├─ URL / link? ────────┼─→ QR Code ⭐
├─ Invoice / ref? ─────┼─→ Code128 ⭐
├─ Complex data? ──────┼─→ QR Code ⭐
└─ Else? ──────────────┼─→ Code128
```

## 🔗 Factory Constructors

```dart
// QR Code
BarcodeData.qrcode('https://example.com');
BarcodeData.qrcode('data', size: 8, fallbackText: 'Fallback');

// Code128
BarcodeData.code128('INV-001');
BarcodeData.code128('data', height: 4, width: 3.0);

// EAN-13
BarcodeData.ean13('1234567890123');  // Must be 13 digits

// EAN-8
BarcodeData.ean8('12345678');        // Must be 8 digits

// Code39
BarcodeData.code39('DATA-123');

// Custom
BarcodeData(
  data: 'custom',
  type: BarcodeType.code128,
  height: 3,
  width: 2.0,
);
```

## 📈 Performance Tips

1. **Reuse receipts** - Jangan buat receipt baru untuk setiap barcode
2. **Batch barcodes** - Cetak multiple barcodes sekaligus
3. **Size matters** - Gunakan ukuran yang sesuai (jangan terlalu besar)
4. **Fallback** - Selalu sediakan fallback text untuk reliability

## 🔍 Debugging

```dart
// Print barcode info
print(data.toString());

// Check valid
print(data.isValid());

// Get barcode type
print(data.type);  // BarcodeType.qrcode
print(data.data);  // 'https://...'
```

## 📚 Related Links

- **Full Guide**: [BARCODE_GUIDE.md](./BARCODE_GUIDE.md)
- **Examples**: [barcode_example.dart](./example/lib/barcode_example.dart)
- **API Reference**: BarcodeData class in `lib/src/models/barcode_data.dart`

---

**Version:** 2.1.0  
**Last Updated:** 2026-02-03
