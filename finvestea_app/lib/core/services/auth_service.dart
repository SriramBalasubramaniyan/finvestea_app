import 'dart:async';
import 'package:finvestea_app/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

// ─── AuthUser ──────────────────────────────────────────────────────────────────

class AuthUser {
  final String uid;
  final String email;
  final String? displayName;

  const AuthUser({required this.uid, required this.email, this.displayName});
}

// ─── AuthException ─────────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String code;
  final String? message;

  const AuthException({required this.code, this.message});

  @override
  String toString() => message ?? code;
}

// ─── AuthService ───────────────────────────────────────────────────────────────
// Fully local, no network calls. Accepts any valid-looking credentials.

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AuthUser? _currentUser;
  final _controller = StreamController<AuthUser?>.broadcast();

  AuthUser? get currentUser => _currentUser;

  set setCurrentUser(AuthUser? user) {
    _currentUser = user;
  }

  Stream<AuthUser?> get authStateChanges => _controller.stream;

  // ─────────────────────────────────────────
  // Email / Password
  // ─────────────────────────────────────────

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!email.contains('@')) {
      throw const AuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }
    
    if (password.isEmpty) {
      throw const AuthException(
        code: 'wrong-password',
        message: 'Incorrect password. Please try again.',
      );
    }

    try {
      final response = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      
      final uId = response.user?.uid ?? 'local_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      _currentUser = AuthUser(
        uid: uId,
        email: email,
        displayName: response.user?.displayName ?? email.split('@').first,
      );
      _controller.add(_currentUser);
      return _currentUser!;
    } on FirebaseAuthException catch(e,a) {
        dev.log("Sign in FirebaseAuthException:${e.toString()} $a");
        throw AuthException(
          code: e.code,
          message: getErrorMessage(AuthException(code: e.code))
        );
    }
  }

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!email.contains('@')) {
      throw const AuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }
  
    if (password.length < 6) {
      throw const AuthException(
        code: 'weak-password',
        message: 'Password must be at least 6 characters.',
      );
    }

    try {
      final response = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      final uId = response.user?.uid ?? 'local_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      _currentUser = AuthUser(
        uid: uId,
        email: email,
        displayName: response.user?.displayName ?? email.split('@').first,
      );
      _controller.add(_currentUser);
      addFireUser(_currentUser!);
      return _currentUser!;
    } on FirebaseAuthException catch(e,a) {
        dev.log("Sign in FirebaseAuthException:${e.toString()} $a");
        throw AuthException(
          code: e.code,
          message: getErrorMessage(AuthException(code: e.code))
        );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Local mode: no-op (snackbar in UI says "email sent")
  }

  // ─────────────────────────────────────────
  // Phone OTP
  // ─────────────────────────────────────────

  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(AuthException e) onError,
    VoidCallback? onAutoVerified,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock verification ID encodes the phone number for use in verifyOTP
    onCodeSent('mock_otp_$phoneNumber');
  }

  Future<AuthUser?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Accept any 6-digit code
    if (smsCode.length != 6) {
      throw const AuthException(
        code: 'invalid-verification-code',
        message: 'Invalid OTP. Please check and try again.',
      );
    }
    final phone = verificationId.replaceFirst('mock_otp_', '');
    _currentUser = AuthUser(
      uid: 'local_phone_$phone',
      email: '$phone@phone.local',
      displayName: phone,
    );
    _controller.add(_currentUser);
    return _currentUser;
  }

  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(AuthException e) onError,
    VoidCallback? onAutoVerified,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
    );
  }

  // ─────────────────────────────────────────
  // Common
  // ─────────────────────────────────────────

  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
    await FirebaseAuth.instance.signOut();
  }

  String getErrorMessage(AuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'code-expired':
        return 'OTP has expired. Please request a new one.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
