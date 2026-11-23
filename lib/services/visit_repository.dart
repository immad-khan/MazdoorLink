import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/mock_data.dart';
import '../data/visit_request.dart';

enum VisitFailure {
  signIn,
  workerUnavailable,
  invalidDetails,
  statusChanged,
  timePassed,
}

class VisitException implements Exception {
  const VisitException(this.reason);

  final VisitFailure reason;
}

abstract interface class VisitRepository {
  Stream<List<VisitRequest>> watchMyVisits({required bool asWorker});

  Future<void> requestVisit({
    required String workerId,
    required VisitDraft draft,
  });

  Future<void> changeStatus(VisitRequest visit, VisitStatus next);
}

class FirestoreVisitRepository implements VisitRepository {
  const FirestoreVisitRepository();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _visits =>
      _db.collection('visit_requests');

  @override
  Stream<List<VisitRequest>> watchMyVisits({required bool asWorker}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _visits
        .where(asWorker ? 'workerId' : 'customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return VisitRequest(
              id: doc.id,
              customerName: data['customerName'] as String,
              workerName: data['workerName'] as String,
              address: data['address'] as String,
              preferredAt: (data['preferredAt'] as Timestamp).toDate(),
              note: data['note'] as String,
              status: VisitStatus.values.byName(data['status'] as String),
            );
          }).toList(),
        );
  }

  @override
  Future<void> requestVisit({
    required String workerId,
    required VisitDraft draft,
  }) async {
    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId == null) throw const VisitException(VisitFailure.signIn);
    if (workerId.isEmpty || workerId == customerId) {
      throw const VisitException(VisitFailure.workerUnavailable);
    }
    if (!draft.isValidAt(DateTime.now())) {
      throw const VisitException(VisitFailure.invalidDetails);
    }

    final users = _db.collection('users');
    final visitRef = _visits.doc();
    await _db.runTransaction((transaction) async {
      final customer = (await transaction.get(users.doc(customerId))).data();
      final worker = (await transaction.get(users.doc(workerId))).data();
      if (customer == null || isBlockedAccount(customer)) {
        throw const VisitException(VisitFailure.signIn);
      }
      if (worker == null || !canReceiveVisits(worker)) {
        throw const VisitException(VisitFailure.workerUnavailable);
      }

      transaction.set(visitRef, {
        'customerId': customerId,
        'customerName': customer['name'] as String? ?? '',
        'workerId': workerId,
        'workerName': worker['name'] as String? ?? '',
        'status': VisitStatus.requested.name,
        'address': draft.address,
        'preferredAt': Timestamp.fromDate(draft.preferredAt),
        'note': draft.note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> changeStatus(VisitRequest visit, VisitStatus next) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw const VisitException(VisitFailure.signIn);

    final ref = _visits.doc(visit.id);
    await _db.runTransaction((transaction) async {
      final data = (await transaction.get(ref)).data();
      final asWorker = data?['workerId'] == uid;
      final asCustomer = data?['customerId'] == uid;
      if ((!asWorker && !asCustomer) ||
          data?['status'] != visit.status.name ||
          !visit.status.nextStatuses(asWorker: asWorker).contains(next)) {
        throw const VisitException(VisitFailure.statusChanged);
      }
      if (next == VisitStatus.accepted &&
          !(data!['preferredAt'] as Timestamp).toDate().isAfter(
            DateTime.now(),
          )) {
        throw const VisitException(VisitFailure.timePassed);
      }
      transaction.update(ref, {
        'status': next.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
