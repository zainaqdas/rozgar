import 'package:intl/intl.dart';

final _pkrFormat = NumberFormat.currency(
  symbol: 'Rs. ',
  decimalDigits: 0,
  locale: 'en_PK',
);

String formatPkr(double amount) {
  if (amount < 0) {
    return '-${_pkrFormat.format(amount.abs())}';
  }
  return _pkrFormat.format(amount);
}

String formatTime(DateTime dateTime) {
  return DateFormat('h:mm a').format(dateTime);
}

String formatDateShort(DateTime dateTime) {
  return DateFormat('MMM d, yyyy').format(dateTime);
}

String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.isNegative) return 'Just now';
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDateShort(dateTime);
}
