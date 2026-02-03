// lib/thermal_receipt.dart

import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'src/models/font_size.dart';
import 'src/models/barcode_data.dart';

enum ReceiptTextType {
  text,
  money,
}

String formatMoney(num value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  int count = 0;

  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write('.');
      count = 0;
    }
  }
  return buf.toString().split('').reversed.join();
}

/// Mapper untuk mengkonversi FontSize ke PosStyles
/// Melakukan perhitungan manual berdasarkan ukuran font dalam points
class ThermalFontMapper {
  /// Menghasilkan PosStyles berdasarkan FontSize
  /// 
  /// Parameters:
  /// - [size]: Ukuran font dalam point (6pt-32pt)
  /// - [bold]: Apakah teks bold
  /// - [align]: Alignment teks (left, center, right)
  /// 
  /// Returns: PosStyles yang dikonfigurasi sesuai ukuran font
  static PosStyles style(
    FontSize size, {
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) {
    final widthMultiplier = size.getWidthMultiplier();
    final heightMultiplier = size.getHeightMultiplier();

    // Konversi multiplier ke PosTextSize
    final PosTextSize posWidth;
    final PosTextSize posHeight;

    switch (widthMultiplier) {
      case 1:
        posWidth = PosTextSize.size1;
        break;
      case 2:
        posWidth = PosTextSize.size2;
        break;
      case 3:
        posWidth = PosTextSize.size3;
        break;
      case 4:
      default:
        posWidth = PosTextSize.size4;
        break;
    }

    switch (heightMultiplier) {
      case 1:
        posHeight = PosTextSize.size1;
        break;
      case 2:
        posHeight = PosTextSize.size2;
        break;
      case 3:
        posHeight = PosTextSize.size3;
        break;
      case 4:
      default:
        posHeight = PosTextSize.size4;
        break;
    }

    return PosStyles(
      bold: bold,
      align: align,
      height: posHeight,
      width: posWidth,
    );
  }
}

/// Simple text-only preview buffer for UI preview
class ReceiptPreview {
  final StringBuffer _buf = StringBuffer();

  void text(String text, {bool center = false}) {
    if (center) {
      _buf.writeln('[CENTER] $text');
    } else {
      _buf.writeln(text);
    }
  }

  void row(String left, String right) {
    _buf.writeln('$left    $right');
  }

  void hr([int width = 32]) {
    _buf.writeln('-' * width);
  }

  void feed([int n = 1]) {
    for (int i = 0; i < n; i++) {
      _buf.writeln();
    }
  }

  void cut() {
    _buf.writeln('-------- CUT --------');
  }

  @override
  String toString() => _buf.toString();
}

/// ThermalReceipt: wrapper + builder over esc_pos_utils_plus Generator
/// - Holds bytes list
/// - Keeps preview buffer in sync
class ThermalReceipt {
  final Generator _generator;
  final List<int> _bytes = [];
  final ReceiptPreview _preview = ReceiptPreview();
  final PaperSize paperSize;

  ThermalReceipt._(this._generator, this.paperSize);

  /// factory: create generator by loading capability profile
  static Future<ThermalReceipt> create({
    PaperSize paper = PaperSize.mm58,
  }) async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(paper, profile);
    return ThermalReceipt._(gen, paper);
  }

  /// Final bytes for printing
  List<int> build() => List.unmodifiable(_bytes);

  /// Text preview (human readable)
  String preview() => _preview.toString();

  // -----------------------
  // IMAGE / LOGO SUPPORT
  // -----------------------
  /// Insert image from asset (resize automatically)
  /// `assetPath`: path in assets, e.g. 'assets/logo.png'
  /// Replace existing logo(...) implementation with this one.
  /// Expects `charsPerLine`, `_generator`, `_bytes`, and `_preview` to exist in the class.
  Future<void> logo(
    Uint8List bytes, {
    PosAlign align = PosAlign.center,
  }) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return;

