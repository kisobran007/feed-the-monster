part of '../../main.dart';

class AuthService {
  const AuthService._();
  static Future<void>? _googleSignInInitialization;

  static Future<void> _ensureGoogleSignInInitialized() {
    _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
    return _googleSignInInitialization!;
  }

  static Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    }

    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
