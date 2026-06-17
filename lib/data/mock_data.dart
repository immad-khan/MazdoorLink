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
  const WorkerModel({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.price,
    required this.image,
    required this.skillsEn,
    required this.skillsUr,
  });

  final String name;
  final String category;
  final double rating;
  final int reviews;
  final double distanceKm;
  final String price;
  final String image;
  final List<String> skillsEn;
  final List<String> skillsUr;
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

const List<WorkerModel> workers = [
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

const List<JobModel> jobs = [
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

