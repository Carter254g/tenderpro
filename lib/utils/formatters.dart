// lib/utils/formatters.dart
// Currency, date, and other formatting utilities

import 'package:intl/intl.dart';

class Formatters {
  /// Format value as Kenyan Shillings
  static String kes(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_KE');
    return 'KES ${formatter.format(amount)}';
  }

  /// Compact KES (e.g. 1.2M, 45K)
  static String kesCompact(double amount) {
    if (amount >= 1000000) {
      return 'KES ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'KES ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return kes(amount);
  }

  /// Format a DateTime as readable date
  static String date(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  /// Format as relative time (e.g. "2 days ago")
  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return date(dt);
  }

  /// Safe double parse with fallback
  static double parseDouble(String val, {double fallback = 0}) {
    return double.tryParse(val.replaceAll(',', '')) ?? fallback;
  }

  /// Format a number for display in table
  static String number(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }
}
