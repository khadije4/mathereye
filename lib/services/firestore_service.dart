import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> createChild(String childId, String pairingCode) async {
    await _db.collection('children').doc(childId).set({
      'pairingCode': pairingCode,
      'parentFcmToken': null,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> writeAlert(String childId, String type, String matchedText) async {
    await _db.collection('children').doc(childId).collection('alerts').add({
      'type': type,
      'matchedText': matchedText,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _db.collection('children').doc(childId)
        .update({'lastSeen': FieldValue.serverTimestamp()});
  }

  static Future<void> writeActivityReport(String childId, String analysisJson) async {
    Map<String, dynamic> analysis = {};
    try {
      analysis = jsonDecode(analysisJson) as Map<String, dynamic>;
    } catch (e) {
      // Try to extract JSON block from response if wrapped in markdown
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(analysisJson);
      if (match == null) return;
      try {
        analysis = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } catch (_) { return; }
    }

    await _db.collection('children').doc(childId).collection('reports').add({
      'analysis': analysis,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    final spec = analysis['specialistRecommendation'] as Map<String, dynamic>?;
    if (spec != null && spec['needed'] == true && spec['urgency'] == 'immediately') {
      await writeAlert(childId, 'specialist_urgent', spec['reason_fr'] ?? '');
    }
  }

  static Future<String?> findChildByCode(String code) async {
    final q = await _db.collection('children')
        .where('pairingCode', isEqualTo: code).limit(1).get();
    return q.docs.isEmpty ? null : q.docs.first.id;
  }

  static Future<void> saveParentToken(String childId, String token) async =>
      _db.collection('children').doc(childId).update({'parentFcmToken': token});

  static Stream<QuerySnapshot> alertStream(String childId) => _db
      .collection('children').doc(childId).collection('alerts')
      .orderBy('timestamp', descending: true).limit(50).snapshots();

  static Future<void> markAlertRead(String childId, String alertId) async =>
      _db.collection('children').doc(childId)
          .collection('alerts').doc(alertId).update({'read': true});

  static Stream<QuerySnapshot> reportStream(String childId) => _db
      .collection('children').doc(childId).collection('reports')
      .orderBy('timestamp', descending: true).limit(20).snapshots();

  static Future<List<Map<String, dynamic>>> getRecentReports(String childId,
      {int limit = 5}) async {
    final snap = await _db.collection('children').doc(childId)
        .collection('reports')
        .orderBy('timestamp', descending: true).limit(limit).get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
