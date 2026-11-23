import 'package:flutter/material.dart';

class ServiceCategory {
  const ServiceCategory({
    required this.key,
    required this.en,
    required this.ur,
    required this.icon,
  });

  final String key;
  final String en;
  final String ur;
  final IconData icon;
}

const List<ServiceCategory> categories = [
  ServiceCategory(
    key: 'electrician',
    en: 'Electrician',
    ur: 'الیکٹریشن',
    icon: Icons.electrical_services,
  ),
  ServiceCategory(
    key: 'plumber',
    en: 'Plumber',
    ur: 'پلمبر',
    icon: Icons.plumbing,
  ),
];

ServiceCategory? serviceCategoryFor(Object? value) {
  final key = value?.toString().trim().toLowerCase();
  for (final category in categories) {
    if (key == category.key ||
        key == category.en.toLowerCase() ||
        key == category.ur) {
      return category;
    }
  }
  return null;
}

bool isBlockedAccount(Map<String, dynamic> data) =>
    ['banned', 'suspended'].contains(data['status']);

bool isApprovedWorker(Map<String, dynamic> data) {
  final roles = data['roles'];
  final hasWorkerRole =
      data['role'] == 'worker' || (roles is List && roles.contains('worker'));
  return hasWorkerRole &&
      !isBlockedAccount(data) &&
      (data['workerStatus'] ?? data['status']) == 'approved';
}

// A worker can receive requests while offline. Workers may pause visits without
// affecting their presence or existing bookings.
bool canReceiveVisits(Map<String, dynamic> data) =>
    isApprovedWorker(data) && data['acceptsVisits'] != false;

class WorkerModel {
  const WorkerModel({
    this.id,
    required this.name,
    required this.category,
    this.categoryKey,
    this.rating = 0,
    this.reviews = 0,
    this.price = '',
    this.image = '',
    this.phone = '',
    this.area = '',
    this.isApproved = false,
    this.isOnline = false,
    this.acceptsVisits = true,
  });

  final String? id;
  final String name;
  final String category;
  final String? categoryKey;
  final double rating;
  final int reviews;

  /// Populated by legacy repair tracking, never by the directory.
  final String price;
  final String image;
  final String phone;
  final String area;
  final bool isApproved;
  final bool isOnline;
  final bool acceptsVisits;

  bool get canRequestVisit =>
      isApproved && acceptsVisits && id?.isNotEmpty == true;

  String categoryLabel(bool isUrdu) {
    final trade = serviceCategoryFor(categoryKey ?? category);
    return trade == null ? category : (isUrdu ? trade.ur : trade.en);
  }

  factory WorkerModel.fromFirestore(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final trade =
        serviceCategoryFor(data['category']) ??
        serviceCategoryFor(data['categoryKey']) ??
        serviceCategoryFor(data['categoryNameEn']);

    final rating = data['rating'];
    final reviews = data['ratingCount'] ?? data['reviews'];

    return WorkerModel(
      id: docId ?? data['uid']?.toString(),
      name: data['name']?.toString() ?? '',
      categoryKey: trade?.key,
      category: trade?.en ?? data['categoryNameEn']?.toString() ?? '',
      rating: rating is num ? rating.toDouble() : 0,
      reviews: reviews is num ? reviews.toInt() : 0,
      image:
          data['profileImage']?.toString() ??
          data['profilePicUrl']?.toString() ??
          '',
      phone: data['phone']?.toString() ?? '',
      area: data['area']?.toString() ?? data['city']?.toString() ?? '',
      isApproved: isApprovedWorker(data),
      isOnline: data['isOnline'] == true,
      acceptsVisits: data['acceptsVisits'] != false,
    );
  }
}

List<WorkerModel> directoryWorkers(
  Iterable<WorkerModel> workers, {
  required String? viewerId,
  String? categoryKey,
}) {
  final listed = workers
      .where(
        (worker) =>
            worker.isApproved &&
            worker.id != viewerId &&
            (categoryKey == null || worker.categoryKey == categoryKey),
      )
      .toList();
  int priority(WorkerModel worker) =>
      (worker.acceptsVisits ? 2 : 0) + (worker.isOnline ? 1 : 0);
  return listed..sort((a, b) {
    final availability = priority(b).compareTo(priority(a));
    if (availability != 0) return availability;
    final rating = b.rating.compareTo(a.rating);
    return rating == 0 ? a.name.compareTo(b.name) : rating;
  });
}
