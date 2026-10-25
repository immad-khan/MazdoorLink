import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_data.dart';
import 'translation_service.dart';
import 'location_service.dart';

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

/// Maximum allowed radius in kilometers for worker matching and job offers
const double kMaxWorkerDistanceKm = 5.0;

/// Calculates distance in kilometers between two GPS coordinates using the Haversine formula
double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // pi / 180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

/// Returns workers in [categoryKey] who have at least one skill matching
/// any of the [selectedSkillTitles] AND are within [maxDistanceKm] (default 5.0 km) of customer.
Future<List<WorkerModel>> getWorkersByCategoryAndSkills(
  String categoryKey,
  List<String> selectedSkillTitles, {
  double? customerLatitude,
  double? customerLongitude,
  double maxDistanceKm = kMaxWorkerDistanceKm,
}) async {
  // Fetch all approved workers in the right category first.
  final allInCategory = await getWorkersByCategory(categoryKey);

  List<WorkerModel> matched = allInCategory;

  if (selectedSkillTitles.isNotEmpty) {
    final normalised = selectedSkillTitles
        .map((t) => t.trim().toLowerCase())
        .toSet();

    matched = matched.where((worker) {
      final workerSkills = worker.skillsEn
          .map((s) => s.trim().toLowerCase())
          .toSet();
      return workerSkills.intersection(normalised).isNotEmpty;
    }).toList();
  }

  // 5 km Distance Filtering (when customer coordinates are provided)
  if (customerLatitude != null && customerLongitude != null) {
    final List<WorkerModel> nearbyWorkers = [];

    for (final worker in matched) {
      if (worker.latitude != null && worker.longitude != null) {
        final dist = calculateDistanceKm(
          customerLatitude,
          customerLongitude,
          worker.latitude!,
          worker.longitude!,
        );

        // Filter: Keep strictly workers within the 5 km radius
        if (dist <= maxDistanceKm) {
          nearbyWorkers.add(
            worker.copyWith(
              distanceKm: double.parse(dist.toStringAsFixed(1)),
            ),
          );
        }
      } else {
        // Fallback for workers whose GPS coordinates are not yet set
        if (worker.distanceKm <= maxDistanceKm) {
          nearbyWorkers.add(worker);
        }
      }
    }

    // Sort by closest worker first
    nearbyWorkers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return nearbyWorkers;
  }

  return matched;
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
  double maxDistanceKm = kMaxWorkerDistanceKm,
}) async {
  final customer = FirebaseAuth.instance.currentUser;
  if (customer == null || workerId == null) return null;

  // 5 km Range Verification: enforce request is sent ONLY to worker within 5 km
  double? distanceKm;
  if (customerLatitude != null && customerLongitude != null) {
    try {
      final workerDoc = await FirebaseFirestore.instance.collection('users').doc(workerId).get();
      final workerData = workerDoc.data();
      final workerLat = (workerData?['latitude'] as num?)?.toDouble();
      final workerLng = (workerData?['longitude'] as num?)?.toDouble();

      if (workerLat != null && workerLng != null) {
        final calculatedDist = calculateDistanceKm(
          customerLatitude,
          customerLongitude,
          workerLat,
          workerLng,
        );
        distanceKm = double.parse(calculatedDist.toStringAsFixed(1));

        if (calculatedDist > maxDistanceKm) {
          throw Exception(
            'Worker is outside the ${maxDistanceKm.toStringAsFixed(0)} km service range (${calculatedDist.toStringAsFixed(1)} km away).',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('service range')) rethrow;
    }
  }

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
    if (distanceKm != null) 'distanceKm': distanceKm,
    'maxDistanceRadiusKm': maxDistanceKm,
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
  'pending',
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

/// Active job statuses for customers (not yet completed/completedly cancelled in effect - any non-completed)
const List<String> kCustomerActiveJobStatuses = [
  'pending',
  'scheduled',
  'accepted',
  'arrival_pending',
  'working',
  'worker_completed',
  'payment_pending',
  'worker_payment_pending',
  'payment_disputed',
];

Future<bool> customerHasActiveJobInCategory(
  String customerId,
  String categoryKey,
) async {
  if (customerId.isEmpty) return false;
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('customerId', isEqualTo: customerId)
        .get();
    final targetCat = categoryKey.toLowerCase().trim();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status']?.toString() ?? '').toLowerCase().trim();
      if (!kCustomerActiveJobStatuses.contains(status)) continue;
      final cat = (data['categoryKey']?.toString() ?? data['category']?.toString() ?? '').toLowerCase().trim();
      if (cat == targetCat) {
        return true;
      }
    }
  } catch (_) {}
  return false;
}

class CustomerActiveJobInfo {
  final String jobId;
  final String categoryKey;
  final String workerName;
  final String status;
  final double price;

  const CustomerActiveJobInfo({
    required this.jobId,
    required this.categoryKey,
    required this.workerName,
    required this.status,
    required this.price,
  });
}

Stream<Map<String, CustomerActiveJobInfo>> streamCustomerActiveCategoriesMap(String customerId) {
  if (customerId.isEmpty) return Stream.value({});
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((snapshot) {
        final map = <String, CustomerActiveJobInfo>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final status = (data['status']?.toString() ?? '').toLowerCase().trim();
          if (!kCustomerActiveJobStatuses.contains(status)) continue;
          final cat = (data['categoryKey']?.toString() ?? data['category']?.toString() ?? '').toLowerCase().trim();
          if (cat.isNotEmpty && !map.containsKey(cat)) {
            map[cat] = CustomerActiveJobInfo(
              jobId: doc.id,
              categoryKey: cat,
              workerName: data['workerName']?.toString() ?? 'Worker',
              status: data['status']?.toString() ?? 'pending',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
            );
          }
        }
        return map;
      });
}

