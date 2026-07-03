import 'dart:math';
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

/// Returns workers in [categoryKey] who have at least one skill matching
/// any of the [selectedSkillTitles]. Filtering is done client-side because
/// Firestore cannot query on nested array-of-map fields.
/// If [selectedSkillTitles] is empty, all workers in the category are returned.
Future<List<WorkerModel>> getWorkersByCategoryAndSkills(
  String categoryKey,
  List<String> selectedSkillTitles,
) async {
  // Fetch all approved workers in the right category first.
  final allInCategory = await getWorkersByCategory(categoryKey);

  if (selectedSkillTitles.isEmpty) return allInCategory;

  final normalised = selectedSkillTitles
      .map((t) => t.trim().toLowerCase())
      .toSet();

  // Keep only workers whose skills list contains at least one match.
  return allInCategory.where((worker) {
    final workerSkills = worker.skillsEn
        .map((s) => s.trim().toLowerCase())
        .toSet();
    return workerSkills.intersection(normalised).isNotEmpty;
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

Future<String?> getUserPhone(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.data()?['phone']?.toString();
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
  String? birthday,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final Map<String, dynamic> updates = {};
  if (name != null) updates['name'] = name;
  if (phone != null) updates['phone'] = phone;
  if (birthday != null && birthday.isNotEmpty) updates['birthday'] = birthday;
  if (updates.isNotEmpty) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
  }
}

Future<String?> createJobOffer({
  required String? workerId,
  required String workerName,
  required String descriptionEn,
  required String descriptionUr,
  required double price,
  required String categoryKey,
  String paymentMethod = 'Cash',
  double? customerLatitude,
  double? customerLongitude,
  int visibilityDurationMinutes = 10,
}) async {
  final customer = FirebaseAuth.instance.currentUser;
  if (customer == null || workerId == null) return null;

  final customerDoc = await FirebaseFirestore.instance.collection('users').doc(customer.uid).get();
  final customerName = customerDoc.data()?['name']?.toString() ?? customer.displayName ?? 'Customer';

  final pin = '${1000 + Random().nextInt(9000)}';
  final expiresAt = DateTime.now().add(Duration(minutes: visibilityDurationMinutes));

  final docRef = await FirebaseFirestore.instance.collection('jobs').add({
    'customerId': customer.uid,
    'customerName': customerName,
    'workerId': workerId,
    'workerName': workerName,
    'descriptionEn': descriptionEn,
    'descriptionUr': descriptionUr,
    'price': price,
    'categoryKey': categoryKey,
    'paymentMethod': paymentMethod,
    'status': 'pending',
    'pin': pin,
    if (customerLatitude != null) 'customerLatitude': customerLatitude,
    if (customerLongitude != null) 'customerLongitude': customerLongitude,
    'createdAt': FieldValue.serverTimestamp(),
    'expiresAt': expiresAt.toIso8601String(),
    'visibilityDurationMinutes': visibilityDurationMinutes,
  });

  return docRef.id;
}

Future<void> updateJobStatus(String jobId, String status) async {
  final updates = <String, dynamic>{
    'status': status,
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  };

  switch (status) {
    case 'accepted':
      updates['acceptedAt'] = FieldValue.serverTimestamp();
      break;
    case 'arrival_pending':
      updates['workerArrivedAt'] = FieldValue.serverTimestamp();
      break;
    case 'working':
      updates['customerConfirmedArrivalAt'] = FieldValue.serverTimestamp();
      break;
    case 'arrival_declined':
      updates['customerDeclinedArrivalAt'] = FieldValue.serverTimestamp();
      break;
    case 'worker_completed':
      updates['workerCompletedAt'] = FieldValue.serverTimestamp();
      break;
    case 'payment_pending':
      updates['customerConfirmedWorkAt'] = FieldValue.serverTimestamp();
      break;
    case 'worker_payment_pending':
      updates['customerMarkedPaidAt'] = FieldValue.serverTimestamp();
      break;
    case 'payment_disputed':
      updates['paymentDisputedAt'] = FieldValue.serverTimestamp();
      break;
    case 'completed':
      updates['workerConfirmedPaymentAt'] = FieldValue.serverTimestamp();
      updates['customerCompletedAt'] = FieldValue.serverTimestamp();
      updates['completedAt'] = FieldValue.serverTimestamp();
      break;
  }

  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update(updates);
}

Stream<QuerySnapshot> streamWorkerJobs(String workerId) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: workerId)
      .where('status', isEqualTo: 'pending')
      .snapshots();
}

