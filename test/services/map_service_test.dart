import 'package:flutter_test/flutter_test.dart';
import 'package:rozgar/services/map_service.dart';

void main() {
  group('MapService', () {
    setUp(() {
      // Reset to defaults before each test
      MapService.instance.setUseOsm();
    });

    test('defaults to OSM provider', () {
      expect(MapService.instance.provider, MapProviderType.osm);
      expect(MapService.instance.useGoogleMaps, false);
    });

    test('can switch to Google Maps', () {
      MapService.instance.setUseGoogleMaps();
      expect(MapService.instance.provider, MapProviderType.googleMaps);
      expect(MapService.instance.useGoogleMaps, true);
    });

    test('can switch back to OSM', () {
      MapService.instance.setUseGoogleMaps();
      MapService.instance.setUseOsm();
      expect(MapService.instance.provider, MapProviderType.osm);
    });
  });

  group('MapMarker', () {
    test('creates employer marker correctly', () {
      final marker = MapMarker(
        id: 'emp-1',
        lat: 31.5204,
        lng: 74.3587,
        title: 'Employer Location',
        isEmployer: true,
      );

      expect(marker.isEmployer, true);
      expect(marker.snippet, isNull);
      expect(marker.onTap, isNull);
    });

    test('creates worker marker correctly', () {
      final marker = MapMarker(
        id: 'wrk-1',
        lat: 31.522,
        lng: 74.356,
        title: 'Worker Name',
        snippet: '4.9',
        isEmployer: false,
      );

      expect(marker.isEmployer, false);
      expect(marker.snippet, '4.9');
    });

    test('markers with same id but different coords are not equal', () {
      final a = MapMarker(id: 'w1', lat: 31.5, lng: 74.3, title: 'A');
      final b = MapMarker(id: 'w1', lat: 31.6, lng: 74.4, title: 'A');
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });

    test('markers with same id and coords are equal', () {
      final a = MapMarker(id: 'w1', lat: 31.5, lng: 74.3, title: 'A');
      final b = MapMarker(id: 'w1', lat: 31.5, lng: 74.3, title: 'A');
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('markers with same id and coords but different title are not equal', () {
      final a = MapMarker(id: 'w1', lat: 31.5, lng: 74.3, title: 'A');
      final b = MapMarker(id: 'w1', lat: 31.5, lng: 74.3, title: 'B');
      expect(a == b, isFalse);
    });
  });
}
