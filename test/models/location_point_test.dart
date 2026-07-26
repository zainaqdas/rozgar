import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/models/location_point.dart';

void main() {
  group('LocationPoint', () {
    test('toJson and fromJson round-trip', () {
      final point = const LocationPoint(
        lat: 31.5204,
        lng: 74.3587,
        address: 'Gulberg III, Lahore',
        city: 'Lahore',
      );

      final json = point.toJson();
      final restored = LocationPoint.fromJson(json);

      expect(restored.lat, 31.5204);
      expect(restored.lng, 74.3587);
      expect(restored.address, 'Gulberg III, Lahore');
      expect(restored.city, 'Lahore');
    });

    test('handles missing optional fields in fromJson', () {
      final json = {'lat': 31.5, 'lng': 74.3};

      final point = LocationPoint.fromJson(json);
      expect(point.lat, 31.5);
      expect(point.lng, 74.3);
      expect(point.address, '');
      expect(point.city, isNull);
    });

    test('toString returns formatted string', () {
      final point = const LocationPoint(
        lat: 31.5204,
        lng: 74.3587,
        address: 'Gulberg, Lahore',
      );

      final str = point.toString();
      expect(str, contains('31.5204'));
      expect(str, contains('74.3587'));
      expect(str, contains('Gulberg, Lahore'));
    });
  });
}