Stream<QuerySnapshot> streamWorkerActiveJobs(String workerId) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: workerId)
      .where('status', whereIn: ['pending', 'accepted', 'arrival_pending', 'working', 'worker_completed', 'payment_pending', 'worker_payment_pending', 'payment_disputed'])
      .orderBy('createdAt', descending: true)
      .snapshots();
}

Stream<double> streamWorkerEarnings() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'completed')
      .snapshots()
      .map((snapshot) => snapshot.docs.fold<double>(0, (total, doc) {
            final data = doc.data();
            final price = data['price'];
            return total + ((price as num?)?.toDouble() ?? 0);
          }));
}

Stream<QuerySnapshot> streamAllJobs() {
  return FirebaseFirestore.instance
      .collection('jobs')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

Future<void> updateJobCompleted(String jobId) async {
  await updateJobStatus(jobId, 'completed');
}

Future<void> submitPaymentComplaint({
  required String jobId,
  required String reason,
  required double amount,
  required String paymentMethod,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  await FirebaseFirestore.instance.collection('complaints').add({
    'jobId': jobId,
    'customerId': user?.uid,
    'type': 'payment_not_made',
    'reason': reason,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'status': 'pending',
    'resolved': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Stream<DocumentSnapshot> streamJobById(String jobId) {
  return FirebaseFirestore.instance.collection('jobs').doc(jobId).snapshots();
}

// ── Complaints ──────────────────────────────

Stream<QuerySnapshot> streamComplaints() {
  return FirebaseFirestore.instance
      .collection('complaints')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

Future<void> resolveComplaint(String complaintId) async {
  await FirebaseFirestore.instance.collection('complaints').doc(complaintId).update({
    'resolved': true,
  });
}

// ── Damage Claims ───────────────────────────

Stream<QuerySnapshot> streamDamageClaims() {
  return FirebaseFirestore.instance
      .collection('damage_claims')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

Future<void> updateDamageClaimStatus(String claimId, String status) async {
  await FirebaseFirestore.instance.collection('damage_claims').doc(claimId).update({
    'status': status,
  });
}

// ── Security Deposits ───────────────────────

Stream<QuerySnapshot> streamSecurityDeposits() {
  return FirebaseFirestore.instance
      .collection('security_deposits')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

// ── Favourite Workers ───────────────────────

Future<void> addFavouriteWorker(String workerId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'favouriteWorkerIds': FieldValue.arrayUnion([workerId]),
  });
}

Future<void> removeFavouriteWorker(String workerId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'favouriteWorkerIds': FieldValue.arrayRemove([workerId]),
  });
}

Stream<List<String>> streamFavouriteWorkerIds() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        final ids = doc.data()?['favouriteWorkerIds'] as List<dynamic>?;
        return ids?.map((e) => e.toString()).toList() ?? [];
      });
}

// ── Conversations & Chat ────────────────────

Future<String> createConversation({
  required String otherUserId,
  required String otherUserName,
  String? otherUserImage,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not logged in');
  final docRef = await FirebaseFirestore.instance.collection('conversations').add({
    'participants': [user.uid, otherUserId],
    'participantNames': {
      user.uid: user.displayName ?? 'User',
      otherUserId: otherUserName,
    },
    if (otherUserImage != null)
      'participantImages': {
        user.uid: '',
        otherUserId: otherUserImage,
      },
    'lastMessage': '',
    'lastTimestamp': FieldValue.serverTimestamp(),
    'createdAt': FieldValue.serverTimestamp(),
  });
  return docRef.id;
}

Stream<QuerySnapshot> streamConversations() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('conversations')
      .where('participants', arrayContains: user.uid)
      .orderBy('lastTimestamp', descending: true)
      .snapshots();
}

Future<void> sendMessage(String conversationId, String text) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .add({
    'senderId': user.uid,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  });
  await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
    'lastMessage': text,
    'lastTimestamp': FieldValue.serverTimestamp(),
  });
}

Stream<QuerySnapshot> streamMessages(String conversationId) {
  return FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();
}

Future<String?> findExistingConversation(String otherUserId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final snapshot = await FirebaseFirestore.instance
      .collection('conversations')
      .where('participants', arrayContains: user.uid)
      .get();
  for (final doc in snapshot.docs) {
    final participants = List<String>.from(doc['participants'] ?? []);
    if (participants.contains(otherUserId)) return doc.id;
  }
  return null;
}
