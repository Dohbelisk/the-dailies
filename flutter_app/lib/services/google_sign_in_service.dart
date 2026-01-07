import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleSignInResult {
  final bool success;
  final String? idToken;
  final String? error;
  final bool cancelled;

  GoogleSignInResult._({
    required this.success,
    this.idToken,
    this.error,
    this.cancelled = false,
  });

  factory GoogleSignInResult.success(String idToken) =>
      GoogleSignInResult._(success: true, idToken: idToken);

  factory GoogleSignInResult.failure(String error) =>
      GoogleSignInResult._(success: false, error: error);

  factory GoogleSignInResult.cancelled() =>
      GoogleSignInResult._(success: false, cancelled: true);
}

class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and return the Firebase ID token
  Future<GoogleSignInResult> signIn() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return GoogleSignInResult.cancelled();
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase to get verified ID token
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        return GoogleSignInResult.failure('Failed to get ID token');
      }

      return GoogleSignInResult.success(idToken);
    } catch (e) {
      return GoogleSignInResult.failure('Google Sign-In failed: $e');
    }
  }

  /// Sign out from Google and Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// Check if user is currently signed in with Google
  bool get isSignedIn => _googleSignIn.currentUser != null;
}
