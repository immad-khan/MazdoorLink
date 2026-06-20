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

class WorkerModel {
  WorkerModel({
    this.id,
    required this.name,
    required this.category,
    this.rating = 0,
    this.reviews = 0,
    this.distanceKm = 0,
    this.price = '',
    this.image = '',
    this.skillsEn = const [],
    this.skillsUr = const [],
    this.phone = '',
    this.email = '',
    this.priceValue = 0,
  });

  final String? id;
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final double distanceKm;
  final String price;
  final String image;
  final List<String> skillsEn;
  final List<String> skillsUr;
  final String phone;
  final String email;
  final double priceValue;

  factory WorkerModel.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    final List<dynamic> skillsData = data['skills'] as List<dynamic>? ?? [];
    final List<String> skillsEn = skillsData.map((s) => (s as Map)['titleEn']?.toString() ?? '').toList();
    final List<String> skillsUr = skillsData.map((s) => (s as Map)['titleUr']?.toString() ?? '').toList();

    final categoryNameEn = data['categoryNameEn']?.toString() ?? '';

    final double lowestPrice = skillsData.fold<double>(0, (prev, s) {
      final p = ((s as Map)['price'] ?? 0).toDouble();
      return prev == 0 ? p : (p < prev ? p : prev);
    });

    return WorkerModel(
      id: docId ?? data['uid']?.toString(),
      name: data['name']?.toString() ?? '',
      category: categoryNameEn,
      rating: (data['rating'] ?? 4.5).toDouble(),
      reviews: (data['reviews'] ?? 0) as int,
      distanceKm: (data['distanceKm'] ?? 2.0).toDouble(),
      price: lowestPrice > 0 ? 'Rs. ${lowestPrice.toStringAsFixed(0)}' : '',
      image: data['profileImage']?.toString() ?? '',
      skillsEn: skillsEn,
      skillsUr: skillsUr,
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      priceValue: lowestPrice,
    );
  }
}

class JobModel {
  const JobModel({
    required this.titleEn,
    required this.titleUr,
    required this.status,
    required this.price,
    required this.distance,
    required this.time,
  });

  final String titleEn;
  final String titleUr;
  final String status;
  final String price;
  final String distance;
  final String time;
}

const List<ServiceCategory> categories = [
  ServiceCategory(key: 'electrician', en: 'Electrician', ur: 'الیکٹریشن', icon: Icons.electrical_services),
  ServiceCategory(key: 'plumber', en: 'Plumber', ur: 'پلمبر', icon: Icons.plumbing),
];

final List<WorkerModel> workers = [
  WorkerModel(
    name: 'Muhammad Ali',
    category: 'Plumber',
    rating: 4.8,
    reviews: 124,
    distanceKm: 2.5,
    price: 'Rs. 800 - 1,200',
    image: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
    skillsEn: ['Pipe Leakage', 'Motor Installation', 'Geyser Repair'],
    skillsUr: ['پائپ لیکیج', 'موٹر انسٹالیشن', 'گیزر مرمت'],
  ),
  WorkerModel(
    name: 'Usman Tariq',
    category: 'Electrician',
    rating: 4.9,
    reviews: 210,
    distanceKm: 1.8,
    price: 'Rs. 1,100 - 1,700',
    image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600',
    skillsEn: ['Wiring', 'Fans', 'UPS Setup'],
    skillsUr: ['وائرنگ', 'پنکھے', 'یو پی ایس سیٹ اپ'],
  ),
  WorkerModel(
    name: 'Zahid Khan',
    category: 'Carpenter',
    rating: 4.5,
    reviews: 89,
    distanceKm: 3.2,
    price: 'Rs. 900 - 1,500',
    image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600',
    skillsEn: ['Wood Repair', 'Shelves', 'Doors'],
    skillsUr: ['لکڑی مرمت', 'شیلف', 'دروازے'],
  ),
];

final List<JobModel> jobs = [
  JobModel(
    titleEn: 'Fix leaking kitchen sink',
    titleUr: 'کچن سنک لیکیج ٹھیک کریں',
    status: 'pending',
    price: 'Rs. 1,000',
    distance: '3.2 km',
    time: 'Today, 2:00 PM',
  ),
  JobModel(
    titleEn: 'Install 2 ceiling fans',
    titleUr: '2 سیلنگ فین لگائیں',
    status: 'completed',
    price: 'Rs. 1,500',
    distance: '1.5 km',
    time: 'Yesterday',
  ),
];

