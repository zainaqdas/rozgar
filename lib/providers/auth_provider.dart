import 'package:flutter/foundation.dart';
import '../models/auth_identity.dart';
import '../models/profile.dart';
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

  Future<String?> signInWithEmail(
    String email,
    String password,
    List<Profile> Function() getProfiles,
    void Function(AuthIdentity, List<Profile>) onAuthenticated,
  ) async {
    try {
      final response = await _supabase.signInWithEmail(email, password);
      if (response.session != null) {
        final user = response.session!.user;
        final identity = AuthIdentity(
          id: user.id,
          email: email,
          phoneNumber: user.phone,
          preferredLanguage: PreferredLanguage.en,
          createdAt: user.createdAt is DateTime
              ? user.createdAt as DateTime
              : DateTime.tryParse(user.createdAt.toString()) ?? DateTime.now(),
        );
        _authIdentity = identity;
        final profiles = await _supabase.getProfilesByAuthId(user.id);
        _needsOnboarding = profiles.isEmpty;
        notifyListeners();
        onAuthenticated(identity, profiles);
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

  Future<String?> signUpWithEmail(
    String email,
    String password,
    void Function(AuthIdentity) onSignedUp,
  ) async {
    try {
      final response = await _supabase.signUpWithEmail(email, password);
      if (response.session != null) {
        final user = response.session!.user;
        final identity = AuthIdentity(
          id: user.id,
          email: email,
          preferredLanguage: PreferredLanguage.en,
          createdAt: DateTime.now(),
        );
        onSignedUp(identity);
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

  /// Legacy phone/email login (mock OTP flow).
  void loginWithPhoneOrEmail(String contact) {
    final isPhone = contact.contains('+') ||
        contact.replaceAll(' ', '').contains(RegExp(r'^\d+$'));
    _authIdentity = AuthIdentity(
      id: 'auth-user-1',
      phoneNumber: isPhone ? contact : null,
      email: !isPhone ? contact : null,
      preferredLanguage: PreferredLanguage.en,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  bool verifyOtp(String otp) {
    return true;
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
