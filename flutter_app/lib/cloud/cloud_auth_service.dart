import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CloudAuthService {
  CloudAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      return _auth.signInWithPopup(provider);
    }

    final account = await _google.signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled');
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// If the current user is anonymous, link the Google credential to preserve data.
  Future<UserCredential> linkAnonymousWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return signInWithGoogle();
    if (!user.isAnonymous) return signInWithGoogle();

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      return user.linkWithPopup(provider);
    }

    final account = await _google.signIn();
    if (account == null) {
      throw StateError('Google link cancelled');
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return user.linkWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _google.signOut();
    }
  }
}

