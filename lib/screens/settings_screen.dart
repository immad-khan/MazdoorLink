import 'dart:async';
import 'dart:math' as math;
import 'service_tracking_screen.dart' show showWorkerReviewsSheet;
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
import 'issue_selection_screen.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        ProfileArguments;
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Displays confirmation dialog asking "Want to switch to [Customer/Mazdoor] account, yes or no?"
  Future<bool> _showSwitchRoleDialog(
    BuildContext context, {
    required bool toWorker,
  }) async {
    final targetAccount = toWorker ? 'Mazdoor' : 'Customer';
    final targetAccountUrdu = toWorker ? 'مزدور' : 'کسٹمر';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF0D9488),
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bilingual(context, 'Switch Account', 'اکاؤنٹ سوئچ کریں'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          bilingual(
            context,
            'Want to switch to $targetAccount account?',
            'کیا آپ $targetAccountUrdu اکاؤنٹ پر سوئچ کرنا چاہتے ہیں؟',
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(bilingual(context, 'No', 'نہیں')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(bilingual(context, 'Yes', 'ہاں')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Called when user in Customer mode taps "Switch to Worker Mode"
  Future<void> _switchToWorkerMode(
    BuildContext context,
    Map<String, dynamic> userData,
  ) async {
    final c = AppScope.of(context);
    final roles =
        (userData['roles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final workerStatus =
        userData['workerStatus']?.toString() ?? userData['status']?.toString();
    final hasWorkerAccess =
        roles.contains('worker') || userData['role'] == 'worker';

    if (hasWorkerAccess && workerStatus == 'approved') {
      // Worker mode is already set up and approved — switch directly
      await WorkerPresenceService.instance.setOnline(false);
      c.switchActiveRole(UserRole.worker);
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.workerDashboard,
          (r) => false,
        );
      }
    } else if (workerStatus == 'pending') {
      // Applied but not yet approved by admin
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.pending_actions, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bilingual(
                      context,
                      'Application Pending',
                      'درخواست زیر التواء',
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              bilingual(
                context,
                'Your worker verification request is under admin review. You will be able to access worker mode once approved.',
                'آپ کی ورکر تصدیقی درخواست ایڈمن کے جائزے میں ہے۔ منظوری پر آپ کو مطلع کیا جائے گا اور آپ ورکر موڈ استعمال کر سکیں گے۔',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(bilingual(context, 'OK', 'ٹھیک ہے')),
              ),
            ],
          ),
        );
      }
    } else if (workerStatus == 'rejected') {
      // Previously rejected by admin - allow re-applying with updated verification docs
      final reason =
          userData['rejectReason']?.toString() ?? 'Documents not verified';
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bilingual(context, 'Application Rejected', 'درخواست مسترد'),
                  ),
                ),
              ],
            ),
            content: Text(
              bilingual(
                context,
                'Your worker verification application was rejected by admin.\nReason: $reason\n\nPlease update your verification documents and re-apply.',
                'ایڈمن کی جانب سے آپ کی ورکر تصدیق مسترد ہو گئی ہے۔\nوجہ: $reason\n\nبراہ کرم دستاویزات اپ ڈیٹ کر کے دوبارہ جمع کرائیں۔',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(bilingual(context, 'Cancel', 'منسوخ')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.workerVerification);
                },
                child: Text(
                  bilingual(context, 'Update & Re-apply', 'دوبارہ درخواست دیں'),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // First time accessing worker mode — show modal to prompt for verification
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    size: 32,
                    color: Color(0xFF0D9488),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  bilingual(
                    context,
                    'Worker Verification Required',
                    'ورکر تصدیق لازمی ہے',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  bilingual(
                    context,
                    'To switch to worker mode and start receiving jobs, you must submit your CNIC, optional certificates/experience letters, and skill details for admin approval.',
                    'ورکر بننے اور کام وصول کرنے کے لیے اپنا شناختی کارڈ، سرٹیفکیٹ اور مہارت کی تفصیلات ایڈمن منظوری کے لیے جمع کروائیں۔',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.badge_outlined),
                    label: Text(
                      bilingual(
                        context,
                        'Complete Worker Verification',
                        'ورکر تصدیق مکمل کریں',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.workerVerification,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }
    }
  }

  /// Called when user in Worker mode taps "Switch to Customer Mode"
  Future<void> _switchToCustomerMode(BuildContext context) async {
    final c = AppScope.of(context);
    // Go offline before switching so the worker is removed from listings
    await WorkerPresenceService.instance.setOnline(false);
    c.switchActiveRole(UserRole.customer);
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.customerHome,
        (r) => false,
      );
    }
  }

  Widget _buildNotificationChannelCard(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    final currentPref =
        data?['notificationPreference']?.toString() ??
        (data?['otpVerifiedVia'] == 'phone' ? 'phone' : 'email');
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF0D9488).withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bilingual(
                            context,
                            'Notification Channel',
                            'نوٹیفیکیشن کا ذریعہ',
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          bilingual(
                            context,
                            'Choose where you want to receive admin updates & alerts',
                            'ایڈمن منظوری اور الرٹس وصول کرنے کا ذریعہ منتخب کریں',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildNotificationChannelChip(
                    context,
                    label: bilingual(
                      context,
                      'Number (SMS)',
                      'موبائل نمبر (SMS)',
                    ),
                    icon: Icons.sms_outlined,
                    selected: currentPref == 'phone',
                    onTap: () async {
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'notificationPreference': 'phone'});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bilingual(
                                  context,
                                  'Notifications set to Phone Number (SMS)',
                                  'نوٹیفیکیشنز موبائل نمبر پر سیٹ ہو گئیں',
                                ),
                              ),
                              backgroundColor: const Color(0xFF0D9488),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildNotificationChannelChip(
                    context,
                    label: bilingual(context, 'Email', 'ای میل'),
                    icon: Icons.email_outlined,
                    selected: currentPref == 'email',
                    onTap: () async {
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'notificationPreference': 'email'});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bilingual(
                                  context,
                                  'Notifications set to Email',
                                  'نوٹیفیکیشنز ای میل پر سیٹ ہو گئیں',
                                ),
                              ),
                              backgroundColor: const Color(0xFF0D9488),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildNotificationChannelChip(
                    context,
                    label: bilingual(context, 'Both', 'دونوں'),
                    icon: Icons.all_inclusive,
                    selected: currentPref == 'both',
                    onTap: () async {
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'notificationPreference': 'both'});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bilingual(
                                  context,
                                  'Notifications set to Both (SMS & Email)',
                                  'نوٹیفیکیشنز دونوں پر سیٹ ہو گئیں',
                                ),
                              ),
                              backgroundColor: const Color(0xFF0D9488),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationChannelChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0D9488)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.black87,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final isWorker = c.role == UserRole.worker;

    return MzScaffold(
      showBottomNav: true,
      title: bilingual(context, 'Settings', 'ترتیبات'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: streamCurrentUserData(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final name =
                  data?['name']?.toString() ??
                  FirebaseAuth.instance.currentUser?.displayName ??
                  'User';
              final phone = data?['phone']?.toString() ?? '+92 300 1234567';
              final profileImage = data?['profileImage']?.toString() ?? '';

              // ── Role Switcher Card ──────────────────────────────────────────
              Widget roleSwitcher = const SizedBox.shrink();
              if (data != null) {
                roleSwitcher = Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF0D9488,
                                ).withOpacity(0.12),
                                child: Icon(
                                  isWorker
                                      ? Icons.handyman_rounded
                                      : Icons.person_rounded,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bilingual(
                                      context,
                                      'Current Mode',
                                      'موجودہ موڈ',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    isWorker
                                        ? bilingual(
                                            context,
                                            'Worker Mode',
                                            'ورکر موڈ',
                                          )
                                        : bilingual(
                                            context,
                                            'Customer Mode',
                                            'کسٹمر موڈ',
                                          ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0D9488),
                                side: const BorderSide(
                                  color: Color(0xFF0D9488),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                isWorker
                                    ? Icons.person_rounded
                                    : Icons.handyman_rounded,
                              ),
                              label: Text(
                                isWorker
                                    ? bilingual(
                                        context,
                                        'Switch to Customer Mode',
                                        'کسٹمر موڈ پر جائیں',
                                      )
                                    : bilingual(
                                        context,
                                        'Switch to Worker Mode',
                                        'ورکر موڈ پر جائیں',
                                      ),
                              ),
                              onPressed: () async {
                                if (isWorker) {
                                  final confirmed = await _showSwitchRoleDialog(
                                    context,
                                    toWorker: false,
                                  );
                                  if (confirmed && context.mounted) {
                                    _switchToCustomerMode(context);
                                  }
                                } else {
                                  final confirmed = await _showSwitchRoleDialog(
                                    context,
                                    toWorker: true,
                                  );
                                  if (confirmed && context.mounted) {
                                    _switchToWorkerMode(context, data);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage.isEmpty
                          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(name),
                    subtitle: Text(phone),
                  ),
                  const SizedBox(height: 8),
                  roleSwitcher,
                  if (isWorker) _buildNotificationChannelCard(context, data),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.profileManagement),
            child: _SettingsItem(
              icon: Icons.person,
              color: Colors.blue,
              title: bilingual(context, 'Profile', 'پروفائل'),
            ),
          ),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.notificationPreferences),
            child: _SettingsItem(
              icon: Icons.notifications,
              color: Colors.amber,
              title: bilingual(context, 'Notifications', 'نوٹیفیکیشن'),
            ),
          ),
          _SettingsItem(
            icon: Icons.language,
            color: Colors.purple,
            title: bilingual(context, 'Language', 'زبان'),
            trailing: TextButton(
              onPressed: c.toggleLanguage,
              child: Text(c.isUrdu ? 'English' : 'اردو'),
            ),
          ),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.privacySettings),
            child: _SettingsItem(
              icon: Icons.lock,
              color: Colors.green,
              title: bilingual(context, 'Privacy', 'پرائیویسی'),
            ),
          ),
          if (!isWorker)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/customer/support'),
              child: _SettingsItem(
                icon: Icons.help_outline,
                color: const Color(0xFF0D9488),
                title: bilingual(context, 'Customer Support', 'کسٹمر سپورٹ'),
              ),
            ),
          if (isWorker)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/worker/support'),
              child: _SettingsItem(
                icon: Icons.help_outline,
                color: const Color(0xFF0D9488),
                title: bilingual(context, 'Worker Support', 'ورکر سپورٹ'),
              ),
            ),
          if (isWorker)
            StreamBuilder<DocumentSnapshot>(
              stream: streamCurrentUserData(),
              builder: (context, userSnap) {
                final uData = userSnap.data?.data() as Map<String, dynamic>?;
                final double rating =
                    (uData?['rating'] as num?)?.toDouble() ?? 0.0;
                final int reviewsCount =
                    (uData?['reviews'] as num?)?.toInt() ?? 0;
                final user = FirebaseAuth.instance.currentUser;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFF59E0B),
                        width: 1.2,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFEF3C7),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFD97706),
                          size: 26,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            bilingual(
                              context,
                              'My Rating & Feedback',
                              'میری درجہ بندی اور جائزے',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFD97706),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating > 0
                                      ? rating.toStringAsFixed(1)
                                      : (c.isUrdu ? 'نیا' : 'New'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        reviewsCount > 0
                            ? '$reviewsCount ${bilingual(context, 'customer reviews received • Tap to view', 'کسٹمر جائزے موصول ہوئے • دیکھنے کے لیے کلک کریں')}'
                            : bilingual(
                                context,
                                'No reviews yet. Complete jobs to get rated!',
                                'ابھی کوئی جائزہ نہیں ملا۔ درجہ بندی کے لیے کام مکمل کریں!',
                              ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Transform.rotate(
                        angle: c.isUrdu ? math.pi : 0,
                        child: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      onTap: () =>
                          showWorkerReviewsSheet(context, user?.uid ?? ''),
                    ),
                  ),
                );
              },
            ),
          if (isWorker)
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.workerServicesSetup),
              child: _SettingsItem(
                icon: Icons.build,
                color: const Color(0xFF0D9488),
                title: bilingual(
                  context,
                  'Skills & Services',
                  'مہارتیں اور خدمات',
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bilingual(context, 'Logout?', 'لاگ آؤٹ؟'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    bilingual(
                      context,
                      'Are you sure you want to log out?',
                      'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(bilingual(context, 'No', 'نہیں')),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(bilingual(context, 'Yes', 'ہاں')),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await c.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.welcome,
                    (route) => false,
                  );
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              bilingual(context, 'Log Out', 'لاگ آؤٹ'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final shouldExit = await showExitMazdoorlinkDialog(context);
              if (shouldExit) {
                await c.logout();
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
            icon: const Icon(Icons.exit_to_app, color: Color(0xFF64748B)),
            label: Text(
              bilingual(context, 'Exit Mazdoorlink', 'Mazdoorlink بند کریں'),
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final isUrdu = scope.isUrdu;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing:
            trailing ??
            Transform.rotate(
              angle: isUrdu ? math.pi : 0,
              child: const Icon(Icons.chevron_right),
            ),
      ),
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

/// Data model for job photos in the photo picker modal
class _JobPhotoAsset {
  const _JobPhotoAsset(this.label, this.asset, this.icon);
  final String label;
  final String asset;
  final IconData icon;
}

/// Card widget for camera/gallery action buttons in photo picker
/// Card widget for camera/gallery action buttons in photo picker
class _PhotoActionCard extends StatelessWidget {
  const _PhotoActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
              child: Icon(icon, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteWorkersScreen extends StatefulWidget {
  const FavoriteWorkersScreen({super.key});
  @override
  State<FavoriteWorkersScreen> createState() => _FavoriteWorkersScreenState();
}

class _FavoriteWorkersScreenState extends State<FavoriteWorkersScreen> {
  StreamSubscription? _favSub;
  List<String> _favouriteIds = [];
  List<WorkerModel> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _favSub = streamFavouriteWorkerIds().listen((ids) {
      _favouriteIds = ids;
      _fetchWorkers(ids);
    });
  }

  Future<void> _fetchWorkers(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted)
        setState(() {
          _workers = [];
          _loading = false;
        });
      return;
    }
    final workers = <WorkerModel>[];
    for (final id in ids) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('workers')
            .doc(id)
            .get();
        final data = doc.data();
        if (data != null) {
          workers.add(WorkerModel.fromFirestore(data, docId: doc.id));
        }
      } catch (_) {}
    }
    if (mounted)
      setState(() {
        _workers = workers;
        _loading = false;
      });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBack: true,
      title: bilingual(context, 'Favorite Workers', 'پسندیدہ ورکرز'),
      showBottomNav: false,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  bilingual(
                    context,
                    'No favourite workers yet. Tap the heart icon on a worker\'s profile to add them.',
                    'ابھی تک کوئی پسندیدہ ورکر نہیں۔ ورکر کے پروفائل پر دل کے آئیکن کو تھپتھپا کر شامل کریں۔',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _workers.length,
              itemBuilder: (context, i) {
                final w = _workers[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: w.image.isNotEmpty
                        ? NetworkImage(w.image)
                        : null,
                    child: w.image.isEmpty
                        ? Text(
                            w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                          )
                        : null,
                  ),
                  title: Text(
                    w.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${w.category}${w.price.isNotEmpty ? '  •  ${w.price}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 22,
                        ),
                        onPressed: () {
                          final wid = w.id;
                          if (wid == null) return;
                          removeFavouriteWorker(wid);
                          setState(() => _favouriteIds.remove(wid));
                          _fetchWorkers(_favouriteIds);
                        },
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.pushNamed(
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
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        color: const Color(0xFF0D9488),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
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
                    );
                  },
                );
              },
            ),
    );
  }
}
