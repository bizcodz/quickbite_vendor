import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? verificationId;
  static String? _localOtp; // For local mock OTP

  static Future<void> sendOtp({
    required String phone,
    required Function onCodeSent,
    required Function(String) onError,
  }) async {
    // Generate a random 6-digit OTP
    _localOtp = (Random().nextInt(900000) + 100000).toString();
    
    // Show the notification locally
    await NotificationService.showOtpNotification(_localOtp!);
    
    // We still call onCodeSent to proceed to the OTP screen
    // We set a dummy verificationId to bypass Firebase logic if needed
    verificationId = "mock_verification_id";
    onCodeSent();
    
    /* 
    // Original Firebase Logic (Commented out for Local OTP mock)
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? "Error");
      },
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
    */
  }

  static Future<UserCredential?> verifyOtp(String otp) async {
    // Check against local mock OTP
    if (_localOtp != null && otp == _localOtp) {
      // Sign in anonymously to get a UID for Firestore
      return await _auth.signInAnonymously();
    }
    
    /*
    // Original Firebase Logic
    if (verificationId == null) return null;
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
    */
    
    throw Exception("Invalid OTP entered");
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
