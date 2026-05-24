import 'package:flutter/material.dart';
import '../app_state.dart';
import 'mazdoor_flow.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareLocation = true;
  bool _sharePhone = true;
  bool _shareProfile = false;
  bool _allowMessaging = true;
  bool _allowNotifications = true;

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Privacy Settings', 'پرائیویسی ترتیبات'),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy preferences section
          Text(
            bilingual(context, 'Data Sharing', 'ڈیٹا شیئرنگ'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _PrivacyToggle(
            icon: Icons.location_on_outlined,
            title: bilingual(context, 'Share Location', 'لوکیشن شیئر کریں'),
            subtitle: bilingual(context, 'Allow workers to see your location', 'ورکرز کو اپنی لوکیشن دکھائیں'),
            value: _shareLocation,
            onChanged: (val) => setState(() => _shareLocation = val),
          ),
          const SizedBox(height: 12),
          _PrivacyToggle(
            icon: Icons.phone_outlined,
            title: bilingual(context, 'Show Phone Number', 'فون نمبر دکھائیں'),
            subtitle: bilingual(context, 'Let workers contact you directly', 'ورکرز براہ راست رابطہ کریں'),
            value: _sharePhone,
            onChanged: (val) => setState(() => _sharePhone = val),
          ),
          const SizedBox(height: 12),
          _PrivacyToggle(
            icon: Icons.person_outline,
            title: bilingual(context, 'Public Profile', 'عوامی پروفائل'),
            subtitle: bilingual(context, 'Let others view your profile', 'دوسرے آپ کا پروفائل دیکھ سکیں'),
            value: _shareProfile,
            onChanged: (val) => setState(() => _shareProfile = val),
          ),
          const SizedBox(height: 24),
          // Communication section
          Text(
            bilingual(context, 'Communication', 'رابطہ'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _PrivacyToggle(
            icon: Icons.chat_bubble_outline,
            title: bilingual(context, 'Allow Direct Messages', 'براہ راست پیغامات قبول کریں'),
            subtitle: bilingual(context, 'Workers can message you', 'ورکرز آپ کو پیغام بھیج سکیں'),
            value: _allowMessaging,
            onChanged: (val) => setState(() => _allowMessaging = val),
          ),
          const SizedBox(height: 12),
          _PrivacyToggle(
            icon: Icons.notifications_outlined,
            title: bilingual(context, 'Allow Notifications', 'اطلاعات قبول کریں'),
            subtitle: bilingual(context, 'Receive job and chat notifications', 'کام اور چیٹ کی اطلاعات موصول کریں'),
            value: _allowNotifications,
            onChanged: (val) => setState(() => _allowNotifications = val),
          ),
          const SizedBox(height: 24),
          // Account privacy section
          Text(
            bilingual(context, 'Account Privacy', 'اکاؤنٹ کی رازداری'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(bilingual(
                    context,
                    'Password changed successfully',
                    'پاس ورڈ کامیابی سے بدل گیا',
                  )),
                ),
              );
            },
            icon: const Icon(Icons.lock_outline),
            label: Text(bilingual(context, 'Change Password', 'پاس ورڈ بدلیں')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(bilingual(
                    context,
                    'Sessions cleared',
                    'سیشنز صاف کر دیے گئے',
                  )),
                ),
              );
            },
            icon: const Icon(Icons.logout),
            label: Text(bilingual(context, 'Clear Other Sessions', 'دوسرے سیشنز صاف کریں')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              _showDeleteAccountDialog(context);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: Text(
              bilingual(context, 'Delete Account', 'اکاؤنٹ ڈیلیٹ کریں'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bilingual(context, 'Delete Account?', 'اکاؤنٹ ڈیلیٹ کریں؟')),
        content: Text(bilingual(
          context,
          'This action cannot be undone. All your data will be permanently deleted.',
          'یہ کارروائی واپس نہیں کی جا سکتی۔ آپ کے تمام ڈیٹا مستقل طور پر حذف ہو جائیں گے۔',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(bilingual(context, 'Cancel', 'منسوخ')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(bilingual(
                    context,
                    'Account deletion requested',
                    'اکاؤنٹ ڈیلیٹ کرنے کی درخواست موصول ہوئی',
                  )),
                ),
              );
            },
            child: Text(
              bilingual(context, 'Delete', 'ڈیلیٹ کریں'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyToggle extends StatelessWidget {
  const _PrivacyToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withValues(alpha: 0.12),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.teal,
        ),
      ),
    );
  }
}

