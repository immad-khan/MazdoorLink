import 'package:flutter_test/flutter_test.dart';
import 'package:service_frontend/data/mock_data.dart';
import 'package:service_frontend/data/visit_request.dart';

void main() {
  final now = DateTime.utc(2026, 11, 23, 9);

  test(
    'a visit draft trims the address and note and requires a future time',
    () {
      final draft = VisitDraft(
        address: '  23 Example Street  ',
        note: '  Leaking sink ',
        preferredAt: now.add(const Duration(hours: 1)),
      );
      expect(draft.address, '23 Example Street');
      expect(draft.note, 'Leaking sink');
      expect(draft.isValidAt(now), isTrue);
      expect(draft.isValidAt(draft.preferredAt), isFalse);
      expect(VisitDraft.validAddress('  '), isFalse);
      expect(
        VisitDraft.validTime(now.add(const Duration(days: 31)), now),
        isFalse,
      );
      expect(
        VisitDraft(
          address: draft.address,
          preferredAt: draft.preferredAt,
          note: List.filled(501, 'x').join(),
        ).isValidAt(now),
        isFalse,
      );
    },
  );

  test('only the worker can confirm, decline or complete a visit', () {
    expect(VisitStatus.requested.nextStatuses(asWorker: true), [
      VisitStatus.accepted,
      VisitStatus.declined,
    ]);
    expect(VisitStatus.requested.nextStatuses(asWorker: false), [
      VisitStatus.cancelled,
    ]);
    expect(VisitStatus.accepted.nextStatuses(asWorker: true), [
      VisitStatus.completed,
      VisitStatus.cancelled,
    ]);
    expect(VisitStatus.accepted.nextStatuses(asWorker: false), [
      VisitStatus.cancelled,
    ]);
    for (final status in [
      VisitStatus.declined,
      VisitStatus.cancelled,
      VisitStatus.completed,
    ]) {
      expect(status.nextStatuses(asWorker: true), isEmpty);
      expect(status.nextStatuses(asWorker: false), isEmpty);
    }
  });

  test(
    'directory lists approved workers in the trade, including offline and paused profiles',
    () {
      const workerProfile = {
        'role': 'worker',
        'status': 'approved',
        'category': 'plumber',
      };
      WorkerModel worker(String id, Map<String, dynamic> fields) =>
          WorkerModel.fromFirestore({
            ...workerProfile,
            'name': id,
            ...fields,
          }, docId: id);

      final results = directoryWorkers(
        [
          worker('paused', {'acceptsVisits': false, 'isOnline': true}),
          worker('pending', {'status': 'pending', 'isOnline': true}),
          worker('other-trade', {'category': 'electrician'}),
          worker('me', {}),
          worker('offline', {
            'isOnline': false,
            'skills': [
              {'titleEn': 'Old repair', 'price': 800},
            ],
          }),
          worker('dual-role', {
            'role': 'customer',
            'roles': ['worker', 'customer'],
            'status': 'active',
            'workerStatus': 'approved',
            'isOnline': true,
          }),
          worker('legacy', {'category': null, 'categoryNameEn': ' Plumber '}),
          worker('suspended', {
            'workerStatus': 'approved',
            'status': 'suspended',
          }),
        ],
        viewerId: 'me',
        categoryKey: 'plumber',
      );

      expect(results.map((worker) => worker.id), [
        'dual-role',
        'legacy',
        'offline',
        'paused',
      ]);
      expect(
        results.firstWhere((worker) => worker.id == 'offline').canRequestVisit,
        isTrue,
      );
      expect(
        results.firstWhere((worker) => worker.id == 'offline').price,
        isEmpty,
      );
      expect(results.last.canRequestVisit, isFalse);
    },
  );
}
