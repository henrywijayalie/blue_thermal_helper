// lib/src/models/font_size.dart

/// Model untuk ukuran font dengan validasi range 6pt hingga 32pt
/// 
/// FontSize memungkinkan Anda menentukan ukuran teks secara spesifik,
/// serupa dengan Microsoft Word atau text editor lainnya.
/// 
/// Contoh penggunaan:
/// ```dart
/// final size10 = FontSize(10);  // 10pt
/// final size12 = FontSize(12);  // 12pt
/// final size16 = FontSize(16);  // 16pt
/// ```
class FontSize {
  /// Ukuran font dalam satuan point (pt)
  /// 
  /// Nilai harus berada dalam range 6pt hingga 32pt.
  /// Nilai di luar range ini akan throw FormatException.
  final double sizeInPoints;

  /// Nama preset ukuran font (opsional)
  final String? presetName;

  /// Membuat instance FontSize dengan validasi range 6pt-32pt
  /// 
  /// Parameters:
  /// - [sizeInPoints]: Ukuran font dalam point (6.0 - 32.0)
  /// - [presetName]: Nama preset opsional (contoh: "Body", "Header")
  /// 
  /// Throws [FormatException] jika ukuran di luar range 6pt-32pt
  FontSize(
    this.sizeInPoints, {
    this.presetName,
  }) {
    if (sizeInPoints < 6.0 || sizeInPoints > 32.0) {
      throw FormatException(
        'FontSize harus berada dalam range 6pt hingga 32pt. Diterima: ${sizeInPoints}pt',
      );
    }
  }

  /// Preset FontSize standar: ExtraSmall (6pt)
  static const FontSize extraSmall = FontSize._raw(6.0, 'ExtraSmall');

  /// Preset FontSize standar: Small (8pt)
  static const FontSize small = FontSize._raw(8.0, 'Small');

  /// Preset FontSize standar: Normal (10pt)
  static const FontSize normal = FontSize._raw(10.0, 'Normal');

  /// Preset FontSize standar: Medium (12pt)
  static const FontSize medium = FontSize._raw(12.0, 'Medium');

  /// Preset FontSize standar: Large (16pt)
  static const FontSize large = FontSize._raw(16.0, 'Large');

  /// Preset FontSize standar: ExtraLarge (20pt)
  static const FontSize extraLarge = FontSize._raw(20.0, 'ExtraLarge');

  /// Preset FontSize standar: Header (24pt)
  static const FontSize header = FontSize._raw(24.0, 'Header');

  /// Constructor internal untuk preset constants
  const FontSize._raw(this.sizeInPoints, this.presetName);

  /// Menghitung multiplier width untuk ESC/POS berdasarkan ukuran font
  /// 
  /// Formula: multiplier = (sizeInPoints - 4) / 6
  /// 
  /// Hasil:
  /// - 6pt → 0.33x (width: 1)
  /// - 8pt → 0.67x (width: 1)
  /// - 10pt → 1.0x (width: 1) - ukuran standar
  /// - 16pt → 2.0x (width: 2) - double width
  /// - 24pt → 3.33x (width: 3) - triple width
  int getWidthMultiplier() {
    // Konversi pt ke multiplier dengan formula linear
    final multiplier = ((sizeInPoints - 4) / 6).round();
    return multiplier.clamp(1, 4); // Printer thermal biasanya max 4x
  }

  /// Menghitung multiplier height untuk ESC/POS berdasarkan ukuran font
  /// 
  /// Formula: sama dengan width multiplier untuk hasil yang konsisten
  int getHeightMultiplier() {
    final multiplier = ((sizeInPoints - 4) / 6).round();
    return multiplier.clamp(1, 4); // Printer thermal biasanya max 4x
  }

  /// Estimasi karakter yang bisa ditampilkan per baris untuk paper 58mm
  /// 
  /// Formula: chars = 32 / width_multiplier
  /// 
  /// Contoh:
  /// - 6pt (1x) → ~32 karakter per baris
  /// - 10pt (1x) → ~32 karakter per baris  
  /// - 16pt (2x) → ~16 karakter per baris
  /// - 24pt (3x) → ~10 karakter per baris
  int getCharsPerLine58mm() {
    final widthMul = getWidthMultiplier();
    return (32 / widthMul).round();
  }

  /// Estimasi karakter yang bisa ditampilkan per baris untuk paper 80mm
  /// 
  /// Formula: chars = 48 / width_multiplier
  /// 
  /// Contoh:
  /// - 6pt (1x) → ~48 karakter per baris
  /// - 10pt (1x) → ~48 karakter per baris
  /// - 16pt (2x) → ~24 karakter per baris
  /// - 24pt (3x) → ~16 karakter per baris
  int getCharsPerLine80mm() {
    final widthMul = getWidthMultiplier();
    return (48 / widthMul).round();
  }

  /// Estimasi lebar pixel untuk paper 58mm (berdasarkan 203 DPI standard)
  /// 
  /// 58mm ≈ 464 pixels pada 203 DPI
  /// Dibagi dengan width multiplier untuk mendapatkan pixel per karakter
  int getPixelWidth58mm() {
    final widthMul = getWidthMultiplier();
    return (464 / widthMul).round();
  }

  /// Estimasi lebar pixel untuk paper 80mm (berdasarkan 203 DPI standard)
  /// 
  /// 80mm ≈ 640 pixels pada 203 DPI
  /// Dibagi dengan width multiplier untuk mendapatkan pixel per karakter
  int getPixelWidth80mm() {
    final widthMul = getWidthMultiplier();
    return (640 / widthMul).round();
  }

  @override
  String toString() {
    if (presetName != null) {
      return '$presetName ($sizeInPoints pt)';
    }
    return '${sizeInPoints.toStringAsFixed(1)} pt';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontSize &&
          runtimeType == other.runtimeType &&
          sizeInPoints == other.sizeInPoints;

  @override
  int get hashCode => sizeInPoints.hashCode;
}
