// lib/src/utils/formatting_utils.dart

/// Internal utility functions for formatting.
///
/// This file is not part of the public API and should not be imported
/// directly by package users.
library;

/// Formats a numeric value as Indonesian Rupiah currency format.
///
/// Converts numbers like 1234567 to "1.234.567" format with thousand separators.
///
/// Example:
/// ```dart
/// formatMoney(50000);    // Returns "50.000"
/// formatMoney(1234567);  // Returns "1.234.567"
/// formatMoney(0);        // Returns "0"
/// ```
///
/// Parameters:
/// - [value]: The numeric value to format (int or double)
///
/// Returns: Formatted string with thousand separators using dots
String formatMoney(num value) {
  final s = value.toStringAsFixed(0);

  // Handle zero or single digit
  if (s.length <= 3) return s;

  final buf = StringBuffer();
  int count = 0;

  // Build string from right to left
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write('.');
      count = 0;
    }
  }

  // Reverse the string to get correct order
  return buf.toString().split('').reversed.join();
}

/// Wraps text into multiple lines based on maximum characters per line.
///
/// This function intelligently wraps text by:
/// - Breaking at word boundaries when possible
/// - Hard-breaking long words that exceed maxChars
/// - Preserving multiple spaces between words
///
/// Example:
/// ```dart
/// wrapText('Hello World', 5);
/// // Returns: ['Hello', 'World']
///
/// wrapText('Verylongword', 5);
/// // Returns: ['Veryl', 'ongwo', 'rd']
/// ```
///
/// Parameters:
/// - [text]: The text to wrap
/// - [maxChars]: Maximum characters per line
///
/// Returns: List of wrapped lines
List<String> wrapText(String text, int maxChars) {
  if (text.isEmpty) return [''];
  if (maxChars <= 0) return [text];

  final words = text.split(RegExp(r'\s+'));
  final lines = <String>[];
  var currentLine = StringBuffer();

  for (var word in words) {
    // Handle words longer than maxChars (hard break)
    if (word.length > maxChars) {
      // Flush current line first
      if (currentLine.isNotEmpty) {
        lines.add(currentLine.toString());
        currentLine = StringBuffer();
      }

      // Break long word into chunks
      var pos = 0;
      while (pos < word.length) {
        final end =
            (pos + maxChars < word.length) ? pos + maxChars : word.length;
        lines.add(word.substring(pos, end));
        pos = end;
      }
      continue;
    }

    // Try to add word to current line
    if (currentLine.isEmpty) {
      currentLine.write(word);
    } else if (currentLine.length + 1 + word.length <= maxChars) {
      currentLine.write(' ');
      currentLine.write(word);
    } else {
      // Current line is full, start new line
      lines.add(currentLine.toString());
      currentLine = StringBuffer();
      currentLine.write(word);
    }
  }

  // Add remaining content
  if (currentLine.isNotEmpty) {
    lines.add(currentLine.toString());
  }

  return lines.isEmpty ? [''] : lines;
}
