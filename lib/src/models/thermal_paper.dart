// lib/src/models/thermal_paper.dart

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Supported thermal paper sizes.
///
/// This enum defines the paper sizes supported by the plugin.
/// The paper size affects:
/// - Characters per line
/// - Maximum image width
/// - Receipt formatting
///
/// Example:
/// ```dart
/// final printer = BlueThermalHelper.instance;
/// printer.setPaper(ThermalPaper.mm58);
/// ```
enum ThermalPaper {
  /// 58mm thermal paper (common for portable printers).
  ///
  /// Typical specifications:
  /// - Width: 58mm
  /// - Characters per line: ~32 (normal font)
  /// - Max image width: ~384px (at 203 DPI)
  mm58,

  /// 80mm thermal paper (common for POS systems).
  ///
  /// Typical specifications:
  /// - Width: 80mm
  /// - Characters per line: ~48 (normal font)
  /// - Max image width: ~576px (at 203 DPI)
  mm80,
}

/// Helper utilities for thermal paper configuration.
///
/// This class provides static methods to get paper-specific properties
/// such as characters per line, paper size mapping, and image dimensions.
///
/// All methods are static and the class should not be instantiated.
class ThermalPaperHelper {
  // Private constructor to prevent instantiation
  ThermalPaperHelper._();

  /// Returns the estimated number of characters per line for the given paper size.
  ///
  /// This is an approximation based on normal font size (size 1).
  /// Actual character count may vary depending on:
  /// - Font size used
  /// - Character width (proportional fonts)
  /// - Printer model
  ///
  /// Common values:
  /// - 58mm: 32 characters
  /// - 80mm: 48 characters
  ///
  /// Example:
  /// ```dart
  /// final chars = ThermalPaperHelper.charsPerLine(ThermalPaper.mm58);
  /// print(chars); // 32
  /// ```
  static int charsPerLine(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return 48;
      case ThermalPaper.mm58:
        return 32;
    }
  }

  /// Maps [ThermalPaper] enum to [PaperSize] from esc_pos_utils_plus.
  ///
  /// This is used internally to configure the ESC/POS generator
  /// with the correct paper size.
  ///
  /// Example:
  /// ```dart
  /// final size = ThermalPaperHelper.paperSize(ThermalPaper.mm80);
  /// // Returns PaperSize.mm80
  /// ```
  static PaperSize paperSize(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return PaperSize.mm80;
      case ThermalPaper.mm58:
        return PaperSize.mm58;
    }
  }

  /// Returns the maximum recommended image width in pixels for the given paper size.
  ///
  /// These values are conservative estimates based on common thermal printers
  /// with 203 DPI resolution. Images wider than these values may:
  /// - Be automatically scaled down
  /// - Print incorrectly
  /// - Cause printing errors
  ///
  /// Recommended maximum widths:
  /// - 58mm: 384 pixels
  /// - 80mm: 576 pixels
  ///
  /// Example:
  /// ```dart
  /// final maxWidth = ThermalPaperHelper.maxImageWidthPx(ThermalPaper.mm58);
  /// // Resize image to fit: image.resize(maxWidth, ...)
  /// ```
  static int maxImageWidthPx(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return 576; // typical 80mm @203dpi
      case ThermalPaper.mm58:
        return 384; // typical 58mm @203dpi
    }
  }

  /// Parses a string value to [ThermalPaper] enum.
  ///
  /// This method is useful for parsing configuration from:
  /// - User input
  /// - Configuration files
  /// - API responses
  ///
  /// Supported formats (case-insensitive):
  /// - "58", "mm58", "58mm" → ThermalPaper.mm58
  /// - "80", "mm80", "80mm" → ThermalPaper.mm80
  ///
  /// Example:
  /// ```dart
  /// final paper1 = ThermalPaperHelper.parseFromString('58');
  /// final paper2 = ThermalPaperHelper.parseFromString('mm80');
  /// final paper3 = ThermalPaperHelper.parseFromString('80 mm');
  /// ```
  ///
  /// Returns [ThermalPaper.mm58] as default if the value doesn't match 80mm variants.
  static ThermalPaper parseFromString(String value) {
    final normalized = value.toLowerCase().replaceAll(' ', '');
    if (normalized.contains('80')) {
      return ThermalPaper.mm80;
    }
    return ThermalPaper.mm58;
  }

  /// Returns a human-readable display name for the paper size.
  ///
  /// Useful for UI display purposes.
  ///
  /// Example:
  /// ```dart
  /// final name = ThermalPaperHelper.displayName(ThermalPaper.mm58);
  /// print(name); // "58 mm"
  /// ```
  static String displayName(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return '80 mm';
      case ThermalPaper.mm58:
        return '58 mm';
    }
  }
}
