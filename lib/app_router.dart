import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/providers.dart';
import 'providers/app_state.dart';
import 'models/job.dart';
import 'models/profile.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/employer/employer_home.dart';
import 'screens/worker/worker_home.dart';
import 'screens/employer/post_job_flow.dart';
import 'screens/job/job_detail_view.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/map/nearby_workers_map.dart';
import 'screens/profile/profile_view.dart';
import 'screens/notifications/notifications_view.dart';
import 'screens/profile/public_profile_view.dart';
import 'screens/worker/earnings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/rating/rating_modal.dart';
import 'widgets/header.dart';
import 'widgets/bottom_nav.dart';
import 'theme/app_theme.dart';
import 'app.dart' show AppView;

final routerProvider = Provider<GoRouter>((ref) {
  final appState = ref.read(appStateProvider);
  return _buildRouter(appState);
});

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter _buildRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: _buildRedirect(appState),
    refreshListenable: appState,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go(_defaultHome(appState) ?? '/auth'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final step =
              int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0;
          return AuthScreen(
            appState: appState,
            onAuthComplete: () =>
                context.go(_defaultHome(appState) ?? '/employer/home'),
            initialStep: step,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          appState: appState,
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/employer/home',
            builder: (context, state) => EmployerHome(
              onPostJobClick: () => context.go('/employer/post-job'),
              onOpenJobDetails: (job) => context.go('/job/${job.id}'),
              onOpenMapClick: () => context.go('/map'),
            ),
          ),
          GoRoute(
            path: '/worker/home',
            builder: (context, state) => WorkerHome(
              appState: appState,
              onOpenJobDetails: (job) => context.go('/job/${job.id}'),
              onOpenMapClick: () => context.go('/map'),
            ),
          ),
          GoRoute(
            path: '/employer/post-job',
            builder: (context, state) => PostJobFlow(
              appState: appState,
              onComplete: () =>
                  context.go(_defaultHome(appState) ?? '/employer/home'),
            ),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => NearbyWorkersMap(
              onOpenChat: (workerId) => context.go('/chat', extra: workerId),
              onOpenProfile: (workerId) => context.go('/u/$workerId'),
            ),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => ChatScreen(
              appState: appState,
              targetWorkerProfileId: state.extra as String?,
              onBack: () => context.pop(),
              onJobCompleteClick: (jobId) {
                showDialog(
                  context: context,
                  builder: (_) => RatingModal(
                    appState: appState,
                    jobId: jobId,
                    revieweeProfileId: state.extra as String? ?? '',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/worker/earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileView(),
          ),
        ],
      ),
      GoRoute(
        path: '/job/:jobId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final jobId = state.pathParameters['jobId'] ?? '';
          final job = appState.jobs.where((j) => j.id == jobId).firstOrNull;
          if (job == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Job not found')),
              body: const Center(child: Text('This job could not be found.')),
            );
          }
          return JobDetailView(
            appState: appState,
            job: job,
            onBack: () => context.pop(),
            onOpenChat: (workerId) => context.go('/chat', extra: workerId),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => NotificationsView(
onBack: () => context.pop(),
onOpenJobDetailsById: (jobId) => context.go('/job/$jobId'),
),
      ),
      GoRoute(
        path: '/u/:workerId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final workerId = state.pathParameters['workerId'] ?? '';
          final data = appState.getPublicProfile(workerId);
          if (data == null || data.workerDetails == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profile not found')),
              body: const Center(
                  child: Text('This profile could not be found.')),
            );
          }
          return PublicProfileView(
            profile: data.profile,
            workerDetails: data.workerDetails!,
            onBack: () => context.pop(),
            onOpenChat: (wid) => context.go('/chat', extra: wid),
            onHire: () {
              final openJob = appState.jobs
                  .where((j) => j.status == JobStatus.open)
                  .firstOrNull;
              if (openJob != null) {
                appState.hireWorker(openJob.id, workerId);
                context.go('/chat', extra: workerId);
              }
            },
          );
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SettingsScreen(
          onBack: () => context.pop(),
        ),
      ),
    ],
  );
}

String? Function(BuildContext, GoRouterState) _buildRedirect(
    AppState appState) {
  return (context, state) {
    final isLoggedIn = appState.authIdentity != null;
    final isOnAuth = state.matchedLocation == '/auth';

    if (!isLoggedIn && !isOnAuth) return '/auth';

    // Needs onboarding → force to profile creation (unless already there)
    if (isLoggedIn && appState.needsOnboarding) {
      if (isOnAuth && state.uri.queryParameters['step'] == '2') return null;
      return '/auth?step=2';
    }

    // Onboarding done, still on auth → go home
    if (isLoggedIn && isOnAuth) return _defaultHome(appState);

    // On root → go home
    if (isLoggedIn && state.matchedLocation == '/') return _defaultHome(appState);

    return null;
  };
}

String? _defaultHome(AppState state) {
  if (state.activeProfileType == ProfileType.employer) {
    return '/employer/home';
  }
  return '/worker/home';
}

class AppShell extends StatelessWidget {
  final AppState appState;
  final String location;
  final Widget child;

  const AppShell({
    super.key,
    required this.appState,
    required this.location,
    required this.child,
  });

  AppView? get _activeTab {
    if (location == '/employer/home' || location == '/worker/home') {
      return AppView.home;
    }
    if (location == '/employer/post-job') return AppView.postJob;
    if (location == '/map') return AppView.nearbyWorkersMap;
    if (location == '/chat') return AppView.chat;
    if (location == '/worker/earnings') return AppView.history;
    if (location == '/profile') return AppView.profile;
    return AppView.home;
  }

  @override
  Widget build(BuildContext context) {
    final isNotifications = location == '/notifications';
    final bottomNavTabs = appState.activeProfileType == ProfileType.employer
        ? _employerTabs
        : _workerTabs;

    // Surface operation errors to the user
    final error = appState.lastOperationError;
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.rose500,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        appState.clearOperationError();
      });
    }

    return Scaffold(
      body: Column(
        children: [
          if (!isNotifications)
            RozgarHeader(
              appState: appState,
              onOpenNotifications: () => context.go('/notifications'),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: RozgarBottomNav(
        appState: appState,
        activeTab: _activeTab ?? AppView.home,
        tabs: bottomNavTabs,
        onTabChange: (view) {
          final path = _viewToPath(view, appState.activeProfileType);
          if (path != null) context.go(path);
        },
      ),
    );
  }
}

String? _viewToPath(AppView view, ProfileType profileType) {
  switch (view) {
    case AppView.home:
      return profileType == ProfileType.employer
          ? '/employer/home'
          : '/worker/home';
    case AppView.postJob:
      return '/employer/post-job';
    case AppView.nearbyWorkersMap:
      return '/map';
    case AppView.chat:
      return '/chat';
    case AppView.history:
      return '/worker/earnings';
    case AppView.profile:
      return '/profile';
    default:
      return null;
  }
}

const _employerTabs = <AppView>[
  AppView.home,
  AppView.postJob,
  AppView.nearbyWorkersMap,
  AppView.chat,
  AppView.profile,
];

const _workerTabs = <AppView>[
  AppView.home,
  AppView.nearbyWorkersMap,
  AppView.chat,
  AppView.history,
  AppView.profile,
];
