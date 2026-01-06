

import 'package:blue_thermal_helper/thermal_receipt.dart';

class ReceiptPreview {
  final StringBuffer _buf = StringBuffer();
  final int baseChars; // e.g. 32 for 58mm, 48 for 80mm

  ReceiptPreview({required this.baseChars});

  int _charsForSize(ThermalFontSize size) {
    // size normal -> multiplier 1; large -> multiplier 2
    final mult = (size == ThermalFontSize.large) ? 2 : 1;
    return (baseChars / mult).floor();
  }

  List<String> _wrapLine(String line, int maxChars) {
    final words = line.split(RegExp(r'\s+'));
    final out = <String>[];
    var cur = StringBuffer();
    for (var w in words) {
      if (cur.length + (cur.isEmpty ? 0 : 1) + w.length <= maxChars) {
        if (cur.isNotEmpty) cur.write(' ');
        cur.write(w);
      } else {
        if (cur.isNotEmpty) {
          out.add(cur.toString());
        }
        // word longer than maxChars -> hard break
        while (w.length > maxChars) {
          out.add(w.substring(0, maxChars));
          w = w.substring(maxChars);
        }
        cur = StringBuffer(w);
      }
    }
    if (cur.isNotEmpty) out.add(cur.toString());
    return out;
  }

  void text(String text, {bool center = false, ThermalFontSize size = ThermalFontSize.normal}) {
    final maxChars = _charsForSize(size);
    final lines = text.split('\n');
    for (var raw in lines) {
      final wrapped = _wrapLine(raw, maxChars);
      for (var l in wrapped) {
        if (center) {
          final leftPad = ((maxChars - l.length) / 2).floor();
          _buf.writeln(' ' * leftPad + l);
        } else {
          _buf.writeln(l);
        }
      }
    }
  }

  void row(String left, String right, {ThermalFontSize size = ThermalFontSize.normal}) {
    final maxChars = _charsForSize(size);
    // allocate columns: try 60% left, 40% right (for 2-column typical)
    final leftWidth = (maxChars * 0.6).floor();
    final rightWidth = maxChars - leftWidth;

    final leftLines = _wrapLine(left, leftWidth);
    final rightLines = _wrapLine(right, rightWidth);

    final maxLines = leftLines.length > rightLines.length ? leftLines.length : rightLines.length;

    for (var i = 0; i < maxLines; i++) {
      final l = (i < leftLines.length) ? leftLines[i] : '';
      final r = (i < rightLines.length) ? rightLines[i] : '';
      final paddedLeft = l.padRight(leftWidth);
      final line = paddedLeft + r.padLeft(rightWidth);
      _buf.writeln(line);
    }
  }

  void hr([int width = -1]) {
    final w = (width > 0) ? width : baseChars;
    _buf.writeln('-' * w);
  }

  void feed([int n = 1]) {
    for (var i = 0; i < n; i++) {
      _buf.writeln();
    }
  }

  void cut() {
    _buf.writeln('-------- CUT --------');
  }

  void logoPlaceholder({bool center = true}) {
    if (center) {
      final pad = ((baseChars - 6) / 2).floor();
      _buf.writeln(' ' * pad + '[LOGO]');
    } else {
      _buf.writeln('[LOGO]');
    }
  }

  @override
  String toString() => _buf.toString();
}
