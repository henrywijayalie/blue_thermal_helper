// lib/blue_thermal_helper.dart
import 'dart:async';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart';
import 'thermal_receipt.dart'; // sesuaikan path jika berbeda

/// Simple model
class BluetoothPrinter {
  final String name;
  final String address;

  BluetoothPrinter({required this.name, required this.address});

  factory BluetoothPrinter.fromPlatform(Map<dynamic, dynamic> map) {
    return BluetoothPrinter(
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
    );
  }
}

/// Paper enum
enum ThermalPaper {
  mm58,
  mm80
}

/// Small helper mapping for paper -> properties
class ThermalPaperHelper {
  static int charsPerLine(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return 48;
      case ThermalPaper.mm58:
        return 32;
    }
  }

  static PaperSize paperSize(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return PaperSize.mm80;
      case ThermalPaper.mm58:
        return PaperSize.mm58;
    }
  }

  static int maxImageWidthPx(ThermalPaper paper) {
    switch (paper) {
      case ThermalPaper.mm80:
        return 576;
      case ThermalPaper.mm58:
        return 384;
    }
  }

  static String displayName(ThermalPaper p) => p == ThermalPaper.mm80 ? '80 mm' : '58 mm';
}

/// BlueThermalHelper singleton
class BlueThermalHelper {
  BlueThermalHelper._internal();

  static final BlueThermalHelper instance = BlueThermalHelper._internal();

  // Channels
  final MethodChannel _method = const MethodChannel('blue_thermal_helper/methods');
  final EventChannel _event = const EventChannel('blue_thermal_helper/events');

