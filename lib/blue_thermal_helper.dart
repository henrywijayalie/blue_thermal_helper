library;

import 'dart:async';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';

// Public API exports
export 'src/models/bluetooth_printer.dart';
export 'src/models/thermal_paper.dart';
export 'src/models/font_size.dart';
export 'src/models/barcode_data.dart';
export 'thermal_receipt.dart';

// Internal imports (not exported)
import 'src/models/bluetooth_printer.dart';
import 'src/models/thermal_paper.dart';
import 'src/models/font_size.dart';
import 'src/utils/formatting_utils.dart' as utils;
import 'thermal_receipt.dart';

/// A Flutter plugin for Bluetooth thermal printer (ESC/POS).
///
/// This is the main class that provides all printer functionality.
/// Use the singleton [instance] to access all methods.
///
/// See also:
/// - [ThermalReceipt] for receipt building APIs
/// - [ThermalPaper] for paper size configuration
/// - [BluetoothPrinter] for printer device model
class BlueThermalHelper {
  BlueThermalHelper._internal();

  /// Singleton instance of [BlueThermalHelper].
  ///
  /// Use this instance to access all printer functionality:
  /// ```dart
  /// final printer = BlueThermalHelper.instance;
  /// ```
  static final BlueThermalHelper instance = BlueThermalHelper._internal();

  // Platform channels
  final MethodChannel _method =
      const MethodChannel('blue_thermal_helper/methods');
  final EventChannel _event = const EventChannel('blue_thermal_helper/events');

  // Events stream
  Stream<Map<String, dynamic>>? _eventsStream;

