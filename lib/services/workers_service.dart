import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_data.dart';
import 'translation_service.dart';

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
      .where('isOnline', isEqualTo: true)
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
      .where('isOnline', isEqualTo: true)
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

Future<String?> getUserEmail(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  final email = doc.data()?['email']?.toString() ?? '';
  return email.isEmpty ? null : email;
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

const List<String> kBusyJobStatuses = [
  'accepted',
  'arrival_pending',
  'working',
  'worker_completed',
  'payment_pending',
  'worker_payment_pending',
  'payment_disputed',
];

Future<bool> workerHasActiveJob(String workerId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: workerId)
      .where('status', whereIn: kBusyJobStatuses)
      .limit(1)
      .get();
  return snapshot.docs.isNotEmpty;
}

Future<void> scheduleAcceptedJob(String jobId, DateTime scheduledTime) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'status': 'accepted',
    'scheduledReminderAt': Timestamp.fromDate(scheduledTime),
    'scheduleConfirmed': false,
    'acceptedAt': FieldValue.serverTimestamp(),
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> confirmJobSchedule(String jobId) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'scheduleConfirmed': true,
    'scheduleConfirmedAt': FieldValue.serverTimestamp(),
  });
}

Stream<QuerySnapshot> streamWorkerUpcomingJobs(String workerId) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: workerId)
      .where('status', isEqualTo: 'accepted')
      .snapshots();
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

/// Creates a conversation with [otherUserId]. Uses a deterministic document id
/// (`conv_<uidA>_<uidB>`, uids sorted) so two users starting a chat
/// simultaneously can never create duplicate conversations.
Future<String> createConversation({
  required String otherUserId,
  required String otherUserName,
  String? otherUserImage,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Not logged in');
  final ids = [user.uid, otherUserId]..sort();
  final convId = 'conv_${ids[0]}_${ids[1]}';
  final ref = FirebaseFirestore.instance.collection('conversations').doc(convId);
  try {
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (snap.exists) return;
      txn.set(ref, {
        'participants': [user.uid, otherUserId],
        'participantNames': {
          user.uid: user.displayName ?? 'User',
          otherUserId: otherUserName,
        },
        'participantImages': {
          user.uid: user.photoURL ?? '',
          otherUserId: otherUserImage ?? '',
        },
        'lastMessage': '',
        'lastMessageEn': '',
        'lastMessageUr': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCounts': {user.uid: 0, otherUserId: 0},
        'typing': {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  } catch (_) {
    // Already exists (created concurrently) — reuse it.
  }
  return convId;
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
  final sourceLang = detectLanguage(text);
  final otherLang = sourceLang == 'en' ? 'ur' : 'en';
  final translated = await TranslationService().translate(
    text: text,
    sourceLang: sourceLang,
    targetLang: otherLang,
  );
  final textEn = sourceLang == 'en' ? text : translated;
  final textUr = sourceLang == 'ur' ? text : translated;
  final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
  await FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(convRef);
    if (!snap.exists) return;
    final data = snap.data() ?? {};
    final participants = List<String>.from(data['participants'] ?? []);
    final otherId = participants.where((p) => p != user.uid).firstOrNull ?? '';
    tx.set(convRef.collection('messages').doc(), {
      'senderId': user.uid,
      'text': text,
      'textEn': textEn,
      'textUr': textUr,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [user.uid],
    });
    final unread = Map<String, dynamic>.from(data['unreadCounts'] as Map? ?? {});
    if (otherId.isNotEmpty) {
      unread[otherId] = ((unread[otherId] as num?)?.toInt() ?? 0) + 1;
    }
    tx.update(convRef, {
      'lastMessage': text,
      'lastMessageEn': textEn,
      'lastMessageUr': textUr,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts': unread,
    });
  });
}

/// Marks the current user's incoming messages in [conversationId] as read and
/// resets their unread counter on the conversation doc.
Future<void> markConversationRead(String conversationId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
  try {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(convRef);
      if (!snap.exists) return;
      final unread = Map<String, dynamic>.from(snap.data()?['unreadCounts'] as Map? ?? {});
      unread[user.uid] = 0;
      tx.update(convRef, {'unreadCounts': unread});
    });
  } catch (_) {
    // Conversation may have been deleted or field already matches.
  }
  final snap = await convRef.collection('messages')
      .where('senderId', isNotEqualTo: user.uid)
      .get();
  final batch = FirebaseFirestore.instance.batch();
  var changed = false;
  for (final doc in snap.docs) {
    final readBy = List<String>.from(doc['readBy'] as List? ?? []);
    if (!readBy.contains(user.uid)) {
      batch.update(doc.reference, {'readBy': FieldValue.arrayUnion([user.uid])});
      changed = true;
    }
  }
  if (changed) await batch.commit();
}

/// Publishes a typing heartbeat for the current user on [conversationId].
/// Pass `false` to clear the indicator.
Future<void> setTyping(String conversationId, bool typing) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
  if (typing) {
    await convRef.update({'typing.${user.uid}': FieldValue.serverTimestamp()});
  } else {
    await convRef.update({'typing.${user.uid}': FieldValue.delete()});
  }
}

/// Publishes online/offline presence for the current user in `presence/{uid}`.
Future<void> setPresence({required bool online}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final ref = FirebaseFirestore.instance.collection('presence').doc(user.uid);
  await ref.set({
    'online': online,
    'lastSeen': FieldValue.serverTimestamp(),
  });
}

Stream<DocumentSnapshot> streamPresence(String uid) {
  return FirebaseFirestore.instance.collection('presence').doc(uid).snapshots();
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
