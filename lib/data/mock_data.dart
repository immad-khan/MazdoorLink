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

class WorkerSkill {
  final String titleEn;
  final String titleUr;
  final double price;

  const WorkerSkill({
    required this.titleEn,
    required this.titleUr,
    required this.price,
  });

  factory WorkerSkill.fromMap(Map<String, dynamic> map) {
    return WorkerSkill(
      titleEn: map['titleEn']?.toString() ?? '',
      titleUr: map['titleUr']?.toString() ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : (double.tryParse(map['price']?.toString() ?? '0') ?? 0.0),
    );
  }
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
    this.skills = const [],
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
  final List<WorkerSkill> skills;
  final List<String> skillsEn;
  final List<String> skillsUr;
  final String phone;
  final String email;
  final double priceValue;

  factory WorkerModel.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    final List<dynamic> skillsData = data['skills'] as List<dynamic>? ?? [];
    final List<WorkerSkill> skillsList = [];
    final List<String> skillsEn = [];
    final List<String> skillsUr = [];

    for (final s in skillsData) {
      if (s is Map) {
        final map = Map<String, dynamic>.from(s);
        final skill = WorkerSkill.fromMap(map);
        skillsList.add(skill);
        if (skill.titleEn.isNotEmpty) skillsEn.add(skill.titleEn);
        if (skill.titleUr.isNotEmpty) skillsUr.add(skill.titleUr);
      } else if (s is String && s.isNotEmpty) {
        skillsList.add(WorkerSkill(titleEn: s, titleUr: s, price: 0.0));
        skillsEn.add(s);
        skillsUr.add(s);
      }
    }

    final categoryNameEn = data['categoryNameEn']?.toString() ?? '';

    final double lowestPrice = skillsList.fold<double>(0, (prev, s) {
      final p = s.price;
      return prev == 0 ? p : (p < prev && p > 0 ? p : prev);
    });

    return WorkerModel(
      id: docId ?? data['uid']?.toString(),
      name: data['name']?.toString() ?? '',
      category: categoryNameEn,
      rating: (data['rating'] ?? 4.5).toDouble(),
      reviews: (data['reviews'] ?? 0) as int,
      distanceKm: (data['distanceKm'] ?? 2.0).toDouble(),
      price: lowestPrice > 0 ? 'Rs. ${lowestPrice.toStringAsFixed(0)}' : '',
      image: data['profileImage']?.toString() ?? data['profilePicUrl']?.toString() ?? '',
      skills: skillsList,
      skillsEn: skillsEn,
      skillsUr: skillsUr,
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      priceValue: lowestPrice,
    );
  }
}

const List<ServiceCategory> categories = [
  ServiceCategory(key: 'electrician', en: 'Electrician', ur: 'الیکٹریشن', icon: Icons.electrical_services),
  ServiceCategory(key: 'plumber', en: 'Plumber', ur: 'پلمبر', icon: Icons.plumbing),
];

