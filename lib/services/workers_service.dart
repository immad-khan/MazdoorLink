import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_data.dart';

Future<List<WorkerModel>> getAllApprovedWorkers() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .where('status', isEqualTo: 'approved')
      .get();

  return snapshot.docs.map((doc) {
    return WorkerModel.fromFirestore(doc.data(), docId: doc.id);
  }).toList();
}

Future<List<WorkerModel>> getWorkersByCategory(String categoryKey) async {
  final categoryName = _categoryKeyToName(categoryKey);
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .where('status', isEqualTo: 'approved')
      .where('categoryNameEn', isEqualTo: categoryName)
      .get();

  return snapshot.docs.map((doc) {
    return WorkerModel.fromFirestore(doc.data(), docId: doc.id);
  }).toList();
}

String _categoryKeyToName(String key) {
  switch (key.toLowerCase()) {
    case 'electrician':
      return 'Electrician';
    case 'plumber':
      return 'Plumber';
    case 'carpenter':
      return 'Carpenter';
    case 'ac_mechanic':
    case 'acmechanic':
      return 'AC Mechanic';
    case 'painter':
      return 'Painter';
    case 'cleaner':
      return 'Cleaner';
    default:
      return key;
  }
}

Stream<List<WorkerModel>> streamApprovedWorkers() {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .where('status', isEqualTo: 'approved')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            return WorkerModel.fromFirestore(doc.data(), docId: doc.id);
          }).toList());
}

Stream<List<WorkerModel>> streamWorkersByCategory(String categoryKey) {
  final categoryName = _categoryKeyToName(categoryKey);
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'worker')
      .where('status', isEqualTo: 'approved')
      .where('categoryNameEn', isEqualTo: categoryName)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            return WorkerModel.fromFirestore(doc.data(), docId: doc.id);
          }).toList());
}

Future<Map<String, dynamic>?> getCurrentUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return doc.data();
}

Stream<DocumentSnapshot> streamCurrentUserData() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
}

Future<void> updateProfileImage(String imageUrl) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'profileImage': imageUrl,
  });
}

Future<void> updateUserProfile({
  String? name,
  String? phone,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final Map<String, dynamic> updates = {};
  if (name != null) updates['name'] = name;
  if (phone != null) updates['phone'] = phone;
  if (updates.isNotEmpty) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
  }
}
