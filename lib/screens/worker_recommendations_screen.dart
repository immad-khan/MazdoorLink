import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../data/mock_data.dart';
import '../services/workers_service.dart';
import '../services/location_service.dart';
import 'recommendation_arguments.dart';
import 'issue_selection_screen.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        ProfileArguments;
class WorkerRecommendationsScreen extends StatefulWidget {
  const WorkerRecommendationsScreen({super.key});

  @override
  State<WorkerRecommendationsScreen> createState() =>
      _WorkerRecommendationsScreenState();
}

class _WorkerRecommendationsScreenState
    extends State<WorkerRecommendationsScreen> {
  List<IssueItem> selectedIssues = [];
  String categoryKey = 'electrician';
  String paymentMethod = 'Cash';
  double? customerLatitude;
  double? customerLongitude;
  late Future<List<WorkerModel>> _workersFuture;
  List<String> _favouriteIds = [];
  StreamSubscription? _favSub;

  @override
  void initState() {
    super.initState();
    _favSub = streamFavouriteWorkerIds().listen((ids) {
      if (mounted) setState(() => _favouriteIds = ids);
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is RecommendationArguments) {
      selectedIssues = rawArgs.selectedIssues;
      categoryKey = rawArgs.categoryKey;
      paymentMethod = rawArgs.paymentMethod;
      customerLatitude = rawArgs.customerLatitude;
      customerLongitude = rawArgs.customerLongitude;
    } else if (rawArgs is JobPostingArguments) {
      categoryKey = rawArgs.categoryKey;
      paymentMethod = rawArgs.paymentMethod;
      customerLatitude = rawArgs.customerLatitude;
      customerLongitude = rawArgs.customerLongitude;
      selectedIssues = [
        IssueItem(
          titleEn: rawArgs.descriptionEn,
          titleUr: rawArgs.descriptionUr,
          price: rawArgs.price,
          icon: Icons.build,
        ),
      ];
    }

    final skillTitles = selectedIssues.map((i) => i.titleEn).toList();
    final effectiveLat = customerLatitude ??
        (LocationService.instance.currentLocation.latitude != 0
            ? LocationService.instance.currentLocation.latitude
            : null);
    final effectiveLng = customerLongitude ??
        (LocationService.instance.currentLocation.longitude != 0
            ? LocationService.instance.currentLocation.longitude
            : null);

    _workersFuture = getWorkersByCategoryAndSkills(
      categoryKey,
      skillTitles,
      customerLatitude: effectiveLat,
      customerLongitude: effectiveLng,
      maxDistanceKm: 5.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Available Workers', 'دستیاب ورکرز'),
      child: FutureBuilder<List<WorkerModel>>(
        future: _workersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                bilingual(
                  context,
                  'Failed to load workers',
                  'ورکرز لوڈ کرنے میں ناکامی',
                ),
              ),
            );
          }
          final matchedWorkers = snapshot.data ?? [];
          if (matchedWorkers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF99F6E4), width: 2),
                      ),
                      child: const Icon(
                        Icons.radar,
                        size: 48,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      bilingual(
                        context,
                        'No workers found within 5 km',
                        '5 کلومیٹر کے دائرے میں کوئی ورکر نہیں ملا',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bilingual(
                        context,
                        'There are currently no active workers for this category within 5 km of your location. Try picking another area or check back in a few minutes.',
                        'اس زمرے کے لیے آپ کے مقام سے 5 کلومیٹر کے اندر کوئی فعال ورکر دستیاب نہیں ہے۔ براہ کرم مقام تبدیل کریں یا کچھ دیر بعد چیک کریں۔',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.location_on_outlined, size: 18),
                      label: Text(bilingual(context, 'Change Location', 'مقام تبدیل کریں')),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isUrdu
                                    ? '${matchedWorkers.length} ورکرز دستیاب ہیں'
                                    : '${matchedWorkers.length} workers available',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isUrdu ? '5 کلومیٹر دائرہ' : 'Within 5 km',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUrdu
                                ? 'قیمت دیکھنے کے لیے پیشکش کریں'
                                : 'Make an offer to negotiate price',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < matchedWorkers.length; i++) ...[
                () {
                  final worker = matchedWorkers[i];
                  double workerTotalPrice = 0;
                  if (selectedIssues.isNotEmpty) {
                    for (final issue in selectedIssues) {
                      double price = issue.price;
                      final matchedWorkerSkill = worker.skills.where((ws) {
                        final wsTitle = ws.titleEn.toLowerCase().trim();
                        final issueTitle = issue.titleEn.toLowerCase().trim();
                        return wsTitle == issueTitle ||
                            wsTitle.contains(issueTitle) ||
                            issueTitle.contains(wsTitle);
                      }).firstOrNull;

                      if (matchedWorkerSkill != null && matchedWorkerSkill.price > 0) {
                        price = matchedWorkerSkill.price;
                      }
                      workerTotalPrice += price;
                    }
                  } else {
                    workerTotalPrice = worker.priceValue;
                  }

                  final displayPrice = workerTotalPrice > 0
                      ? 'Rs. ${workerTotalPrice.toStringAsFixed(0)}'
                      : worker.price;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 320 + i * 100),
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 18),
                        child: child,
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedIssues.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: selectedIssues.map((issue) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDFA),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF99F6E4),
                                      ),
                                    ),
                                    child: Text(
                                      isUrdu ? '📌 ${issue.titleUr}' : '📌 ${issue.titleEn}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: worker.image.isNotEmpty
                                      ? Image.network(
                                          worker.image,
                                          width: 62,
                                          height: 62,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              CircleAvatar(
                                                radius: 31,
                                                child: Text(
                                                  worker.name.isNotEmpty
                                                      ? worker.name[0].toUpperCase()
                                                      : '?',
                                                ),
                                              ),
                                        )
                                      : CircleAvatar(
                                          radius: 31,
                                          child: Text(
                                            worker.name.isNotEmpty
                                                ? worker.name[0].toUpperCase()
                                                : '?',
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        worker.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.darkerText,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            worker.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFFBBF7D0),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.near_me,
                                                  size: 10,
                                                  color: Color(0xFF16A34A),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  isUrdu
                                                      ? '${worker.distanceKm.toStringAsFixed(1)} کلومیٹر دور'
                                                      : '${worker.distanceKm.toStringAsFixed(1)} km away',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (displayPrice.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              displayPrice,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0D9488),
                                              ),
                                            ),
                                            if (selectedIssues.length > 1) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                isUrdu
                                                    ? '(${selectedIssues.length} خدمات)'
                                                    : '(${selectedIssues.length} services)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _favouriteIds.contains(worker.id)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _favouriteIds.contains(worker.id)
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    final wid = worker.id;
                                    if (wid == null) return;
                                    if (_favouriteIds.contains(wid)) {
                                      removeFavouriteWorker(wid);
                                    } else {
                                      addFavouriteWorker(wid);
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (worker.skillsEn.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: (isUrdu ? worker.skillsUr : worker.skillsEn).map((s) {
                                  final isSelected = selectedIssues.any((issue) {
                                    final issueTitle = (isUrdu ? issue.titleUr : issue.titleEn).toLowerCase().trim();
                                    final sTitle = s.toLowerCase().trim();
                                    return issueTitle == sTitle || issueTitle.contains(sTitle) || sTitle.contains(issueTitle);
                                  });

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF5EEAD4) : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(Icons.check, size: 12, color: Color(0xFF0F766E)),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          s,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            color: isSelected ? const Color(0xFF0F766E) : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  final combinedEn = selectedIssues.isNotEmpty
                                      ? selectedIssues.map((e) => e.titleEn).join(', ')
                                      : '';
                                  final combinedUr = selectedIssues.isNotEmpty
                                      ? selectedIssues.map((e) => e.titleUr).join('، ')
                                      : '';
                                  final issueIndex = i % (selectedIssues.isNotEmpty ? selectedIssues.length : 1);
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.workerProfile,
                                    arguments: ProfileArguments(
                                      worker: worker,
                                      selectedIssues: selectedIssues,
                                      job: JobPostingArguments(
                                        descriptionEn: combinedEn.isNotEmpty
                                            ? combinedEn
                                            : (selectedIssues.isNotEmpty
                                                ? selectedIssues[issueIndex].titleEn
                                                : ''),
                                        descriptionUr: combinedUr.isNotEmpty
                                            ? combinedUr
                                            : (selectedIssues.isNotEmpty
                                                ? selectedIssues[issueIndex].titleUr
                                                : ''),
                                        price: workerTotalPrice,
                                        categoryKey: categoryKey,
                                        paymentMethod: paymentMethod,
                                        customerLatitude: customerLatitude,
                                        customerLongitude: customerLongitude,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_outline, size: 16),
                                label: Text(
                                  bilingual(
                                    context,
                                    'View Profile',
                                    'پروفائل دیکھیں',
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }(),
              ],
            ],
          );
        },
      ),
    );
  }
}