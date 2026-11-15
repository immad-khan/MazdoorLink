import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../app_state.dart';
import '../data/mock_data.dart';
import '../services/workers_service.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        AppRoutes,
        ProfileArguments,
        ConversationArguments;

class WorkerPublicProfileScreen extends StatefulWidget {
  final WorkerModel? initialWorker;
  final String? workerId;

  const WorkerPublicProfileScreen({
    super.key,
    this.initialWorker,
    this.workerId,
  });

  @override
  State<WorkerPublicProfileScreen> createState() =>
      _WorkerPublicProfileScreenState();
}

class _WorkerPublicProfileScreenState extends State<WorkerPublicProfileScreen> {
  WorkerModel? _worker;
  bool _loading = false;
  List<String> _favouriteIds = [];
  StreamSubscription? _favSub;

  @override
  void initState() {
    super.initState();
    _worker = widget.initialWorker;

    _favSub = streamFavouriteWorkerIds().listen((ids) {
      if (mounted) setState(() => _favouriteIds = ids);
    });

    if (_worker == null && widget.workerId != null) {
      _loadWorkerById(widget.workerId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_worker == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is WorkerModel) {
        setState(() => _worker = args);
      } else if (args is ProfileArguments) {
        setState(() => _worker = args.worker);
      } else if (args is String && args.isNotEmpty) {
        _loadWorkerById(args);
      } else if (args is Map<String, dynamic>) {
        if (args.containsKey('worker') && args['worker'] is WorkerModel) {
          setState(() => _worker = args['worker'] as WorkerModel);
        } else if (args.containsKey('id') || args.containsKey('workerId')) {
          final id = (args['id'] ?? args['workerId'])?.toString();
          if (id != null && id.isNotEmpty) _loadWorkerById(id);
        }
      }
    }
  }

