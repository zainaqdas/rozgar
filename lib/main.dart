import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'utils/translations.dart';
import 'services/supabase_config.dart';
import 'services/config.dart';
import 'services/map_service.dart';
import 'services/push_service.dart';
import 'services/sync_service.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FATAL: ${details.exception}\n${details.stack}');
  };

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Hive.initFlutter();
  await SyncService.instance.initialize();
  await SupabaseConfig.initialize();

  if (AppConfig.googleMapsApiKey.isNotEmpty) {
    MapService.instance.setUseGoogleMaps();
  }

  await PushService.instance.initialize();

  runApp(const ProviderScope(child: RozgarApp()));
}

class RozgarApp extends ConsumerStatefulWidget {
  const RozgarApp({super.key});

  @override
  ConsumerState<RozgarApp> createState() => _RozgarAppState();
}

class _RozgarAppState extends ConsumerState<RozgarApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    PushService.onNotificationTap = _handleNotificationTap;
  }

  void _handleNotificationTap(String? payload) {
    final router = ref.read(routerProvider);
    switch (payload) {
      case 'new_message':
        router.go('/chat');
      default:
        router.go('/notifications');
    }
  }

  @override
  void dispose() {
    PushService.onNotificationTap = null;
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await ref.read(coordinatorProvider.notifier).initialize();
    } catch (e) {
      debugPrint('App initialization failed: $e');
    }
    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).language;
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Rozgar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: Locale(lang == LanguageOption.ur ? 'ur' : 'en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
      ],
      routerConfig: router,
      builder: (context, child) {
        if (!_isInitialized) {
          return const _SplashScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'ر',
                  style: TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ROZGAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ہنر مند',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
