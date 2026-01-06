// lib/receipt_utils.dart
import 'package:blue_thermal_helper/thermal_receipt.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
// import ThermalReceipt, ThermalFontSize, PosAlign if needed

/// Format number like 1234567 -> 1.234.567
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

/// Wrap a single paragraph into lines with maxChars
List<String> wrapText(String text, int maxChars) {
  final words = text.split(RegExp(r'\s+'));
  final lines = <String>[];
  var cur = StringBuffer();

  for (var w in words) {
    if (w.length > maxChars) {
      // flush current
      if (cur.isNotEmpty) {
        lines.add(cur.toString());
        cur = StringBuffer();
      }
      // hard split the long word
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

/// rowItemAutoWrap
/// - receipt : ThermalReceipt instance
/// - name : item name
/// - qty : integer
/// - price : numeric unit price (not total)
/// - charsPerLine: default 32 (58mm). Set 48 for 80mm
/// - leftCols / rightCols : proportion in 12-grid (default left 7 / right 5)
void rowItemAutoWrap({
  required ThermalReceipt receipt,
  required String name,
  required int qty,
  required num price,
  int charsPerLine = 32,
  int leftCols = 7,
  int rightCols = 5,
  ThermalFontSize size = ThermalFontSize.normal,
}) {
  // 1) compute char widths from proportions
  final totalCols = leftCols + rightCols;
  final leftChars = (charsPerLine * leftCols / totalCols).floor();
  final rightChars = charsPerLine - leftChars;

  // 2) format right column: "qty x priceFormatted"
  final priceText = '$qty x ${formatMoney(price)}';

  // 3) wrap left name into leftChars
  final leftLines = wrapText(name, leftChars);
  // also wrap right if needed (rare, but safe)
  final rightLines = wrapText(priceText, rightChars);

  final maxLines = leftLines.length > rightLines.length ? leftLines.length : rightLines.length;

  for (var i = 0; i < maxLines; i++) {
    final leftPart = (i < leftLines.length) ? leftLines[i] : '';
    final rightPart = (i == 0) ? (rightLines.isNotEmpty ? rightLines[0] : '') : (i < rightLines.length ? rightLines[i] : '');

    // if first line, print left+right; subsequent lines print left only
    if (i == 0) {
      receipt.rowColumns([
        receipt.col(leftPart, leftCols, size: size),
        receipt.col(rightPart, rightCols, size: size, align: PosAlign.right),
      ]);
    } else {
      // continuation: left part, empty right
      receipt.rowColumns([
        receipt.col(leftPart, leftCols, size: size),
        receipt.col('', rightCols),
      ]);
    }
  }
}

/// Build receipt from JSON-like data (Map). Does NOT change existing ThermalReceipt API.
/// JSON schema example (Map):
/// {
///   "logo": "assets/logo.png", // optional
///   "header": { "title": "TOKO", "subtitle": "Alamat..." },
///   "items": [ { "name":"Nasi Goreng", "qty":2, "price":35000, "note":"pedas" }, ... ],
///   "total": 215000,
///   "footer": "Terima kasih"
/// }
Future<void> buildReceiptFromJson(ThermalReceipt r, Map<String, dynamic> json, {int charsPerLine = 32}) async {
  // logo
  if (json.containsKey('logo') && json['logo'] is String) {
    try {
      await r.logo(json['logo'] as String);
    } catch (_) {
      // ignore if logo fails
    }
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
        // print item with auto-wrap
        rowItemAutoWrap(
          receipt: r,
          name: name,
          qty: qty,
          price: price,
          charsPerLine: charsPerLine,
        );

        // optional note
        if (it.containsKey('note') && (it['note']?.toString().isNotEmpty ?? false)) {
          r.note(it['note'].toString());
        }
      }
    }
  }

  // total (if provided)
  if (json.containsKey('total')) {
    final total = json['total'];
    final totalNum = (total is num) ? total : num.tryParse(total.toString()) ?? 0;
    r.hr();
    // right column with money
    r.rowColumns([
      r.col('TOTAL', 6, bold: true),
      r.col(formatMoney(totalNum), 6, bold: true, align: PosAlign.right),
    ]);
  }

  // footer
  if (json.containsKey('footer')) {
    r.feed(1);
    r.text(json['footer'].toString(), center: true);
  }

  r.feed(2);
  r.cut();
}
