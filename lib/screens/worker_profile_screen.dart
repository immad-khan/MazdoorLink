import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../data/mock_data.dart';
import '../services/workers_service.dart';
import '../services/location_service.dart';
import '../services/smtp_service.dart';
import '../services/sms_service.dart';
import 'issue_selection_screen.dart';
import 'worker_tracking_screen.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        ProfileArguments,
        TrackingArguments,
        LocationPickArguments,
        ConversationArguments;
class _FlowDisplayedSkill {
  final String titleEn;
  final String titleUr;
  final double price;

  const _FlowDisplayedSkill({
    required this.titleEn,
    required this.titleUr,
    required this.price,
  });
}

class FlowWorkerProfileScreen extends StatefulWidget {
  const FlowWorkerProfileScreen({super.key});

  @override
  State<FlowWorkerProfileScreen> createState() =>
      _FlowWorkerProfileScreenState();
}

class _FlowWorkerProfileScreenState extends State<FlowWorkerProfileScreen> {
  final TextEditingController _offerController = TextEditingController();
  List<String> _favouriteIds = [];
  StreamSubscription? _favSub;
  int _visibilityMinutes = 10;
  bool _initializedOffer = false;

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
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as ProfileArguments?;
    final worker = args?.worker;
    final selectedIssues = args?.selectedIssues ?? const [];
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    if (worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(bilingual(context, 'Worker not found', 'ورکر نہیں ملا')),
        ),
      );
    }

    final List<_FlowDisplayedSkill> displayedSkills = [];

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

        displayedSkills.add(
          _FlowDisplayedSkill(
            titleEn: issue.titleEn,
            titleUr: issue.titleUr,
            price: price,
          ),
        );
      }
    } else if (worker.skills.isNotEmpty) {
      for (final ws in worker.skills) {
        displayedSkills.add(
          _FlowDisplayedSkill(
            titleEn: ws.titleEn,
            titleUr: ws.titleUr.isNotEmpty ? ws.titleUr : ws.titleEn,
            price: ws.price,
          ),
        );
      }
    } else {
      for (int i = 0; i < worker.skillsEn.length; i++) {
        final en = worker.skillsEn[i];
        final ur = i < worker.skillsUr.length ? worker.skillsUr[i] : en;
        displayedSkills.add(
          _FlowDisplayedSkill(
            titleEn: en,
            titleUr: ur,
            price: worker.priceValue > 0 ? worker.priceValue : 300,
          ),
        );
      }
    }

    final double grandTotal = displayedSkills.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );

    if (!_initializedOffer && grandTotal > 0) {
      _offerController.text = grandTotal.toStringAsFixed(0);
      _initializedOffer = true;
    }

    return MzScaffold(
      showBottomNav: false,
      background: Colors.white,
      child: Stack(
        children: [
          ListView(
            children: [
              Stack(
                children: [
                  worker.image.isNotEmpty
                      ? Image.network(
                          worker.image,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 260,
                          width: double.infinity,
                          color: const Color(0xFF0D9488),
                          child: Center(
                            child: Text(
                              worker.name.isNotEmpty
                                  ? worker.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 80,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  Container(
                    height: 260,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 14,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    right: 14,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: Icon(
                          _favouriteIds.contains(worker.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final wid = worker.id;
                          if (wid == null) return;
                          if (_favouriteIds.contains(wid)) {
                            removeFavouriteWorker(wid);
                          } else {
                            addFavouriteWorker(wid);
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                worker.rating > 0
                                    ? worker.rating.toStringAsFixed(1)
                                    : (isUrdu ? 'نیا' : 'New'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (worker.reviews > 0)
                                Text(
                                  ' (${worker.reviews})',
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
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${worker.category} • ${worker.distanceKm} km ${bilingual(context, 'away', 'دور')}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: const [
                        _Tag('CNIC Verified', Colors.green),
                        _Tag('Police Cleared', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _offerController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            'PKR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                        hintText: isUrdu ? 'مثلاً 500' : 'E.g., 500',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF0D9488),
                            width: 2,
                          ),
                        ),
                        labelText: isUrdu
                            ? 'اپنی پیشکش درج کریں (Rs)'
                            : 'Enter Your Offer (Rs)',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bilingual(
                              context,
                              'Offer visible to worker for:',
                              'ورکر کو پیشکش نظر آئے گی:',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _DurationChip(
                                  label: '1 min',
                                  minutes: 1,
                                  selected: _visibilityMinutes == 1,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 1),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label: '5 min',
                                  minutes: 5,
                                  selected: _visibilityMinutes == 5,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 5),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label: '10 min',
                                  minutes: 10,
                                  selected: _visibilityMinutes == 10,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 10),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label: '30 min',
                                  minutes: 30,
                                  selected: _visibilityMinutes == 30,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 30),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label:
                                      '1 ${bilingual(context, 'hr', 'گھنٹہ')}',
                                  minutes: 60,
                                  selected: _visibilityMinutes == 60,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 60),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label:
                                      '6 ${bilingual(context, 'hr', 'گھنٹے')}',
                                  minutes: 360,
                                  selected: _visibilityMinutes == 360,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 360),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label: '1 ${bilingual(context, 'day', 'دن')}',
                                  minutes: 1440,
                                  selected: _visibilityMinutes == 1440,
                                  onTap: () =>
                                      setState(() => _visibilityMinutes = 1440),
                                ),
                                const SizedBox(width: 6),
                                _DurationChip(
                                  label:
                                      '1 ${bilingual(context, 'week', 'ہفتہ')}',
                                  minutes: 10080,
                                  selected: _visibilityMinutes == 10080,
                                  onTap: () => setState(
                                    () => _visibilityMinutes = 10080,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bilingual(context, 'Skills', 'مہارتیں'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAllSkillsBottomSheet(
                            context,
                            worker,
                            isUrdu,
                            selectedIssues,
                          ),
                          icon: const Icon(
                            Icons.format_list_bulleted,
                            size: 16,
                            color: Color(0xFF0D9488),
                          ),
                          label: Text(
                            bilingual(
                              context,
                              'View All Skills',
                              'تمام مہارتیں دیکھیں',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF0D9488),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final skill in displayedSkills)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isUrdu ? skill.titleUr : skill.titleEn,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Text(
                              'Rs. ${skill.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (displayedSkills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 20,
                                  color: Color(0xFF0D9488),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  bilingual(
                                    context,
                                    'Total Bill / Grand Total:',
                                    'کل بل / گرینڈ ٹوٹل:',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rs. ${grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      bilingual(context, 'Recent Reviews', 'حالیہ جائزے'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: streamWorkerReviews(worker.id ?? ''),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Card(
                            elevation: 0,
                            color: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      bilingual(
                                        context,
                                        'No reviews yet for this worker.',
                                        'اس کاریگر کے لیے ابھی کوئی جائزہ نہیں۔',
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: docs.take(5).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final customerName =
                                data['customerName']?.toString() ?? 'Customer';
                            final r = (data['rating'] as num?)?.toInt() ?? 5;
                            final reviewText = data['review']?.toString() ?? '';
                            final jobTitle = data['jobTitle']?.toString() ?? '';
                            final ts = data['createdAt'] as Timestamp?;
                            final dateStr = ts != null
                                ? DateFormat('d MMM').format(ts.toDate())
                                : '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              color: const Color(0xFFF9FAFB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        r,
                                        (i) => const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                    if (dateStr.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (jobTitle.isNotEmpty)
                                      Text(
                                        jobTitle,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    if (reviewText.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        reviewText,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: () async {
                    final wid = worker.id;
                    if (wid == null) return;
                    final existingId = await findExistingConversation(wid);
                    if (!context.mounted) return;
                    final args = ConversationArguments(
                      conversationId: existingId ?? '',
                      otherName: worker.name,
                      otherImage: worker.image,
                    );
                    if (existingId != null) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.sharedConversation,
                        arguments: args,
                      );
                    } else {
                      final newId = await createConversation(
                        otherUserId: wid,
                        otherUserName: worker.name,
                        otherUserImage: worker.image,
                      );
                      if (context.mounted) {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.sharedConversation,
                          arguments: ConversationArguments(
                            conversationId: newId,
                            otherName: worker.name,
                            otherImage: worker.image,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null && context.mounted) {
                          final priceText = _offerController.text.trim();
                          final offerPrice = double.tryParse(priceText);
                          if (offerPrice == null || offerPrice <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  bilingual(
                                    context,
                                    'Please enter a valid amount to make an offer.',
                                    'براہ کرم پیشکش کرنے کے لئے ایک درست رقم درج کریں۔',
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }
                          final jobDesc =
                              args?.job ??
                              JobPostingArguments(
                                descriptionEn: 'Scheduled Service',
                                descriptionUr: 'شیڈولڈ سروس',
                                price: offerPrice,
                                categoryKey: worker.category.toLowerCase(),
                              );
                          double? latitude = jobDesc.customerLatitude;
                          double? longitude = jobDesc.customerLongitude;
                          if (latitude == null || longitude == null) {
                            final loc = await Navigator.pushNamed(
                              context,
                              AppRoutes.confirmLocation,
                              arguments: LocationPickArguments(),
                            );
                            if (loc is Map &&
                                loc['lat'] != null &&
                                loc['lng'] != null) {
                              latitude = (loc['lat'] as num).toDouble();
                              longitude = (loc['lng'] as num).toDouble();
                            }
                            if (!context.mounted) return;
                          }
                          final categoryKeyToUse =
                              jobDesc.categoryKey.isNotEmpty
                              ? jobDesc.categoryKey.toLowerCase()
                              : worker.category.toLowerCase();
                          final customerId =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (customerId != null && customerId.isNotEmpty) {
                            final hasActive =
                                await customerHasActiveJobInCategory(
                                  customerId,
                                  categoryKeyToUse,
                                );
                            if (hasActive && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    bilingual(
                                      context,
                                      'You can book only one ${worker.category} at a time. Please complete your previous ${worker.category} job first.',
                                      'آپ صرف ایک ${worker.category} ایک وقت میں بک کر سکتے ہیں۔ براہ کرم اپنا پچھلا ${worker.category} کام مکمل کریں۔',
                                    ),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                              return;
                            }
                          }
                          try {
                            final jobId = await createJobOffer(
                              workerId: worker.id,
                              workerName: worker.name,
                              descriptionEn: jobDesc.descriptionEn,
                              descriptionUr: jobDesc.descriptionUr,
                              price: offerPrice,
                              categoryKey: categoryKeyToUse,
                              paymentMethod: jobDesc.paymentMethod,
                              customerLatitude: latitude,
                              customerLongitude: longitude,
                              visibilityDurationMinutes: _visibilityMinutes,
                            );
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.tracking,
                                arguments: TrackingArguments(
                                  worker: worker,
                                  job: jobDesc,
                                  jobId: jobId,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    bilingual(
                                      context,
                                      e.toString().replaceAll('Exception: ', ''),
                                      'ورکر آپ کے مقام سے 5 کلومیٹر کی حدود سے باہر ہے۔',
                                    ),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(bilingual(context, 'Schedule', 'شیڈول کریں')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final priceText = _offerController.text.trim();
                      final offerPrice = double.tryParse(priceText);
                      if (offerPrice == null || offerPrice <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bilingual(
                                context,
                                'Please enter a valid amount to make an offer.',
                                'براہ کرم پیشکش کرنے کے لئے ایک درست رقم درج کریں۔',
                              ),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      final jobDesc =
                          args?.job ??
                          JobPostingArguments(
                            descriptionEn: 'Service',
                            descriptionUr: 'سروس',
                            price: offerPrice,
                            categoryKey: worker.category.toLowerCase(),
                          );
                      double? latitude = jobDesc.customerLatitude;
                      double? longitude = jobDesc.customerLongitude;
                      if (latitude == null || longitude == null) {
                        final loc = await Navigator.pushNamed(
                          context,
                          AppRoutes.confirmLocation,
                          arguments: LocationPickArguments(),
                        );
                        if (loc is Map &&
                            loc['lat'] != null &&
                            loc['lng'] != null) {
                          latitude = (loc['lat'] as num).toDouble();
                          longitude = (loc['lng'] as num).toDouble();
                        }
                        if (!context.mounted) return;
                      }
                      final categoryKeyToUse = jobDesc.categoryKey.isNotEmpty
                          ? jobDesc.categoryKey.toLowerCase()
                          : worker.category.toLowerCase();
                      final customerId = FirebaseAuth.instance.currentUser?.uid;
                      if (customerId != null && customerId.isNotEmpty) {
                        final hasActive = await customerHasActiveJobInCategory(
                          customerId,
                          categoryKeyToUse,
                        );
                        if (hasActive && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bilingual(
                                  context,
                                  'You can book only one ${worker.category} at a time. Please complete your previous ${worker.category} job first.',
                                  'آپ صرف ایک ${worker.category} ایک وقت میں بک کر سکتے ہیں۔ براہ کرم اپنا پچھلا ${worker.category} کام مکمل کریں۔',
                                ),
                              ),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                          return;
                        }
                      }
                      try {
                        final jobId = await createJobOffer(
                          workerId: worker.id,
                          workerName: worker.name,
                          descriptionEn: jobDesc.descriptionEn,
                          descriptionUr: jobDesc.descriptionUr,
                          price: offerPrice,
                          categoryKey: categoryKeyToUse,
                          paymentMethod: jobDesc.paymentMethod,
                          customerLatitude: latitude,
                          customerLongitude: longitude,
                          visibilityDurationMinutes: _visibilityMinutes,
                        );
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.tracking,
                            arguments: TrackingArguments(
                              worker: worker,
                              job: jobDesc,
                              jobId: jobId,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bilingual(
                                  context,
                                  e.toString().replaceAll('Exception: ', ''),
                                  'ورکر آپ کے مقام سے 5 کلومیٹر کی حدود سے باہر ہے۔',
                                ),
                              ),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                    child: Text(
                      bilingual(context, 'Hire Now', 'ابھی ہائر کریں'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSkillsBottomSheet(
    BuildContext context,
    WorkerModel worker,
    bool isUrdu,
    List<IssueItem> selectedIssues,
  ) {
    final allSkills = <_FlowDisplayedSkill>[];
    final seenTitles = <String>{};

    for (final ws in worker.skills) {
      if (seenTitles.add(ws.titleEn.toLowerCase().trim())) {
        allSkills.add(
          _FlowDisplayedSkill(
            titleEn: ws.titleEn,
            titleUr: ws.titleUr.isNotEmpty ? ws.titleUr : ws.titleEn,
            price: ws.price,
          ),
        );
      }
    }

    if (allSkills.isEmpty) {
      for (int i = 0; i < worker.skillsEn.length; i++) {
        final en = worker.skillsEn[i];
        final ur = i < worker.skillsUr.length ? worker.skillsUr[i] : en;
        if (seenTitles.add(en.toLowerCase().trim())) {
          allSkills.add(
            _FlowDisplayedSkill(
              titleEn: en,
              titleUr: ur,
              price: worker.priceValue > 0 ? worker.priceValue : 300,
            ),
          );
        }
      }
    }

    final categoryKey = worker.category.toLowerCase();
    final List<_FlowDisplayedSkill> defaultCategorySkills =
        (categoryKey.contains('plumb'))
        ? const [
            _FlowDisplayedSkill(
              titleEn: 'Water Tap Leakage Fix',
              titleUr: 'نلکے سے پانی کا رساو ٹھیک کرنا',
              price: 300,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Flush Tank Repair',
              titleUr: 'فلش ٹینک کی مرمت',
              price: 600,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Sink / Wash Basin Installation',
              titleUr: 'واش بیسن لگانا',
              price: 1200,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Motor Pump Installation',
              titleUr: 'پانی کی موٹر لگانا',
              price: 2500,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Geyser Repair & Service',
              titleUr: 'گیزر کی سروس اور مرمت',
              price: 1800,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Pipeline Leakage Repair',
              titleUr: 'پائپ لائن لیکیج مرمت',
              price: 1000,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Shower Fitting Replacement',
              titleUr: 'شاور فٹنگ تبدیل کرنا',
              price: 700,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Drain Blockage Cleaning',
              titleUr: 'بند نالی کی صفائی',
              price: 800,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Full Washroom Setup',
              titleUr: 'واش روم کا مکمل سیٹ اپ',
              price: 12000,
            ),
          ]
        : (categoryKey.contains('elect'))
        ? const [
            _FlowDisplayedSkill(
              titleEn: 'Broken Switch Repair',
              titleUr: 'خراب سوئچ کی مرمت',
              price: 300,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Short Circuit Fix',
              titleUr: 'شارٹ سرکٹ ٹھیک کرنا',
              price: 400,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Ceiling Fan Installation',
              titleUr: 'سیلنگ فین انسٹالیشن',
              price: 500,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Full Home Wiring Repair',
              titleUr: 'مکمل گھر کی وائرنگ مرمت',
              price: 8000,
            ),
            _FlowDisplayedSkill(
              titleEn: 'AC Switch Installation',
              titleUr: 'اے سی سوئچ لگانا',
              price: 450,
            ),
            _FlowDisplayedSkill(
              titleEn: 'UPS Setup & Installation',
              titleUr: 'یو پی ایس سیٹ اپ',
              price: 1500,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Generator Repair',
              titleUr: 'جنریٹر کی مرمت',
              price: 2000,
            ),
            _FlowDisplayedSkill(
              titleEn: 'Bulb or Holder Replacement',
              titleUr: 'بلب یا ہولڈر تبدیل کرنا',
              price: 150,
            ),
          ]
        : const [];

    for (final def in defaultCategorySkills) {
      if (seenTitles.add(def.titleEn.toLowerCase().trim())) {
        allSkills.add(def);
      }
    }

    final selectedTitles = selectedIssues
        .map((e) => e.titleEn.toLowerCase().trim())
        .toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bilingual(
                              ctx,
                              '${worker.name}\'s Skills',
                              '${worker.name} کی مہارتیں',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bilingual(
                              ctx,
                              'All available services & pricing',
                              'تمام دستیاب سروسز اور قیمتیں',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: allSkills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = allSkills[i];
                    final sTitle = s.titleEn.toLowerCase().trim();
                    final isRequested = selectedTitles.any(
                      (st) =>
                          st == sTitle ||
                          st.contains(sTitle) ||
                          sTitle.contains(st),
                    );

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isRequested
                              ? const Color(0xFF0D9488).withOpacity(0.12)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isRequested
                              ? Icons.check_circle
                              : Icons.handyman_outlined,
                          color: isRequested
                              ? const Color(0xFF0D9488)
                              : Colors.black54,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isUrdu ? s.titleUr : s.titleEn,
                              style: TextStyle(
                                fontWeight: isRequested
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isRequested) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bilingual(ctx, 'Requested', 'مطلوبہ'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        'Rs. ${s.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D9488) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0D9488) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