Future<void> scheduleAcceptedJob(String jobId, DateTime scheduledTime) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'status': 'scheduled',
    'scheduledReminderAt': Timestamp.fromDate(scheduledTime),
    'scheduleConfirmed': false,
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  });
}

/// Worker proposes a scheduled time without being busy â€” sets status to 'scheduled'
Future<void> scheduleProposedJob(String jobId, DateTime scheduledTime) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'status': 'scheduled',
    'scheduledReminderAt': Timestamp.fromDate(scheduledTime),
    'scheduleConfirmed': false,
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> confirmJobSchedule(String jobId) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'scheduleConfirmed': true,
    'scheduleConfirmedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> startScheduledJob(String jobId) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'scheduleStarted': true,
    'scheduleStartedAt': FieldValue.serverTimestamp(),
    'status': 'accepted',
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  });
}

Stream<QuerySnapshot> streamWorkerUpcomingJobs(String workerId) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: workerId)
      .where('status', isEqualTo: 'accepted')
      .snapshots();
}

Stream<QuerySnapshot> streamWorkerScheduledJobs(String workerId) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('workerId', isEqualTo: workerId)
      .where('status', isEqualTo: 'scheduled')
      .snapshots();
}

Stream<QuerySnapshot> streamCustomerScheduledJobs(String customerId) {
  return FirebaseFirestore.instance
      .collection('jobs')
      .where('customerId', isEqualTo: customerId)
      .where('status', isEqualTo: 'scheduled')
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

Future<void> acceptScheduledJob(String jobId) async {
  await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
    'scheduleConfirmed': true,
    'scheduleConfirmedAt': FieldValue.serverTimestamp(),
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  });
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

