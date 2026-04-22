import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_session.dart';

class CloudBackupService {
  CloudBackupService({
    FirebaseFirestore? firestore,
    CloudSession? session,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _session = session ?? CloudSession();

  final FirebaseFirestore _firestore;
  final CloudSession _session;

  /// Initializes Firebase (if needed) and signs in anonymously.
  /// Returns the UID on success.
  Future<String> ensureReady() => _session.ensureSignedIn();

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('dndArcanumBackups').doc(uid);

  Future<void> uploadJsonBackup({required String json}) async {
    final uid = await ensureReady();
    await _doc(uid).set({
      'schema': 1,
      'updatedAt': FieldValue.serverTimestamp(),
      'json': json,
    }, SetOptions(merge: true));
  }

  /// Returns null if there is no cloud backup yet.
  Future<String?> downloadLatestJsonBackup() async {
    final uid = await ensureReady();
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    final json = data?['json'];
    return json is String && json.trim().isNotEmpty ? json : null;
  }
}

