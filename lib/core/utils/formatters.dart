import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String npr(num amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return 'NPR ${formatter.format(amount)}';
  }

  /// Full price value with thousands separators: 25000 -> 25,000.
  /// Used everywhere a price is displayed (no K/L abbreviation).
  static String amount(num value) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // HH:mm — used in chat message timestamps
  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }
}