/// Deducts 2% platform commission from worker's top-up balance when customer pays
Future<void> deductPlatformCommission({
  required String jobId,
  double? amount,
  String? paymentMethod,
}) async {
  try {
    final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
    final jobSnap = await jobRef.get();
    if (!jobSnap.exists) return;

    final data = jobSnap.data() as Map<String, dynamic>;

    // Idempotency check: don't deduct commission multiple times for the same job
    if (data['commissionDeducted'] == true) return;

    final workerId = data['workerId']?.toString() ?? '';
    final workerName = data['workerName']?.toString() ?? 'Worker';
    final customerId = data['customerId']?.toString() ?? '';
    final customerName = data['customerName']?.toString() ?? 'Customer';
    final jobTitle = data['descriptionEn']?.toString() ??
        data['descriptionUr']?.toString() ??
        data['categoryKey']?.toString() ??
        'Service Job';
    final categoryKey = data['categoryKey']?.toString() ?? 'general';

    final totalPaid = amount ??
        (data['price'] as num?)?.toDouble() ??
        0.0;
    if (totalPaid <= 0) return;

    const commissionRate = 0.02; // 2% fixed platform fee
    final commissionAmount = double.parse((totalPaid * commissionRate).toStringAsFixed(2));
    final method = paymentMethod ?? data['paymentMethod']?.toString() ?? 'Cash';

    // 1. Deduct 2% from worker's topup balance in users collection
    if (workerId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(workerId).set({
        'topupBalance': FieldValue.increment(-commissionAmount),
      }, SetOptions(merge: true));

      // Also sync currentBalance in security_deposits
      final depositQuery = await FirebaseFirestore.instance
          .collection('security_deposits')
          .where('workerId', isEqualTo: workerId)
          .limit(1)
          .get();

      if (depositQuery.docs.isNotEmpty) {
        final docId = depositQuery.docs.first.id;
        await FirebaseFirestore.instance
            .collection('security_deposits')
            .doc(docId)
            .update({
          'currentBalance': FieldValue.increment(-commissionAmount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 2. Mark job document with commission details
    await jobRef.set({
      'commissionDeducted': true,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'commissionDeductedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Log to platform_earnings collection
    await FirebaseFirestore.instance.collection('platform_earnings').add({
      'jobId': jobId,
      'workerId': workerId,
      'workerName': workerName,
      'customerId': customerId,
      'customerName': customerName,
      'jobTitle': jobTitle,
      'categoryKey': categoryKey,
      'totalPaid': totalPaid,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'paymentMethod': method,
      'status': 'Deducted from Top-up Balance',
      'timestamp': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Error deducting platform commission: $e');
  }
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

// â”€â”€ Complaints â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Damage Claims â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Security Deposits â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Stream<QuerySnapshot> streamSecurityDeposits() {
  return FirebaseFirestore.instance
      .collection('security_deposits')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

// â”€â”€ Favourite Workers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Conversations & Chat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    // Already exists (created concurrently) â€” reuse it.
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

/// Global service managing worker online presence and app lifecycle.

// ── Worker Ratings & Reviews ───────────────────────

/// Submits a rating and review for a worker after job completion.
/// Updates the worker's average rating and total review count.
/// Also stores the individual review in a subcollection.
Future<void> submitWorkerRating({
  required String workerId,
  required String jobId,
  required int rating,
  String? reviewText,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('User must be logged in to submit a rating');
  }

  if (rating < 1 || rating > 5) {
    throw ArgumentError('Rating must be between 1 and 5');
  }

  final firestore = FirebaseFirestore.instance;

  // 1. Get job info to ensure valid context and resolve workerId if not provided
  final jobDoc = await firestore.collection('jobs').doc(jobId).get();
  final jobData = jobDoc.data();
  final actualWorkerId = workerId.isNotEmpty
      ? workerId
      : (jobData?['workerId']?.toString() ?? '');

  if (actualWorkerId.isEmpty) {
    throw StateError('No worker found associated with this job');
  }

  final jobTitle = jobData?['descriptionEn']?.toString() ??
      jobData?['categoryKey']?.toString() ??
      'Service';

  // 2. Get customer info
  String customerName = 'Customer';
  try {
    final customerDoc = await firestore.collection('users').doc(user.uid).get();
    customerName = customerDoc.data()?['name']?.toString() ??
        jobData?['customerName']?.toString() ??
        user.displayName ??
        'Customer';
  } catch (_) {
    customerName = jobData?['customerName']?.toString() ?? user.displayName ?? 'Customer';
  }

  final cleanReviewText = reviewText?.trim() ?? '';

  final reviewPayload = {
    'customerId': user.uid,
    'customerName': customerName,
    'jobId': jobId,
    'jobTitle': jobTitle,
    'rating': rating,
    'review': cleanReviewText,
    'createdAt': FieldValue.serverTimestamp(),
  };

  // 3. Store the individual review in worker's reviews subcollection
  try {
    await firestore
        .collection('users')
        .doc(actualWorkerId)
        .collection('reviews')
        .add(reviewPayload);
  } catch (e) {
    debugPrint('Subcollection review save note: $e');
  }

  // Also store in top-level reviews collection for cross-querying
  try {
    await firestore.collection('reviews').doc('${jobId}_${user.uid}').set(
      reviewPayload,
      SetOptions(merge: true),
    );
  } catch (e) {
    debugPrint('Top-level review save note: $e');
  }

  // 4. Update the worker's average rating and review count
  final workerRef = firestore.collection('users').doc(actualWorkerId);
  try {
    final workerDoc = await workerRef.get();
    if (workerDoc.exists) {
      final currentRating = (workerDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
      final currentReviews = (workerDoc.data()?['reviews'] as num?)?.toInt() ?? 0;

      final newReviews = currentReviews + 1;
      final newRating = currentReviews > 0
          ? ((currentRating * currentReviews) + rating) / newReviews
          : rating.toDouble();

      final roundedRating = double.parse(newRating.toStringAsFixed(1));

      await workerRef.update({
        'rating': roundedRating,
        'reviews': newReviews,
        'ratingCount': newReviews,
        'ratingSum': FieldValue.increment(rating),
      });
    }
  } catch (e) {
    debugPrint('Worker doc rating update note: $e');
  }

  // 5. Update the job to mark it as reviewed and ensure status is completed
  await firestore.collection('jobs').doc(jobId).update({
    'reviewed': true,
    'reviewedAt': FieldValue.serverTimestamp(),
    'customerRating': rating,
    'status': 'completed',
    if (cleanReviewText.isNotEmpty) 'customerReview': cleanReviewText,
  });

  // 6. Track ratings given by customer
  try {
    await firestore.collection('users').doc(user.uid).update({
      'ratingsGivenCount': FieldValue.increment(1),
    });
  } catch (_) {}
}

/// Gets the list of reviews for a worker
Stream<QuerySnapshot> streamWorkerReviews(String workerId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(workerId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

/// Gets recent reviews for a worker (limited)
Future<List<Map<String, dynamic>>> getWorkerReviews(String workerId, {int limit = 10}) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(workerId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .get();
  
  return snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      ...data,
    };
  }).toList();
}

/// Keeps worker online while navigating within the app, and temporarily
/// marks worker offline only when the worker actually leaves the app
/// (paused/detached) or explicitly toggles off / logs out.
class WorkerPresenceService with WidgetsBindingObserver {
  static final WorkerPresenceService instance = WorkerPresenceService._();
  WorkerPresenceService._();

  bool _initialized = false;
  bool isOnline = false;
  Timer? _heartbeat;

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isOnline) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lastSeenAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
        setPresence(online: true).catchError((_) {});
      }
    });
  }

  void stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> setOnline(bool value) async {
    isOnline = value;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final loc = LocationService.instance.currentLocation;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': value,
        'lastSeenAt': FieldValue.serverTimestamp(),
        if (value) ...{
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'city': loc.city,
          'area': loc.area,
          'locationAddress': loc.fullAddress,
        },
      });
      await setPresence(online: value);
    } catch (_) {}

    if (value) {
      startHeartbeat();
    } else {
      stopHeartbeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Only manage online status if worker had toggled online
    if (!isOnline) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Worker left the app: mark offline in Firestore
      stopHeartbeat();
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': false,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
      setPresence(online: false).catchError((_) {});
    } else if (state == AppLifecycleState.resumed) {
      // Worker returned to the app: restore online status in Firestore
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
      setPresence(online: true).catchError((_) {});
      startHeartbeat();
    }
  }
}