  // Events stream
  Stream<Map<String, dynamic>>? _eventsStream;
  Stream<Map<String, dynamic>> get events {
    _eventsStream ??= _event.receiveBroadcastStream().map<Map<String, dynamic>>((dynamic e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      } else {
        return <String, dynamic>{
          'event': e.toString()
        };
      }
    }).asBroadcastStream();
    return _eventsStream!;
  }

  // Paper state (in-memory). Call setPaper(...) from UI when user chooses.
  ThermalPaper _paper = ThermalPaper.mm58;
  void setPaper(ThermalPaper paper) => _paper = paper;
  ThermalPaper get paper => _paper;
  int get charsPerLine => ThermalPaperHelper.charsPerLine(_paper);
  PaperSize get paperSize => ThermalPaperHelper.paperSize(_paper);

  // -------------------------
  // Basic MethodChannel wrappers
  // -------------------------
  Future<List<BluetoothPrinter>> scan({int timeout = 8}) async {
    try {
      final res = await _method.invokeMethod('scan', {
        'timeout': timeout
      });
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

  Future<bool> connect(String mac) async {
    try {
      final res = await _method.invokeMethod('connect', {
        'mac': mac
      });
      // plugin should return true on success
      return res == true;
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _method.invokeMethod('disconnect');
    } on PlatformException {
      rethrow;
    }
  }

  Future<bool> isConnected() async {
    try {
      final res = await _method.invokeMethod('isConnected');
      return res == true;
    } on PlatformException {
      return false;
    }
  }

  /// low-level write (send bytes to native)
  Future<void> printBytes(List<int> bytes) async {
    try {
      await _method.invokeMethod('printBytes', {
        'bytes': bytes
      });
    } on PlatformException {
      rethrow;
    }
  }

  // -------------------------
  // High-level helpers: printReceipt / previewReceipt
  // -------------------------
  /// Build receipt with provided builder and send bytes to printer.
  /// Uses the helper.paper (PaperSize) automatically.
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

  /// Build receipt and return preview text-only
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
  // JSON based printing helpers (uses internal builders)
  // -------------------------
  Future<void> printFromJson(
    Map<String, dynamic> data, {
    String? printerMac,
    ThermalPaper? paper, // optional override
  }) async {
    final paperToUse = paper ?? _paper;
    final genPaper = ThermalPaperHelper.paperSize(paperToUse);
    final chars = ThermalPaperHelper.charsPerLine(paperToUse);

    final receipt = await ThermalReceipt.create(paper: genPaper);
    await _buildReceiptFromJson(receipt, data, charsPerLine: chars);
    await printBytes(receipt.build());
  }

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
  // Internal helpers: money formatter, wrap, item builder, json builder
  // -------------------------
  String _formatMoney(num value) {
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

  List<String> _wrapText(String text, int maxChars) {
    if (text.isEmpty) {
      return [
        ''
      ];
    }
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var cur = StringBuffer();

    for (var w in words) {
      if (w.length > maxChars) {
        if (cur.isNotEmpty) {
          lines.add(cur.toString());
          cur = StringBuffer();
        }
        var pos = 0;
        while (pos < w.length) {
          final end = (pos + maxChars < w.length) ? pos + maxChars : w.length;
          lines.add(w.substring(pos, end));
          pos = end;
        }
        continue;
      }

      if (cur.isEmpty) {
        cur.write(w);
      } else if (cur.length + 1 + w.length <= maxChars) {
        cur.write(' ');
        cur.write(w);
      } else {
        lines.add(cur.toString());
        cur = StringBuffer();
        cur.write(w);
      }
    }

    if (cur.isNotEmpty) lines.add(cur.toString());
    return lines;
  }

  void _rowItemAutoWrap({
    required ThermalReceipt receipt,
    required String name,
    required int qty,
    required num price,
    required int charsPerLine,
    int leftCols = 7,
    int rightCols = 5,
    ThermalFontSize size = ThermalFontSize.normal,
  }) {
    final totalCols = leftCols + rightCols;
    final leftChars = (charsPerLine * leftCols / totalCols).floor();
    final rightChars = charsPerLine - leftChars;

    final priceText = '$qty x ${_formatMoney(price)}';

    final leftLines = _wrapText(name, leftChars);
    final rightLines = _wrapText(priceText, rightChars);

    final maxLines = leftLines.length > rightLines.length ? leftLines.length : rightLines.length;

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

  Future<void> _buildReceiptFromJson(
    ThermalReceipt r,
    Map<String, dynamic> json, {
    required int charsPerLine,
  }) async {
    // logo
    if (json.containsKey('logo') && json['logo'] is String && (json['logo'] as String).isNotEmpty) {
      try {
        await r.logo(json['logo'] as Uint8List);
      } catch (_) {}
    }

    // header
    if (json.containsKey('header') && json['header'] is Map) {
      final h = json['header'] as Map<String, dynamic>;
      if (h.containsKey('title')) {
        r.text(h['title'].toString(), bold: true, center: true, size: ThermalFontSize.large);
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
          final qty = (it['qty'] is num) ? (it['qty'] as num).toInt() : int.tryParse((it['qty'] ?? '0').toString()) ?? 0;
          final price = (it['price'] is num) ? it['price'] as num : num.tryParse((it['price'] ?? '0').toString()) ?? 0;

          _rowItemAutoWrap(
            receipt: r,
            name: name,
            qty: qty,
            price: price,
            charsPerLine: charsPerLine,
          );

          if (it.containsKey('note') && (it['note']?.toString().isNotEmpty ?? false)) {
            r.note(it['note'].toString());
          }
        }
      }
    }

    // total
    if (json.containsKey('total')) {
      final totalVal = json['total'];
      final totalNum = (totalVal is num) ? totalVal : num.tryParse(totalVal.toString()) ?? 0;
      r.hr();
      r.rowColumns([
        r.col('TOTAL', 6, bold: true),
        r.col(_formatMoney(totalNum), 6, bold: true, align: PosAlign.right),
      ]);
    }

    // footer
    if (json.containsKey('footer') && (json['footer']?.toString().isNotEmpty ?? false)) {
      r.feed(1);
      r.text(json['footer'].toString(), center: true);
    }

    r.feed(2);
    r.cut();
  }
}
