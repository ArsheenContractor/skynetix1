import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> testWrite() async {
  await _db.collection('issues').add({
    'lat': 12.9716,
    'lng': 77.5946,
    'type': 'pothole',
    'status': 'open',
    'time': FieldValue.serverTimestamp(),
  });
}
}