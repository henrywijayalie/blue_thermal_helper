# Versioning & Changelog

Dokumen ini menjelaskan skema versioning dan contoh CHANGELOG untuk package **blue_thermal_helper**.

# Changelog

## [1.0.0] - 2026-01-06

### Added

- BlueThermalHelper core helper
- Scan, connect, disconnect Bluetooth printer
- ThermalReceipt builder abstraction
- ESC/POS real printing support
- Receipt preview (text-based)
- Support paper size via enum (58mm / 80mm)
- Money formatting with auto-alignment
- Auto-wrap item name
- Print receipt from JSON data

### Fixed

- Preview width mismatch with 58mm paper
- Money column alignment edge cases
- Connection status not updating in UI

### Notes

- Initial public release
- Tested with 58mm thermal printer

### ✅ Compatibility #

Tested on Flutter 3.38.5 with real android devices Oppo Reno 14 and PANDA Thermal Printer PRJ-R58B
<!-- 
---
## [0.1.1] - 2026-01-10

--- -->