  /// Stream of printer events.
  ///
  /// Listen to this stream to receive real-time updates about:
  /// - Connection status changes
  /// - Errors
  /// - Reconnection attempts
  ///
  /// Example:
  /// ```dart
  /// printer.events.listen((event) {
  ///   print('Event: ${event['event']}');
  ///   if (event['event'] == 'connected') {
  ///     print('Connected to: ${event['mac']}');
  ///   }
  /// });
  /// ```
  ///
  /// Common events:
  /// - `connected`: Successfully connected to printer
  /// - `disconnected`: Disconnected from printer
  /// - `error`: An error occurred
  /// - `reconnecting`: Attempting to reconnect
  /// - `reconnected`: Successfully reconnected
  Stream<Map<String, dynamic>> get events {
    _eventsStream ??=
        _event.receiveBroadcastStream().map<Map<String, dynamic>>((dynamic e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      } else {
        return <String, dynamic>{'event': e.toString()};
      }
    }).asBroadcastStream();
    return _eventsStream!;
  }

  // Paper state (in-memory)
  ThermalPaper _paper = ThermalPaper.mm58;

  /// Sets the paper size for printing.
  ///
  /// This must be called before printing to ensure correct formatting.
  /// The paper size affects:
  /// - Characters per line
  /// - Image width
  /// - Receipt layout
  ///
  /// Example:
  /// ```dart
  /// printer.setPaper(ThermalPaper.mm58); // For 58mm paper
  /// printer.setPaper(ThermalPaper.mm80); // For 80mm paper
  /// ```
  void setPaper(ThermalPaper paper) => _paper = paper;

  /// Gets the currently configured paper size.
  ThermalPaper get paper => _paper;

  /// Gets the number of characters per line for the current paper size.
  ///
  /// This is useful for manual text formatting.
  int get charsPerLine => ThermalPaperHelper.charsPerLine(_paper);

  /// Gets the [PaperSize] enum value for use with esc_pos_utils_plus.
  PaperSize get paperSize => ThermalPaperHelper.paperSize(_paper);

  /// Checks if Bluetooth is currently enabled on the device.
  ///
  /// Returns `true` if Bluetooth is on, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await printer.isBluetoothOn()) {
  ///   // Proceed with scanning
  /// } else {
  ///   // Request user to enable Bluetooth
  /// }
  /// ```
  Future<bool> isBluetoothOn() async {
    final bool? res = await _method.invokeMethod<bool>('isBluetoothOn');
    return res ?? false;
  }

  /// Requests the user to enable Bluetooth.
  ///
  /// On Android, this shows the system Bluetooth enable dialog.
  /// On iOS, this is not applicable as Bluetooth cannot be programmatically enabled.
  ///
  /// Example:
  /// ```dart
  /// if (!await printer.isBluetoothOn()) {
  ///   await printer.requestEnableBluetooth();
  /// }
  /// ```
  Future<void> requestEnableBluetooth() async {
    await _method.invokeMethod('requestEnableBluetooth');
  }

  // -------------------------
  // Bluetooth Operations
  // -------------------------

  /// Scans for paired Bluetooth devices.
  ///
  /// Returns a list of [BluetoothPrinter] devices that are already
  /// paired with the device. Does not perform discovery of new devices.
  ///
  /// Parameters:
  /// - [timeout]: Maximum time to wait for scan (default: 8 seconds)
  ///
  /// Throws [PlatformException] if:
  /// - Bluetooth permissions are not granted
  /// - Bluetooth is disabled
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final devices = await printer.scan(timeout: 10);
  ///   for (var device in devices) {
  ///     print('${device.name} - ${device.address}');
  ///   }
  /// } catch (e) {
  ///   print('Scan failed: $e');
  /// }
  /// ```
  Future<List<BluetoothPrinter>> scan({int timeout = 8}) async {
    try {
      final res = await _method.invokeMethod('scan', {'timeout': timeout});
      if (res == null) return [];
      final list = res as List;
      return list.map((e) {
        final map = Map<dynamic, dynamic>.from(e as Map);
        return BluetoothPrinter.fromPlatform(map);
      }).toList();
    } on PlatformException {
      rethrow;
    }
  }

  /// Connects to a Bluetooth printer by MAC address.
  ///
  /// Parameters:
  /// - [mac]: The MAC address of the printer (e.g., "00:11:22:33:44:55")
  ///
  /// Returns `true` if connection is successful, `false` otherwise.
  ///
  /// Throws [PlatformException] if:
  /// - Bluetooth permissions are not granted
  /// - Device is not paired
  /// - Connection fails
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final success = await printer.connect('00:11:22:33:44:55');
  ///   if (success) {
  ///     print('Connected successfully');
  ///   }
  /// } catch (e) {
  ///   print('Connection failed: $e');
  /// }
  /// ```
  Future<bool> connect(String mac) async {
    try {
      final res = await _method.invokeMethod('connect', {'mac': mac});
      return res == true;
    } on PlatformException {
      rethrow;
    }
  }

  /// Disconnects from the currently connected printer.
  ///
  /// It's safe to call this even if not connected.
  ///
  /// Example:
  /// ```dart
  /// await printer.disconnect();
  /// ```
  Future<void> disconnect() async {
    try {
      await _method.invokeMethod('disconnect');
    } on PlatformException {
      rethrow;
    }
  }

  /// Checks if currently connected to a printer.
  ///
  /// Returns `true` if connected, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await printer.isConnected()) {
  ///   // Safe to print
  /// } else {
  ///   // Need to connect first
  /// }
  /// ```
  Future<bool> isConnected() async {
    try {
      final res = await _method.invokeMethod('isConnected');
      return res == true;
    } on PlatformException {
      return false;
    }
  }

  /// Sends raw bytes to the printer.
  ///
  /// This is a low-level method. Most users should use [printReceipt] instead.
  ///
  /// Parameters:
  /// - [bytes]: ESC/POS command bytes to send
  ///
  /// Throws [PlatformException] if:
  /// - Not connected to printer
  /// - IO error occurs
  ///
  /// Example:
  /// ```dart
  /// final bytes = [0x1B, 0x40]; // ESC @ (initialize printer)
  /// await printer.printBytes(bytes);
  /// ```
  Future<void> printBytes(List<int> bytes) async {
    try {
      await _method.invokeMethod('printBytes', {'bytes': bytes});
    } on PlatformException {
      rethrow;
    }
  }

  // -------------------------
  // High-level Printing APIs
  // -------------------------

  /// Builds and prints a receipt using the builder pattern.
  ///
  /// This is the recommended way to print receipts. The builder function
  /// receives a [ThermalReceipt] instance that provides high-level methods
  /// for building receipt content.
  ///
  /// Parameters:
  /// - [builder]: Function that builds the receipt content
  /// - [paperOverride]: Optional paper size override (uses [setPaper] value if not provided)
  ///
  /// Example:
  /// ```dart
  /// await printer.printReceipt((r) async {
  ///   r.text('STORE NAME', bold: true, center: true, size: ThermalFontSize.large);
  ///   r.hr();
  ///   r.row('Item', 'Price');
  ///   r.row('Coffee', '15.000');
  ///   r.hr();
  ///   r.row('TOTAL', '15.000', bold: true);
  ///   r.feed(2);
  ///   r.cut();
  /// });
  /// ```
  Future<void> printReceipt(
    Future<void> Function(ThermalReceipt r) builder, {
    ThermalPaper? paperOverride,
  }) async {
    final paperToUse = paperOverride ?? _paper;
    final genPaper = ThermalPaperHelper.paperSize(paperToUse);

    final receipt = await ThermalReceipt.create(paper: genPaper);
    await builder(receipt);
    final bytes = receipt.build();
    await printBytes(bytes);
  }

  /// Builds a receipt and returns a text preview.
  ///
  /// Useful for showing users what will be printed before actually printing.
  ///
  /// Parameters:
  /// - [builder]: Function that builds the receipt content
  /// - [paperOverride]: Optional paper size override
  ///
  /// Returns: Text representation of the receipt
  ///
  /// Example:
  /// ```dart
  /// final preview = await printer.previewReceipt((r) async {
  ///   r.text('TEST RECEIPT', center: true);
  ///   r.row('Item', 'Price');
  /// });
  /// print(preview);
  /// ```
  Future<String> previewReceipt(
    Future<void> Function(ThermalReceipt r) builder, {
    ThermalPaper? paperOverride,
  }) async {
    final paperToUse = paperOverride ?? _paper;
    final genPaper = ThermalPaperHelper.paperSize(paperToUse);

    final receipt = await ThermalReceipt.create(paper: genPaper);
    await builder(receipt);
    return receipt.preview();
  }

  // -------------------------
  // JSON-based Printing
  // -------------------------

  /// Prints a receipt from JSON data.
  ///
  /// This is useful for backend-driven receipt generation where the
  /// receipt structure comes from an API.
  ///
  /// JSON structure:
  /// ```json
  /// {
  ///   "logo": "base64_or_asset_path",
  ///   "header": {
  ///     "title": "STORE NAME",
  ///     "subtitle": "Address line"
  ///   },
  ///   "items": [
  ///     {"name": "Item 1", "qty": 2, "price": 15000, "note": "Optional note"}
  ///   ],
  ///   "total": 30000,
  ///   "footer": "Thank you"
  /// }
  /// ```
  ///
  /// Parameters:
  /// - [data]: JSON map containing receipt data
  /// - [printerMac]: Optional MAC address (reserved for future use)
  /// - [paper]: Optional paper size override
  ///
  /// Example:
  /// ```dart
  /// final receiptData = {
  ///   'header': {'title': 'MY STORE'},
  ///   'items': [
  ///     {'name': 'Coffee', 'qty': 1, 'price': 15000}
  ///   ],
  ///   'total': 15000,
  /// };
  /// await printer.printFromJson(receiptData);
  /// ```
  Future<void> printFromJson(
    Map<String, dynamic> data, {
    String? printerMac,
    ThermalPaper? paper,
  }) async {
    final paperToUse = paper ?? _paper;
    final genPaper = ThermalPaperHelper.paperSize(paperToUse);
    final chars = ThermalPaperHelper.charsPerLine(paperToUse);

    final receipt = await ThermalReceipt.create(paper: genPaper);
    await _buildReceiptFromJson(receipt, data, charsPerLine: chars);
    await printBytes(receipt.build());
  }

  /// Generates a preview from JSON data.
  ///
  /// Similar to [printFromJson] but returns a text preview instead of printing.
  ///
  /// Parameters:
  /// - [data]: JSON map containing receipt data
  /// - [printerMac]: Optional MAC address (reserved for future use)
  /// - [paper]: Optional paper size override
  ///
  /// Returns: Text representation of the receipt
  Future<String> previewFromJson(
    Map<String, dynamic> data, {
    String? printerMac,
    ThermalPaper? paper,
  }) async {
    final paperToUse = paper ?? _paper;
    final genPaper = ThermalPaperHelper.paperSize(paperToUse);
    final chars = ThermalPaperHelper.charsPerLine(paperToUse);

    final receipt = await ThermalReceipt.create(paper: genPaper);
    await _buildReceiptFromJson(receipt, data, charsPerLine: chars);
    return receipt.preview();
  }

  // -------------------------
  // Internal Helper Methods
  // -------------------------

  /// Internal method to print an item row with automatic text wrapping.
  void _rowItemAutoWrap({
    required ThermalReceipt receipt,
    required String name,
    required int qty,
    required num price,
    required int charsPerLine,
    int leftCols = 7,
    int rightCols = 5,
    FontSize size = FontSize.normal,
  }) {
    final totalCols = leftCols + rightCols;
    final leftChars = (charsPerLine * leftCols / totalCols).floor();
    final rightChars = charsPerLine - leftChars;

    final priceText = '$qty x ${utils.formatMoney(price)}';

    final leftLines = utils.wrapText(name, leftChars);
    final rightLines = utils.wrapText(priceText, rightChars);

    final maxLines = leftLines.length > rightLines.length
        ? leftLines.length
        : rightLines.length;

    for (var i = 0; i < maxLines; i++) {
      final leftPart = (i < leftLines.length) ? leftLines[i] : '';
      final rightPart = (i < rightLines.length) ? rightLines[i] : '';

      if (i == 0) {
        receipt.rowColumns([
          receipt.col(leftPart, leftCols, size: size),
          receipt.col(rightPart, rightCols, size: size, align: PosAlign.right),
        ]);
      } else {
        receipt.rowColumns([
          receipt.col(leftPart, leftCols, size: size),
          receipt.col('', rightCols),
        ]);
      }
    }
  }

  /// Internal method to build receipt from JSON data.
  Future<void> _buildReceiptFromJson(
    ThermalReceipt r,
    Map<String, dynamic> json, {
    required int charsPerLine,
  }) async {
    // logo
    if (json.containsKey('logo') &&
        json['logo'] is String &&
        (json['logo'] as String).isNotEmpty) {
      try {
        await r.logo(json['logo'] as Uint8List);
      } catch (_) {
        // Silently fail if logo cannot be loaded
      }
    }

    // header
    if (json.containsKey('header') && json['header'] is Map) {
      final h = json['header'] as Map<String, dynamic>;
      if (h.containsKey('title')) {
        r.text(h['title'].toString(),
            bold: true, center: true, size: FontSize.large);
      }
      if (h.containsKey('subtitle')) {
        r.text(h['subtitle'].toString(), center: true);
      }
      r.hr();
    }

    // items
    if (json.containsKey('items') && json['items'] is List) {
      final items = json['items'] as List;
      for (var it in items) {
        if (it is Map<String, dynamic>) {
          final name = (it['name'] ?? '').toString();
          final qty = (it['qty'] is num)
              ? (it['qty'] as num).toInt()
              : int.tryParse((it['qty'] ?? '0').toString()) ?? 0;
          final price = (it['price'] is num)
              ? it['price'] as num
              : num.tryParse((it['price'] ?? '0').toString()) ?? 0;

          _rowItemAutoWrap(
            receipt: r,
            name: name,
            qty: qty,
            price: price,
            charsPerLine: charsPerLine,
          );

          if (it.containsKey('note') &&
              (it['note']?.toString().isNotEmpty ?? false)) {
            r.note(it['note'].toString());
          }
        }
      }
    }

    // total
    if (json.containsKey('total')) {
      final totalVal = json['total'];
      final totalNum =
          (totalVal is num) ? totalVal : num.tryParse(totalVal.toString()) ?? 0;
      r.hr();
      r.rowColumns([
        r.col('TOTAL', 6, bold: true),
        r.col(utils.formatMoney(totalNum), 6,
            bold: true, align: PosAlign.right),
      ]);
    }

    // footer
    if (json.containsKey('footer') &&
        (json['footer']?.toString().isNotEmpty ?? false)) {
      r.feed(1);
      r.text(json['footer'].toString(), center: true);
    }

    r.feed(2);
    r.cut();
  }
}
