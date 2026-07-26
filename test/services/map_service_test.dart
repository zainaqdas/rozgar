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
  });
}
