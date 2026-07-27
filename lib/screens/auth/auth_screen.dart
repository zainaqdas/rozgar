import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/app_state.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/translations.dart';
import '../../data/categories.dart';
import '../../models/location_point.dart';
import '../../models/profile.dart';
import '../../widgets/location_pin_drop.dart';
import '../../utils/geo.dart';

class AuthScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onAuthComplete;

  /// If set, skip directly to this step (e.g. 2 for profile choice after email confirmation).
  final int initialStep;

  const AuthScreen({
    super.key,
    required this.appState,
    required this.onAuthComplete,
    this.initialStep = 0,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late int _step; // 0: contact, 1: otp, 2: profile_choice, 3: onboarding
  bool _isPhone = true;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }
  bool _isSignUp = false;
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isAuthLoading = false;
  String? _authError;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Onboarding
  ProfileType _selectedRole = ProfileType.worker;
  String _selectedCategoryId = 'home-electrical';
  int _yearsExperience = 5;
  final _yearsExperienceController = TextEditingController(text: '5');
  final _bioController = TextEditingController();
  bool _isAiBioLoading = false;
  bool _isLocating = false;
  LocationPoint _homeLocation = const LocationPoint(
    lat: 31.5204,
    lng: 74.3587,
    address: '',
    city: '',
  );

  Future<void> _autoDetectLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (!mounted) return;
        setState(() => _isLocating = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => _isLocating = false);
          return;
        }
      }
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final addr = await reverseGeocode(pos.latitude, pos.longitude);
      final parts = addr.split(',');
      final city = parts.length >= 3 ? parts[parts.length - 3].trim() : '';
      if (mounted) {
        setState(() {
          _homeLocation = LocationPoint(
            lat: pos.latitude,
            lng: pos.longitude,
            address: addr,
            city: city,
          );
        });
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _openMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: LocationPinDrop(
          initialLocation: _homeLocation.address.isNotEmpty ? _homeLocation : null,
          language: widget.appState.language,
          confirmBtnText: 'Set This Location',
          onClose: () => Navigator.pop(ctx),
          onConfirmLocation: (loc) {
            setState(() => _homeLocation = loc);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _signUpNameController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _yearsExperienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.appState.language;
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // App Logo Header
                _buildAppHeader(lang),
                const SizedBox(height: 20),

                // Auth Card
                Container(
                  width: double.maxFinite,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildStepContent(lang),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader(LanguageOption lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.teal600,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal600.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'ر',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'ROZGAR ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  '| ہنر مند',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal600,
                  ),
                ),
              ],
            ),
            const Text(
              'Pakistan Local Services Marketplace',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.teal700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Language toggle
        GestureDetector(
          onTap: () {
            widget.appState.setLanguage(
              lang == LanguageOption.en
                  ? LanguageOption.ur
                  : LanguageOption.en,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Text(
              lang == LanguageOption.en ? 'اردو' : 'EN',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(LanguageOption lang) {
    switch (_step) {
      case 0:
        return _buildContactStep(lang);
      case 1:
        return _buildOtpStep(lang);
      case 2:
        return _buildProfileChoiceStep(lang);
      case 3:
        return _buildOnboardingStep(lang);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: Sign In / Sign Up
  Widget _buildContactStep(LanguageOption lang) {
    if (_isSignUp) return _buildSignUpForm(lang);
    return _buildSignInForm(lang);
  }

  Widget _buildSignInForm(LanguageOption lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.t('welcomeBack', lang),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppTranslations.t('phoneOrEmailLogin', lang),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 16),

        // Phone/Email toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isPhone = true;
                    _authError = null;
                  }),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isPhone
                          ? AppColors.teal600
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone,
                            size: 16,
                            color: _isPhone
                                ? Colors.white
                                : AppColors.slate600),
                        const SizedBox(width: 6),
                        Text(
                          'Phone (+92)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isPhone
                                ? Colors.white
                                : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isPhone = false;
                    _authError = null;
                  }),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isPhone
                          ? AppColors.teal600
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined,
                            size: 16,
                            color: !_isPhone
                                ? Colors.white
                                : AppColors.slate600),
                        const SizedBox(width: 6),
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: !_isPhone
                                ? Colors.white
                                : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Email/Phone Input
        TextField(
          controller: _contactController,
          decoration: InputDecoration(
            labelText: _isPhone
                ? 'Mobile Number (Pakistan)'
                : 'Email Address',
            hintText: _isPhone
                ? '+92 300 1234567'
                : 'name@example.com',
          ),
        ),
        const SizedBox(height: 12),

        // Password field (for email auth)
        if (!_isPhone) ...[
          TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: AppColors.slate400,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _handleForgotPassword(),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_authError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.rose50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.rose200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: AppColors.rose500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _authError!,
                    style: TextStyle(fontSize: 11, color: AppColors.rose500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Sign In / Send OTP Button
        SizedBox(
          width: double.maxFinite,
          child: ElevatedButton(
            onPressed: _isAuthLoading
                ? null
                : () async {
                    if (_isPhone) {
                      // Phone OTP flow
                      try {
                        widget.appState.loginWithPhoneOrEmail(
                            _contactController.text);
                        if (mounted) setState(() => _step = 1);
                      } catch (e) {
                        if (mounted) {
                          setState(() => _authError = 'Failed to send OTP: $e');
                        }
                      }
                    } else {
                      // Email + Password flow
                      setState(() {
                        _isAuthLoading = true;
                        _authError = null;
                      });
                      final error = await widget.appState.signInWithEmail(
                        _contactController.text.trim(),
                        _passwordController.text,
                      );
                      if (mounted) {
                        if (error == null) {
                          setState(() => _step = 2);
                        } else {
                          setState(() => _authError = error);
                        }
                        setState(() => _isAuthLoading = false);
                      }
                    }
                  },
            child: _isAuthLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isPhone ? Icons.sms : Icons.login, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isPhone
                              ? AppTranslations.t('sendOTP', lang)
                              : 'Sign In',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Toggle to Sign Up
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isSignUp = true;
                _authError = null;
                _contactController.text = '';
                _passwordController.text = '';
              });
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
                text: "Don't have an account? ",
                children: const [
                  TextSpan(
                    text: 'Create one',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(LanguageOption lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _isSignUp = false;
                _authError = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, size: 18, color: AppColors.slate600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Join Rozgar as an employer or worker',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Full Name
        TextField(
          controller: _signUpNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. Ahmed Khan',
            prefixIcon: Icon(Icons.person_outline, size: 18),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),

        // Email
        TextField(
          controller: _contactController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
          ),
        ),
        const SizedBox(height: 12),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Min. 6 characters',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.slate400,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Confirm Password
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: AppColors.slate400,
              ),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Error display
        if (_authError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.rose50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.rose200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: AppColors.rose500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _authError!,
                    style: TextStyle(fontSize: 11, color: AppColors.rose500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Create Account Button
        SizedBox(
          width: double.maxFinite,
          child: ElevatedButton(
            onPressed: _isAuthLoading
                ? null
                : _handleSignUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isAuthLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Create Account',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Toggle back to Sign In
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isSignUp = false;
                _authError = null;
                _contactController.text = '';
                _passwordController.text = '';
              });
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
                text: 'Already have an account? ',
                children: const [
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.teal600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignUp() async {
    final name = _signUpNameController.text.trim();
    final email = _contactController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    // Validation
    if (name.isEmpty) {
      setState(() => _authError = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _authError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _authError = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _authError = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isAuthLoading = true;
      _authError = null;
    });

    // Store name for the onboarding step
    _nameController.text = name;

    final error = await widget.appState.signUpWithEmail(email, password);
    if (mounted) {
      if (error == null) {
        // Success — move to profile choice
        setState(() => _step = 2);
      } else {
        setState(() => _authError = error);
      }
      setState(() => _isAuthLoading = false);
    }
  }

  void _handleForgotPassword() {
    final email = _contactController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _authError = 'Please enter your email address first to receive the reset link.';
      });
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_reset, size: 20, color: AppColors.teal600),
            const SizedBox(width: 8),
            const Text(
              'Reset Password',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'A password reset link will be sent to:\n\n$email\n\nPlease check your inbox and follow the instructions to reset your password.',
          style: TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() {
                _isAuthLoading = true;
                _authError = null;
              });
              final error = await widget.appState.sendPasswordResetEmail(email);
              if (mounted) {
                setState(() => _isAuthLoading = false);
                if (error == null) {
                  _showSuccessSnackBar('Password reset link sent to $email');
                } else {
                  setState(() => _authError = error);
                }
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          ],
        ),
        backgroundColor: AppColors.teal600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // STEP 1: OTP Verification
  Widget _buildOtpStep(LanguageOption lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Code',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
            text: 'Sent 6-digit OTP code to ',
            children: [
              TextSpan(
                text: _contactController.text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _otpController,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.teal700,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            counterText: '',
            labelText: '6-Digit Code',
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.maxFinite,
          child: ElevatedButton(
            onPressed: () {
              if (widget.appState
                  .verifyOtp(_otpController.text)) {
                setState(() => _step = 2);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user, size: 16),
                const SizedBox(width: 8),
                Text(AppTranslations.t('verifyAndLogin', lang)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: Choose Profile Type
  Widget _buildProfileChoiceStep(LanguageOption lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Profile Type to Start',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.slate800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'You can create both Employer and Worker profiles under this login and switch anytime!',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 20),

        _RoleCard(
          icon: Icons.work,
          iconBgColor: AppColors.teal100,
          iconColor: AppColors.teal700,
          title: 'Employer Profile (مالک)',
          subtitle:
              'I want to post small jobs, hire electricians, plumbers, drivers, cleaners, or tutors nearby.',
          onTap: () {
            setState(() {
              _selectedRole = ProfileType.employer;
              _step = 3;
            });
          },
        ),
        const SizedBox(height: 12),

        _RoleCard(
          icon: Icons.construction,
          iconBgColor: AppColors.amber100,
          iconColor: AppColors.amber700,
          title: 'Worker Profile (کاریگر)',
          subtitle:
              'I am a technician or laborer wanting to receive nearby job alerts and earn daily.',
          onTap: () {
            setState(() {
              _selectedRole = ProfileType.worker;
              _step = 3;
            });
          },
        ),
      ],
    );
  }

  // STEP 3: Onboarding Form
  Widget _buildOnboardingStep(LanguageOption lang) {
    final isWorker = _selectedRole == ProfileType.worker;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Profile Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.teal200),
                ),
                child: const Text(
                  'Progress 70%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isWorker
                ? 'Set up your service skills & location in Lahore.'
                : 'Set up your employer profile.',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 16),

          // Display Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
            ),
          ),
          const SizedBox(height: 12),

          if (isWorker) ...[
            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Primary Skill Category',
              ),
              items: seededCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Text(
                    '${cat.nameEn} (${cat.nameUr})',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategoryId = v);
              },
            ),
            const SizedBox(height: 12),

            // Years Experience
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Years Experience',
              ),
              controller: _yearsExperienceController,
              onChanged: (v) =>
                  _yearsExperience = int.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 12),

            // Bio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Bio & Experience Note',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    setState(() => _isAiBioLoading = true);
                    try {
                      final categoryName = seededCategories
                          .where((c) => c.id == _selectedCategoryId)
                          .firstOrNull
                          ?.nameEn ?? 'Services';
                      final result = await AIService.generateBio(
                        _bioController.text.isEmpty
                            ? 'Local technician'
                            : _bioController.text,
                        categoryName,
                      );
                      if (!mounted) return;
                      final newBio = result['bio'] as String? ?? '';
                      if (newBio.isNotEmpty) _bioController.text = newBio;
                    } catch (e) {
                      debugPrint('AI bio generation failed: $e');
                    }
                    if (mounted) setState(() => _isAiBioLoading = false);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: _isAiBioLoading
                            ? AppColors.slate400
                            : AppColors.amber600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAiBioLoading ? 'Writing...' : 'Let AI write bio',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isAiBioLoading
                              ? AppColors.slate400
                              : AppColors.amber600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Write 2 lines about your tools and service quality...',
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Location
          const Text(
            'Home Location',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.teal600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _homeLocation.address.isNotEmpty
                        ? _homeLocation.address
                        : 'Tap a button below to set your location',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _homeLocation.address.isNotEmpty
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _homeLocation.address.isNotEmpty
                          ? AppColors.slate800
                          : AppColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _autoDetectLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.teal50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.teal200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isLocating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.teal600),
                              )
                            : const Icon(Icons.my_location,
                                size: 16, color: AppColors.teal600),
                        const SizedBox(width: 6),
                        const Text(
                          'Use My Location',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _openMapPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 16, color: AppColors.slate600),
                        SizedBox(width: 6),
                        Text(
                          'Pick on Map',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Finish Button
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: () {
                if (isWorker) {
                  widget.appState.completeWorkerOnboarding(
                    displayName: _nameController.text,
                    categoryIds: [_selectedCategoryId],
                    bio: _bioController.text,
                    yearsExperience: _yearsExperience,
                    homeLocation: _homeLocation,
                  );
                } else {
                  widget.appState.completeEmployerOnboarding(
                    displayName: _nameController.text,
                    homeLocation: _homeLocation,
                  );
                }
                widget.onAuthComplete();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  const Text('Finish & Start Using Rozgar'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
