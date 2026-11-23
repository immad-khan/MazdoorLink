enum VisitStatus {
  requested,
  accepted,
  declined,
  cancelled,
  completed;

  /// Keep these transitions in sync with the visit_requests Firestore rules.
  List<VisitStatus> nextStatuses({required bool asWorker}) => switch (this) {
    requested => asWorker ? [accepted, declined] : [cancelled],
    accepted => asWorker ? [completed, cancelled] : [cancelled],
    _ => const [],
  };
}

class VisitDraft {
  static const int maxAddressLength = 300;
  static const int maxNoteLength = 500;
  static const int schedulingDays = 30;

  VisitDraft({
    required String address,
    required this.preferredAt,
    String note = '',
  }) : address = address.trim(),
       note = note.trim();

  final String address;
  final DateTime preferredAt;
  final String note;

  static bool validAddress(String address) =>
      address.trim().isNotEmpty && address.trim().length <= maxAddressLength;

  static bool validTime(DateTime preferredAt, DateTime now) =>
      preferredAt.isAfter(now) &&
      preferredAt.isBefore(now.add(const Duration(days: schedulingDays + 1)));

  bool isValidAt(DateTime now) =>
      validAddress(address) &&
      note.length <= maxNoteLength &&
      validTime(preferredAt, now);
}

class VisitRequest {
  const VisitRequest({
    required this.id,
    required this.customerName,
    required this.workerName,
    required this.address,
    required this.preferredAt,
    required this.note,
    required this.status,
  });

  final String id;
  final String customerName;
  final String workerName;
  final String address;
  final DateTime preferredAt;
  final String note;
  final VisitStatus status;
}
