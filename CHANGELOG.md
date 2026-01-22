# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.9] - 2026-01-22

### Fixed

- **Further Adjustment for Text Wrapping**
  - Adjusted column split from 4-8 to 3-9 for small/normal fonts
  - Prevents last digit from wrapping to next line for very long values
  - Supports values up to ~30 characters on 58mm paper without any wrapping
  - Large fonts use 4-8 split

---

## [1.0.8] - 2026-01-22

### Fixed

- **Text Wrapping Issue for Long Values**
  - Fixed critical issue where long values (e.g., reference numbers 23+ chars) in `row()` method would wrap to next line
  - Changed column width allocation from 6-6 to 3-9 split for small/normal fonts
  - Gives maximum space to value column (right side) to accommodate very long text
  - Large fonts use 4-8 split to balance space with larger character size
  - Ensures label and value stay on the same line even with very long values (up to ~30 characters on 58mm paper)
  - Resolves regression introduced when adding `size` parameter to `row()` method

---

## [1.0.7] - 2026-01-22

### Added

- **Enhanced `row()` Method**
  - Added optional `bold` parameter to `row()` method for bold text styling
  - Added optional `size` parameter to `row()` method for font size control (using `ThermalFontSize` enum)
  - Allows more flexible formatting of two-column rows without using `rowColumns()` directly
  - Example: `receipt.row('Total', '100000', bold: true, size: ThermalFontSize.large)`

---

## [1.0.6] - 2026-01-22

### Added

- **Extra Small Font Size Support**
  - Added `ThermalFontSize.extraSmall` enum value
  - Uses alternative font (fontB) for smaller text rendering
  - Useful for detailed information like long addresses, footnotes, or disclaimers
  - Example usage in sample app for address and footer text

### Changed

- Updated example app to demonstrate `extraSmall` font size usage
- Enhanced documentation with font size examples

---

## [1.0.5] - 2026-01-22

### Improvements

- **Code Quality Improvements**
  - Removed code duplication: consolidated `formatMoney()` and `wrapText()` into shared utilities
  - Refactored internal structure: moved models to `lib/src/models/`
  - Moved utilities to `lib/src/utils/` (internal, not exported)
  - Cleaned up example app: removed commented code, improved formatting
  - Standardized naming conventions throughout codebase

- **Documentation**
  - Added comprehensive dartdoc comments to all public APIs
  - Improved code examples in documentation
  - Added detailed parameter descriptions
  - Enhanced README with better examples

- **API Improvements**
  - Better separation of public vs internal APIs
  - Cleaner export structure in main library file
  - More consistent error handling

### Fixed

- Import issues in example app
- Inconsistent formatting in example code

### Internal

- Created `lib/src/utils/formatting_utils.dart` for shared utilities
- Created `lib/src/models/bluetooth_printer.dart` for printer model
- Created `lib/src/models/thermal_paper.dart` for paper configuration
- Removed duplicate files: `printer_paper.dart`, `receipt_util.dart`, `receipt_preview.dart`

### Notes

- This is a **non-breaking** release
- All existing code will continue to work without changes
- Internal refactoring improves maintainability without affecting public API

---

## [1.0.4+1] - Previous

- Update README

## [1.0.4] - Previous

- Add Request Enabling Bluetooth ON

## [1.0.3] - Previous

- Bug Fix Logo Function

## [1.0.2] - Previous

- Update README

## [1.0.1] - Previous

- Update README

## [1.0.0] - 2026-01-06

### Features

- BlueThermalHelper core helper
- Scan, connect, disconnect Bluetooth printer
- ThermalReceipt builder abstraction
- ESC/POS real printing support
- Receipt preview (text-based)
- Support paper size via enum (58mm / 80mm)
- Money formatting with auto-alignment
- Auto-wrap item name
- Print receipt from JSON data

### Bug Fixes

- Preview width mismatch with 58mm paper
- Money column alignment edge cases
- Connection status not updating in UI

### Release Notes

- Initial public release
- Tested with 58mm thermal printer

### ✅ Compatibility

Tested on Flutter 3.38.5 with real android devices Oppo Reno 14 and PANDA Thermal Printer PRJ-R58B