  Future<void> _loadWorkerById(String id) async {
    setState(() => _loading = true);
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (doc.exists && mounted) {
        setState(() {
          _worker = WorkerModel.fromFirestore(doc.data()!, docId: doc.id);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  void _onBookPressed(BuildContext context, WorkerModel worker, bool isUrdu) {
    // Determine category key
    String catKey = worker.category.toLowerCase().trim();
    if (catKey.contains('plumb')) {
      catKey = 'plumber';
    } else if (catKey.contains('elect')) {
      catKey = 'electrician';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bilingual(
            context,
            'Select issues to request ${worker.name}',
            '${worker.name} کو بک کرنے کے لیے مسائل منتخب کریں',
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );

    Navigator.pushNamed(
      context,
      AppRoutes.issueSelection,
      arguments: catKey,
    );
  }

  Future<void> _onChatPressed(BuildContext context, WorkerModel worker) async {
    final wid = worker.id;
    if (wid == null || wid.isEmpty) return;

    final existingId = await findExistingConversation(wid);
    if (!context.mounted) return;

    if (existingId != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.sharedConversation,
        arguments: ConversationArguments(
          conversationId: existingId,
          otherName: worker.name,
          otherImage: worker.image,
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(bilingual(context, 'Worker Profile', 'ورکر پروفائل')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final worker = _worker;
    if (worker == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(bilingual(context, 'Worker Not Found', 'ورکر نہیں ملا')),
        ),
        body: Center(
          child: Text(
            bilingual(
              context,
              'Worker information could not be loaded.',
              'ورکر کی معلومات لوڈ نہیں ہو سکیں۔',
            ),
          ),
        ),
      );
    }

    final isFav = _favouriteIds.contains(worker.id);

    // Compute lowest / starting price
    double startingPrice = worker.priceValue;
    if (startingPrice <= 0 && worker.skills.isNotEmpty) {
      for (final s in worker.skills) {
        if (s.price > 0 && (startingPrice <= 0 || s.price < startingPrice)) {
          startingPrice = s.price;
        }
      }
    }
    if (startingPrice <= 0) {
      final parsed =
          double.tryParse(worker.price.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (parsed != null && parsed > 0) startingPrice = parsed;
    }
    if (startingPrice <= 0) startingPrice = 300.0;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Hero App Bar ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: const Color(0xFF0D9488),
                  leading: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: Icon(
                        isUrdu ? Icons.arrow_forward : Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () {
                          final wid = worker.id;
                          if (wid == null) return;
                          if (isFav) {
                            removeFavouriteWorker(wid);
                          } else {
                            addFavouriteWorker(wid);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        worker.image.isNotEmpty
                            ? Image.network(
                                worker.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderAvatar(worker),
                              )
                            : _buildPlaceholderAvatar(worker),
                        // Dark gradient overlay
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black87,
                                Colors.black38,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.45, 0.9],
                            ),
                          ),
                        ),
                        // Worker Info Overlay at bottom of hero
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      worker.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  // Category Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC0D72F),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      worker.category,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    bilingual(context, 'Available for work', 'کام کے لیے دستیاب'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (worker.distanceKm > 0) ...[
                                    const Text(
                                      '  •  ',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                    Text(
                                      '${worker.distanceKm} km ${bilingual(context, 'away', 'دور')}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Body Content ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Row
                        _buildQuickStatsCard(context, worker, startingPrice, isUrdu),
                        const SizedBox(height: 16),

                        // Trust & Verification Badges
                        _buildVerificationBadges(context, isUrdu),
                        const SizedBox(height: 20),

                        // About Section
                        _buildAboutSection(context, worker, isUrdu),
                        const SizedBox(height: 20),

                        // Rate Card / Services Catalog
                        _buildServicesCatalog(context, worker, isUrdu),
                        const SizedBox(height: 24),

                        // Customer Reviews Section
                        _buildReviewsSection(context, worker, isUrdu),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Fixed Bottom Action Bar ──────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Chat Button
                      OutlinedButton.icon(
                        onPressed: () => _onChatPressed(context, worker),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D9488),
                          side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: Text(
                          bilingual(context, 'Chat', 'چیٹ'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Book / Hire Service Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _onBookPressed(context, worker, isUrdu),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_today_outlined, size: 20),
                          label: Text(
                            bilingual(context, 'Book Service', 'سروس بک کریں'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(WorkerModel worker) {
    return Container(
      color: const Color(0xFF0D9488),
      child: Center(
        child: Text(
          worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 72,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(
    BuildContext context,
    WorkerModel worker,
    double startingPrice,
    bool isUrdu,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rating
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      worker.rating > 0
                          ? worker.rating.toStringAsFixed(1)
                          : bilingual(context, 'New', 'نیا'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  worker.reviews > 0
                      ? '${worker.reviews} ${bilingual(context, 'Reviews', 'جائزے')}'
                      : bilingual(context, 'No Reviews', 'کوئی جائزہ نہیں'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),

          // Starting Rate
          Expanded(
            child: Column(
              children: [
                Text(
                  'Rs. ${startingPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bilingual(context, 'Starting from', 'ابتدائی قیمت'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade200),

          // Experience / Category
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF0D9488), size: 20),
                const SizedBox(height: 2),
                Text(
                  bilingual(context, 'Verified Pro', 'تصدیق شدہ'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadges(BuildContext context, bool isUrdu) {
    return Row(
      children: [
        _buildBadge(
          icon: Icons.badge_outlined,
          color: const Color(0xFF15803D),
          bgColor: const Color(0xFFDCFCE7),
          label: bilingual(context, 'CNIC Verified', 'شناختی کارڈ تصدیق شدہ'),
        ),
        const SizedBox(width: 8),
        _buildBadge(
          icon: Icons.security_outlined,
          color: const Color(0xFF1D4ED8),
          bgColor: const Color(0xFFDBEAFE),
          label: bilingual(context, 'Police Cleared', 'پولیس کلیئرڈ'),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, WorkerModel worker, bool isUrdu) {
    final catName = worker.category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bilingual(context, 'About Worker', 'ورکر کے بارے میں'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            bilingual(
              context,
              'Professional $catName providing reliable, quality service in your area. Background checked and certified on MazdoorLink.',
              'آپ کے علاقے میں معیاری اور قابل اعتماد سروس فراہم کرنے والے پیشہ ور $catName۔ مزدور لنک پر مکمل تصدیق شدہ۔',
            ),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCatalog(BuildContext context, WorkerModel worker, bool isUrdu) {
    // Gather all skills
    final skills = worker.skills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bilingual(context, 'Services & Rate Card', 'خدمات اور ریٹ لسٹ'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${skills.length} ${bilingual(context, 'services', 'خدمات')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          bilingual(
            context,
            'Standard rates per service for your reference.',
            'آپ کے حوالہ کے لیے ہر سروس کے معیاری ریٹس۔',
          ),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),

        if (skills.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.handyman_outlined, color: Color(0xFF0D9488)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bilingual(
                      context,
                      'Standard ${worker.category} services available on booking.',
                      'بکنگ پر معیاری ${worker.category} خدمات دستیاب ہیں۔',
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: skills.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade100,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final s = skills[index];
                final title = isUrdu && s.titleUr.isNotEmpty ? s.titleUr : s.titleEn;
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.handyman_outlined,
                      color: Color(0xFF0D9488),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text(
                      'Rs. ${s.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, WorkerModel worker, bool isUrdu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bilingual(context, 'Customer Reviews', 'گاہکوں کے جائزے'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (worker.reviews > 0)
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${worker.rating.toStringAsFixed(1)} (${worker.reviews})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: streamWorkerReviews(worker.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.rate_review_outlined,
                      color: Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bilingual(
                          context,
                          'No reviews yet. Book this worker and be the first to leave a review!',
                          'ابھی تک کوئی جائزہ نہیں۔ اس ورکر کو بک کریں اور پہلا جائزہ دیں۔',
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: docs.take(6).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final customerName = data['customerName']?.toString() ?? 'Customer';
                final r = (data['rating'] as num?)?.toInt() ?? 5;
                final reviewText = data['review']?.toString() ?? '';
                final jobTitle = data['jobTitle']?.toString() ?? '';
                final ts = data['createdAt'] as Timestamp?;
                final dateStr =
                    ts != null ? DateFormat('d MMM yyyy').format(ts.toDate()) : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                            child: Text(
                              customerName.isNotEmpty
                                  ? customerName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: Color(0xFF0D9488),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < r ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 16,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (jobTitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            jobTitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (reviewText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          reviewText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
