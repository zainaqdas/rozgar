import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../models/profile.dart';

/// Dedicated Settings screen (Screen #16 of prompt spec).
/// Manages language, notification radius, verification, block/report, and delete account.
class SettingsScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.appState,
    required this.onBack,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cnicController = TextEditingController(text: '35201-1234567-1');
  bool _isVerifyingCnic = false;
  bool _cnicVerified = false;
  bool _showDeleteConfirm = false;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final lang = state.language;
    final details = state.workerDetails;
    final profile = state.activeProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 16, color: AppColors.slate700),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Settings',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800)),
            ],
          ),
          const SizedBox(height: 20),

          // Language
          _SettingsGroup(
            title: 'App Language',
            children: [
              _SettingsRow(
                icon: Icons.language,
                title: 'Language',
                subtitle:
                    lang == LanguageOption.en ? 'English' : 'اردو (Urdu)',
                trailing: GestureDetector(
                  onTap: () {
                    state.setLanguage(
                      lang == LanguageOption.en
                          ? LanguageOption.ur
                          : LanguageOption.en,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.teal50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.teal200),
                    ),
                    child: Text(
                      lang == LanguageOption.en ? 'Switch to اردو' : 'Switch to English',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notification Settings (Worker only)
          if (state.activeProfileType == ProfileType.worker && details != null)
            _SettingsGroup(
              title: 'Notifications & Online',
              children: [
                // Online toggle
                _SettingsRow(
                  icon: Icons.wifi,
                  title: 'Appear Online on Map',
                  subtitle: details.isOnlineForMap
                      ? 'Visible to nearby employers'
                      : 'Hidden from employers',
                  trailing: Switch(
                    value: details.isOnlineForMap,
                    onChanged: (v) => state.toggleWorkerOnline(v),
                    activeThumbColor: AppColors.teal600,
                  ),
                ),
                const Divider(height: 1, indent: 48),
                // Notification Radius
                _SettingsRow(
                  icon: Icons.radar,
                  title: 'Job Alert Radius',
                  subtitle: '${details.notificationRadiusKm.toInt()} km',
                  trailing: SizedBox(
                    width: 120,
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.teal600,
                        inactiveTrackColor: AppColors.slate200,
                        thumbColor: AppColors.teal600,
                        overlayColor:
                            AppColors.teal600.withValues(alpha: 0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        min: 3,
                        max: 30,
                        value: details.notificationRadiusKm,
                        onChanged: (v) => state.updateWorkerRadius(v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (state.activeProfileType == ProfileType.worker)
            const SizedBox(height: 16),

          // Identity Verification
          _SettingsGroup(
            title: 'Identity & Security',
            children: [
              _SettingsRow(
                icon: Icons.verified_user,
                title: 'NADRA CNIC Verification',
                subtitle: _cnicVerified || profile?.isVerified == true
                    ? '✅ Verified Citizen'
                    : 'Not verified yet',
                trailing: _cnicVerified || profile?.isVerified == true
                    ? const Icon(Icons.check_circle,
                        size: 20, color: AppColors.teal600)
                    : GestureDetector(
                        onTap: _verifyCnic,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.teal600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _isVerifyingCnic
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Verify',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                        ),
                      ),
              ),
              if (!(_cnicVerified || profile?.isVerified == true)) ...[
                const Divider(height: 1, indent: 48),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 8, 16, 8),
                  child: TextField(
                    controller: _cnicController,
                    decoration: const InputDecoration(
                      hintText: '35201-XXXXXXX-X',
                      labelText: 'CNIC Number',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Account Management
          _SettingsGroup(
            title: 'Account',
            children: [
              _SettingsRow(
                icon: Icons.report,
                title: 'Report a User',
                subtitle: 'Report inappropriate behavior',
                trailing: const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.slate400),
                onTap: () => _showReportDialog(context, state),
              ),
              const Divider(height: 1, indent: 48),
              _SettingsRow(
                icon: Icons.block,
                title: 'Blocked Users',
                subtitle: 'Manage blocked profiles',
                trailing: const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.slate400),
                onTap: () => _showBlockedDialog(context),
              ),
              const Divider(height: 1, indent: 48),
              _SettingsRow(
                icon: Icons.info_outline,
                title: 'About Rozgar',
                subtitle: 'Version 1.0.0 • Pakistan',
                trailing: const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.slate400),
                onTap: () => _showAboutDialog(context),
              ),
              const Divider(height: 1, indent: 48),
              _SettingsRow(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                iconColor: AppColors.rose500,
                titleColor: AppColors.rose500,
                onTap: () {
                  state.logout();
                  widget.onBack();
                },
              ),
              const Divider(height: 1, indent: 48),
              _SettingsRow(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently remove all data',
                iconColor: AppColors.rose500,
                titleColor: AppColors.rose500,
                onTap: () => setState(() => _showDeleteConfirm = true),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Delete Confirmation
          if (_showDeleteConfirm)
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.rose50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.rose200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber,
                      size: 40, color: AppColors.rose500),
                  const SizedBox(height: 12),
                  const Text(
                    'Delete Account?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.rose500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will permanently remove all your data including jobs, messages, and reviews. This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showDeleteConfirm = false),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppColors.slate200),
                            ),
                            child: const Center(
                              child: Text('Cancel',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate700)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            state.logout();
                            widget.onBack();
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.rose500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text('Delete My Account',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _verifyCnic() {
    setState(() => _isVerifyingCnic = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isVerifyingCnic = false;
          _cnicVerified = true;
        });
      }
    });
  }

  void _showReportDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Report a User',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'Use this to report inappropriate behavior, fake profiles, or spam. Our team will review within 24 hours.',
          style: TextStyle(fontSize: 12, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Report submitted. We will review it shortly.')),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Blocked Users',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'You haven\'t blocked any users yet.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, size: 20, color: AppColors.teal600),
            SizedBox(width: 8),
            Text('About Rozgar',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Platform: Flutter',
                style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            Text('Market: Lahore, Pakistan',
                style: TextStyle(fontSize: 12)),
            SizedBox(height: 8),
            Text(
              'Rozgar connects employers with nearby skilled and unskilled workers. Built for the Pakistani market with Urdu and English support.',
              style: TextStyle(fontSize: 11, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.teal700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.teal600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? AppColors.slate800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
