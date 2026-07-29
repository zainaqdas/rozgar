import 'package:flutter/foundation.dart';
import '../models/auth_identity.dart';
import '../services/supabase_service.dart';

class AuthNotifier extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService.instance;

  AuthIdentity? _authIdentity;
  bool _needsOnboarding = false;
  String? _lastOperationError;

  AuthIdentity? get authIdentity => _authIdentity;
  bool get needsOnboarding => _needsOnboarding;
  String? get lastOperationError => _lastOperationError;

  void clearOperationError() {
    _lastOperationError = null;
    notifyListeners();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.resetPasswordForEmail(email);
      return null;
    } catch (e) {
      debugPrint('Password reset error: $e');
      _lastOperationError = 'Password reset failed';
      notifyListeners();
      return 'Failed to send reset email: ${e.toString()}';
    }
  }

  /// Send an OTP to a phone number. Returns error string or null on success.
  Future<String?> sendPhoneOtp(String phone) async {
    final validationError = _validatePhone(phone);
    if (validationError != null) return validationError;
    try {
      await _supabase.signInWithPhoneOtp(phone);
      return null;
    } catch (e) {
      debugPrint('Phone OTP send error: $e');
      _lastOperationError = 'Failed to send OTP';
      notifyListeners();
      return 'Failed to send OTP: ${e.toString()}';
    }
  }

  /// Validate E.164 phone format. Pakistan numbers: +92XXXXXXXXXX (13 digits total).
  static String? _validatePhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      return 'Phone number is required.';
    }
    if (!trimmed.startsWith('+')) {
      return 'Phone number must start with + (e.g. +923001234567).';
    }
    final digits = trimmed.substring(1);
    if (digits.length < 10 || digits.length > 15) {
      return 'Invalid phone number length. Use format +92XXXXXXXXXX.';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
      return 'Phone number must contain only digits after +.';
    }
    return null;
  }

  /// Verify an SMS OTP. On success, sets auth identity and checks onboarding.
  /// Returns error string or null on success.
  Future<String?> verifyPhoneOtp(String phone, String otp) async {
    try {
      final response = await _supabase.verifyPhoneOtp(phone, otp);
      if (response.session != null) {
        final user = response.session!.user;
        _authIdentity = AuthIdentity(
          id: user.id,
          phoneNumber: phone,
          preferredLanguage: PreferredLanguage.en,
          createdAt: user.createdAt is DateTime
              ? user.createdAt as DateTime
              : DateTime.tryParse(user.createdAt.toString()) ?? DateTime.now(),
        );
        final profiles = await _supabase.getProfilesByAuthId(user.id);
        _needsOnboarding = profiles.isEmpty;
        notifyListeners();
        return null;
      }
      return 'Verification failed. Please try again.';
    } catch (e) {
      debugPrint('Phone OTP verify error: $e');
      _lastOperationError = 'OTP verification failed';
      notifyListeners();
      return 'Invalid code. Please check and try again.';
    }
  }

  /// Simple email sign-in (returns error string or null on success).
  Future<String?> signInSimple(String email, String password) async {
    try {
      final response = await _supabase.signInWithEmail(email, password);
      if (response.session != null) {
        final user = response.session!.user;
        _authIdentity = AuthIdentity(
          id: user.id,
          email: email,
          phoneNumber: user.phone,
          preferredLanguage: PreferredLanguage.en,
          createdAt: user.createdAt is DateTime
              ? user.createdAt as DateTime
              : DateTime.tryParse(user.createdAt.toString()) ?? DateTime.now(),
        );
        final profiles = await _supabase.getProfilesByAuthId(user.id);
        _needsOnboarding = profiles.isEmpty;
        notifyListeners();
        return null;
      }
      return 'Login failed. Please check your credentials.';
    } catch (e) {
      debugPrint('Sign in error: $e');
      _lastOperationError = 'Sign in failed';
      notifyListeners();
      return 'Login failed: ${e.toString()}';
    }
  }

  /// Simple email sign-up (returns error string or null on success).
  Future<String?> signUpSimple(String email, String password) async {
    try {
      final response = await _supabase.signUpWithEmail(email, password);
      if (response.session != null) {
        return null;
      }
      return 'Signup successful! Check your email to confirm your account.';
    } catch (e) {
      debugPrint('Sign up error: $e');
      _lastOperationError = 'Sign up failed';
      notifyListeners();
      return 'Signup failed: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      _lastOperationError = 'Sign out failed';
    }
    _authIdentity = null;
    _needsOnboarding = false;
    notifyListeners();
  }
}
