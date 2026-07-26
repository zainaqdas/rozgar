import 'package:flutter/material.dart';
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
import 'screens/rating/rating_modal.dart';
import 'screens/profile/public_profile_view.dart';
import 'screens/worker/earnings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/header.dart';
import 'widgets/bottom_nav.dart';

/// Represents all possible views in the app
enum AppView {
  home,
  postJob,
  nearbyWorkersMap,
  jobsNearMe,
  chat,
  history,
  profile,
  jobDetail,
  notifications,
  publicProfile,
  settings,
}

class RozgarShell extends StatefulWidget {
  final AppState appState;
  const RozgarShell({super.key, required this.appState});

  @override
  State<RozgarShell> createState() => _RozgarShellState();
}

class _RozgarShellState extends State<RozgarShell> {
  AppView _activeView = AppView.home;
  Job? _selectedJob;
  String? _targetWorkerForChat;
  String? _targetWorkerIdForProfile;
  ({String jobId, String revieweeId})? _ratingJobInfo;

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;

    if (state.authIdentity == null || state.needsOnboarding) {
      return AuthScreen(
        appState: state,
        onAuthComplete: () => setState(() => _activeView = AppView.home),
        initialStep: state.needsOnboarding ? 2 : 0,
      );
    }

    // Determine bottom nav tabs based on active profile
    final bottomNavTabs = state.activeProfileType == ProfileType.employer
        ? <AppView>[AppView.home, AppView.postJob, AppView.nearbyWorkersMap, AppView.chat, AppView.profile]
        : <AppView>[AppView.jobsNearMe, AppView.nearbyWorkersMap, AppView.chat, AppView.history, AppView.profile];

    // Map active view to the closest bottom nav tab for highlighting
    AppView activeBottomTab = _activeView;
    if (!bottomNavTabs.contains(_activeView)) {
      if (_activeView == AppView.jobDetail ||
          _activeView == AppView.notifications ||
          _activeView == AppView.publicProfile) {
        activeBottomTab = AppView.home;
      } else if (_activeView == AppView.settings) {
        activeBottomTab = AppView.profile;
      } else {
        activeBottomTab = AppView.home; // generic fallback
      }
    }

    return Stack(
      children: [
        Scaffold(
          body: Column(
            children: [
              // Top Header (hidden for notifications view)
              if (_activeView != AppView.notifications)
                RozgarHeader(
                  appState: state,
                  onOpenNotifications: () =>
                      setState(() => _activeView = AppView.notifications),
                ),

              // Main Content
              Expanded(child: _buildBody(state)),
            ],
          ),
          bottomNavigationBar: RozgarBottomNav(
            appState: state,
            activeTab: activeBottomTab,
            tabs: bottomNavTabs,
            onTabChange: (tab) {
              setState(() {
                _activeView = tab;
                if (tab != AppView.chat) _targetWorkerForChat = null;
              });
            },
          ),
        ),

        // Rating Modal Overlay
        if (_ratingJobInfo != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: RatingModal(
              appState: state,
              jobId: _ratingJobInfo!.jobId,
              revieweeProfileId: _ratingJobInfo!.revieweeId,
              onClose: () => setState(() => _ratingJobInfo = null),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(AppState state) {
    switch (_activeView) {
      case AppView.home:
        return EmployerHome(
          appState: state,
          onPostJobClick: () => setState(() => _activeView = AppView.postJob),
          onOpenJobDetails: (job) => setState(() {
            _selectedJob = job;
            _activeView = AppView.jobDetail;
          }),
          onOpenMapClick: () =>
              setState(() => _activeView = AppView.nearbyWorkersMap),
        );

      case AppView.jobsNearMe:
        return WorkerHome(
          appState: state,
          onOpenJobDetails: (job) => setState(() {
            _selectedJob = job;
            _activeView = AppView.jobDetail;
          }),
          onOpenMapClick: () =>
              setState(() => _activeView = AppView.nearbyWorkersMap),
        );

      case AppView.postJob:
        return PostJobFlow(
          appState: state,
          onComplete: () => setState(() => _activeView = AppView.home),
        );

      case AppView.nearbyWorkersMap:
        return NearbyWorkersMap(
          appState: state,
          onOpenChat: (workerId) => setState(() {
            _targetWorkerForChat = workerId;
            _activeView = AppView.chat;
          }),
          onOpenProfile: (workerId) => setState(() {
            _targetWorkerIdForProfile = workerId;
            _activeView = AppView.publicProfile;
          }),
        );

      case AppView.chat:
        return ChatScreen(
          appState: state,
          targetWorkerProfileId: _targetWorkerForChat,
          onBack: () => setState(() => _activeView = AppView.home),
          onJobCompleteClick: (jobId) => setState(() {
            _ratingJobInfo = (
              jobId: jobId,
              revieweeId: _targetWorkerForChat ?? '',
            );
          }),
        );

      case AppView.history:
        return EarningsScreen(appState: state);

      case AppView.profile:
        return ProfileView(appState: state);

      case AppView.jobDetail:
        if (_selectedJob != null) {
          return JobDetailView(
            appState: state,
            job: _selectedJob!,
            onBack: () => setState(() => _activeView = AppView.home),
            onOpenChat: (workerId) => setState(() {
              _targetWorkerForChat = workerId;
              _activeView = AppView.chat;
            }),
          );
        }
        return const SizedBox.shrink();

      case AppView.notifications:
        return NotificationsView(
          appState: state,
          onBack: () => setState(() => _activeView = AppView.home),
          onOpenJobDetailsById: (id) {
            final j = state.jobs.where((j) => j.id == id).firstOrNull;
            if (j != null) {
              setState(() {
                _selectedJob = j;
                _activeView = AppView.jobDetail;
              });
            }
          },
        );
      case AppView.publicProfile:
        if (_targetWorkerIdForProfile != null) {
          final data = state.getPublicProfile(_targetWorkerIdForProfile!);
          if (data != null && data.workerDetails != null) {
            return PublicProfileView(
              appState: state,
              profile: data.profile,
              workerDetails: data.workerDetails!,
              onBack: () => setState(() => _activeView = AppView.home),
              onOpenChat: (workerId) => setState(() {
                _targetWorkerForChat = workerId;
                _activeView = AppView.chat;
              }),
              onHire: () {
                final openJob = state.jobs
                    .where((j) => j.status == JobStatus.open)
                    .firstOrNull;
                if (openJob != null) {
                  state.hireWorker(openJob.id, _targetWorkerIdForProfile!);
                  setState(() {
                    _targetWorkerForChat = _targetWorkerIdForProfile;
                    _activeView = AppView.chat;
                  });
                }
              },
            );
          }
        }
        return const SizedBox.shrink();

      case AppView.settings:
        return SettingsScreen(
          appState: state,
          onBack: () => setState(() => _activeView = AppView.profile),
        );
    }
  }
}
