import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_state.dart';
import '../data/mock_data.dart';
import '../services/location_service.dart';
import '../services/workers_service.dart';
import 'issue_selection_screen.dart';
import 'settings_screen.dart' show FavoriteWorkersScreen;
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        ProfileArguments,
        TrackingArguments;
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LocationService.instance.ensureLocationReady(context);
      }
    });
  }

  void _showActiveJobCategoryBlockedDialog(
    BuildContext context,
    ServiceCategory category,
    CustomerActiveJobInfo activeJob,
    bool isUrdu,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUrdu
                      ? '${category.ur} کا کام جاری ہے'
                      : '${category.en} In Progress',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUrdu
                    ? 'آپ کا ${category.ur} کا کام کاریگر (${activeJob.workerName}) کے ساتھ پہلے سے جاری ہے۔ جب تک یہ کام مکمل نہیں ہو جاتا، آپ نیا ${category.ur} ہائر نہیں کر سکتے۔'
                    : 'You already have an active ${category.en} job in progress with ${activeJob.workerName}. Until this job is completed or cancelled, you cannot request another ${category.en}.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF4B5563),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isUrdu
                            ? 'اسٹیٹس: ${activeJob.status}'
                            : 'Status: ${activeJob.status}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isUrdu ? 'ٹھیک ہے' : 'OK',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(
                  context,
                  AppRoutes.tracking,
                  arguments: TrackingArguments(jobId: activeJob.jobId),
                );
              },
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: Text(isUrdu ? 'کام ٹریک کریں' : 'Track Job'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;

    return MzScaffold(
      showBottomNav: true,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<AppLocation>(
                        valueListenable:
                            LocationService.instance.currentLocationNotifier,
                        builder: (context, loc, _) {
                          return InkWell(
                            onTap: () => LocationService.instance
                                .showAreaPickerDialog(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      loc.shortDisplayNameBilingual(isUrdu),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'ISB / RWP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Text(
                        isUrdu ? 'AR' : 'EN',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final shouldExit =
                            await showExitMazdoorlinkDialog(context);
                        if (shouldExit == true) {
                          await scope.logout();
                          if (context.mounted) {
                            SystemNavigator.pop();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.welcome,
                              (route) => false,
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.exit_to_app_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    hintText: bilingual(
                      context,
                      'What service do you need?',
                      'آپ کو کون سی سروس چاہیے؟',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoriteWorkersScreen(),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFF0D9488)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bilingual(
                              context,
                              'Favorite Workers',
                              'پسندیدہ ورکرز',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            bilingual(
                              context,
                              'Hire your preferred providers directly.',
                              'اپنے پسندیدہ کاریگروں کو تیزی سے ہائر کریں۔',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF0D9488),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              bilingual(context, 'Categories', 'زمرہ جات'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<Map<String, CustomerActiveJobInfo>>(
              stream: streamCustomerActiveCategoriesMap(
                FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, activeSnapshot) {
                final activeCategories = activeSnapshot.data ?? {};
                return GridView.builder(
                  itemCount: categories.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, i) {
                    final item = categories[i];
                    final activeJob = activeCategories[item.key.toLowerCase()];
                    final isJobActive = activeJob != null;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 240 + i * 60),
                      builder: (_, value, child) => Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.92 + value * 0.08,
                          child: child,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (isJobActive) {
                            _showActiveJobCategoryBlockedDialog(
                              context,
                              item,
                              activeJob,
                              isUrdu,
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.issueSelection,
                              arguments: item.key,
                            );
                          }
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isJobActive
                                ? const BorderSide(
                                    color: Color(0xFFF59E0B),
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          color: isJobActive ? const Color(0xFFFFFBEB) : null,
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isJobActive
                                            ? const Color(0xFFFEF3C7)
                                            : const Color(0xFFE6FFFA),
                                        child: Icon(
                                          item.icon,
                                          color: isJobActive
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF0D9488),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isUrdu ? item.ur : item.en,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isJobActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isJobActive
                                              ? const Color(0xFF92400E)
                                              : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isJobActive)
                                Positioned(
                                  top: 6,
                                  right: isUrdu ? null : 6,
                                  left: isUrdu ? 6 : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isUrdu ? 'جاری ہے' : 'In Progress',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Text(
                  bilingual(context, 'Top Rated Workers', 'بہترین ورکرز'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  bilingual(context, 'See all', 'سب دیکھیں'),
                  style: const TextStyle(color: Color(0xFF0D9488)),
                ),
              ],
            ),
          ),
          StreamBuilder<List<WorkerModel>>(
            stream: streamApprovedWorkers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    bilingual(
                      context,
                      'Failed to load workers',
                      'ورکرز لوڈ کرنے میں ناکامی',
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final realWorkers = snapshot.data!;
              if (realWorkers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    bilingual(
                      context,
                      'No workers available yet',
                      'ابھی کوئی ورکر دستیاب نہیں',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final w in realWorkers)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: w.image.isNotEmpty
                            ? NetworkImage(w.image)
                            : null,
                        child: w.image.isEmpty
                            ? Text(
                                w.name.isNotEmpty
                                    ? w.name[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(w.name),
                      subtitle: Text(
                        '${w.category}${w.price.isNotEmpty ? '  •  ${w.price}' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.workerProfile,
                        arguments: ProfileArguments(
                          worker: w,
                          job: JobPostingArguments(
                            descriptionEn: '',
                            descriptionUr: '',
                            price: 0,
                            categoryKey: '',
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}