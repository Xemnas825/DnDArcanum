import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/character.dart';
import 'cloud_session.dart';

class CloudCharactersSync {
  CloudCharactersSync({
    FirebaseFirestore? firestore,
    CloudSession? session,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _session = session ?? CloudSession();

  final FirebaseFirestore _firestore;
  final CloudSession _session;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('characters');

  Future<void> upsert(Character c, {required int updatedAtMs}) async {
    final uid = await _session.ensureSignedIn();
    await _col(uid).doc(c.id).set({
      'updatedAtMs': updatedAtMs,
      'deleted': false,
      'character': c.toJson(),
    }, SetOptions(merge: true));
  }

  Future<void> tombstone(String id, {required int updatedAtMs}) async {
    final uid = await _session.ensureSignedIn();
    await _col(uid).doc(id).set({
      'updatedAtMs': updatedAtMs,
      'deleted': true,
    }, SetOptions(merge: true));
  }

  /// Pulls all remote characters and returns raw docs.
  Future<List<Map<String, dynamic>>> listRemote() async {
    final uid = await _session.ensureSignedIn();
    final snap = await _col(uid).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}

