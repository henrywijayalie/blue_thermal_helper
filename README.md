# Blue Thermal Helper

Helper Flutter untuk **Bluetooth Thermal Printer (ESC/POS)** yang dibuat reusable, sederhana dipakai oleh developer aplikasi kasir / internal app.

Fokus utama:

- API **high-level** (tidak perlu paham byte ESC/POS)
- Support **58mm & 80mm**
- Preview sebelum print
- Build receipt dari **kode** atau **JSON**
- Auto alignment, money formatter, wrap text

---

## ☕ Support

If this package helps you, consider supporting the development:

[![Buy Me a Coffee](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=🍵&slug=henrywijayalie&button_colour=FFDD00&font_colour=000000&outline_colour=000000&coffee_colour=ffffff)](https://www.buymeacoffee.com/henrywijayalie)

---

## Instalasi

Tambahkan dependency yang dibutuhkan:

```yaml
dependencies:
  esc_pos_utils_plus: ^2.0.3
```

## Android Permissions

This plugin declares the required Bluetooth permissions automatically.

However, you must request runtime permissions in your application:

### Android 12+ (API 31+)

- BLUETOOTH_SCAN
- BLUETOOTH_CONNECT

### Android ≤ 11

- ACCESS_FINE_LOCATION

Example using permission_handler:

```dart
await Permission.bluetoothScan.request();
await Permission.bluetoothConnect.request();
```

---

## Konsep Dasar

```text
UI / View
   ↓
BlueThermalHelper  (state paper, connect, print)
   ↓
ThermalReceipt     (builder receipt)
   ↓
ESC/POS bytes
   ↓
Bluetooth Printer
```

`BlueThermalHelper` adalah **single source of truth**.

---

## Initial Helper

```dart
final _printer = BlueThermalHelper.instance;
```

## Enum & Konfigurasi Kertas

### ThermalPaper

```dart
enum ThermalPaper {
  mm58,
  mm80,
}
```

### Set jenis kertas (WAJIB)

```dart
_printer.setPaper(ThermalPaper.mm58);
```

Efeknya:

- chars per line otomatis
- ukuran logo menyesuaikan
- preview = hasil print

---

## ✨ FontSize Manual (NEW in v2.0)

Sistem **FontSize Manual** memungkinkan Anda menentukan ukuran teks secara spesifik (6pt-32pt), mirip dengan Microsoft Word atau text editor profesional.

### Menggunakan Preset FontSize

```dart
final receipt = await ThermalReceipt.create();

receipt.text('Header 24pt', bold: true, center: true, size: FontSize.header);
receipt.text('Subheader 16pt', size: FontSize.large);
receipt.text('Body text 10pt', size: FontSize.normal);
receipt.text('Detail 8pt', size: FontSize.small);
```

### Preset FontSize yang Tersedia

- `FontSize.extraSmall` → 6pt
- `FontSize.small` → 8pt
- `FontSize.normal` → 10pt (default)
- `FontSize.medium` → 12pt
- `FontSize.large` → 16pt
- `FontSize.extraLarge` → 20pt
- `FontSize.header` → 24pt

### Custom FontSize

```dart
receipt.text('Custom 14pt', size: FontSize(14.0));
receipt.text('Custom 11.5pt', size: FontSize(11.5));
```

Rentang yang didukung: **6pt - 32pt**

---

## ✨ Smart Row Alignment (NEW in v2.0)

Fitur baru `rowLabel()` membuat tanda `:` selaras vertikal secara otomatis:

```dart
receipt.rowLabel('Nama Pelanggan', 'John Doe');
receipt.rowLabel('Email', 'john@example.com');
receipt.rowLabel('No. HP', '08123456789');
```

**Output** (tanda : selaras otomatis):

```
Nama Pelanggan : John Doe
Email          : john@example.com
No. HP         : 08123456789
```

---

## 📖 Dokumentasi FontSize

Untuk dokumentasi lengkap tentang FontSize dan fitur-fitur baru lainnya:

- **Quick Start**: Baca [QUICKREFERENCE.md](QUICKREFERENCE.md)
- **Dokumentasi Lengkap**: Baca [FONTSIZE_GUIDE.md](FONTSIZE_GUIDE.md)
- **Index Dokumentasi**: Lihat [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- **Contoh Code**: Lihat [example/lib/font_size_demo.dart](example/lib/font_size_demo.dart)

---

## Scan Printer

```dart
final devices = await _printer.scan(timeout: 8);
```

Return:

```dart
List<BluetoothPrinter>
```

Digunakan untuk menampilkan daftar printer bluetooth.

---

## Connect Printer

```dart
await _printer.connect(printer.address);
```

Catatan:

- Jangan connect ulang jika sudah connected
- Status dipantau lewat `events`

---

## Disconnect Printer

```dart
await _printer.disconnect();
```

Menutup socket bluetooth secara aman.

---

## Cek Status Koneksi

```dart
final connected = await _printer.isConnected();
```

Digunakan untuk enable / disable tombol print.

---

## Event Listener

```dart
_printer.events.listen((event) {
  print(event);
});
```

Contoh event:

```json
{ "event": "connected", "mac": "00:11:22" }
{ "event": "disconnected" }
{ "event": "error", "message": "..." }
```

---

## Print Receipt (Builder)

### Contoh Paling Umum

```dart
await _printer.printReceipt((r) async {
  r.text('TOKO CONTOH', bold: true, center: true, size: ThermalFontSize.large);
  r.hr();
  r.row('Kopi', '2 x 15.000');
  r.row('TOTAL', '30.000', bold: true);
  
  r.cut();
});
```

Kelebihan:

- Aman
- Mudah dibaca
- Tidak berurusan dengan ESC/POS byte

---

## Preview Receipt

```dart
final preview = await _printer.previewReceipt((r) async {
  r.text('TOKO CONTOH', center: true);
  r.row('Kopi', '2 x 15.000');
});
```

Biasanya dipakai sebelum print.

---

## Print dari JSON

### Contoh JSON

```json
{
  "header": {
    "title": "WARUNG MAKAN",
    "subtitle": "Jl. Sudirman"
  },
  "items": [
    { "name": "Nasi Goreng Ayam", "qty": 2, "price": 35000 },
    { "name": "Iga Bakar", "qty": 1, "price": 65000, "note": "Pedas sekali" }
  ],
  "total": 135000,
  "footer": "Terima kasih atas kunjungan anda."
}
```

### Print

```dart
await _printer.printFromJson(data);
```

### Preview

```dart
final preview = await _printer.previewFromJson(data);
```

Kelebihan:

- Backend-friendly
- Bisa langsung dari API
- Cocok untuk POS skala besar

---

## ThermalReceipt API

### Font Sizes

Plugin ini mendukung 4 ukuran font:

```dart
enum ThermalFontSize {
  extraSmall,  // Font ekstra kecil (menggunakan fontB)
  small,       // Font kecil
  normal,      // Font normal (default)
  large,       // Font besar
}
```

Contoh penggunaan:

```dart
// Font ekstra kecil untuk informasi detail
r.text('Alamat lengkap toko', size: ThermalFontSize.extraSmall);

// Font normal untuk konten utama
r.text('Nama Item', size: ThermalFontSize.normal);

// Font besar untuk header
r.text('TOKO SAYA', size: ThermalFontSize.large, bold: true);
```

**Catatan:** `ThermalFontSize.extraSmall` menggunakan font alternatif (fontB) yang lebih kecil dari ukuran standar. Ini berguna untuk mencetak informasi detail seperti alamat panjang, catatan kaki, atau disclaimer pada ruang terbatas.

### rowItem (AUTO-WRAP ITEM + MONEY ALIGN)

Method khusus untuk mencetak item transaksi (nama + qty x harga) dengan:

- auto-wrap nama item panjang
- alignment harga otomatis
- mengikuti charsPerLine (58mm / 80mm)

```dart
r.rowItem(
  name: 'Iga Bakar Rempah Super Pedas',
  qty: 2,
  price: 65000,
);
```

Hasil print (58mm contoh):

```text
Iga Bakar Rempah Super Pedas
2 x 65.000
```

Jika ada catatan:

```dart
r.rowItem(
  name: 'Iga Bakar Rempah',
  qty: 1,
  price: 65000,
  note: 'Pedas sekali',
);
```

Hasil:

```text
Iga Bakar Rempah
1 x 65.000
  * Pedas sekali
```

---

### text

```dart
r.text('Hello', bold: true, center: true);
```

### row (2 kolom)

```dart
r.row('TOTAL', '100.000', bold: true);
```

### rowColumns (multi kolom)

```dart
r.rowColumns([
  r.col('Item', 6),
  r.col('Harga', 6, align: PosAlign.right),
]);
```

### horizontal rules

```dart
r.hr();
```

### note

```dart
r.note('Pedas sekali');
```

### logo

```dart
ByteData bytesAsset = await rootBundle.load("assets/logo_header3.png");

Uint8List imageBytesFromAsset = bytesAsset.buffer.asUint8List(bytesAsset.offsetInBytes, bytesAsset.lengthInBytes);

await r.logo(imageBytesFromAsset);
```

### feed & cut

```dart
r.feed(2);
r.cut();
```

---

## Money Formatter (Otomatis)

```text
1 x 50.000
2 x  5.000
```

Alignment otomatis berdasarkan chars-per-line.

---

## Best Practice

### ✔ Set paper di awal aplikasi

### ✔ Jangan kirim ESC/POS byte manual

### ✔ Gunakan preview untuk QA

### ✔ Simpan printer MAC di local storage

---

## Roadmap (Will Update Soon)

- Retry & reconnect strategy
- Print Bitmap QR Code
- Printer profile per MAC
- Multi printer routing (Print and switch ke thermal printer yang berbeda sesuai profile yang disimpan)

---

## Penutup

### ✅ Compatibility

Tested on Flutter 3.38.5 with real android devices Oppo Reno 14 and PANDA Thermal Printer PRJ-R58B

### Additional information

This is Just The Initial Version feel free to Contribute or Report any Bug!
