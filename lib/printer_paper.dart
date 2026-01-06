// lib/printer_paper.dart
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Pilihan kertas yang kita dukung
enum ThermalPaper {
  mm58,
  mm80,
}

/// Helper util untuk mapping ThermalPaper -> properties yang diperlukan
class ThermalPaperHelper {
  /// jumlah karakter per baris (estimasi) untuk mode normal (size normal)
  /// common defaults: 58mm ~ 32 chars, 80mm ~ 48 chars
  static int charsPerLine(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return 48;
      case ThermalPaper.mm58:
      return 32;
    }
  }

  /// mapping ke PaperSize yang dipakai oleh esc_pos_utils_plus
  static PaperSize paperSize(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return PaperSize.mm80;
      case ThermalPaper.mm58:
      return PaperSize.mm58;
    }
  }

  /// perkiraan max pixel width untuk gambar/logo (untuk resize sebelum gen.image)
  /// nilai konservatif yang umum dipakai (203 DPI)
  static int maxImageWidthPx(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return 576; // typical 80mm @203dpi
      case ThermalPaper.mm58:
      return 384; // typical 58mm @203dpi
    }
  }

  /// parse dari string sederhana (mis. '58' atau '80' atau 'mm58' dsb)
  static ThermalPaper parseFromString(String value) {
    final v = value.toLowerCase().replaceAll(' ', '');
    if (v.contains('80')) return ThermalPaper.mm80;
    return ThermalPaper.mm58;
  }

  /// pretty name tampil di UI
  static String displayName(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return '80 mm';
      case ThermalPaper.mm58:
      return '58 mm';
    }
  }
}
