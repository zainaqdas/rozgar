import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/utils/formatters.dart';

void main() {
  group('formatPkr', () {
    test('formats whole numbers correctly', () {
      expect(formatPkr(2500), contains('Rs.'));
      expect(formatPkr(2500), contains('2,500'));
    });

    test('formats zero', () {
      expect(formatPkr(0), contains('Rs.'));
      expect(formatPkr(0), contains('0'));
    });

    test('formats negative amounts with leading minus', () {
      final result = formatPkr(-500);
      expect(result, startsWith('-'));
      expect(result, contains('Rs.'));
      expect(result, contains('500'));
    });

    test('formats large numbers', () {
      expect(formatPkr(100000), contains('Rs.'));
    });
  });

  group('formatTime', () {
    test('returns time in h:mm a format', () {
      final time = DateTime(2024, 1, 1, 14, 30);
      final formatted = formatTime(time);
      expect(formatted, contains('2:30'));
      // Should contain either AM or PM
      expect(formatted.contains('AM') || formatted.contains('PM'), true);
    });
  });

  group('formatDateShort', () {
    test('returns MMM d, yyyy format', () {
      final date = DateTime(2024, 6, 15);
      expect(formatDateShort(date), 'Jun 15, 2024');
    });
  });

  group('timeAgo', () {
    test('returns "Just now" for recent times', () {
      final now = DateTime.now();
      expect(timeAgo(now), 'Just now');
    });

    test('returns minutes ago', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(timeAgo(fiveMinAgo), '5m ago');
    });

    test('returns hours ago', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      expect(timeAgo(threeHoursAgo), '3h ago');
    });

    test('returns days ago', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      expect(timeAgo(twoDaysAgo), '2d ago');
    });

    test('returns date for older dates', () {
      final lastYear = DateTime(2023, 1, 1);
      final formatted = timeAgo(lastYear);
      expect(formatted, contains('Jan 1'));
    });
  });
}
