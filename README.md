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
await r.logo('assets/logo.png');
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

### ✅ Compatibility #

Tested on Flutter 3.38.5 with real android devices Oppo Reno 14 and PANDA Thermal Printer PRJ-R58B
