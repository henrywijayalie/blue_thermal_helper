// lib/thermal_receipt.dart

import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

/// Enum sederhana untuk ukuran teks logis
enum ThermalFontSize {
  small,
  normal,
  large,
}

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

/// Mapping ukuran logis ke PosStyles (abstraksi)
class ThermalFontMapper {
  static PosStyles style(
    ThermalFontSize size, {
    bool bold = false,
    PosAlign align = PosAlign.left,
  }) {
    switch (size) {
      case ThermalFontSize.small:
        return PosStyles(
          bold: bold,
          align: align,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
      case ThermalFontSize.large:
        // Many printers only support up to size2; use size2 for large
        return PosStyles(
          bold: bold,
          align: align,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        );
      case ThermalFontSize.normal:
        return PosStyles(
          bold: bold,
          align: align,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        );
    }
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
    ThermalFontSize size = ThermalFontSize.normal,
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
    ThermalFontSize size = ThermalFontSize.normal,
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
    ThermalFontSize size = ThermalFontSize.normal,
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
  void row(String left, String right, {bool bold = false}) {
    rowColumns([
      col(left, 6, size: ThermalFontSize.normal, bold: bold),
      col(right, 6,
          size: ThermalFontSize.normal, bold: bold, align: PosAlign.right),
    ]);
  }

  void rowItem({
    required int qty,
    required String name,
    required num price,
    ThermalFontSize size = ThermalFontSize.normal,
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

  // -----------------------
  // NOTE / DETAIL (single line)
  // -----------------------
  void note(String text) {
    // print indented line with prefix
    _bytes.addAll(_generator.text('  - $text',
        styles: const PosStyles(align: PosAlign.left)));
    _preview.text('  > $text');
  }
}
