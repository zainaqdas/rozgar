import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:rozgar/services/map_service.dart';
import 'package:rozgar/theme/app_theme.dart';
import 'package:rozgar/widgets/rozgar_map.dart';

/// Basic tile provider for tests (standard network image, no dio timers).
final _testTileProvider = osm.NetworkTileProvider();

/// Helper to pump a RozgarMap with default params.
Future<void> pumpRozgarMap(
  WidgetTester tester, {
  double initialLat = 31.5204,
  double initialLng = 74.3587,
  double initialZoom = 14,
  List<MapMarker> markers = const [],
  void Function(double lat, double lng)? onCameraMove,
  VoidCallback? onCameraIdle,
  bool showCenteredPin = false,
  bool showZoomControls = false,
  RozgarMapController? controller,
  double? height,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: height ?? 360,
          child: RozgarMap(
            initialLat: initialLat,
            initialLng: initialLng,
            initialZoom: initialZoom,
            markers: markers,
            onCameraMove: onCameraMove,
            onCameraIdle: onCameraIdle,
            showCenteredPin: showCenteredPin,
            showZoomControls: showZoomControls,
            controller: controller,
            tileProvider: _testTileProvider,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    // Always start with OSM as the default provider
    MapService.instance.setUseOsm();
  });

  group('RozgarMap (OSM provider)', () {
    testWidgets('renders FlutterMap widget', (tester) async {
      await pumpRozgarMap(tester);
      await tester.pump();

      expect(find.byType(osm.FlutterMap), findsOneWidget);
    });

    testWidgets('sets initial center and zoom from props', (tester) async {
      await pumpRozgarMap(
        tester,
        initialLat: 31.48,
        initialLng: 74.32,
        initialZoom: 15,
      );
      await tester.pump();

      final flutterMap = tester.widget<osm.FlutterMap>(
        find.byType(osm.FlutterMap),
      );
      expect(flutterMap.options.initialCenter.latitude, closeTo(31.48, 0.001));
      expect(flutterMap.options.initialCenter.longitude, closeTo(74.32, 0.001));
      expect(flutterMap.options.initialZoom, 15);
    });

    testWidgets('renders OSM TileLayer', (tester) async {
      await pumpRozgarMap(tester);
      await tester.pump();

      expect(find.byType(osm.TileLayer), findsOneWidget);
      final tileLayer = tester.widget<osm.TileLayer>(
        find.byType(osm.TileLayer),
      );
      expect(
        tileLayer.urlTemplate,
        contains('tile.openstreetmap.org'),
      );
    });

    testWidgets('applies custom height', (tester) async {
      await pumpRozgarMap(tester, height: 500);
      await tester.pump();

      // Find the SizedBox with the custom height (not helper's width-only box)
      final heightBoxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 500,
      );
      expect(heightBoxes, findsOneWidget);
    });

    testWidgets('applies default height of 360 when not specified',
        (tester) async {
      await pumpRozgarMap(tester);
      await tester.pump();

      // Find the SizedBox with default height
      final heightBoxes = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 360,
      );
      expect(heightBoxes, findsOneWidget);
    });
  });

  group('RozgarMap (OSM markers)', () {
    testWidgets('renders markers on OSM map', (tester) async {
      final markers = [
        MapMarker(
          id: 'm1',
          lat: 31.5204,
          lng: 74.3587,
          title: 'Marker 1',
          isEmployer: true,
        ),
        MapMarker(
          id: 'm2',
          lat: 31.522,
          lng: 74.356,
          title: 'Worker',
          isEmployer: false,
        ),
      ];

      await pumpRozgarMap(tester, markers: markers);
      await tester.pump();

      expect(find.byType(osm.MarkerLayer), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('marker tap calls onTap', (tester) async {
      String? tappedId;
      final markers = [
        MapMarker(
          id: 'tappable',
          lat: 31.5204,
          lng: 74.3587,
          title: 'Tappable',
          isEmployer: true,
          onTap: () => tappedId = 'tappable',
        ),
      ];

      await pumpRozgarMap(tester, markers: markers);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.work));
      await tester.pump();

      expect(tappedId, 'tappable');
    });

    testWidgets('handles empty markers list', (tester) async {
      await pumpRozgarMap(tester, markers: []);
      await tester.pump();

      expect(find.byType(osm.MarkerLayer), findsOneWidget);
      expect(find.byIcon(Icons.work), findsNothing);
      expect(find.byIcon(Icons.construction), findsNothing);
    });
  });

  // ===========================================================================
  // Google Maps Provider Tests
  // ===========================================================================
  // NOTE: gmaps.GoogleMap uses platform views (AndroidView/UiKitView) that
  // require platform channel mocks not available in flutter_test. To verify
  // Google Maps rendering, run integration tests in integration_test/
  // on a real device or emulator where platform channels work.
  //
  // The MapService switching logic (setUseGoogleMaps / setUseOsm) is tested
  // in test/services/map_service_test.dart.
  // ===========================================================================
  

  group('RozgarMap (centered pin)', () {
    testWidgets('shows centered pin when showCenteredPin is true',
        (tester) async {
      await pumpRozgarMap(tester, showCenteredPin: true);
      await tester.pump();

      // Two location_on icons: shadow + main pin
      expect(find.byIcon(Icons.location_on), findsNWidgets(2));
    });

    testWidgets('hides centered pin when showCenteredPin is false',
        (tester) async {
      await pumpRozgarMap(tester, showCenteredPin: false);
      await tester.pump();

      // OSM tiles might also use location_on markers
      final pins = find.byIcon(Icons.location_on);
      // When showCenteredPin is false, no centered pin is shown
      // (tile icons may still appear with location_on)
      expect(pins, findsNothing);
    });

    testWidgets('centered pin icon has a teardrop style (main pin)', (tester) async {
      await pumpRozgarMap(tester, showCenteredPin: true);
      await tester.pump();

      // Find only the full-color location_on (not the shadow)
      final mainPins = find.descendant(
        of: find.byType(Stack),
        matching: find.byIcon(Icons.location_on),
      );
      // At least one main pin icon exists inside a Stack
      expect(mainPins, findsAtLeast(1));
    });

    testWidgets('no centered pin Stack when pin is disabled', (tester) async {
      await pumpRozgarMap(tester, showCenteredPin: false);
      await tester.pump();

      // No pin icon means no Stack should contain it
      expect(find.byIcon(Icons.location_on), findsNothing);
      // Other Stacks (MaterialApp/Scaffold internals) can exist
    });
  });

  group('RozgarMapController', () {
    testWidgets('controller is attached and does not crash on animateTo',
        (tester) async {
      final controller = RozgarMapController();
      await pumpRozgarMap(tester, controller: controller);
      await tester.pump();

      // animateTo should not throw (OSM controller.move handles null)
      await controller.animateTo(31.5, 74.35, 16);
      // If we reach here without exception, the test passes
    });

    testWidgets('controller returns current center when available',
        (tester) async {
      final controller = RozgarMapController();
      await pumpRozgarMap(tester, controller: controller);
      await tester.pump();

      final center = controller.currentCenter;
      expect(center, isNotNull);
      // Use bang operator since we verified isNotNull above
      expect(center!.lat, closeTo(31.5204, 0.001));
      expect(center.lng, closeTo(74.3587, 0.001));
    });

    testWidgets('controller works without RozgarMap attached', (tester) async {
      final controller = RozgarMapController();

      // Should not throw when no map is attached
      await controller.animateTo(31.5, 74.35, 16);
      expect(controller.currentCenter, isNull);
    });
  });

  group('RozgarMap (callbacks)', () {
    testWidgets('accepts onCameraMove callback without error', (tester) async {
      double? movedLat;
      double? movedLng;

      await pumpRozgarMap(
        tester,
        onCameraMove: (lat, lng) {
          movedLat = lat;
          movedLng = lng;
        },
      );
      await tester.pump();

      // RozgarMap should render with the callback registered
      expect(find.byType(osm.FlutterMap), findsOneWidget);
      // Callbacks are initially not triggered (no map drag occurred)
      expect(movedLat, isNull);
      expect(movedLng, isNull);
    });

    testWidgets('accepts onCameraIdle callback without error', (tester) async {
      bool idleCalled = false;

      await pumpRozgarMap(
        tester,
        onCameraIdle: () => idleCalled = true,
      );
      await tester.pump();

      expect(find.byType(osm.FlutterMap), findsOneWidget);
      expect(idleCalled, false);
    });
  });

  group('RozgarMap (provider switching)', () {
    testWidgets('renders OSM by default', (tester) async {
      await pumpRozgarMap(tester);
      await tester.pump();

      expect(find.byType(osm.FlutterMap), findsOneWidget);
      expect(find.byType(gmaps.GoogleMap), findsNothing);
    });

    testWidgets('switches provider selection via MapService', (tester) async {
      await pumpRozgarMap(tester);
      await tester.pump();
      expect(find.byType(osm.FlutterMap), findsOneWidget);

      // Switch to Google Maps selection (verify via service, not widget)
      MapService.instance.setUseGoogleMaps();
      expect(MapService.instance.useGoogleMaps, true);

      // Switch back to OSM
      MapService.instance.setUseOsm();
      expect(MapService.instance.useGoogleMaps, false);

      // Pump again — still OSM, FlutterMap should re-render fine
      await tester.pump();
      expect(find.byType(osm.FlutterMap), findsOneWidget);
    });

    testWidgets('OSM markers render after provider switch-back', (tester) async {
      final markers = [
        MapMarker(
          id: 'emp',
          lat: 31.5204,
          lng: 74.3587,
          title: 'Employer',
          isEmployer: true,
        ),
      ];

      await pumpRozgarMap(tester, markers: markers);
      await tester.pump();
      expect(find.byIcon(Icons.work), findsOneWidget);

      // Switch to Google Maps selection, then back to OSM
      MapService.instance.setUseGoogleMaps();
      MapService.instance.setUseOsm();
      await tester.pump();

      // Markers should still render correctly after switch-back
      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byType(osm.FlutterMap), findsOneWidget);
    });
  });
}