      // langsung kirim ke generator
      _bytes.addAll(
        _generator.image(
          image,
          align: align,
        ),
      );
    } catch (_) {
      // silent fail → receipt tetap lanjut
    }
  }

  // /// Helper to determine a reasonable max width per paper size
  // int _paperMaxWidth(PaperSize paper) {
  //   // conservative defaults (common printers)
  //   switch (paper) {
  //     case PaperSize.mm80:
  //       return 576; // typical 80mm at 203 dpi
  //     case PaperSize.mm58:
  //     default:
  //       return 384; // typical 58mm at 203 dpi
  //   }
  // }

  // -----------------------
  // TEXT / LAYOUT
  // -----------------------

  /// Generic text with logical font size + alignment
  void text(
    String text, {
    FontSize size = FontSize.normal,
    bool bold = false,
    bool center = false,
  }) {
    final styles = ThermalFontMapper.style(
      size,
      bold: bold,
      align: center ? PosAlign.center : PosAlign.left,
    );

    _bytes.addAll(_generator.text(text, styles: styles));
    _preview.text(text, center: center);
  }

  /// Convenience: horizontal rule
  void hr([int width = 32]) {
    _bytes.addAll(_generator.hr());
    _preview.hr(width);
  }

  /// feed n lines
  void feed([int n = 1]) {
    _bytes.addAll(_generator.feed(n));
    _preview.feed(n);
  }

  /// cut paper
  void cut() {
    _bytes.addAll(_generator.cut());
    _preview.cut();
  }

  // -----------------------
  // ROW / COLUMN SUPPORT
  // -----------------------

  /// Generic row that accepts PosColumn list (full control)
  void rowColumns(List<PosColumn> columns) {
    _bytes.addAll(_generator.row(columns));
    // For preview: try to create simple left-right for 2-col case
    if (columns.length == 2) {
      final left = columns[0].text;
      final right = columns[1].text;
      _preview.row(left, right);
    } else {
      // fallback: simply join texts
      final joined = columns.map((c) => c.text).join(' | ');
      _preview.text(joined);
    }
  }

  /// Helper to create PosColumn with mapped styles (so user doesn't need to import PosStyles)
  PosColumn col(
    String text,
    int width, {
    FontSize size = FontSize.normal,
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) {
    return PosColumn(
      text: text,
      width: width,
      styles: ThermalFontMapper.style(size, bold: bold, align: align),
    );
  }

  PosColumn colAuto(
    dynamic value,
    int width, {
    ReceiptTextType type = ReceiptTextType.text,
    FontSize size = FontSize.normal,
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) {
    String text;

    if (type == ReceiptTextType.money) {
      if (value is num) {
        text = formatMoney(value);
      } else {
        text = value.toString();
      }
      align = PosAlign.right; // money selalu kanan
    } else {
      text = value.toString();
    }

    return PosColumn(
      text: text,
      width: width,
      styles: ThermalFontMapper.style(
        size,
        bold: bold,
        align: align,
      ),
    );
  }

  /// Convenience for common 2-column usage
  void row(
    String left,
    String right, {
    bool bold = false,
    FontSize size = FontSize.normal,
  }) {
    // Adjust width allocation to prevent text wrapping for long values
    // Gunakan dynamic width berdasarkan font size multiplier
    final widthMul = size.getWidthMultiplier();
    final baseLabelWidth = 3;
    final baseValueWidth = 9;
    
    // Sesuaikan lebar berdasarkan multiplier
    final leftWidth = (baseLabelWidth * (5 - widthMul)).round().clamp(2, 8);
    final rightWidth = (baseValueWidth * (5 - widthMul)).round().clamp(2, 8);

    rowColumns([
      col(left, leftWidth, size: size, bold: bold),
      col(right, rightWidth, size: size, bold: bold, align: PosAlign.right),
    ]);
  }

  void rowItem({
    required int qty,
    required String name,
    required num price,
    FontSize size = FontSize.normal,
  }) {
    // format "qty x price"
    final priceText = '$qty x ${formatMoney(price)}';

    rowColumns([
      col(name, 7, size: size),
      colAuto(
        priceText,
        5,
        type: ReceiptTextType.money,
        size: size,
      ),
    ]);
  }

  /// Smart row dengan alignment otomatis untuk tanda ":"
  /// 
  /// Format: Label : Value dengan tanda : selaras vertikal
  /// Contoh:
  /// ```dart
  /// receipt.rowLabel('Nama Penerima', 'John Doe');
  /// receipt.rowLabel('No. Referensi', '123456789');
  /// receipt.rowLabel('Tanggal', '2026-02-03');
  /// ```
  /// 
  /// Akan menghasilkan:
  /// ```
  /// Nama Penerima : John Doe
  /// No. Referensi : 123456789
  /// Tanggal       : 2026-02-03
  /// ```
  /// 
  /// Tanda ":" akan selaras berdasarkan label terpanjang
  void rowLabel(
    String label,
    String value, {
    FontSize size = FontSize.normal,
    bool bold = false,
  }) {
    // Hitung jumlah karakter yang tersedia
    final charsPerLine = size.getCharsPerLine58mm(); // Default 58mm, bisa disesuaikan
    
    // Format: label (dengan padding) + " : " + value
    // Minimum padding adalah 1 karakter
    final colonText = ' : ';
    final maxLabelWidth = (charsPerLine * 0.4).floor(); // 40% untuk label
    
    // Jika label lebih panjang dari maksimal, gunakan apa adanya
    final paddedLabel = label.length <= maxLabelWidth
        ? label.padRight(maxLabelWidth)
        : label;
    
    final fullText = '$paddedLabel$colonText$value';
    
    // Cetak sebagai text biasa dengan alignment left
    text(fullText, size: size, bold: bold, center: false);
  }

  /// Smart row dengan alignment untuk tanda ":" dengan custom width
  /// 
  /// Sama seperti rowLabel() tapi dengan kontrol width untuk label
  void rowLabelCustom(
    String label,
    String value, {
    int labelWidth = 20,
    FontSize size = FontSize.normal,
    bool bold = false,
  }) {
    final paddedLabel = label.length <= labelWidth
        ? label.padRight(labelWidth)
        : label;
    
    final fullText = '$paddedLabel : $value';
    
    text(fullText, size: size, bold: bold, center: false);
  }

  // -----------------------
  // NOTE / DETAIL (single line)
  // -----------------------
  void note(String text) {
    // print indented line with prefix
    _bytes.addAll(_generator.text('  - $text',
        styles: const PosStyles(align: PosAlign.left)));
    _preview.text('  > $text');
  }

  // -----------------------
  // BARCODE / QR CODE
  // -----------------------

  /// Generate dan cetak barcode/QR code
  /// 
  /// Mendukung berbagai tipe barcode (Code128, EAN-13, EAN-8, Code39, QR Code, dll)
  /// Method ini akan:
  /// 1. Generate barcode dari data
  /// 2. Konversi ke SVG/image format
  /// 3. Cetak ke thermal printer
  /// 
  /// Parameters:
  /// - [barcodeData]: Data barcode yang berisi type, data, ukuran, dll
  /// - [align]: Alignment untuk barcode (left, center, right). Default: center
  /// 
  /// Example:
  /// ```dart
  /// receipt.barcode(BarcodeData.qrcode('https://example.com'));
  /// receipt.barcode(BarcodeData.ean13('1234567890123'));
  /// receipt.barcode(BarcodeData.code128('INVOICE-001'));
  /// ```
  /// 
  /// Throws FormatException jika data barcode tidak valid
  void barcode(
    BarcodeData barcodeData, {
    PosAlign align = PosAlign.center,
  }) {
    if (!barcodeData.isValid()) {
      // Fallback ke text jika data tidak valid
      if (barcodeData.fallbackText != null) {
        text(barcodeData.fallbackText!, center: align == PosAlign.center);
        _preview.text('[Barcode fallback: ${barcodeData.fallbackText}]');
      } else {
        throw FormatException(
          'Invalid barcode data for type ${barcodeData.type}: ${barcodeData.data}',
        );
      }
      return;
    }

    try {
      final bc = barcodeData.getBarcode();
      
      // Generate SVG
      final svg = bc.toSvg(
        barcodeData.data,
        width: 200.0 * barcodeData.width,
        height: 80.0 * barcodeData.height,
        drawText: barcodeData.withLabel,
      );

      // Convert SVG to image
      // Untuk thermal printer, kita convert ke image bytes
      final imageData = _svgToImage(svg, barcodeData);
      
      if (imageData != null) {
        // Cetak image ke printer
        _bytes.addAll(_generator.image(imageData, align: align));
        _preview.text('[Barcode: ${barcodeData.type} - ${barcodeData.data}]');
      } else {
        // Fallback ke text
        if (barcodeData.fallbackText != null) {
          text(barcodeData.fallbackText!, center: align == PosAlign.center);
          _preview.text('[Barcode fallback: ${barcodeData.fallbackText}]');
        }
      }
    } catch (e) {
      // Fallback handling jika ada error
      if (barcodeData.fallbackText != null) {
        text(barcodeData.fallbackText!, center: align == PosAlign.center);
        _preview.text('[Barcode error - fallback: ${barcodeData.fallbackText}]');
      } else {
        throw FormatException('Failed to generate barcode: $e');
      }
    }
  }

  /// Generate barcode dengan custom align dan fallback
  /// Alias untuk barcode() dengan parameter yang lebih fleksibel
  void barcode128(
    String data, {
    PosAlign align = PosAlign.center,
    int height = 3,
    double width = 2.0,
    bool withLabel = true,
    String? fallbackText,
  }) {
    barcode(
      BarcodeData.code128(
        data,
        height: height,
        width: width,
        withLabel: withLabel,
        fallbackText: fallbackText,
      ),
      align: align,
    );
  }

  /// Generate dan cetak QR code
  /// 
  /// QR code ideal untuk URL, nomor referensi, atau data kompleks
  /// 
  /// Parameters:
  /// - [data]: Data untuk di-encode (URL, text, nomor, dll)
  /// - [size]: Ukuran QR code (1-10, default 8)
  /// - [align]: Alignment QR code
  /// - [fallbackText]: Text alternatif jika generate gagal
  /// 
  /// Example:
  /// ```dart
  /// receipt.qrcode('https://example.com/invoice/123');
  /// receipt.qrcode('REF-2026-000123');
  /// ```
  void qrcode(
    String data, {
    int size = 8,
    PosAlign align = PosAlign.center,
    String? fallbackText,
  }) {
    barcode(
      BarcodeData.qrcode(data, size: size, fallbackText: fallbackText),
      align: align,
    );
  }

  /// Helper method untuk konversi SVG ke image format
  /// Ini adalah placeholder - implementasi sebenarnya memerlukan svg parsing library
  /// 
  /// TODO: Implementasi proper SVG to Image conversion
  /// Opsi:
  /// 1. Gunakan package 'svg' untuk parse SVG
  /// 2. Render SVG menggunakan flutter_svg + image capture
  /// 3. Gunakan barcode package yang langsung support image output
  static img.Image? _svgToImage(String svg, BarcodeData barcodeData) {
    try {
      // Placeholder implementation
      // Dalam praktek, kita bisa menggunakan:
      // - barcode.toImage() jika tersedia
      // - Custom SVG parser + render
      // - Atau gunakan format PNG/bytes langsung dari package
      
      // Untuk sekarang, return null untuk fallback ke text
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting SVG to image: $e');
      }
      return null;
    }
  }
}
