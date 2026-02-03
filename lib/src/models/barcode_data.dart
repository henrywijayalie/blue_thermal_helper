import 'package:barcode/barcode.dart';

/// Enum untuk tipe barcode yang didukung
enum BarcodeType {
  code128,
  ean13,
  ean8,
  code39,
  upca,
  codabar,
  qrcode,
}

/// Model untuk data barcode/QR code
/// 
/// Digunakan untuk generate barcode atau QR code yang dapat dicetak
/// ke thermal printer dengan berbagai format dan ukuran
class BarcodeData {
  /// Data atau value yang akan di-encode menjadi barcode
  final String data;

  /// Tipe barcode yang akan digenerate
  /// Default: BarcodeType.code128
  final BarcodeType type;

  /// Tinggi barcode dalam unit satuan printer (1 unit = ~1mm)
  /// Range: 1-10, Default: 3 untuk barcode normal, 5-10 untuk QR code
  final int height;

  /// Width ratio untuk barcode (tidak berlaku untuk QR code)
  /// Range: 1.0-4.0, Default: 2.0
  final double width;

  /// Apakah menampilkan label/text di bawah barcode
  /// Default: true untuk barcode, false untuk QR code
  final bool withLabel;

  /// Text alternative jika generate barcode gagal
  /// Berguna untuk fallback ke text biasa
  final String? fallbackText;

  const BarcodeData({
    required this.data,
    this.type = BarcodeType.code128,
    this.height = 3,
    this.width = 2.0,
    this.withLabel = true,
    this.fallbackText,
  });

  /// Factory constructor untuk QR code dengan default optimal
  factory BarcodeData.qrcode(
    String data, {
    int size = 8,
    String? fallbackText,
  }) {
    return BarcodeData(
      data: data,
      type: BarcodeType.qrcode,
      height: size,
      width: 1.0, // QR code adalah square, width ratio tidak digunakan
      withLabel: false,
      fallbackText: fallbackText,
    );
  }

  /// Factory constructor untuk EAN-13 dengan default optimal
  factory BarcodeData.ean13(
    String data, {
    int height = 3,
    bool withLabel = true,
    String? fallbackText,
  }) {
    if (data.length != 13) {
      throw FormatException(
        'EAN-13 data harus tepat 13 digit, diberikan: ${data.length}',
      );
    }
    return BarcodeData(
      data: data,
      type: BarcodeType.ean13,
      height: height,
      width: 2.0,
      withLabel: withLabel,
      fallbackText: fallbackText,
    );
  }

  /// Factory constructor untuk EAN-8 dengan default optimal
  factory BarcodeData.ean8(
    String data, {
    int height = 3,
    bool withLabel = true,
    String? fallbackText,
  }) {
    if (data.length != 8) {
      throw FormatException(
        'EAN-8 data harus tepat 8 digit, diberikan: ${data.length}',
      );
    }
    return BarcodeData(
      data: data,
      type: BarcodeType.ean8,
      height: height,
      width: 2.0,
      withLabel: withLabel,
      fallbackText: fallbackText,
    );
  }

  /// Factory constructor untuk Code-39
  factory BarcodeData.code39(
    String data, {
    int height = 3,
    bool withLabel = true,
    String? fallbackText,
  }) {
    return BarcodeData(
      data: data,
      type: BarcodeType.code39,
      height: height,
      width: 2.0,
      withLabel: withLabel,
      fallbackText: fallbackText,
    );
  }

  /// Factory constructor untuk Code-128 (default)
  factory BarcodeData.code128(
    String data, {
    int height = 3,
    double width = 2.0,
    bool withLabel = true,
    String? fallbackText,
  }) {
    return BarcodeData(
      data: data,
      type: BarcodeType.code128,
      height: height,
      width: width,
      withLabel: withLabel,
      fallbackText: fallbackText,
    );
  }

  /// Convert enum BarcodeType ke barcode.Barcode type
  Barcode getBarcode() {
    switch (type) {
      case BarcodeType.code128:
        return Barcode.code128();
      case BarcodeType.ean13:
        return Barcode.ean13();
      case BarcodeType.ean8:
        return Barcode.ean8();
      case BarcodeType.code39:
        return Barcode.code39();
      case BarcodeType.upca:
        return Barcode.upcA();
      case BarcodeType.codabar:
        return Barcode.codabar();
      case BarcodeType.qrcode:
        return Barcode.qrCode();
    }
  }

  /// Validasi data sesuai dengan type barcode
  bool isValid() {
    try {
      // Basic length check
      if (data.isEmpty) return false;

      switch (type) {
        case BarcodeType.ean13:
          return data.length == 13 && _isNumeric(data);
        case BarcodeType.ean8:
          return data.length == 8 && _isNumeric(data);
        case BarcodeType.code128:
        case BarcodeType.code39:
        case BarcodeType.upca:
        case BarcodeType.codabar:
          return true;
        case BarcodeType.qrcode:
          // QR code bisa handle berbagai format data
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Helper untuk check apakah string hanya berisi digit
  static bool _isNumeric(String s) => double.tryParse(s) != null;

  @override
  String toString() {
    return 'BarcodeData(data: $data, type: $type, height: $height, width: $width, withLabel: $withLabel)';
  }
}
