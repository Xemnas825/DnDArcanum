import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'cloud_auth_service.dart';

/// Shared Firebase session used by cloud features.
///
/// - App runs fine without Firebase configured.
/// - When Firebase is configured, we use anonymous auth by default to enable
///   sync/backup with zero friction.
class CloudSession {
  CloudSession({
    FirebaseAuth? auth,
    CloudAuthService? cloudAuth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        cloudAuth = cloudAuth ?? CloudAuthService(auth: auth);

  final FirebaseAuth _auth;
  final CloudAuthService cloudAuth;

  /// Ensures Firebase is initialized and the user is signed in.
  /// Returns the current UID.
  Future<String> ensureSignedIn() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final current = _auth.currentUser;
    if (current != null) return current.uid;

    final cred = await _auth.signInAnonymously();
    return cred.user!.uid;
  }
}

