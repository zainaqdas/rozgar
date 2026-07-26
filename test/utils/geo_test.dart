import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/utils/geo.dart';

void main() {
  group('calculateDistanceKm', () {
    test('returns 0 for same coordinates', () {
      final dist = calculateDistanceKm(
        lat1: 31.5204, lng1: 74.3587,
        lat2: 31.5204, lng2: 74.3587,
      );
      expect(dist, 0.0);
    });

    test('calculates Gulberg to Liberty Market distance correctly', () {
      // Gulberg III to Liberty Market ~ 0.4 km
      final dist = calculateDistanceKm(
        lat1: 31.5204, lng1: 74.3587, // Gulberg III
        lat2: 31.522, lng2: 74.356,   // Liberty Market
      );
      expect(dist, greaterThan(0));
      expect(dist, lessThan(1)); // less than 1 km
    });

    test('calculates larger distances correctly', () {
      // Gulberg to DHA ~ 7 km
      final dist = calculateDistanceKm(
        lat1: 31.5204, lng1: 74.3587, // Gulberg III
        lat2: 31.4697, lng2: 74.4027, // DHA Phase 5
      );
      expect(dist, greaterThan(4));
      expect(dist, lessThan(15));
    });

    test('returns consistent results (commutative)', () {
      final d1 = calculateDistanceKm(lat1: 31.5204, lng1: 74.3587, lat2: 31.468, lng2: 74.401);
      final d2 = calculateDistanceKm(lat1: 31.468, lng1: 74.401, lat2: 31.5204, lng2: 74.3587);
      expect(d1, d2);
    });
  });

  group('formatDistance', () {
    test('returns "Very close" for < 200m', () {
      expect(formatDistance(0.1), contains('Very close'));
    });

    test('returns km format for larger distances', () {
      expect(formatDistance(1.5), contains('1.5 km'));
    });
  });

  group('reverseGeocodeMock', () {
    test('returns Islamabad for northern latitudes', () {
      expect(reverseGeocodeMock(33.7, 73.0), contains('Islamabad'));
    });

    test('returns Gulberg for Lahore latitudes', () {
      expect(reverseGeocodeMock(31.53, 74.35), contains('Gulberg'));
    });

    test('returns Model Town for mid Lahore latitudes', () {
      expect(reverseGeocodeMock(31.49, 74.32), contains('Model Town'));
    });

    test('returns DHA for low Lahore latitude + high longitude', () {
      expect(reverseGeocodeMock(31.44, 74.39), contains('DHA'));
    });

    test('returns Johar Town for southern Lahore', () {
      expect(reverseGeocodeMock(31.47, 74.28), contains('Johar Town'));
    });

    test('returns Ferozepur Road for remaining Lahore', () {
      expect(reverseGeocodeMock(31.44, 74.36), contains('Ferozepur'));
    });

    test('returns Karachi for southern latitudes', () {
      expect(reverseGeocodeMock(24.86, 67.0), contains('Karachi'));
    });
  });
}
